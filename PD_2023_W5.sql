-- REQUIREMENTS

-- - Create the bank code by splitting out off the letters from the Transaction code, call this field 'Bank'
-- - Change transaction date to the just be the month of the transaction
-- - Total up the transaction values so you have one row for each bank and month combination
-- - Rank each bank for their value of transactions each month against the other banks. 1st is the highest value of transactions, 3rd the lowest. 
-- - Without losing all of the other data fields, find:
-- 	- The average rank a bank has across all of the months, call this field 'Avg Rank per Bank'
-- 	- The average transaction value per rank, call this field 'Avg Transaction Value per Rank'

with bank_month as (
select 
split_part(transaction_code,'-',1) as Bank,
to_char(to_date(left(transaction_date,10), 'DD/MM/YYYY'), 'FMmonth') as Month,
sum(value) as value
from pd2023_wk05
group by 1,2
  ),
  
rank as (
select
  *,
  row_number () over (partition by Month order by value desc) as rn
from bank_month
 ),
 
avg_rank as (
 select
  round(avg(rn),1) as avg_rank_per_bank,
  bank 
 from rank group by bank 
  ),
  
avg_value as (
 select
  round(avg(value),0) as avg_value_per_bank,
  bank 
 from rank group by bank 
 )
 
 select
 r.*,
 avg_rank_per_bank,
 avg_value_per_bank
 from rank r
 join avg_rank ar
 on r.bank = ar.bank
 join avg_value av
 on r.bank = av.bank
