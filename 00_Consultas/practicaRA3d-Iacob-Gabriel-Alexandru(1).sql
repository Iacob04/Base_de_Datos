use sakila;

#Consulta 1: Clientes con al menos un alquiler
SELECT DISTINCT
    c.customer_id, c.first_name, c.last_name, c.email
FROM
    customer c
        INNER JOIN
    rental r ON c.customer_id = r.customer_id
ORDER BY c.last_name , c.first_name;


#Consulta 2: Todos los clientes y sus alquileres
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_alquileres
FROM
    customer c
        LEFT JOIN
    rental r ON c.customer_id = r.customer_id
WHERE
    c.store_id = 1
GROUP BY c.customer_id , c.first_name , c.last_name
ORDER BY total_alquileres DESC , c.last_name , c.first_name;

#Consulta 3: Actores y sus películas

SELECT 
    a.actor_id, a.first_name, a.last_name, f.title AS pelicula
FROM
    actor a
        LEFT JOIN
    film_actor fa ON a.actor_id = fa.actor_id
        LEFT JOIN
    film f ON fa.film_id = f.film_id
ORDER BY a.last_name , a.first_name , f.title;

#Consulta 4: Categorías y películas

SELECT 
    c.category_id, c.name AS categoria, f.title AS pelicula
FROM
    category c
        LEFT JOIN
    film_category fc ON c.category_id = fc.category_id
        LEFT JOIN
    film f ON fc.film_id = f.film_id 
UNION SELECT 
    c.category_id, c.name AS categoria, f.title AS pelicula
FROM
    film f
        LEFT JOIN
    film_category fc ON f.film_id = fc.film_id
        LEFT JOIN
    category c ON fc.category_id = c.category_id
WHERE
    c.category_id IS NULL
ORDER BY categoria , pelicula;


#Consulta 5: Películas y sus actores

SELECT 
    f.film_id,
    f.title AS pelicula,
    CONCAT(a.first_name, ' ', a.last_name) AS actor
FROM
    film f
        LEFT JOIN
    film_actor fa ON f.film_id = fa.film_id
        LEFT JOIN
    actor a ON fa.actor_id = a.actor_id
ORDER BY f.title , a.last_name , a.first_name;



