#!/bin/bash

# ==========================================
# Common Functions Library
# Sourced by all scripts in /scripts/
# ==========================================

# --- Paths ---
# Script directory (where this common.sh is located)
SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Scripts directory (parent of lib/)
SCRIPTS_DIR="$(dirname "$SCRIPT_LIB_DIR")"
# Project root directory (parent of scripts/)
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"

# --- Colors ---
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export NC='\033[0m'

# --- Print Functions ---
print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

print_step() {
    echo -e "\n${CYAN}[$1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_tip() {
    echo -e "${MAGENTA}💡 TIP: $1${NC}"
}

# --- Input Functions ---
prompt_input() {
    local prompt="$1"
    local default="$2"
    local result

    if [ -n "$default" ]; then
        read -p "$(echo -e ${BLUE}${prompt}${NC} [${GREEN}${default}${NC}]: )" result
        echo "${result:-$default}"
    else
        read -p "$(echo -e ${BLUE}${prompt}${NC}: )" result
        while [ -z "$result" ]; do
            echo -e "${RED}This field is required.${NC}"
            read -p "$(echo -e ${BLUE}${prompt}${NC}: )" result
        done
        echo "$result"
    fi
}

prompt_yn() {
    local prompt="$1"
    local default="${2:-n}"
    local result

    if [ "$default" == "y" ] || [ "$default" == "Y" ]; then
        read -p "$(echo -e ${BLUE}${prompt}${NC} [${GREEN}Y${NC}/n]: )" result
        result="${result:-y}"
    else
        read -p "$(echo -e ${BLUE}${prompt}${NC} [y/${GREEN}N${NC}]: )" result
        result="${result:-n}"
    fi

    echo "$result"
}

# --- Utility Functions ---
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

validate_domain() {
    local domain=$1

    # Allow localhost
    if [ "$domain" == "localhost" ]; then
        return 0
    fi

    # Allow IP addresses
    if [[ $domain =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi

    # Standard domain validation
    if [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        print_error "Invalid domain format: $domain"
        return 1
    fi
    return 0
}

# Check if IP is in CIDR range
check_ip_in_range() {
    local ip=$1
    local cidr=$2

    local network=${cidr%/*}
    local maskbits=${cidr#*/}

    IFS=. read -r i1 i2 i3 i4 <<< "$ip"
    local ip_int=$(( (i1<<24) + (i2<<16) + (i3<<8) + i4 ))

    IFS=. read -r n1 n2 n3 n4 <<< "$network"
    local net_int=$(( (n1<<24) + (n2<<16) + (n3<<8) + n4 ))

    local mask=$(( 0xFFFFFFFF << (32-maskbits) & 0xFFFFFFFF ))

    if (( (ip_int & mask) == (net_int & mask) )); then
        return 0
    else
        return 1
    fi
}

# --- Docker Functions ---
detect_compose_files() {
    # Load environment from project root
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env"
        export APP_NAME
    fi

    # Detect environment
    if grep -q "APP_ENV=production" "$PROJECT_ROOT/.env" 2>/dev/null; then
        echo "-f docker-compose.yaml -f docker-compose.prod.yaml"
    else
        echo "-f docker-compose.yaml -f docker-compose.dev.yaml"
    fi
}

# Docker compose wrapper that works from any directory
dc() {
    local compose_files=$(detect_compose_files)
    (cd "$PROJECT_ROOT" && docker compose $compose_files "$@")
}

wait_for_service() {
    local service=$1
    local max_attempts=${2:-60}
    local attempt=0

    print_info "Waiting for $service to be healthy..."

    while [ $attempt -lt $max_attempts ]; do
        if dc ps | grep -q "${service}.*healthy"; then
            print_success "$service is healthy"
            return 0
        fi

        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo ""
    print_error "$service failed to become healthy"
    dc logs --tail=50 $service
    return 1
}

# --- Environment Functions ---
load_env() {
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        print_error ".env file not found in project root"
        return 1
    fi

    set -a
    source "$PROJECT_ROOT/.env"
    set +a

    print_success "Environment loaded"
    return 0
}

check_requirements() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        print_info "Running on Windows – skipping Linux-specific checks."

        if ! command -v docker >/dev/null 2>&1; then
            print_error "Docker Desktop for Windows is not installed."
            exit 1
        fi

        if ! command -v dig >/dev/null 2>&1; then
            print_warning "dig not found – DNS checks will be skipped."
        fi

        print_success "All prerequisites met for Windows environment"
        return
    fi

    local missing=()

    command -v docker >/dev/null 2>&1 || missing+=("docker")
    command -v git >/dev/null 2>&1 || missing+=("git")
    command -v dig >/dev/null 2>&1 || missing+=("dnsutils")
    command -v openssl >/dev/null 2>&1 || missing+=("openssl")

    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Missing requirements: ${missing[*]}"

        if [[ " ${missing[*]} " =~ " docker " ]]; then
            local install=$(prompt_yn "Install Docker now?" "n")

            if [ "$install" == "y" ]; then
                print_info "Installing Docker..."
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                print_success "Docker installed"
            else
                exit 1
            fi
        fi

        if [[ " ${missing[*]} " =~ " dnsutils " ]] || [[ " ${missing[*]} " =~ " openssl " ]]; then
            sudo apt-get update
            sudo apt-get install -y dnsutils openssl
        fi
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose v2 is not installed"
        echo -e "${BLUE}To install Docker Compose v2:${NC}"
        echo -e "  Ubuntu/Debian: ${GREEN}sudo apt install docker-compose-plugin${NC}"
        echo -e "  macOS:         ${GREEN}brew install docker-compose${NC}"
        echo -e "  Or see: ${CYAN}https://docs.docker.com/compose/install/${NC}"
        exit 1
    fi

    print_success "All prerequisites met"
}

# --- Error Handling ---
error_exit() {
    print_error "$1"
    exit "${2:-1}"
}

# Cleanup on error
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Script failed with exit code $exit_code"
    fi
}

# Export all functions for use in other scripts
export -f print_header print_step print_success print_error print_warning print_info print_tip
export -f prompt_input prompt_yn
export -f generate_password validate_domain check_ip_in_range
export -f detect_compose_files dc wait_for_service
export -f load_env check_requirements
export -f error_exit cleanup
