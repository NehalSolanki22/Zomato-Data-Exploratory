-- // This is an Exploratory data analysis project which is based on food delievery buisiness sample data created by me //
-- // There are different questions that i try to answer using queries  //

create database [Zomato]
use Zomato

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--Q 1) What is the Total Amount each customer spend on Zomato ?

select s.userid,sum(p.price) as [Total Amount] from sales as s
join product as p
on s.product_id = p.product_id
group by s.userid
order by 1

-- Q 2) How Many days each customer visited zomato ?

select userid,count(distinct(created_date)) as [Total Days] from sales
group by userid

--Q 3) What was the first product purchased by the customer

with First_product as 
(
select s.userid,s.created_date,s.product_id,p.product_name,ROW_NUMBER() over (partition by s.userid order by s.created_date) as [Rank] from sales as s
join product as p 
on s.product_id=p.product_id
)

select userid,created_date,product_name from First_product
where [Rank] = 1

--Q 4) What was the most purchased item on the menu and how many times it was purchased by each customer

select userid,count(product_id) as [Total Purchase] from sales
where product_id=(select top 1 product_id from sales
group by product_id 
order by count(product_id) desc)
group by userid
order by 2 desc

--Q 5) Which Item was the most popular for each customer

with Most_Popular as(
select userid,product_id,count(product_id) as [Total Purchase],ROW_NUMBER() over (partition by userid order by count(product_id) desc) as [Rank]  from sales
group by userid,product_id 
)
select userid,product_id,[Total Purchase] from Most_Popular
where [Rank]=1

--Q 6) which item was first purchase by the customer after they became gold member

with First_item as(
select s.userid,s.created_date,s.product_id,ROW_NUMBER() over (partition by s.userid order by s.created_date) as [Rank] from sales as s
join goldusers_signup as g
on g.userid = s.userid
where s.created_date>=(select g.gold_signup_date)
)
select userid,product_id from First_item
where [Rank]=1

--Q 7) which item was purchase just before the customer became gold member

with First_item as(
select s.userid,s.created_date,s.product_id,g.gold_signup_date,ROW_NUMBER() over (partition by s.userid order by s.created_date desc) as [Rank] from sales as s
join goldusers_signup as g
on g.userid = s.userid
where s.created_date<(select g.gold_signup_date)
)
select userid,product_id from First_item
where [Rank]=1

--Q 8) What is the total orders and amount spent for each member before they became a member ?


select s.userid,count(s.created_date) as [Total Orders],sum(p.price) as [Amount] from sales as s
join goldusers_signup as g
on g.userid = s.userid
join product as p
on p.product_id=s.product_id
where s.created_date<(select g.gold_signup_date)
group by s.userid

--Q 9) If buying products generates points for eg 5 rs = 2 zomato points and each products have different purchasing points
-- for eg for p1 5 rs = 1 zomato points, for p2 10 rs = 5 zomato points and p3 5 rs = 1 zomato points , 2rs= 1 zomato points

-- calculate points collected by each customer and for which product most points have been given till now

select c.*,(c.Amount/c.points) as [Total Points] from (
select b.*,case when b.product_id = 1 then 5 when b.product_id = 2 then 2 when b.product_id = 3 then 5 else 0 end as [points] from 
(select a.userid,a.product_id,sum(a.price) as [Amount] from
(select s.*,p.price from sales as s
join product as p
on s.product_id=p.product_id) as a
group by a.userid,a.product_id)as b) as c

--For Customer

select c.userid,sum((c.Amount/c.points)) as [Total Points] from (
select b.*,case when b.product_id = 1 then 5 when b.product_id = 2 then 2 when b.product_id = 3 then 5 else 0 end as [points] from 
(select a.userid,a.product_id,sum(a.price) as [Amount] from
(select s.*,p.price from sales as s
join product as p
on s.product_id=p.product_id) as a
group by a.userid,a.product_id)as b) as c
group by c.userid


--For Product

select top 1 c.product_id,sum((c.Amount/c.points)) as [Total Points] from (
select b.*,case when b.product_id = 1 then 5 when b.product_id = 2 then 2 when b.product_id = 3 then 5 else 0 end as [points] from 
(select a.userid,a.product_id,sum(a.price) as [Amount] from
(select s.*,p.price from sales as s
join product as p
on s.product_id=p.product_id) as a
group by a.userid,a.product_id)as b) as c
group by c.product_id
order by 2 desc

--Q 10) In the first year after joining the gold program including join date irrespective of what they purchased they earned 5 zomato points on every 10 rs spent who earned more user 1 or 3
-- and what was there points earning in the first year

select top 1 a.userid,(a.price/2) as [Total Points] from
(select s.userid,s.product_id,p.price from sales as s
join product as p
on p.product_id=s.product_id
join goldusers_signup as g
on g.userid=s.userid and s.created_date>=g.gold_signup_date and s.created_date<=DATEADD(year,1,g.gold_signup_date)
) as a
order by 2 desc

--Q 11) Rank All the transaction of the customers

select *,RANK() over (partition by userid order by created_date) as [Transaction number] from sales

--Q 12) Rank All the transaction of the customers if they are gold member if they are non gold member mark them as na


select b.*,case when b.[Transaction number]=0 then 'NA' else b.[Transaction number] end as [Transaction Number] from
(select a.*,cast((case when gold_signup_date is null then 0 else RANK() over (partition by a.userid order by a.created_date desc)end) as varchar) as [Transaction number] from
(select s.*,g.gold_signup_date from sales as s
left join goldusers_signup as g
on s.userid=g.userid and s.created_date>=gold_signup_date) as a ) as b