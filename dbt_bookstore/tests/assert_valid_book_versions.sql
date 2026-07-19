{{ config(tags=['source_validation']) }}

select
    concat_ws('||', book_id, cast(`__START_AT` as string)) as record_key,
    case
        when is_quarantined then 'QUARANTINED_BOOK_REACHED_SILVER'
        when price < 0 or price > 100 then 'BOOK_PRICE_OUT_OF_RANGE'
        when `__END_AT` is not null and `__END_AT` <= `__START_AT` then 'INVALID_BOOK_VALIDITY_WINDOW'
    end as reason
from {{ source('bookstore_silver', 'books_silver') }}
where is_quarantined
   or price < 0
   or price > 100
   or (`__END_AT` is not null and `__END_AT` <= `__START_AT`)
