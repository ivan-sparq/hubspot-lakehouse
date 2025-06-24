#!/bin/bash

# HubSpot Lakehouse Setup Script
# Complete setup for MinIO standalone server with Azure ILM

set -e

echo "🏗️  HubSpot Lakehouse Setup"
echo "=========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please copy env.example to .env and configure your Azure Storage credentials:"
    echo "cp env.example .env"
    echo "Then edit .env with your Azure Storage account details."
    exit 1
fi

# Load environment variables
source .env

# Check required environment variables
if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ]; then
    print_error "AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY must be set in .env file"
    exit 1
fi

print_success "Environment variables loaded"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_success "Docker is running"

# Step 1: Start MinIO standalone server
print_status "Step 1: Starting MinIO standalone server..."
docker-compose up -d minio

# Wait for MinIO to be ready
print_status "Waiting for MinIO to be ready..."
sleep 15

# Test MinIO health
if curl -f "http://localhost:9000/minio/health/live" > /dev/null 2>&1; then
    print_success "MinIO is healthy"
else
    print_error "MinIO health check failed"
    echo "Check MinIO logs: docker-compose logs minio"
    exit 1
fi

# Step 2: Setup MinIO with Azure ILM
print_status "Step 2: Setting up MinIO with Azure Object Lifecycle Management..."
./scripts/setup-minio-azure-ilm.sh

# Step 3: Sync initial data from Azure
print_status "Step 3: Syncing initial data from Azure Storage..."
./scripts/sync-azure-to-minio-initial.sh

# Step 4: Start Unity Catalog
print_status "Step 4: Starting Unity Catalog..."
docker-compose up -d unity-catalog

# Wait for Unity Catalog to be ready
print_status "Waiting for Unity Catalog to be ready..."
sleep 20

# Test Unity Catalog health
if curl -f "http://localhost:8080" > /dev/null 2>&1; then
    print_success "Unity Catalog is healthy"
else
    print_warning "Unity Catalog health check failed, but continuing..."
fi

# Step 5: Start DuckDB
print_status "Step 5: Starting DuckDB..."
docker-compose up -d duckdb

# Wait for DuckDB to be ready
print_status "Waiting for DuckDB to be ready..."
sleep 10

# Test DuckDB health
if curl -f "http://localhost:8081/health" > /dev/null 2>&1; then
    print_success "DuckDB is healthy"
else
    print_warning "DuckDB health check failed, but continuing..."
fi

# Step 6: Verify all services
print_status "Step 6: Verifying all services..."
docker-compose ps

echo ""
print_success "🎉 HubSpot Lakehouse setup completed successfully!"
echo ""

echo "📊 Service URLs:"
echo "================="
echo "MinIO Console:     http://localhost:9001 (minioadmin / minioadmin123)"
echo "MinIO API:         http://localhost:9000"
echo "Unity Catalog:     http://localhost:8080"
echo "DuckDB HTTP:       http://localhost:8081"
echo ""

echo "🔧 Next Steps:"
echo "=============="
echo "1. Test DuckDB connection: ./scripts/connect-duckdb.sh"
echo "2. Run example queries: docker exec -i duckdb duckdb < examples/duckdb-queries.sql"
echo "3. Explore MinIO console: http://localhost:9001"
echo "4. Start dbt development: cd dbt && dbt run --profiles-dir config/dbt"
echo ""

echo "📋 Architecture Summary:"
echo "======================="
echo "• MinIO: Standalone server with ILM for Azure transitions"
echo "• Unity Catalog: Metadata management and governance"
echo "• DuckDB: High-performance analytical queries"
echo "• dbt: Data transformation and modeling"
echo "• Azure Storage: Long-term data storage (via ILM transitions)"
echo ""

echo "💡 ILM Configuration:"
echo "===================="
echo "• Raw data → Azure after 7 days"
echo "• Silver data → Azure after 3 days"
echo "• Gold data → Azure after 1 day"
echo ""

echo "🔍 Troubleshooting:"
echo "=================="
echo "• View logs: docker-compose logs [service-name]"
echo "• Restart service: docker-compose restart [service-name]"
echo "• Check MinIO ILM rules: docker exec minio mc ilm rule ls myminio/raw --transition"
echo ""

print_success "Setup complete! Your lakehouse is ready for data processing." 