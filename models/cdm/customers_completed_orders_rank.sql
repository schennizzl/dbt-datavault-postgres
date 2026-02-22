with latest_sat_customer as (
    select
        customer_pk,
        first_name,
        last_name,
        id as source_customer_id,
        row_number() over (
            partition by customer_pk
            order by load_date desc
        ) as rn
    from {{ ref('sat_customer') }}
),
latest_sat_order as (
    select
        order_pk,
        status,
        row_number() over (
            partition by order_pk
            order by load_date desc
        ) as rn
    from {{ ref('sat_order') }}
),
completed_orders_by_customer as (
    select
        l.customer_pk,
        count(distinct l.order_pk) as completed_orders_count
    from {{ ref('link_customer_order') }} l
    join latest_sat_order o
      on o.order_pk = l.order_pk
     and o.rn = 1
    where o.status = 'completed'
    group by l.customer_pk
)
select
    h.customer_key as customer_email,
    c.first_name,
    c.last_name,
    c.source_customer_id,
    coalesce(co.completed_orders_count, 0) as completed_orders_count
from {{ ref('hub_customer') }} h
left join latest_sat_customer c
  on c.customer_pk = h.customer_pk
 and c.rn = 1
left join completed_orders_by_customer co
  on co.customer_pk = h.customer_pk
order by completed_orders_count desc, customer_email
