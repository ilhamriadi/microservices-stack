# 🚀 Deployment Instructions - VPS 156.67.24.197

## 📋 Prerequisites

Pastikan VPS Anda sudah memiliki:
- Ubuntu 20.04+ atau CentOS 8+
- Docker & Docker Compose
- Akses SSH ke VPS
- Minimal 4GB RAM, 2 CPU cores, 20GB storage

## 🛠️ Installation Steps

### 1. Connect to VPS
```bash
ssh root@156.67.24.197
# atau
ssh your-username@156.67.24.197
```

### 2. Install Docker & Docker Compose (jika belum ada)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group (optional)
sudo usermod -aG docker $USER
```

### 3. Clone & Setup Project
```bash
# Clone repository (atau upload files)
git clone <your-repo-url> microservices-stack
cd microservices-stack

# Or upload via SCP
# scp -r ./project_root/ root@156.67.24.197:/root/microservices-stack/

# Make start script executable
chmod +x start.sh
```

### 4. Quick Setup & Deploy
```bash
# Run interactive setup
./start.sh

# Or manual steps:
./start.sh setup
./start.sh deploy production
```

## ⚡ Quick Commands

```bash
# Setup project
./start.sh setup

# Deploy to production
./start.sh deploy production

# Deploy to staging (with dev tools)
./start.sh deploy staging

# Check status
./start.sh status

# View logs
./start.sh logs

# Health check
./start.sh health

# System audit
./start.sh audit

# Create backup
./start.sh backup

# Stop all services
./start.sh stop

# Clean up everything
./start.sh clean
```

## 🔧 Configuration

### 1. Edit Main Environment File
```bash
nano .env
```

**Important configurations:**
```bash
# Server Configuration
SERVER_IP=156.67.24.197
DOMAIN=156.67.24.197

# Database - CHANGE THESE PASSWORDS!
MYSQL_ROOT_PASSWORD=your_very_strong_root_password_123!
MYSQL_USER=microservices_user
MYSQL_PASSWORD=your_very_strong_password_123!

# Security - GENERATE NEW SECRETS!
JWT_SECRET=your_64_character_jwt_secret_key_here_make_it_very_long_and_random
ENCRYPT_KEY=your_32_character_encryption_key_12
```

### 2. Generate Strong Passwords & Keys
```bash
# Generate random password
openssl rand -base64 32

# Generate JWT secret
openssl rand -base64 64

# Generate encryption key (32 chars)
openssl rand -base64 32 | cut -c1-32
```

### 3. Service-Specific Configuration
```bash
# Laravel Auth Service
nano services/laravel-auth/.env

# Laravel Catalog Service  
nano services/laravel-catalog/.env

# Express API Service
nano services/express-api/.env

# Frontend Service
nano services/frontend/.env
```

## 🚀 Deployment Process

### Option 1: Automated Deployment
```bash
# One-command deployment
./start.sh deploy production
```

### Option 2: Manual Step-by-Step
```bash
# 1. Setup project structure
./start.sh setup

# 2. Start database first
docker-compose -f docker-compose.yml -f compose/production.yml up -d mysql redis

# 3. Wait for database (30 seconds)
sleep 30

# 4. Start application services
docker-compose -f docker-compose.yml -f compose/production.yml up -d laravel-auth laravel-catalog express-api

# 5. Start frontend and proxy
docker-compose -f docker-compose.yml -f compose/production.yml up -d frontend nginx

# 6. Check status
./start.sh status
```

## 🌐 Access Your Services

After deployment, access your services at:

| Service | URL | Description |
|---------|-----|-------------|
| **Main App** | http://156.67.24.197 | Frontend application |
| **Auth API** | http://156.67.24.197/auth | Authentication service |
| **Catalog API** | http://156.67.24.197/catalog | Product catalog service |
| **Express API** | http://156.67.24.197/api | Node.js API service |
| **Health Check** | http://156.67.24.197/health | System health status |

### Staging Environment (Development Tools)
If deployed to staging:
- **PHPMyAdmin**: http://156.67.24.197:8080
- **MailHog**: http://156.67.24.197:8025  
- **Redis Commander**: http://156.67.24.197:8081

## 🔍 Monitoring & Maintenance

### Daily Checks
```bash
# Check service health
./start.sh health

# Check system resources
./start.sh audit

# View recent logs
./start.sh logs | tail -100
```

### Weekly Maintenance
```bash
# Create backup
./start.sh backup production

# System cleanup (careful!)
docker system prune -f

# Update images
docker-compose pull
./start.sh restart
```

## 🔒 Security Hardening

### 1. Firewall Configuration
```bash
# Install UFW
sudo apt install ufw

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### 2. SSL Certificate Setup
```bash
# Install Certbot
sudo apt install certbot

# Get SSL certificate (if you have domain)
sudo certbot certonly --standalone -d yourdomain.com

# Copy certificates to nginx
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem shared/nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem shared/nginx/ssl/

# Update nginx config to use SSL
# Edit shared/nginx/default.conf and uncomment HTTPS section
```

### 3. Database Security
```bash
# Secure MySQL installation
docker-compose exec mysql mysql_secure_installation
```

## 🚨 Troubleshooting

### Service Won't Start
```bash
# Check logs
./start.sh logs service-name

# Rebuild specific service
docker-compose build --no-cache service-name

# Check disk space
df -h

# Check memory
free -h
```

### Database Connection Issues
```bash
# Check MySQL status
docker-compose exec mysql mysql -u root -p -e "SELECT 1;"

# Reset database (CAREFUL!)
./start.sh stop
sudo rm -rf shared/database/data/*
./start.sh start
```

### Permission Issues
```bash
# Fix storage permissions
sudo chown -R www-data:www-data shared/storage/
sudo chmod -R 755 shared/storage/

# Fix script permissions
chmod +x shared/scripts/*.sh
chmod +x start.sh
```

### High Resource Usage
```bash
# Check container resources
docker stats

# Scale down services
docker-compose scale laravel-auth=1 laravel-catalog=1

# Clean up logs
truncate -s 0 shared/nginx/logs/*.log
```

## 📊 Performance Optimization

### Database Optimization
```bash
# Tune MySQL settings
# Edit shared/database/my.cnf

# Optimize Laravel
docker-compose exec laravel-auth php artisan config:cache
docker-compose exec laravel-auth php artisan route:cache
docker-compose exec laravel-auth php artisan view:cache
```

### Caching
```bash
# Clear all caches
docker-compose exec redis redis-cli FLUSHALL

# Check cache hit ratio
docker-compose exec redis redis-cli info stats | grep hit
```

## 🔄 Backup & Recovery

### Create Backup
```bash
# Full backup
./start.sh backup production

# Custom retention (7 days)
./start.sh backup production 7
```

### Restore from Backup
```bash
# Stop services
./start.sh stop

# Restore database
docker-compose exec -T mysql mysql -u root -p < shared/backup/databases/full_backup_YYYYMMDD_HHMMSS.sql

# Restore files
tar -xzf shared/backup/files/storage_backup_YYYYMMDD_HHMMSS.tar.gz -C shared/

# Start services
./start.sh start
```

## 📞 Support

If you encounter issues:

1. Check logs: `./start.sh logs`
2. Run audit: `./start.sh audit`
3. Check system resources: `./start.sh info`
4. Review troubleshooting section above
5. Check Docker daemon: `sudo systemctl status docker`

## 🎉 Success Verification

After deployment, verify everything works:

```bash
# 1. Check all services are running
./start.sh status

# 2. Test health endpoints
curl http://156.67.24.197/health

# 3. Test service endpoints
curl http://156.67.24.197/auth
curl http://156.67.24.197/catalog  
curl http://156.67.24.197/api

# 4. Check database connections
docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"

# 5. Check Redis
docker-compose exec redis redis-cli ping
```

**Expected Results:**
- All services show "Up" status
- Health endpoint returns "healthy"
- Service endpoints return responses (not 502/503 errors)
- Database shows your custom databases
- Redis returns "PONG"

---

🎊 **Congratulations!** Your microservices stack is now running on 156.67.24.197

For ongoing management, use `./start.sh` without arguments to access the interactive menu.
