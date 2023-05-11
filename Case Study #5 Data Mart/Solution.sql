#1
alter table weekly_sales
modify week_date varchar(10);
update weekly_sales
set week_date=date_format(str_to_date(week_date,'%d/%m/%y'),'%y-%m-%d');
alter table weekly_sales
modify week_date date;

#2
alter table weekly_sales
add week_number int after week_date;
update weekly_sales
set week_number=week(week_date,1);

#3
alter table weekly_sales
add month_number int after week_number;
update weekly_sales
set month_number=month(week_date);

#4
alter table weekly_sales
add calendar_year int after month_number;
update weekly_sales
set calendar_year=year(week_date);

#5
alter table weekly_sales
add age_band varchar(25) after segment;
update weekly_sales set 
age_band = 
case when substr(segment,2)='1' then 'Young Adults'
when substr(segment,2)='2' then 'Middle Aged'
when substr(segment,2)='3' or substr(segment,2)='4' then 'Retirees'
else 'Unknown'
end;

#6
alter table weekly_sales
add demographic varchar(25) after age_band;
update weekly_sales set 
demographic = 
case when substr(segment,1,1)='C' then 'Couples'
when substr(segment,1,1)='F' then 'Families'
else 'Unknown'
end;

#7
alter table weekly_sales
add avg_transaction FLOAT(25);
update weekly_sales set 
avg_transaction=ROUND(sales/transactions,2);

select * from weekly_sales
limit 5;

# 1. What day of the week is used for each week_date value?
SELECT 
 distinct(dayname(week_date)) AS week_day 
FROM weekly_sales;

# 2. What range of week numbers are missing from the dataset?

WITH RECURSIVE cte_series(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM cte_series WHERE n < 52
)
SELECT n FROM 
cte_series c left join weekly_sales w on c.n=w.week_number
where w.week_number is null ;

# 3. How many total transactions were there for each year in the dataset?
select calendar_year, sum(transactions) total
from weekly_sales
group by calendar_year
order by calendar_year;

# 4. What is the total sales for each region for each month?
select region, month_number, sum(sales) total
from weekly_sales
group by 1,2
order by 1,2;

# 5. What is the total count of transactions for each platform
select platform, sum(transactions) total
from weekly_sales
group by 1
order by 1;

# 6. What is the percentage of sales for Retail vs Shopify for each month?
select calendar_year,month_number, round(sum(if(platform='Retail',sales,0))/sum(sales)*100,2) as Re,
round(sum(if(platform='Shopify',sales,0))/sum(sales)*100,2) as Sh
from weekly_sales
group by calendar_year, month_number
order by calendar_year, month_number;

select calendar_year,month_number, round(sum(sales*(platform='Retail'))/sum(sales)*100,2) as Re,
 round(sum(sales*(platform='Shopify'))/sum(sales)*100,2) as Sh
from weekly_sales
group by calendar_year, month_number
order by calendar_year, month_number;

# 7. What is the percentage of sales by demographic for each year in the dataset?
select calendar_year, demographic, sum(sales)/sum(sum(sales)) over(partition by calendar_year) as p
from weekly_sales
group by 1,2
order by 1,2;

# 8. Which age_band and demographic values contribute the most to Retail sales?
select age_band, demographic, sum(sales) sum, (sum(sales)/sum(sum(sales)) over())*100 as p
from weekly_sales
group by 1,2
order by 3 desc;

# 9. Can we use the avg_transaction column to find the average 
# transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
select calendar_year,platform, round(avg(avg_transaction)) as avg_transaction_row,
round(sum(sales)/sum(transactions)) as avg_transaction_group
from weekly_sales
group by 1,2
order by 1,2;


# Before & After Analysis
# 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the
# growth or reduction rate in actual values and percentage of sales?

with cte as(
select 
sum(case when week_date between date_sub('2020-06-15', interval 4 week) and '2020-06-15' then sales else 0 end) as sales_before,
sum(case when week_date between '2020-06-15' and date_add('2020-06-15', interval 4 week)  then sales else 0 end) as sales_after
from weekly_sales)
select sales_before,sales_after, sales_after-sales_before as sales_variance,
round((sales_after-sales_before)/sales_before*100,2) as percentage
from cte;

# 2. What about the entire 12 weeks before and after?
with cte as(
select 
sum(case when week_date between date_sub('2020-06-15', interval 12 week) and '2020-06-15' then sales else 0 end) as sales_before,
sum(case when week_date between '2020-06-15' and date_add('2020-06-15', interval 12 week)  then sales else 0 end) as sales_after
from weekly_sales)
select sales_before,sales_after, sales_after-sales_before as sales_variance,
round((sales_after-sales_before)/sales_before*100,2) as percentage
from cte;

# 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
# For 4 weeks:
with cte as(
select calendar_year,
sum(case when week_date between date_sub('2018-06-15', interval 4 week) and '2018-06-15' then sales else 0 end)
+
sum(case when week_date between date_sub('2019-06-15', interval 4 week) and '2019-06-15' then sales else 0 end)
as sales_before,
sum(case when week_date between '2018-06-15' and date_add('2018-06-15', interval 4 week)  then sales else 0 end)
+
sum(case when  week_date between '2019-06-15' and date_add('2019-06-15', interval 4 week)  then sales else 0 end) 
as sales_after
from weekly_sales
group by 1)
select calendar_year,sales_before,sales_after, sales_after-sales_before as sales_variance,
round((sales_after-sales_before)/sales_before*100,2) as percentage
from cte
where calendar_year in(2018,2019)
order by 1;

# For 12 weeks:
with cte as(
select calendar_year,
sum(case when week_date between date_sub('2018-06-15', interval 12 week) and '2018-06-15' then sales else 0 end)
+
sum(case when week_date between date_sub('2019-06-15', interval 12 week) and '2019-06-15' then sales else 0 end)
as sales_before,
sum(case when week_date between '2018-06-15' and date_add('2018-06-15', interval 12 week)  then sales else 0 end)
+
sum(case when  week_date between '2019-06-15' and date_add('2019-06-15', interval 12 week)  then sales else 0 end) 
as sales_after
from weekly_sales
group by 1)
select calendar_year,sales_before,sales_after, sales_after-sales_before as sales_variance,
round((sales_after-sales_before)/sales_before*100,2) as percentage
from cte
where calendar_year in(2018,2019)
order by 1;




drop table test;
CREATE TABLE test (
  calendar_year INT,
  demographic VARCHAR(255),
  sales int
);

INSERT INTO test (calendar_year, demographic, sales) VALUES
(2020, 'Male', 10),
(2020, 'Female', 12),
(2020, 'Other', 5),
(2020, 'Male', 4),
(2021, 'Male', 8),
(2021, 'Female', 9),
(2021, 'Other', 3);

select * from test;

select calendar_year, demographic, sum(sales)/sum(sum(sales)) over() as s
from test
group by 1,2;

drop table test1;
CREATE TABLE test1 (
  calendar_year INT,
  sale1 int,
  sale2 int,
  sale3 int,
  sale4 int
);

INSERT INTO test1 (calendar_year, sale1,sale2,sale3,sale4) VALUES
(2018, 1,2,0,0),
(2019, 0,0,1,2),
(2020, 0,0,0,0);

select * from test1;

select calendar_year, sale1+sale2 as t1, sale3+sale4 as t2
from test1
group by 1





