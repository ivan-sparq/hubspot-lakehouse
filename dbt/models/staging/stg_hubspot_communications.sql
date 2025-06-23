{{
  config(
    materialized='view'
  )
}}

with source as (
    select * from {{ source('raw', 'hubspot_communications') }}
),

cleaned as (
    select
        -- Primary key
        id as communication_id,
        
        -- Timestamps
        try_cast(createdAt as timestamp) as created_at,
        try_cast(updatedAt as timestamp) as updated_at,
        try_cast(properties['hs_createdate'] as timestamp) as hs_created_at,
        try_cast(properties['hs_lastmodifieddate'] as timestamp) as hs_modified_at,
        try_cast(properties['hs_timestamp'] as timestamp) as hs_timestamp,
        
        -- Meeting specific fields
        try_cast(properties['hs_meeting_start_time'] as timestamp) as meeting_start_time,
        try_cast(properties['hs_meeting_end_time'] as timestamp) as meeting_end_time,
        properties['hs_meeting_outcome'] as meeting_outcome,
        properties['hs_meeting_location'] as meeting_location,
        
        -- Communication details
        properties['hs_engagement_type'] as engagement_type,
        properties['hs_activity_type'] as activity_type,
        properties['hs_communication_channel_type'] as channel_type,
        properties['hs_email_direction'] as email_direction,
        properties['hs_email_subject'] as email_subject,
        properties['hs_body_preview'] as body_preview,
        
        -- Call specific fields
        properties['hs_call_direction'] as call_direction,
        properties['hs_call_disposition'] as call_disposition,
        try_cast(properties['hs_call_duration'] as integer) as call_duration_seconds,
        
        -- Attachments
        properties['hs_attachment_ids'] as attachment_ids,
        
        -- Ownership
        properties['hubspot_owner_id'] as owner_id,
        properties['hs_object_id'] as object_id,
        
        -- Associated entities
        properties['associated_contacts'] as associated_contacts,
        properties['associated_companies'] as associated_companies,
        
        -- Status
        archived as is_archived,
        
        -- Metadata
        current_timestamp as _loaded_at
        
    from source
),

final as (
    select
        *,
        -- Derived fields
        case 
            when meeting_start_time is not null and meeting_end_time is not null 
            then date_diff('minute', meeting_start_time, meeting_end_time)
            else null 
        end as meeting_duration_minutes,
        
        case 
            when engagement_type = 'MEETING' then 'meeting'
            when engagement_type = 'EMAIL' then 'email'
            when engagement_type = 'CALL' then 'call'
            else 'other'
        end as communication_type,
        
        -- Date partitions for efficient querying
        date_part('year', coalesce(hs_timestamp, created_at)) as year,
        date_part('month', coalesce(hs_timestamp, created_at)) as month,
        date_part('day', coalesce(hs_timestamp, created_at)) as day,
        date_part('hour', coalesce(hs_timestamp, created_at)) as hour
        
    from cleaned
)

select * from final 