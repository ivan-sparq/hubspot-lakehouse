{{
  config(
    materialized='table',
    name='bronze_hubspot_communications'
  )
}}


SELECT
    id,
    unnest(properties),
    createdAt,
    updatedAt,
    archived,
    filename,
FROM {{ ref('raw_hubspot_communications') }}
