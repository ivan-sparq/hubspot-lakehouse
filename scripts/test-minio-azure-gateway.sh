#!/bin/bash

# Test MinIO Azure Gateway Configuration
# This script tests if MinIO is properly configured to access Azure Blob Storage

set -e

echo "🧪 Testing MinIO Azure Gateway Configuration..."
echo ""

# Load environment variables
source .env

# Check if required environment variables are set
if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ]; then
    echo "❌ Please set AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY in .env file"
    exit 1
fi

echo "✅ Environment variables configured"
echo "   Azure Storage Account: $AZURE_STORAGE_ACCOUNT"
echo ""

# Check if MinIO is running
if ! docker ps | grep -q minio; then
    echo "❌ MinIO container is not running. Start it with:"
    echo "   docker-compose up -d minio"
    exit 1
fi

echo "✅ MinIO container is running"

# Wait for MinIO to be ready
echo "⏳ Waiting for MinIO to be ready..."
sleep 10

# Test MinIO health
if curl -f "http://localhost:9000/minio/health/live" > /dev/null 2>&1; then
    echo "✅ MinIO health check passed"
else
    echo "❌ MinIO health check failed"
    exit 1
fi

# Configure MinIO client
echo "🔧 Configuring MinIO client..."
docker exec minio mc alias set myminio "http://localhost:9000" "minioadmin" "minioadmin123"

# List buckets (containers in Azure)
echo "📦 Listing Azure Storage containers (buckets):"
docker exec minio mc ls myminio

echo ""
echo "🔍 Testing access to Azure Storage container 'raw':"

# Test access to the raw container
if docker exec minio mc ls myminio/raw > /dev/null 2>&1; then
    echo "✅ Successfully accessed Azure Storage container 'raw'"
    
    # List some files in the raw container
    echo "📁 Files in raw container:"
    docker exec minio mc ls myminio/raw/hubspot/communications/20250531/ | head -5
    
else
    echo "❌ Failed to access Azure Storage container 'raw'"
    echo "   This might be because:"
    echo "   1. The container doesn't exist"
    echo "   2. Azure Storage credentials are incorrect"
    echo "   3. MinIO gateway configuration is wrong"
    exit 1
fi

echo ""
echo "🎉 MinIO Azure Gateway test completed successfully!"
echo ""
echo "📊 MinIO Console: http://localhost:9001"
echo "   Username: minioadmin"
echo "   Password: minioadmin123"
echo ""
echo "🔗 S3 Endpoint: http://localhost:9000"
echo "   Access Key: minioadmin"
echo "   Secret Key: minioadmin123"
echo ""
echo "📝 Next steps:"
echo "1. Start Unity Catalog: docker-compose up -d unity-catalog"
echo "2. Start DuckDB: docker-compose up -d duckdb"
echo "3. Test queries with S3 paths like: s3://raw/hubspot/communications/..." 