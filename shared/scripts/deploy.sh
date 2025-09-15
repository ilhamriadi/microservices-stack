#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default environment
ENVIRONMENT=${1:-production}
COMPOSE_FILE="compose/${ENVIRONMENT}.yml"

echo -e "${GREEN}🚀 Starting deployment for ${ENVIRONMENT} environment${NC}"

# Function to check if required files exist
check_prerequisites() {
    echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
    
    if [[ ! -f ".env" ]]; then
        echo -e "${RED}❌ .env file not found. Please copy .env.example to .env and configure it.${NC}"
        exit 1
    fi
    
    if [[ ! -f "docker-compose.yml" ]]; then
        echo -e "${RED}❌ docker-compose.yml not found${NC}"
        exit 1
    fi
    
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        echo -e "${RED}❌ ${COMPOSE_FILE} not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to create necessary directories
create_directories() {
    echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
    
    mkdir -p shared/storage/{auth,catalog,express}
    mkdir -p shared/nginx/logs
    mkdir -p shared/database/data
    mkdir -p shared/backup
    mkdir -p logs/{laravel-auth,laravel-catalog,express-api}
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Function to set permissions
set_permissions() {
    echo -e "${YELLOW}🔒 Setting permissions...${NC}"
    
    chmod -R 755 shared/storage
    chmod -R 755 shared/nginx/logs
    chmod -R 755 shared/database/data
    chmod +x shared/scripts/*.sh
    
    echo -e "${GREEN}✅ Permissions set${NC}"
}

# Function to generate app keys for Laravel services
generate_app_keys() {
    echo -e "${YELLOW}🔑 Generating application keys...${NC}"
    
    for service in "laravel-auth" "laravel-catalog"; do
        env_file="services/${service}/.env"
        if [[ -f "$env_file" ]] && ! grep -q "APP_KEY=base64:" "$env_file"; then
            echo "Generating app key for $service..."
            app_key=$(openssl rand -base64 32)
            sed -i "s/APP_KEY=.*/APP_KEY=base64:${app_key}/" "$env_file"
        fi
    done
    
    echo -e "${GREEN}✅ Application keys generated${NC}"
}

# Function to build images
build_images() {
    echo -e "${YELLOW}🏗️ Building Docker images...${NC}"
    
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" build --no-cache
    
    echo -e "${GREEN}✅ Images built successfully${NC}"
}

# Function to start services
start_services() {
    echo -e "${YELLOW}🎯 Starting services...${NC}"
    
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" up -d mysql redis
    
    echo "Waiting for database to be ready..."
    sleep 30
    
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" up -d laravel-auth laravel-catalog express-api
    
    echo "Waiting for application services to be ready..."
    sleep 20
    
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" up -d frontend nginx
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        docker compose -f docker-compose.yml -f "$COMPOSE_FILE" up -d fluentd backup
    fi
    
    echo -e "${GREEN}✅ All services started${NC}"
}

# Function to run post-deployment tasks
post_deploy() {
    echo -e "${YELLOW}🔧 Running post-deployment tasks...${NC}"
    
    sleep 30
    
    echo "Running Laravel Auth migrations..."
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" exec -T laravel-auth php artisan migrate --force
    
    echo "Running Laravel Catalog migrations..."
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" exec -T laravel-catalog php artisan migrate --force
    
    echo "Optimizing Laravel applications..."
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" exec -T laravel-auth php artisan optimize
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" exec -T laravel-catalog php artisan optimize
    
    echo -e "${GREEN}✅ Post-deployment tasks completed${NC}"
}

# Function to show service status
show_status() {
    echo -e "${YELLOW}📊 Service Status:${NC}"
    docker compose -f docker-compose.yml -f "$COMPOSE_FILE" ps
    
    echo -e "\n${YELLOW}🌐 Service URLs:${NC}"
    echo -e "Main Application: ${GREEN}http://156.67.24.197${NC}"
    echo -e "Auth Service: ${GREEN}http://156.67.24.197/auth${NC}"
    echo -e "Catalog Service: ${GREEN}http://156.67.24.197/catalog${NC}"
    echo -e "API Service: ${GREEN}http://156.67.24.197/api${NC}"
    
    if [[ "$ENVIRONMENT" == "staging" ]]; then
        echo -e "PHPMyAdmin: ${GREEN}http://156.67.24.197:8080${NC}"
        echo -e "MailHog: ${GREEN}http://156.67.24.197:8025${NC}"
        echo -e "Redis Commander: ${GREEN}http://156.67.24.197:8081${NC}"
    fi
}

# Function to run health checks
health_check() {
    echo -e "${YELLOW}🏥 Running health checks...${NC}"
    
    if curl -f -s http://156.67.24.197/health >/dev/null; then
        echo -e "${GREEN}✅ Nginx is healthy${NC}"
    else
        echo -e "${RED}❌ Nginx health check failed${NC}"
    fi
    
    services=("laravel-auth" "laravel-catalog" "express-api" "frontend")
    for service in "${services[@]}"; do
        if docker compose -f docker-compose.yml -f "$COMPOSE_FILE" ps "$service" | grep -q "Up"; then
            echo -e "${GREEN}✅ $service is running${NC}"
        else
            echo -e "${RED}❌ $service is not running${NC}"
        fi
    done
}

# Main deployment flow
main() {
    echo -e "${GREEN}🎉 Docker Microservices Deployment Script${NC}"
    echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
    echo ""
    
    check_prerequisites
    create_directories
    set_permissions
    generate_app_keys
    build_images
    start_services
    post_deploy
    health_check
    show_status
    
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${YELLOW}📝 Check logs with: docker compose -f docker-compose.yml -f $COMPOSE_FILE logs -f${NC}"
    echo -e "${YELLOW}🛑 Stop services with: docker compose -f docker-compose.yml -f $COMPOSE_FILE down${NC}"
}

main "$@"
