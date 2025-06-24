{{
  config(
    materialized='table',
    name='bronze_hubspot_deals'
  )
}}

SELECT
    id,
    unnest(properties),
    createdAt,
    updatedAt,
    archived,
    filename,
FROM {{ ref('raw_hubspot_deals') }}
