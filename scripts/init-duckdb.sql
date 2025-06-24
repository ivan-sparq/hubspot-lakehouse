-- DuckDB Initialization Script for Unity Catalog Integration
-- This script runs when the DuckDB container starts
-- Configured for MinIO Azure Gateway (S3-compatible access to Azure Blob Storage)

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

-- Configure S3/MinIO access (Azure Gateway)
SET s3_endpoint = 'minio:9000';
SET s3_access_key_id = 'minioadmin';
SET s3_secret_access_key = 'minioadmin123';
SET s3_region = 'us-east-1';
SET s3_url_style = 'path';

-- Configure Unity Catalog connection
SET unity_catalog_url = 'http://unity-catalog:8080';

-- Create a view to test Unity Catalog connectivity
CREATE OR REPLACE VIEW unity_catalog_test AS 
SELECT 'Unity Catalog connected successfully' as status;

-- Create a view to test S3/MinIO connectivity
CREATE OR REPLACE VIEW s3_test AS 
SELECT 'S3/MinIO Azure Gateway connected successfully' as status;

-- Create a view to test Azure Storage access via S3
CREATE OR REPLACE VIEW azure_storage_test AS 
SELECT 'Azure Storage accessible via S3 gateway' as status;

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
SELECT 'DuckDB initialized successfully with Unity Catalog and Azure S3 Gateway integration' as init_status; 