use sakila;

Delimiter //

create procedure rent_movie(
in r_customer_id int ,
in r_inventory_id int ,
in r_staff_id int 
)
begin
	insert into rental (rental_date, inventory_id, customer_id, staff_id) values(NOW(), p_inv_id, p_cust_id, p_staff_id);
    
end //

Delimiter ;

-- Contar películas de una categoría
-- Crea un procedimiento contar_por_categoria que reciba el ID de una categoría (IN) y devuelva en un parámetro OUT el número de películas que pertenecen a esa categoría. Usa las tablas film_category.

delimiter //

create procedure contar_por_categoria(
in p_category_id int,
out p_cantidad_peliculas int

)
begin
select count(*) into p_cantidad_peliculas from film_category where category_id = p_category_id; 
	


end//

delimiter ;

-- Uso:
CALL contar_por_categoria(1, @total);
SELECT @total;



DELIMITER //
-- Cierre de tienda
-- Crea un procedimiento close_store que reciba un store_id y mueva todos sus empleados a la otra tienda existente. Pista: primero busca el ID de la otra tienda con un SELECT, luego actualiza la tabla staff.

CREATE PROCEDURE close_store(IN p_store_id INT)
BEGIN
    DECLARE v_target INT;

    -- Busca la otra tienda (la que NO es la que cerramos)
    SELECT store_id INTO v_target
    FROM store
    WHERE store_id <> p_store_id
    LIMIT 1;

    -- Mueve todos los empleados de la tienda cerrada
    UPDATE staff
    SET store_id = v_target
    WHERE store_id = p_store_id;
END //

DELIMITER ;

-- Uso:
CALL close_store(2);



delimiter ;



delimiter //
create procedure update_cat_prices(
in p_perc decimal(5,2) ,
in p_cat_id int 
)
begin
UPDATE film f JOIN film_category fc USING(film_id) SET f.rental_rate = f.rental_rate * (1 + p_perc/100) WHERE fc.category_id = p_cat_id;

end//


delimiter ;

-- Estadísticas de actor
-- Crea el procedimiento get_actor_stats que reciba el ID de un actor y devuelva mediante parámetros OUT el número de películas en las que ha participado y la duración media. Necesitas hacer un JOIN entre film y film_actor.
 DELIMITER //

CREATE PROCEDURE get_actor_stats(
    IN  p_actor_id INT,
    OUT p_films    INT,
    OUT p_avg_len  DECIMAL(10,2)
)
BEGIN
    SELECT COUNT(*), AVG(length)
    INTO   p_films, p_avg_len
    FROM   film
    JOIN   film_actor USING(film_id)
    WHERE  actor_id = p_actor_id;
END //

DELIMITER ;

-- Uso:
CALL get_actor_stats(1, @peliculas, @duracion);
SELECT @peliculas AS num_peliculas, @duracion AS duracion_media;



-- Conversor de minutos a texto
-- Crea la función format_min(p_min INT) que reciba minutos y devuelva un texto con formato 'Xh Ym'. Por ejemplo: 95 → '1h 35m'. Es pura matemática, no consulta ninguna tabla.

DELIMITER //

CREATE FUNCTION format_min(p_min INT)
RETURNS VARCHAR(20) DETERMINISTIC
BEGIN
    -- DIV = división entera, MOD = resto
    RETURN CONCAT(p_min DIV 60, 'h ', p_min MOD 60, 'm');
END //

DELIMITER ;

-- Uso:
SELECT format_min(95);   -- → '1h 35m'
SELECT format_min(length) AS duracion_texto FROM film LIMIT 5;


-- Email de marketing
-- Crea la función gen_mkt_email(p_first VARCHAR(45), p_last VARCHAR(45)) que genere un email corporativo con el formato nombre.apellido@sakilavideo.com todo en minúsculas. Por ejemplo: 'MARY', 'SMITH' → 'mary.smith@sakilavideo.com'.

delimiter //

create function gen_mkt_email(p_first varchar(45), p_last varchar(45))
returns varchar(50) deterministic
begin
return concat(lower(p_first),".",lower(p_last),"@sakilavideo.com");


end //
delimiter ;

-- Estado VIP del cliente
-- Crea la función get_customer_status(p_cust_id INT) que devuelva 'VIP' si el cliente ha gastado más de 150€ en total, o 'ESTANDAR' en caso contrario. Consulta la tabla payment.

delimiter //
create function get_customer_status(p_cust_id int)
returns varchar(20) 
reads sql data
begin
declare customer int ;
select amount into customer from payment where customer_id = p_cust_id;

if customer > 150 then return "VIP" ; else return "ESTANDAR"; end if; 


end //
delimiter ;

-- Uso en SELECT:
SELECT customer_id, first_name,
       get_customer_status(customer_id) AS estado
FROM customer LIMIT 10;


-- Disponibilidad total de una película
-- Crea la función total_film_stock(p_film_id INT) que devuelva el número total de copias disponibles (en stock) de una película sumando todas las tiendas. Usa la función inventory_in_stock() que ya existe en Sakila para comprobar cada copia.

DELIMITER //

CREATE FUNCTION total_film_stock(p_film_id INT)
RETURNS INT READS SQL DATA
BEGIN
    DECLARE v_count INT;

    -- inventory_in_stock() ya existe en Sakila y devuelve TRUE/FALSE
    SELECT COUNT(*) INTO v_count
    FROM inventory i
    WHERE film_id = p_film_id
      AND inventory_in_stock(i.inventory_id);  -- llama a otra función

    RETURN v_count;
END //

DELIMITER ;

-- Uso:
SELECT film_id, title,
       total_film_stock(film_id) AS copias_disponibles
FROM film WHERE film_id IN (1, 2, 3, 4, 5);

-- Cálculo de multa por retraso
-- Crea la función get_late_fine(p_rental_id INT) que devuelva la multa de un alquiler: 1.50€ por cada día de retraso sobre la duración permitida (rental_duration de la tabla film). Si no hay retraso devuelve 0. Necesita un JOIN entre rental, inventory y film. Usa IFNULL(return_date, NOW()) para los que aún no han devuelto.

DELIMITER //

CREATE FUNCTION get_late_fine(p_rental_id INT)
RETURNS DECIMAL(10,2)
NOT DETERMINISTIC READS SQL DATA   -- usa NOW() → cambia cada día
BEGIN
    DECLARE v_delay INT;

    SELECT DATEDIFF(IFNULL(return_date, NOW()), rental_date)
           - f.rental_duration          -- días pasados menos días permitidos
    INTO v_delay
    FROM rental r
    JOIN inventory i USING(inventory_id)
    JOIN film f      USING(film_id)
    WHERE r.rental_id = p_rental_id;

    -- IF como expresión: IF(condición, valor_si_true, valor_si_false)
    RETURN IF(v_delay > 0, v_delay * 1.50, 0.00);
END //

DELIMITER ;

-- Uso:
SELECT rental_id, get_late_fine(rental_id) AS multa
FROM rental WHERE return_date IS NOT NULL LIMIT 10;


-- Clasificador de rating
-- Crea un procedimiento desc_rating(IN p_rating VARCHAR(10), OUT p_desc VARCHAR(100)) que asigne una descripción según el campo rating de la tabla film. Valores posibles: G → 'Todos los públicos', PG → 'Supervisión de padres', PG-13 → 'Mayores de 13', R → 'Restringido', NC-17 → 'Solo adultos'. Cualquier otro → 'Desconocido'.

DELIMITER //

CREATE PROCEDURE desc_rating(
    IN  p_rating VARCHAR(10),
    OUT p_desc   VARCHAR(100)
)
BEGIN
    CASE p_rating
        WHEN 'G'     THEN SET p_desc = 'Todos los públicos';
        WHEN 'PG'    THEN SET p_desc = 'Supervisión de padres';
        WHEN 'PG-13' THEN SET p_desc = 'Mayores de 13';
        WHEN 'R'     THEN SET p_desc = 'Restringido';
        WHEN 'NC-17' THEN SET p_desc = 'Solo adultos';
        ELSE              SET p_desc = 'Desconocido';
    END CASE;
END //

DELIMITER ;

CALL desc_rating('PG-13', @d);
SELECT @d;

-- Validación de stock antes de alquilar
-- Crea el procedimiento check_and_rent(IN p_film_id INT, IN p_store_id INT). Debe llamar al procedimiento existente film_in_stock(film_id, store_id, OUT count) para saber cuántas copias hay disponibles, y luego mostrar el mensaje 'Disponible' si hay al menos una copia, o 'Sin existencias' si no hay ninguna.

DELIMITER //

CREATE PROCEDURE check_and_rent(
    IN p_film_id  INT,
    IN p_store_id INT
)
BEGIN
    DECLARE v_stock INT;

    -- film_in_stock es un proc. que ya existe en Sakila
    CALL film_in_stock(p_film_id, p_store_id, v_stock);

    IF v_stock > 0 THEN
        SELECT 'Disponible' AS msg;
    ELSE
        SELECT 'Sin existencias' AS msg;
    END IF;
END //

DELIMITER ;

CALL check_and_rent(1, 1);

-- Generador de 100 filas de prueba
-- Crea el procedimiento populate_test() que use un bucle WHILE para insertar 100 filas en una tabla auxiliar test_table(val INT). El valor de cada fila debe ser el número de iteración (1, 2, 3... 100).

DELIMITER //

CREATE PROCEDURE populate_test()
BEGIN
    DECLARE i INT DEFAULT 1;   -- empieza en 1

    WHILE i <= 100 DO
        INSERT INTO test_table(val) VALUES (i);
        SET i = i + 1;         -- IMPRESCINDIBLE para avanzar
    END WHILE;
END //

DELIMITER ;

CALL populate_test();
SELECT * FROM test_table;

-- Bucle de interés compuesto con LOOP
-- Crea el procedimiento calc_debt(IN p_init DECIMAL(10,2), IN p_target DECIMAL(10,2)) que aplique un interés del 5% anual a una deuda inicial hasta que supere el objetivo. Usa un LOOP con LEAVE (no WHILE). Al final muestra la deuda resultante.

DELIMITER //

CREATE PROCEDURE calc_debt(
    IN p_init   DECIMAL(10,2),
    IN p_target DECIMAL(10,2)
)
BEGIN
    DECLARE v_debt DECIMAL(10,2) DEFAULT p_init;

    -- La etiqueta permite a LEAVE saber a qué bucle referirse
    mi_loop: LOOP
        IF v_debt >= p_target THEN
            LEAVE mi_loop;    -- sale del bucle en este punto
        END IF;

        SET v_debt = v_debt * 1.05;
    END LOOP mi_loop;

    SELECT ROUND(v_debt, 2) AS deuda_final;
END //

DELIMITER ;

CALL calc_debt(1000.00, 2000.00);

-- Promoción mensual con CASE + función
-- Crea la función get_monthly_promo() que devuelva el porcentaje de descuento según el mes actual: diciembre (12) → 20.00, agosto (8) → 10.00, enero (1) → 5.00, cualquier otro mes → 0.00. Usa MONTH(NOW()) para obtener el mes. ¿Qué modificador necesita?

DELIMITER //

-- Usa NOW() → NOT DETERMINISTIC (el resultado cambia cada mes)
-- No accede a tablas → no necesita READS SQL DATA
CREATE FUNCTION get_monthly_promo()
RETURNS DECIMAL(5,2) NOT DETERMINISTIC
BEGIN
    -- CASE sobre la expresión MONTH(NOW())
    CASE MONTH(NOW())
        WHEN 12 THEN RETURN 20.00;
        WHEN 8  THEN RETURN 10.00;
        WHEN 1  THEN RETURN 5.00;
        ELSE         RETURN 0.00;
    END CASE;
END //

DELIMITER ;

-- Uso directo en SELECT:
SELECT title, rental_rate,
       rental_rate * (1 - get_monthly_promo()/100) AS precio_con_promo
FROM film LIMIT 5;


-- la estructura de un trigger
-- DELIMITER //

-- CREATE TRIGGER nombre_trigger
--    BEFORE | AFTER          -- ¿cuándo se ejecuta?
--    INSERT | UPDATE | DELETE  -- ¿qué evento lo dispara?
--    ON nombre_tabla         -- ¿en qué tabla?
--    FOR EACH ROW            -- siempre esta línea, es obligatoria
-- BEGIN
    -- tu código aquí
    -- tienes acceso a NEW y OLD
-- END //

-- DELIMITER ;


-- Auto-mayúsculas al insertar actor
-- Crea el trigger capitalizar_apellido que se ejecute antes de insertar en la tabla actor. Debe asegurarse de que el last_name se guarde siempre en mayúsculas, independientemente de cómo lo escriba el usuario.

DELIMITER //

CREATE TRIGGER capitalizar_apellido
    BEFORE INSERT ON actor
    FOR EACH ROW
BEGIN
    -- Modificamos NEW antes de que MySQL lo guarde
    SET NEW.last_name = UPPER(NEW.last_name);
END //

DELIMITER ;

-- Prueba:
INSERT INTO actor(first_name, last_name) VALUES ('Tom', 'hanks');
-- Se guarda como 'HANKS' aunque lo insertamos en minúsculas


-- Auditoría de pagos modificados
-- Crea el trigger audit_pay que guarde en la tabla audit_payments(payment_id, old_amt, new_amt) cualquier cambio en el campo amount de la tabla payment. Solo debe insertar un registro si el importe realmente cambió.

DELIMITER //

CREATE TRIGGER audit_pay
    AFTER UPDATE ON payment
    FOR EACH ROW
BEGIN
    -- Solo actuamos si el importe cambió realmente
    IF OLD.amount <> NEW.amount THEN
        INSERT INTO audit_payments(payment_id, old_amt, new_amt)
        VALUES (OLD.payment_id, OLD.amount, NEW.amount);
    END IF;
END //

DELIMITER ;


-- Protección de actores con SIGNAL
-- Crea el trigger protect_actors que impida borrar un actor si ha participado en más de 20 películas. Si se intenta borrar, debe lanzar un error con SIGNAL SQLSTATE '45000' y el mensaje 'Actor demasiado famoso para borrar'. Usa la tabla film_actor.

DELIMITER //

CREATE TRIGGER protect_actors
    BEFORE DELETE ON actor
    FOR EACH ROW
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count
    FROM film_actor
    WHERE actor_id = OLD.actor_id;

    IF v_count > 20 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Actor demasiado famoso para borrar';
    END IF;
END //

DELIMITER ;

-- Prueba:
DELETE FROM actor WHERE actor_id = 1;
-- ERROR: Actor demasiado famoso para borrar


-- Auto-mayúsculas al actualizar cliente
-- Crea el trigger cust_upper que asegure que el first_name de un cliente se guarde siempre en mayúsculas cuando se haga un UPDATE en la tabla customer.

DELIMITER //

CREATE TRIGGER cust_upper
    BEFORE UPDATE ON customer
    FOR EACH ROW
BEGIN
    SET NEW.first_name = UPPER(NEW.first_name);
END //

DELIMITER ;

-- Prueba:
UPDATE customer SET first_name = 'maria' WHERE customer_id = 1;
-- Se guarda como 'MARIA'


-- Histórico de emails de clientes
-- Crea el trigger email_hist que guarde el email anterior de un cliente en la tabla email_history(customer_id, old_email, fecha_cambio) justo antes de que sea modificado. Solo debe actuar si el email realmente cambia.

DELIMITER //

CREATE TRIGGER email_hist
    BEFORE UPDATE ON customer
    FOR EACH ROW
BEGIN
    -- Guardamos el historial SOLO si el email cambió
    IF OLD.email <> NEW.email THEN
        INSERT INTO email_history(customer_id, old_email, fecha_cambio)
        VALUES (OLD.customer_id, OLD.email, NOW());
        -- OLD.email = email que había ANTES del UPDATE
    END IF;
END //

DELIMITER ;

-- Prueba:
UPDATE customer SET email = 'nuevo@email.com' WHERE customer_id = 1;
-- Se guarda el email anterior en email_history


