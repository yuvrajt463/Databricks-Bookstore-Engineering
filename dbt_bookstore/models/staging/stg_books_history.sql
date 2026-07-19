select
    cast(book_id as string) as book_id,
    cast(title as string) as title,
    cast(author as string) as author,
    cast(price as decimal(18, 2)) as price,
    cast(`__START_AT` as timestamp) as valid_from,
    cast(`__END_AT` as timestamp) as valid_to,
    cast(`__END_AT` is null as boolean) as is_current,
    cast(is_quarantined as boolean) as is_quarantined
from {{ source('bookstore_silver', 'books_silver') }}
