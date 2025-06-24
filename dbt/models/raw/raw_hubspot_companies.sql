{{
  config(
    materialized='table',
    name='raw_hubspot_companies'
  )
}}

SELECT
  id,
  properties,
  createdAt,
  updatedAt,
  archived,
  filename
FROM {{ source('hubspot', 'companies') }}
