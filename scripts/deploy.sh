#!/bin/bash
set -e

# ==========================================
# Laravel Docker Deployment Script
# Production-ready with interactive setup
# Supports Cloudflare proxy detection
# Usage: ./scripts/deploy.sh dev | prod
# ==========================================

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Navigate to project root
cd "$PROJECT_ROOT"

# --- Global Variables ---
NEEDS_KEY_GENERATION=false
ENVIRONMENT=""
ENV_FILE=""
COMPOSE_FILES=""
USES_CLOUDFLARE=false
CLOUDFLARE_PROXIED=false
SSL_CONFIGURED=false

# --- Cloudflare Detection ---
detect_cloudflare() {
    local domain=$1

    print_info "Checking Cloudflare configuration for $domain..."

    if ! command -v dig &> /dev/null; then
        print_warning "dig command not found, skipping Cloudflare detection"
        USES_CLOUDFLARE=false
        CLOUDFLARE_PROXIED=false
        return
    fi

    local domain_ip=$(dig +short "$domain" 2>/dev/null | grep -E '^[0-9]+\.' | head -n1)

    if [ -z "$domain_ip" ]; then
        print_warning "Could not resolve domain IP"
        USES_CLOUDFLARE=false
        CLOUDFLARE_PROXIED=false
        return
    fi

    print_info "Domain resolves to: $domain_ip"

    # Cloudflare IPv4 ranges
    local cloudflare_ranges=(
        "173.245.48.0/20" "103.21.244.0/22" "103.22.200.0/22" "103.31.4.0/22"
        "141.101.64.0/18" "108.162.192.0/18" "190.93.240.0/20" "188.114.96.0/20"
        "197.234.240.0/22" "198.41.128.0/17" "162.158.0.0/15" "104.16.0.0/13"
        "104.24.0.0/14" "172.64.0.0/13" "131.0.72.0/22"
    )

    local is_cloudflare=false
    for range in "${cloudflare_ranges[@]}"; do
        if check_ip_in_range "$domain_ip" "$range"; then
            is_cloudflare=true
            break
        fi
    done

    if [ "$is_cloudflare" = true ]; then
        USES_CLOUDFLARE=true
        CLOUDFLARE_PROXIED=true
        print_warning "Domain is PROXIED through Cloudflare (orange cloud)"
        print_info "Detected Cloudflare IP: $domain_ip"
        return
    fi

    local nameservers=$(dig +short NS "$domain" 2>/dev/null | grep -i cloudflare | wc -l)

    if [ "$nameservers" -gt 0 ]; then
        USES_CLOUDFLARE=true
        CLOUDFLARE_PROXIED=false
        print_success "Domain uses Cloudflare nameservers (DNS-only / gray cloud)"
    else
        USES_CLOUDFLARE=false
        CLOUDFLARE_PROXIED=false
        print_success "Domain does not use Cloudflare"
    fi
}

# --- Environment Setup ---
setup_env_file() {
    local env_backup=".env.${ENVIRONMENT}"

    if [ -f "$ENV_FILE" ]; then
        print_warning "Existing $ENV_FILE found"
        local reconfigure=$(prompt_yn "Reconfigure environment?" "n")

        if [ "$reconfigure" != "y" ]; then
            print_info "Using existing configuration"
            source "$ENV_FILE"
            export APP_NAME DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_PASSWORD SERVER_NAME
            return
        fi

        set +e
        source "$ENV_FILE" 2>/dev/null
        set -e

        echo ""
        echo -e "${RED}╔═══════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ⚠️  DATABASE WILL BE RESET!  ⚠️      ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}Reconfiguring the environment will:${NC}"
        echo -e "  • Stop all containers"
        echo -e "  • ${RED}Delete the database volume${NC}"
        echo -e "  • ${RED}ALL DATA WILL BE LOST!${NC}"
        echo -e "  • Create new database with new passwords"
        echo ""

        local confirm=$(prompt_yn "Are you ABSOLUTELY sure you want to continue?" "n")

        if [ "$confirm" != "y" ]; then
            print_info "Reconfiguration cancelled"
            exit 0
        fi

        print_info "Stopping containers and removing volumes..."
        dc down -v 2>/dev/null || true
        print_success "Containers stopped and volumes removed"

        cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Backup created"
    fi

    if [ -f "$env_backup" ] && [ "$reconfigure" != "y" ]; then
        print_info "Found existing $env_backup"
        local use_backup=$(prompt_yn "Use this configuration?" "y")

        if [ "$use_backup" == "y" ]; then
            cp "$env_backup" "$ENV_FILE"
            print_success "Using $env_backup"
            source "$ENV_FILE"
            export APP_NAME DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_PASSWORD SERVER_NAME
            return
        fi
    fi

    if [ ! -f ".env.example" ]; then
        print_error ".env.example not found!"
        exit 1
    fi

    cp .env.example "$ENV_FILE"

    set +e
    source "$ENV_FILE" 2>/dev/null
    set -e

    print_info "Let's configure your environment..."
    echo ""

    APP_NAME=$(prompt_input "Application name (container names)" "${APP_NAME:-laravel_app}")
    sed -i "s/^APP_NAME=.*/APP_NAME=${APP_NAME}/" "$ENV_FILE"

    if [ "$ENVIRONMENT" == "prod" ]; then
        APP_URL=$(prompt_input "Application URL (https://yourdomain.com)" "")
        while ! validate_domain "$(echo $APP_URL | sed -e 's|^https\?://||' -e 's|/.*||')"; do
            APP_URL=$(prompt_input "Application URL (https://yourdomain.com)" "")
        done

        SERVER_NAME=$(echo "$APP_URL" | sed -e 's|^https\?://||' -e 's|/.*||')
        sed -i "s/^SERVER_NAME=.*/SERVER_NAME=${SERVER_NAME}/" "$ENV_FILE"
        print_info "Server name: $SERVER_NAME"

        detect_cloudflare "$SERVER_NAME"
    else
        APP_URL=$(prompt_input "Application URL" "${APP_URL:-http://localhost}")
        SERVER_NAME="localhost"
    fi
    sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" "$ENV_FILE"

    if [ "$ENVIRONMENT" == "prod" ]; then
        sed -i "s/^APP_ENV=.*/APP_ENV=production/" "$ENV_FILE"
        sed -i "s/^APP_DEBUG=.*/APP_DEBUG=false/" "$ENV_FILE"
    else
        sed -i "s/^APP_ENV=.*/APP_ENV=local/" "$ENV_FILE"
        sed -i "s/^APP_DEBUG=.*/APP_DEBUG=true/" "$ENV_FILE"
    fi

    if [ -z "$APP_KEY" ] || [ "$APP_KEY" == "" ]; then
        print_info "APP_KEY will be generated after containers start"
        sed -i "s/^APP_KEY=.*/APP_KEY=/" "$ENV_FILE"
        NEEDS_KEY_GENERATION=true
    else
        print_success "APP_KEY already set"
        NEEDS_KEY_GENERATION=false
    fi

    echo -e "\n${BLUE}=== Database Configuration ===${NC}\n"

    DB_DATABASE=$(prompt_input "Database name" "${DB_DATABASE:-${APP_NAME}_db}")
    sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" "$ENV_FILE"

    DB_USERNAME=$(prompt_input "Database username" "${DB_USERNAME:-${APP_NAME}_user}")
    sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" "$ENV_FILE"

    if [ "$ENVIRONMENT" == "prod" ]; then
        print_info "Generating secure database password..."
        DB_PASSWORD=$(generate_password)
        echo -e "${YELLOW}Generated DB_PASSWORD: ${GREEN}$DB_PASSWORD${NC}"
        echo -e "${RED}⚠️  Save this password securely!${NC}"
        read -p "Press enter to continue..."

        MYSQL_ROOT_PASSWORD=$(generate_password)
    else
        DB_PASSWORD=$(prompt_input "Database password" "${DB_PASSWORD:-password}")
        MYSQL_ROOT_PASSWORD=$(prompt_input "MySQL root password" "${MYSQL_ROOT_PASSWORD:-rootpassword}")
    fi

    sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" "$ENV_FILE"
    sed -i "s/^MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}/" "$ENV_FILE"

    if [ "$ENVIRONMENT" == "prod" ]; then
        print_info "Generating secure Redis password..."
        REDIS_PASSWORD=$(generate_password)
    else
        REDIS_PASSWORD=$(prompt_input "Redis password" "${REDIS_PASSWORD:-redis_password}")
    fi

    sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=${REDIS_PASSWORD}/" "$ENV_FILE"

    cp "$ENV_FILE" "$env_backup"
    print_success "Configuration saved to $env_backup"

    export APP_NAME DB_DATABASE DB_USERNAME DB_PASSWORD MYSQL_ROOT_PASSWORD REDIS_PASSWORD SERVER_NAME
}

# --- SSL Certificate Functions ---
check_ssl_certificates() {
    if [ "$ENVIRONMENT" == "dev" ]; then
        if [ ! -f "./docker/nginx/dev-cert/cert.pem" ]; then
            print_warning "No dev SSL certificates found"
            local create_certs=$(prompt_yn "Create self-signed certificates?" "y")

            if [ "$create_certs" == "y" ]; then
                if [ -f "$SCRIPTS_DIR/create-ssl-certs.sh" ]; then
                    print_info "Running SSL certificate script..."
                    bash "$SCRIPTS_DIR/create-ssl-certs.sh"
                else
                    print_error "create-ssl-certs.sh not found in $SCRIPTS_DIR"
                    print_info "Skipping SSL setup"
                fi
            else
                print_warning "Skipping SSL certificate creation"
                print_info "HTTPS won't work without certificates"
            fi
        else
            print_success "Dev SSL certificates found"

            local expiry=$(openssl x509 -in ./docker/nginx/dev-cert/cert.pem -noout -enddate 2>/dev/null | cut -d= -f2)
            if [ -n "$expiry" ]; then
                print_info "Certificate expires: $expiry"
            fi
        fi
    else
        setup_production_ssl
    fi
}

setup_production_ssl() {
    local cert_path="./data/certbot/conf/live/${SERVER_NAME}"

    if [ -f "$cert_path/fullchain.pem" ]; then
        SSL_CONFIGURED=true
        print_success "SSL certificates found for ${SERVER_NAME}"

        local expiry_date=$(openssl x509 -in "$cert_path/fullchain.pem" -noout -enddate 2>/dev/null | cut -d= -f2)
        if [ -n "$expiry_date" ]; then
            print_info "Certificate valid until: $expiry_date"

            local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry_date" +%s 2>/dev/null || echo "0")
            local now_epoch=$(date +%s)
            local days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))

            if [ "$days_left" -lt 30 ] && [ "$days_left" -gt 0 ]; then
                print_warning "Certificate expires in $days_left days - renewal recommended"
                print_info "Auto-renewal runs twice daily via certbot container"
            elif [ "$days_left" -le 0 ]; then
                SSL_CONFIGURED=false
                print_error "Certificate has EXPIRED!"
                print_info "Run: docker compose $COMPOSE_FILES run --rm certbot renew"
            fi
        fi
        return
    fi

    print_warning "No SSL certificates found for ${SERVER_NAME}"
    echo ""

    if [ "$USES_CLOUDFLARE" = true ]; then
        echo -e "${YELLOW}╔═════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║           CLOUDFLARE DETECTED                           ║${NC}"
        echo -e "${YELLOW}╚═════════════════════════════════════════════════════════╝${NC}\n"

        if [ "$CLOUDFLARE_PROXIED" = true ]; then
            echo -e "${RED}⚠️  Your domain is PROXIED through Cloudflare (orange cloud)${NC}"
            echo -e "${YELLOW}Let's Encrypt HTTP validation will fail with proxy enabled.${NC}\n"

            echo -e "${BLUE}You have 3 SSL options:${NC}\n"
            echo -e "${GREEN}1.${NC} ${YELLOW}Temporarily disable Cloudflare proxy${NC} (RECOMMENDED)"
            echo -e "   • Go to Cloudflare Dashboard → DNS"
            echo -e "   • Click orange cloud next to ${SERVER_NAME} → Make it gray"
            echo -e "   • Wait 2-3 minutes for DNS propagation"
            echo -e "   • Get Let's Encrypt certificate"
            echo -e "   • Re-enable proxy (orange cloud) after"
            echo -e "   • Set SSL mode to 'Full (strict)'"
            echo -e ""
            echo -e "${GREEN}2.${NC} ${CYAN}Use Cloudflare Origin Certificate${NC}"
            echo -e "   • Valid for 15 years"
            echo -e "   • Works with proxy enabled"
            echo -e "   • Get at: Cloudflare → SSL/TLS → Origin Server"
            echo -e ""
            echo -e "${GREEN}3.${NC} ${BLUE}Skip SSL for now${NC}"
            echo -e "   • Use Cloudflare Flexible SSL (less secure)"
            echo -e "   • HTTP only between Cloudflare and server"
            echo -e ""

            local choice=$(prompt_input "Choose option (1/2/3)" "1")

            case $choice in
                1)
                    echo -e "\n${YELLOW}═══════════════════════════════════════════════════════${NC}"
                    echo -e "${YELLOW}PLEASE DISABLE CLOUDFLARE PROXY NOW:${NC}"
                    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}\n"
                    echo -e "1. Open: ${CYAN}https://dash.cloudflare.com${NC}"
                    echo -e "2. Select your domain: ${GREEN}${SERVER_NAME}${NC}"
                    echo -e "3. Go to: ${CYAN}DNS → Records${NC}"
                    echo -e "4. Find A record for: ${GREEN}${SERVER_NAME}${NC}"
                    echo -e "5. Click ${YELLOW}orange cloud${NC} → Make it ${BLUE}gray (DNS only)${NC}"
                    echo -e "6. Wait ${RED}2-3 minutes${NC} for DNS propagation"
                    echo -e ""

                    local ready=$(prompt_yn "Have you disabled the proxy and waited 2-3 minutes?" "n")

                    if [ "$ready" == "y" ]; then
                        request_letsencrypt_cert

                        if [ -f "$cert_path/fullchain.pem" ]; then
                            SSL_CONFIGURED=true
                            echo -e "\n${GREEN}✓ Certificates obtained successfully!${NC}\n"
                            echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
                            echo -e "${YELLOW}FINAL STEPS:${NC}"
                            echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}\n"
                            echo -e "1. Re-enable Cloudflare proxy:"
                            echo -e "   • Go back to Cloudflare DNS settings"
                            echo -e "   • Click ${BLUE}gray cloud${NC} → Make it ${YELLOW}orange${NC}"
                            echo -e ""
                            echo -e "2. Set SSL mode to 'Full (strict)':"
                            echo -e "   • Cloudflare → ${CYAN}SSL/TLS${NC} → Overview"
                            echo -e "   • Select: ${GREEN}Full (strict)${NC}"
                            echo -e ""
                            print_tip "This enables end-to-end encryption!"
                        fi
                    else
                        print_warning "SSL setup cancelled - proxy not disabled"
                        print_info "You can configure SSL later when ready"
                    fi
                    ;;
                2)
                    setup_cloudflare_origin_cert
                    ;;
                3)
                    print_warning "Skipping SSL certificate setup"
                    echo -e "${BLUE}Using Cloudflare Flexible SSL:${NC}"
                    echo -e "• Go to Cloudflare → SSL/TLS → Overview"
                    echo -e "• Select: ${YELLOW}Flexible${NC}"
                    echo -e "${RED}⚠️  Note: Traffic between Cloudflare and server is NOT encrypted${NC}"
                    ;;
                *)
                    print_warning "Invalid choice, skipping SSL setup"
                    ;;
            esac
        else
            print_success "Domain is DNS-only (gray cloud) - Let's Encrypt will work!"
            echo ""
            local proceed=$(prompt_yn "Request Let's Encrypt certificates?" "y")

            if [ "$proceed" == "y" ]; then
                request_letsencrypt_cert
            fi
        fi
    else
        print_info "Cloudflare not detected - using standard Let's Encrypt"
        echo ""

        local server_ip=$(curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || echo "unknown")
        local domain_ip=$(dig +short "$SERVER_NAME" 2>/dev/null | grep -E '^[0-9]+\.' | head -n1)

        echo -e "Server IP:  ${GREEN}$server_ip${NC}"
        echo -e "Domain IP:  ${CYAN}$domain_ip${NC}"
        echo ""

        if [ "$server_ip" != "$domain_ip" ] && [ "$server_ip" != "unknown" ] && [ "$domain_ip" != "" ]; then
            print_error "DNS mismatch! Domain does not point to this server"
            print_warning "Let's Encrypt validation will likely fail"
            echo ""
            echo -e "${BLUE}To fix this:${NC}"
            echo -e "• Update your DNS A record for ${GREEN}$SERVER_NAME${NC}"
            echo -e "• Point it to: ${GREEN}$server_ip${NC}"
            echo -e "• Wait a few minutes for DNS propagation"
            echo -e ""
            local continue=$(prompt_yn "Continue anyway?" "n")
            [ "$continue" != "y" ] && return
        else
            SSL_CONFIGURED=true
            print_success "DNS correctly points to this server"
        fi

        local request=$(prompt_yn "Request Let's Encrypt certificates?" "y")

        if [ "$request" == "y" ]; then
            request_letsencrypt_cert
        fi
    fi
}

setup_cloudflare_origin_cert() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}CLOUDFLARE ORIGIN CERTIFICATE SETUP${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"

    echo -e "${BLUE}Follow these steps:${NC}\n"
    echo -e "1. Open: ${GREEN}https://dash.cloudflare.com${NC}"
    echo -e "2. Select your domain: ${GREEN}${SERVER_NAME}${NC}"
    echo -e "3. Go to: ${CYAN}SSL/TLS${NC} → ${CYAN}Origin Server${NC}"
    echo -e "4. Click: ${GREEN}Create Certificate${NC}"
    echo -e "5. Keep defaults (15 year validity)"
    echo -e "6. Click: ${GREEN}Create${NC}"
    echo -e "7. You'll see two text boxes:"
    echo -e "   • Origin Certificate (PEM format)"
    echo -e "   • Private Key"
    echo -e ""

    local ready=$(prompt_yn "Are you ready with the certificate and key?" "n")

    if [ "$ready" != "y" ]; then
        print_warning "Cloudflare Origin Certificate setup cancelled"
        return
    fi

    mkdir -p "./data/certbot/conf/live/${SERVER_NAME}"

    echo -e "\n${BLUE}Paste the ORIGIN CERTIFICATE (fullchain.pem):${NC}"
    echo -e "${YELLOW}(Paste the entire certificate including BEGIN/END lines, then press Ctrl+D on a new line)${NC}\n"
    cat > "./data/certbot/conf/live/${SERVER_NAME}/fullchain.pem"

    echo -e "\n${BLUE}Paste the PRIVATE KEY (privkey.pem):${NC}"
    echo -e "${YELLOW}(Paste the entire key including BEGIN/END lines, then press Ctrl+D on a new line)${NC}\n"
    cat > "./data/certbot/conf/live/${SERVER_NAME}/privkey.pem"

    chmod 644 "./data/certbot/conf/live/${SERVER_NAME}/fullchain.pem"
    chmod 600 "./data/certbot/conf/live/${SERVER_NAME}/privkey.pem"

    if openssl x509 -in "./data/certbot/conf/live/${SERVER_NAME}/fullchain.pem" -noout -text &>/dev/null; then
        SSL_CONFIGURED=true
        print_success "Cloudflare Origin Certificate configured successfully!"

        print_info "Reloading nginx with new certificate..."
        dc exec webserver nginx -s reload 2>/dev/null || dc restart webserver || true

        echo -e "\n${YELLOW}═══════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}IMPORTANT: Set Cloudflare SSL Mode${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}\n"
        echo -e "1. Go to: Cloudflare → ${CYAN}SSL/TLS${NC} → Overview"
        echo -e "2. Select: ${GREEN}Full (strict)${NC}"
        echo -e "3. This enables end-to-end encryption!"
        echo -e ""
        print_tip "Origin Certificates are valid for 15 years - no renewal needed!"
    else
        SSL_CONFIGURED=false
        print_error "Invalid certificate format!"
        rm -f "./data/certbot/conf/live/${SERVER_NAME}/fullchain.pem"
        rm -f "./data/certbot/conf/live/${SERVER_NAME}/privkey.pem"
        print_warning "Please try again with correct certificate format"
    fi
}

request_letsencrypt_cert() {
    local email=$(prompt_input "Email for Let's Encrypt notifications" "admin@${SERVER_NAME}")
    local cert_path="./data/certbot/conf/live/${SERVER_NAME}"

    print_info "Preparing to request SSL certificate..."

    # Create directories
    mkdir -p ./data/certbot/conf
    mkdir -p ./data/certbot/www

    # Make sure NO certificates exist (so nginx starts in HTTP-only mode)
    if [ -d "$cert_path" ]; then
        print_info "Removing old certificates to enable HTTP-only mode..."
        rm -rf "$cert_path"
    fi

    # Start/restart webserver (will start in HTTP-only mode)
    print_info "Starting webserver in HTTP-only mode..."
    dc up -d webserver
    sleep 5

    # Test HTTP accessibility
    print_info "Testing HTTP accessibility at ${SERVER_NAME}..."
    local test_response=$(curl -s -o /dev/null -w "%{http_code}" "http://${SERVER_NAME}/" 2>/dev/null || echo "000")

    if [ "$test_response" == "200" ] || [ "$test_response" == "404" ] || [ "$test_response" == "403" ]; then
        print_success "Webserver is accessible via HTTP (status: $test_response)"
    else
        print_warning "Cannot reach http://${SERVER_NAME}/ (status: $test_response)"
        echo ""
        echo -e "${YELLOW}Troubleshooting:${NC}"
        echo -e "  1. Check DNS: ${CYAN}dig +short ${SERVER_NAME}${NC}"
        echo -e "  2. Check firewall: ${CYAN}sudo ufw status${NC}"
        echo -e "  3. Check cloud firewall (Vultr/Hetzner/DO panel)"
        echo ""
        local try_anyway=$(prompt_yn "Try Let's Encrypt anyway?" "n")
        [ "$try_anyway" != "y" ] && return 1
    fi

    print_info "Requesting SSL certificate from Let's Encrypt..."
    echo -e "${YELLOW}This may take 30-60 seconds...${NC}\n"

    # Request certificate (only main domain, not www to simplify)
    if dc run --rm --entrypoint "" certbot certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$email" \
        --agree-tos \
        --no-eff-email \
        --non-interactive \
        -d "$SERVER_NAME"; then

        SSL_CONFIGURED=true

        print_success "SSL certificate obtained successfully!"

        # Restart nginx to switch to SSL mode (it will detect the new certs)
        print_info "Restarting webserver with SSL enabled..."
        dc restart webserver
        sleep 3

        # Verify
        if [ -f "$cert_path/fullchain.pem" ]; then
            local expiry_date=$(openssl x509 -in "$cert_path/fullchain.pem" -noout -enddate 2>/dev/null | cut -d= -f2)
            print_success "Certificate valid until: $expiry_date"
            print_success "HTTPS enabled at https://${SERVER_NAME}"
        fi

        return 0
    else

        SSL_CONFIGURED=false

        print_error "Failed to obtain SSL certificate"
        echo ""
        echo -e "${YELLOW}Common causes:${NC}"
        echo -e "  • DNS not pointing to this server"
        echo -e "  • Port 80 blocked"
        echo -e "  • Rate limit exceeded (5 failures/hour)"
        echo ""
        print_info "The app will work on HTTP for now"
        show_ssl_troubleshooting
        return 1
    fi
}

show_ssl_troubleshooting() {
    echo -e "\n${YELLOW}╔═════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║           SSL TROUBLESHOOTING                           ║${NC}"
    echo -e "${YELLOW}╚═════════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${BLUE}Common issues and solutions:${NC}\n"

    echo -e "${GREEN}1. DNS not pointing to this server${NC}"
    echo -e "   Check DNS: ${CYAN}dig +short $SERVER_NAME${NC}"
    echo -e "   Server IP: ${CYAN}curl -4 ifconfig.me${NC}"
    echo -e "   ${YELLOW}→ Update DNS A record to point to server IP${NC}"
    echo -e ""

    echo -e "${GREEN}2. Cloudflare proxy enabled (orange cloud)${NC}"
    echo -e "   ${YELLOW}→ Temporarily disable proxy (make it gray)${NC}"
    echo -e "   ${YELLOW}→ OR use Cloudflare Origin Certificate instead${NC}"
    echo -e ""

    echo -e "${GREEN}3. Port 80 blocked by firewall${NC}"
    echo -e "   Check: ${CYAN}sudo ufw status${NC}"
    echo -e "   Allow: ${CYAN}sudo ufw allow 80/tcp${NC}"
    echo -e ""

    echo -e "${GREEN}4. Let's Encrypt rate limit${NC}"
    echo -e "   ${YELLOW}→ 5 failed attempts per hour${NC}"
    echo -e "   ${YELLOW}→ Wait 1 hour and try again${NC}"
    echo -e ""

    echo -e "${GREEN}5. Webserver not running${NC}"
    echo -e "   Check: ${CYAN}docker compose $COMPOSE_FILES ps${NC}"
    echo -e "   Start: ${CYAN}docker compose $COMPOSE_FILES up -d webserver${NC}"
    echo -e ""

    print_tip "You can always configure SSL later - the app will work over HTTP"
}

# --- APP_KEY Generation ---
generate_and_sync_app_key() {
    if ! dc exec -T app php artisan key:generate --force; then
        print_error "Failed to generate APP_KEY"
        exit 1
    fi

    print_success "APP_KEY generated in container"
    sleep 2

    APP_KEY=$(dc exec -T app cat .env \
        | grep '^APP_KEY=' \
        | cut -d '=' -f 2- \
        | tr -d '\r\n' \
        | tr -d '"' \
        | tr -d "'")

    if [ -z "$APP_KEY" ]; then
        print_error "Failed to extract APP_KEY"
        APP_KEY=$(dc exec -T app sh -c 'grep "^APP_KEY=" .env | cut -d "=" -f 2-' \
            | tr -d '\r\n' \
            | tr -d '"' \
            | tr -d "'")

        if [ -z "$APP_KEY" ]; then
            print_error "All extraction methods failed"
            dc exec -T app grep APP_KEY .env
            exit 1
        fi
    fi

    if [[ ! "$APP_KEY" =~ ^base64: ]]; then
        print_warning "APP_KEY format might be incorrect: ${APP_KEY:0:20}..."
    else
        print_success "Valid APP_KEY: ${APP_KEY:0:20}..."
    fi

    local escaped_key=$(printf '%s\n' "$APP_KEY" | sed 's/[\/&\\|]/\\&/g')

    for file in "$ENV_FILE" ".env"; do
        if [ -f "$file" ]; then
            cp "$file" "${file}.backup"

            if grep -q '^APP_KEY=' "$file"; then
                sed -i "s|^APP_KEY=.*|APP_KEY=${escaped_key}|" "$file"
            else
                echo "APP_KEY=${escaped_key}" >> "$file"
            fi

            if grep -q "$APP_KEY" "$file"; then
                print_success "APP_KEY updated in $file"
                rm -f "${file}.backup"
            else
                print_error "Failed to update $file"
                mv "${file}.backup" "$file"
            fi
        fi
    done

    print_info "Synchronizing to container..."
    dc cp .env app:/usr/src/app/.env

    print_success "APP_KEY configuration completed"
}

# --- Main Deployment ---
main() {
    local env=${1:-}

    if [ -z "$env" ]; then
        print_error "Usage: $0 [dev|prod]"
        echo -e "\n${BLUE}Examples:${NC}"
        echo -e "  ${GREEN}$0 dev${NC}  - Development environment"
        echo -e "  ${GREEN}$0 prod${NC} - Production environment"
        exit 1
    fi

    if [[ "$env" != "dev" && "$env" != "prod" ]]; then
        print_error "Invalid environment. Use: dev or prod"
        exit 1
    fi

    ENVIRONMENT="$env"
    ENV_FILE=".env"

    if [ "$ENVIRONMENT" == "prod" ]; then
        COMPOSE_FILES="-f docker-compose.yaml -f docker-compose.prod.yaml"
    else
        COMPOSE_FILES="-f docker-compose.yaml -f docker-compose.dev.yaml"
    fi

    print_header "🚀 Laravel Docker Deployment ($ENVIRONMENT)"

    print_step "0/13" "Checking prerequisites..."
    check_requirements

    print_step "1/13" "Configuring environment..."
    setup_env_file

    print_step "2/13" "Stopping existing containers..."
    dc down 2>/dev/null || true
    print_success "Containers stopped"

    print_step "3/13" "Building Docker images..."
    if [ "$ENVIRONMENT" == "prod" ]; then
        dc build --no-cache
    else
        dc build
    fi
    print_success "Images built"

    print_step "4/13" "Checking SSL certificates..."
    check_ssl_certificates

    print_step "5/13" "Starting containers..."
    dc up -d
    print_success "Containers started"

    print_step "6/13" "Waiting for services to be ready..."
    wait_for_service "app"
    wait_for_service "db"
    wait_for_service "caching"

    print_step "7/13" "Installing PHP dependencies..."
    if [ "$ENVIRONMENT" == "prod" ]; then
        dc exec -T app composer install --no-dev --optimize-autoloader --no-interaction
    else
        dc exec -T app composer install --no-interaction
    fi
    print_success "Composer dependencies installed"

    print_step "8/13" "Checking application key..."
    if [ "$NEEDS_KEY_GENERATION" = true ]; then
        generate_and_sync_app_key
    else
        print_success "APP_KEY already configured"
    fi

    if [ "$ENVIRONMENT" == "prod" ]; then
        print_step "9/13" "Installing frontend dependencies..."
        dc exec -T app npm install
        print_success "NPM dependencies installed"

        print_step "10/13" "Building frontend (production)..."
        dc exec -T app npm run build
        print_success "Frontend built"
    else
        print_step "9/13" "Frontend ready (npm/vite managed by container)..."
        print_success "Vite dev server starting on: http://localhost:5173"
        print_step "10/13" "Waiting for Vite to start..."
        sleep 3
        print_success "Frontend ready"
    fi

    print_step "11/13" "Creating storage link..."
    dc exec -T app php artisan storage:link || true
    print_success "Storage linked"

    print_step "12/13" "Running database migrations..."
    if [ "$ENVIRONMENT" == "prod" ]; then
        dc exec -T app php artisan migrate --force
    else
        dc exec -T app php artisan migrate --no-interaction

        echo ""
        local seed_db=$(prompt_yn "Seed database?" "n")
        if [ "$seed_db" == "y" ]; then
            dc exec -T app php artisan db:seed
        fi
    fi
    print_success "Migrations completed"

    print_step "13/13" "Optimizing Laravel..."
    dc exec -T app php artisan config:clear
    dc exec -T app php artisan cache:clear
    dc exec -T app php artisan route:clear
    dc exec -T app php artisan view:clear

    if [ "$ENVIRONMENT" == "prod" ]; then
        dc exec -T app php artisan config:cache
        dc exec -T app php artisan route:cache
        dc exec -T app php artisan view:cache
        dc exec -T app php artisan event:cache
    fi
    print_success "Laravel optimized"

    print_header "✅ Deployment Complete!"

    echo -e "${GREEN}Application Details:${NC}"
    echo -e "  • Name:        ${BLUE}$APP_NAME${NC}"
    echo -e "  • URL:         ${BLUE}$APP_URL${NC}"
    echo -e "  • Environment: ${BLUE}$ENVIRONMENT${NC}"

    echo -e "\n${YELLOW}Container Status:${NC}"
    dc ps

    echo -e "\n${YELLOW}Useful Commands:${NC}"
    echo -e "  • View logs:    ${GREEN}cd $PROJECT_ROOT && docker compose $COMPOSE_FILES logs -f${NC}"
    echo -e "  • Shell access: ${GREEN}cd $PROJECT_ROOT && docker compose $COMPOSE_FILES exec app bash${NC}"
    echo -e "  • Restart:      ${GREEN}cd $PROJECT_ROOT && docker compose $COMPOSE_FILES restart${NC}"
    echo -e "  • Stop:         ${GREEN}cd $PROJECT_ROOT && docker compose $COMPOSE_FILES down${NC}"

    if [ "$ENVIRONMENT" == "dev" ]; then
        echo -e "\n${BLUE}Development URLs:${NC}"
        echo -e "  • Application: ${GREEN}http://localhost${NC}"
        if [ -f "./docker/nginx/dev-cert/cert.pem" ]; then
            echo -e "  • HTTPS:       ${GREEN}https://localhost${NC}"
        fi
        echo -e "  • Vite HMR:    ${GREEN}http://localhost:5173${NC}"
    fi

    if [ "$ENVIRONMENT" == "prod" ]; then
        echo -e "\n${BLUE}Production Status:${NC}"

        if [ "$SSL_CONFIGURED" = true ]; then
            echo -e "  • SSL:    ${GREEN}✓ Configured${NC}"
            echo -e "  • URL:    ${GREEN}https://${SERVER_NAME}${NC}"
        else
            echo -e "  • SSL:    ${RED}✗ Not configured${NC}"
            echo -e "  • URL:    ${YELLOW}http://${SERVER_NAME}${NC}"
        fi

        if [ "$USES_CLOUDFLARE" = true ]; then
            echo -e "  • CDN:    ${GREEN}✓ Cloudflare${NC}"

            if [ "$CLOUDFLARE_PROXIED" = true ]; then
                echo -e "  • Proxy:  ${GREEN}✓ Enabled (orange cloud)${NC}"
                if [ "$SSL_CONFIGURED" = true ]; then
                    print_tip "Ensure Cloudflare SSL mode is set to 'Full (strict)'"
                else
                    print_tip "You can use Cloudflare Flexible SSL for now"
                fi
            else
                echo -e "  • Proxy:  ${BLUE}○ DNS only (gray cloud)${NC}"
            fi
        fi

        echo -e "\n${RED}⚠️  Production Checklist:${NC}"

        if [ "$SSL_CONFIGURED" = true ]; then
            echo -e "  ${GREEN}1. SSL configured ✓${NC}"
        else
            echo -e "  ${RED}1. Configure SSL (HIGH PRIORITY!)${NC}"
            echo -e "     Run the deploy script again and choose SSL setup"
        fi

        echo -e "  2. Setup automated backups"
        echo -e "  3. Configure monitoring"
        echo -e "  4. Review firewall rules"

        if [ "$SSL_CONFIGURED" = true ]; then
            echo -e "  5. Test SSL: ${CYAN}https://www.ssllabs.com/ssltest/analyze.html?d=${SERVER_NAME}${NC}"
        fi
    fi

    echo ""
}

# Cleanup trap
cleanup_deploy() {
    if [ $? -ne 0 ]; then
        print_error "Deployment failed!"
        echo -e "\n${YELLOW}Debugging commands:${NC}"
        echo -e "  • cd $PROJECT_ROOT && docker compose $COMPOSE_FILES logs"
        echo -e "  • cd $PROJECT_ROOT && docker compose $COMPOSE_FILES ps"
        echo -e "  • cd $PROJECT_ROOT && docker compose $COMPOSE_FILES down -v"
    fi
}
trap cleanup_deploy EXIT

# Run
main "$@"
