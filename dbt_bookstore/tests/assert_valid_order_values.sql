{{ config(tags=['source_validation']) }}

select
    concat_ws('||', order_id, cast(order_timestamp as string)) as record_key,
    case
        when quantity <= 0 then 'NONPOSITIVE_ORDER_QUANTITY'
        when total < 0 or total > 100000 then 'ORDER_TOTAL_OUT_OF_RANGE'
        when order_timestamp < timestamp('2020-01-01') then 'ORDER_DATE_BEFORE_2020'
        when order_timestamp > current_timestamp() then 'ORDER_DATE_IN_FUTURE'
        when size(books) = 0 then 'ORDER_HAS_NO_LINES'
    end as reason
from {{ source('bookstore_silver', 'orders_silver') }}
where quantity <= 0
   or total < 0
   or total > 100000
   or order_timestamp < timestamp('2020-01-01')
   or order_timestamp > current_timestamp()
   or size(books) = 0
