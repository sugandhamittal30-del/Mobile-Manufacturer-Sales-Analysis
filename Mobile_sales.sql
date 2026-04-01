
--Q1  List all the states in which we have customers who have bought cellphones  from 2005 till today.

SELECT DISTINCT l.State
FROM FACT_TRANSACTIONS f
JOIN DIM_LOCATION l
ON f.IDLocation = l.IDLocation
WHERE YEAR(f.Date) >= 2005;

--Q2 What state in the US is buying the most 'Samsung' cell phones?   

select top 1 state 
from FACT_TRANSACTIONS as f
join DIM_LOCATION as l
on f.IDLocation= l.IDLocation
join DIM_MODEL as m
on f.IDModel= m.IDModel
join DIM_MANUFACTURER as ma
on m.IDManufacturer= ma.IDManufacturer
where Country='us' and Manufacturer_Name='samsung'
group by State
order by SUM(quantity) desc

--Q3  Show the number of transactions for each model per zip code per state.   

select State,ZipCode,Model_Name,COUNT(*) as trans_count
from FACT_TRANSACTIONS as f
inner join DIM_LOCATION as l
on f.IDLocation=l.IDLocation
join DIM_MODEL as m
on f.IDModel=m.IDModel
group by State,ZipCode,Model_Name

--Q4 Show the cheapest cellphone (Output should contain the price also) 

select top 1 model_name , unit_price from DIM_model
order by Unit_price asc

--Q5 Find out the average price for each model in the top5 manufacturers in  
--  terms of sales quantity and order by average price.   

select  Model_Name,AVG(totalprice) as avg_price,sum(quantity) as total_qty from FACT_TRANSACTIONS as f 
join DIM_MODEL as m
on f.IDModel=m.IDModel
join DIM_MANUFACTURER as ma
on ma.IDManufacturer=m.IDManufacturer
where Manufacturer_Name in ( select top 5 Manufacturer_Name from FACT_TRANSACTIONS as f 
                             join DIM_MODEL as m
                             on f.IDModel=m.IDModel
                             join DIM_MANUFACTURER as ma
                             on ma.IDManufacturer=m.IDManufacturer
                             group by Manufacturer_Name
                             order by SUM(totalprice) desc)
group by Model_Name
order by avg_price desc


--Q6 List the names of the customers and the average amount spent in 2009,  
--  where the average is higher than 500.

select Customer_Name,AVG(totalprice) as avg_amount 
from DIM_CUSTOMER as c
join FACT_TRANSACTIONS as f
on c.IDCustomer=f.IDCustomer
where YEAR(date)=2009
group by Customer_Name
having AVG(totalprice)>500 

 --Q7 List if there is any model that was in the top 5 in terms of quantity,  
 --  simultaneously in 2008, 2009 and 2010  
select model_name from
( select top 5 Model_Name
 from FACT_TRANSACTIONS as f
 join DIM_MODEL as m
 on f.IDModel=m.IDModel
 where YEAR(date)=2008
 group by Model_Name
 order by SUM(quantity) desc
 intersect
  select top 5 Model_Name
 from FACT_TRANSACTIONS as f
 join DIM_MODEL as m
 on f.IDModel=m.IDModel
 where YEAR(date)=2009
 group by Model_Name
 order by SUM(quantity) desc
 intersect
  select top 5 Model_Name
 from FACT_TRANSACTIONS as f
 join DIM_MODEL as m
 on f.IDModel=m.IDModel
 where YEAR(date)=2010
 group by Model_Name
 order by SUM(quantity) desc) as x


 
 --Q8 Show the manufacturer with the 2nd top sales in the year of 2009 and the  
 --   manufacturer with the 2nd top sales in the year of 2010.

select Manufacturer_Name,sales from
      (select Manufacturer_Name,SUM(totalprice) as sales,DENSE_RANK() over(order by sum(totalprice) desc) as ranks
      from FACT_TRANSACTIONS as f
      join DIM_MODEL as m
      on f.IDModel=m.IDModel
      join DIM_MANUFACTURER as ma
      on m.IDManufacturer=ma.IDManufacturer
      where YEAR(date)=2009 
      group by Manufacturer_Name) as x
      where ranks=2
      union
select manufacturer_name,sales from
      (select Manufacturer_Name,SUM(totalprice) as sales,DENSE_RANK() over(order by sum(totalprice) desc) as ranks
      from FACT_TRANSACTIONS as f
      join DIM_MODEL as m
      on f.IDModel=m.IDModel
      join DIM_MANUFACTURER as ma
      on m.IDManufacturer=ma.IDManufacturer
      where YEAR(date)=2010
      group by Manufacturer_Name) as x
      where ranks=2

--Q9 Show the manufacturers that sold cellphones in 2010 but did not in 2009. 

select distinct Manufacturer_Name from
FACT_TRANSACTIONS as f
join DIM_MODEL as m
on f.IDModel=m.IDModel
join DIM_MANUFACTURER as ma
on ma.IDManufacturer=m.IDManufacturer
where YEAR(date)=2010 and Manufacturer_Name not in (select distinct Manufacturer_Name from
FACT_TRANSACTIONS as f
join DIM_MODEL as m
on f.IDModel=m.IDModel
join DIM_MANUFACTURER as ma
on ma.IDManufacturer=m.IDManufacturer
where YEAR(date)=2009)

--Q10 Find top 10 customers and their average spend, average quantity by each  
--   year. Also find the percentage of change in their spend. 

with top_cust as
(select top 10 Customer_Name from FACT_TRANSACTIONS as f
join DIM_CUSTOMER as c
on c.IDCustomer=f.IDCustomer
group by Customer_Name
order by SUM(totalprice) desc),

avg_data as 
( select Customer_Name,year(date) as year,AVG(totalprice) as avg_spend, AVG(quantity) as avg_aqty from FACT_TRANSACTIONS as f
join DIM_CUSTOMER as c
on c.IDCustomer=f.IDCustomer
where Customer_Name in ( select Customer_Name from top_cust)
group by Customer_Name, YEAR(date)),

lag_prices as
(select *,LAG(avg_spend,1) over(partition by customer_name order by year) as lag_price
from avg_data) 

select *,((avg_spend-lag_price)/lag_price)as percent_change
from lag_prices


