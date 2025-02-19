create database project;

use project;
-- toggling safe mode of mysql
set sql_safe_updates = 0;

-- exploring datasets
desc customer;
desc orders;

-- cleaning/transforming customer table
delete from customer where Week = "Week"; 			-- deleting unnessesary row
update customer set `Customer Created Date` = str_to_date(`Customer Created Date`, '%d %b, %Y %H:%i:%S');	-- converting str values to datetime
alter table customer modify column `Customer Created Date` datetime;		-- changing column data type

-- creating primary key in customer table

alter table customer 
change column `Cust ID` `Cust ID` varchar(255), 
add primary key (`Cust ID`); -- creating primary key

-- cleaning/transforming order table
update orders set `Order Date` = substring(`Order Date`, 3, length(`Order Date`)); -- doing modifications for proper datetime conversion
delete from orders where locate(".", `Order Date`) > 0;		-- removing rows with unproper date entries
update orders set `Order Date` = str_to_date(`Order Date`, '%e-%c-%y %H:%i');	-- converting column values datetime format
alter table orders modify column `Order Date` datetime;		-- changing column data type
update orders set `Order Amount` = 0 where `Order Amount` = 0; -- replacing blanks with 0
alter table orders add column Revenue int;		-- Adding column to store actual revenue
update orders set Revenue = case				-- populating revenue column
								when `Order Status` = "Other" then 0
                                when `Order Status` = "Won" then `Order Amount`
							end;
			
-- calculating monthly revenue metrics
select 
	monthname(`Order Date`) month, 
	sum(`Order Amount`) total_potential,		-- total revenue that could have been made
	sum(Revenue) revenue_won, 					-- revenue from orders that were acyually won
    sum(`Order Amount`) - sum(Revenue) lost_opportunity,
    round(sum(Revenue) * 100 / sum(`Order Amount`), 2) conversion		-- percentage of revenue that was won
from orders group by monthname(`Order Date`);

-- customer acquired monthly
select 
	monthname(`Customer Created Date`) month, 
    count(*) new_customers
from customer
group by monthname(`Customer Created Date`)
order by field(month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

-- Monthly active users (MAU)
select 
	monthname(`Order Date`) month, 
    count(distinct(`Cust ID`)) active_users
from orders
group by monthname(`Order Date`)
order by field(month, 'January', 'February', 'March', 'April','May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

-- monthly average revenue per user (MRPU)
select 
	monthname(`Order Date`) month,
	round(sum(Revenue) / count(distinct(`Cust ID`)), 2) ARPU
from orders
group by monthname(`Order Date`)
order by field(month, 'January', 'February', 'March', 'April','May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

-- monthly number of orders placed vs orders won
select 
	monthname(`Order Date`) month, 
    sum(case when `Order Amount` > 0 then 1 else 0 end) orders_placed, 
	sum(case when `Order Status` = 'Won' then 1 else 0 end ) orders_won,
    round(sum(case when `Order Status` = 'Won' then 1 else 0 end ) * 100 / sum(case when `Order Amount` > 0 then 1 else 0 end), 2) percentage
from orders
group by monthname(`Order Date`)
order by field(month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');


-- profession wise orders placed vs orders won
select 
    c.`Cust Profession` profession, 
    sum(case when o.`Order Amount` > 0 then 1 else 0 end) orders_placed,
    sum(case when o.`Order Status` = 'Won' then 1 else 0 end) as orders_won,
	round(sum(case when o.`Order Status` = 'Won' then 1 else 0 end) * 100 / sum(case when o.`Order Amount` > 0 then 1 else 0 end) , 2) percentage
from customer c
left join orders o 
on c.`Cust ID` = o.`Cust ID`
group by c.`Cust Profession`
order by percentage asc;

-- cohort analysis
-- identifying first purchase month for each user
with first_purchase as (
	select 
		`Cust ID`,
        min(month(`Order Date`)) as cohort_month
	from orders
    group by `Cust ID`
), 

-- assing each purchase to a cohort and track purchases over months
cohort_analysis as (
	select 
		f.cohort_month, 
        month(`Order Date`) as purchase_month, 
        count(distinct(o.`Cust ID`)) as num_customers
	from orders o 
    join first_purchase f
    on o.`Cust ID` = f.`Cust ID`
    group by 1, 2
    order by 1, 2
)

-- creating pivot table
select 
	cohort_month, 
    sum(case when purchase_month = 1 then num_customers else 0 end) `Activity in Jan`,
	sum(case when purchase_month = 2 then num_customers else 0 end)`Activity in Feb`,
	sum(case when purchase_month = 3 then num_customers else 0 end)`Activity in Mar`,
	sum(case when purchase_month = 4 then num_customers else 0 end)`Activity in Apr`,
	sum(case when purchase_month = 5 then num_customers else 0 end)`Activity in May`,
	sum(case when purchase_month = 6 then num_customers else 0 end)`Activity in Jun`,
	sum(case when purchase_month = 7 then num_customers else 0 end)`Activity in Jul`,
	sum(case when purchase_month = 8 then num_customers else 0 end)`Activity in Aug`,
	sum(case when purchase_month = 9 then num_customers else 0 end)`Activity in Sep`
from cohort_analysis
group by cohort_month
order by cohort_month;

