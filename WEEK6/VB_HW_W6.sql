-- 1.	Show all customers whose last names start with T. Order them by first name from A-Z.
select last_name, first_name		--select name columns from customer table
from customer
where last_name like 'T%'			--filter based on last name using a where.... like.... statement, like allows filtering for all starting with a 'T'
order by first_name;				--order by first name

--2.	Show all rentals returned from 5/28/2005 to 6/1/2005

select rental_id, return_date		--select id, return date from rental
from rental
where return_date >= '5-28-2005' and return_date <= '6-1-2005'		--filter using a where statements based on return dates
order by return_date;				--order by return dates

--turns out it is mandatory to put date in mm-dd-yyyy format

--3.	How would you determine which movies are rented the most?

select film_id, count(rental_id) as total_rented, title		--select appropriate columns
from rental
inner join inventory										--from rental joined to inventory(contains inventory_id, is necessary as unique identifier)
using (inventory_id)
inner join film												--join to film which contains the title and film_id(title might be not unique, film_id must be)
using (film_id)
group by title, film_id										--group by film_id and title
order by total_rented desc;									--order by how many times they were rented

-- Used inner join, because if the entry is not present in any of the two tables, I am unable to extract the title or frequency anyways

--4.	Show how much each customer spent on movies (for all time) . Order them from least to most

select customer_id, sum(amount)			--selected customer id and summed the amounts spent from payment
from payment
group by customer_id					--grouped by id, so sum would be performed only per customer basis not globally
order by sum(amount);					--ordered by the total amount spent per customer

/* 5.	Which actor was in the most movies in 2006 (based on this dataset)? 
Be sure to alias the actor name and count as a more descriptive name. 
Order the results from most to least. */

select actor.actor_id, first_name, last_name, count(film.film_id) as numberof_movies		--selected appropriate columns and count separate film_ids (later be grouped by actor_id)
from actor
inner join film_actor
on actor.actor_id = film_actor.actor_id
inner join film
on film.film_id = film_actor.film_id														--joined to film_actor (contains the film ids necessary) and film(contains the release year)
where film.release_year = 2006																--filtered with the help of where clause for 2006 release year
group by actor.actor_id																		--grouped by actor for the count to be performed on a per acotr basis
order by numberof_movies desc;																--ordered by the counts

--need to use a where clause, it is a bit like if.... else pass in python

/*6.	Write an explain plan for 4 and 5. 
Show the queries and explain what is happening in each one. 
Use the following link to understand how this works */

explain select customer_id, sum(amount)
from payment
group by customer_id
order by sum(amount);

/*"Sort  (cost=383.25..384.75 rows=599 width=34)"
"  Sort Key: (sum(amount))"
"  ->  HashAggregate  (cost=348.13..355.62 rows=599 width=34)"
"        Group Key: customer_id"
"        ->  Seq Scan on payment  (cost=0.00..270.42 rows=15542 width=8)"*/

explain select actor.actor_id, first_name, last_name, count(film.film_id) as numberof_movies
from actor
inner join film_actor
on actor.actor_id = film_actor.actor_id
inner join film
on film.film_id = film_actor.film_id
where film.release_year = 2006
group by actor.actor_id
order by numberof_movies desc;

/*"Sort  (cost=259.59..260.09 rows=200 width=25)"
"  Sort Key: (count(film.film_id)) DESC"
"  ->  HashAggregate  (cost=249.94..251.94 rows=200 width=25)"
"        Group Key: actor.actor_id"
"        ->  Hash Join  (cost=85.50..218.08 rows=6372 width=21)"
"              Hash Cond: (film_actor.film_id = film.film_id)"
"              ->  Hash Join  (cost=6.50..122.30 rows=6372 width=19)"
"                    Hash Cond: (film_actor.actor_id = actor.actor_id)"
"                    ->  Seq Scan on film_actor  (cost=0.00..98.72 rows=6372 width=4)"
"                    ->  Hash  (cost=4.00..4.00 rows=200 width=17)"
"                          ->  Seq Scan on actor  (cost=0.00..4.00 rows=200 width=17)"
"              ->  Hash  (cost=66.50..66.50 rows=1000 width=4)"
"                    ->  Seq Scan on film  (cost=0.00..66.50 rows=1000 width=4)"
"                          Filter: ((release_year)::integer = 2006)"*/

-- it seems to estimate the time demand for each step. Useful when knowing enough options to optimize

--7.	What is the average rental rate per genre?

select category.name as genre, round(avg(rental_rate),2) as avg_rate		--select genre and average rental_rate
from film
inner join film_category
on film.film_id = film_category.film_id
inner join category															--this contains the categories, can be joined through film_category
on film_category.category_id = category.category_id
group by category.name;														-- group by genre, so that averages would be by genre

--8.	How many films were returned late? Early? On time?

select count(film.film_id),			--select the count film_id
case when date_part('day', rental.return_date - rental.rental_date) > film.rental_duration then 'LATE'		--create filter with help of case statement
	when date_part('day',rental.return_date - rental.rental_date) = film.rental_duration then 'ON TIME'
	else 'EARLY' end
	as return_time
from film							--join to rental (contains the rental dates information), through inventory
inner join inventory				--left join gives the exact same result
on film.film_id = inventory.film_id
inner join rental
on rental.inventory_id = inventory.inventory_id
group by return_time;				--group by the return time defined earlier in the case statement

--9.	What categories are the most rented and what are their total sales?

select category.name as genre, count(rental.rental_id) as total_rented, sum(payment.amount) as total_revenue 
from rental
inner join inventory
on rental.inventory_id = inventory.inventory_id
inner join film 
on film.film_id = inventory.inventory_id
inner join film_category
on film.film_id = film_category.film_id
inner join category
on category.category_id = film_category.category_id
inner join payment on rental.rental_id = payment.rental_id
group by genre
order by total_rented desc;

/*need to nest two queries as aggregate functions cannot be aggregated on top of each other in one select statement. 
The subselect needs to be aliased as (x), and need to group by both columns in the first query, not very clear why, though*/

--10.	Create a view for 8 and a view for 9. Be sure to name them appropriately. 
drop view if exists view_8;

create view view_8 as			--we create the view under an alias
select * from					--selecting all columns from the result of our query under 8 (functioning as a subquery here)
(select count(film.film_id),
case when (extract(epoch from(rental.return_date - rental.rental_date)) :: integer) > film.rental_duration * 24 * 3600 then 'LATE'
	when (extract(epoch from(rental.return_date - rental.rental_date)) :: integer) = film.rental_duration * 24 * 3600 then 'ON TIME'
	else 'EARLY' end
	as return_time
from film
inner join inventory
on film.film_id = inventory.film_id
inner join rental
on rental.inventory_id = inventory.inventory_id
group by return_time) as x limit 10;		--subquery needs to be aliased. Also we limit the results to 10 rows

select * from view_8; 

drop view if exist view_9;

create view view_9 as 						--repetitio est mater studiorum
select * from
(select genre, sum(total_rev_generated) as total
from
(select category.name as genre, (count(*)*film.rental_rate) as total_rev_generated
from rental
inner join inventory
on rental.inventory_id = inventory.inventory_id
inner join film 
on film.film_id = inventory.inventory_id
inner join film_category
on film.film_id = film_category.film_id
inner join category
on category.category_id = film_category.category_id
group by category.name, film.rental_rate) as x
group by genre) as y limit 5;

select * from view_9;



--BONUS Write a query that shows how many films were rented each month. Group them by category and month. 

select category.name as genre, EXTRACT(MONTH from rental_date) as rental_month, count(rental_id)
from rental
inner join inventory
on rental.inventory_id = inventory.inventory_id
inner join film 
on film.film_id = inventory.inventory_id
inner join film_category
on film.film_id = film_category.film_id
inner join category
on category.category_id = film_category.category_id
group by category.name, EXTRACT(MONTH from rental_date)
order by rental_month;