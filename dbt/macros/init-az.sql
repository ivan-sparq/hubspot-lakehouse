{% macro init_azure_storage() %}
    -- configure Azure Storage
    {% set azure_setup_query %}
        INSTALL azure;
        LOAD azure;

        -- The credential_chain provider allows connecting using credentials automatically fetched by the Azure SDK via the Azure credential chain.
        -- https://duckdb.org/docs/stable/core_extensions/azure#credential_chain-provider
        CREATE SECRET IF NOT EXISTS azure_creds (
            TYPE azure,
            PROVIDER credential_chain,
            SCOPE 'az://strprimrosedatalake.blob.core.windows.net/'
        );
    {% endset %}

    {% do run_query(azure_setup_query) %}
{% endmacro %}
