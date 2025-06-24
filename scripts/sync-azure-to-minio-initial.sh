#!/bin/bash

# Initial Sync from Azure Storage to MinIO
# This script syncs data from Azure Storage to MinIO for initial lakehouse setup
# After this, MinIO will use ILM to transition objects back to Azure

set -e

echo "🔄 Initial sync from Azure Storage to MinIO..."
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

# Create buckets if they don't exist
echo "📦 Creating lakehouse buckets..."
docker exec minio mc mb myminio/raw --ignore-existing
docker exec minio mc mb myminio/silver --ignore-existing
docker exec minio mc mb myminio/gold --ignore-existing

echo "✅ Created buckets: raw, silver, gold"

# Sync data from Azure Storage to MinIO
echo "🔄 Syncing HubSpot communications data from Azure to MinIO..."

# Create a temporary script for the sync operation
cat > /tmp/sync_script.sh << 'EOF'
#!/bin/bash

# Azure Storage account details
AZURE_STORAGE_ACCOUNT="$1"
AZURE_STORAGE_KEY="$2"

# Sync raw data from Azure Storage to MinIO
echo "📥 Syncing raw data from Azure Storage..."
docker exec minio mc cp \
    "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/raw/hubspot/communications/20250531/" \
    "myminio/raw/hubspot/communications/20250531/" \
    --recursive \
    --ignore-existing

echo "✅ Sync completed!"
EOF

chmod +x /tmp/sync_script.sh

# Run the sync script
/tmp/sync_script.sh "$AZURE_STORAGE_ACCOUNT" "$AZURE_STORAGE_KEY"

# Clean up
rm /tmp/sync_script.sh

# List synced data
echo "📁 Synced data in MinIO:"
docker exec minio mc ls myminio/raw/hubspot/communications/20250531/ | head -10

echo ""
echo "🎉 Initial sync completed successfully!"
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
echo "1. Setup ILM for Azure transitions: ./scripts/setup-minio-azure-ilm.sh"
echo "2. Start Unity Catalog: docker-compose up -d unity-catalog"
echo "3. Start DuckDB: docker-compose up -d duckdb"
echo "4. Test queries with S3 paths like: s3://raw/hubspot/communications/..."
echo ""
echo "💡 Note: After setting up ILM, objects will automatically transition to Azure Storage"
echo "   based on the configured lifecycle rules, providing cost optimization." 