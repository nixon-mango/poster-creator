#!/bin/bash

# Jaaz Docker Management Script
# This script provides convenient commands for managing the Jaaz Docker setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
show_usage() {
    echo "Jaaz Docker Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Initial setup (copy env file, create directories)"
    echo "  dev       - Start development environment"
    echo "  prod      - Start production environment"
    echo "  build     - Build all Docker images"
    echo "  start     - Start all services"
    echo "  stop      - Stop all services"
    echo "  restart   - Restart all services"
    echo "  logs      - Show logs for all services"
    echo "  logs-f    - Follow logs for all services"
    echo "  clean     - Clean up Docker resources"
    echo "  reset     - Reset everything (clean + rebuild)"
    echo "  health    - Check service health"
    echo "  shell     - Access backend container shell"
    echo "  backup    - Create backup of data"
    echo "  help      - Show this help message"
}

# Setup environment
setup() {
    print_status "Setting up Jaaz Docker environment..."
    
    # Copy environment file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Copying environment template..."
        cp .env.docker .env
        print_success "Environment file created! Please edit .env with your configurations."
    else
        print_warning "Environment file already exists."
    fi
    
    # Create necessary directories
    print_status "Creating necessary directories..."
    mkdir -p data logs data/uploads data/workspaces
    chmod 755 data logs
    
    print_success "Setup completed!"
    print_warning "Don't forget to configure your API keys in .env file!"
}

# Start development environment
start_dev() {
    print_status "Starting development environment..."
    docker-compose up --build
}

# Start production environment
start_prod() {
    print_status "Starting production environment..."
    if [ ! -f .env.production ]; then
        print_error "Production environment file not found!"
        print_status "Creating from template..."
        cp .env.docker .env.production
        print_warning "Please configure .env.production before running production!"
        exit 1
    fi
    docker-compose --env-file .env.production up --build -d
}

# Build images
build() {
    print_status "Building Docker images..."
    docker-compose build --no-cache
    print_success "Build completed!"
}

# Start services
start() {
    print_status "Starting services..."
    docker-compose up -d
    print_success "Services started!"
}

# Stop services
stop() {
    print_status "Stopping services..."
    docker-compose down
    print_success "Services stopped!"
}

# Restart services
restart() {
    print_status "Restarting services..."
    docker-compose restart
    print_success "Services restarted!"
}

# Show logs
logs() {
    docker-compose logs
}

# Follow logs
logs_follow() {
    docker-compose logs -f
}

# Clean up
clean() {
    print_warning "This will remove all containers, networks, and images!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up..."
        docker-compose down --rmi all -v
        docker system prune -f
        print_success "Cleanup completed!"
    fi
}

# Reset everything
reset() {
    print_warning "This will completely reset the Docker environment!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        clean
        build
        print_success "Reset completed!"
    fi
}

# Check health
health() {
    print_status "Checking service health..."
    
    echo ""
    echo "Docker Compose Status:"
    docker-compose ps
    
    echo ""
    echo "Backend Health:"
    if curl -s http://localhost:57988/health > /dev/null; then
        print_success "Backend is healthy"
    else
        print_error "Backend is not responding"
    fi
    
    echo ""
    echo "Frontend Health:"
    if curl -s http://localhost/health > /dev/null; then
        print_success "Frontend is healthy"
    else
        print_error "Frontend is not responding"
    fi
    
    echo ""
    echo "Redis Health:"
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        print_success "Redis is healthy"
    else
        print_error "Redis is not responding"
    fi
}

# Access shell
shell() {
    print_status "Accessing backend container shell..."
    docker-compose exec backend bash
}

# Create backup
backup() {
    backup_name="jaaz-backup-$(date +%Y%m%d-%H%M%S)"
    print_status "Creating backup: $backup_name.tar.gz"
    
    tar -czf "$backup_name.tar.gz" data/ logs/ .env
    print_success "Backup created: $backup_name.tar.gz"
}

# Main script logic
case "$1" in
    setup)
        setup
        ;;
    dev)
        start_dev
        ;;
    prod)
        start_prod
        ;;
    build)
        build
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs
        ;;
    logs-f)
        logs_follow
        ;;
    clean)
        clean
        ;;
    reset)
        reset
        ;;
    health)
        health
        ;;
    shell)
        shell
        ;;
    backup)
        backup
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        if [ -z "$1" ]; then
            show_usage
        else
            print_error "Unknown command: $1"
            show_usage
            exit 1
        fi
        ;;
esac