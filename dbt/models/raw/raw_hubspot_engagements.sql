{{
  config(
    materialized='table',
    name='raw_hubspot_engagements'
  )
}}

SELECT
  id,
  properties,
  createdAt,
  updatedAt,
  archived,
  filename
FROM {{ source('hubspot', 'engagements') }}
