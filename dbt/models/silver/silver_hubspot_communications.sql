{{
  config(
    materialized='table',
    partition_by={
      "field": "hs_timestamp",
      "data_type": "timestamp",
      "granularity": "hour"
    }
  )
}}

with staging as (
    select * from {{ ref('stg_hubspot_communications') }}
),

validated as (
    select
        *,
        -- Data quality checks
        case 
            when communication_id is not null and communication_id != '' then true
            else false 
        end as is_valid_id,
        
        case 
            when hs_timestamp is not null then true
            else false 
        end as is_valid_timestamp,
        
        case 
            when engagement_type is not null then true
            else false 
        end as is_valid_engagement_type,
        
        -- Business logic validations
        case 
            when meeting_start_time is not null and meeting_end_time is not null 
            and meeting_start_time < meeting_end_time then true
            else false 
        end as is_valid_meeting_times,
        
        case 
            when call_duration_seconds is null or call_duration_seconds >= 0 then true
            else false 
        end as is_valid_call_duration
        
    from staging
),

enriched as (
    select
        -- Core fields
        communication_id,
        created_at,
        updated_at,
        hs_created_at,
        hs_modified_at,
        hs_timestamp,
        
        -- Meeting fields
        meeting_start_time,
        meeting_end_time,
        meeting_outcome,
        meeting_location,
        meeting_duration_minutes,
        
        -- Communication fields
        engagement_type,
        activity_type,
        channel_type,
        email_direction,
        email_subject,
        body_preview,
        communication_type,
        
        -- Call fields
        call_direction,
        call_disposition,
        call_duration_seconds,
        
        -- Other fields
        attachment_ids,
        owner_id,
        object_id,
        associated_contacts,
        associated_companies,
        is_archived,
        
        -- Quality flags
        is_valid_id,
        is_valid_timestamp,
        is_valid_engagement_type,
        is_valid_meeting_times,
        is_valid_call_duration,
        
        -- Derived business fields
        case 
            when is_valid_id and is_valid_timestamp and is_valid_engagement_type 
            then true 
            else false 
        end as is_high_quality_record,
        
        -- Time-based fields
        year,
        month,
        day,
        hour,
        date_part('dow', hs_timestamp) as day_of_week,
        date_part('week', hs_timestamp) as week_of_year,
        
        -- Metadata
        _loaded_at
        
    from validated
),

final as (
    select
        *,
        -- Additional business logic
        case 
            when communication_type = 'meeting' and meeting_duration_minutes > 60 then 'long_meeting'
            when communication_type = 'meeting' and meeting_duration_minutes between 30 and 60 then 'medium_meeting'
            when communication_type = 'meeting' and meeting_duration_minutes < 30 then 'short_meeting'
            when communication_type = 'call' and call_duration_seconds > 300 then 'long_call'
            when communication_type = 'call' and call_duration_seconds between 60 and 300 then 'medium_call'
            when communication_type = 'call' and call_duration_seconds < 60 then 'short_call'
            else 'other'
        end as communication_category
        
    from enriched
)

select * from final 