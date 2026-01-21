#!/bin/bash

# ==========================================
# Automated Database Backup Script
# Usage: ./backup.sh [manual|auto]
# ==========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="./backups"
RETENTION_DAYS=30
MAX_BACKUPS=50

# Load environment
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

source .env

# Detect compose files
if grep -q "APP_ENV=production" .env 2>/dev/null; then
    COMPOSE_FILES="-f docker-compose.yaml -f docker-compose.prod.yaml"
else
    COMPOSE_FILES="-f docker-compose.yaml -f docker-compose.dev.yaml"
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_STR=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/${APP_NAME}_${TIMESTAMP}.sql"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Database Backup for ${APP_NAME}${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if database container is running
if ! docker compose $COMPOSE_FILES ps | grep -q "db_${APP_NAME}.*running"; then
    echo -e "${RED}Error: Database container is not running${NC}"
    exit 1
fi

# Perform backup
echo -e "${YELLOW}Starting backup...${NC}"
echo -e "Database: ${BLUE}${DB_DATABASE}${NC}"
echo -e "File: ${BLUE}${BACKUP_FILE}${NC}\n"

if docker compose $COMPOSE_FILES exec -T db mysqldump \
    -u"${DB_USERNAME}" \
    -p"${DB_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    "${DB_DATABASE}" > "${BACKUP_FILE}"; then

    # Compress backup
    echo -e "${YELLOW}Compressing backup...${NC}"
    if gzip -k "${BACKUP_FILE}"; then  # -k keep original
        rm "${BACKUP_FILE}"  # delete original after success
    fi
    BACKUP_FILE="${BACKUP_FILE}.gz"

    # Get file size
    FILE_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)

    echo -e "\n${GREEN}✓ Backup completed successfully${NC}"
    echo -e "File: ${BLUE}${BACKUP_FILE}${NC}"
    echo -e "Size: ${BLUE}${FILE_SIZE}${NC}\n"

    # Clean old backups
    echo -e "${YELLOW}Cleaning old backups...${NC}"

    # Remove backups older than RETENTION_DAYS
    find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete

    # Keep only MAX_BACKUPS most recent files
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        REMOVE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
        ls -1t "$BACKUP_DIR"/*.sql.gz | tail -n "$REMOVE_COUNT" | xargs rm -f
        echo -e "${GREEN}✓ Removed $REMOVE_COUNT old backup(s)${NC}"
    fi

    # Summary
    REMAINING_BACKUPS=$(ls -1 "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l)
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

    echo -e "\n${BLUE}Backup Summary:${NC}"
    echo -e "Total backups: ${GREEN}${REMAINING_BACKUPS}${NC}"
    echo -e "Total size: ${GREEN}${TOTAL_SIZE}${NC}"
    echo -e "Retention: ${GREEN}${RETENTION_DAYS} days${NC}"

    # Create backup log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup completed: ${BACKUP_FILE} (${FILE_SIZE})" >> "$BACKUP_DIR/backup.log"

else
    echo -e "\n${RED}✗ Backup failed${NC}"
    exit 1
fi

# Optional: Upload to S3 or remote storage
# Uncomment and configure if needed
# if [ -n "$AWS_BUCKET" ]; then
#     echo -e "\n${YELLOW}Uploading to S3...${NC}"
#     aws s3 cp "${BACKUP_FILE}" "s3://${AWS_BUCKET}/backups/${APP_NAME}/"
#     echo -e "${GREEN}✓ Uploaded to S3${NC}"
# fi

echo ""
