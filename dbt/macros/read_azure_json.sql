{% macro read_azure_json(data_type, partition_date=none) %}
    {% set azure_base_path = 'az://strprimrosedatalake.blob.core.windows.net/raw/hubspot/' %}
    {% set full_path = azure_base_path ~ data_type %}

    {% if partition_date %}
        {% set full_path = full_path ~ '/' ~ partition_date %}
    {% endif %}

    {% set file_pattern = full_path ~ '/**/*.json' %}

    SELECT
        *,
        -- Extract date from the file path for partitioning
        REGEXP_EXTRACT(_FILE_NAME, '/([0-9]{8})/', 1) as partition_date,
        -- Extract timestamp from the file path
        REGEXP_EXTRACT(_FILE_NAME, '/([0-9]{6})\.json', 1) as partition_time,
        -- Add source tracking
        '{{ data_type }}' as source_table,
        _FILE_NAME as source_file
    FROM '{{ file_pattern }}'
{% endmacro %}
