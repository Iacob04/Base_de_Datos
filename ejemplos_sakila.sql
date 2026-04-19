-- ============================================================
--  GUÍA PROGRAMACIÓN BASES DE DATOS - Sakila
--  Ejemplos: Procedimientos | Funciones | Control de Flujo
-- ============================================================

USE sakila;

-- ============================================================
-- BLOQUE 1: PROCEDIMIENTOS ALMACENADOS
-- ============================================================

-- 1.1 Sin parámetros — El "Hola Mundo"
DELIMITER //
CREATE PROCEDURE saludo()
BEGIN
    SELECT '¡Hola clase de DAM!' AS mensaje;
END //
DELIMITER ;

CALL saludo();


-- 1.2 Con parámetro IN — Buscar actor por apellido
DELIMITER //
CREATE PROCEDURE buscar_actor(IN p_apellido VARCHAR(45))
BEGIN
    SELECT first_name, last_name
    FROM actor
    WHERE last_name LIKE CONCAT(p_apellido, '%');
END //
DELIMITER ;

CALL buscar_actor('Jackman');


-- 1.3 Con parámetros IN y OUT — Estadísticas de un actor
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

CALL get_actor_stats(1, @total_peliculas, @duracion_media);
SELECT @total_peliculas AS peliculas, @duracion_media AS duracion_media;


-- ============================================================
-- BLOQUE 2: FUNCIONES DE USUARIO
-- ============================================================

-- 2.1 Operación matemática — Calcular precio con IVA
DELIMITER //
CREATE FUNCTION calcular_iva(p_precio DECIMAL(10,2))
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
    RETURN p_precio * 1.21;
END //
DELIMITER ;

SELECT calcular_iva(10.00) AS precio_con_iva;


-- 2.2 Formateo de texto — Nombre completo (Apellido, Nombre)
DELIMITER //
CREATE FUNCTION nombre_completo(
    p_nombre   VARCHAR(45),
    p_apellido VARCHAR(45)
)
RETURNS VARCHAR(100) DETERMINISTIC
BEGIN
    RETURN CONCAT(p_apellido, ', ', p_nombre);
END //
DELIMITER ;

SELECT nombre_completo('John', 'Doe') AS nombre_formateado;


-- 2.3 Consulta a BBDD — Días que duró un alquiler
DELIMITER //
CREATE FUNCTION dias_alquiler(p_rental_id INT)
RETURNS INT READS SQL DATA
BEGIN
    DECLARE v_dias INT;
    SELECT DATEDIFF(return_date, rental_date)
    INTO   v_dias
    FROM   rental
    WHERE  rental_id = p_rental_id;
    RETURN v_dias;
END //
DELIMITER ;

SELECT dias_alquiler(1) AS dias_alquiler;


-- ============================================================
-- BLOQUE 3: ESTRUCTURAS DE CONTROL
-- ============================================================

-- 3.1 IF simple — Clasificar mayoría de edad (dentro de un procedimiento)
DELIMITER //
CREATE PROCEDURE clasificar_edad(IN p_edad INT, OUT p_mensaje VARCHAR(50))
BEGIN
    IF p_edad >= 18 THEN
        SET p_mensaje = 'Mayor de edad';
    ELSE
        SET p_mensaje = 'Menor de edad';
    END IF;
END //
DELIMITER ;

CALL clasificar_edad(20, @msg);
SELECT @msg AS resultado;


-- 3.2 CASE — Nombre de categoría según ID
DELIMITER //
CREATE PROCEDURE nombre_categoria(
    IN  p_categoria_id INT,
    OUT p_nombre_cat   VARCHAR(50)
)
BEGIN
    CASE p_categoria_id
        WHEN 1 THEN SET p_nombre_cat = 'Acción';
        WHEN 2 THEN SET p_nombre_cat = 'Animación';
        WHEN 3 THEN SET p_nombre_cat = 'Comedia';
        ELSE        SET p_nombre_cat = 'Otros';
    END CASE;
END //
DELIMITER ;

CALL nombre_categoria(2, @cat);
SELECT @cat AS categoria;


-- 3.3 WHILE — Insertar N filas de prueba en tabla auxiliar
-- (Asegúrate de tener la tabla creada antes de llamar al procedimiento)
-- CREATE TABLE IF NOT EXISTS tabla_log (id INT AUTO_INCREMENT PRIMARY KEY, msg VARCHAR(50));

DELIMITER //
CREATE PROCEDURE generar_log(IN p_filas INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= p_filas DO
        INSERT INTO tabla_log(msg) VALUES (CONCAT('Paso ', i));
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- CALL generar_log(5);
-- SELECT * FROM tabla_log;
