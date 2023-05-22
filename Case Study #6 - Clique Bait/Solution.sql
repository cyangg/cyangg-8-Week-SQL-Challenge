use clique_bait;
# 1. How many users are there?
select count(distinct user_id)
from clique_bait.users;

# 2. How many cookies does each user have on average?
select count(cookie_id)/count(distinct user_id) c 
from clique_bait.users;

# 3. What is the unique number of visits by all users per month?
select month(event_time) as month, count(distinct visit_id) as count
from events
group by 1
order by 1;

# 4. What is the number of events for each event type?
select event_type, count(*) as count
from events
group by 1;

# 5. What is the percentage of visits which have a purchase event?
select count(distinct visit_id)/(select count(distinct visit_id) from events) as p
from events e1 left join event_identifier e2 using(event_type)
where event_name='Purchase';


# 6. What is the percentage of visits which view the checkout page but do not have a
# purchase event?
with cte as(
select *,
if(event_name='Purchase',1,0) as e_score, if(page_name='Checkout',1,0) as p_score
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id))
select round((1-(sum(e_score)/sum(p_score)))*100,2) as p
from cte;

drop table test;
CREATE TABLE test (
  visit_id INT,
  page_name varchar(25),
  event_name varchar(25)
);

INSERT INTO test(visit_id, page_name,event_name) VALUES
  (1, 'Home Page', 'Page View'),
  (1, 'All Products', 'Page View'),
  (1, 'Lobster', 'Page View'),
  (1, 'Lobster', 'Add to Cart'),
  (1, 'Crab', 'Page View'),
  (1, 'Crab', 'Add to Cart'),
  (1, 'Oyster', 'Page View'),
  (1, 'Oyster', 'Add to Cart'),
  (1, 'Checkout', 'Page View'),
  (1, 'Confirmation', 'Purchase'),
  (2, 'Home Page', 'Page View'),
  (2, 'All Products', 'Page View'),
  (2, 'Kingfish', 'Page View'),
  (2, 'Kingfish', 'Add to Cart'),
  (2, 'Tuna', 'Page View'),
  (2, 'Tuna', 'Add to Cart'),
  (2, 'Black Truffle', 'Page View'),
  (2, 'Abalone', 'Page View'),
  (2, 'Abalone', 'Add to Cart'),
  (2, 'Crab', 'Page View'),
  (2, 'Crab', 'Add to Cart'),
  (2, 'Checkout', 'Page View'),
  (3, 'Home Page', 'Page View'),
  (3, 'All Products', 'Page View'),
  (3, 'Crab', 'Page View'),
   (3, 'Crab', 'Add to Cart'),
  (4, 'Home Page', 'Page View'),
  (4, 'All Products', 'Page View'),
  (4, 'Abalone', 'Page View'),
  (4, 'Abalone', 'Add to Cart'),
  (4, 'Checkout', 'Page View'),
  (4, 'Confirmation', 'Purchase');

select * from test
order by visit_id;

# How many times was each product viewed?
select page_name, count(event_name) as viewed
from test
where page_name !='Home Page' and page_name !='All Products'
group by 1
order by 1;
# How many times was each product added to cart?
select page_name, count(event_name) as cart_add
from test
where event_name='Add to Cart'
group by 1
order by 1;
# How many times was each product added to a cart but not purchased (abandoned)?
select page_name,count(event_name) as abandoned 
from test t 
where t.visit_id in (
select visit_id
from test
group by visit_id
having sum(if(event_name='Purchase',1,0))=0
and sum(if(event_name='Add to Cart',1,0))>0)
and event_name='Add to Cart'
and page_name !='Home Page' and page_name !='All Products'
and page_name !='Checkout'
group by 1
;



# How many times was each product purchased?







select *
from test
where event_name = 'Purchase' or event_name ='Add to Cart'
;


# 7. What are the top 3 pages by number of views?
select page_name, count(page_name) p
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name='Page View'
group by 1
order by 2 desc
limit 3
;

# 8. What is the number of views and cart adds for each product category?
select product_category, sum(if(event_name='Page View',1,0)) as p_view,
sum(if(event_name='Add to Cart',1,0)) as c_view
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where product_category is not null
group by 1
order by 2 desc;

# 9. What are the top 3 products by purchases?
select page_name, count(event_name) as c
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where product_category is not null
and event_name = 'Purchase'
group by 1
;


select *
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where product_id is not null
;

select *
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
group by visit_id
having sum(if(event_name='Purchase',1,0))>0
;



select *
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name = 'Purchase' or event_name ='Add to Cart'
;

SELECT *
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
WHERE event_name = 'Add to Cart'
  AND visit_id IN (SELECT visit_id from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id) WHERE event_name = 'Purchase');



select visit_id, cookie_id, page_name, event_name, sequence_number
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name='Purchase'
;

# C. Product Funnel Analysis
# Using a single SQL query - create a new output table which has the following details:

# How many times was each product viewed?
select page_name, product_category, count(event_name) as viewed
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name = 'Page View'
and product_category is not null
group by 1
order by product_category;
# How many times was each product added to cart?
select page_name, product_category,count(event_name) as cart_adds
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name = 'Add to Cart'
and product_category is not null
group by 1
order by 1;
# How many times was each product added to a cart but not purchased (abandoned)?
select page_name,count(event_name) as abandoned 
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where e1.visit_id in (
select e1.visit_id
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
group by e1.visit_id
having sum(if(event_name='Purchase',1,0))=0
and sum(if(event_name='Add to Cart',1,0))>0)
and event_name='Add to Cart'
and page_name not in ('Home Page', 'All Products', 'Checkout')
group by 1
;
# How many times was each product purchased?
select page_name,count(event_name) as purchased
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where e1.visit_id in (
select e1.visit_id
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
group by e1.visit_id
having sum(if(event_name='Purchase',1,0))>0)
and event_name='Add to Cart'
and page_name not in ('Home Page', 'All Products', 'Checkout')
group by 1
;



drop table if exists product_info;
create table product_info as 
with cte1 as(
select page_name, product_category, count(event_name) as viewed
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name = 'Page View'
and product_category is not null
group by 1
order by product_category),
cte2 as(
select page_name,count(event_name) as cart_adds
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name = 'Add to Cart'
and product_category is not null
group by 1
order by 1),
cte3 as(
select page_name,count(event_name) as abandoned 
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where e1.visit_id in (
select e1.visit_id
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
group by e1.visit_id
having sum(if(event_name='Purchase',1,0))=0
and sum(if(event_name='Add to Cart',1,0))>0)
and event_name='Add to Cart'
and page_name not in ('Home Page', 'All Products', 'Checkout')
group by 1),
cte4 as (
select page_name,count(event_name) as purchased
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where e1.visit_id in (
select e1.visit_id
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
group by e1.visit_id
having sum(if(event_name='Purchase',1,0))>0)
and event_name='Add to Cart'
and page_name not in ('Home Page', 'All Products', 'Checkout')
group by 1
)
select *
from cte1 join cte2 using(page_name)
join cte3 using(page_name) 
join cte4 using(page_name)
order by product_category;




drop table if exists product_category;
create table product_category as 
with cte1 as(
select product_category, count(event_name) as viewed
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name = 'Page View'
and product_category is not null
group by 1
order by 1),
cte2 as(
select product_category,count(event_name) as cart_adds
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where event_name = 'Add to Cart'
and product_category is not null
group by 1
order by 1),
cte3 as(
select product_category,count(event_name) as abandoned 
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where e1.visit_id in (
select e1.visit_id
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
group by e1.visit_id
having sum(if(event_name='Purchase',1,0))=0
and sum(if(event_name='Add to Cart',1,0))>0)
and event_name='Add to Cart'
and page_name not in ('Home Page', 'All Products', 'Checkout')
group by 1),
cte4 as (
select product_category,count(event_name) as purchased
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
where e1.visit_id in (
select e1.visit_id
from events e1 join event_identifier e2 using(event_type)
join page_hierarchy p1 using(page_id)
group by e1.visit_id
having sum(if(event_name='Purchase',1,0))>0)
and event_name='Add to Cart'
and page_name not in ('Home Page', 'All Products', 'Checkout')
group by 1
)
select *
from cte1 join cte2 using(product_category)
join cte3 using(product_category) 
join cte4 using(product_category)
order by product_category;

# Use your 2 new output tables - answer the following questions:
# Which product had the most views, cart adds and purchases?
select page_name from product_info
order by viewed desc
limit 1; 
select page_name from product_info
order by cart_adds desc
limit 1; 
select page_name from product_info
order by purchased desc
limit 1; 
# Which product was most likely to be abandoned?
select page_name from product_info
order by abandoned desc
limit 1; 
# Which product had the highest view to purchase percentage?
select page_name,round(purchased/viewed*100,2) p
from product_info
order by 2 desc
limit 1;
# What is the average conversion rate from view to cart add?
select round(avg(cart_adds/viewed*100),2) avg_view_to_cart_add
from product_info;
# What is the average conversion rate from cart add to purchase?
select round(avg(purchased/cart_adds*100),2) avg_cart_add_to_purchase
from product_info;























