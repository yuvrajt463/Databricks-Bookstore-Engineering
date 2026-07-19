{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='order_line_id',
        file_format='delta',
        on_schema_change='fail'
    )
}}

select
    priced.order_line_id,
    priced.order_id,
    priced.order_timestamp,
    priced.order_date,
    priced.order_line_position,
    priced.customer_id,
    priced.book_id,
    priced.author,
    priced.quantity,
    priced.unit_price,
    priced.source_subtotal,
    priced.calculated_subtotal,
    customers.country,
    priced.loaded_at
from {{ ref('int_order_lines_priced') }} as priced
left join {{ ref('stg_customers') }} as customers
    on priced.customer_id = customers.customer_id
