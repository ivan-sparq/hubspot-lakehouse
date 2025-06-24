# HubSpot Lakehouse POC

A proof-of-concept data lakehouse solution using **Unity Catalog**, **DuckDB**, and **dbt core** to process HubSpot communications data. This solution uses **MinIO** as a standalone object storage server with **Object Lifecycle Management (ILM)** to automatically transition data to Azure Storage for cost optimization.

## Architecture

```
Azure Storage (ADLS) ←→ MinIO (Standalone + ILM) ←→ Unity Catalog ←→ DuckDB → dbt
```

### Key Components

- **MinIO**: Standalone object storage server with ILM for automatic Azure transitions
- **Unity Catalog**: Open-source metadata catalog for data governance
- **DuckDB**: In-process analytical database for fast queries
- **dbt**: Data transformation and modeling
- **Azure Storage**: Long-term data storage with automatic transitions

### Data Flow

1. **Raw Data**: HubSpot communications data stored in Azure Storage
2. **Initial Sync**: Data synced to MinIO for local processing
3. **Processing**: Unity Catalog + DuckDB + dbt transform data through silver → gold layers
4. **ILM Transitions**: MinIO automatically transitions objects to Azure based on lifecycle rules
5. **Cost Optimization**: Recent data stays local for performance, older data moves to Azure

## Prerequisites

- Docker and Docker Compose
- Azure Storage account with HubSpot data
- Python 3.8+ (for local development)

## Quick Start

### 1. Environment Setup

```bash
# Copy environment template
cp env.example .env

# Edit .env with your Azure Storage credentials
AZURE_STORAGE_ACCOUNT=your-storage-account
AZURE_STORAGE_KEY=your-storage-key
```

### 2. Start Services

```bash
# Start MinIO standalone server
docker-compose up -d minio

# Setup MinIO with Azure ILM
./scripts/setup-minio-azure-ilm.sh

# Sync initial data from Azure to MinIO
./scripts/sync-azure-to-minio-initial.sh

# Start Unity Catalog and DuckDB
docker-compose up -d unity-catalog duckdb
```

### 3. Verify Setup

```bash
# Check service status
docker-compose ps

# Test DuckDB connection
./scripts/connect-duckdb.sh

# Run example queries
docker exec -i duckdb duckdb < examples/duckdb-queries.sql
```

## Configuration

### MinIO ILM Rules

The setup configures automatic transitions to Azure Storage:

- **Raw data**: Transitions to Azure after 7 days
- **Silver data**: Transitions to Azure after 3 days  
- **Gold data**: Transitions to Azure after 1 day

### Data Paths

```
s3://raw/hubspot/communications/YYYYMMDD/HHMMSS.json
s3://silver/ (processed data)
s3://gold/ (aggregated insights)
```

## Usage

### DuckDB Queries

```sql
-- Test connections
SELECT * FROM unity_catalog_test;
SELECT * FROM s3_test;
SELECT * FROM azure_storage_test;

-- Query HubSpot data
SELECT * FROM read_json_auto('s3://raw/hubspot/communications/20250531/140000.json');

-- Process data through layers
SELECT 
    communication_id,
    contact_id,
    channel_type,
    created_at,
    status
FROM read_json_auto('s3://raw/hubspot/communications/*.json')
WHERE created_at >= '2025-05-31';
```

### Python Integration

```python
import duckdb

# Connect to DuckDB
conn = duckdb.connect('http://localhost:8081')

# Query data
df = conn.execute("""
    SELECT * FROM read_json_auto('s3://raw/hubspot/communications/*.json')
    LIMIT 10
""").df()

print(df)
```

### dbt Models

```bash
# Navigate to dbt project
cd dbt

# Run dbt models
dbt run --profiles-dir config/dbt

# Generate documentation
dbt docs generate
```

## Services

| Service | URL | Credentials |
|---------|-----|-------------|
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin123 |
| MinIO API | http://localhost:9000 | minioadmin / minioadmin123 |
| Unity Catalog | http://localhost:8080 | - |
| DuckDB HTTP | http://localhost:8081 | - |

## Data Model

### Staging Layer (`dbt/models/staging/`)

Raw data ingestion and basic cleaning:

```sql
-- stg_hubspot_communications.sql
SELECT 
    communication_id,
    contact_id,
    channel_type,
    created_at,
    status,
    metadata
FROM {{ source('raw', 'hubspot_communications') }}
```

### Silver Layer (`dbt/models/silver/`)

Cleaned and validated data:

```sql
-- silver_communications.sql
SELECT 
    communication_id,
    contact_id,
    channel_type,
    created_at,
    status,
    CASE 
        WHEN status = 'SENT' THEN 'SUCCESS'
        WHEN status = 'FAILED' THEN 'FAILED'
        ELSE 'PENDING'
    END as delivery_status
FROM {{ ref('stg_hubspot_communications') }}
WHERE created_at IS NOT NULL
```

### Gold Layer (`dbt/models/gold/`)

Business insights and aggregations:

```sql
-- gold_daily_communications_summary.sql
SELECT 
    DATE(created_at) as date,
    channel_type,
    delivery_status,
    COUNT(*) as total_communications,
    COUNT(CASE WHEN delivery_status = 'SUCCESS' THEN 1 END) as successful_communications
FROM {{ ref('silver_communications') }}
GROUP BY 1, 2, 3
```

## Development

### Adding New Data Sources

1. Add source configuration in `dbt/models/staging/_sources.yml`
2. Create staging model in `dbt/models/staging/`
3. Create silver model in `dbt/models/silver/`
4. Create gold model in `dbt/models/gold/`

### MinIO Management

```bash
# Access MinIO console
open http://localhost:9001

# List buckets
docker exec minio mc ls myminio

# Upload files
docker exec minio mc cp local-file.json myminio/raw/

# Check ILM rules
docker exec minio mc ilm rule ls myminio/raw --transition
```

### Unity Catalog Integration

Unity Catalog provides metadata management and governance:

- **Data Discovery**: Browse and search datasets
- **Lineage Tracking**: Understand data dependencies
- **Access Control**: Manage permissions and policies
- **Data Quality**: Monitor and validate data

## Troubleshooting

### Common Issues

1. **MinIO not starting**: Check Docker logs with `docker-compose logs minio`
2. **Azure connection issues**: Verify credentials in `.env` file
3. **DuckDB connection errors**: Ensure MinIO is running first
4. **ILM not working**: Check MinIO logs and verify Azure credentials

### Logs

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs minio
docker-compose logs unity-catalog
docker-compose logs duckdb
```

## Production Considerations

### Security

- Use Azure Managed Identity instead of storage keys
- Enable TLS for all connections
- Implement proper access controls
- Use Azure Key Vault for secrets management

### Performance

- Configure MinIO with appropriate resources
- Use DuckDB's parallel processing capabilities
- Optimize dbt models for incremental processing
- Monitor ILM transition performance

### Monitoring

- Set up health checks for all services
- Monitor Azure Storage costs
- Track data processing metrics
- Implement alerting for failures

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [MinIO Object Lifecycle Management](https://min.io/docs/minio/linux/administration/object-management/transition-objects-to-azure.html)
- [Unity Catalog Documentation](https://docs.databricks.com/data-governance/unity-catalog/index.html)
- [DuckDB Documentation](https://duckdb.org/docs/)
- [dbt Documentation](https://docs.getdbt.com/)
