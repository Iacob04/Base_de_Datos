use sakila;


/*Ejercicio1  Obtener para cada idioma, cuántas películas tienen rating 'R'*/

SELECT 
    film.title
FROM
    language
        JOIN
    film.original_language_id ON language.language_id
WHERE
    rating LIKE ('R')
ORDER BY language.name;


/*Ejercicio2 El **encargado de atención al cliente** quiere un listado de *todos* los
clientes registrados en el almacén 1 y el número de alquileres que han
hecho, incluyendo clientes sin alquileres.*/

SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    (SELECT 
            COUNT(rental.rental_id)
        FROM
            rental
        WHERE
            rental.customer_id = customer.customer_id
                AND rental.inventory_id IN (SELECT 
                    inventory.inventory_id
                FROM
                    inventory
                WHERE
                    inventory.store_id = 1)) AS total_alquileres
FROM
    customer
WHERE
    customer.store_id = 1;

/*Ejercicio3  El **gerente de la tienda** desea conocer qué clientes han realizado
alquileres de películas, sin incluir a aquellos que no han alquilado nada.*/

SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name
FROM
    customer
WHERE
    EXISTS( SELECT 
            rental.rental_id
        FROM
            rental
        WHERE
            rental.customer_id = customer.customer_id);

/*Ejercicio 4 Para cada categoría, calcula la duración media de las películas alquiladas
(considerando solo películas alquiladas).*/

SELECT 
    category.name, AVG(film.length) AS Duración_media
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
GROUP BY category.name;
/*WHERE
    EXISTS( SELECT 
            1
        FROM
            rental
        WHERE
            rental.inventory_id = inventory.inventory_id)
;*/ -- No me sale el resultado pero creo que se haria de esta manera
           

/* Ejercicio 5 Obtener para cada país la suma de los pagos (amount) realizados en 2005.*/
SELECT 
    country.country,
    (SELECT 
            SUM(payment.amount)
        FROM
            payment
                JOIN
            customer ON payment.customer_id = customer.customer_id
                JOIN
            address ON customer.address_id = address.address_id
                JOIN
            city ON address.city_id = city.city_id
        WHERE
            city.country_id = country.country_id
                AND YEAR(payment.payment_date) = 2005) AS total_pagos
FROM
    country;


