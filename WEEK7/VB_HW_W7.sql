/*1.	Create a new column called “status” in the rental table that uses a case statement 
to indicate if a film was returned late, early, or on time.*/

alter table rental				--alter the original table rental
add column status varchar(10);	--by adding a new column storing various characters of maximal length 10

update rental					--update our table with the new values 
set status = 					-- that are set to be the result of this case when.... clause
case when date_part('day', rental.return_date - rental.rental_date) > film.rental_duration then 'LATE'
	when date_part('day',rental.return_date - rental.rental_date) = film.rental_duration then 'ON TIME'
	else 'EARLY' end
from film						--based on rows filtered from film (which contains the rental duration necessary in the case statement)
inner join inventory
on film.film_id = inventory.film_id
inner join rental as r			--and based on rows in rental (which contain the rental and return dates). These two had to be joined through inventory
on r.inventory_id = inventory.inventory_id;

--2.	Show the total payment amounts for people who live in Kansas City or Saint Louis. 

select sum(amount), customer_id, city		--select sum of all the amounts belonging to a customer (group by customer at the end tells how to bin amounts to be added)
from payment
inner join customer using(customer_id)		--join to city through customer and address
inner join address using(address_id)
inner join city using(city_id)
where city = 'Saint Louis' or city = 'Kansas City'		--filter for the two cities
group by customer_id, city;								--need to group by city, too (why this limitation?). In this case there are only 1-1 customers from each city anyways

/*3.	How many films are in each category?
Why do you think there is a table for category and a table for film category?*/
/* Maybe folks who organized these table thought some tables would become too big, 
or that it is easier to navigate this way. I, personally would have put these two 
into one table*/

select count(film_id) as movie_number, name as genre		-- select count of film ids and genre
from film_category
inner join category using(category_id)						--perform join
group by genre												--need to group by genre to return the count by genre as opposed to total count
order by movie_number;

--4.	Show a roster for the staff that includes their email, address, city, and country (not ids)

select first_name, last_name, email, address, city, country --select all columns we need
from staff
left join address on staff.address_id = address.address_id	--address is in address, city in city, country in country, so we need to join to these
left join city on address.city_id = city.city_id
left join country on city.country_id = country.country_id;

--      Option B:

select concat(first_name, ' ', last_name) as name, email, address, city, country
from staff
left join address on staff.address_id = address.address_id
left join city on address.city_id = city.city_id
left join country on city.country_id = country.country_id;

--5.	Show the film_id, title, and length for the movies that were returned from May 15 to 31, 2005

select film_id, title, length
from film
inner join inventory using(film_id)
inner join rental using(inventory_id)
where return_date > '2005-05-15' and return_date < '2005-05-31';	--the where clause will filter the results based on the return date

--      Option B:

select film_id, title, length
from film
inner join inventory using(film_id)
inner join rental using(inventory_id)
where return_date between '2005-05-15' and '2005-05-31';			--we can use between instead of  < and > in two separate conditions

--6.	Write a subquery to show which movies are rented below the average price for all movies.

select title as below_average		--selected the corresponding titles from film
from film
where rental_rate < (select avg(rental_rate) from film);		--filtered the rows based on the result of the subquery that returned the average rental rate

--7.	Write a join statement to show which movies are rented below the average price for all movies.

select f1.title as below_average					-- selected the titles from film
from film f1
join film f2
on f1.film_id != f2.film_id							--performed self join (this is from google, to me not clear why the syntax has to be like this)
group by f1.title, f2.rental_rate
having f2.rental_rate < avg(f1.rental_rate);		-- filtered the results with the help of having, the average used in the filter was calculated from film rental rates

--8.	Perform an explain plan on 6 and 7, and describe what you’re seeing and important ways they differ.

--for 6:

/* "Seq Scan on film  (cost=66.51..133.01 rows=333 width=15)"
"  Filter: (rental_rate < $0)"
"  InitPlan 1 (returns $0)"
"    ->  Aggregate  (cost=66.50..66.51 rows=1 width=32)"
"          ->  Seq Scan on film film_1  (cost=0.00..64.00 rows=1000 width=6)"*/

--for 7:
/*"HashAggregate  (cost=22623.00..22668.00 rows=1000 width=21)"
"  Group Key: f1.title, f2.rental_rate"
"  Filter: (f2.rental_rate < avg(f1.rental_rate))"
"  ->  Nested Loop  (cost=0.00..15130.50 rows=999000 width=27)"
"        Join Filter: (f1.film_id <> f2.film_id)"
"        ->  Seq Scan on film f1  (cost=0.00..64.00 rows=1000 width=25)"
"        ->  Materialize  (cost=0.00..69.00 rows=1000 width=10)"
"              ->  Seq Scan on film f2  (cost=0.00..64.00 rows=1000 width=10)"*/

/*if I understand this well, 6 is much more effective than 7. The HashAggregate and nested loop are not particularly cost effective in 7. 
The latter includes an astonishing 999000 rows, while in 6 we perform operations on a 1000 rows at most. 
When running the two 6 executed in 45 ms while 7 executed in 350 ms, which is in line with the explain plan. */

--9.	With a window function, write a query that shows the film, its duration, and what percentile the duration fits into
select title, length, rental_duration,									--select title, length, duration
ntile(100) over(partition by rental_duration) as duration_percentile	--use ntile(x) to set what percentiles to look at, partition by duration defines for which column the percenties need to be calculated
from film
order by duration_percentile desc;										--order by the percentiles calculated

/*10.	In under 100 words, explain what the difference is between set-based and procedural programming. 
Be sure to specify which sql and python are.*/

/* Procedural programming (Python) performs tasks in a sequential, elementwise fashion (e.g to multiply a column it would loop through and multiply each element), 
while a set-based(SQL) approach would be to perform operations on a complete set of rows*/