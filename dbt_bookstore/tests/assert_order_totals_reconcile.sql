{{ config(tags=['gold_validation']) }}

with line_totals as (
    select
        order_id,
        order_timestamp,
        cast(sum(source_subtotal) as decimal(18, 2)) as line_total
    from {{ ref('fct_order_line') }}
    group by order_id, order_timestamp
)
select
    concat_ws('||', orders.order_id, cast(orders.order_timestamp as string)) as record_key,
    'ORDER_TOTAL_DOES_NOT_RECONCILE_TO_LINES' as reason
from {{ ref('stg_orders') }} as orders
left join line_totals
    on orders.order_id = line_totals.order_id
    and orders.order_timestamp = line_totals.order_timestamp
where line_totals.order_id is null
   or abs(orders.order_total - line_totals.line_total) > cast(0.01 as decimal(18, 2))
