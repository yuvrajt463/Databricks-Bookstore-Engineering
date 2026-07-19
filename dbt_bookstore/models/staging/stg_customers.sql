select
    cast(customer_id as string) as customer_id,
    cast(country as string) as country
from {{ source('bookstore_silver', 'customers_silver') }}
