{{ config(tags=['gold_validation']) }}

select
    concat_ws('||', cast(order_date as string), author) as record_key,
    'DUPLICATE_AUTHOR_DAILY_GRAIN' as reason
from {{ ref('agg_author_daily') }}
group by order_date, author
having count(*) > 1
