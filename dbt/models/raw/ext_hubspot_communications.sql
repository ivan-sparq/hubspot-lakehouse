{{
  config(
    materialized='table',
    name='ext_hubspot_communications'
  )
}}

SELECT
id, properties, createdAt, updatedAt, archived, filename,
FROM 'az://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/*.json'
