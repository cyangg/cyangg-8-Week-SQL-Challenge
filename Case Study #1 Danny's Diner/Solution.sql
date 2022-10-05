# 1. What is the total amount each customer spent at the restaurant?
SELECT 
    customer_id, CONCAT('$', SUM(price)) AS total_amount
FROM
    sales s
        LEFT JOIN
    menu m USING (product_id)
GROUP BY 1;

# 2. How many days has each customer visited the restaurant?
SELECT 
    customer_id, COUNT(DISTINCT order_date) days
FROM
    sales
GROUP BY 1; 

#3. What was the first item from the menu purchased by each customer?
select customer_id, m.product_name
from (select customer_id,product_id, dense_rank() over(PARTITION BY customer_id order by order_date) as s from sales)x 
join menu m using (product_id)
where x.s=1
group by 1;

#4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with cte as (select product_id, dense_rank()
over(order by ct desc) as rk from (
select product_id, count(customer_id) ct
from sales
group by 1)x)
select product_name, count(product_id) fav_count
from sales s left join menu m using (product_id)
where product_id in (select product_id from cte where rk=1)
group by 1;

#5. Which item was the most popular for each customer?
with cte as (select customer_id,product_id, ct, dense_rank()
over(partition by customer_id order by ct desc) as rk from (
select customer_id, product_id, count(product_id) ct
from sales
group by 1,2)x)
select customer_id, product_name, ct as order_count from cte c
left join menu m using (product_id)
where rk=1;

#6. Which item was purchased first by the customer after they became a member?
with cte as (select customer_id, order_date,product_id,product_name,
dense_rank() over(partition by customer_id order by order_date) rk
from sales s left join members m using (customer_id)
left join menu me using (product_id)
where order_date >= join_date)
select cte.customer_id, product_name, order_date
from cte
where rk=1;

#7. Which item was purchased just before the customer became a member?
with cte as (select customer_id, order_date,product_id,product_name,
dense_rank() over(partition by customer_id order by order_date desc) rk
from sales s left join members m using (customer_id)
left join menu me using (product_id)
where order_date < join_date)
select cte.customer_id, product_name, order_date
from cte
where rk=1;

#8. What is the total items and amount spent for each member before they became a member?
with cte as (select customer_id, order_date,product_id,product_name, price
from sales s left join members m using (customer_id)
left join menu me using (product_id)
where order_date < join_date)
select customer_id, count(product_id) total_ct, sum(price) total_amount
from cte
group by 1;

#9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as (select customer_id, price,case when product_name='sushi' then 20 else 10 end as po
from sales s left join menu m using (product_id))
select customer_id, sum(po*price) pp
from cte
group by 1;

#10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with t1 as(
select *, date_add(join_date, interval 6 day) as valid_date,
'2021-01-31' as last_date
from members)
select customer_id,
sum(case when product_name='sushi' then price*20
when order_date between join_date and valid_date then price*20
else price*10
end) as total_points
from sales join menu using (product_id)
join t1 using (customer_id)
where order_date<=last_date
group by customer_id
order by customer_id;










