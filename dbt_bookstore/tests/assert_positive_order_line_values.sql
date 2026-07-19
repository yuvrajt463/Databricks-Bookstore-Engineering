{{ config(tags=['gold_validation']) }}

select
    order_line_id as record_key,
    case
        when quantity <= 0 then 'NONPOSITIVE_LINE_QUANTITY'
        when unit_price < 0 then 'NEGATIVE_HISTORICAL_PRICE'
    end as reason
from {{ ref('fct_order_line') }}
where quantity <= 0
   or unit_price < 0
