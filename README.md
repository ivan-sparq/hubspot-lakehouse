# HubSpot Lakehouse with Unity Catalog

A modern data lakehouse solution for HubSpot communications data using Unity Catalog, DuckDB, and dbt.

## Architecture

This solution provides a containerized data lakehouse with the following components:

- **Unity Catalog**: Metadata management and Azure Storage connectivity
- **DuckDB**: High-performance analytical database (self-serve compute engine)
- **dbt**: Data transformation and modeling
- **Azure Storage**: Data storage for all layers (raw, silver, gold)

## Data Flow

```
Azure Storage (Raw JSON) → Unity Catalog → DuckDB → dbt → Silver/Gold Layers
```

### Data Layers

1. **Raw Layer**: `hubspot/communications/YYYYMMDD/HHMMSS.json`
   - Hourly JSON files from HubSpot
   - Stored in Azure Storage container `raw`

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

4. **Initialize dbt project**
   ```bash
   docker exec -it dbt-core bash
   dbt deps
   dbt run
   ```

5. **Connect to DuckDB**
   ```bash
   ./scripts/connect-duckdb.sh
   ```

## Services

### Unity Catalog (Port 8080)
- Metadata management
- Azure Storage connectivity
- Schema and table definitions

### DuckDB (Port 8081)
- **Self-serve analytical query engine**
- Unity Catalog integration
- HTTP API for external connections
- **No local data storage** - all data accessed via Azure Storage
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

3. **Python/Jupyter Integration**
   ```python
   import duckdb
   conn = duckdb.connect('http://localhost:8081')
   ```

4. **Execute SQL files**
   ```bash
   docker exec -i duckdb duckdb < examples/duckdb-queries.sql
   ```

### Example Queries

```sql
-- Test Unity Catalog connection
SELECT * FROM unity_catalog_test;

-- Query raw HubSpot data from Azure Storage
SELECT 
    id,
    properties['hs_engagement_type'] as engagement_type,
    properties['hs_createdate'] as created_date
FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/140000.json')
LIMIT 10;

-- Analyze communications by type
SELECT 
    properties['hs_engagement_type'] as engagement_type,
    COUNT(*) as count
FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/*.json')
GROUP BY properties['hs_engagement_type'];
```

### Python Integration Example

```python
import duckdb
import pandas as pd

# Connect to DuckDB
conn = duckdb.connect('http://localhost:8081')

# Query data
df = conn.execute("""
    SELECT 
        id,
        properties['hs_engagement_type'] as engagement_type,
        properties['hs_createdate'] as created_date
    FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/140000.json')
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
-- Query raw communications
SELECT * FROM raw.hubspot_communications LIMIT 10;

-- Query silver layer
SELECT 
    communication_type,
    count(*) as count
FROM silver.silver_hubspot_communications 
GROUP BY communication_type;

-- Query gold layer summaries
SELECT 
    time_period,
    total_communications,
    total_meetings,
    meeting_completion_rate
FROM gold.gold_communications_summary 
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

### Azure Kubernetes Service
- Deploy as Kubernetes pods
- Auto-scaling based on demand
- Load balancing for multiple DuckDB instances

### Benefits of Self-Serve DuckDB
- **No data storage costs** - all data in Azure Storage
- **Pay-per-use compute** - scale up/down as needed
- **Unified governance** - all access through Unity Catalog
- **Multi-format support** - JSON, Parquet, Delta, etc.
- **High performance** - columnar storage and vectorized execution

## Contributing

1. Follow the existing code structure
2. Add tests for new models
3. Update documentation
4. Use conventional commit messages

## License

[Add your license information here]
