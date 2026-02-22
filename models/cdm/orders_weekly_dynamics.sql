with latest_sat_order as (
    select
        order_pk,
        order_date::date as order_date,
        status,
        row_number() over (
            partition by order_pk
            order by load_date desc
        ) as rn
    from {{ ref('sat_order') }}
),
current_orders as (
    select
        h.order_key::int as order_id,
        s.order_date,
        s.status
    from {{ ref('hub_order') }} h
    join latest_sat_order s
      on s.order_pk = h.order_pk
     and s.rn = 1
)
select
    date_trunc('week', order_date)::date as week_start_date,
    count(*) as total_orders_count
from current_orders
group by 1
order by 1
