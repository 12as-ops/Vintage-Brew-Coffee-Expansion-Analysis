-- Velvet_Brew Expansion Analysis

Select *from city;
Select*from products;
select* from customers;
select * from sales;

--Reports & Data Analysis

-- Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) as unique_cx,
    ROUND(
        SUM(ci.population * 0.25)/1000000
    ,2) as coffee_consumers_in_millions
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
GROUP BY 1
ORDER BY 2 DESC;
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select *,
extract(Year from sale_date) as last_quarter_of_2023,
extract(Quarter from sale_date) as last_quarter_
from sales;


SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales AS s
JOIN customers AS c 
    ON s.customer_id = c.customer_id
JOIN city AS ci 
    ON ci.city_id = c.city_id
WHERE 
    EXTRACT(YEAR FROM s.sale_date) = 2023
    AND EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select P.product_name, count(s.product_id) As sales_count
from products as p
left join sales as s on p.product_id = s.product_id
group by p.product_id
order by sales_count desc ;

-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue, count(distinct s.customer_id) as total_customers,
	Round
	(sum(s.total)::numeric /count(distinct s.customer_id),2) 
	::numeric as avg_sales_per_customer
FROM sales AS s
JOIN customers AS c 
    ON s.customer_id = c.customer_id
JOIN city AS ci 
    ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers


WITH city_table AS

	(select 
	  city_name, 
	  Round(population * 0.25/1000000,2) as Est_coffee_cx
	from city), 
	
customer_table as

( 	SELECT ci.city_name, count(distinct c.customer_id) as unique_cx
	from sales as s
	join customers as c
	ON c.customer_id = s.customer_id
	join city as ci
	on ci.city_id = c.city_id
group by ci.city_name
)

SELECT
	customer_table.city_name,
	city_table.Est_coffee_cx as coffee_cns_millions,
	customer_table.unique_cx
	from city_table
JOIN
customer_table  on
city_table.city_name = customer_table.city_name

-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
 select * from(
select ci.city_name, p.product_name, 
	count(s.sale_id) as total_order,
	dense_rank () over(partition by ci.city_name order by count(s.sale_id) desc) as rank
from sales as s
join products as p
on s.product_id= p.product_id
join customers as c
on c.customer_id = s.customer_id
JOIN city as ci
on ci.city_id = c.city_id
group by 1,2)
 
where rank <=3;

commit;


-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?



SELECT 
   ci.city_name, count(distinct c.customer_id ) as uniq_Customer
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
join products as p
on p.product_id = s.product_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14) 
group by 1

ROLLBACK;


-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
--conclusion

WITH city_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(
            SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id),
            2 
        ) AS avg_sales_per_customer
    FROM sales AS s
    JOIN customers AS c 
        ON s.customer_id = c.customer_id
    JOIN city AS ci 
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),

city_rent as

(select city_name, estimated_rent
from city)
select cr.city_name, 
	cr.estimated_rent,
	ct.total_customers,
	ct.avg_sales_per_customer,
	round(cr.estimated_rent::numeric/ct.total_customers::numeric,2)as avg_rent_per_cx
	from city_rent as cr
JOIN
city_table as ct
on cr.city_name = ct.city_name
order by 5 desc	

ROLLBACK;


-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
--by each city
 with monthly_sales
 AS
	(select 
		ci.city_name,
		extract(month from sale_date) as month,
		extract(year from sale_date)  as year,
		sum(s.total) as total_Sale
	from sales as s
	join customers as c
	on s.customer_id = c.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1,2,3
	order by 1,3,2),

growth_ratio as		

(select 
		city_name,
		month,
		year,
		total_sale as cr_month_sale,
		lag(total_sale,1) over(partition by city_name order by year,month) as last_month_sale
		from monthly_sales
)

select 
	city_name,
	month,
	year,
	cr_month_sale,
	Round((cr_month_sale-last_month_sale)::numeric/last_month_sale ::numeric *100
	,2) as growth_ratio

	from growth_ratio
	where last_month_sale is not null;	

-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table AS (
    SELECT 
        ci.city_name,
		sum(s.total) as total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(
            SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id),
            2 
        ) AS avg_sales_per_customer
    FROM sales AS s
    JOIN customers AS c 
        ON s.customer_id = c.customer_id
    JOIN city AS ci 
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
	order by 2
),

city_rent as

	(select city_name, 
		estimated_rent,
		round((population*0.25)/1000000 ,3)as est_coffee_consumer_in_millions
	from city)
select cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customers,
	est_coffee_consumer_in_millions,
	ct.avg_sales_per_customer,
	round(cr.estimated_rent::numeric/ct.total_customers::numeric,2)as avg_rent_per_cx
	from city_rent as cr
JOIN
city_table as ct
on cr.city_name = ct.city_name
order by 2 desc






