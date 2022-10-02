use sys;
drop table If Exists sales;
drop table If Exists menu;
drop table If Exists members;
Create table If Not Exists sales (customer_id varchar(20), order_date date, product_id int);
Create table If Not Exists menu (product_id int, product_name varchar(20), price int);
Create table If Not Exists members (customer_id varchar(20), join_date date);
Truncate table sales;
insert into sales (customer_id, order_date, product_id) values ('A', '2021-01-01','1');
insert into sales (customer_id, order_date, product_id) values ('A', '2021-01-01','2');
insert into sales (customer_id, order_date, product_id) values ('A', '2021-01-07','2');
insert into sales (customer_id, order_date, product_id) values ('A', '2021-01-10','3');
insert into sales (customer_id, order_date, product_id) values ('A', '2021-01-11','3');
insert into sales (customer_id, order_date, product_id) values ('A', '2021-01-11','3');
insert into sales (customer_id, order_date, product_id) values ('B', '2021-01-01','2');
insert into sales (customer_id, order_date, product_id) values ('B', '2021-01-02','2');
insert into sales (customer_id, order_date, product_id) values ('B', '2021-01-04','1');
insert into sales (customer_id, order_date, product_id) values ('B', '2021-01-11','1');
insert into sales (customer_id, order_date, product_id) values ('B', '2021-01-16','3');
insert into sales (customer_id, order_date, product_id) values ('B', '2021-02-01','3');
insert into sales (customer_id, order_date, product_id) values ('C', '2021-01-01','3');
insert into sales (customer_id, order_date, product_id) values ('C', '2021-01-01','3');
insert into sales (customer_id, order_date, product_id) values ('C', '2021-01-07','3');
Truncate table menu;
insert into menu (product_id, product_name, price) values ('1', 'sushi', '10');
insert into menu (product_id, product_name, price) values ('2', 'curry', '15');
insert into menu (product_id, product_name, price) values ('3', 'ramen', '12');
Truncate table members;
insert into members (customer_id, join_date) values ('A', '2021-01-07');
insert into members (customer_id, join_date) values ('B', '2021-01-09');

# 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, sum(price) total 
from sales s 
left join menu m using (product_id)
group by 1
;

# 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) days
from sales
group by 1;

# 3. What was the first item from the menu purchased by each customer?
select customer_id, product_name
from sales s left join menu m using (product_id)
where (customer_id, order_date) in (select customer_id,min(order_date) from sales group by customer_id)
group by 1;

# 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
# ramen, 8
select product_name, count(*) order_times
from sales s left join menu m using (product_id)
group by s.product_id
order by 2 desc
limit 1;

# 5. Which item was the most popular for each customer? !!!!!
select customer_id, product_name, count(*) order_times
from sales s left join menu m using (product_id)
group by customer_id,product_id;

with cte as (select customer_id, s.product_id, product_name,
 dense_rank() over(partition by customer_id
order by count(product_id) desc) s
from sales s left join menu m using (product_id)
group by customer_id, product_id)
select customer_id, product_name 
from cte
where s =1 ;

# 6. Which item was purchased first by the customer after they became a member?  !!!!
select s.customer_id, product_name
from sales s left join members m using (customer_id)
join menu me using (product_id)
where order_date >= join_date
group by 1;

# 7. Which item was purchased just before the customer became a member?

with cte as (
select s.customer_id, product_name,
dense_rank() over(partition by customer_id order by order_date desc) rk
from sales s left join members m using (customer_id)
join menu me using (product_id)
where order_date < join_date)
select customer_id, product_name 
from cte
where rk =1 ; 

# 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, sum(price) total_a, count(s.product_id) total_i
from sales s left join members m using (customer_id)
join menu me using (product_id)
where order_date < join_date
group by 1;

# 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
# how many points would each customer have?

select customer_id,
sum((case when product_name= 'sushi' then price*20 else price*10 end)) as points
from sales s left join menu m using (product_id)
group by 1;

# 10 .In the first week after a customer joins the program 
# (including their join date) they earn 2x points on all items, not just sushi - 
# how many points do customer A and B have at the end of January?

with points as(
select s.customer_id, order_date, join_date, s.product_id, product_name,
(case when product_name= 'sushi' then price*20 else price*10 end) as points
from sales s left join menu m using (product_id)
join members me using (customer_id)
)
select *, case when 0<=(order_date - join_date)<=7 then points*2 else points*1 end 
as new_points
from points;

select s.customer_id, order_date, join_date, s.product_id, product_name,
order_date -join_date as de
from sales s left join menu m using (product_id)
join members me using (customer_id)













