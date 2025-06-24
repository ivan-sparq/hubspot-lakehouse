#!/bin/bash

# DuckDB Connection Script
# This script provides multiple ways to connect to the DuckDB container

echo "🦆 DuckDB Connection Options (MinIO with ILM)"
echo "============================================"
echo ""

# Check if containers are running
if ! docker ps | grep -q duckdb; then
    echo "❌ DuckDB container is not running. Start it with:"
    echo "   docker-compose up -d"
    exit 1
fi

if ! docker ps | grep -q minio; then
    echo "❌ MinIO container is not running. Start it with:"
    echo "   docker-compose up -d minio"
    exit 1
fi

echo "✅ DuckDB and MinIO containers are running"
echo ""

echo "1. 🖥️  Interactive DuckDB CLI:"
echo "   docker exec -it duckdb duckdb"
echo ""

echo "2. 🌐 HTTP API (for applications):"
echo "   http://localhost:8081"
echo ""

echo "3. 📊 MinIO Console:"
echo "   http://localhost:9001"
echo "   Username: minioadmin"
echo "   Password: minioadmin123"
echo ""

echo "4. 📊 Connect from Jupyter/Python:"
echo "   import duckdb"
echo "   conn = duckdb.connect('http://localhost:8081')"
echo ""

echo "5. 🔧 Run SQL file:"
echo "   docker exec -i duckdb duckdb < examples/duckdb-queries.sql"
echo ""

echo "6. 📝 Execute single query:"
echo "   docker exec duckdb duckdb -c \"SELECT * FROM unity_catalog_test;\""
echo ""

echo "7. 🧪 Health check:"
echo "   curl http://localhost:8081/health"
echo ""

echo "📚 Example queries (MinIO S3 paths):"
echo "===================================="
echo ""
echo "# Test Unity Catalog connection:"
echo "SELECT * FROM unity_catalog_test;"
echo ""
echo "# Test S3/MinIO connection:"
echo "SELECT * FROM s3_test;"
echo ""
echo "# Test Azure Storage access:"
echo "SELECT * FROM azure_storage_test;"
echo ""
echo "# Check available extensions:"
echo "SELECT name FROM duckdb_extensions() WHERE loaded = true;"
echo ""
echo "# Query MinIO data (with ILM to Azure):"
echo "SELECT * FROM read_json_auto('s3://raw/hubspot/communications/20250531/140000.json');"
echo ""
echo "# List MinIO buckets:"
echo "SELECT name, size FROM read_parquet('s3://raw/hubspot/communications/*.parquet');"
echo ""

echo "🔄 Setup MinIO with Azure ILM:"
echo "============================="
echo "To setup MinIO with Azure Object Lifecycle Management:"
echo "./scripts/setup-minio-azure-ilm.sh"
echo ""
echo "To sync initial data from Azure to MinIO:"
echo "./scripts/sync-azure-to-minio-initial.sh"
echo ""

echo "🔗 Unity Catalog Integration:"
echo "============================"
echo "DuckDB is configured to work with Unity Catalog for metadata management."
echo "All data queries go through MinIO with automatic ILM transitions to Azure."
echo ""

echo "📁 MinIO Bucket Structure:"
echo "========================="
echo "s3://raw/hubspot/communications/YYYYMMDD/HHMMSS.json"
echo "s3://silver/ (processed data)"
echo "s3://gold/ (aggregated insights)"
echo ""
echo "📋 ILM Configuration:"
echo "   - Raw data transitions to Azure after 7 days"
echo "   - Silver data transitions to Azure after 3 days"
echo "   - Gold data transitions to Azure after 1 day"
echo "" 