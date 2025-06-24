#!/bin/bash

# Setup MinIO with Azure Object Lifecycle Management (ILM)
# This script configures MinIO to transition objects to Azure Storage
# Based on current MinIO documentation (not deprecated gateway mode)

set -e

echo "🔧 Setting up MinIO with Azure Object Lifecycle Management..."
echo ""

# Load environment variables
source .env

# Check if required environment variables are set
if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ]; then
    echo "❌ Please set AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY in .env file"
    exit 1
fi

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

# Create buckets for our lakehouse
echo "📦 Creating lakehouse buckets..."
docker exec minio mc mb myminio/raw --ignore-existing
docker exec minio mc mb myminio/silver --ignore-existing
docker exec minio mc mb myminio/gold --ignore-existing

echo "✅ Created buckets: raw, silver, gold"

# Configure Azure remote storage tier
echo "☁️  Configuring Azure remote storage tier..."
docker exec minio mc admin tier add azure myminio azure-tier \
    --endpoint "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net" \
    --access-key "${AZURE_STORAGE_ACCOUNT}" \
    --secret-key "${AZURE_STORAGE_KEY}"

echo "✅ Configured Azure remote storage tier"

# Create ILM rules for transitioning objects to Azure
echo "📋 Creating ILM rules for Azure transitions..."

# Rule 1: Transition raw data to Azure after 7 days
echo "   Creating rule: raw data → Azure after 7 days"
docker exec minio mc ilm rule add myminio/raw \
    --transition-tier azure-tier \
    --transition-days 7

# Rule 2: Transition silver data to Azure after 3 days
echo "   Creating rule: silver data → Azure after 3 days"
docker exec minio mc ilm rule add myminio/silver \
    --transition-tier azure-tier \
    --transition-days 3

# Rule 3: Transition gold data to Azure after 1 day
echo "   Creating rule: gold data → Azure after 1 day"
docker exec minio mc ilm rule add myminio/gold \
    --transition-tier azure-tier \
    --transition-days 1

echo "✅ Created ILM transition rules"

# Verify the rules
echo "📋 Verifying ILM rules..."
docker exec minio mc ilm rule ls myminio/raw --transition
docker exec minio mc ilm rule ls myminio/silver --transition
docker exec minio mc ilm rule ls myminio/gold --transition

# Create a test file to verify the setup
echo "🧪 Creating test file to verify setup..."
echo "test data for MinIO ILM verification" | docker exec -i minio mc pipe myminio/raw/test-file.txt

echo "✅ Test file created"

# List buckets and files
echo "📁 Current MinIO buckets and files:"
docker exec minio mc ls myminio
echo ""
docker exec minio mc ls myminio/raw

echo ""
echo "🎉 MinIO Azure ILM setup completed successfully!"
echo ""
echo "📊 MinIO Console: http://localhost:9001"
echo "   Username: minioadmin"
echo "   Password: minioadmin123"
echo ""
echo "🔗 S3 Endpoint: http://localhost:9000"
echo "   Access Key: minioadmin"
echo "   Secret Key: minioadmin123"
echo ""
echo "📋 ILM Configuration:"
echo "   - Raw data transitions to Azure after 7 days"
echo "   - Silver data transitions to Azure after 3 days"
echo "   - Gold data transitions to Azure after 1 day"
echo ""
echo "📝 Next steps:"
echo "1. Start Unity Catalog: docker-compose up -d unity-catalog"
echo "2. Start DuckDB: docker-compose up -d duckdb"
echo "3. Test queries with S3 paths like: s3://raw/hubspot/communications/..."
echo ""
echo "💡 Note: Objects will automatically transition to Azure Storage based on the ILM rules"
echo "   This provides cost optimization while maintaining local performance for recent data" 