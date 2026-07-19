{{ config(tags=['source_validation']) }}

select
    book_id as record_key,
    'BOOK_REQUIRES_EXACTLY_ONE_CURRENT_VERSION' as reason
from {{ source('bookstore_silver', 'books_silver') }}
group by book_id
having sum(case when `__END_AT` is null then 1 else 0 end) <> 1
