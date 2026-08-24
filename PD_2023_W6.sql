-- REQUIREMENTS

-- - Reshape the data so we have 5 rows for each customer, with responses for the Mobile App and Online Interface being in separate fields on the same row
-- - Clean the question categories so they don't have the platform in from of them
-- 	- e.g. Mobile App - Ease of Use should be simply Ease of Use
-- - Exclude the Overall Ratings, these were incorrectly calculated by the system
-- - Calculate the Average Ratings for each platform for each customer 
-- - Calculate the difference in Average Rating between Mobile App and Online Interface for each customer
-- - Catergorise customers as being:
-- 	- Mobile App Superfans if the difference is greater than or equal to 2 in the Mobile App's favour
-- 	- Mobile App Fans if difference >= 1
-- 	- Online Interface Fan
-- 	- Online Interface Superfan
-- 	- Neutral if difference is between 0 and 1
-- - Calculate the Percent of Total customers in each category, rounded to 1 decimal place

with pivot as (
select
  s. customer_id,
  v.metric,
  v.value
from pd2023_wk06 as s
cross join lateral (
  values
    ('MOBILE_APP - EASE OF USE', MOBILE_APP_EASE_OF_USE),
    ('MOBILE_APP - EASE OF ACCESS', MOBILE_APP_EASE_OF_ACCESS),
    ('MOBILE_APP - NAVIGATION', MOBILE_APP_NAVIGATION),
    ('MOBILE_APP - LIKELIHOOD TO RECOMMEND', MOBILE_APP_LIKELIHOOD_TO_RECOMMEND),
    ('MOBILE_APP - OVERALL RATING', MOBILE_APP_OVERALL_RATING),
    ('ONLINE_INTERFACE - EASE OF USE', ONLINE_INTERFACE_EASE_OF_USE),
    ('ONLINE_INTERFACE - EASE OF ACCESS', ONLINE_INTERFACE_EASE_OF_ACCESS),
    ('ONLINE_INTERFACE - NAVIGATION', ONLINE_INTERFACE_NAVIGATION),
    ('ONLINE_INTERFACE - LIKELIHOOD TO RECOMMEND', ONLINE_INTERFACE_LIKELIHOOD_TO_RECOMMEND),
    ('ONLINE_INTERFACE - OVERALL RATING', ONLINE_INTERFACE_OVERALL_RATING)
) as v(metric, value)
),

mobile as (
select
  customer_id,
  split_part(metric, '- ',2) as Question,
  value as mobile_value
from pivot
where metric LIKE '%MOBILE%'
),  
  
online as (
select
  customer_id,
  split_part(metric, '- ',2) as Question,
  value as online_value
from pivot
where metric LIKE '%ONLINE%'
 ),
 
 mobile_avg as (
select
   customer_id,
   avg(mobile_value) as mobile_avg
from mobile
group by 1
),

  online_avg as (
select
   customer_id,
   avg(online_value) as online_avg
from online
group by 1
 ),
 
diff as (
select
  m.customer_id,
  mobile_avg,
  online_avg,
  (mobile_avg - online_avg) as diff
from mobile_avg m
join online_avg o
  on m.customer_id = o.customer_id
)

select
case
	when diff >= 2 then 'Mobile App Superfan'
    when diff >= 1 then 'Mobile App Fan'
    when diff <= -2 then 'Online Interface Superfan'
    when diff <= -1 then 'Online Interface Fan'
    else 'Neutral'
end as Category,
round((count(customer_id)::numeric / (select count(distinct customer_id) from pd2023_wk06))*100, 1) as pct
from diff
group by 1
    
