{{
  config(
    materialized='table',
    name='ext_hubspot_communications'
  )
}}

SELECT
  id,
  properties,
  createdAt,
  updatedAt,
  archived,
  filename
FROM {{ source('hubspot', 'communications') }}
