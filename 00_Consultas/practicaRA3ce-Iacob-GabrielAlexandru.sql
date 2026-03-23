USE sakila;
-- ==============================================
-- SECCIÓN A) 30 CONSULTAS CON JOIN DE 2 TABLAS
-- ==============================================
-- 1:  Para cada actor, muestra el número total de películas en las que aparece; es decir, cuenta cuántas filas de film_actor corresponden a cada actor.
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(film_actor.film_id) AS total_films
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
GROUP BY actor.actor_id , actor.first_name , actor.last_name;


-- 2:  Lista solo los actores que participan en 20 o más películas (umbral alto) con su conteo.
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(film_actor.film_id) AS total_films
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
GROUP BY actor.actor_id , actor.first_name , actor.last_name
HAVING COUNT(film_actor.film_id) >= 20
ORDER BY total_films DESC;



-- 3:  Para cada idioma, indica cuántas películas están catalogadas en ese idioma.
SELECT 
    language.language_id,
    language.name,
    COUNT(film.language_id) AS total_films
FROM
    language
        JOIN
    film ON language.language_id = film.language_id
GROUP BY language.language_id , language.name;


-- 4:  Muestra el promedio de duración (length) de las películas por idioma y filtra aquellos idiomas con duración media estrictamente mayor a 110 minutos.
SELECT 
    language.language_id,
    language.name,
    ROUND(AVG(film.length), 4) AS avg_length
FROM
    film
        JOIN
    language ON film.language_id = language.language_id
GROUP BY language.language_id , language.name
HAVING AVG(film.length) > 110
ORDER BY avg_length;


-- 5:  Para cada película, muestra cuántas copias hay en el inventario.
SELECT 
    film.film_id,
    film.title,
    COUNT(inventory.inventory_id) AS total_copies
FROM
    film
        JOIN
    inventory ON film.film_id = inventory.film_id
GROUP BY film.film_id , film.title
HAVING COUNT(inventory.inventory_id);


-- 6:  Lista solo las películas que tienen al menos 5 copias en inventario.
SELECT 
    film.film_id,
    film.title,
    COUNT(inventory.inventory_id) AS total_copies
FROM
    film
        JOIN
    inventory ON film.film_id = inventory.film_id
GROUP BY film.film_id , film.title
HAVING COUNT(inventory.inventory_id) >= 5;


-- 7:  Para cada artículo de inventario, cuenta cuántos alquileres se han realizado.
SELECT 
    inventory.inventory_id,
    COUNT(rental.rental_id) AS total_rental
FROM
    inventory
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
GROUP BY inventory.inventory_id;


-- 8:  Para cada cliente, muestra cuántos alquileres ha realizado en total.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    COUNT(rental.rental_id) AS total_rental
FROM
    customer
        JOIN
    rental ON customer.customer_id = rental.customer_id
GROUP BY customer.customer_id , customer.first_name , customer.last_name;


-- 9:  Lista los clientes con 30 o más alquileres acumulados.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    COUNT(rental.rental_id) AS total_rental
FROM
    customer
        JOIN
    rental ON customer.customer_id = rental.customer_id
GROUP BY customer.customer_id , customer.first_name , customer.last_name
HAVING COUNT(rental.rental_id) >= 30;


-- 10:  Para cada cliente, muestra el total de pagos (suma en euros/dólares) que ha realizado.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    SUM(payment.amount) AS total_pay
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
GROUP BY customer.customer_id , customer.first_name , customer.last_name;


-- 11:  Muestra los clientes cuyo importe total pagado es al menos 200.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    SUM(payment.amount) AS total_pay
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
GROUP BY customer.customer_id , customer.first_name , customer.last_name
HAVING SUM(payment.amount) >= 200;


-- 12:  Para cada empleado (staff), muestra el número de pagos que ha procesado.
SELECT 
    staff.staff_id,
    staff.first_name,
    staff.last_name,
    COUNT(payment.payment_id) AS payments_processed
FROM
    staff
        JOIN
    payment ON staff.staff_id = payment.staff_id
GROUP BY staff.staff_id , staff.first_name , staff.last_name;


-- 13:  Para cada empleado, muestra el importe total procesado.
SELECT 
    staff.staff_id,
    staff.first_name,
    staff.last_name,
    SUM(payment.amount) AS amount_processed
FROM
    staff
        JOIN
    payment ON staff.staff_id = payment.staff_id
GROUP BY staff.staff_id , staff.first_name , staff.last_name;


-- 14:  Para cada tienda, cuenta cuántos artículos de inventario tiene.
SELECT 
    store.store_id,
    COUNT(inventory.inventory_id) AS total_articles
FROM
    store
        JOIN
    inventory ON store.store_id = inventory.store_id
GROUP BY store.store_id;



-- 15:  Para cada tienda, cuenta cuántos clientes tiene asignados.
SELECT 
    store.store_id,
    COUNT(customer.customer_id) AS total_customers
FROM
    store
        JOIN
    customer ON store.store_id = customer.store_id
GROUP BY store.store_id;


-- 16:  Para cada tienda, cuenta cuántos empleados (staff) tiene asignados.
SELECT 
    store.store_id, COUNT(staff.staff_id) AS total_staff
FROM
    store
        JOIN
    staff ON store.store_id = staff.store_id
GROUP BY store.store_id;


-- 17:  Para cada dirección (address), cuenta cuántas tiendas hay ubicadas ahí (debería ser 0/1 en datos estándar).
SELECT 
    address.address_id, COUNT(store.store_id) AS total_stores
FROM
    address
        JOIN
    store ON address.address_id = store.address_id
GROUP BY address.address_id;


-- 18:  Para cada dirección, cuenta cuántos empleados residen en esa dirección.
SELECT 
    address.address_id, COUNT(staff.staff_id) AS total_staff
FROM
    address
        JOIN
    staff ON address.address_id = staff.address_id
GROUP BY address.address_id;


-- 19:  Para cada dirección, cuenta cuántos clientes residen ahí.
SELECT 
    address.address_id,
    COUNT(customer.customer_id) AS total_customers
FROM
    address
        JOIN
    customer ON address.address_id = customer.address_id
GROUP BY address.address_id;


-- 20:  Para cada ciudad, cuenta cuántas direcciones hay registradas.
SELECT 
    city.city_id,
    city.city,
    COUNT(address.address_id) AS total_adress
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
GROUP BY city.city_id , city.city;


-- 21:  Para cada país, cuenta cuántas ciudades existen.
SELECT 
    country.country_id,
    country.country,
    COUNT(city.city_id) AS total_city
FROM
    country
        JOIN
    city ON country.country_id = city.country_id
GROUP BY country.country_id , country.country;


-- 22:  Para cada idioma, calcula la duración media de películas y muestra solo los idiomas con media entre 90 y 120 inclusive.
SELECT 
    language.language_id,
    language.name,
    AVG(film.length) AS avg_length
FROM
    language
        JOIN
    film ON language.language_id = film.language_id
GROUP BY language.language_id , language.name
HAVING AVG(film.length) BETWEEN 90 AND 120;


-- 23:  Para cada película, cuenta el número de alquileres que se han hecho de cualquiera de sus copias (usando inventario).
SELECT 
    film.film_id,
    film.title,
    COUNT(rental.rental_id) AS total_rentals
FROM
    film
        JOIN
    inventory ON film.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
GROUP BY film.film_id , film.title;

-- 24:  Para cada cliente, cuenta cuántos pagos ha realizado en 2005 (usando el año de payment_date).
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    COUNT(payment.payment_id) AS total_pay_2005
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
WHERE
    YEAR(payment.payment_date) = 2005
GROUP BY customer.customer_id , customer.first_name , customer.last_name;


-- 25:  Para cada película, muestra el promedio de tarifa de alquiler (rental_rate) de las copias existentes (es un promedio redundante pero válido).
SELECT 
    film.film_id, film.title, AVG(film.rental_rate) AS avg_rate
FROM
    film
GROUP BY film.film_id , film.title;


-- 26:  Para cada actor, muestra la duración media (length) de sus películas.
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    AVG(film.length) AS avg_length_by_actor
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
        JOIN
    film ON film_actor.film_id = film.film_id
GROUP BY actor.actor_id , actor.first_name , actor.last_name;


-- 27:  Para cada ciudad, cuenta cuántos clientes hay (usando la relación cliente->address->city requiere 3 tablas; aquí contamos direcciones por ciudad).
SELECT 
    city.city_id,
    city.city,
    COUNT(customer.customer_id) AS total_customer
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
GROUP BY city.city_id , city.city;


-- 28:  Para cada película, cuenta cuántos actores tiene asociados.
SELECT 
    film.film_id,
    film.title,
    COUNT(actor.actor_id) AS total_actors
FROM
    film
        JOIN
    film_actor ON film.film_id = film_actor.film_id
        JOIN
    actor ON film_actor.actor_id = actor.actor_id
GROUP BY film.film_id , film.title;


-- 29:  Para cada categoría (por id), cuenta cuántas películas pertenecen a ella (sin nombre de categoría para mantener 2 tablas).
SELECT 
    category.category_id, COUNT(film.film_id) AS total_films
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
GROUP BY category.category_id;


-- 30:  Para cada tienda, cuenta cuántos alquileres totales se originan en su inventario.
SELECT 
    store.store_id,
    COUNT(rental.rental_id) AS rentals_by_store_inventory
FROM
    store
        JOIN
    inventory ON store.store_id = inventory.store_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
GROUP BY store.store_id;


-- ==============================================
-- SECCIÓN B) 30 CONSULTAS CON JOIN DE 3 TABLAS
-- ==============================================
-- 31:  Para cada actor, cuenta cuántas películas tiene y muestra solo los que superan 15 películas.
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(film.film_id) AS films_by_actor
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
        JOIN
    film ON film_actor.film_id = film.film_id
GROUP BY actor.actor_id , actor.first_name , actor.last_name
HAVING COUNT(film.film_id) >= 15;



-- 32:  Para cada categoría (por nombre), cuenta cuántas películas hay en esa categoría.
SELECT 
    category.category_id,
    category.name,
    COUNT(film.film_id) AS total_films_in_category
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
GROUP BY category.category_id , category.name;


-- 33:  Para cada película, cuenta cuántos alquileres se han hecho de sus copias.
SELECT 
    film.film_id,
    film.title,
    COUNT(rental.rental_id) AS rentals_of_film
FROM
    film
        JOIN
    inventory ON film.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
GROUP BY film.film_id , film.title;


-- 34:  Para cada cliente, suma el importe pagado en 2005 y filtra clientes con total >= 150.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    SUM(payment.amount) AS total_payed
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
WHERE
    YEAR(payment.payment_date) = 2005
GROUP BY customer.customer_id , customer.first_name , customer.last_name
HAVING SUM(payment.amount) >= 150;



-- 35:  Para cada tienda, suma el importe cobrado por todos sus empleados.
SELECT 
    store.store_id,
    SUM(payment.amount) AS revenue_by_store_staff
FROM
    store
        JOIN
    staff ON store.store_id = staff.store_id
        JOIN
    payment ON staff.staff_id = payment.staff_id
GROUP BY store.store_id;


-- 36:  Para cada ciudad, cuenta cuántos empleados residen ahí (staff -> address -> city).
SELECT 
    city.city_id,
    city.city,
    COUNT(staff.staff_id) AS staff_in_city
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    staff ON address.address_id = staff.address_id
GROUP BY city.city_id , city.city;


-- 37:  Para cada ciudad, cuenta cuántas tiendas existen (store -> address -> city).
SELECT 
    city.city_id,
    city.city,
    COUNT(store.store_id) AS store_in_city
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    store ON address.address_id = store.address_id
GROUP BY city.city_id , city.city;


-- 38:  Para cada actor, calcula la duración media de sus películas del año 2006.
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    AVG(film.length) AS avg_film_length
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
        JOIN
    film ON film_actor.film_id = film.film_id
WHERE
    film.release_year = 2006
GROUP BY actor.actor_id , actor.first_name , actor.last_name;



-- 39:  Para cada categoría, calcula la duración media y muestra solo las que superan 120.
SELECT 
    category.category_id,
    category.name,
    AVG(film.length) AS avg_length_by_catecory
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
GROUP BY category.category_id , category.name
HAVING AVG(film.length) > 120;


-- 40:  Para cada idioma, suma las tarifas de alquiler (rental_rate) de todas sus películas.
SELECT 
    language.language_id,
    language.name,
    SUM(film.rental_rate) AS total_rates
FROM
    language
        JOIN
    film ON language.language_id = film.language_id
GROUP BY language.language_id , language.name;


-- 41:  Para cada cliente, cuenta cuántos alquileres realizó en fines de semana (SÁB-DO) usando DAYOFWEEK (1=Domingo).
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    COUNT(rental.rental_id) AS weekend_rentals
FROM
    customer
        JOIN
    rental ON customer.customer_id = rental.customer_id
WHERE
    DAYOFWEEK(rental.rental_date) IN (1 , 7)
GROUP BY customer.customer_id , customer.first_name , customer.last_name;


-- 42:  Para cada actor, muestra el total de títulos distintos en los que participa (equivale a COUNT DISTINCT, sin subconsulta).
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(DISTINCT (film.film_id)) AS total_titles
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
        JOIN
    film ON film_actor.film_id = film.film_id
GROUP BY actor.actor_id , actor.first_name , actor.last_name;



-- 43:  Para cada ciudad, cuenta cuántos clientes residen ahí (customer -> address -> city).
SELECT 
    city.city_id,
    city.city,
    COUNT(customer.customer_id) AS customers_in_city
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
GROUP BY city.city_id , city.city;


-- 44:  Para cada categoría, muestra cuántos actores distintos participan en películas de esa categoría.
SELECT 
    category.category_id,
    category.name,
    COUNT(DISTINCT (actor.actor_id)) AS actors_in_category
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
        JOIN
    film_actor ON film.film_id = film_actor.film_id
        JOIN
    actor ON film_actor.actor_id = actor.actor_id
GROUP BY category.category_id , category.name;


-- 45:  Para cada tienda, cuenta cuántas copias totales (inventario) tiene de películas en 2006.
SELECT 
    store.store_id, COUNT(inventory.inventory_id) AS copies_2006
FROM
    store
        JOIN
    inventory ON store.store_id = inventory.store_id
        JOIN
    film ON inventory.film_id = film.film_id
WHERE
    film.release_year = 2006
GROUP BY store.store_id;


-- 46:  Para cada cliente, suma el total pagado por alquileres cuyo empleado pertenece a la tienda 1.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    SUM(payment.amount) AS total_pay_customer_store1
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
        JOIN
    store ON customer.store_id = store.store_id
WHERE
    store.store_id = 1
GROUP BY customer.customer_id , customer.first_name , customer.last_name;


-- 47:  Para cada película, cuenta cuántos actores tienen el apellido de longitud >= 5.
SELECT 
    film.film_id,
    film.title,
    COUNT(actor.actor_id) AS actors_lastname_len5plus
FROM
    film
        JOIN
    film_actor ON film.film_id = film_actor.film_id
        JOIN
    actor ON film_actor.actor_id = actor.actor_id
WHERE
    LENGTH(actor.last_name) >= 5
GROUP BY film.film_id , film.title;



-- 48:  Para cada categoría, suma la duración total (length) de sus películas.
SELECT 
    category.category_id,
    category.name,
    SUM(film.length) AS total_duration
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
GROUP BY category.category_id , category.name;



-- 49:  Para cada ciudad, suma los importes pagados por clientes que residen en esa ciudad.
SELECT 
    city.city_id,
    city.city,
    SUM(payment.amount) AS total_payments
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
        JOIN
    payment ON customer.customer_id = payment.customer_id
GROUP BY city.city_id , city.city;


-- 50:  Para cada idioma, cuenta cuántos actores distintos participan en películas de ese idioma.
SELECT 
    language.language_id,
    language.name,
    COUNT(DISTINCT actor.actor_id) AS distinct_actors
FROM
    language
        JOIN
    film ON language.language_id = film.language_id
        JOIN
    film_actor ON film.film_id = film_actor.film_id
        JOIN
    actor ON film_actor.actor_id = actor.actor_id
GROUP BY language.language_id , language.name;



-- 51:  Para cada tienda, cuenta cuántos clientes activos (active=1) tiene.
SELECT 
    store.store_id, 
    COUNT(customer.customer_id) AS active_customers
FROM 
    store
JOIN 
    customer ON store.store_id = customer.store_id
WHERE 
    customer.active = 1
GROUP BY 
    store.store_id;


-- 52:  Para cada cliente, cuenta en cuántas categorías distintas ha alquilado (aprox. vía film_category; requiere 4 tablas, aquí contamos películas 2006 por inventario).
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    COUNT(DISTINCT category.category_id) AS rentals_2006
FROM 
    customer
JOIN 
    rental ON customer.customer_id = rental.customer_id
JOIN 
    inventory ON rental.inventory_id = inventory.inventory_id
JOIN 
    film ON inventory.film_id = film.film_id
JOIN 
    film_category ON film.film_id = film_category.film_id
JOIN 
    category ON film_category.category_id = category.category_id
WHERE 
    film.release_year = 2006
GROUP BY 
    customer.customer_id, customer.first_name, customer.last_name;
    
-- Nota: Esta consulta cuenta cuántas categorías distintas ha alquilado cada cliente en películas del año 2006,
-- como indica el enunciado ("cuenta en cuántas categorías distintas ha alquilado").
-- El resultado difiere del suyo porque parece estar contando el número de películas alquiladas en 2006,
-- no las categorías. Si se desea contar películas en lugar de categorías, habría que usar COUNT(DISTINCT film.film_id).



-- 53:  Para cada empleado, cuenta cuántos clientes diferentes le han pagado.
SELECT 
    staff.staff_id,
    staff.first_name,
    staff.last_name,
    COUNT(DISTINCT payment.customer_id) AS distinct_customers
FROM
    staff
        JOIN
    payment ON staff.staff_id = payment.staff_id
GROUP BY staff.staff_id , staff.first_name , staff.last_name;



-- 54:  Para cada ciudad, cuenta cuántas películas del año 2006 han sido alquiladas por residentes en esa ciudad.
SELECT 
    city.city_id,
    city.city,
    COUNT(DISTINCT film.film_id) AS rented_films_2006
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
        JOIN
    rental ON customer.customer_id = rental.customer_id
        JOIN
    inventory ON rental.inventory_id = inventory.inventory_id
        JOIN
    film ON inventory.film_id = film.film_id
WHERE
    film.release_year = 2006
GROUP BY city.city_id , city.city;



-- 55:  Para cada categoría, calcula el promedio de replacement_cost de sus películas.
SELECT 
    category.category_id,
    category.name,
    AVG(film.replacement_cost) AS average_replacement_cost
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
GROUP BY category.category_id , category.name;



-- 56:  Para cada tienda, suma los importes cobrados en 2006 (vía empleados de esa tienda).
SELECT 
    store.store_id, SUM(payment.amount) AS total_payments_2006
FROM
    store
        JOIN
    staff ON store.store_id = staff.store_id
        JOIN
    payment ON staff.staff_id = payment.staff_id
WHERE
    YEAR(payment.payment_date) = 2006
GROUP BY store.store_id;


-- 57:  Para cada actor, cuenta cuántas películas tienen título de más de 12 caracteres.
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(film.film_id) AS long_title_films
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
        JOIN
    film ON film_actor.film_id = film.film_id
WHERE
    LENGTH(film.title) > 12
GROUP BY actor.actor_id , actor.first_name , actor.last_name;


-- 58:  Para cada ciudad, calcula la suma de pagos de 2005 y filtra las ciudades con total >= 300.
SELECT 
    city.city_id,
    city.city,
    SUM(payment.amount) AS total_payments_2005
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
        JOIN
    payment ON customer.customer_id = payment.customer_id
WHERE
    YEAR(payment.payment_date) = 2005
GROUP BY city.city_id , city.city
HAVING SUM(payment.amount) >= 300;


-- 59:  Para cada categoría, cuenta cuántas películas tienen rating 'PG' o 'PG-13'.
SELECT 
    category.category_id,
    category.name,
    COUNT(film.film_id) AS pg_films
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
WHERE
    film.rating IN ('PG' , 'PG-13')
GROUP BY category.category_id , category.name;


-- 60:  Para cada cliente, calcula el total pagado en pagos procesados por el empleado 2.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    SUM(payment.amount) AS total_payments_by_staff2
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
WHERE
    payment.staff_id = 2
GROUP BY customer.customer_id , customer.first_name , customer.last_name;

-- ==============================================
-- SECCIÓN C) 20 CONSULTAS CON JOIN DE 4 TABLAS
-- ==============================================
-- 61:  Para cada ciudad, cuenta cuántos clientes hay y muestra solo ciudades con 10 o más clientes.
SELECT 
    city.city_id,
    city.city,
    COUNT(customer.customer_id) AS total_customers
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
GROUP BY city.city_id , city.city
HAVING COUNT(customer.customer_id) >= 10;


-- 62:  Para cada actor, cuenta cuántos alquileres totales suman todas sus películas.
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(rental.rental_id) AS total_rentals
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
        JOIN
    inventory ON film_actor.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
GROUP BY actor.actor_id , actor.first_name , actor.last_name;


-- 63:  Para cada categoría, suma los importes pagados derivados de películas de esa categoría.
SELECT 
    category.category_id,
    category.name,
    SUM(payment.amount) AS total_payments
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    inventory ON film_category.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    payment ON rental.rental_id = payment.rental_id
GROUP BY category.category_id , category.name;


-- 64:  Para cada ciudad, suma los importes pagados por clientes residentes en esa ciudad en 2005.
SELECT 
    city.city_id,
    city.city,
    SUM(payment.amount) AS total_payments_2005
FROM
    city
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
        JOIN
    payment ON customer.customer_id = payment.customer_id
WHERE
    YEAR(payment.payment_date) = 2005
GROUP BY city.city_id , city.city;


-- 65:  Para cada tienda, cuenta cuántos actores distintos aparecen en las películas de su inventario.
SELECT 
    store.store_id,
    COUNT(DISTINCT actor.actor_id) AS distinct_actors
FROM
    store
        JOIN
    inventory ON store.store_id = inventory.store_id
        JOIN
    film_actor ON inventory.film_id = film_actor.film_id
        JOIN
    actor ON film_actor.actor_id = actor.actor_id
GROUP BY store.store_id;


-- 66:  Para cada idioma, cuenta cuántos alquileres totales se han hecho de películas en ese idioma.
SELECT 
    language.language_id,
    language.name,
    COUNT(rental.rental_id) AS total_rentals
FROM
    language
        JOIN
    film ON language.language_id = film.language_id
        JOIN
    inventory ON film.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
GROUP BY language.language_id , language.name;


-- 67:  Para cada cliente, cuenta en cuántos meses distintos de 2005 realizó pagos (meses distintos).
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    COUNT(DISTINCT MONTH(payment.payment_date)) AS distinct_months
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
WHERE
    YEAR(payment.payment_date) = 2005
GROUP BY customer.customer_id , customer.first_name , customer.last_name;


-- 68:  Para cada categoría, calcula la duración media de las películas alquiladas (considerando solo películas alquiladas).
SELECT 
    category.category_id,
    category.name,
    AVG(film.length) AS average_length
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    inventory ON film_category.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    film ON inventory.film_id = film.film_id
GROUP BY category.category_id , category.name;


-- 69:  Para cada país, cuenta cuántos clientes hay (country -> city -> address -> customer).
SELECT 
    country.country_id,
    country.country,
    COUNT(customer.customer_id) AS total_customers
FROM
    country
        JOIN
    city ON country.country_id = city.country_id
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
GROUP BY country.country_id , country.country;


-- 70:  Para cada país, suma los importes pagados por sus clientes.
SELECT 
    country.country_id,
    country.country,
    SUM(payment.amount) AS total_payments
FROM
    country
        JOIN
    city ON country.country_id = city.country_id
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
        JOIN
    payment ON customer.customer_id = payment.customer_id
GROUP BY country.country_id , country.country;


-- 71:  Para cada tienda, cuenta cuántas categorías distintas existen en su inventario.
SELECT 
    store.store_id,
    COUNT(DISTINCT category.category_id) AS distinct_categories
FROM
    store
        JOIN
    inventory ON store.store_id = inventory.store_id
        JOIN
    film_category ON inventory.film_id = film_category.film_id
        JOIN
    category ON film_category.category_id = category.category_id
GROUP BY store.store_id;


-- 72:  Para cada tienda, suma la recaudación por categoría (resultado agregado por tienda y categoría).
SELECT 
    store.store_id,
    category.category_id,
    category.name,
    SUM(payment.amount) AS total_payments
FROM
    store
        JOIN
    inventory ON store.store_id = inventory.store_id
        JOIN
    film_category ON inventory.film_id = film_category.film_id
        JOIN
    category ON film_category.category_id = category.category_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    payment ON rental.rental_id = payment.rental_id
GROUP BY store.store_id , category.category_id , category.name;


-- 73:  Para cada actor, cuenta en cuántas tiendas distintas se han alquilado sus películas.
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(DISTINCT store.store_id) AS distinct_stores
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
        JOIN
    inventory ON film_actor.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    store ON inventory.store_id = store.store_id
GROUP BY actor.actor_id , actor.first_name , actor.last_name;


-- 74:  Para cada categoría, cuenta cuántos clientes distintos han alquilado películas de esa categoría.
SELECT 
    category.category_id,
    category.name,
    COUNT(DISTINCT customer.customer_id) AS distinct_customers
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    inventory ON film_category.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    customer ON rental.customer_id = customer.customer_id
GROUP BY category.category_id , category.name;


-- 75:  Para cada idioma, cuenta cuántos actores distintos participan en películas alquiladas en ese idioma.
SELECT 
    language.language_id,
    language.name,
    COUNT(DISTINCT actor.actor_id) AS distinct_actors
FROM
    language
        JOIN
    film ON language.language_id = film.language_id
        JOIN
    film_actor ON film.film_id = film_actor.film_id
        JOIN
    inventory ON film.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    actor ON film_actor.actor_id = actor.actor_id
GROUP BY language.language_id , language.name;


-- 76:  Para cada país, cuenta cuántas tiendas hay (país->ciudad->address->store).
SELECT 
    country.country_id,
    country.country,
    COUNT(store.store_id) AS total_stores
FROM
    country
        JOIN
    city ON country.country_id = city.country_id
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    store ON address.address_id = store.address_id
GROUP BY country.country_id , country.country;


-- 77:  Para cada cliente, cuenta los alquileres en los que la devolución (return_date) fue el mismo día del alquiler.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    COUNT(rental.rental_id) AS same_day_returns
FROM
    customer
        JOIN
    rental ON customer.customer_id = rental.customer_id
WHERE
    DATE(rental.rental_date) = DATE(rental.return_date)
GROUP BY customer.customer_id , customer.first_name , customer.last_name;

-- 78:  Para cada tienda, cuenta cuántos clientes distintos realizaron pagos en 2005.
SELECT 
    store.store_id,
    COUNT(DISTINCT customer.customer_id) AS distinct_customers
FROM
    store
        JOIN
    staff ON store.store_id = staff.store_id
        JOIN
    payment ON staff.staff_id = payment.staff_id
        JOIN
    customer ON payment.customer_id = customer.customer_id
WHERE
    YEAR(payment.payment_date) = 2005
GROUP BY store.store_id;


-- 79:  Para cada categoría, cuenta cuántas películas con título de longitud > 15 han sido alquiladas.
SELECT 
    category.category_id,
    category.name,
    COUNT(DISTINCT film.film_id) AS long_title_films
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
        JOIN
    inventory ON film.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
WHERE
    LENGTH(film.title) > 15
GROUP BY category.category_id , category.name;


-- 80:  Para cada país, suma los pagos procesados por los empleados de las tiendas ubicadas en ese país.
SELECT 
    country.country_id,
    country.country,
    SUM(payment.amount) AS total_payments
FROM
    country
        JOIN
    city ON country.country_id = city.country_id
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    store ON address.address_id = store.address_id
        JOIN
    staff ON store.store_id = staff.store_id
        JOIN
    payment ON staff.staff_id = payment.staff_id
GROUP BY country.country_id , country.country;


-- ==============================================
-- SECCIÓN D) 20 CONSULTAS EXTRA (DIFICULTAD +), <=4 JOINS
-- ==============================================
-- 81:  Para cada cliente, muestra el total pagado con IVA teórico del 21% aplicado (total*1.21), redondeado a 2 decimales.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    ROUND(SUM(payment.amount) * 1.21, 2) AS total_with_vat
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
GROUP BY customer.customer_id , customer.first_name , customer.last_name;


-- 82:  Para cada hora del día (0-23), cuenta cuántos alquileres se iniciaron en esa hora.
SELECT 
    HOUR(rental.rental_date) AS rental_hour,
    COUNT(rental.rental_id) AS total_rentals
FROM
    rental
GROUP BY HOUR(rental.rental_date)
ORDER BY rental_hour asc;


-- 83:  Para cada tienda, muestra la media de length de las películas alquiladas en 2005 y filtra las tiendas con media >= 100.
SELECT 
    store.store_id, AVG(film.length) AS average_length
FROM
    store
        JOIN
    inventory ON store.store_id = inventory.store_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    film ON inventory.film_id = film.film_id
WHERE
    YEAR(rental.rental_date) = 2005
GROUP BY store.store_id
HAVING AVG(film.length) >= 100;


-- 84:  Para cada categoría, muestra la media de replacement_cost de las películas alquiladas un domingo.
SELECT 
    category.category_id,
    category.name,
    AVG(film.replacement_cost) AS average_replacement_cost
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    inventory ON film_category.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    film ON inventory.film_id = film.film_id
WHERE
    DAYOFWEEK(rental.rental_date) = 1
GROUP BY category.category_id , category.name;


-- 85:  Para cada empleado, muestra el importe total por pagos realizados entre las 00:00 y 06:00 (inclusive 00:00, exclusivo 06:00).
SELECT 
    staff.staff_id,
    staff.first_name,
    staff.last_name,
    SUM(payment.amount) AS total_payments
FROM
    staff
        JOIN
    payment ON staff.staff_id = payment.staff_id
WHERE
    TIME(payment.payment_date) >= '00:00:00'
        AND TIME(payment.payment_date) < '06:00:00'
GROUP BY staff.staff_id , staff.first_name , staff.last_name;


-- 86:  Para cada actor, cuenta cuántas de sus películas tienen un título que contiene la palabra 'LOVE' (mayúsculas).
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(film.film_id) AS love_films
FROM
    actor
        JOIN
    film_actor ON actor.actor_id = film_actor.actor_id
        JOIN
    film ON film_actor.film_id = film.film_id
WHERE
    film.title LIKE '%LOVE%'
GROUP BY actor.actor_id , actor.first_name , actor.last_name;


-- 87:  Para cada idioma, muestra el total de pagos de alquileres de películas en ese idioma.
SELECT 
    language.language_id,
    language.name,
    SUM(payment.amount) AS total_payments
FROM
    language
        JOIN
    film ON language.language_id = film.language_id
        JOIN
    inventory ON film.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    payment ON rental.rental_id = payment.rental_id
GROUP BY language.language_id , language.name;


-- 88:  Para cada cliente, cuenta en cuántos días distintos de 2005 realizó algún alquiler.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    COUNT(DISTINCT DATE(rental.rental_date)) AS distinct_days
FROM
    customer
        JOIN
    rental ON customer.customer_id = rental.customer_id
WHERE
    YEAR(rental.rental_date) = 2005
GROUP BY customer.customer_id , customer.first_name , customer.last_name;


-- 89:  Para cada categoría, calcula la longitud media de títulos (número de caracteres) de sus películas alquiladas.
SELECT 
    category.category_id,
    category.name,
    AVG(LENGTH(film.title)) AS average_title_length
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    inventory ON film_category.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    film ON inventory.film_id = film.film_id
GROUP BY category.category_id , category.name;


-- 90:  Para cada tienda, cuenta cuántos clientes distintos alquilaron en el primer trimestre de 2006 (enero-marzo).
SELECT 
    store.store_id,
    COUNT(DISTINCT customer.customer_id) AS distinct_customers
FROM
    store
        JOIN
    inventory ON store.store_id = inventory.store_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
        JOIN
    customer ON rental.customer_id = customer.customer_id
WHERE
    rental.rental_date BETWEEN '2006-01-01' AND '2006-03-31'
GROUP BY store.store_id;


-- 91:  Para cada país, cuenta cuántas categorías diferentes han sido alquiladas por clientes residentes en ese país.
SELECT 
    country.country_id,
    country.country,
    COUNT(DISTINCT category.category_id) AS distinct_categories
FROM
    country
        JOIN
    city ON country.country_id = city.country_id
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
        JOIN
    rental ON customer.customer_id = rental.customer_id
        JOIN
    inventory ON rental.inventory_id = inventory.inventory_id
        JOIN
    film_category ON inventory.film_id = film_category.film_id
        JOIN
    category ON film_category.category_id = category.category_id
GROUP BY country.country_id , country.country;


-- 92:  Para cada cliente, muestra el importe medio de sus pagos redondeado a 2 decimales, solo si ha hecho al menos 10 pagos.
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    ROUND(AVG(payment.amount), 2) AS average_payment
FROM
    customer
        JOIN
    payment ON customer.customer_id = payment.customer_id
GROUP BY customer.customer_id , customer.first_name , customer.last_name
HAVING COUNT(payment.payment_id) >= 10;


-- 93:  Para cada categoría, muestra el número de películas con replacement_cost > 20 que hayan sido alquiladas al menos una vez.
SELECT 
    category.category_id,
    category.name,
    COUNT(DISTINCT film.film_id) AS qualifying_films
FROM
    category
        JOIN
    film_category ON category.category_id = film_category.category_id
        JOIN
    film ON film_category.film_id = film.film_id
        JOIN
    inventory ON film.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
WHERE
    film.replacement_cost > 20
GROUP BY category.category_id , category.name;


-- 94:  Para cada tienda, suma los importes pagados en fines de semana.
SELECT 
    store.store_id, SUM(payment.amount) AS weekend_payments
FROM
    store
        JOIN
    staff ON store.store_id = staff.store_id
        JOIN
    payment ON staff.staff_id = payment.staff_id
WHERE
    DAYOFWEEK(payment.payment_date) IN (1 , 7)
GROUP BY store.store_id;


-- 95:  Para cada actor, cuenta cuántas películas suyas fueron alquiladas por al menos 5 clientes distintos (se cuenta alquileres y luego se filtra por HAVING).
SELECT 
    actor.actor_id,
    actor.first_name,
    actor.last_name,
    COUNT(film.film_id) AS popular_films
FROM 
    actor
JOIN 
    film_actor ON actor.actor_id = film_actor.actor_id
JOIN 
    inventory ON film_actor.film_id = inventory.film_id
JOIN 
    rental ON inventory.inventory_id = rental.inventory_id
JOIN 
    film ON film_actor.film_id = film.film_id
GROUP BY 
    actor.actor_id, actor.first_name, actor.last_name, film.film_id
HAVING 
    COUNT(DISTINCT rental.customer_id) >= 5;


-- 96:  Para cada idioma, muestra el número de películas cuyo título empieza por la letra 'A' y que han sido alquiladas.
SELECT 
    language.language_id,
    language.name,
    COUNT(DISTINCT film.film_id) AS films_starting_A
FROM
    language
        JOIN
    film ON language.language_id = film.language_id
        JOIN
    inventory ON film.film_id = inventory.film_id
        JOIN
    rental ON inventory.inventory_id = rental.inventory_id
WHERE
    film.title LIKE 'A%'
GROUP BY language.language_id , language.name;


-- 97:  Para cada país, suma el importe total de pagos realizados por clientes residentes y filtra países con total >= 1000.
SELECT 
    country.country_id,
    country.country,
    SUM(payment.amount) AS total_payments
FROM
    country
        JOIN
    city ON country.country_id = city.country_id
        JOIN
    address ON city.city_id = address.city_id
        JOIN
    customer ON address.address_id = customer.address_id
        JOIN
    payment ON customer.customer_id = payment.customer_id
GROUP BY country.country_id , country.country
HAVING SUM(payment.amount) >= 1000;


-- 98:  Para cada cliente, cuenta cuántos días han pasado entre su primer y su último alquiler en 2005 (diferencia de fechas), mostrando solo clientes con >= 5 alquileres en 2005.
--     (Se evita subconsulta calculando sobre el conjunto agrupado por cliente y usando MIN/MAX de rental_date en 2005).
SELECT 
    customer.customer_id,
    customer.first_name,
    customer.last_name,
    DATEDIFF(MAX(rental.rental_date),
            MIN(rental.rental_date)) AS rental_span_days
FROM
    customer
        JOIN
    rental ON customer.customer_id = rental.customer_id
WHERE
    YEAR(rental.rental_date) = 2005
GROUP BY customer.customer_id , customer.first_name , customer.last_name
HAVING COUNT(rental.rental_id) >= 5;

-- 99:  Para cada tienda, muestra la media de importes cobrados por transacción en el año 2006, con dos decimales.
SELECT 
    store.store_id,
    ROUND(AVG(payment.amount), 2) AS average_transaction_2006
FROM
    store
        JOIN
    staff ON store.store_id = staff.store_id
        JOIN
    payment ON staff.staff_id = payment.staff_id
WHERE
    YEAR(payment.payment_date) = 2006
GROUP BY store.store_id;


-- 100:  Para cada categoría, calcula la media de duración (length) de películas alquiladas en 2006 y ordénalas descendentemente por dicha media.
SELECT 
    category.category_id, 
    category.name, 
    AVG(film.length) AS average_length_2006
FROM 
    category
JOIN 
    film_category ON category.category_id = film_category.category_id
JOIN 
    inventory ON film_category.film_id = inventory.film_id
JOIN 
    rental ON inventory.inventory_id = rental.inventory_id
JOIN 
    film ON inventory.film_id = film.film_id
WHERE 
    YEAR(rental.rental_date) = 2006
GROUP BY 
    category.category_id, category.name
ORDER BY 
    average_length_2006 DESC;


