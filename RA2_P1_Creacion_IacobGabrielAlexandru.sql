drop database if exists gestion_universitaria;
create database gestion_universitaria;

use gestion_universitaria;

drop table if exists imparten;
drop table if exists asignaturas;
drop table if exists grados;
drop table if exists profesores;
drop table if exists facultades;

CREATE TABLE facultades (
    id_facultad INT UNSIGNED AUTO_INCREMENT,
    codigo VARCHAR(4) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    id_decano INT UNSIGNED,
    CONSTRAINT pk_facultad PRIMARY KEY (id_facultad),
    CONSTRAINT uk_codigo UNIQUE (codigo),
    CONSTRAINT uk_nombre_facultad UNIQUE (nombre),
    CONSTRAINT chk_codigo_longitud CHECK (CHAR_LENGTH(codigo) = 4)
);

CREATE TABLE profesores (
    id_profesor INT UNSIGNED AUTO_INCREMENT,
    nif VARCHAR(9) NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    salario DECIMAL(10,2) DEFAULT 2000.00,
    id_facultad INT UNSIGNED NOT NULL,
    CONSTRAINT pk_profesor PRIMARY KEY (id_profesor),
    CONSTRAINT uk_nif UNIQUE (nif),
    CONSTRAINT fk_profesor_facultad FOREIGN KEY (id_facultad)
        REFERENCES facultades (id_facultad)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_nif CHECK (CHAR_LENGTH(nif) = 9),
    CONSTRAINT chk_salario CHECK (salario > 0)
);

CREATE TABLE grados (
    id_grado INT UNSIGNED AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    id_facultad INT UNSIGNED NOT NULL,
    CONSTRAINT pk_grado PRIMARY KEY (id_grado),
    CONSTRAINT uk_nombre_grado UNIQUE (nombre),
    CONSTRAINT fk_grado_facultad FOREIGN KEY (id_facultad)
        REFERENCES facultades (id_facultad)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE asignaturas (
    id_asignatura INT UNSIGNED AUTO_INCREMENT,
    codigo_asig VARCHAR(10) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    creditos INT UNSIGNED DEFAULT 6,
    CONSTRAINT pk_asignatura PRIMARY KEY (id_asignatura),
    CONSTRAINT uk_codigo_asig UNIQUE (codigo_asig),
    CONSTRAINT chk_creditos CHECK (creditos >= 3)
);

CREATE TABLE imparten (
    id_profesor INT UNSIGNED NOT NULL,
    id_asignatura INT UNSIGNED NOT NULL,
    tipo_grupo ENUM('TEORIA', 'PRACTICA') DEFAULT 'TEORIA',
    CONSTRAINT pk_imparten PRIMARY KEY (id_profesor, id_asignatura),
    CONSTRAINT fk_imparten_profesor FOREIGN KEY (id_profesor)
        REFERENCES profesores (id_profesor)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_imparten_asignatura FOREIGN KEY (id_asignatura)
        REFERENCES asignaturas (id_asignatura)
        ON DELETE CASCADE ON UPDATE CASCADE
);

ALTER TABLE facultades
    ADD CONSTRAINT fk_facultad_decano FOREIGN KEY (id_decano)
        REFERENCES profesores (id_profesor)
        ON DELETE RESTRICT ON UPDATE CASCADE;

drop view if exists v_cuadro_docente;
create view v_cuadro_docente AS
SELECT
    profesores.nombre_completo AS profesor,
    profesores.nif AS nif_profesor,
    asignaturas.nombre AS asignatura,
    imparten.tipo_grupo AS modalidad,
    facultades.nombre AS facultad_origen
FROM
    profesores
    JOIN facultades ON profesores.id_facultad = facultades.id_facultad
    JOIN imparten ON imparten.id_profesor = profesores.id_profesor
    JOIN asignaturas ON asignaturas.id_asignatura = imparten.id_asignatura;

drop view if exists v_resumen_facultades;
create view v_resumen_facultades AS
SELECT
    facultades.nombre AS facultad,
    facultades.codigo AS codigo_facultad,
    count(profesores.id_profesor) AS num_profesores,
    sum(profesores.salario) AS masa_salarial,
    avg(profesores.salario) AS salario_medio
FROM
    facultades
    LEFT JOIN profesores ON profesores.id_facultad = facultades.id_facultad
GROUP BY facultades.id_facultad , facultades.nombre , facultades.codigo;


-- Las Create Vew he seguido los pasos que me han ido indicando mis compañeros junto con la ayuda de la ia , espero que esté bien :)