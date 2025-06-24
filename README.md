# HubSpot Lakehouse

A modern data lakehouse solution for HubSpot data using DuckDB, dbt, and Azure Blob Storage.

## 🏗️ Architecture

This project implements a medallion architecture:
- **Raw Layer**: Direct ingestion from HubSpot APIs to Azure Blob Storage
- **Bronze Layer**: Flattened and cleaned data using dbt
- **Silver Layer**: Business logic and transformations
- **Gold Layer**: Aggregated and curated data for analytics

## 🚀 Quick Start

### Prerequisites

- Python 3.12+
- Azure Storage Account with Blob Storage
- HubSpot API access

### 1. Install Dependencies

```bash
uv sync
source .venv/bin/activate
```

### 2. Set Up DuckDB Locally

#### Install DuckDB

**macOS (using Homebrew):**
```bash
brew install duckdb
```



#### Verify Installation
```bash
duckdb --version
```

### 3. Configure Azure Authentication


####  Azure CLI Authentication (Development)

```bash
# Login with Azure CLI
az login

# Set subscription
az account set --subscription "195658e6-d263-4cc9-9049-a6909ca5b2f6"
```

### 4. Configure DuckDB for Azure

#### Install Required Extensions

Connect to DuckDB and install extensions:


#### Connect to DuckDB
```bash
duckdb dev.db
```
#### Install required extensions
```sql

INSTALL azure;
INSTALL httpfs;
LOAD azure;
LOAD httpfs;
```

#### Configure Azure Authentication
```sql
CREATE SECRET IF NOT EXISTS azure_creds (
    TYPE azure,
    PROVIDER credential_chain,
    SCOPE 'az://strprimrosedatalake.blob.core.windows.net/'
);
```

### 5. Configure dbt

```bash
dbt deps
```

### 6. Test Configuration

#### Test Azure Connection

```sql
-- Test reading from Azure Blob Storage
SELECT * FROM read_json('az://your-container/path/to/file.json') LIMIT 5;
```

#### Test dbt

```bash
# Test dbt connection
dbt debug

# Run a simple model
dbt run --select raw_hubspot_communications
```

## 📁 Project Structure

```
hubspot-lakehouse/
├── dbt/
│   ├── models/
│   │   ├── raw/           # Raw data models
│   │   ├── bronze/        # Flattened and cleaned data
│   │   ├── silver/        # Business logic transformations
│   │   └── gold/          # Aggregated data
│   ├── sources.yml        # Source definitions
│   └── profiles.yml       # dbt profile configuration
├── config/
│   ├── duckdb/           # DuckDB configuration
│   └── unity-catalog/    # Unity Catalog configuration
├── docs/                 # Documentation
├── examples/             # Example notebooks and scripts
└── tests/                # Test files
```

## 🔧 Development

### Running dbt Models

```bash
# Run all models
dbt run

# Run specific model
dbt run --select bronze_hubspot_communications

# Run models with dependencies
dbt run --select +bronze_hubspot_communications

# Run models in a specific folder
dbt run --select raw/*
```

### Testing

```bash
# Run all tests
dbt test

# Run specific test
dbt test --select test_name
```

### Documentation

```bash
# Generate documentation
dbt docs generate

# Serve documentation
dbt docs serve
```

### Debugging

```bash
# Debug dbt configuration
dbt debug

# Show model lineage
dbt ls --select +model_name

# Show model SQL
dbt compile --select model_name
```

## 🔐 Security Best Practices

1. **Use Service Principals** for production environments
2. **Rotate Access Keys** regularly
3. **Use Managed Identities** when possible
4. **Store Secrets** in Azure Key Vault
5. **Limit Permissions** to minimum required access

## 🐛 Troubleshooting

### Common Issues

1. **Azure Authentication Errors:**
   - Verify service principal permissions
   - Check environment variables
   - Ensure storage account access

2. **DuckDB Extension Issues:**
   - Reinstall extensions: `INSTALL azure; LOAD azure;`
   - Check DuckDB version compatibility

3. **dbt Connection Issues:**
   - Run `dbt debug` to diagnose
   - Check `profiles.yml` configuration
   - Verify Azure credentials

### Getting Help

- Check [DuckDB Azure documentation](https://duckdb.org/docs/extensions/azure)
- Review [dbt DuckDB adapter docs](https://github.com/jwills/dbt-duckdb)
- Open an issue in this repository

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
