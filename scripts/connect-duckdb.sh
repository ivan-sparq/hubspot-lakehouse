#!/bin/bash

# DuckDB Connection Script
# This script provides multiple ways to connect to the DuckDB container

echo "🦆 DuckDB Connection Options"
echo "=========================="
echo ""

# Check if container is running
if ! docker ps | grep -q duckdb; then
    echo "❌ DuckDB container is not running. Start it with:"
    echo "   docker-compose up -d duckdb"
    exit 1
fi

echo "✅ DuckDB container is running"
echo ""

echo "1. 🖥️  Interactive DuckDB CLI:"
echo "   docker exec -it duckdb duckdb"
echo ""

echo "2. 🌐 HTTP API (for applications):"
echo "   http://localhost:8081"
echo ""

echo "3. 📊 Connect from Jupyter/Python:"
echo "   import duckdb"
echo "   conn = duckdb.connect('http://localhost:8081')"
echo ""

echo "4. 🔧 Run SQL file:"
echo "   docker exec -i duckdb duckdb < your_query.sql"
echo ""

echo "5. 📝 Execute single query:"
echo "   docker exec duckdb duckdb -c \"SELECT * FROM unity_catalog_test;\""
echo ""

echo "6. 🧪 Health check:"
echo "   curl http://localhost:8081/health"
echo ""

echo "📚 Example queries:"
echo "=================="
echo ""
echo "# Test Unity Catalog connection:"
echo "SELECT * FROM unity_catalog_test;"
echo ""
echo "# Check available extensions:"
echo "SELECT name FROM duckdb_extensions() WHERE loaded = true;"
echo ""
echo "# Query Azure Storage data:"
echo "SELECT * FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/140000.json');"
echo ""

echo "🔗 Unity Catalog Integration:"
echo "============================"
echo "DuckDB is configured to work with Unity Catalog for metadata management."
echo "All data queries will go through Unity Catalog for governance and access control." 