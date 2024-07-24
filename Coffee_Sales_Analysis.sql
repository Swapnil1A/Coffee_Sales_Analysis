--Total Revenue on each Store_location generated
select store_location, SUM(transaction_qty*unit_price) as Total_Revenue from coffee_details
group by 1
order by Total_Revenue 

--Month wise Revenue generated
select extract(Month from transaction_date) as Month_no , to_char(transaction_date,'Month') as Month,SUM(transaction_qty*unit_price) as Total_Revenue  from coffee_details
group by Month_no,Month

--TotaL_Revenue generated
select SUM(transaction_qty*unit_price) as Total_Revenue from coffee_details

--Store,Month-wise Revenue generated
select store_location, to_char(transaction_date,'Month') as Month,SUM(transaction_qty*unit_price) as Total_Revenue  from coffee_details
group by 1, Month

--Product_category wise revenue
select product_category, SUM(transaction_qty*unit_price) as Total_Revenue  from coffee_details
group by product_category
order by Total_Revenue desc

--Product_type wise revenue
select product_type, count(transaction_qty) as qty from coffee_details
group by product_type
order by qty desc

--Total_Revenue percent of each product_category round 2 decimal
with cte as(
select product_category, 
ROUND(SUM(transaction_qty*unit_price),2)/(select ROUND(SUM(transaction_qty*unit_price),2)
from coffee_details)
*100 as revenue
from coffee_details
group by product_category)

select product_category, 
round(cte.revenue,2) as percent_total_revenue 
from cte
order by percent_total_revenue asc


--Total Revenue generated on Store_location and product_category basis
select store_location,product_category, SUM(transaction_qty*unit_price) as Total_Revenue from coffee_details
group by 1,2
order by Total_Revenue desc

--Avg transaction on Store_location and product_type basis
select store_location,round(avg(transaction_qty*unit_price),2) as avg_transaction, product_type
from coffee_details
group by store_location,3
order by avg_transaction desc

--list the tranc. where tranc. time is same but tranc. id is different
select a.transaction_id,a.transaction_time,b.transaction_id,b.transaction_time
from coffee_details a
join coffee_details b on a.transaction_time=b.transaction_time
where a.transaction_id != b.transaction_id

--Highest Avg sales amt per date
with cte as(
select product_type, round(avg(transaction_qty*unit_price),2) as Total_Sales, transaction_date
from coffee_details
group by product_type ,3
order by 2 desc),

cte_2 as(
select product_type, transaction_date, Total_Sales, ROW_NUMBER()OVER(PARTITION BY transaction_date ORDER BY 2 desc) as RowNo
from cte
)
select product_type, transaction_date, Total_Sales from cte_2
where RowNo<=1


--Top 3 store_location with Highest sales with top selling product_category
WITH cte AS (
 SELECT store_location,product_category,transaction_qty * unit_price AS totalsale
 FROM coffeesales
),
store_totals AS (
 SELECT store_location,SUM(totalsale) AS store_total_sale
 FROM cte GROUP BY store_location
),ranked_stores AS (
 SELECT store_location,store_total_sale,RANK() OVER (ORDER BY store_total_sale DESC) AS 
store_rank
 FROM store_totals
),top_stores AS (
 SELECT store_location,store_total_sale
 FROM ranked_stores
 WHERE store_rank <= 3
),
category_totals AS (
 SELECT store_location,product_category,SUM(totalsale) AS category_total_sale
 FROM cte GROUP BY store_location, product_category
),ranked_categories AS (
 SELECT store_location,product_category,category_total_sale,
 RANK() OVER (PARTITION BY store_location ORDER BY category_total_sale DESC) AS 
category_rank
 FROM category_totals)
SELECT rc.store_location,
 rc.product_category,
 ROUND(rc.category_total_sale,2)AS category_total_sale
FROM ranked_categories rc
JOIN top_stores ts ON rc.store_location = ts.store_location
WHERE rc.category_rank = 1;


--Contribution percentage of tea and coffee in Total Revenue

WITH cte AS (
 SELECT SUM(transaction_qty * unit_price) AS total_revenue_overall
 FROM coffee_details
),
cte_2 as (
select product_category,total_revenue_overall, SUM(transaction_qty * unit_price) as revenue_category,
round((sum(transaction_qty * unit_price)/(total_revenue_overall))*100, 2 )as percent_contribution from coffee_details,cte
group by product_category,cte.total_revenue_overall
)
select * from cte_2
where product_category='Coffee' or product_category='Tea'


--Cumulative sum over time : using cte
with cte as(
    select transaction_date,sum(transaction_qty*unit_price) as revenue
    from coffee_details
    group by 1
),
cte_2 as(
    select *, sum(revenue) over(order by transaction_date) as cumulative_sum from cte
)
select * from cte_2