--1. How many customers has Foodie-Fi ever had?

SELECT DISTINCT
COUNT (customer_id) as Customer_count

FROM foodie_fi.subscriptions;


--2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT 
DATE_TRUNC('month',start_date) as month,
COUNT(customer_id) as trial_starts
FROM subscriptions
WHERE plan_id = 0
GROUP BY DATE_TRUNC('month',start_date)

--3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT
plan_name,
COUNT(*) as count_of_events
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
WHERE DATE_PART('year',start_date) > 2020
GROUP BY plan_name

--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT
count(distinct customer_id) as customer_count,
round((count (distinct customer_id):: numeric / (select count (distinct customer_id) from foodie_fi.subscriptions)*100),1) as churn_pct
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
WHERE plan_name = 'churn'

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with cte as (
SELECT
s.*,
row_number () over (partition by customer_id order by start_date asc) as rn
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
order by customer_id
)

select
count (distinct customer_id) as customer_count,
round((count (distinct customer_id):: numeric / (select count (distinct customer_id) from foodie_fi.subscriptions)*100),0) as churn_pct
from cte
where rn = 2 and plan_id = 4

--6. What is the number and percentage of customer plans after their initial free trial?

with cte as (
SELECT
s.*,
p.plan_name,
row_number () over (partition by s.customer_id order by s.start_date asc) as rn
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
order by customer_id
)

select
plan_name,
count (distinct customer_id) as customer_count,
round((count (distinct customer_id):: numeric / (select count (distinct customer_id) from foodie_fi.subscriptions)*100),0) as plan_pct
from cte
where rn = 2 and plan_name <>'churn'
group by plan_name

--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with cte as (
SELECT
s.*,
p.plan_name,
row_number () over (partition by s.customer_id order by s.start_date desc) as rn
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
where start_date <= '2020-12-31'
order by customer_id
)

select
plan_name,
count (distinct customer_id) as customer_count,
round((count (distinct customer_id):: numeric / (select count (distinct customer_id) from foodie_fi.subscriptions)*100),0) as plan_pct
from cte
where rn = 1
group by plan_name

--8. How many customers have upgraded to an annual plan in 2020?

SELECT
count (distinct customer_id) as customer_count
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
where date_part('year',start_date) = 2020 and plan_name = 'pro annual'


--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with start as (
SELECT
customer_id,
min(start_date) as start_date
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
group by 1
),

annual as (
 SELECT
customer_id,
min(start_date) as annual_date
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
where plan_name = 'pro annual'
group by 1 
)

select
ROUND(AVG(annual_date - start_date),0) as avg_days_to_annual
from start s
join annual a
on s.customer_id = a.customer_id

--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with start as (
SELECT
customer_id,
min(start_date) as start_date
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
group by 1
),

annual as (
 SELECT
customer_id,
min(start_date) as annual_date
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
where plan_name = 'pro annual'
group by 1 
)

select
case
  when (annual_date - start_date) <= 30 then '0-30 days'
  when (annual_date - start_date) <= 31 then '31-60 days'
  when (annual_date - start_date) <= 61 then '61-90 days'
  when (annual_date - start_date) <= 91 then '91-120 days'
  when (annual_date - start_date) <= 121 then '121-150 days'
  when (annual_date - start_date) <= 151 then '151-180 days'
  else '180+ days' end as bins,
  count (distinct s.customer_id)
from start s
join annual a
on s.customer_id = a.customer_id
group by 1

--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

with pro as (
select 
customer_id,
start_date
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
where plan_name = 'pro monthly'
),
basic as (
 SELECT
customer_id,
start_date
FROM foodie_fi.subscriptions as S
INNER JOIN foodie_fi.plans as P on S.plan_id = P.plan_id
where plan_name = 'basic monthly'
)
select
b.customer_id,
p.start_date as pro_date,
b.start_date as basic_date
from pro p
join basic b
on p.customer_id = b.customer_id
where date_part('year', b.start_date) = 2020
and b.start_date > p.start_date
