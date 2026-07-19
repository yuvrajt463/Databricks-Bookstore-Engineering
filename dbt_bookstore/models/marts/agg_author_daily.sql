{{ config(materialized='table', file_format='delta') }}

select
    order_date,
    author,
    cast(count(distinct order_id) as bigint) as orders_count,
    cast(sum(quantity) as bigint) as units_sold,
    cast(sum(calculated_subtotal) as decimal(18, 2)) as gross_sales
from {{ ref('fct_order_line') }}
group by order_date, author
