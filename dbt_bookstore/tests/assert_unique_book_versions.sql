{{ config(tags=['source_validation']) }}

select
    concat_ws('||', book_id, cast(`__START_AT` as string)) as record_key,
    'DUPLICATE_BOOK_VERSION' as reason
from {{ source('bookstore_silver', 'books_silver') }}
group by book_id, `__START_AT`
having count(*) > 1
