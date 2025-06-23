

# HubSpot Lakehouse with Unity Catalog

A modern data lakehouse solution for HubSpot communications data using Unity Catalog, DuckDB, and dbt.

## Architecture

This solution provides a containerized data lakehouse with the following components:

- **Unity Catalog**: Metadata management and Azure Storage connectivity
- **DuckDB**: High-performance analytical database
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

5. **Query data with DuckDB**
   ```bash
   docker exec -it duckdb duckdb
   # Connect to Unity Catalog and query data
   ```

## Services

### Unity Catalog (Port 8080)
- Metadata management
- Azure Storage connectivity
- Schema and table definitions

### DuckDB (Port 8081)
- Analytical query engine
- Unity Catalog integration
- HTTP API for external connections

### dbt Core
- Data transformation pipeline
- Model development
- Data quality testing

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

## Deployment

This solution is designed to be easily deployable to Azure Container Instances or Azure Kubernetes Service. The same container images and configurations can be used in the cloud with minimal changes.

## Contributing

1. Follow the existing code structure
2. Add tests for new models
3. Update documentation
4. Use conventional commit messages

## License

[Add your license information here]
