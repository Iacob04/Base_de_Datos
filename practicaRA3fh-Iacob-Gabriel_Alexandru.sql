use sakila;
/*1) Película(s) más larga(s) por categoría*/

SELECT 
    c.name AS category, f.title AS title, f.length AS length
FROM
    category c
        JOIN
    film_category fc ON c.category_id = fc.category_id
        JOIN
    film f ON fc.film_id = f.film_id
WHERE
    f.length = (SELECT 
            MAX(f2.length)
        FROM
            film f2
                JOIN
            film_category fc2 ON f2.film_id = fc2.film_id
        WHERE
            fc2.category_id = c.category_id)
ORDER BY category ASC;

/*2) Número de películas sin stock disponible en ninguna tienda*/

SELECT 
    COUNT(*) AS num_unavailable_films
FROM
    film f
WHERE
    NOT EXISTS( SELECT 
            1
        FROM
            inventory i
        WHERE
            i.film_id = f.film_id
                AND i.inventory_id NOT IN (SELECT 
                    r.inventory_id
                FROM
                    rental r
                WHERE
                    r.return_date IS NULL));


/*3) Recaudación mensual por categoría en 2024*/

SELECT 
    c.name AS category,
    MONTH(p.payment_date) AS month,
    SUM(p.amount) AS total
FROM
    payment p
        JOIN
    rental r ON p.rental_id = r.rental_id
        JOIN
    inventory i ON r.inventory_id = i.inventory_id
        JOIN
    film_category fc ON i.film_id = fc.film_id
        JOIN
    category c ON fc.category_id = c.category_id
WHERE
    YEAR(p.payment_date) = 2024
GROUP BY c.name , MONTH(p.payment_date)
ORDER BY category ASC , month ASC;

/*4) Clientes con alquileres pero sin pagos registrados*/

SELECT 
    cu.customer_id,
    CONCAT(cu.first_name, ' ', cu.last_name) AS customer
FROM
    customer cu
WHERE
    EXISTS( SELECT 
            1
        FROM
            rental r
        WHERE
            r.customer_id = cu.customer_id)
        AND NOT EXISTS( SELECT 
            1
        FROM
            payment p
        WHERE
            p.customer_id = cu.customer_id);

/*5) Cliente(s) que más ha(n) gastado en cada país*/

SELECT 
    co.country AS country,
    CONCAT(cu.first_name, ' ', cu.last_name) AS top_customer,
    SUM(p.amount) AS max_spent
FROM
    payment p
        JOIN
    customer cu ON p.customer_id = cu.customer_id
        JOIN
    address a ON cu.address_id = a.address_id
        JOIN
    city ci ON a.city_id = ci.city_id
        JOIN
    country co ON ci.country_id = co.country_id
GROUP BY co.country , cu.customer_id
HAVING SUM(p.amount) = (SELECT 
        MAX(total_by_customer)
    FROM
        (SELECT 
            SUM(p2.amount) AS total_by_customer
        FROM
            payment p2
        JOIN customer cu2 ON p2.customer_id = cu2.customer_id
        JOIN address a2 ON cu2.address_id = a2.address_id
        JOIN city ci2 ON a2.city_id = ci2.city_id
        WHERE
            ci2.country_id = ci.country_id
        GROUP BY cu2.customer_id) AS subquery)
ORDER BY country ASC;


/*6) Categorías con ingresos superiores a la media global*/
SELECT 
    c.name AS category, SUM(p.amount) AS total_revenue
FROM
    payment p
        JOIN
    rental r ON p.rental_id = r.rental_id
        JOIN
    inventory i ON r.inventory_id = i.inventory_id
        JOIN
    film_category fc ON i.film_id = fc.film_id
        JOIN
    category c ON fc.category_id = c.category_id
GROUP BY c.category_id , c.name
HAVING SUM(p.amount) > (SELECT 
        AVG(category_revenue)
    FROM
        (SELECT 
            SUM(p2.amount) AS category_revenue
        FROM
            payment p2
        JOIN rental r2 ON p2.rental_id = r2.rental_id
        JOIN inventory i2 ON r2.inventory_id = i2.inventory_id
        JOIN film_category fc2 ON i2.film_id = fc2.film_id
        GROUP BY fc2.category_id) avg_table)
ORDER BY total_revenue DESC;





