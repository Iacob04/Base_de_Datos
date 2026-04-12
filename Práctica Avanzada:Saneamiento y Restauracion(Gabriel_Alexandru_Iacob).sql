use gha_analytics;
select *from pacientes;

/*1. Normalización de Identidad (Pacientes):
• Elimina duplicados exactos en pacientes (mismo NIF y nombre), manteniendo el
ID más bajo.
• Asegura que el NIF no tenga espacios y cumpla el formato de 8 números y una
letra (Regex). Los que no cumplan, deben ser corregidos o eliminados.
• Convierte la columna nif en UNIQUE y NOT NULL.*/

start transaction;
set sql_safe_updates = 0;
DELETE FROM pacientes
WHERE id NOT IN (
    SELECT id_min FROM (
        SELECT MIN(id) AS id_min
        FROM pacientes
        GROUP BY nif
    ) AS tmp
);
set sql_safe_updates = 1;
commit;

start transaction;
set sql_safe_updates = 0;
UPDATE pacientes 
SET 
    nif = TRIM(nif);
UPDATE pacientes SET nif = REPLACE(nif, '-', '');
SELECT 
    *FROM pacientes;
SET SQL_SAFE_UPDATES = 1;
commit;

start transaction;
set sql_safe_updates = 0;
DELETE FROM pacientes 
WHERE
    nif NOT REGEXP '^[0-9]{8}[A-Za-z]$';
SELECT 
    *
FROM
    pacientes;
    set sql_safe_updates = 1;
commit;

start transaction;
set sql_safe_updates = 0;
ALTER TABLE pacientes
MODIFY nif VARCHAR(9) NOT NULL,
ADD CONSTRAINT uq_nif UNIQUE (nif);
set sql_safe_updates = 1;
commit;



/*2. Consistencia de Colegiados (Médicos):
• Los números de colegiado deben tener el formato COL-XX-YYYY (donde XX es la
provincia y YYYY el número). Estandariza los existentes.
• Aplica una restricción CHECK para validar este formato.*/


select *from medicos;

start transaction;
set sql_safe_updates = 0;
UPDATE medicos SET num_colegiado = REPLACE(num_colegiado,'/','-');
UPDATE medicos SET num_colegiado = 'COL-99-0999' WHERE num_colegiado = 'INV-999';
UPDATE medicos
SET num_colegiado = CONCAT('COL-', LEFT(REPLACE(num_colegiado, 'COL', ''), 2), '-', RIGHT(num_colegiado, 4))
WHERE num_colegiado NOT REGEXP '^COL-[0-9]{2}-[0-9]{4}$';

delete from medicos
where num_colegiado NOT REGEXP '^COL-[0-9]{2}-[0-9]{4}$';
set sql_safe_updates = 1;
commit;
select *from medicos;

start transaction;
set sql_safe_updates = 0;
ALTER TABLE medicos
ADD CONSTRAINT chk_num_colegiado 
CHECK (num_colegiado REGEXP '^COL-[0-9]{2}-[0-9]{4}$');
set sql_safe_updates = 1;
commit;




/*3. Integridad Referencial:
• Los médicos con especialidades inexistentes deben asignarse a la especialidad
'Medicina General'.
• Añade las FOREIGN KEY correspondientes en medicos y visitas.*/

START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE medicos
    SET especialidad_id = (SELECT id FROM especialidades WHERE nombre = 'Medicina General')
    WHERE especialidad_id NOT IN (SELECT id FROM especialidades);
SET SQL_SAFE_UPDATES = 1;
SELECT * FROM medicos WHERE especialidad_id NOT IN (SELECT id FROM especialidades); -- 0 resultados
COMMIT;

select *from visitas;

-- Limpiar visitas huérfanas ANTES de añadir las FK (evita Error 1452)
SET SQL_SAFE_UPDATES = 0;
DELETE FROM visitas WHERE paciente_id NOT IN (SELECT id FROM pacientes);
DELETE FROM visitas WHERE medico_id   NOT IN (SELECT id FROM medicos);
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM visitas WHERE paciente_id NOT IN (SELECT id FROM pacientes); -- 0
SELECT * FROM visitas WHERE medico_id   NOT IN (SELECT id FROM medicos);   -- 0

ALTER TABLE medicos
    ADD CONSTRAINT fk_medicos_especialidades
    FOREIGN KEY (especialidad_id) REFERENCES especialidades(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
 
ALTER TABLE visitas
    ADD CONSTRAINT fk_visitas_pacientes
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE visitas
    ADD CONSTRAINT fk_visitas_medicos
    FOREIGN KEY (medico_id) REFERENCES medicos(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
 

/*4. Normalización y División de Tablas:
• Extrae la información de seguros de la tabla pacientes a una nueva tabla
independiente llamada seguros_pacientes.
• La nueva tabla debe contener el paciente_id, el num_poliza y una nueva columna
estado_poliza con el valor por defecto 'ACTIVA'.
• Asegura la integridad referencial entre ambas tablas.*/
start transaction;
CREATE TABLE seguros_pacientes (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    paciente_id   INT         NOT NULL,
    num_poliza    VARCHAR(50) NOT NULL,
    estado_poliza VARCHAR(20) DEFAULT 'ACTIVA',
    CONSTRAINT fk_seguros_paciente
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

INSERT INTO seguros_pacientes (paciente_id, num_poliza)
    SELECT id, num_poliza FROM pacientes WHERE num_poliza IS NOT NULL;
    
    SELECT importe_sucio FROM visitas;
    ALTER TABLE pacientes DROP COLUMN num_poliza;
   commit;
   
   
 /*5. Columnas Calculadas y Blindaje:
• Añade a la tabla visitas una columna llamada copago_estimado de tipo DECIMAL(10,2).
• El valor de esta columna debe calcularse como el 20% del importe (tras haber
saneado la columna importe_sucio).
• Blindaje Final: Una vez saneados los datos, establece como obligatorios (NOT
NULL) los campos num_poliza (en su nueva tabla) y copago_estimado. Ningún
registro debe quedar sin estos valores.*/

START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE visitas SET importe_sucio = REPLACE(importe_sucio, '€',   '');
UPDATE visitas SET importe_sucio = REPLACE(importe_sucio, '$',   '');
UPDATE visitas SET importe_sucio = REPLACE(importe_sucio, 'EUR', '');
UPDATE visitas SET importe_sucio = TRIM(importe_sucio);
UPDATE visitas SET importe_sucio = REPLACE(importe_sucio, ' ',   '');
UPDATE visitas SET importe_sucio = REPLACE(importe_sucio, ',',   '.');
UPDATE visitas SET importe_sucio = '0.00' WHERE importe_sucio REGEXP '[a-zA-Z]+';
SET SQL_SAFE_UPDATES = 1;
SELECT importe_sucio FROM visitas;
COMMIT;


--  Cast a DECIMAL y renombrar
ALTER TABLE visitas MODIFY COLUMN importe_sucio DECIMAL(10,2);
ALTER TABLE visitas RENAME COLUMN importe_sucio TO importe;
 
--  Calcular copago (20%)
ALTER TABLE visitas ADD COLUMN copago_estimado DECIMAL(10,2);
 
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE visitas SET copago_estimado = ROUND(importe * 0.20, 2);
SET SQL_SAFE_UPDATES = 1;
COMMIT;
 
-- Blindaje NOT NULL
ALTER TABLE visitas MODIFY COLUMN copago_estimado DECIMAL(10,2) NOT NULL;
 
SELECT * FROM visitas;

/*6. Ingesta de Datos Externos:
• Los registros contenidos en la tabla de staging raw_import_visitas deben ser
procesados e importados a sus tablas correspondientes (pacientes y visitas).
• Debes desglosar el campo raw_data, limpiar los formatos y asegurar que no se
creen duplicados si el paciente ya existe.*/

SELECT * FROM raw_import_visitas;
 
-- Insertar pacientes nuevos (no existentes por NIF)
START TRANSACTION;
SET sql_safe_updates = 0;
INSERT INTO pacientes (nif, nombre_completo)
SELECT DISTINCT
    UPPER(TRIM(SUBSTRING_INDEX(raw_data, '|', 1))),
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data, '|', 2), '|', -1))
FROM raw_import_visitas
WHERE UPPER(TRIM(SUBSTRING_INDEX(raw_data, '|', 1)))
      NOT IN (SELECT nif FROM pacientes);
SET sql_safe_updates = 1;
COMMIT;
 
SELECT * FROM pacientes;
 
-- Insertar visitas relacionando NIF → paciente_id
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
 
INSERT INTO visitas (paciente_id, medico_id, fecha_visita, importe, copago_estimado)
SELECT
    p.id,
    1,
    CASE
        WHEN TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1)) LIKE '%/%/____'
            THEN STR_TO_DATE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1)), '%d/%m/%Y')
        WHEN TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1)) LIKE '____-__-__'
            THEN STR_TO_DATE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1)), '%Y-%m-%d')
        WHEN TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1)) LIKE '__-__-____'
            THEN STR_TO_DATE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1)), '%d-%m-%Y')
        WHEN TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1)) LIKE '____.%.%'
            THEN STR_TO_DATE(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1)), '%Y.%m.%d')
        ELSE TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(raw_data,'|',3),'|',-1))
    END,
    CAST(
        CASE
            WHEN TRIM(SUBSTRING_INDEX(raw_data,'|',-1)) REGEXP '[a-zA-Z]+'
                THEN '0.00'
            ELSE REPLACE(REPLACE(REPLACE(
                    TRIM(SUBSTRING_INDEX(raw_data,'|',-1))
                 ,'$',''),'EUR',''),',','.')
        END
    AS DECIMAL(10,2)),
    ROUND(CAST(
        CASE
            WHEN TRIM(SUBSTRING_INDEX(raw_data,'|',-1)) REGEXP '[a-zA-Z]+'
                THEN '0.00'
            ELSE REPLACE(REPLACE(REPLACE(
                    TRIM(SUBSTRING_INDEX(raw_data,'|',-1))
                 ,'$',''),'EUR',''),',','.')
        END
    AS DECIMAL(10,2)) * 0.20, 2)
FROM raw_import_visitas r
    JOIN pacientes p ON p.nif = UPPER(TRIM(SUBSTRING_INDEX(r.raw_data, '|', 1)));
 
SET SQL_SAFE_UPDATES = 1;
SELECT * FROM visitas;
COMMIT;

/**/

-- 2.1 EMAILS
SET SQL_SAFE_UPDATES = 0;
UPDATE pacientes SET email = REPLACE(email, 'gmail,con', 'gmail.com') WHERE email LIKE '%gmail,con';
UPDATE pacientes SET email = REPLACE(email, '.con', '.com') WHERE email LIKE '%.con';
UPDATE pacientes SET email = NULL WHERE email REGEXP '.*@.*@.*';
SET SQL_SAFE_UPDATES = 1;
SELECT id, email FROM pacientes;

-- 2.2 TELÉFONOS
SET SQL_SAFE_UPDATES = 0;
UPDATE pacientes SET tel_contacto = REPLACE(tel_contacto, ' ', '');
UPDATE pacientes SET tel_contacto = REPLACE(tel_contacto, '-', '');
UPDATE pacientes SET tel_contacto = REPLACE(tel_contacto, '+34', '');
UPDATE pacientes SET tel_contacto = SUBSTRING(tel_contacto, 5, 9) WHERE tel_contacto LIKE '0034%';
SET SQL_SAFE_UPDATES = 1;
SELECT id, tel_contacto FROM pacientes;

-- 2.3 f_nacimiento VARCHAR → DATE
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE pacientes
SET f_nacimiento = CASE
    WHEN f_nacimiento LIKE '%/%/____'   THEN STR_TO_DATE(f_nacimiento, '%d/%m/%Y')
    WHEN f_nacimiento LIKE '____.%.%'   THEN STR_TO_DATE(f_nacimiento, '%Y.%m.%d')
    WHEN f_nacimiento LIKE '%-%-____'   THEN STR_TO_DATE(f_nacimiento, '%d-%m-%Y')
    WHEN f_nacimiento LIKE '____-__-__' THEN STR_TO_DATE(f_nacimiento, '%Y-%m-%d')
    ELSE f_nacimiento
END
WHERE f_nacimiento IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
COMMIT;
ALTER TABLE pacientes MODIFY COLUMN f_nacimiento DATE;
SELECT id, f_nacimiento FROM pacientes;

-- 2.4 fecha_visita VARCHAR → DATETIME
START TRANSACTION;
SET SQL_SAFE_UPDATES = 0;
UPDATE visitas
SET fecha_visita = CASE
    WHEN fecha_visita REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$'
        THEN STR_TO_DATE(fecha_visita, '%d/%m/%Y %H:%i')
    WHEN fecha_visita REGEXP '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2} [0-9]{2}:[0-9]{2}$'
        THEN STR_TO_DATE(fecha_visita, '%Y.%m.%d %H:%i')
    WHEN fecha_visita REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4} [0-9]{2}:[0-9]{2}$'
        THEN STR_TO_DATE(fecha_visita, '%d-%m-%Y %H:%i')
    WHEN fecha_visita REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
        THEN STR_TO_DATE(fecha_visita, '%d/%m/%Y')
    WHEN fecha_visita REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(fecha_visita, '%Y-%m-%d')
    WHEN fecha_visita REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
        THEN STR_TO_DATE(fecha_visita, '%d-%m-%Y')
    WHEN fecha_visita REGEXP '^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$'
        THEN STR_TO_DATE(fecha_visita, '%Y.%m.%d')
    ELSE fecha_visita
END
WHERE fecha_visita IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;
COMMIT;
ALTER TABLE visitas CHANGE fecha_visita fecha_visita DATETIME;
SELECT id, fecha_visita FROM visitas;

-- 2.5 descuento_aplicado VARCHAR → DECIMAL
ALTER TABLE visitas MODIFY COLUMN descuento_aplicado DECIMAL(10,2);
SELECT id, descuento_aplicado FROM visitas;

-- 2.6 COALESCE: informe de facturación
SELECT
    p.id AS paciente_id,
    p.nif,
    p.nombre_completo,
    COALESCE(p.email, 'Sin email registrado') AS email,
    COALESCE(p.tel_contacto, 'Sin teléfono') AS telefono,
    v.fecha_visita,
    v.importe,
    COALESCE(v.descuento_aplicado, 0.00) AS descuento,
    v.importe - COALESCE(v.descuento_aplicado, 0.00) AS importe_neto,
    v.copago_estimado,
    COALESCE(s.num_poliza, 'Sin póliza') AS poliza,
    COALESCE(s.estado_poliza, 'INACTIVA') AS estado_poliza
FROM visitas v
    JOIN pacientes p ON v.paciente_id = p.id
    LEFT JOIN seguros_pacientes s ON p.id = s.paciente_id
ORDER BY p.nombre_completo, v.fecha_visita;

-- 2.7 ÍNDICES (SARGability)
CREATE INDEX idx_visitas_fecha        ON visitas (fecha_visita);
CREATE INDEX idx_visitas_paciente     ON visitas (paciente_id);
CREATE INDEX idx_visitas_medico       ON visitas (medico_id);
CREATE INDEX idx_medicos_especialidad ON medicos (especialidad_id);

-- Consulta SARGable usando el índice de fecha (evita funciones en el WHERE)
SELECT * FROM visitas
WHERE fecha_visita >= '2026-03-01' AND fecha_visita < '2026-04-01';