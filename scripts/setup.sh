#!/bin/bash

# HubSpot Lakehouse Setup Script
set -e

echo "🚀 Setting up HubSpot Lakehouse with Unity Catalog..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  Please edit .env file with your Azure Storage credentials before continuing"
    echo "   Required: AZURE_STORAGE_KEY"
    exit 1
fi

# Load environment variables
source .env

# Check if Azure Storage key is set
if [ "$AZURE_STORAGE_KEY" = "your_azure_storage_key_here" ]; then
    echo "❌ Please set your Azure Storage key in the .env file"
    exit 1
fi

echo "✅ Environment variables configured"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p config/unity-catalog
mkdir -p config/duckdb
mkdir -p config/dbt
mkdir -p dbt/models/{staging,silver,gold}
mkdir -p dbt/{tests,analyses,macros,seeds,snapshots}

echo "✅ Directories created"

# Start services
echo "🐳 Starting Docker services..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
echo "🔍 Checking service health..."

# Check Unity Catalog
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Unity Catalog is running"
else
    echo "❌ Unity Catalog is not responding"
    docker-compose logs unity-catalog
    exit 1
fi

# Check DuckDB
if curl -f http://localhost:8081/health > /dev/null 2>&1; then
    echo "✅ DuckDB is running"
else
    echo "⚠️  DuckDB health check failed, but service may still be starting"
fi

echo "✅ All services are running!"

# Initialize dbt
echo "🔧 Initializing dbt project..."
docker exec -it dbt-core dbt deps
docker exec -it dbt-core dbt run

echo "🎉 Setup complete!"
echo ""
echo "📊 Next steps:"
echo "1. Access Unity Catalog UI: http://localhost:8080"
echo "2. Connect to DuckDB: docker exec -it duckdb duckdb"
echo "3. Run dbt commands: docker exec -it dbt-core dbt run"
echo "4. Query data from your local Jupyter notebook"
echo ""
echo "📚 Documentation: See README.md for detailed usage instructions" 