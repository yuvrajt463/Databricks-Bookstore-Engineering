{{ config(tags=['source_validation']) }}

with expected as (
    select * from values
        ('orders_silver', 'order_id', 'string'),
        ('orders_silver', 'order_timestamp', 'timestamp'),
        ('orders_silver', 'customer_id', 'string'),
        ('orders_silver', 'quantity', 'bigint'),
        ('orders_silver', 'total', 'bigint'),
        ('orders_silver', 'books', 'array<struct<book_id:string,quantity:bigint,subtotal:bigint>>'),
        ('orders_silver', '_loaded_at', 'timestamp'),
        ('customers_silver', 'customer_id', 'string'),
        ('customers_silver', 'country', 'string'),
        ('books_silver', 'book_id', 'string'),
        ('books_silver', 'title', 'string'),
        ('books_silver', 'author', 'string'),
        ('books_silver', 'price', 'double'),
        ('books_silver', '__start_at', 'timestamp'),
        ('books_silver', '__end_at', 'timestamp'),
        ('books_silver', 'is_quarantined', 'boolean')
        as expected(table_name, column_name, data_type)
),
actual as (
    select
        lower(table_name) as table_name,
        lower(column_name) as column_name,
        regexp_replace(lower(data_type), '\\s+', '') as data_type
    from {{ adapter.quote(var('source_catalog', target.database)) }}.information_schema.columns
    where lower(table_schema) = lower('{{ var('source_schema', 'bookstore_eng_pro') }}')
      and lower(table_name) in ('orders_silver', 'customers_silver', 'books_silver')
)
select
    concat(expected.table_name, '.', expected.column_name) as record_key,
    case
        when actual.column_name is null then 'MISSING_REQUIRED_COLUMN'
        else concat('TYPE_MISMATCH_EXPECTED_', expected.data_type, '_ACTUAL_', actual.data_type)
    end as reason
from expected
left join actual
    on expected.table_name = actual.table_name
    and expected.column_name = actual.column_name
where actual.column_name is null
   or regexp_replace(lower(expected.data_type), '\\s+', '') <> actual.data_type
