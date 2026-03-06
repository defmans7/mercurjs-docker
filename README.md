# Mercur Docker Setup Guide

## Step 1: Initial Setup
Copy the files above into your Mercur project directory
Copy .env.example to .env and fill in your actual API keys and credentials
Ensure you have medusa-config.ts in your project root (from the manual installation steps)

## Step 2: Build and Start Services
```bash 
# Build and start all services
docker compose up -d

# View logs
docker compose logs -f mercur_backend
```

Step 3: Create Admin User

```bash 
# Create an admin user
docker compose exec mercur_backend npx medusa user --email admin@mercurjs.com --password admin
```

## Step 4: Access the Application
Backend API: http://localhost:9000
Health check: http://localhost:9000/health

Common Commands
```bash 
# Stop all services
docker compose down
# Stop and remove volumes (database will be wiped)
docker compose down -v
# Rebuild the application
docker compose up -d --build
# View logs for all services
docker compose logs -f
# View logs for specific service
docker compose logs -f mercur_backend
# Access backend shell
docker compose exec mercur_backend sh
# Run migrations manually
docker compose exec mercur_backend yarn medusa db:migrate
# Seed database
docker compose exec mercur_backend yarn seed
# Check service status
docker compose ps
# Restart a specific service
docker compose restart mercur_backend
# Pull latest images
docker compose pull
# Validate compose file
docker compose config
```