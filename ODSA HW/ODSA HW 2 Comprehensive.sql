#Task 1.1.1: Find Films with Special Characters (5 points)
#Hint: Use REGEXP to match any digit. Order by title.
select title from sakila.film where title regexp '[^[:alnum:][:space:]]+' order by title;
#Matching Any Non-Alphanumeric/Non-Whitespace Character

#Task 1.1.2: Email Domain Analysis (10 points)
#Hint: Extract everything after "@". Consider SUBSTRING + INSTR (or SUBSTRING_INDEX in MySQL 8+).
select substr(email, instr(email, '@')+1) as domain from sakila.customer where email like '%@%';

#Task 1.2.1: Find Duplicate Film Titles (10 points)
#Hint: GROUP BY title and filter with HAVING COUNT(*) > 1.
select title, count(*) as film_count from sakila.film group by title having count(*) > 1 order by title;

#Task 1.2.2: Identify Duplicate Customer Records (10 points)
#Hint: Aggregate first to find duplicates, then join back to the base table to list details.
with duplicate_customers as 
(
select customer_id, count(*) as customer_count from sakila.customer group by customer_id having customer_count > 1
)
select a.* from sakila.customer as a inner join duplicate_customers as b on a.customer_id = b.customer_id;

#Task 1.3.1: Standardize Customer Names (8 points)
#Hint: Combine TRIM + UPPER/LOWER + SUBSTRING, then CONCAT to build "Firstname Lastname".
select concat(concat(upper(substr(first_name, 1, 1)), lower(substr(first_name, 2))), ' ', concat(upper(substr(last_name, 1, 1)), lower(substr(last_name, 2)))) as customer_name from sakila.customer order by customer_name;

#Task 1.3.2: Clean and Format Phone Numbers (7 points)
#Hint: Strip non-digits first (REGEXP_REPLACE), then conditionally format when length=10. Handle NULL.
select case when phone is null then '0000000000' when length(regexp_replace(phone, '[^0-9]', '')) = 10 then regexp_replace(phone, '[^0-9]', '')
else '0000000000' end as phone from sakila.address order by phone desc;

#Task 1.3.3: Calculate Customer Tenure (10 points)
#Hint: Use DATEDIFF(CURDATE(), DATE(create_date)). Build CASE categories.
select case when tenure  <= 5 then 'Short tenure' else 'Long tenure' end as tenure_category from (
select datediff(current_date(), date(create_date)) as tenure from sakila.customer) as sub1;

#Task 2.1.1: Top Spending Customers Report (20 points)
#Hint: First CTE computes totals per customer. In outer query, compare to overall average (subquery or CTE).
with spending_per_customer as 
(
select a.customer_id, sum(case when b.customer_id is null then 0 else b.amount end) as total_spent from sakila.customer as a left join sakila.payment as b
on a.customer_id = b.customer_id
group by a.customer_id
)
select customer_id, total_spent, (select avg(amount) from sakila.payment) as overall_average from spending_per_customer where total_spent > (select avg(amount) from sakila.payment);

#Task 2.2.1: Comprehensive Film Performance Analysis (30 points)
#Hint: Build three CTEs: rentals, inventory, revenue. Join all three; compute utilization and revenue per copy. Filter to >=10 rentals.
with rentals as 
(
select c.film_id, count(a.rental_id) as rental_count from sakila.rental as a inner join sakila.inventory as b
on a.inventory_id = b.inventory_id inner join sakila.film as c on b.film_id = c.film_id group by c.film_id
),
inventory as 
(
select b.film_id, b.title, count(a.inventory_id) as inventory_count from sakila.inventory as a inner join sakila.film as b on a.film_id = b.film_id
group by b.film_id, b.title
),
revenue as 
(
select a.film_id, sum(c.amount) as revenue from 
sakila.inventory as a inner join sakila.rental as b on a.inventory_id = b.inventory_id
inner join sakila.payment as c on b.rental_id = c.rental_id
group by a.film_id
)
select b.title, c.rental_count, b.inventory_count, a.revenue from revenue as a inner join inventory as b on a.film_id = b.film_id inner join
rentals as c on a.film_id = c.film_id;

#Task 3.1.1: Rank Films by Category (15 points)
#Hint: Aggregate revenue per film; then apply RANK(), DENSE_RANK(), ROW_NUMBER() partitioned by category.
select a.film_id, c.`name` as category, a.revenue, rank() over (partition by c.`name` order by a.revenue desc) as category_rank from
(select a.film_id, sum(c.amount) as revenue from 
sakila.inventory as a inner join sakila.rental as b on a.inventory_id = b.inventory_id
inner join sakila.payment as c on b.rental_id = c.rental_id
group by a.film_id) as a inner join sakila.film_category as b on a.film_id = b.film_id
inner join sakila.category as c on b.category_id = c.category_id;

#Task 3.1.2: Customer Ranking by Store (10 points)
#Hint: Compute totals per customer; then rank within store_id and filter to top 10. You may need a subquery for filtering on window results.
select store_id, customer_id, total_payment, store_payment_rank from (
select store_id, customer_id, total_payment, row_number() over (partition by store_id order by total_payment desc) as store_payment_rank
from (
select a.store_id, a.customer_id, sum(coalesce(b.amount, 0)) as total_payment from sakila.customer as a left join 
sakila.payment as b on a.customer_id = b.customer_id group by a.store_id, a.customer_id
) as sub1) as sub2 where store_payment_rank <= 10; 

#Task 3.2.1: Daily Revenue Running Total (12 points)
#Hint: Aggregate by DATE(payment_date) first, then running total with SUM() OVER (ORDER BY...).
with revenue as 
(
select date(payment_date) as payment_date, sum(amount) as revenue from sakila.payment group by date(payment_date)
)
select payment_date, revenue, sum(revenue) over (order by payment_date) as running_total from revenue order by payment_date;

#Task 3.2.2: Customer Spending vs Store Average (13 points)
#Hint: Window AVG() over store partition; compute difference and percent rank.
