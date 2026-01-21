#!/bin/bash
set -euo pipefail

# ==========================================
# Laravel Helper Scripts Collection
# Quick access to common Laravel operations
# Usage: ./scripts/laravel-helper.sh
# ==========================================

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Navigate to project root
cd "$PROJECT_ROOT"

# Load environment
load_env

# Detect compose files
COMPOSE_FILES=$(detect_compose_files)

# Detect environment
if grep -q "APP_ENV=production" .env 2>/dev/null; then
    ENV="prod"
else
    ENV="dev"
fi

# --- Helper Functions ---
run_artisan() {
    dc exec -T app php artisan "$@"
}

run_composer() {
    dc exec -T app composer "$@"
}

run_npm() {
    dc exec app npm "$@"
}

# --- Menu Functions ---
show_menu() {
    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Laravel Docker Utilities ($ENV)${NC}"
    echo -e "${GREEN}  Project: ${BLUE}$APP_NAME${NC}"
    echo -e "${GREEN}========================================${NC}\n"

    echo -e "${YELLOW}Container Management:${NC}"
    echo "  1) Start containers"
    echo "  2) Stop containers"
    echo "  3) Restart containers"
    echo "  4) View logs (all)"
    echo "  5) View logs (specific service)"
    echo "  6) Container status"
    echo ""

    echo -e "${YELLOW}Laravel Operations:${NC}"
    echo "  7) Run migrations"
    echo "  8) Rollback migrations"
    echo "  9) Seed database"
    echo " 10) Clear all caches"
    echo " 11) Optimize Laravel"
    echo " 12) Generate APP_KEY"
    echo " 13) Storage link"
    echo " 14) Run tests"
    echo ""

    echo -e "${YELLOW}Database Operations:${NC}"
    echo " 15) MySQL CLI"
    echo " 16) Backup database"
    echo " 17) Restore database"
    echo " 18) Fresh migration (⚠️  WARNING)"
    echo ""

    echo -e "${YELLOW}Development Tools:${NC}"
    echo " 19) Bash into app container"
    echo " 20) Composer install"
    echo " 21) Composer update"
    echo " 22) NPM install"
    echo " 23) NPM build"
    echo " 24) Run queue worker"
    echo " 25) Tinker"
    echo ""

    echo -e "${YELLOW}Monitoring:${NC}"
    echo " 26) Horizon dashboard"
    echo " 27) View supervisor status"
    echo " 28) Check disk usage"
    echo ""

    echo " 0) Exit"
    echo ""

    read -p "Select option (or type to search): " choice
    echo ""
}

# --- Operation Functions ---
start_containers() {
    print_info "Starting containers..."
    dc up -d
    print_success "Containers started"
}

stop_containers() {
    print_info "Stopping containers..."
    dc down
    print_success "Containers stopped"
}

restart_containers() {
    print_info "Restarting containers..."
    dc restart
    print_success "Containers restarted"
}

view_logs() {
    dc logs -f
}

view_service_logs() {
    echo -e "${YELLOW}Available services: app, webserver, db, caching, supervisor, scheduler${NC}"
    read -p "Enter service name: " service
    dc logs -f $service
}

container_status() {
    dc ps
}

run_migrations() {
    print_info "Running migrations..."
    run_artisan migrate
    print_success "Migrations completed"
}

rollback_migrations() {
    echo -e "${YELLOW}How many steps to rollback?${NC}"
    read -p "Steps [1]: " steps
    steps=${steps:-1}
    print_info "Rolling back $steps step(s)..."
    run_artisan migrate:rollback --step=$steps
    print_success "Rollback completed"
}

seed_database() {
    print_info "Seeding database..."
    run_artisan db:seed
    print_success "Database seeded"
}

clear_caches() {
    print_info "Clearing all caches..."
    run_artisan config:clear
    run_artisan cache:clear
    run_artisan route:clear
    run_artisan view:clear
    print_success "All caches cleared"
}

optimize_laravel() {
    print_info "Optimizing Laravel..."
    run_artisan config:cache
    run_artisan route:cache
    run_artisan view:cache
    run_artisan event:cache
    print_success "Laravel optimized"
}

generate_key() {
    print_info "Generating APP_KEY..."
    run_artisan key:generate
    print_success "APP_KEY generated"
}

storage_link() {
    print_info "Creating storage link..."
    run_artisan storage:link
    print_success "Storage link created"
}

run_tests() {
    print_info "Running tests..."
    dc exec -T app php artisan test
}

mysql_cli() {
    print_info "Opening MySQL CLI..."
    dc exec db mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE
}

backup_database() {
    BACKUP_DIR="$PROJECT_ROOT/backups"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/db_backup_$(date +%Y%m%d_%H%M%S).sql"

    print_info "Backing up database to $BACKUP_FILE..."
    dc exec -T db mysqldump -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > "$BACKUP_FILE"
    print_success "Database backed up to $BACKUP_FILE"
}

restore_database() {
    BACKUP_DIR="$PROJECT_ROOT/backups"

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        print_error "No backups found in $BACKUP_DIR"
        return
    fi

    echo -e "${YELLOW}Available backups:${NC}"
    ls -1 "$BACKUP_DIR"
    echo ""
    read -p "Enter backup filename: " backup_file

    if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        print_error "Backup file not found"
        return
    fi

    echo -e "${RED}⚠️  WARNING: This will replace the current database!${NC}"
    read -p "Are you sure? (yes/no): " confirm

    if [ "$confirm" == "yes" ]; then
        print_info "Restoring database from $backup_file..."
        dc exec -T db mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < "$BACKUP_DIR/$backup_file"
        print_success "Database restored"
    else
        print_warning "Restore cancelled"
    fi
}

fresh_migration() {
    echo -e "${RED}⚠️  WARNING: This will DROP ALL TABLES and re-run migrations!${NC}"
    read -p "Are you absolutely sure? Type 'yes' to confirm: " confirm

    if [ "$confirm" == "yes" ]; then
        print_info "Running fresh migration..."
        run_artisan migrate:fresh --seed
        print_success "Fresh migration completed"
    else
        print_warning "Operation cancelled"
    fi
}

bash_container() {
    print_info "Opening bash in app container..."
    dc exec app bash
}

composer_install() {
    print_info "Running composer install..."
    run_composer install
    print_success "Composer install completed"
}

composer_update() {
    print_info "Running composer update..."
    run_composer update
    print_success "Composer update completed"
}

npm_install() {
    print_info "Running npm install..."
    run_npm install
    print_success "NPM install completed"
}

npm_build() {
    print_info "Building frontend assets..."
    run_npm run build
    print_success "Frontend build completed"
}

queue_worker() {
    print_info "Starting queue worker..."
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    run_artisan queue:work
}

tinker_shell() {
    print_info "Opening Tinker..."
    dc exec app php artisan tinker
}

horizon_dashboard() {
    print_info "Horizon dashboard URL:"
    echo -e "${GREEN}$APP_URL/horizon${NC}"
}

supervisor_status() {
    print_info "Supervisor status:"
    dc exec supervisor supervisorctl status
}

disk_usage() {
    print_info "Disk usage:"
    echo ""
    echo -e "${YELLOW}Docker volumes:${NC}"
    docker system df -v
    echo ""
    echo -e "${YELLOW}Local storage:${NC}"
    du -sh storage/* 2>/dev/null || echo "No storage directory"
}

# --- Main Loop ---
main() {
    while true; do
        show_menu

        case $choice in
            1) start_containers ;;
            2) stop_containers ;;
            3) restart_containers ;;
            4) view_logs ;;
            5) view_service_logs ;;
            6) container_status ;;
            7) run_migrations ;;
            8) rollback_migrations ;;
            9) seed_database ;;
            10) clear_caches ;;
            11) optimize_laravel ;;
            12) generate_key ;;
            13) storage_link ;;
            14) run_tests ;;
            15) mysql_cli ;;
            16) backup_database ;;
            17) restore_database ;;
            18) fresh_migration ;;
            19) bash_container ;;
            20) composer_install ;;
            21) composer_update ;;
            22) npm_install ;;
            23) npm_build ;;
            24) queue_worker ;;
            25) tinker_shell ;;
            26) horizon_dashboard ;;
            27) supervisor_status ;;
            28) disk_usage ;;
            0)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac

        echo ""
        read -p "Press enter to continue..."
    done
}

main
