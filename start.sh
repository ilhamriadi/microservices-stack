#!/bin/bash

# Docker Microservices Quick Start Script
# Author: System Administrator
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art Banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 Docker Microservices Stack                    ║"
    echo "║                          Quick Start Script                         ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to display help
show_help() {
    echo -e "${YELLOW}Usage: $0 [COMMAND] [ENVIRONMENT]${NC}"
    echo ""
    echo -e "${BLUE}COMMANDS:${NC}"
    echo "  setup         Initialize project (copy env files, set permissions)"
    echo "  deploy        Deploy services (default: production)"
    echo "  start         Start services"
    echo "  stop          Stop services"
    echo "  restart       Restart services"
    echo "  status        Show services status"
    echo "  logs          Show services logs"
    echo "  audit         Run system audit"
    echo "  backup        Create backup"
    echo "  clean         Clean up containers and volumes"
    echo "  help          Show this help message"
    echo ""
    echo -e "${BLUE}ENVIRONMENTS:${NC}"
    echo "  production    Production environment (default)"
    echo "  staging       Staging environment with dev tools"
    echo ""
    echo -e "${BLUE}EXAMPLES:${NC}"
    echo "  $0 setup                    # Initialize project"
    echo "  $0 deploy production        # Deploy to production"
    echo "  $0 deploy staging          # Deploy to staging with dev tools"
    echo "  $0 logs laravel-auth       # Show logs for specific service"
    echo "  $0 audit production        # Run system audit"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
        echo "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker daemon is not running. Please start Docker first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites are met!${NC}"
}

# Function to setup project
setup_project() {
    echo -e "${YELLOW}📋 Setting up project...${NC}"
    
    # Create necessary directories
    echo "Creating directories..."
    mkdir -p shared/storage/{auth,catalog,express}
    mkdir -p shared/nginx/logs
    mkdir -p shared/database/data
    mkdir -p shared/backup
    mkdir -p logs/{laravel-auth,laravel-catalog,express-api}
    
    # Copy environment files if they don't exist
    echo "Setting up environment files..."
    
    if [[ ! -f ".env" ]]; then
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Please edit .env file with your configuration${NC}"
    fi
    
    # Laravel Auth service
    if [[ ! -f "services/laravel-auth/.env" ]]; then
        cp services/laravel-auth/.env.example services/laravel-auth/.env
        echo -e "${YELLOW}⚠️  Please edit services/laravel-auth/.env file${NC}"
    fi
    
    # Laravel Catalog service
    if [[ ! -f "services/laravel-catalog/.env" ]]; then
        cp services/laravel-catalog/.env.example services/laravel-catalog/.env
        echo -e "${YELLOW}⚠️  Please edit services/laravel-catalog/.env file${NC}"
    fi
    
    # Express API service
    if [[ ! -f "services/express-api/.env" ]]; then
        cp services/express-api/.env.example services/express-api/.env
        echo -e "${YELLOW}⚠️  Please edit services/express-api/.env file${NC}"
    fi
    
    # Frontend service
    if [[ ! -f "services/frontend/.env" ]]; then
        cp services/frontend/.env.example services/frontend/.env
        echo -e "${YELLOW}⚠️  Please edit services/frontend/.env file${NC}"
    fi
    
    # Set permissions
    echo "Setting permissions..."
    chmod -R 755 shared/storage
    chmod -R 755 shared/nginx/logs
    chmod -R 755 shared/database/data
    chmod +x shared/scripts/*.sh
    
    echo -e "${GREEN}✅ Project setup completed!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Edit .env files with your configuration"
    echo "2. Run: $0 deploy [environment]"
    echo ""
}

# Function to get compose file
get_compose_file() {
    local env=${1:-production}
    echo "compose/${env}.yml"
}

# Function to deploy services
deploy_services() {
    local environment=${1:-production}
    echo -e "${YELLOW}🚀 Deploying services to $environment environment...${NC}"
    
    if [[ -x "./shared/scripts/deploy.sh" ]]; then
        ./shared/scripts/deploy.sh "$environment"
    else
        echo -e "${RED}❌ Deploy script not found or not executable${NC}"
        exit 1
    fi
}

# Function to start services
start_services() {
    local environment=${1:-production}
    local compose_file=$(get_compose_file "$environment")
    
    echo -e "${YELLOW}▶️  Starting services...${NC}"
    
    if [[ -f "$compose_file" ]]; then
        docker-compose -f docker-compose.yml -f "$compose_file" up -d
        echo -e "${GREEN}✅ Services started successfully!${NC}"
    else
        echo -e "${RED}❌ Compose file $compose_file not found${NC}"
        exit 1
    fi
}

# Function to stop services
stop_services() {
    local environment=${1:-production}
    local compose_file=$(get_compose_file "$environment")
    
    echo -e "${YELLOW}⏹️  Stopping services...${NC}"
    
    if [[ -f "$compose_file" ]]; then
        docker-compose -f docker-compose.yml -f "$compose_file" down
        echo -e "${GREEN}✅ Services stopped successfully!${NC}"
    else
        echo -e "${RED}❌ Compose file $compose_file not found${NC}"
        exit 1
    fi
}

# Function to restart services
restart_services() {
    local environment=${1:-production}
    local service=${2:-""}
    local compose_file=$(get_compose_file "$environment")
    
    echo -e "${YELLOW}🔄 Restarting services...${NC}"
    
    if [[ -f "$compose_file" ]]; then
        if [[ -n "$service" ]]; then
            docker-compose -f docker-compose.yml -f "$compose_file" restart "$service"
            echo -e "${GREEN}✅ Service $service restarted successfully!${NC}"
        else
            docker-compose -f docker-compose.yml -f "$compose_file" restart
            echo -e "${GREEN}✅ All services restarted successfully!${NC}"
        fi
    else
        echo -e "${RED}❌ Compose file $compose_file not found${NC}"
        exit 1
    fi
}

# Function to show status
show_status() {
    local environment=${1:-production}
    local compose_file=$(get_compose_file "$environment")
    
    echo -e "${YELLOW}📊 Services Status:${NC}"
    
    if [[ -f "$compose_file" ]]; then
        docker-compose -f docker-compose.yml -f "$compose_file" ps
        
        echo ""
        echo -e "${YELLOW}🌐 Service URLs:${NC}"
        echo -e "Main Application: ${GREEN}http://156.67.24.197${NC}"
        echo -e "Auth Service: ${GREEN}http://156.67.24.197/auth${NC}"
        echo -e "Catalog Service: ${GREEN}http://156.67.24.197/
