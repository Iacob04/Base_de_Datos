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

UPDATE medicos
SET num_colegiado = CONCAT('COL-', LEFT(num_colegiado, 2), '-', RIGHT(num_colegiado, 4))
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
’Medicina General’.
• Añade las FOREIGN KEY correspondientes en medicos y visitas.*/

select *from especialidades;


