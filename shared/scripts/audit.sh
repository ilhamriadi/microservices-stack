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

echo -e "${BLUE}🔍 System Audit Report - $(date)${NC}"
echo -e "${BLUE}Environment: $ENVIRONMENT${NC}"
echo "=================================================="

# Function to check system resources
check_system_resources() {
    echo -e "\n${YELLOW}💻 System Resources:
