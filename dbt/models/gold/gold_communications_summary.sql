{{
  config(
    materialized='table'
  )
}}

with silver as (
    select * from {{ ref('silver_hubspot_communications') }}
    where is_high_quality_record = true
),

daily_summary as (
    select
        -- Date dimensions
        date_trunc('day', hs_timestamp) as date,
        year,
        month,
        day,
        day_of_week,
        
        -- Communication counts by type
        count(*) as total_communications,
        count(case when communication_type = 'meeting' then 1 end) as total_meetings,
        count(case when communication_type = 'email' then 1 end) as total_emails,
        count(case when communication_type = 'call' then 1 end) as total_calls,
        count(case when communication_type = 'other' then 1 end) as total_other,
        
        -- Meeting metrics
        count(case when communication_type = 'meeting' and meeting_outcome = 'COMPLETED' then 1 end) as completed_meetings,
        count(case when communication_type = 'meeting' and meeting_outcome = 'CANCELLED' then 1 end) as cancelled_meetings,
        avg(case when communication_type = 'meeting' then meeting_duration_minutes end) as avg_meeting_duration_minutes,
        sum(case when communication_type = 'meeting' then meeting_duration_minutes end) as total_meeting_minutes,
        
        -- Call metrics
        count(case when communication_type = 'call' and call_duration_seconds > 0 then 1 end) as successful_calls,
        avg(case when communication_type = 'call' then call_duration_seconds end) as avg_call_duration_seconds,
        sum(case when communication_type = 'call' then call_duration_seconds end) as total_call_seconds,
        
        -- Quality metrics
        count(case when is_high_quality_record then 1 end) as high_quality_records,
        count(case when not is_high_quality_record then 1 end) as low_quality_records,
        
        -- Owner activity
        count(distinct owner_id) as active_owners,
        
        -- Time-based patterns
        count(case when hour between 9 and 17 then 1 end) as business_hours_communications,
        count(case when hour < 9 or hour > 17 then 1 end) as after_hours_communications
        
    from silver
    group by 1, 2, 3, 4, 5
),

weekly_summary as (
    select
        date_trunc('week', date) as week_start,
        year,
        week_of_year,
        
        -- Weekly aggregations
        sum(total_communications) as weekly_communications,
        sum(total_meetings) as weekly_meetings,
        sum(total_emails) as weekly_emails,
        sum(total_calls) as weekly_calls,
        
        -- Weekly averages
        avg(total_communications) as avg_daily_communications,
        avg(total_meetings) as avg_daily_meetings,
        avg(total_emails) as avg_daily_emails,
        avg(total_calls) as avg_daily_calls,
        
        -- Weekly totals
        sum(total_meeting_minutes) as weekly_meeting_minutes,
        sum(total_call_seconds) as weekly_call_seconds,
        
        -- Weekly quality
        sum(high_quality_records) as weekly_high_quality,
        sum(low_quality_records) as weekly_low_quality
        
    from daily_summary
    group by 1, 2, 3
),

monthly_summary as (
    select
        date_trunc('month', date) as month_start,
        year,
        month,
        
        -- Monthly aggregations
        sum(total_communications) as monthly_communications,
        sum(total_meetings) as monthly_meetings,
        sum(total_emails) as monthly_emails,
        sum(total_calls) as monthly_calls,
        
        -- Monthly averages
        avg(total_communications) as avg_daily_communications_monthly,
        avg(total_meetings) as avg_daily_meetings_monthly,
        avg(total_emails) as avg_daily_emails_monthly,
        avg(total_calls) as avg_daily_calls_monthly,
        
        -- Monthly totals
        sum(total_meeting_minutes) as monthly_meeting_minutes,
        sum(total_call_seconds) as monthly_call_seconds,
        
        -- Monthly quality
        sum(high_quality_records) as monthly_high_quality,
        sum(low_quality_records) as monthly_low_quality,
        
        -- Monthly owner activity
        max(active_owners) as max_active_owners_monthly
        
    from daily_summary
    group by 1, 2, 3
),

final as (
    select
        'daily' as granularity,
        date as time_period,
        year,
        month,
        day,
        day_of_week,
        null as week_of_year,
        
        -- Metrics
        total_communications,
        total_meetings,
        total_emails,
        total_calls,
        total_other,
        completed_meetings,
        cancelled_meetings,
        avg_meeting_duration_minutes,
        total_meeting_minutes,
        successful_calls,
        avg_call_duration_seconds,
        total_call_seconds,
        high_quality_records,
        low_quality_records,
        active_owners,
        business_hours_communications,
        after_hours_communications,
        
        -- Calculated metrics
        case 
            when total_meetings > 0 then round(completed_meetings * 100.0 / total_meetings, 2)
            else 0 
        end as meeting_completion_rate,
        
        case 
            when total_calls > 0 then round(successful_calls * 100.0 / total_calls, 2)
            else 0 
        end as call_success_rate,
        
        current_timestamp as _loaded_at
        
    from daily_summary
    
    union all
    
    select
        'weekly' as granularity,
        week_start as time_period,
        year,
        month,
        null as day,
        null as day_of_week,
        week_of_year,
        
        weekly_communications as total_communications,
        weekly_meetings as total_meetings,
        weekly_emails as total_emails,
        weekly_calls as total_calls,
        null as total_other,
        null as completed_meetings,
        null as cancelled_meetings,
        null as avg_meeting_duration_minutes,
        weekly_meeting_minutes as total_meeting_minutes,
        null as successful_calls,
        null as avg_call_duration_seconds,
        weekly_call_seconds as total_call_seconds,
        weekly_high_quality as high_quality_records,
        weekly_low_quality as low_quality_records,
        null as active_owners,
        null as business_hours_communications,
        null as after_hours_communications,
        null as meeting_completion_rate,
        null as call_success_rate,
        current_timestamp as _loaded_at
        
    from weekly_summary
    
    union all
    
    select
        'monthly' as granularity,
        month_start as time_period,
        year,
        month,
        null as day,
        null as day_of_week,
        null as week_of_year,
        
        monthly_communications as total_communications,
        monthly_meetings as total_meetings,
        monthly_emails as total_emails,
        monthly_calls as total_calls,
        null as total_other,
        null as completed_meetings,
        null as cancelled_meetings,
        null as avg_meeting_duration_minutes,
        monthly_meeting_minutes as total_meeting_minutes,
        null as successful_calls,
        null as avg_call_duration_seconds,
        monthly_call_seconds as total_call_seconds,
        monthly_high_quality as high_quality_records,
        monthly_low_quality as low_quality_records,
        max_active_owners_monthly as active_owners,
        null as business_hours_communications,
        null as after_hours_communications,
        null as meeting_completion_rate,
        null as call_success_rate,
        current_timestamp as _loaded_at
        
    from monthly_summary
)

select * from final 