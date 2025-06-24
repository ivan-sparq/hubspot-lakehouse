# HubSpot Lakehouse with Unity Catalog

A modern data lakehouse solution for HubSpot communications data using Unity Catalog, DuckDB, and dbt with MinIO Azure Gateway.

## Architecture

This solution provides a containerized data lakehouse with the following components:

- **Unity Catalog**: Metadata management and S3-compatible storage connectivity
- **MinIO**: S3-compatible gateway to Azure Blob Storage (direct access, no sync needed)
- **DuckDB**: High-performance analytical database (self-serve compute engine)
- **dbt**: Data transformation and modeling
- **Azure Storage**: Data storage for all layers (raw, silver, gold)

## Data Flow

```
Azure Storage (ADLS) ←→ MinIO (S3 Gateway) ←→ Unity Catalog ←→ DuckDB → dbt → Silver/Gold Layers
```

### Why MinIO Azure Gateway?

Unity Catalog has better support for S3-compatible storage than Azure Data Lake Storage (ADLS). MinIO acts as an S3 gateway to Azure Blob Storage, providing:
- **Direct Azure Storage access** - No data sync required
- **Better Unity Catalog compatibility** - Native S3 protocol support
- **Real-time data access** - Data stays in Azure, accessed via S3
- **Unified access** - Single S3 endpoint for all storage operations
- **Future-proof** - Easy migration to other S3-compatible storage

### Data Layers

1. **Raw Layer**: `s3://raw/hubspot/communications/YYYYMMDD/HHMMSS.json`
   - Hourly JSON files from HubSpot
   - Directly accessed from Azure Storage via S3 gateway

2. **Silver Layer**: Cleaned and validated communications data
   - Data quality checks
   - Business logic validation
   - Structured format

3. **Gold Layer**: Aggregated business insights
   - Daily, weekly, monthly summaries
   - Key performance metrics
   - Business intelligence ready

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Azure Storage account access
- Azure Storage key or Service Principal

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hubspot-lakehouse
   ```

2. **Configure environment variables**
   ```bash
   cp env.example .env
   # Edit .env with your Azure Storage credentials
   ```

3. **Start the services**
   ```bash
   docker-compose up -d
   ```

4. **Test Azure gateway configuration**
   ```bash
   ./scripts/test-minio-azure-gateway.sh
   ```

5. **Connect to DuckDB**
   ```bash
   ./scripts/connect-duckdb.sh
   ```

## Services

### MinIO (Ports 9000, 9001)
- **S3-compatible gateway to Azure Blob Storage**
- Web console for data management
- Direct access to Azure Storage containers
- No data sync required

### Unity Catalog (Port 8080)
- Metadata management
- S3 storage connectivity via MinIO
- Schema and table definitions

### DuckDB (Port 8081)
- **Self-serve analytical query engine**
- Unity Catalog integration
- HTTP API for external connections
- **No local data storage** - all data accessed via Azure Storage via S3
- **Compute engine only** - perfect for cloud deployment

### dbt Core
- Data transformation pipeline
- Model development
- Data quality testing

## DuckDB Self-Serve Usage

### Connection Methods

1. **Interactive CLI**
   ```bash
   docker exec -it duckdb duckdb
   ```

2. **HTTP API (for applications)**
   ```bash
   curl http://localhost:8081/health
   ```

3. **MinIO Console**
   ```bash
   http://localhost:9001
   # Username: minioadmin
   # Password: minioadmin123
   ```

4. **Python/Jupyter Integration**
   ```python
   import duckdb
   conn = duckdb.connect('http://localhost:8081')
   ```

5. **Execute SQL files**
   ```bash
   docker exec -i duckdb duckdb < examples/duckdb-queries.sql
   ```

### Example Queries (Azure S3 Paths)

```sql
-- Test Unity Catalog connection
SELECT * FROM unity_catalog_test;

-- Test S3/MinIO connection
SELECT * FROM s3_test;

-- Test Azure Storage access
SELECT * FROM azure_storage_test;

-- Query raw HubSpot data from Azure Storage via S3
SELECT 
    id,
    properties['hs_engagement_type'] as engagement_type,
    properties['hs_createdate'] as created_date
FROM read_json_auto('s3://raw/hubspot/communications/20250531/140000.json')
LIMIT 10;

-- Analyze communications by type
SELECT 
    properties['hs_engagement_type'] as engagement_type,
    COUNT(*) as count
FROM read_json_auto('s3://raw/hubspot/communications/20250531/*.json')
GROUP BY properties['hs_engagement_type'];
```

### Python Integration Example

```python
import duckdb
import pandas as pd

# Connect to DuckDB
conn = duckdb.connect('http://localhost:8081')

# Query data from Azure Storage via S3
df = conn.execute("""
    SELECT 
        id,
        properties['hs_engagement_type'] as engagement_type,
        properties['hs_createdate'] as created_date
    FROM read_json_auto('s3://raw/hubspot/communications/20250531/140000.json')
    LIMIT 10
""").df()

print(df.head())
```

## Data Models

### Staging Layer
- `stg_hubspot_communications`: Cleaned raw data with proper typing

### Silver Layer
- `silver_hubspot_communications`: Validated data with business logic

### Gold Layer
- `gold_communications_summary`: Aggregated insights by day/week/month

## Query Examples

### Basic Data Exploration
```sql
-- Query raw communications from Azure Storage
SELECT * FROM read_json_auto('s3://raw/hubspot/communications/20250531/*.json') LIMIT 10;

-- Query silver layer
SELECT 
    communication_type,
    count(*) as count
FROM read_parquet('s3://silver/silver_hubspot_communications.parquet')
GROUP BY communication_type;

-- Query gold layer summaries
SELECT 
    time_period,
    total_communications,
    total_meetings,
    meeting_completion_rate
FROM read_parquet('s3://gold/gold_communications_summary.parquet')
WHERE granularity = 'daily'
ORDER BY time_period DESC;
```

## Development

### Adding New Models
1. Create new SQL files in `dbt/models/`
2. Follow naming conventions: `stg_*`, `silver_*`, `gold_*`
3. Run `dbt run --select model_name` to test

### Testing
```bash
# Run all tests
dbt test

# Run specific model tests
dbt test --select model_name
```

### Documentation
```bash
# Generate documentation
dbt docs generate
dbt docs serve
```

## Cloud Deployment

This solution is designed for easy cloud deployment:

### Azure Container Instances
- Use the same docker-compose configuration
- Scale DuckDB instances as needed
- No persistent storage required (compute-only)
- MinIO gateway provides S3 access to Azure Storage

### Azure Kubernetes Service
- Deploy as Kubernetes pods
- Auto-scaling based on demand
- Load balancing for multiple DuckDB instances
- MinIO can be deployed as a StatefulSet

### Benefits of Self-Serve DuckDB with MinIO Azure Gateway
- **No data storage costs** - all data in Azure Storage
- **Pay-per-use compute** - scale up/down as needed
- **Unified governance** - all access through Unity Catalog
- **S3 compatibility** - works with any S3-compatible storage
- **High performance** - columnar storage and vectorized execution
- **Better Unity Catalog support** - native S3 protocol
- **Direct Azure access** - no data sync required
- **Real-time data** - always up-to-date from Azure Storage

## Contributing

1. Follow the existing code structure
2. Add tests for new models
3. Update documentation
4. Use conventional commit messages

## License

[Add your license information here]
