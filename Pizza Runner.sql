--Part A

-- 1. How many pizzas were ordered?

select
	count (order_id) as total_orders
from pizza_runner.customer_orders

-- 2. How many unique customer orders were made?

select
	count (distinct order_id) as total_unique_orders
from pizza_runner.customer_orders

-- 3. How many successful orders were delivered by each runner?

select
	count (distinct co.order_id) as total_unique_orders
from pizza_runner.customer_orders as co
	join pizza_runner.runner_orders as ro
    	on co.order_id = ro.order_id 
where distance <> 'null'

-- 4. How many of each type of pizza was delivered?

select
	pn.pizza_name
    ,count (co.pizza_id)
from pizza_runner.customer_orders as co
	join pizza_runner.runner_orders as ro
    	on co.order_id = ro.order_id 
    join pizza_runner.pizza_names pn
    	on co.pizza_id = pn.pizza_id
where distance <> 'null'
group by 1

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

select
	co. customer_id
    , pn.pizza_name
    ,count (co.pizza_id)
from pizza_runner.customer_orders as co
	join pizza_runner.runner_orders as ro
    	on co.order_id = ro.order_id 
    join pizza_runner.pizza_names pn
    	on co.pizza_id = pn.pizza_id
group by 1,2

-- 6. What was the maximum number of pizzas delivered in a single order?

with cte as (
select
	co. order_id
    ,count (co.pizza_id) as no_of_pizzas
    , rank () over (
      			order by count (co.pizza_id) desc
			) as rank
from pizza_runner.customer_orders as co
	join pizza_runner.runner_orders as ro
    	on co.order_id = ro.order_id 
    join pizza_runner.pizza_names pn
    	on co.pizza_id = pn.pizza_id
where ro.distance <> 'null'
group by 1
)

select
	order_id
    ,no_of_pizzas
from cte
where rank = 1

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select
	co.customer_id
    , sum (case 
    	when 
        	((co.exclusions is not null and exclusions <> 'null' and length(exclusions) >0) 
             or (extras is not null and extras <> 'null' and length(extras) >0)) = TRUE
        then 1
        else 0
      end) as changes
    , sum (case 
    	when 
        	((co.exclusions is  null or exclusions = 'null' or length(exclusions) < 1) 
             and (extras is null  or extras = 'null' or length(extras) < 1)) = true
        then 1
        else 0
      end) as no_changes 
from pizza_runner.customer_orders as co
	join pizza_runner.runner_orders as ro
    	on co.order_id = ro.order_id 
    join pizza_runner.pizza_names pn
    	on co.pizza_id = pn.pizza_id
where ro.distance <> 'null'
group by 1

-- 8. How many pizzas were delivered that had both exclusions and extras?

select
	co.customer_id
    , sum (case 
    	when 
        	((co.exclusions is not null and exclusions <> 'null' and length(exclusions) >= 1) 
             and (extras is not null and extras <> 'null' and length(extras) >= 1)) = TRUE
        then 1
        else 0
      end) as changes
from pizza_runner.customer_orders as co
	join pizza_runner.runner_orders as ro
    	on co.order_id = ro.order_id 
    join pizza_runner.pizza_names pn
    	on co.pizza_id = pn.pizza_id
where ro.distance <> 'null'
group by 1

-- 9. What was the total volume of pizzas ordered for each hour of the day?

select
	date_part('hour', order_time) as hour
    , count (co.order_id) as ordered_pizzas
from pizza_runner.customer_orders as co
	join pizza_runner.runner_orders as ro
    	on co.order_id = ro.order_id 
    join pizza_runner.pizza_names pn
    	on co.pizza_id = pn.pizza_id
group by hour

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Part B

-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

with runner_signups as (	
	select
  		runner_id
  		, registration_date
  		, date_trunc('week', registration_date) + INTERVAL '4 day' as start_week 
  
  	from pizza_runner.runners
  )
  
  select
  	start_week
    , count (start_week) as signups
  from runner_signups
  group by start_week
  
-- 2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?


with order_time as (
	select
		order_id
  		, order_time

	from pizza_runner.customer_orders
 )
 ,
 pickup_time as (
 	select
   		order_id
   		, runner_id
   		, cast(pickup_time as timestamp) as pickup_time
  from pizza_runner.runner_orders
  where pickup_time != 'null'
  )
 

	select 
		p.runner_id
        ,round(AVG(EXTRACT(EPOCH FROM (p.pickup_time - o.order_time)) / 60)) AS avg_time_minutes
  	from order_time as o
  	inner join pickup_time as p
  		on o.order_id = p.order_id
    group by p.runner_id

-- 3.Is there any relationship between the number of pizzas and how long the order takes to prepare?

with order_info as (

	select 
    	co.order_id
        , count(co.pizza_id) as no_of_pizzas
        , AVG(EXTRACT(EPOCH FROM (ro.pickup_time::TIMESTAMP - co.order_time::TIMESTAMP)) / 60) AS prep_time
	from pizza_runner.customer_orders as co
  	join pizza_runner.runner_orders as ro
  		on co.order_id = ro.order_id
    where pickup_time != 'null'
    group by 1
)

select
	no_of_pizzas
    , avg(prep_time) as avg_prep_time
    
from order_info
group by 1
order by 2 desc

-- 4.What was the average distance travelled for each customer?  IMCOMPLETE

with order_info as (

	select 
    	co.customer_id as customer_id
        , replace (ro.distance, 'km', '') as distance
	from pizza_runner.customer_orders as co
  	join pizza_runner.runner_orders as ro
  		on co.order_id = ro.order_id
    where ro.distance != 'null'

)

select
	customer_id
    ,  AVG(CAST(distance AS DECIMAL(3, 1))) AS avg_distance_travelled 
from order_info
group by 1

-- 5.What was the difference between the longest and shortest delivery times for all orders?

with clean_distance as (
	select 
  		order_id
  		, cast(left(duration, 2) as Integer) as duration
  	from pizza_runner.runner_orders
  	where duration != 'null'
)

select
	max(duration)-min(duration) as delivery_difference
from clean_distance
	
-- 6.What was the average speed for each runner for each delivery and do you notice any trend for these values?

with cleaned as (
	select 
  		order_id
        , runner_id
  		, (cast(left(duration, 2) as decimal)/60) as duration_hr
  		, (cast(replace(distance, 'km', '') AS decimal(3, 1))) as distance_km
  	from pizza_runner.runner_orders
  	where duration != 'null'
)

select
	order_id
    , runner_id
    , (distance_km / duration_hr) as km_h
from cleaned
order by km_h desc

-- 7.What is the successful delivery percentage for each runner?

with runner_deliveries as (
select 
     runner_id
	, sum(case 
    	when duration = 'null' then 0
        else 1
      end) as deliveries
    , count (order_id) as no_of_orders
      
from pizza_runner.runner_orders
group by 1
  )
  
select
	runner_id
    , cast(deliveries as decimal) / no_of_orders * 100 as delivery_percent
from runner_deliveries




