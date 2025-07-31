# Docker Setup for Jaaz

This document provides instructions for running Jaaz using Docker and Docker Compose.

## 🐳 Prerequisites

- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **System Requirements**: 
  - Minimum 4GB RAM
  - 10GB free disk space
  - Multi-core CPU recommended

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd jaaz
cp .env.docker .env
```

### 2. Configure Environment

Edit the `.env` file with your specific configurations:

```bash
# Essential configurations
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
# Add other API keys as needed
```

### 3. Build and Run

```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### 4. Access the Application

- **Frontend**: http://localhost (port 80)
- **Backend API**: http://localhost:57988
- **Redis**: localhost:6379
- **Development Tools**: http://localhost:8080 (Adminer)

## 📁 Project Structure

```
jaaz/
├── docker-compose.yml              # Main docker compose configuration
├── docker-compose.override.yml     # Development overrides
├── Dockerfile.backend             # Backend Python/FastAPI container
├── Dockerfile.frontend            # Frontend React/Nginx container
├── nginx.conf                     # Nginx configuration
├── .env.docker                    # Environment template
└── DOCKER.md                      # This documentation
```

## 🏗️ Architecture

The Docker setup consists of the following services:

### Backend Service (`jaaz-backend`)
- **Image**: Custom Python 3.11 image
- **Framework**: FastAPI with WebSocket support
- **Port**: 57988
- **Features**: 
  - AI services integration
  - WebSocket real-time communication
  - File upload handling
  - REST API endpoints

### Frontend Service (`jaaz-frontend`)
- **Image**: Multi-stage build (Node.js builder + Nginx)
- **Framework**: React with Vite
- **Port**: 80 (HTTP), 443 (HTTPS)
- **Features**:
  - React application serving
  - API proxy to backend
  - WebSocket proxy
  - Static asset optimization

### Redis Service (`jaaz-redis`)
- **Image**: Redis 7 Alpine
- **Port**: 6379
- **Purpose**: Session management and WebSocket scaling

### Optional: PostgreSQL Service
- **Image**: PostgreSQL 15 Alpine
- **Port**: 5432
- **Purpose**: Alternative to SQLite for production

## 🔧 Configuration

### Environment Variables

Copy `.env.docker` to `.env` and configure:

#### AI Services
```bash
# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# Local Ollama (if running locally)
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

#### Database Options
```bash
# Use SQLite (default)
# No additional configuration needed

# Use PostgreSQL (uncomment in docker-compose.yml)
DATABASE_URL=postgresql://jaaz:jaaz_password@postgres:5432/jaaz
```

#### Security
```bash
JWT_SECRET_KEY=your-secure-random-key-here
CORS_ORIGINS=http://localhost,https://yourdomain.com
```

## 🛠️ Development Mode

### Start Development Environment

```bash
# Development mode with hot-reload
docker-compose up --build

# The override file automatically enables:
# - Source code mounting
# - Hot-reload for both frontend and backend
# - Development ports and debugging
```

### Development Features

- **Hot Reload**: Code changes automatically restart services
- **Debug Ports**: Python debugger on port 5678
- **Source Mounting**: Local changes reflect immediately
- **Development Tools**: Adminer for database inspection

### Frontend Development

```bash
# Access development server
http://localhost:5174

# API calls are proxied to backend automatically
```

### Backend Development

```bash
# API documentation (FastAPI)
http://localhost:57988/docs

# Backend health check
http://localhost:57988/health
```

## 🚢 Production Deployment

### 1. Production Configuration

```bash
# Create production environment file
cp .env.docker .env.production

# Edit production settings
NODE_ENV=production
DEBUG=false
# Add production API keys and configurations
```

### 2. Production Build

```bash
# Build for production
docker-compose -f docker-compose.yml --env-file .env.production up --build -d

# Or use production override
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build -d
```

### 3. SSL/HTTPS Setup

Update `nginx.conf` for SSL:

```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /etc/ssl/certs/your-cert.pem;
    ssl_certificate_key /etc/ssl/private/your-key.pem;
    # ... rest of configuration
}
```

Mount SSL certificates:

```yaml
# In docker-compose.yml
frontend:
  volumes:
    - ./ssl:/etc/ssl
```

## 📊 Monitoring and Logs

### View Logs

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs backend
docker-compose logs frontend

# Follow logs in real-time
docker-compose logs -f
```

### Health Checks

```bash
# Check service status
docker-compose ps

# Backend health
curl http://localhost:57988/health

# Frontend health  
curl http://localhost/health
```

### Container Management

```bash
# Restart specific service
docker-compose restart backend

# Scale services (if needed)
docker-compose up --scale backend=2

# Update and rebuild
docker-compose up --build
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Port Conflicts
```bash
# Check if ports are in use
netstat -tulpn | grep :80
netstat -tulpn | grep :57988

# Change ports in docker-compose.yml if needed
```

#### 2. Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER ./data ./logs

# Or create directories with correct permissions
mkdir -p data logs
chmod 755 data logs
```

#### 3. Build Failures
```bash
# Clean build
docker-compose down
docker system prune -f
docker-compose build --no-cache
docker-compose up
```

#### 4. WebSocket Connection Issues
```bash
# Check nginx configuration
docker-compose exec frontend nginx -t

# Verify backend WebSocket endpoint
curl -H "Upgrade: websocket" http://localhost:57988/socket.io/
```

### Debug Mode

Enable debug mode in `.env`:

```bash
DEBUG=true
LOG_LEVEL=DEBUG
```

### Container Shell Access

```bash
# Access backend container
docker-compose exec backend bash

# Access frontend container
docker-compose exec frontend sh

# Access Redis container
docker-compose exec redis redis-cli
```

## 🧹 Cleanup

### Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Remove everything including images
docker-compose down --rmi all -v
```

### Clean Docker System

```bash
# Remove unused containers, networks, images
docker system prune -f

# Remove all unused volumes
docker volume prune -f
```

## 📦 Backup and Restore

### Backup Data

```bash
# Backup application data
tar -czf jaaz-backup-$(date +%Y%m%d).tar.gz data/ logs/

# Backup database (if using PostgreSQL)
docker-compose exec postgres pg_dump -U jaaz jaaz > jaaz-db-backup.sql
```

### Restore Data

```bash
# Restore application data
tar -xzf jaaz-backup-20240101.tar.gz

# Restore database
docker-compose exec -T postgres psql -U jaaz jaaz < jaaz-db-backup.sql
```

## 🔐 Security Considerations

1. **Environment Variables**: Never commit `.env` files with real API keys
2. **Network Security**: Use internal networks for service communication
3. **SSL/TLS**: Enable HTTPS in production
4. **User Permissions**: Run containers with non-root users
5. **Secrets Management**: Use Docker secrets for sensitive data in production

## 📞 Support

For issues and questions:

1. Check the [troubleshooting section](#troubleshooting)
2. Review container logs: `docker-compose logs`
3. Open an issue on the project repository
4. Join our Discord community for real-time help

## 🔄 Updates

To update Jaaz:

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up --build -d
```

---

**Happy Dockerizing! 🚀**