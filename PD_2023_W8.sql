-- REQUIREMENTS

-- Combine the 12 monthly files

-- Create a 'file date' using the month found in the file name
-- - The Null value should be replaced as 1

-- Clean the Market Cap value to ensure it is the true value as 'Market Capitalisation'
-- - Remove any rows with 'n/a'

-- Categorise the Purchase Price into groupings
-- - 0 to 24,999.99 as 'Low'
-- - 25,000 to 49,999.99 as 'Medium'
-- - 50,000 to 74,999.99 as 'High'
-- - 75,000 to 100,000 as 'Very High'

-- Categorise the Market Cap into groupings
-- - Below $100M as 'Small'
-- - Between $100M and below $1B as 'Medium'
-- - Between $1B and below $100B as 'Large' 
-- - $100B and above as 'Huge'

-- Rank the highest 5 purchases per combination of: file date, Purchase Price Categorisation and Market Capitalisation Categorisation.
-- Output only records with a rank of 1 to 5


with _union as (
  select 
  'Jan' as Month,
  *
  from pd2023_wk08_01
  
  union all
  
   select 
  'Feb' as Month,
  *
  from pd2023_wk08_02
  
  union all
  
   select 
  'Mar' as Month,
  *
  from pd2023_wk08_03
  
  union all
  
   select 
  'Apr' as Month,
  *
  from pd2023_wk08_04
  
  union all
  
   select 
  'May' as Month,
  *
  from pd2023_wk08_05
  
  union all
  
   select 
  'Jun' as Month,
  *
  from pd2023_wk08_06
  
  union all
  
   select 
  'Jul' as Month,
  *
  from pd2023_wk08_07
  
  union all
  
   select 
  'Aug' as Month,
  *
  from pd2023_wk08_08
  
  union all
  
   select 
  'Sep' as Month,
  *
  from pd2023_wk08_09
  
  union all
  
   select 
  'Oct' as Month,
  *
  from pd2023_wk08_10
  
  union all
  
   select 
  'Nov' as Month,
  *
  from pd2023_wk08_11
  
  union all
  
   select 
  'Dec' as Month,
  *
  from pd2023_wk08_12
),

cat as (
Select 
*,
case
	when (replace("Purchase Price", '$', ''):: numeric) >= 75000 then 'Very High'
    when (replace("Purchase Price", '$', ''):: numeric) >= 50000 then 'High'
    when (replace("Purchase Price", '$', ''):: numeric) >= 25000 then 'Medium'
    when (replace("Purchase Price", '$', ''):: numeric) >= 0 then 'Low'
end as Price_Category,
case
	when (regexp_replace("Market Cap", '[\$BM]', '', 'g'):: numeric) *
    (case
     	when "Market Cap" LIKE '%B%' then 1000000000
     	when "Market Cap" LIKE '%M%' then 1000000
     end) > 100000000000 then 'Huge'
     when (regexp_replace("Market Cap", '[\$BM]', '', 'g'):: numeric) *
    (case
     	when "Market Cap" LIKE '%B%' then 1000000000
     	when "Market Cap" LIKE '%M%' then 1000000
     end) > 1000000000 then 'Large'
     when (regexp_replace("Market Cap", '[\$BM]', '', 'g'):: numeric) *
    (case
     	when "Market Cap" LIKE '%B%' then 1000000000
     	when "Market Cap" LIKE '%M%' then 1000000
     end) > 100000000 then 'Medium'
     else 'Small'
end as Market_cap_category
from _union
where "Market Cap" <> 'n/a'
),

rank as (
select
*,
row_number () over (partition by month, price_category, market_cap_category order by "Purchase Price" desc) as rank
from cat
)

select
*
from rank
where rank <= 5
