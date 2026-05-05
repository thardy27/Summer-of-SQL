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

