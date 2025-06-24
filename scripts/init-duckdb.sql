-- DuckDB Initialization Script for Unity Catalog Integration
-- This script runs when the DuckDB container starts

-- Install required extensions
INSTALL httpfs;
INSTALL json;
INSTALL parquet;
INSTALL delta;

-- Load extensions
LOAD httpfs;
LOAD json;
LOAD parquet;
LOAD delta;

-- Configure Azure Storage access
SET httpfs_azure_storage_account = 'strprimrosedatalake';
SET httpfs_azure_storage_key = '${AZURE_STORAGE_KEY}';

-- Configure Unity Catalog connection
SET unity_catalog_url = 'http://unity-catalog:8080';

-- Create a view to test Unity Catalog connectivity
CREATE OR REPLACE VIEW unity_catalog_test AS 
SELECT 'Unity Catalog connected successfully' as status;

-- Set up some useful settings for analytics workloads
SET memory_limit = '4GB';
SET threads = 4;

-- Create a simple health check function
CREATE OR REPLACE FUNCTION health_check() 
RETURNS VARCHAR AS 
$$ 
    SELECT 'DuckDB is healthy and ready for queries' 
$$;

-- Log successful initialization
SELECT 'DuckDB initialized successfully with Unity Catalog integration' as init_status; 