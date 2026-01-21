#!/bin/bash
set -euo pipefail

# ==========================================
# Quick Update Script - Zero Downtime
# For minor updates without rebuild
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

print_step() {
    echo -e "\n${YELLOW}[$1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Load environment
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

source .env
export APP_NAME

# Detect environment
if grep -q "APP_ENV=production" .env 2>/dev/null; then
    COMPOSE_FILES="-f docker-compose.yaml -f docker-compose.prod.yaml"
    ENV="prod"
else
    COMPOSE_FILES="-f docker-compose.yaml -f docker-compose.dev.yaml"
    ENV="dev"
fi

# Show menu
show_menu() {
    clear
    print_header "🔄 Quick Update ($ENV)"

    echo -e "${YELLOW}Update type:${NC}\n"
    echo "  1) Code only (views, controllers) - 10-20s"
    echo "  2) Frontend (assets, JS, CSS) - 30-60s"
    echo "  3) Backend (composer dependencies) - 1-2 min"
    echo "  4) Database (migrations) - Variable"
    echo "  5) Configuration (.env, config) - 10-20s"
    echo "  6) Full update (without rebuild) - 2-3 min"
    echo ""
    echo "  7) Restart specific service"
    echo "  8) Full rebuild (with downtime)"
    echo ""
    echo "  0) Cancel"
    echo ""
}

# Update code only (views, controllers)
update_code() {
    print_step "1" "Syncing code..."

    # Code is already up-to-date via Docker volume mount
    # Just force reload
    print_info "Code automatically synced via Docker volumes"

    # Clear caches
    print_step "2" "Clearing caches..."
    docker compose $COMPOSE_FILES exec -T app php artisan view:clear
    docker compose $COMPOSE_FILES exec -T app php artisan cache:clear

    if [ "$ENV" == "prod" ]; then
        docker compose $COMPOSE_FILES exec -T app php artisan config:cache
        docker compose $COMPOSE_FILES exec -T app php artisan route:cache
        docker compose $COMPOSE_FILES exec -T app php artisan view:cache
    fi

    print_success "Code updated (zero downtime)"
}

# Update frontend
update_frontend() {
    print_step "1" "Installing NPM dependencies..."
    docker compose $COMPOSE_FILES exec -T app npm ci

    if [ "$ENV" == "prod" ]; then
        print_step "2" "Building assets (production)..."
        docker compose $COMPOSE_FILES exec -T app npm run build
    else
        print_step "2" "Restarting Vite dev server..."
        docker compose $COMPOSE_FILES restart app
        sleep 3
        docker compose $COMPOSE_FILES exec -d app npm run dev
    fi

    print_success "Frontend updated"
}

# Update backend dependencies
update_backend() {
    print_step "1" "Installing Composer dependencies..."

    if [ "$ENV" == "prod" ]; then
        docker compose $COMPOSE_FILES exec -T app composer install --no-dev --optimize-autoloader --no-interaction
    else
        docker compose $COMPOSE_FILES exec -T app composer install --no-interaction
    fi

    print_step "2" "Optimizing..."
    docker compose $COMPOSE_FILES exec -T app php artisan optimize

    print_success "Backend updated"
}

# Update database
update_database() {
    print_step "1" "Running migrations..."

    if [ "$ENV" == "prod" ]; then
        echo -e "${YELLOW}Migrations will run in production.${NC}"
        read -p "Continue? (yes/no): " confirm

        if [ "$confirm" != "yes" ]; then
            echo -e "${YELLOW}Migration cancelled${NC}"
            return
        fi

        docker compose $COMPOSE_FILES exec -T app php artisan migrate --force
    else
        docker compose $COMPOSE_FILES exec -T app php artisan migrate --no-interaction
    fi

    print_success "Database updated"
}

# Update configuration
update_config() {
    print_step "1" "Reloading configuration..."

    docker compose $COMPOSE_FILES exec -T app php artisan config:clear
    docker compose $COMPOSE_FILES exec -T app php artisan cache:clear

    if [ "$ENV" == "prod" ]; then
        docker compose $COMPOSE_FILES exec -T app php artisan config:cache
    fi

    print_success "Configuration updated"
}

# Update all (without rebuild)
update_all() {
    print_step "1/6" "Updating code..."
    update_code

    print_step "2/6" "Updating Composer dependencies..."
    update_backend

    print_step "3/6" "Updating frontend..."
    update_frontend

    print_step "4/6" "Running database migrations..."
    update_database

    print_step "5/6" "Optimizing Laravel..."
    docker compose $COMPOSE_FILES exec -T app php artisan optimize

    print_step "6/6" "Cleaning up..."
    docker compose $COMPOSE_FILES exec -T app php artisan view:clear

    print_success "Full update completed"
}

# Restart specific service
restart_service() {
    echo -e "\n${YELLOW}Available services:${NC}"
    echo "  - app (PHP-FPM)"
    echo "  - webserver (Nginx)"
    echo "  - db (MySQL)"
    echo "  - caching (Redis)"
    echo "  - supervisor (Horizon)"
    echo "  - scheduler"
    echo ""

    read -p "Service to restart: " service

    if [ -z "$service" ]; then
        echo -e "${RED}No service specified${NC}"
        return
    fi

    print_step "1" "Restarting $service..."

    # Graceful restart for app service
    if [ "$service" == "app" ]; then
        print_info "Graceful restart (zero downtime)..."
        docker compose $COMPOSE_FILES exec app php artisan optimize
        docker compose $COMPOSE_FILES restart app
    else
        docker compose $COMPOSE_FILES restart $service
    fi

    sleep 2

    # Check if service is running
    if docker compose $COMPOSE_FILES ps | grep -q "${service}.*running"; then
        print_success "$service restarted successfully"
    else
        echo -e "${RED}Error restarting $service${NC}"
        echo -e "${YELLOW}Check logs:${NC} docker compose $COMPOSE_FILES logs $service"
    fi
}

# Full rebuild
full_rebuild() {
    echo -e "\n${RED}⚠️  WARNING: Full rebuild with service interruption${NC}"
    echo -e "${YELLOW}This operation will:${NC}"
    echo "  - Stop all containers"
    echo "  - Rebuild Docker images"
    echo "  - Restart all services"
    echo ""
    read -p "Continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Rebuild cancelled${NC}"
        return
    fi

    print_step "1" "Use ./scripts/deploy.sh instead..."
    echo -e "${BLUE}For a full rebuild, use:${NC}"
    echo -e "${GREEN}./scripts/deploy.sh $ENV${NC}"
}

# Main script
print_header "🔄 Quick Update - Laravel Docker"

echo -e "${BLUE}Detected environment: ${GREEN}$ENV${NC}"
echo -e "${BLUE}Application: ${GREEN}$APP_NAME${NC}\n"

show_menu

read -p "Choose an option: " choice

case $choice in
    1)
        print_header "📝 Code Update"
        update_code
        ;;
    2)
        print_header "🎨 Frontend Update"
        update_frontend
        ;;
    3)
        print_header "📦 Backend Update"
        update_backend
        ;;
    4)
        print_header "🗄️ Database Update"
        update_database
        ;;
    5)
        print_header "⚙️ Configuration Update"
        update_config
        ;;
    6)
        print_header "🔄 Full Update"
        update_all
        ;;
    7)
        print_header "🔄 Service Restart"
        restart_service
        ;;
    8)
        full_rebuild
        ;;
    0)
        echo -e "${YELLOW}Cancelled${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
print_success "Operation completed!"

# Show running containers
echo -e "\n${YELLOW}Running containers:${NC}"
docker compose $COMPOSE_FILES ps

echo ""

cleanup() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Update failed! Check logs for details${NC}"
        # Rollback logic could be added here
    fi
}
trap cleanup EXIT
