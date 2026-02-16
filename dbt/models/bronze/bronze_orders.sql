{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['OrderID','load_date']
) }}

with src as (
    select
        *,
        to_date(regexp_extract(input_file_name(), '/Orders/([0-9]{4}-[0-9]{2}-[0-9]{2})/', 1)) as load_date,
        input_file_name() as source_file
    from parquet.`abfss://landing@panmaisonadls.dfs.core.windows.net/northwind/Orders/*/Orders`

    {% if is_incremental() %}
      where to_date(regexp_extract(input_file_name(), '/Orders/([0-9]{4}-[0-9]{2}-[0-9]{2})/', 1))
            >= date_sub(current_date(), 3)
    {% endif %}
)

select * from src
