--Q1)How many rows are there in the table? (ans : 5462 rows)
SELECT CONCAT(a.first_name,' ',a.last_name) as full_name,
f.title, f.description, f.length
FROM actor a
JOIN film_actor fa ON a.actor_id=fa.actor_id
JOIN film f ON f.film_id=fa.film_id;

--Q2)List of actors and movies where the movie length was more than 60 minutes. How many rows are there in this query result? 
--ans : 4900
SELECT CONCAT(a.first_name,' ',a.last_name) as actor_name,
f.title movie_name
FROM actor a
JOIN film_actor fa ON a.actor_id=fa.actor_id
JOIN film f ON f.film_id=fa.film_id
WHERE f.length>60;
--Obtain the actor id, full name of the actor, and counts the number of movies each actor has made. Identify the actor who has made the maximum number movies.
--ans:Gina Degeneres
SELECT a.actor_id, CONCAT(a.first_name,' ',a.last_name) as actor_name,
COUNT(*) movie_count
FROM actor a
JOIN film_actor fa ON a.actor_id=fa.actor_id
JOIN film f ON f.film_id=fa.film_id
GROUP BY 1,2
ORDER BY COUNT(*)DESC;

--Q3) Write a query that displays a table with 4 columns: actor's full name, film title, length of movie, and a column name "filmlen_groups" that classifies movies based on their length. Filmlen_groups should include 4 categories: 1 hour or less, Between 1-2 hours, Between 2-3 hours, More than 3 hours.

SELECT CONCAT(a.first_name,' ',a.last_name) as actor_name,
f.title, f.length,
CASE
	WHEN f.length<60 THEN 'Group 1'
    WHEN f.length>60 and f.length<120 THEN 'Group 2'
    WHEN f.length>120 and f.length<180 THEN 'Group 3'
    WHEN f.length>180 THEN 'Group 4'
END as filmlen_groups
FROM actor a
JOIN film_actor fa ON a.actor_id=fa.actor_id
JOIN film f ON f.film_id=fa.film_id;

--Q4)Write a query you to create a count of movies in each of the 4 filmlen_groups: 1 hour or less, Between 1-2 hours, Between 2-3 hours, More than 3 hours.

SELECT DISTINCT(filmlen_groups),
      COUNT(title) OVER (PARTITION BY filmlen_groups) AS filmcount_bylencat
FROM  
     (SELECT title,length,
      CASE WHEN length <= 60 THEN '1 hour or less'
      WHEN length > 60 AND length <= 120 THEN 'Between 1-2 hours'
      WHEN length > 120 AND length <= 180 THEN 'Between 2-3 hours'
      ELSE 'More than 3 hours' END AS filmlen_groups
      FROM film ) t1
ORDER BY  filmlen_groups


--Q5) Query to count films in each category and rank them by the number of films in descending order
SELECT
    category.name, -- Selecting the category name
    COUNT(film.title) AS film_count, -- Counting the number of films in each category
    RANK() OVER (ORDER BY COUNT(film.title) DESC) AS ranking -- Ranking categories based on film count
FROM
    rental
JOIN inventory USING (inventory_id) -- Joining rental with inventory on inventory_id
JOIN film_category USING (film_id) -- Joining film_category with film on film_id
JOIN category USING (category_id) -- Joining category with film_category on category_id
JOIN film USING (film_id) -- Joining film with category on film_id
GROUP BY category.name -- Grouping by category name
ORDER BY film_count DESC; -- Ordering the result by film count in descending order

--Q6)For each film category, what are the titles, ratings, and counts of movies, and how are they ordered by the number of movies within each category?

-- Selecting category name, film title, film rating, and counting movies within each category
SELECT
    category.name, -- Selecting the category name
    film.title, -- Selecting the title of the film
    film.rating, -- Selecting the rating of the film
    COUNT(film.title) OVER (PARTITION BY category.name) AS number_of_movies, -- Counting the number of movies in each category

    ROW_NUMBER() OVER (PARTITION BY category.name ORDER BY COUNT(film.title)) 
    AS count_of_movies -- Assigning row numbers based on the count of movies per category
FROM
    rental
JOIN inventory USING (inventory_id) -- Joining rental with inventory on inventory_id
JOIN film_category USING (film_id) -- Joining film_category with film on film_id
JOIN category USING (category_id) -- Joining category with film_category on category_id
JOIN film USING (film_id) -- Joining film with category on film_id
GROUP BY
    category.name, film.title, film.rating -- Grouping by category name, film title, and film rating
ORDER BY
    number_of_movies DESC, category.name, count_of_movies; 
    -- Ordering by number of movies in descending order, then by category name and count of movies

--Q7)For each rental transaction, what are the customer details, rental and return dates, days rented, whether there was a penalty due, and if so, what action needs to be taken?
WITH rental_info AS (
    SELECT
        customer_id,
        first_name || ' ' || last_name AS full_name,
        CAST(rental_date AS DATE) AS rental_date,
        CAST((rental_date + INTERVAL '5' day) AS DATE) AS expected_return_date,
        CAST(return_date AS DATE) AS actual_return_date,
        AGE(return_date, rental_date) AS days_rented_for,
        CASE
            WHEN AGE(return_date, rental_date + INTERVAL '5' day) > INTERVAL '0' day
                THEN AGE(return_date, rental_date + INTERVAL '5' day)
            ELSE INTERVAL '0' day
        END AS due_days
    FROM rental
    JOIN customer USING (customer_id)
)

SELECT
    customer_id,
    full_name,
    rental_date,
    expected_return_date,
    actual_return_date,
    days_rented_for,
    due_days,
    CASE
        WHEN due_days > INTERVAL '0' day THEN 'Charge Penalty'
        ELSE 'No Charge'
    END AS due_action
FROM rental_info
ORDER BY due_days DESC;

--Q8)What are the top and least rented (in-demand) genres and what are what are their total sales?
WITH t1 AS (
    SELECT c.name AS Genre, COUNT(cu.customer_id) AS total_rent_demand
    FROM category c
    JOIN film_category fc USING (category_id)
    JOIN film f USING (film_id)
    JOIN inventory i USING (film_id)
    JOIN rental r USING (inventory_id)
    JOIN customer cu USING (customer_id)
    GROUP BY 1
    ORDER BY 2 DESC
),
t2 AS (
    SELECT c.name AS Genre, SUM(p.amount) AS total_sales
    FROM category c
    JOIN film_category fc USING (category_id)
    JOIN film f USING (film_id)
    JOIN inventory i USING (film_id)
    JOIN rental r USING (inventory_id)
    JOIN payment p USING (rental_id)
    GROUP BY 1
    ORDER BY 2 DESC
)

SELECT t1.genre, t1.total_rent_demand, t2.total_sales
FROM t1
JOIN t2
ON t1.genre = t2.genre;

--Q9)Can we know how many distinct users have rented each genre?
SELECT c.name AS Genre, count(DISTINCT cu.customer_id) AS Total_rent_demand
FROM category c
JOIN film_category fc
USING(category_id)
JOIN film f
USING(film_id)
JOIN inventory i
USING(film_id)
JOIN rental r
USING(inventory_id)
JOIN customer cu
USING(customer_id)
GROUP BY 1
ORDER BY 2 DESC;

--Q10)What is the Average rental rate for each genre? (from the highest to the lowest)
SELECT c.name AS genre, ROUND(AVG(f.rental_rate),2) AS Average_rental_rate
FROM category c
JOIN film_category fc
USING(category_id)
JOIN film f
USING(film_id)
GROUP BY 1
ORDER BY 2 DESC;

--Q11)Who are the top 5 customers per total sales and can we get their detail just in case Rent A Film wants to reward them?
WITH t1 AS (SELECT *, first_name || ' ' || last_name AS full_name
           FROM customer)
SELECT full_name, email, address, phone, city, country, sum(amount) 
       as total_purchase_in_currency
FROM t1
JOIN address
USING(address_id)
JOIN city
USING (city_id)
JOIN country
USING (country_id)
JOIN payment
USING(customer_id)
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC
LIMIT 5;