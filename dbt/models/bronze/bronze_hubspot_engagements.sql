{{
  config(
    materialized='table',
    name='bronze_hubspot_engagements'
  )
}}

WITH flattened_engagement AS (
  SELECT
    json_transform(engagement, '{
      "id": "BIGINT",
      "portalId": "BIGINT",
      "active": "BOOLEAN",
      "createdAt": "BIGINT",
      "lastUpdated": "BIGINT",
      "createdBy": "BIGINT",
      "modifiedBy": "BIGINT",
      "ownerId": "BIGINT",
      "type": "VARCHAR",
      "uid": "VARCHAR",
      "timestamp": "BIGINT",
      "allAccessibleTeamIds": "JSON",
      "bodyPreview": "VARCHAR",
      "queueMembershipIds": "JSON",
      "bodyPreviewIsTruncated": "BOOLEAN",
      "bodyPreviewHtml": "VARCHAR"
    }') as engagement_struct,
    associations,
    attachments,
    scheduledTasks,
    json_transform(metadata, '{
      "startTime": "BIGINT",
      "endTime": "BIGINT",
      "title": "VARCHAR",
      "body": "VARCHAR",
      "externalUrl": "VARCHAR",
      "location": "VARCHAR",
      "source": "VARCHAR",
      "sourceId": "VARCHAR",
      "preMeetingProspectReminders": "JSON",
      "iCalUid": "VARCHAR",
      "attendeeOwnerIds": "JSON",
      "guestEmails": "JSON",
      "videoConferenceUrl": "VARCHAR"
    }') as metadata_struct,
    filename
  FROM {{ ref('raw_hubspot_engagements') }}
)

SELECT
  engagement_struct.id,
  engagement_struct.portalId,
  engagement_struct.active,
  engagement_struct.createdAt,
  engagement_struct.lastUpdated,
  engagement_struct.createdBy,
  engagement_struct.modifiedBy,
  engagement_struct.ownerId,
  engagement_struct.type,
  engagement_struct.uid,
  engagement_struct.timestamp,
  engagement_struct.allAccessibleTeamIds,
  engagement_struct.bodyPreview,
  engagement_struct.queueMembershipIds,
  engagement_struct.bodyPreviewIsTruncated,
  engagement_struct.bodyPreviewHtml,
  associations,
  attachments,
  scheduledTasks,
  metadata_struct.startTime,
  metadata_struct.endTime,
  metadata_struct.title,
  metadata_struct.body,
  metadata_struct.externalUrl,
  metadata_struct.location,
  metadata_struct.source,
  metadata_struct.sourceId,
  metadata_struct.preMeetingProspectReminders,
  metadata_struct.iCalUid,
  metadata_struct.attendeeOwnerIds,
  metadata_struct.guestEmails,
  metadata_struct.videoConferenceUrl,
  filename,
FROM flattened_engagement
