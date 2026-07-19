{{ config(tags=['gold_validation']) }}

select
    order_line_id as record_key,
    'LINE_SUBTOTAL_MISMATCH' as reason
from {{ ref('fct_order_line') }}
where abs(source_subtotal - calculated_subtotal) > cast(0.01 as decimal(18, 2))
