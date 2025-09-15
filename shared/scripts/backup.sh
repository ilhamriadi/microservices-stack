#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ENVIRONMENT=${1:-production}
COMPOSE_FILE="compose/${ENVIRONMENT}.yml"
BACKUP_DIR="./shared/backup"
DATE=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}💾 Starting backup process - $(date)${NC}"
echo -e "${BLUE}Environment: $ENVIRONMENT${NC}"
echo "=================================================="

# Function to create backup directory
create_backup_dir() {
    echo -e "${YELLOW}📁 Creating backup directories...${NC}"
    
    mkdir -p "$BACKUP_DIR/databases"
    mkdir -p "$BACKUP_DIR/files"
    mkdir -p "$BACKUP_DIR/configs"
    mkdir -p "$BACKUP_DIR/logs"
    
    echo -e "${GREEN}✅ Backup directories created${NC}"
}

# Function to backup databases
backup_databases() {
    echo -e "${YELLOW}🗄️ Backing up databases...${NC}"
    
    # Check if MySQL is running
    if ! docker-compose -f docker-compose.yml -f "$COMPOSE_FILE" ps mysql | grep -q "Up"; then
        echo -e "${RED}❌ MySQL is not running. Cannot backup databases.${NC}"
        return 1
    fi
    
    # Load environment variables
    source .env
    
    # Backup all databases
    echo "Creating full database backup..."
    docker-compose -f docker-compose.yml -f "$COMPOSE_FILE" exec -T mysql mysqldump \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        --all-databases \
        --routines \
        --triggers \
        --single-transaction \
        --lock-tables=false > "$BACKUP_DIR/databases/full_backup_$DATE.sql"
    
    # Backup individual service databases
    databases=("laravel_auth" "laravel_catalog" "express_api")
    
    for db in "${databases[@]}"; do
        echo "Backing up $db database..."
        docker-compose -f docker-compose.yml -f "$COMPOSE_FILE" exec -T mysql mysqldump \
            -u root -p"$MYSQL_ROOT_PASSWORD" \
            --single-transaction \
            --routines \
            --triggers \
            --lock-tables=false \
            "$db" > "$BACKUP_DIR/databases/${db}_backup_$DATE.sql"
    done
    
    echo -e "${GREEN}✅ Database backups completed${NC}"
}

# Function to backup Redis data
backup_redis() {
    echo -e "${YELLOW}📊 Backing up Redis data...${NC}"
    
    # Check if Redis is running
    if ! docker-compose -f docker-compose.yml -f "$COMPOSE_FILE" ps redis | grep -q "Up"; then
        echo -e "${RED}❌ Redis is not running. Cannot backup Redis data.${NC}"
        return 1
    fi
    
    # Create Redis backup
    docker-compose -f docker-compose.yml -f "$COMPOSE_FILE" exec -T redis redis-cli BGSAVE
    
    # Wait for backup to complete
    sleep 5
    
    # Copy dump.rdb file
    docker-compose -f docker-compose.yml -f "$COMPOSE_FILE" exec -T redis cat /data/dump.rdb > "$BACKUP_DIR/databases/redis_backup_$DATE.rdb"
    
    echo -e "${GREEN}✅ Redis backup completed${NC}"
}

# Function to backup application files
backup_files() {
    echo -e "${YELLOW}📄 Backing up application files...${NC}"
    
    # Backup storage directories
    echo "Backing up storage files..."
    if [[ -d "shared/storage" ]]; then
        tar -czf "$BACKUP_DIR/files/storage_backup_$DATE.tar.gz" -C shared storage/
    fi
    
    # Backup uploaded files from each service
    services=("auth" "catalog" "express")
    for service in "${services[@]}"; do
        if [[ -d "shared/storage/$service" ]]; then
            echo "Backing up $service files..."
            tar -czf "$BACKUP_DIR/files/${service}_files_$DATE.tar.gz" -C "shared/storage" "$service/"
        fi
    done
    
    # Backup SSL certificates if they exist
    if [[ -d "shared/nginx/ssl" ]]; then
        echo "Backing up SSL certificates..."
        tar -czf "$BACKUP_DIR/files/ssl_backup_$DATE.tar.gz" -C shared/nginx ssl/
    fi
    
    echo -e "${GREEN}✅ File backups completed${NC}"
}

# Function to backup configurations
backup_configs() {
    echo -e "${YELLOW}⚙️ Backing up configurations...${NC}"
    
    # Create config backup directory for this date
    config_backup_dir="$BACKUP_DIR/configs/config_backup_$DATE"
    mkdir -p "$config_backup_dir"
    
    # Backup Docker Compose files
    cp docker-compose.yml "$config_backup_dir/"
    cp -r compose/ "$config_backup_dir/"
    
    # Backup environment files (without sensitive data)
    echo "Backing up environment configurations..."
    cp .env.example "$config_backup_dir/"
    
    # Backup service environment examples
    find services/ -name ".env.example" -exec cp --parents {} "$config_backup_dir/" \;
    
    # Backup nginx configuration
    if [[ -d "shared/nginx" ]]; then
        cp -r shared/nginx/*.conf "$config_backup_dir/" 2>/dev/null || true
    fi
    
    # Backup database configuration
    if [[ -f "shared/database/my.cnf" ]]; then
        cp shared/database/my.cnf "$config_backup_dir/"
    fi
    
    # Backup scripts
    if [[ -d "shared/scripts" ]]; then
        cp -r shared/scripts "$config_backup_dir/"
    fi
    
    # Create tar archive of configs
    tar -czf "$BACKUP_DIR/configs/configs_backup_$DATE.tar.gz" -C "$BACKUP_DIR/configs" "config_backup_$DATE/"
    rm -rf "$config_backup_dir"
    
    echo -e "${GREEN}✅ Configuration backups completed${NC}"
}

# Function to backup logs
backup_logs() {
    echo -e "${YELLOW}📋 Backing up logs...${NC}"
    
    # Backup nginx logs
    if [[ -d "shared/nginx/logs" ]]; then
        echo "Backing up nginx logs..."
        tar -czf "$BACKUP_DIR/logs/nginx_logs_$DATE.tar.gz" -C shared/nginx logs/
    fi
    
    # Backup application logs
    if [[ -d "logs" ]]; then
        echo "Backing up application logs..."
        tar -czf "$BACKUP_DIR/logs/app_logs_$DATE.tar.gz" logs/
    fi
    
    # Export recent Docker logs
    services=("nginx" "laravel-auth" "laravel-catalog" "express-api" "frontend" "mysql" "redis")
    
    for service in "${services[@]}"; do
        echo "Exporting $service logs..."
        docker-compose -f docker-compose.yml -f "$COMPOSE_FILE" logs --tail=1000 "$service" > "$BACKUP_DIR/logs/${service}_logs_$DATE.log" 2>/dev/null || true
    done
    
    echo -e "${GREEN}✅ Log backups completed${NC}"
}

# Function to create backup manifest
create_manifest() {
    echo -e "${YELLOW}📝 Creating backup manifest...${NC}"
    
    manifest_file="$BACKUP_DIR/backup_manifest_$DATE.txt"
    
    {
        echo "=== BACKUP MANIFEST ==="
        echo "Date: $(date)"
        echo "Environment: $ENVIRONMENT"
        echo "Server: 156.67.24.197"
        echo "========================"
        echo ""
        echo "DATABASES:"
        ls -la "$BACKUP_DIR/databases/"*"$DATE"* 2>/dev/null || echo "No database backups found"
        echo ""
        echo "FILES:"
        ls -la "$BACKUP_DIR/files/"*"$DATE"* 2>/dev/null || echo "No file backups found"
        echo ""
        echo "CONFIGURATIONS:"
        ls -la "$BACKUP_DIR/configs/"*"$DATE"* 2>/dev/null || echo "No config backups found"
        echo ""
        echo "LOGS:"
        ls -la "$BACKUP_DIR/logs/"*"$DATE"* 2>/dev/null || echo "No log backups found"
        echo ""
        echo "CHECKSUMS:"
        find "$BACKUP_DIR" -name "*$DATE*" -type f -exec md5sum {} \; 2>/dev/null
        
    } > "$manifest_file"
    
    echo -e "${GREEN}✅ Backup manifest created: $manifest_file${NC}"
}

# Function to cleanup old backups
cleanup_old_backups() {
    echo -e "${YELLOW}🧹 Cleaning up old backups...${NC}"
    
    # Keep backups for 30 days by default
    RETENTION_DAYS=${2:-30}
    
    echo "Removing backups older than $RETENTION_DAYS days..."
    
    # Clean database backups
    find "$BACKUP_DIR/databases" -name "*.sql" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
    find "$BACKUP_DIR/databases" -name "*.rdb" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
    
    # Clean file backups
    find "$BACKUP_DIR/files" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
    
    # Clean config backups
    find "$BACKUP_DIR/configs" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
    
    # Clean log backups
    find "$BACKUP_DIR/logs" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
    find "$BACKUP_DIR/logs" -name "*.log" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
    
    # Clean old manifests
    find "$BACKUP_DIR" -name "backup_manifest_*.txt" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
    
    echo -e "${GREEN}✅ Old backups cleaned up${NC}"
}

# Function to compress final backup
compress_backup() {
    echo -e "${YELLOW}🗜️ Compressing final backup...${NC}"
    
    # Create final backup archive
    final_backup="$BACKUP_DIR/microservices_backup_$DATE.tar.gz"
    
    tar -czf "$final_backup" \
        -C "$BACKUP_DIR" \
        --exclude="*.tar.gz" \
        --exclude="microservices_backup_*.tar.gz" \
        databases/ files/ configs/ logs/ backup_manifest_$DATE.txt 2>/dev/null || true
    
    # Calculate and display backup size
    backup_size=$(du -h "$final_backup" | cut -f1)
    echo -e "${GREEN}✅ Final backup created: $final_backup ($backup_size)${NC}"
}

# Function to verify backup
verify_backup() {
    echo -e "${YELLOW}🔍 Verifying backup...${NC}"
    
    # Check database backups
    db_backups=($(ls "$BACKUP_DIR/databases/"*"$DATE"*.sql 2>/dev/null))
    for backup in "${db_backups[@]}"; do
        if [[ -s "$backup" ]]; then
            echo -e "Database backup $(basename "$backup"): ${GREEN}✅ Valid${NC}"
        else
            echo -e "Database backup $(basename "$backup"): ${RED}❌ Empty${NC}"
        fi
    done
    
    # Check Redis backup
    redis_backup="$BACKUP_DIR/databases/redis_backup_$DATE.rdb"
    if [[ -f "$redis_backup" ]] && [[ -s "$redis_backup" ]]; then
        echo -e "Redis backup: ${GREEN}✅ Valid${NC}"
    else
        echo -e "Redis backup: ${RED}❌ Missing or empty${NC}"
    fi
    
    # Check file backups
    file_backups=($(ls "$BACKUP_DIR/files/"*"$DATE"*.tar.gz 2>/dev/null))
    for backup in "${file_backups[@]}"; do
        if tar -tzf "$backup" >/dev/null 2>&1; then
            echo -e "File backup $(basename "$backup"): ${GREEN}✅ Valid${NC}"
        else
            echo -e "File backup $(basename "$backup"): ${RED}❌ Corrupted${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Backup verification completed${NC}"
}

# Function to send backup notification (optional)
send_notification() {
    echo -e "${YELLOW}📧 Sending backup notification...${NC}"
    
    # This is optional - you can integrate with email, Slack, or other notification systems
    # For now, just log the completion
    
    backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    
    echo "Backup completed successfully!" > /tmp/backup_notification.txt
    echo "Date: $(date)" >> /tmp/backup_notification.txt
    echo "Environment: $ENVIRONMENT" >> /tmp/backup_notification.txt
    echo "Total backup size: $backup_size" >> /tmp/backup_notification.txt
    
    # Here you could send the notification via email, webhook, etc.
    # Example: curl -X POST -H 'Content-type: application/json' --data '{"text":"Backup completed!"}' YOUR_SLACK_WEBHOOK
    
    echo -e "${GREEN}✅ Notification prepared${NC}"
}

# Main backup function
main() {
    echo -e "${GREEN}Starting comprehensive backup process...${NC}"
    
    create_backup_dir
    backup_databases
    backup_redis
    backup_files
    backup_configs
    backup_logs
    create_manifest
    cleanup_old_backups "$@"
    compress_backup
    verify_backup
    send_notification
    
    echo -e "\n${GREEN}🎉 Backup process completed successfully!${NC}"
    echo -e "${BLUE}Backup location: $BACKUP_DIR${NC}"
    echo -e "${BLUE}Final archive: microservices_backup_$DATE.tar.gz${NC}"
}

# Help function
show_help() {
    echo "Usage: $0 [environment] [retention_days]"
    echo ""
    echo "Arguments:"
    echo "  environment    : Environment to backup (default: production)"
    echo "  retention_days : Number of days to keep old backups (default: 30)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Backup production environment, keep 30 days"
    echo "  $0 staging           # Backup staging environment"
    echo "  $0 production 7      # Backup production, keep only 7 days"
}

# Check arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
