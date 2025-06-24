-- Example DuckDB Queries for HubSpot Lakehouse
-- These queries demonstrate how to use DuckDB with Unity Catalog and Azure Storage

-- 1. Test Unity Catalog connection
SELECT * FROM unity_catalog_test;

-- 2. Check available extensions
SELECT name, version, loaded 
FROM duckdb_extensions() 
WHERE loaded = true;

-- 3. List Azure Storage files (example)
SELECT 
    name,
    size,
    last_modified
FROM read_parquet('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/*.parquet')
LIMIT 10;

-- 4. Read raw JSON data from Azure Storage
SELECT 
    id,
    properties['hs_engagement_type'] as engagement_type,
    properties['hs_createdate'] as created_date,
    properties['hs_body_preview'] as body_preview
FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/140000.json')
LIMIT 5;

-- 5. Query multiple JSON files (pattern matching)
SELECT 
    id,
    properties['hs_engagement_type'] as engagement_type,
    properties['hs_createdate'] as created_date,
    _filename
FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/*.json')
WHERE properties['hs_engagement_type'] = 'MEETING'
LIMIT 10;

-- 6. Aggregate communications by type
SELECT 
    properties['hs_engagement_type'] as engagement_type,
    COUNT(*) as count,
    MIN(properties['hs_createdate']) as earliest_date,
    MAX(properties['hs_createdate']) as latest_date
FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/*.json')
GROUP BY properties['hs_engagement_type']
ORDER BY count DESC;

-- 7. Create a view for frequently accessed data
CREATE OR REPLACE VIEW hubspot_communications_view AS
SELECT 
    id,
    properties['hs_engagement_type'] as engagement_type,
    properties['hs_createdate'] as created_date,
    properties['hs_lastmodifieddate'] as modified_date,
    properties['hs_body_preview'] as body_preview,
    properties['hubspot_owner_id'] as owner_id,
    properties['hs_meeting_start_time'] as meeting_start,
    properties['hs_meeting_end_time'] as meeting_end,
    properties['hs_meeting_outcome'] as meeting_outcome,
    archived,
    _filename
FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/*/*.json');

-- 8. Query the view
SELECT 
    engagement_type,
    COUNT(*) as total_communications,
    COUNT(CASE WHEN meeting_outcome = 'COMPLETED' THEN 1 END) as completed_meetings
FROM hubspot_communications_view
WHERE engagement_type = 'MEETING'
GROUP BY engagement_type;

-- 9. Time-based analysis
SELECT 
    DATE_TRUNC('hour', CAST(properties['hs_createdate'] AS TIMESTAMP)) as hour,
    COUNT(*) as communications_count
FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/*.json')
GROUP BY DATE_TRUNC('hour', CAST(properties['hs_createdate'] AS TIMESTAMP))
ORDER BY hour;

-- 10. Export query results to Parquet (for further processing)
COPY (
    SELECT 
        id,
        properties['hs_engagement_type'] as engagement_type,
        properties['hs_createdate'] as created_date,
        properties['hs_body_preview'] as body_preview
    FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/*.json')
    WHERE properties['hs_engagement_type'] IS NOT NULL
) TO 'communications_processed.parquet' (FORMAT PARQUET);

-- 11. Performance monitoring query
SELECT 
    query,
    execution_time,
    rows_read,
    rows_written
FROM duckdb_queries()
ORDER BY execution_time DESC
LIMIT 10; 