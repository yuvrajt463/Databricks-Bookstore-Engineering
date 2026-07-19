select
    cast(order_id as string) as order_id,
    cast(order_timestamp as timestamp) as order_timestamp,
    cast(customer_id as string) as customer_id,
    cast(quantity as bigint) as order_quantity,
    cast(total as decimal(18, 2)) as order_total,
    books,
    cast(_loaded_at as timestamp) as loaded_at
from {{ source('bookstore_silver', 'orders_silver') }}
