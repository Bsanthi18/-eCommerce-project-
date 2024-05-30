use e_commerce;
create view new_customers_increasing_each_year as (
SELECT c.year, c.new_customers,
       CASE c.year
       WHEN '2016' THEN 0
       WHEN '2017' THEN ROUND(c.new_customers/total_2016*100,2)
       WHEN '2018' THEN ROUND(c.new_customers/total_2017*100,2)
       END AS growth_rate
FROM
(SELECT b.*,
        SUM(IF(a.year = '2016',1,0)) AS total_2016,
        SUM(IF(a.year IN ('2016','2017'),1,0)) AS total_2017,
        COUNT(a.customer_unique_id) AS total_2018
FROM (SELECT customer_unique_id,
             YEAR(MIN(order_purchase_timestamp)) AS year
      FROM customers c JOIN orders o
      ON c.customer_id = o.customer_id
      GROUP BY customer_unique_id) a
CROSS JOIN (SELECT year, 
                   COUNT(customer_unique_id) AS new_customers
            FROM (SELECT customer_unique_id,
                         YEAR(MIN(order_purchase_timestamp)) AS year
                  FROM customers c JOIN orders o
                  ON c.customer_id = o.customer_id
                  GROUP BY customer_unique_id) a
            GROUP BY year) b
GROUP BY b.year) c
ORDER BY year);
create view state_wise_product_orders_count as (
select c.customer_state,c.customer_city,p.product_category_name,count(oi.order_id) as num_orders
from customers c join orders o on c.customer_id=o.customer_id
join order_items oi on oi.order_id=o.order_id
join products p on p.product_id=oi.product_id
group by c.customer_state,c.customer_city,p.product_category_name
order by count(oi.order_id) desc);
drop view new_customers_increasing_each_year;



drop view Customers_repeating_rate;
create view Canceled_orders_by_category as (
SELECT year, product_category_name, total_canceled_orders
FROM (SELECT year, p.product_category_name,
             SUM(t1.num_canceled_orders) AS total_canceled_orders,
             RANK() OVER (PARTITION BY year ORDER BY SUM(t1.num_canceled_orders) DESC)
             AS value_rank
      FROM (SELECT order_id, YEAR(order_purchase_timestamp) AS year
            FROM orders
            WHERE order_status = 'canceled') o
      JOIN (SELECT order_id, product_id,
                   COUNT(order_id)
                   AS num_canceled_orders
            FROM order_items
            GROUP BY order_id, product_id) t1
      ON o.order_id = t1.order_id
      JOIN products p
      ON t1.product_id = p.product_id
      GROUP BY year, p.product_category_name) t3
WHERE value_rank = 1);

create view number_of_customers_each_year as(
SELECT YEAR(order_purchase_timestamp) AS year,
       COUNT(DISTINCT customer_unique_id) AS num_customers             
FROM customers c JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY year);
create view number_of_Sellers as(
select YEAR(order_purchase_timestamp) AS year,
count(distinct oi.seller_id) as num_sellers
from order_items oi join orders o
on oi.order_id=o.order_id
GROUP BY year);   
create view number_of_orders as(
select YEAR(order_purchase_timestamp) AS year,
count(distinct order_id) as num_orders
from orders 
GROUP BY year);
create view Total_sales as(
SELECT YEAR(order_purchase_timestamp) AS year,
          ROUND(SUM(oi.price) + SUM(oi.freight_value),2)
                   AS revenue
            FROM orders o join order_items oi
            on o.order_id=oi.order_id
            WHERE o.order_status = 'delivered'
            GROUP BY year
            order by year);
create view Total_product_category as(
 select YEAR(order_purchase_timestamp) AS year,
count(distinct product_category_name) as num_prduct_category
from orders o join order_items oi
on o.order_id=oi.order_id
join products p
on oi.product_id=p.product_id
group by year); 
create view Total_cities as(
select YEAR(order_purchase_timestamp) AS year,
count(distinct customer_city) as num_customers
from orders o
join customers c
on o.customer_id=c.customer_id
group by year);                   
create view Total_sates as(
 select YEAR(order_purchase_timestamp) AS year,
count(distinct customer_state) as num_states
from orders o
join customers c
on o.customer_id=c.customer_id
group by year);   
create view product_category_by_sales as(
select distinct product_category_name,
YEAR(order_purchase_timestamp) AS year,       
 ROUND(SUM(oi.price) + SUM(oi.freight_value),2)
                   AS revenue
	from orders o join order_items oi
on o.order_id=oi.order_id
join products p
on oi.product_id=p.product_id
group by year,product_category_name);		
create view sales_by_date as(
SELECT YEAR(order_purchase_timestamp) AS year,
       month(order_purchase_timestamp) AS month,
          ROUND(SUM(oi.price) + SUM(oi.freight_value),2)
                   AS revenue
            FROM orders o join order_items oi
            on o.order_id=oi.order_id
            WHERE o.order_status = 'delivered'
            GROUP BY year,month
            order by year,month);	
create view Average_review_score as(
 select YEAR(order_purchase_timestamp) AS year,
        avg(review_score) as avr_review_score
        from orders o join order_reviews ors
        on o.order_id=ors.order_id
         group by year
         order by year);
 create view orders_by_order_status as(
 select distinct order_status,
      YEAR(order_purchase_timestamp) AS year, 
        count(distinct order_id) as num_orders
        from orders
        group by order_status,year
        order by year);
 create view orders_by_payment_type as(       
 select distinct op.payment_type,
      YEAR(order_purchase_timestamp) AS year, 
        count(distinct o.order_id) as num_orders  
        from orders o join order_payments op
        on o.order_id=op.order_id
        group by op.payment_type,year
        order by year);
create view category_orders_sales_reviews as(
 select distinct product_category_name,
        YEAR(order_purchase_timestamp) AS year,
        ROUND(SUM(oi.price) + SUM(oi.freight_value),2)
                   AS Total_sales,
        count(distinct o.order_id) as Total_orders,
        avg(ors.review_score) as Avr_review_score
        from products p join order_items oi
        on p.product_id=oi.product_id
        join orders o
        on oi.order_id=o.order_id
        join order_reviews ors
        on o.order_id=ors.order_id
        group by product_category_name,year
        order by year);

