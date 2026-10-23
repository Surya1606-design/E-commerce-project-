SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp, '%Y-%m'
    ) AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.fright_value), 2) AS fright_amount
FROM orders AS o
JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    DATE_FORMAT(
        o.order_purchase_timestamp, '%Y-%m'
    )
ORDER BY order_month;

-- Monthly revenue trend
-- Group BY, date functions
-- Business question: How much sales revenue was generated each month? 
select
	date_format(
    o.order_purchase_timestamp, '%Y-%m') as order_month,
    round(sum(oi.price), 2) as Monthly_revenue
from orders as o
join order_items as oi
on o.order_id = oi.order_id
where o.order_status = "delivered"
group by date_format(o.order_purchase_timestamp, '%Y-%m')
order by order_month;

-- Month over month revenue growth
-- SQL skills: CTEs, LAG(), date functions, percentage calculations.
-- Business question: How much did revenue increase or decrease compared with the previous month?

with Monthly_Revenue as (
select date_format(o.order_purchase_timestamp, '%Y-%m') as order_month, 
		sum(oi.price) as revenue
from orders as o
join order_items as oi
on o.order_id = oi.order_id
where o.order_status = "delivered"
group by date_format(
o.order_purchase_timestamp, '%Y-%m')
),
revenue_comparision as (
	select order_month, revenue, 
    lag(revenue) over(
    order by order_month) as previous_month_revenue
    from monthly_revenue)
select order_month, 
		round(revenue, 2) as revenue, 
        round(previous_month_revenue, 2) as previous_month_revenue,
        round((revenue - previous_month_revenue) / nullif(previous_month_revenue, 0) * 100, 2) as mom_growth_percentage
from revenue_comparision
order by order_month;

-- Top 10 product categories by revenue
-- SQL skills: join, sum(), group by, order by, limit
-- Which product category generates the most revenue

select 
	p.product_category_name_english, 
    round(sum(oi.price), 2) as total_revenue,
    count(distinct oi.order_id) as total_items_sold
from order_items as oi
join orders as o
	on o.order_id = oi.order_id
join products as p
	on oi.product_id = p.product_id
where o.order_status = "delivered"
group by p.product_category_name_english
order by total_revenue desc
limit 10;

-- 4. Identify repeat customers
-- SQL skills: count(), group by, having customer identification
-- Business Question: Which customers have placed more than one order
select 
	c.customer_unique_id,
    count(distinct o.order_id) as total_orders
from customers as c
join orders as o
	on c.customer_id = o.customer_id
where o.order_status = "delivered"
group by c.customer_unique_id
having count(distinct o.order_id) > 1
order by total_orders desc;

-- To calculate the overall repeat-customer percentage
with customer_orders as (
	select 
		c.customer_unique_id,
        count(distinct o.order_id) as total_orders
	from customers as c
    join orders as o
		on c.customer_id = o.customer_id
	where o.order_status = "delivered"
    group by c.customer_unique_id
)
select 
	count(*) as total_customers,
    sum(total_orders > 1) as repeat_customers,
    round(
		100.0 * sum(total_orders > 1) / nullif(count(*), 0),2) as repeat_customer_percentage
from customer_orders;

-- On-time delivery percentage
-- SQL Skills: CASE, date comparisions, conditional aggregation
-- Business Questions: What percenatage of delivered orders arrived on or before the estimated delivery
select 
	count(*) as total_delivered_orders,
    sum(
		case 
			when order_delivered_customer_date <= order_estimated_delivery_date
            then 1
            else 0
		end
	) as on_time_orders,
    
    round( 
		100.0 * sum(
			case
				when order_delivered_customer_date <= order_estimated_delivery_date 
                then 1
                else 0
			end
		) / nullif(count(*), 0), 2 
	)as on_time_delivery_percentage
from orders
where order_status = "delivered"
	and order_delivered_customer_date is not null
    and order_estimated_delivery_date is not null;

-- 7. Analyse late deliverries by seller
-- SQL Skills: Multiple joins, group by, case, sum(), avg()
-- Which sellers have the highest numnber of late delivered orders   
select 
	oi.seller_id, s.seller_city, s.seller_state,
    count(distinct o.order_id) as total_orders,
    count(distinct
		case 
			when o.order_delivered_customer_date > o.order_estimated_delivery_date
            then o.order_id
		end
	) as late_orders,
    round(
		100.0 * count(distinct
			case
				when o.order_delivered_customer_date > o.order_estimated_delivery_date
                then o.order_id
			end
		) / nullif(count(distinct o.order_id), 0),
        2
	) as late_delivery_percentage
from order_items oi
join orders o
	on oi.order_id = o.order_id
join sellers s
	on oi.seller_id = s.seller_id
where o.order_status = "delivered"
	and o.order_delivered_customer_date is not null
	and o.order_estimated_delivery_date is not null
group by oi.seller_id, seller_city, seller_state
order by late_orders desc;

-- Review score vs delivery delay
-- SQL skills: Joins, AVG(), CASE, DATEDIFF(), grouping.
-- Business question: Do late deliveries lead to lower customer review scores?
with delivery_status as (
	select 
		order_id,
        case
			when order_delivered_customer_date <= order_estimated_delivery_date
            then 'On Time'
            when order_delivered_customer_date > order_estimated_delivery_date
            then 'Late'
		end as delivery_category,
        datediff(
			order_delivered_customer_date,
            order_estimated_delivery_date) as delay_days
	from orders
    where order_status = 'delivered'
		and order_delivered_customer_date is not null
        and order_estimated_delivery_date is not null
	)
select 
	d.delivery_category, 
    count(distinct d.order_id) as total_orders,
    round(avg(r.review_score), 2) as average_review_score,
    round(avg(d.delay_days), 2) as average_days_vs_estimate
from delivery_status d
join order_reviews r
	on d.order_id = r.order_id
where d.delivery_category is not null
group by d.delivery_category
order by average_review_score desc;

-- 9. Duplicate and missing-key checks
-- SQL skills: group by, having, isnull, count(), anti-joins
-- These checks are important because inaccurate or duplicate records can affect every KPI in your dashboard.

-- A. Check duplicate order IDs
-- SQL skills: GROUP BY, HAVING, IS NULL, COUNT(), anti-joins.
-- These checks are important because inaccurate or duplicate records can affect every KPI in your dashboard.
-- A. Check duplicate order IDs
-- The order_id column should be unique in the orders table.
select order_id, count(*) as duplicate_orders_count
from orders
group by order_id
having duplicate_orders_count > 1;

-- Check duplicate order-item records
select 
	order_id, 
    order_item_id,
    count(*) as duplicate_count
from order_items
group by order_id, order_item_id
having duplicate_count > 1;

-- check missing primary keys
-- Run these queries to identify records with missing ids
-- Missing order ids 
select count(*) as missing_order_ids
from orders
where order_id is null;

-- Missing customer ids
select count(*) as missing_customer_ids
from customers
where customer_id is null;

-- Missing product ids
select count(*) as missing_product_ids
from products
where product_id is null;

-- Missing seller ids
select count(*) as missing_seller_ids
from sellers 
where seller_id is null;

-- Find orders without matching customers
select o.order_id, o.customer_id
from orders o
left join customers c
on c.customer_id = o.customer_id
where c.customer_id is null;
 
-- Find order items without matching orders
select oi.order_id, oi.product_id
from order_items oi
left join orders o
	on oi.order_id = o.order_id
where o.order_id is null;

-- Find order items without matching products 
select oi.order_id, oi.product_id
from order_items oi
left join products p
on oi.product_id = p.product_id
where p.product_id is null;

-- Check missing delivery dates 
select 
	order_status, 
	count(*) as total_orders,
    sum(order_delivered_customer_date is null) as missing_actual_delivery_dates,
    sum(order_estimated_delivery_date is null) as missing_estimated_delivery_dates
from orders
group by order_status
order by total_orders desc;
