-- =============================================================================
-- Script de Limpieza Total — Logística Global 4.0
-- Gabriel Alexandru Iacob — DAM Grado Superior
-- =============================================================================
-- ⚠ IMPORTANTE: Ejecutar sobre la BD recién cargada con 01_setup_logistica_masivo.sql
--   Si ves "Unknown column 'salario_base_sucio'" es porque el script ya se ejecutó
--   parcialmente antes. Recarga el setup y vuelve a ejecutar desde el principio.
-- =============================================================================
-- ORDEN DE EJECUCIÓN OBLIGATORIO:
--   1. Limpieza de texto (TRIM, UPPER, REPLACE)
--   2. Saneamiento de fechas (8 formatos, mismo patrón que GHA)
--   3. Saneamiento financiero (quitar €/$, CAST a DECIMAL)
--   4. Integridad referencial (huérfanos ANTES de añadir FK)
--   5. Blindaje final (FK, CHECK, UNIQUE, NOT NULL)
-- =============================================================================

USE logistica_global;


-- =============================================================================
-- BLOQUE 1: ALMACENES
-- Problemas: espacios en cod_almacen y nombre_sucursal, ciudades abreviadas,
-- tipo_gestion inconsistente, capacidad_m3 sucia, duplicado cod_almacen='ALM-001',
-- registros absurdos (Área 51, Narnia...).
-- =============================================================================

-- 1.1 Limpiar espacios y estandarizar texto
SET SQL_SAFE_UPDATES = 0;
UPDATE almacenes SET cod_almacen      = TRIM(cod_almacen);
UPDATE almacenes SET nombre_sucursal  = TRIM(nombre_sucursal);
UPDATE almacenes SET ciudad_ubicacion = TRIM(ciudad_ubicacion);

-- 1.2 Normalizar abreviaturas de ciudades
UPDATE almacenes SET ciudad_ubicacion = 'Barcelona' WHERE ciudad_ubicacion = 'Barna';
UPDATE almacenes SET ciudad_ubicacion = 'Valencia'  WHERE ciudad_ubicacion = 'VLC';

-- 1.3 Estandarizar tipo_gestion a mayúsculas (igual que estado en ERP)
UPDATE almacenes SET tipo_gestion = UPPER(TRIM(tipo_gestion));

-- 1.4 Limpiar capacidad_m3: quitar ' m3' y ' metros cúbicos', dejar solo número
UPDATE almacenes SET capacidad_m3 = REPLACE(capacidad_m3, ' metros cúbicos', '');
UPDATE almacenes SET capacidad_m3 = REPLACE(capacidad_m3, ' m3', '');
UPDATE almacenes SET capacidad_m3 = TRIM(capacidad_m3);

-- 1.5 Limpiar teléfono: quitar '+34 ' y espacios (mismo plan que GHA)
UPDATE almacenes SET tel_contacto = REPLACE(tel_contacto, '+34 ', '');
UPDATE almacenes SET tel_contacto = REPLACE(tel_contacto, ' ', '');
SET SQL_SAFE_UPDATES = 1;

-- 1.6 Eliminar duplicados de cod_almacen manteniendo el ID más bajo
-- (mismo patrón que deduplicación de clientes en ERP)
SELECT cod_almacen, COUNT(*) FROM almacenes GROUP BY cod_almacen HAVING COUNT(*) > 1;

START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
DELETE FROM almacenes
WHERE id NOT IN (
    SELECT id_min FROM (
        SELECT MIN(id) AS id_min FROM almacenes GROUP BY cod_almacen
    ) AS tmp
);
SET SQL_SAFE_UPDATES = 1;
SELECT cod_almacen, COUNT(*) FROM almacenes GROUP BY cod_almacen HAVING COUNT(*) > 1; -- 0 resultados
COMMIT;

-- 1.7 Eliminar registros absurdos/fantasma (ciudad NULL o claramente inventados)
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
DELETE FROM almacenes
WHERE ciudad_ubicacion IS NULL
   OR ciudad_ubicacion IN ('Nevada', 'Océano', 'Gotham', 'Planta 2', 'Narnia');
SET SQL_SAFE_UPDATES = 1;
COMMIT;

SELECT * FROM almacenes LIMIT 5;


-- =============================================================================
-- BLOQUE 2: EMPLEADOS
-- Problemas: nif_nie NULL (id % 100 = 0) y con espacios (' B '), doble @@
-- en email, f_alta con 8 formatos, salario_base_sucio con ' EUR',
-- activo_boolean inconsistente ('1' / 'NO'), almacen_id = 99999 (huérfano),
-- easter eggs (HAL 9000, Sauron...).
-- =============================================================================

-- 2.1 Limpiar NIF/NIE: quitar espacios
SET SQL_SAFE_UPDATES = 0;
UPDATE empleados SET nif_nie = TRIM(nif_nie);

-- 2.2 Corregir doble @@ en email (mismo patrón que doble @ en GHA)
UPDATE empleados SET email_corp = REPLACE(email_corp, '@@', '@')
    WHERE email_corp LIKE '%@@%';

-- 2.3 Normalizar activo_boolean: '1' → 'SI', todo lo demás → 'NO'
UPDATE empleados SET activo_boolean = 'SI'  WHERE activo_boolean = '1';
UPDATE empleados SET activo_boolean = 'NO'  WHERE activo_boolean != 'SI';
SET SQL_SAFE_UPDATES = 1;

-- 2.4 Limpiar salario: quitar ' EUR' → luego CHANGE COLUMN renombra y castea en un paso
-- (FIX: usamos CHANGE COLUMN en vez de MODIFY + RENAME por separado para evitar
--  el error 1054 si el script se ejecutó parcialmente antes)
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE empleados SET salario_base_sucio = REPLACE(salario_base_sucio, ' EUR', '');
UPDATE empleados SET salario_base_sucio = TRIM(salario_base_sucio);
-- Registros absurdos que no son números (gratis, almas...) → NULL
UPDATE empleados SET salario_base_sucio = NULL
    WHERE salario_base_sucio REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;
SELECT salario_base_sucio FROM empleados LIMIT 5;
COMMIT;

-- CHANGE COLUMN: renombra y cambia tipo en un solo ALTER (más seguro que MODIFY + RENAME)
ALTER TABLE empleados CHANGE COLUMN salario_base_sucio salario_base DECIMAL(10,2);

-- 2.5 Fechas de alta: 8 formatos. Usamos CASE + REGEXP (mismo patrón que GHA)
-- Los formatos yy/mm/dd y dd/mm/yy tienen el mismo REGEXP → usamos dd/mm/yy (más común).
-- Fechas absurdas ('Segunda Edad', 'Hace mucho tiempo', 'Jueves') → NULL.
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE empleados
SET f_alta = CASE
    WHEN f_alta REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(f_alta, '%d/%m/%Y') -- dd/mm/yyyy
    WHEN f_alta REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(f_alta, '%d-%m-%Y') -- dd-mm-yyyy
    WHEN f_alta REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_alta, '%Y-%m-%d') -- yyyy-mm-dd (ISO)
    WHEN f_alta REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_alta, '%Y/%m/%d') -- yyyy/mm/dd
    WHEN f_alta REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_alta, '%d/%m/%y') -- dd/mm/yy
    WHEN f_alta REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_alta, '%d-%m-%y') -- dd-mm-yy
    ELSE NULL -- fechas absurdas o inválidas
END
WHERE f_alta IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
SELECT f_alta FROM empleados LIMIT 5;
COMMIT;

ALTER TABLE empleados MODIFY COLUMN f_alta DATE;

-- 2.6 Empleados con nif_nie NULL → asignar valor especial para blindaje posterior
SET SQL_SAFE_UPDATES = 0;
UPDATE empleados SET nif_nie = CONCAT('DESCONOCIDO-', id) WHERE nif_nie IS NULL;
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM empleados LIMIT 5;


-- =============================================================================
-- BLOQUE 3: VEHÍCULOS
-- Problemas: matricula NULL (ids 10,50,100) y vacía (''),
-- año_fabricacion con 'Año ', capacidad_carga_kg con 'kg',
-- f_ultima_itv con 8 formatos, easter eggs (DeLorean, TARDIS...).
-- =============================================================================

-- 3.1 Matriculas NULL o vacías → asignar valor identificador
SET SQL_SAFE_UPDATES = 0;
UPDATE vehiculos SET matricula = CONCAT('SIN-MATRICULA-', id)
    WHERE matricula IS NULL OR TRIM(matricula) = '';

-- 3.2 Limpiar año_fabricacion: quitar 'Año '
UPDATE vehiculos SET año_fabricacion = REPLACE(año_fabricacion, 'Año ', '');
UPDATE vehiculos SET año_fabricacion = TRIM(año_fabricacion);
-- Años absurdos (no numéricos) → NULL
UPDATE vehiculos SET año_fabricacion = NULL
    WHERE año_fabricacion REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE vehiculos MODIFY COLUMN año_fabricacion YEAR;

-- 3.3 Limpiar capacidad_carga_kg: quitar 'kg'
SET SQL_SAFE_UPDATES = 0;
UPDATE vehiculos SET capacidad_carga_kg = REPLACE(capacidad_carga_kg, 'kg', '');
UPDATE vehiculos SET capacidad_carga_kg = TRIM(capacidad_carga_kg);
-- Valores absurdos → NULL
UPDATE vehiculos SET capacidad_carga_kg = NULL
    WHERE capacidad_carga_kg REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE vehiculos MODIFY COLUMN capacidad_carga_kg DECIMAL(10,2);

-- 3.4 Fechas ITV: mismo CASE de 8 formatos
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE vehiculos
SET f_ultima_itv = CASE
    WHEN f_ultima_itv REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(f_ultima_itv, '%d/%m/%Y')
    WHEN f_ultima_itv REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(f_ultima_itv, '%d-%m-%Y')
    WHEN f_ultima_itv REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_ultima_itv, '%Y-%m-%d')
    WHEN f_ultima_itv REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_ultima_itv, '%Y/%m/%d')
    WHEN f_ultima_itv REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_ultima_itv, '%d/%m/%y')
    WHEN f_ultima_itv REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_ultima_itv, '%d-%m-%y')
    ELSE NULL
END
WHERE f_ultima_itv IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE vehiculos MODIFY COLUMN f_ultima_itv DATE;

-- 3.5 Normalizar estado_vehiculo a mayúsculas
SET SQL_SAFE_UPDATES = 0;
UPDATE vehiculos SET estado_vehiculo = UPPER(TRIM(estado_vehiculo));
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM vehiculos LIMIT 5;


-- =============================================================================
-- BLOQUE 4: CLIENTES
-- Problemas: cif_nif con espacios/fantasma (' '), razon_social NULL (id=1),
-- limite_credito_sucio con €/USD, fecha_alta_cliente con 8 formatos,
-- activo inconsistente, easter eggs (Tony Stark, ACME Corp).
-- =============================================================================

-- 4.1 Limpiar cif_nif: quitar espacios
SET SQL_SAFE_UPDATES = 0;
UPDATE clientes SET cif_nif = TRIM(cif_nif);

-- 4.2 Eliminar clientes fantasma (cif_nif vacío o inválido)
DELETE FROM clientes WHERE TRIM(cif_nif) = '' OR cif_nif IS NULL;

-- 4.3 Limpiar razon_social NULL → valor identificador
UPDATE clientes SET razon_social = CONCAT('CLIENTE-SIN-NOMBRE-', id)
    WHERE razon_social IS NULL;

-- 4.4 Limpiar limite_credito: quitar €, $, USD, espacios → DECIMAL
UPDATE clientes SET limite_credito_sucio = REPLACE(limite_credito_sucio, '€',   '');
UPDATE clientes SET limite_credito_sucio = REPLACE(limite_credito_sucio, '$',   '');
UPDATE clientes SET limite_credito_sucio = REPLACE(limite_credito_sucio, ' USD','');
UPDATE clientes SET limite_credito_sucio = REPLACE(limite_credito_sucio, 'USD', '');
UPDATE clientes SET limite_credito_sucio = TRIM(limite_credito_sucio);
UPDATE clientes SET limite_credito_sucio = NULL
    WHERE limite_credito_sucio REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE clientes CHANGE COLUMN limite_credito_sucio limite_credito DECIMAL(10,2);

-- 4.5 Fechas de alta: mismo CASE de 8 formatos
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE clientes
SET fecha_alta_cliente = CASE
    WHEN fecha_alta_cliente REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(fecha_alta_cliente, '%d/%m/%Y')
    WHEN fecha_alta_cliente REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(fecha_alta_cliente, '%d-%m-%Y')
    WHEN fecha_alta_cliente REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(fecha_alta_cliente, '%Y-%m-%d')
    WHEN fecha_alta_cliente REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(fecha_alta_cliente, '%Y/%m/%d')
    WHEN fecha_alta_cliente REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(fecha_alta_cliente, '%d/%m/%y')
    WHEN fecha_alta_cliente REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(fecha_alta_cliente, '%d-%m-%y')
    ELSE NULL
END
WHERE fecha_alta_cliente IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE clientes MODIFY COLUMN fecha_alta_cliente DATE;

-- 4.6 Normalizar activo a mayúsculas
SET SQL_SAFE_UPDATES = 0;
UPDATE clientes SET activo = UPPER(TRIM(activo));
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM clientes LIMIT 5;


-- =============================================================================
-- BLOQUE 5: ENVÍOS
-- Problemas: tracking_number NULL (ids 1000-1010), cliente_id = -1 (huérfano),
-- vehiculo_id = 0 (huérfano), 3 columnas de fecha con 8 formatos,
-- importe_envio con € y $ (easter egg '0.05$' tiene $ al final),
-- peso_kg_bruto con 'kg', ruta_distancia_km con ' km'.
-- ADVERTENCIA: 100.000 registros. Un CASE por columna para rendimiento óptimo.
-- =============================================================================

-- 5.1 Asignar tracking_number a los que son NULL
SET SQL_SAFE_UPDATES = 0;
UPDATE envios SET tracking_number = CONCAT('TRK-RECUPERADO-', id)
    WHERE tracking_number IS NULL;
SET SQL_SAFE_UPDATES = 1;

-- 5.2 Limpiar importe_envio: quitar €, $ y USD
-- FIX: '0.05$' tiene el $ al final → hay que quitar $ además de €
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE envios SET importe_envio = REPLACE(importe_envio, '€',   '');
UPDATE envios SET importe_envio = REPLACE(importe_envio, '$',   '');
UPDATE envios SET importe_envio = REPLACE(importe_envio, 'USD', '');
UPDATE envios SET importe_envio = TRIM(importe_envio);
UPDATE envios SET importe_envio = REPLACE(importe_envio, ' ',   '');
-- Importes absurdos ('Alma', '1M', 'Un 10.0', texto) → NULL
UPDATE envios SET importe_envio = NULL
    WHERE importe_envio REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE envios MODIFY COLUMN importe_envio DECIMAL(10,2);

-- 5.3 Limpiar peso_kg_bruto: quitar 'kg'
SET SQL_SAFE_UPDATES = 0;
UPDATE envios SET peso_kg_bruto = REPLACE(peso_kg_bruto, 'kg', '');
UPDATE envios SET peso_kg_bruto = TRIM(peso_kg_bruto);
UPDATE envios SET peso_kg_bruto = NULL
    WHERE peso_kg_bruto REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE envios MODIFY COLUMN peso_kg_bruto DECIMAL(10,3);

-- 5.4 Limpiar ruta_distancia_km: quitar ' km'
SET SQL_SAFE_UPDATES = 0;
UPDATE envios SET ruta_distancia_km = REPLACE(ruta_distancia_km, ' km', '');
UPDATE envios SET ruta_distancia_km = TRIM(ruta_distancia_km);
UPDATE envios SET ruta_distancia_km = NULL
    WHERE ruta_distancia_km REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE envios MODIFY COLUMN ruta_distancia_km DECIMAL(10,2);

-- 5.5 Normalizar estado_envio a mayúsculas
SET SQL_SAFE_UPDATES = 0;
UPDATE envios SET estado_envio = UPPER(TRIM(estado_envio));
SET SQL_SAFE_UPDATES = 1;

-- 5.6 Convertir las 3 columnas de fecha. Un CASE por columna.
-- Las fechas absurdas ('3000 BC', 'Mañana', 'Examen', '1995') → NULL.
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;

-- f_salida
UPDATE envios
SET f_salida = CASE
    WHEN f_salida REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(f_salida, '%d/%m/%Y')
    WHEN f_salida REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(f_salida, '%d-%m-%Y')
    WHEN f_salida REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_salida, '%Y-%m-%d')
    WHEN f_salida REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_salida, '%Y/%m/%d')
    WHEN f_salida REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_salida, '%d/%m/%y')
    WHEN f_salida REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_salida, '%d-%m-%y')
    ELSE NULL
END
WHERE f_salida IS NOT NULL;

-- f_llegada_prevista
UPDATE envios
SET f_llegada_prevista = CASE
    WHEN f_llegada_prevista REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(f_llegada_prevista, '%d/%m/%Y')
    WHEN f_llegada_prevista REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(f_llegada_prevista, '%d-%m-%Y')
    WHEN f_llegada_prevista REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_llegada_prevista, '%Y-%m-%d')
    WHEN f_llegada_prevista REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_llegada_prevista, '%Y/%m/%d')
    WHEN f_llegada_prevista REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_llegada_prevista, '%d/%m/%y')
    WHEN f_llegada_prevista REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_llegada_prevista, '%d-%m-%y')
    ELSE NULL
END
WHERE f_llegada_prevista IS NOT NULL;

-- f_entrega_real
UPDATE envios
SET f_entrega_real = CASE
    WHEN f_entrega_real REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(f_entrega_real, '%d/%m/%Y')
    WHEN f_entrega_real REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(f_entrega_real, '%d-%m-%Y')
    WHEN f_entrega_real REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_entrega_real, '%Y-%m-%d')
    WHEN f_entrega_real REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_entrega_real, '%Y/%m/%d')
    WHEN f_entrega_real REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_entrega_real, '%d/%m/%y')
    WHEN f_entrega_real REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_entrega_real, '%d-%m-%y')
    ELSE NULL
END
WHERE f_entrega_real IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE envios MODIFY COLUMN f_salida DATE;
ALTER TABLE envios MODIFY COLUMN f_llegada_prevista DATE;
ALTER TABLE envios MODIFY COLUMN f_entrega_real DATE;

SELECT tracking_number, f_salida, f_llegada_prevista, f_entrega_real, importe_envio FROM envios LIMIT 5;


-- =============================================================================
-- BLOQUE 6: INCIDENCIAS
-- Problemas: envio_id = 888888 (huérfano para ids < 20), f_incidencia con 8
-- formatos, coste_asociado_sucio con 'pavos'/'piñas'/'-50€'/texto absurdo.
-- =============================================================================

-- 6.1 Ver incidencias huérfanas
SELECT * FROM incidencias WHERE envio_id NOT IN (SELECT id FROM envios);

-- Las incidencias con envio_id=888888 no tienen envío real → se eliminan.
-- (mismo criterio que GHA: se borran huérfanos antes de añadir FK)
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
DELETE FROM incidencias WHERE envio_id NOT IN (SELECT id FROM envios);
SET SQL_SAFE_UPDATES = 1;
SELECT * FROM incidencias WHERE envio_id NOT IN (SELECT id FROM envios); -- 0 resultados
COMMIT;

-- 6.2 Limpiar coste_asociado_sucio
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE incidencias SET coste_asociado_sucio = REPLACE(coste_asociado_sucio, '€', '');
UPDATE incidencias SET coste_asociado_sucio = TRIM(coste_asociado_sucio);
-- Valores texto no numéricos ('pavos', 'piñas', 'NULL', texto) → NULL
UPDATE incidencias SET coste_asociado_sucio = NULL
    WHERE coste_asociado_sucio REGEXP '[a-zA-Z]+' OR coste_asociado_sucio = 'NULL';
-- Negativos absurdos → NULL (una incidencia no puede costar negativo)
UPDATE incidencias SET coste_asociado_sucio = NULL
    WHERE coste_asociado_sucio LIKE '-%';
SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE incidencias CHANGE COLUMN coste_asociado_sucio coste_asociado DECIMAL(10,2);

-- 6.3 Fechas de incidencia: mismo CASE de 8 formatos
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE incidencias
SET f_incidencia = CASE
    WHEN f_incidencia REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(f_incidencia, '%d/%m/%Y')
    WHEN f_incidencia REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(f_incidencia, '%d-%m-%Y')
    WHEN f_incidencia REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_incidencia, '%Y-%m-%d')
    WHEN f_incidencia REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_incidencia, '%Y/%m/%d')
    WHEN f_incidencia REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_incidencia, '%d/%m/%y')
    WHEN f_incidencia REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_incidencia, '%d-%m-%y')
    ELSE NULL -- 'Ayer', 'Mañana', '0000-00-00' → NULL
END
WHERE f_incidencia IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE incidencias MODIFY COLUMN f_incidencia DATE;

SELECT * FROM incidencias LIMIT 5;


-- =============================================================================
-- BLOQUE 7: PROVEEDORES
-- Problemas: cif_prov con formato 'CIFi' (sin estructura), valoracion_estrellas
-- con ' *' ('4 *'), ultimo_pedido con 8 formatos.
-- =============================================================================

-- 7.1 Limpiar valoracion_estrellas: quitar ' *', dejar solo número
SET SQL_SAFE_UPDATES = 0;
UPDATE proveedores SET valoracion_estrellas = REPLACE(valoracion_estrellas, ' *', '');
UPDATE proveedores SET valoracion_estrellas = TRIM(valoracion_estrellas);
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE proveedores MODIFY COLUMN valoracion_estrellas TINYINT;

-- 7.2 Fechas ultimo_pedido: mismo CASE
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE proveedores
SET ultimo_pedido = CASE
    WHEN ultimo_pedido REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(ultimo_pedido, '%d/%m/%Y')
    WHEN ultimo_pedido REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(ultimo_pedido, '%d-%m-%Y')
    WHEN ultimo_pedido REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(ultimo_pedido, '%Y-%m-%d')
    WHEN ultimo_pedido REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(ultimo_pedido, '%Y/%m/%d')
    WHEN ultimo_pedido REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(ultimo_pedido, '%d/%m/%y')
    WHEN ultimo_pedido REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(ultimo_pedido, '%d-%m-%y')
    ELSE NULL
END
WHERE ultimo_pedido IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE proveedores MODIFY COLUMN ultimo_pedido DATE;

SELECT * FROM proveedores LIMIT 5;


-- =============================================================================
-- BLOQUE 8: MANTENIMIENTOS_FLOTA
-- Problemas: f_mantenimiento con 8 formatos, coste_reparacion con ' Euros'.
-- =============================================================================

-- 8.1 Limpiar coste_reparacion: quitar ' Euros'
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE mantenimientos_flota SET coste_reparacion = REPLACE(coste_reparacion, ' Euros', '');
UPDATE mantenimientos_flota SET coste_reparacion = TRIM(coste_reparacion);
UPDATE mantenimientos_flota SET coste_reparacion = NULL
    WHERE coste_reparacion REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE mantenimientos_flota MODIFY COLUMN coste_reparacion DECIMAL(10,2);

-- 8.2 Fechas de mantenimiento: mismo CASE
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE mantenimientos_flota
SET f_mantenimiento = CASE
    WHEN f_mantenimiento REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(f_mantenimiento, '%d/%m/%Y')
    WHEN f_mantenimiento REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN STR_TO_DATE(f_mantenimiento, '%d-%m-%Y')
    WHEN f_mantenimiento REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_mantenimiento, '%Y-%m-%d')
    WHEN f_mantenimiento REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_mantenimiento, '%Y/%m/%d')
    WHEN f_mantenimiento REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{2}$' THEN STR_TO_DATE(f_mantenimiento, '%d/%m/%y')
    WHEN f_mantenimiento REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(f_mantenimiento, '%d-%m-%y')
    ELSE NULL
END
WHERE f_mantenimiento IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
COMMIT;

ALTER TABLE mantenimientos_flota MODIFY COLUMN f_mantenimiento DATE;

SELECT * FROM mantenimientos_flota LIMIT 5;


-- =============================================================================
-- BLOQUE 9: INTEGRIDAD REFERENCIAL — HUÉRFANOS
-- CRÍTICO: hay que limpiar los huérfanos ANTES de añadir las FK.
-- Si no, MySQL lanza Error 1452 (mismo problema que en GHA con paciente_id=4).
-- =============================================================================

-- 9.1 Ver todos los huérfanos
SELECT 'empleados.almacen_id' AS tabla, COUNT(*) AS huerfanos
    FROM empleados WHERE almacen_id IS NOT NULL AND almacen_id NOT IN (SELECT id FROM almacenes);
SELECT 'envios.cliente_id' AS tabla, COUNT(*) AS huerfanos
    FROM envios WHERE cliente_id NOT IN (SELECT id FROM clientes);
SELECT 'envios.vehiculo_id' AS tabla, COUNT(*) AS huerfanos
    FROM envios WHERE vehiculo_id NOT IN (SELECT id FROM vehiculos);
SELECT 'incidencias.envio_id' AS tabla, COUNT(*) AS huerfanos
    FROM incidencias WHERE envio_id NOT IN (SELECT id FROM envios);
SELECT 'mantenimientos.vehiculo_id' AS tabla, COUNT(*) AS huerfanos
    FROM mantenimientos_flota WHERE vehiculo_id NOT IN (SELECT id FROM vehiculos);

-- 9.2 Empleados con almacen_id inexistente → NULL
SET SQL_SAFE_UPDATES = 0;
UPDATE empleados SET almacen_id = NULL
    WHERE almacen_id IS NOT NULL AND almacen_id NOT IN (SELECT id FROM almacenes);

-- 9.3 Envíos con cliente_id = -1 → cliente ficticio
INSERT INTO clientes (id, cif_nif, razon_social, tipo_cliente)
    VALUES (99999, 'FICTICIO-99999', 'Cliente Ficticio', 'FICTICIO');
UPDATE envios SET cliente_id = 99999
    WHERE cliente_id NOT IN (SELECT id FROM clientes);

-- 9.4 Envíos con vehiculo_id = 0 → vehículo ficticio
INSERT INTO vehiculos (id, matricula, marca_modelo, estado_vehiculo)
    VALUES (99999, 'SIN-VEHICULO-99999', 'Vehículo Ficticio', 'FICTICIO');
UPDATE envios SET vehiculo_id = 99999
    WHERE vehiculo_id NOT IN (SELECT id FROM vehiculos);

-- 9.5 Mantenimientos con vehiculo_id inexistente → reasignar al ficticio
UPDATE mantenimientos_flota SET vehiculo_id = 99999
    WHERE vehiculo_id NOT IN (SELECT id FROM vehiculos);
SET SQL_SAFE_UPDATES = 1;

-- 9.6 Verificación: todos deben dar 0
SELECT COUNT(*) AS emp_huerfanos FROM empleados WHERE almacen_id IS NOT NULL AND almacen_id NOT IN (SELECT id FROM almacenes);
SELECT COUNT(*) AS env_cli       FROM envios WHERE cliente_id NOT IN (SELECT id FROM clientes);
SELECT COUNT(*) AS env_veh       FROM envios WHERE vehiculo_id NOT IN (SELECT id FROM vehiculos);
SELECT COUNT(*) AS mant_veh      FROM mantenimientos_flota WHERE vehiculo_id NOT IN (SELECT id FROM vehiculos);


-- =============================================================================
-- BLOQUE 10: BLINDAJE FINAL — FK, CHECK, UNIQUE, NOT NULL
-- Solo se añaden una vez que los datos son consistentes (bloque 9 hecho).
-- =============================================================================

-- 10.1 FOREIGN KEYS
ALTER TABLE empleados
    ADD CONSTRAINT fk_empleados_almacenes
    FOREIGN KEY (almacen_id) REFERENCES almacenes(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE envios
    ADD CONSTRAINT fk_envios_clientes
    FOREIGN KEY (cliente_id) REFERENCES clientes(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE envios
    ADD CONSTRAINT fk_envios_vehiculos
    FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- empleado_id en envios puede ser NULL (no siempre asignado)
ALTER TABLE envios
    ADD CONSTRAINT fk_envios_empleados
    FOREIGN KEY (empleado_id) REFERENCES empleados(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE incidencias
    ADD CONSTRAINT fk_incidencias_envios
    FOREIGN KEY (envio_id) REFERENCES envios(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- responsable_id en incidencias puede ser NULL
ALTER TABLE incidencias
    ADD CONSTRAINT fk_incidencias_responsable
    FOREIGN KEY (responsable_id) REFERENCES empleados(id)
    ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE mantenimientos_flota
    ADD CONSTRAINT fk_mantenimientos_vehiculos
    FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- 10.2 UNIQUE: campos que no pueden repetirse
ALTER TABLE envios    ADD CONSTRAINT uq_tracking_number UNIQUE (tracking_number);
ALTER TABLE almacenes ADD CONSTRAINT uq_cod_almacen     UNIQUE (cod_almacen);
ALTER TABLE empleados ADD CONSTRAINT uq_nif_empleado    UNIQUE (nif_nie);
ALTER TABLE vehiculos ADD CONSTRAINT uq_matricula       UNIQUE (matricula);

-- 10.3 NOT NULL: campos que no pueden quedar vacíos
ALTER TABLE envios    MODIFY COLUMN tracking_number VARCHAR(100) NOT NULL;
ALTER TABLE envios    MODIFY COLUMN cliente_id      INT          NOT NULL;
ALTER TABLE envios    MODIFY COLUMN vehiculo_id     INT          NOT NULL;
ALTER TABLE clientes  MODIFY COLUMN cif_nif         VARCHAR(50)  NOT NULL;
ALTER TABLE clientes  MODIFY COLUMN razon_social    VARCHAR(200) NOT NULL;
ALTER TABLE empleados MODIFY COLUMN nif_nie         VARCHAR(50)  NOT NULL;

-- 10.4 CHECK: rangos y formatos válidos
ALTER TABLE empleados ADD CONSTRAINT chk_salario_positivo
    CHECK (salario_base IS NULL OR salario_base >= 0);

ALTER TABLE proveedores ADD CONSTRAINT chk_valoracion_rango
    CHECK (valoracion_estrellas IS NULL OR (valoracion_estrellas BETWEEN 1 AND 5));

ALTER TABLE envios ADD CONSTRAINT chk_peso_positivo
    CHECK (peso_kg_bruto IS NULL OR peso_kg_bruto > 0);

ALTER TABLE envios ADD CONSTRAINT chk_importe_positivo
    CHECK (importe_envio IS NULL OR importe_envio >= 0);

ALTER TABLE incidencias ADD CONSTRAINT chk_coste_positivo
    CHECK (coste_asociado IS NULL OR coste_asociado >= 0);

-- 10.5 ÍNDICES para SARGability (consultas rápidas sin funciones en el WHERE)
-- ❌ NO SARGable: WHERE YEAR(f_salida) = 2025  → full table scan en 100k filas
-- ✅ SARGable:    WHERE f_salida >= '2025-01-01' AND f_salida < '2026-01-01'
CREATE INDEX idx_envios_f_salida         ON envios (f_salida);
CREATE INDEX idx_envios_cliente          ON envios (cliente_id);
CREATE INDEX idx_envios_vehiculo         ON envios (vehiculo_id);
CREATE INDEX idx_incidencias_envio       ON incidencias (envio_id);
CREATE INDEX idx_empleados_almacen       ON empleados (almacen_id);
CREATE INDEX idx_mantenimientos_vehiculo ON mantenimientos_flota (vehiculo_id);


-- =============================================================================
-- VERIFICACIÓN FINAL
-- =============================================================================
SELECT 'almacenes'           AS tabla, COUNT(*) AS registros FROM almacenes
UNION ALL
SELECT 'empleados',            COUNT(*) FROM empleados
UNION ALL
SELECT 'vehiculos',            COUNT(*) FROM vehiculos
UNION ALL
SELECT 'clientes',             COUNT(*) FROM clientes
UNION ALL
SELECT 'envios',               COUNT(*) FROM envios
UNION ALL
SELECT 'incidencias',          COUNT(*) FROM incidencias
UNION ALL
SELECT 'proveedores',          COUNT(*) FROM proveedores
UNION ALL
SELECT 'mantenimientos_flota', COUNT(*) FROM mantenimientos_flota;

-- Consulta SARGable de ejemplo: envíos de marzo 2025
SELECT tracking_number, f_salida, importe_envio
FROM envios
WHERE f_salida >= '2025-03-01' AND f_salida < '2025-04-01'
LIMIT 10;