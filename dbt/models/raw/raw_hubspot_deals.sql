{{
  config(
    materialized='table',
    name='raw_hubspot_deals'
  )
}}

SELECT
  id,
  properties,
  createdAt,
  updatedAt,
  archived,
  filename
FROM {{ source('hubspot', 'deals') }}
