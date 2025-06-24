#!/bin/bash

# Azure Storage to MinIO Sync Script
# This script syncs data from Azure Storage to MinIO for Unity Catalog access

set -e

echo "🔄 Syncing Azure Storage to MinIO..."

# Load environment variables
source .env

# Check if required environment variables are set
if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ]; then
    echo "❌ Please set AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY in .env file"
    exit 1
fi

# MinIO configuration
MINIO_ENDPOINT="http://localhost:9000"
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin123"
MINIO_BUCKET="hubspot-data"

# Check if MinIO is running
if ! curl -f "$MINIO_ENDPOINT/minio/health/live" > /dev/null 2>&1; then
    echo "❌ MinIO is not running. Start it with: docker-compose up -d minio"
    exit 1
fi

echo "✅ MinIO is running"

# Create bucket if it doesn't exist
echo "📦 Creating MinIO bucket: $MINIO_BUCKET"
docker exec minio mc alias set myminio "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"
docker exec minio mc mb myminio/$MINIO_BUCKET --ignore-existing

# Sync data from Azure Storage to MinIO
echo "🔄 Syncing HubSpot communications data..."

# Create a temporary script for the sync operation
cat > /tmp/sync_script.sh << 'EOF'
#!/bin/bash

# Azure Storage account details
AZURE_STORAGE_ACCOUNT="$1"
AZURE_STORAGE_KEY="$2"
MINIO_BUCKET="$3"

# Create container structure in MinIO
docker exec minio mc mb myminio/$MINIO_BUCKET/raw --ignore-existing
docker exec minio mc mb myminio/$MINIO_BUCKET/silver --ignore-existing
docker exec minio mc mb myminio/$MINIO_BUCKET/gold --ignore-existing

# Sync raw data (example for one day)
echo "📥 Syncing raw data from Azure Storage..."
docker exec minio mc cp \
    "https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/raw/hubspot/communications/20250531/" \
    "myminio/$MINIO_BUCKET/raw/hubspot/communications/20250531/" \
    --recursive \
    --ignore-existing

echo "✅ Sync completed!"
EOF

chmod +x /tmp/sync_script.sh

# Run the sync script
/tmp/sync_script.sh "$AZURE_STORAGE_ACCOUNT" "$AZURE_STORAGE_KEY" "$MINIO_BUCKET"

# Clean up
rm /tmp/sync_script.sh

echo "🎉 Azure Storage to MinIO sync completed!"
echo ""
echo "📊 MinIO Console: http://localhost:9001"
echo "   Username: minioadmin"
echo "   Password: minioadmin123"
echo ""
echo "🔗 Data is now available via S3 protocol:"
echo "   s3://$MINIO_BUCKET/raw/hubspot/communications/"
echo ""
echo "📝 Next steps:"
echo "1. Start Unity Catalog: docker-compose up -d unity-catalog"
echo "2. Start DuckDB: docker-compose up -d duckdb"
echo "3. Test queries with S3 paths" 