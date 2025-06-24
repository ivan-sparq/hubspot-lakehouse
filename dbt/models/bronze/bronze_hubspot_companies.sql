{{
  config(
    materialized='table',
    name='bronze_hubspot_companies'
  )
}}

SELECT
    id,
    unnest(properties),
    createdAt,
    updatedAt,
    archived,
    filename,
FROM {{ ref('raw_hubspot_companies') }}
