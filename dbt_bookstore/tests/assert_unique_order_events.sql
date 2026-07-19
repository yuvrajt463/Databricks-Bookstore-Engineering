{{ config(tags=['source_validation']) }}

select
    concat_ws('||', order_id, cast(order_timestamp as string)) as record_key,
    'DUPLICATE_ORDER_EVENT' as reason
from {{ source('bookstore_silver', 'orders_silver') }}
group by order_id, order_timestamp
having count(*) > 1
