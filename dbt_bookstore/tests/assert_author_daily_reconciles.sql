{{ config(tags=['gold_validation']) }}

with expected as (
    select
        order_date,
        author,
        cast(count(distinct order_id) as bigint) as orders_count,
        cast(sum(quantity) as bigint) as units_sold,
        cast(sum(calculated_subtotal) as decimal(18, 2)) as gross_sales
    from {{ ref('fct_order_line') }}
    group by order_date, author
)
select
    concat_ws('||', cast(coalesce(expected.order_date, actual.order_date) as string), coalesce(expected.author, actual.author)) as record_key,
    'AUTHOR_DAILY_DOES_NOT_RECONCILE_TO_FACT' as reason
from expected
full outer join {{ ref('agg_author_daily') }} as actual
    on expected.order_date = actual.order_date
    and expected.author = actual.author
where expected.order_date is null
   or actual.order_date is null
   or expected.orders_count <> actual.orders_count
   or expected.units_sold <> actual.units_sold
   or abs(expected.gross_sales - actual.gross_sales) > cast(0.01 as decimal(18, 2))
