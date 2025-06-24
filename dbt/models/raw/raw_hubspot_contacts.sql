{{
  config(
    materialized='table',
    name='raw_hubspot_contacts'
  )
}}

SELECT
  id,
  properties,
  createdAt,
  updatedAt,
  archived,
  filename
FROM {{ source('hubspot', 'contacts') }}
