select
    lines.order_line_id,
    lines.order_id,
    lines.order_timestamp,
    lines.order_date,
    lines.order_line_position,
    lines.customer_id,
    lines.book_id,
    books.author,
    lines.quantity,
    books.price as unit_price,
    lines.source_subtotal,
    cast(lines.quantity * books.price as decimal(18, 2)) as calculated_subtotal,
    lines.loaded_at
from {{ ref('int_order_lines') }} as lines
left join {{ ref('stg_books_history') }} as books
    on lines.book_id = books.book_id
    and lines.order_timestamp >= books.valid_from
    and (books.valid_to is null or lines.order_timestamp < books.valid_to)
