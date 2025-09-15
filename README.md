# 🚀 Docker Microservices Stack

Modern microservices architecture dengan Docker Compose untuk deployment yang mudah dan scalable.

## 📋 Arsitektur

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Nginx Proxy   │────│  Laravel Auth    │    │ Laravel Catalog │
│   (Port 80/443) │    │   Service        │    │   Service       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                       │
         │              ┌─────────────────┐               │
         │──────────────│  Express API    │───────────────│
         │              │   Service       │               │
         │              └─────────────────┘               │
         │                        │                       │
         │              ┌─────────────────┐               │
         └──────────────│   Frontend      │───────────────┘
                        │  (React/Vue)    │
                        └─────────────────┘
                                 │
                   ┌─────────────────────────────┐
                   │                             │
            ┌──────────────┐           ┌─────────────┐
            │    MySQL     │           │    Redis    │
            │   Database   │           │    Cache    │
            └──────────────┘           └─────────────┘
```

## 🛠️ Services

| Service | Port | Description |
|---------|------|-------------|
| **Nginx** | 80, 443 | Reverse proxy & load balancer |
| **Laravel Auth** | - | Authentication service |
| **Laravel Catalog** | - | Product catalog service |
| **Express API** | - | Node.js API service |
| **Frontend** | - | React/Vue frontend |
| **MySQL** | 3306 | Primary database |
| **Redis** | 6379 | Cache & session store |

## 🚀 Quick Start

### 1. Clone & Setup

```bash
# Clone repository
git clone <repository-url>
cd project_root

# Copy environment files
cp .env.example .env
cp services/laravel-auth/.env.example services/laravel-auth/.env
cp services/laravel-catalog/.env.example services/laravel-catalog/.env
cp services/express-api/.env.example services/express-api/.env
cp services/frontend/.env.example services/frontend/.env
```

### 2. Configure Environment

Edit `.env` file dengan konfigurasi Anda:

```bash
# Update server IP
SERVER_IP=156.67.24.197

# Set strong passwords
MYSQL_ROOT_PASSWORD=your_strong_root_password_here
MYSQL_PASSWORD=your_strong_password_here

# Configure JWT secrets
JWT_SECRET=your_very_long_jwt_secret_key_here
```

### 3. Deploy

```bash
# Make scripts executable
chmod +x shared/scripts/*.sh

# Deploy to production
./shared/scripts/deploy.sh production

# Or deploy to staging
./shared/scripts/deploy.sh staging
```

## 📂 Project Structure

```
project_root/
├── services/                          # Semua service terisolasi
│   ├── laravel-auth/                 # Laravel Authentication Service
│   │   ├── src/                      # Laravel source code
│   │   ├── docker/                   # Docker configuration
│   │   │   ├── Dockerfile
│   │   │   ├── entrypoint.sh
│   │   │   ├── php.ini
│   │   │   └── www.conf
│   │   └── .env                      # Service environment
│   │
│   ├── laravel-catalog/              # Laravel Catalog Service
│   │   ├── src/                      # Laravel source code
│   │   ├── docker/                   # Docker configuration
│   │   └── .env                      # Service environment
│   │
│   ├── express-api/                  # Express API Service
│   │   ├── src/                      # Express source code
│   │   ├── docker/                   # Docker configuration
│   │   └── .env                      # Service environment
│   │
│   └── frontend/                     # Frontend Service
│       ├── src/                      # React/Vue source code
│       ├── docker/                   # Docker configuration
│       └── .env                      # Service environment
│
├── shared/                           # Shared resources
│   ├── nginx/                        # Reverse proxy
│   │   ├── Dockerfile
│   │   └── default.conf
│   ├── database/                     # Database configuration
│   │   ├── my.cnf
│   │   └── init/
│   ├── scripts/                      # Management scripts
│   │   ├── deploy.sh                 # Deployment script
│   │   ├── audit.sh                  # System audit script
│   │   └── backup.sh                 # Backup script
│   ├── storage/                      # Shared storage
│   └── backup/                       # Backup storage
│
├── compose/                          # Environment configurations
│   ├── staging.yml                   # Staging overrides
│   └── production.yml                # Production overrides
│
├── docker-compose.yml                # Base configuration
├── .env.example                      # Environment template
├── .dockerignore
└── README.md                         # Documentation
```

## 🔧 Management Commands

### Deployment

```bash
# Deploy ke production
./shared/scripts/deploy.sh production

# Deploy ke staging (dengan development tools)
./shared/scripts/deploy.sh staging

# Stop services
docker-compose -f docker-compose.yml -f compose/production.yml down

# View logs
docker-compose -f docker-compose.yml -f compose/production.yml logs -f

# Restart specific service
docker-compose -f docker-compose.yml -f compose/production.yml restart laravel-auth
```

### System Audit

```bash
# Run system audit
./shared/scripts/audit.sh production

# Generate detailed audit report
./shared/scripts/audit.sh production --report
```

### Backup & Recovery

```bash
# Create backup
./shared/scripts/backup.sh production

# Create backup with custom retention (7 days)
./shared/scripts/backup.sh production 7

# Restore from backup
# (Manual process - see backup manifest for details)
```

## 🌐 Service URLs

| Service | URL |
|---------|-----|
| **Main App** | http://156.67.24.197 |
| **Auth API** | http://156.67.24.197/auth |
| **Catalog API** | http://156.67.24.197/catalog |
| **Express API** | http://156.67.24.197/api |
| **Health Check** | http://156.67.24.197/health |

### Development Tools (Staging Only)

| Tool | URL | Description |
|------|-----|-------------|
| **PHPMyAdmin** | http://156.67.24.197:8080 | Database management |
| **MailHog** | http://156.67.24.197:8025 | Email testing |
| **Redis Commander** | http://156.67.24.197:8081 | Redis management |

## 🔒 Security Features

- **SSL/TLS**: Ready for HTTPS with self-signed certificates
- **Rate Limiting**: Nginx-based rate limiting for APIs
- **Security Headers**: XSS protection, content type sniffing prevention
- **Non-root Containers**: Services run with minimal privileges
- **Network Isolation**: Services communicate through internal Docker network
- **Environment Separation**: Isolated environments for different stages

## 📊 Monitoring & Logging

### Health Checks

```bash
# Check service health
curl http://156.67.24.197/health

# Check individual service status
docker-compose ps

# View resource usage
docker stats
```

### Log Management

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f laravel-auth

# View nginx access logs
docker-compose exec nginx tail -f /var/log/nginx/access.log

# Export logs for analysis
docker-compose logs --since="24h" > system_logs.txt
```

## 🔄 Scaling

### Horizontal Scaling

```bash
# Scale specific services
docker-compose up -d --scale laravel-auth=3
docker-compose up -d --scale express-api=2

# Update nginx upstream configuration
# Edit shared/nginx/default.conf to add scaled instances
```

### Performance Optimization

1. **Database Optimization**
   - Adjust MySQL configuration in `shared/database/my.cnf`
   - Monitor slow queries and optimize indexes

2. **Redis Optimization**
   - Configure Redis memory limits
   - Set appropriate cache expiration policies

3. **Application Optimization**
   - Enable PHP OPcache
   - Configure Laravel queue workers
   - Optimize frontend builds

## 🚨 Troubleshooting

### Common Issues

1. **Services Won't Start**
   ```bash
   # Check logs
   docker-compose logs service-name
   
   # Rebuild containers
   docker-compose build --no-cache service-name
   
   # Check disk space
   df -h
   ```

2. **Database Connection Issues**
   ```bash
   # Check MySQL status
   docker-compose exec mysql mysql -u root -p -e "SELECT 1;"
   
   # Reset database
   docker-compose down
   sudo rm -rf shared/database/data/*
   docker-compose up -d mysql
   ```

3. **Permission Issues**
   ```bash
   # Fix storage permissions
   sudo chown -R www-data:www-data shared/storage/
   sudo chmod -R 755 shared/storage/
   ```

4. **Memory Issues**
   ```bash
   # Check container memory usage
   docker stats
   
   # Adjust resource limits in production.yml
   # Restart with more memory
   ```

### Debug Mode

For staging environment, enable debug mode:

```bash
# Deploy in staging mode
./shared/scripts/deploy.sh staging

# Services will run with:
# - Debug logging enabled
# - Development tools available
# - Hot reload for frontend
```

## 📋 Maintenance

### Regular Tasks

1. **Daily**
   - Monitor resource usage
   - Check service health
   - Review error logs

2. **Weekly**
   - Run system audit
   - Check backup integrity
   - Update security patches

3. **Monthly**
   - Clean old logs and backups
   - Review performance metrics
   - Update dependencies

### Backup Strategy

- **Automated Daily Backups**: Database, files, and configurations
- **Retention Policy**: 30 days by default
- **Backup Verification**: Automated integrity checks
- **Off-site Storage**: Consider copying backups to external storage

## 🤝 Contributing

1. Follow the service isolation principle
2. Update documentation when adding features
3. Test changes in staging environment first
4. Use semantic versioning for releases

## 📄 License

[Your License Here]

## 🆘 Support

For issues and questions:

1. Check troubleshooting section above
2. Review service logs for error details
3. Run system audit for comprehensive diagnostics
4. Contact system administrator

---

**Server Information:**
- **IP**: 156.67.24.197
- **Environment**: Production/Staging
- **Last Updated**: $(date)

> 💡 **Tip**: Use `./shared/scripts/audit.sh` regularly to monitor system health and performance.
