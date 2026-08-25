-- How many unique nodes are there on the Data Bank system?

select
count (distinct node_id) as node_count
from data_bank.customer_nodes

-- What is the number of nodes per region?

select
	region_name,
	count (distinct node_id) as node_count
from data_bank.customer_nodes n
join data_bank.regions r
	on n.region_id = r.region_id
group by region_name

-- How many customers are allocated to each region?

select
	region_name,
	count (distinct customer_id) as customer_count
from data_bank.customer_nodes n
join data_bank.regions r
	on n.region_id = r.region_id
group by region_name

-- How many days on average are customers reallocated to a different node?

with date_diff as (
select
    customer_id,
    node_id,
    SUM(end_date - start_date) as date_diff
from data_bank.customer_nodes n
where end_date < '9999-1-1'
group by 1,2
)

select
round(avg(date_diff),1) as avg_days_to_switch
from date_diff

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

with date_diff as (
select
    customer_id,
    node_id,
  	region_name,
    SUM(end_date - start_date) as date_diff
from data_bank.customer_nodes n
join data_bank.regions r
  on n.region_id = r.region_id
where end_date < '9999-1-1'
group by 1,2,3
),
_order as (
  select
  region_name,
  date_diff,
  dense_rank () over (partition by region_name order by date_diff asc) as rn
  from date_diff
),
_max as (
  select
  region_name,
  max(rn) as max_rn
  from _order
 group by 1 
),

final as (
select
o.region_name,
case
	when o.rn = round(m.max_rn * 0.5, 0) then 'Median'
    when o.rn = round(m.max_rn * 0.80, 0) then '80th Percentile'
    when o.rn = round(m.max_rn * 0.95, 0) then '95th Percentile'
end as statistic,
date_diff
from _order o
join _max m
	on o.region_name = m.region_name
)

select distinct
*
from final
where statistic is not null
order by region_name
