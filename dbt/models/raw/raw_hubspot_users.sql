{{
  config(
    materialized='table',
    name='raw_hubspot_users'
  )
}}

SELECT
  id,
  properties,
  createdAt,
  updatedAt,
  archived,
  filename
FROM {{ source('hubspot', 'users') }}
