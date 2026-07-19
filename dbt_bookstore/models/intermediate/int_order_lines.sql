select
    sha2(
        concat_ws(
            '||',
            orders.order_id,
            cast(orders.order_timestamp as string),
            cast(exploded.order_line_position as string)
        ),
        256
    ) as order_line_id,
    orders.order_id,
    orders.order_timestamp,
    cast(orders.order_timestamp as date) as order_date,
    cast(exploded.order_line_position as int) as order_line_position,
    orders.customer_id,
    cast(exploded.book.book_id as string) as book_id,
    cast(exploded.book.quantity as bigint) as quantity,
    cast(exploded.book.subtotal as decimal(18, 2)) as source_subtotal,
    orders.loaded_at
from {{ ref('stg_orders') }} as orders
lateral view posexplode(orders.books) exploded as order_line_position, book
