{{ config(tags=['source_validation']) }}

select
    concat_ws('||', earlier.book_id, cast(earlier.`__START_AT` as string), cast(later.`__START_AT` as string)) as record_key,
    'OVERLAPPING_BOOK_VALIDITY_WINDOWS' as reason
from {{ source('bookstore_silver', 'books_silver') }} as earlier
join {{ source('bookstore_silver', 'books_silver') }} as later
    on earlier.book_id = later.book_id
    and earlier.`__START_AT` < later.`__START_AT`
    and coalesce(earlier.`__END_AT`, timestamp('9999-12-31')) > later.`__START_AT`
