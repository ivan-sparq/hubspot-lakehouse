{{
  config(
    materialized='table',
    name='raw_hubspot_engagements'
  )
}}

SELECT
  engagement,
  associations,
  attachments,
  scheduledTasks,
  metadata,
  filename
FROM {{ source('hubspot', 'engagements') }}
