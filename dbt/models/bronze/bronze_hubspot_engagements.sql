{{
  config(
    materialized='table',
    name='bronze_hubspot_engagements'
  )
}}

SELECT
    id,
    unnest(properties),
    createdAt,
    updatedAt,
    archived,
    filename,
FROM {{ ref('raw_hubspot_engagements') }}
