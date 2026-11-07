-- =====================================================================
-- Usuarios de prueba (contraseña: iweb)
--   Administrador:           carlosrp@oceanlink.pe
--   Capacity Planner:        luciatl@oceanlink.pe
--   Network Operator:        diegoqj@oceanlink.pe
--   Maintenance Coordinator: miguelcg@oceanlink.pe
--   Supervisor:              greciage@oceanlink.pe
-- =====================================================================

-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema MiBaseDeDatos
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `mibasededatos` ;
CREATE SCHEMA IF NOT EXISTS `mibasededatos` DEFAULT CHARACTER SET utf8 ;
USE `mibasededatos` ;

-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`ROL`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mibasededatos`.`ROL` (
  `id_rol` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id_rol`),
  UNIQUE INDEX `nombre_UNIQUE` (`nombre` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`USUARIO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mibasededatos`.`USUARIO` (
  `dni_usuario` INT NOT NULL,
  `nombre` VARCHAR(50) NOT NULL,
  `apellido_1` VARCHAR(50) NOT NULL,
  `apellido_2` VARCHAR(45) NOT NULL,
  `correo` VARCHAR(100) NOT NULL,
  `password` VARCHAR(225) NOT NULL,
  `estado` VARCHAR(20) NOT NULL,
  `ROL_id_rol` INT NOT NULL,
  `foto` MEDIUMBLOB NULL,
  `foto_tipo` VARCHAR(50) NULL,
  PRIMARY KEY (`dni_usuario`),
  UNIQUE INDEX `correo_UNIQUE` (`correo` ASC) VISIBLE,
  INDEX `fk_USUARIO_ROL1_idx` (`ROL_id_rol` ASC) VISIBLE,
  CONSTRAINT `fk_USUARIO_ROL1`
    FOREIGN KEY (`ROL_id_rol`)
    REFERENCES `mibasededatos`.`ROL` (`id_rol`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`CLIENTE`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mibasededatos`.`CLIENTE` (
  `id_cliente` INT NOT NULL AUTO_INCREMENT,
  `razon_social` VARCHAR(100) NOT NULL,
  `ruc` VARCHAR(20) NOT NULL,
  `correo` VARCHAR(100) NOT NULL,
  `telefono` VARCHAR(20) NULL,
  PRIMARY KEY (`id_cliente`),
  UNIQUE INDEX `ruc_UNIQUE` (`ruc` ASC) VISIBLE,
  UNIQUE INDEX `correo_UNIQUE` (`correo` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`ACTIVIDAD_MANTENIMIENTO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mibasededatos`.`ACTIVIDAD_MANTENIMIENTO` (
  `id_actividad` INT NOT NULL AUTO_INCREMENT,
  `descripcion` TEXT NOT NULL,
  `fecha` DATE NOT NULL,
  `hora` TIME NOT NULL,
  `tiempo_invertido` TIME NOT NULL,
  `titulo` TEXT NOT NULL,
  `MANTENIMIENTO_codigo_mantenimiento` VARCHAR(10) NULL,
  PRIMARY KEY (`id_actividad`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`FINALIZACION_MANTENIMIENTO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mibasededatos`.`FINALIZACION_MANTENIMIENTO` (
  `id_finalizacion` INT NOT NULL AUTO_INCREMENT,
  `resultado` VARCHAR(50) NOT NULL,
  `resumen_final` TEXT NOT NULL,
  `observacion` TEXT NULL,
  `fecha_fin` DATETIME NOT NULL,
  `estado_servicios` VARCHAR(30) NOT NULL,
  PRIMARY KEY (`id_finalizacion`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`HIST_MANTENIMIENTO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mibasededatos`.`HIST_MANTENIMIENTO` (
  `id_historial` INT NOT NULL AUTO_INCREMENT,
  `estado` VARCHAR(30) NOT NULL,
  `fecha` DATETIME NOT NULL,
  `MANTENIMIENTO_codigo_mantenimiento` VARCHAR(10) NULL,
  `observacion` VARCHAR(500) NULL,
  `USUARIO_dni_usuario` INT NULL,
  PRIMARY KEY (`id_historial`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`MANTENIMIENTO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mibasededatos`.`MANTENIMIENTO` (
  `codigo_mantenimiento` VARCHAR(10) NOT NULL,
  `tipo` VARCHAR(30) NOT NULL,
  `estado` VARCHAR(30) NOT NULL,
  `fecha_programada` DATE NOT NULL,
  `hora_inicio` TIME NULL,
  `duracion_estimada` TIME NOT NULL,
  `ACTIVIDAD_MANTENIMIENTO_id_actividad` INT NULL,
  `FINALIZACION_MANTENIMIENTO_id_finalizacion` INT NULL,
  `HIST_MANTENIMIENTO_id_historial` INT NULL,
  PRIMARY KEY (`codigo_mantenimiento`),
  INDEX `fk_MANTENIMIENTO_ACTIVIDAD_MANTENIMIENTO1_idx` (`ACTIVIDAD_MANTENIMIENTO_id_actividad` ASC) VISIBLE,
  INDEX `fk_MANTENIMIENTO_FINALIZACION_MANTENIMIENTO1_idx` (`FINALIZACION_MANTENIMIENTO_id_finalizacion` ASC) VISIBLE,
  INDEX `fk_MANTENIMIENTO_HIST_MANTENIMIENTO1_idx` (`HIST_MANTENIMIENTO_id_historial` ASC) VISIBLE,
  CONSTRAINT `fk_MANTENIMIENTO_ACTIVIDAD_MANTENIMIENTO1`
    FOREIGN KEY (`ACTIVIDAD_MANTENIMIENTO_id_actividad`)
    REFERENCES `mibasededatos`.`ACTIVIDAD_MANTENIMIENTO` (`id_actividad`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_MANTENIMIENTO_FINALIZACION_MANTENIMIENTO1`
    FOREIGN KEY (`FINALIZACION_MANTENIMIENTO_id_finalizacion`)
    REFERENCES `mibasededatos`.`FINALIZACION_MANTENIMIENTO` (`id_finalizacion`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_MANTENIMIENTO_HIST_MANTENIMIENTO1`
    FOREIGN KEY (`HIST_MANTENIMIENTO_id_historial`)
    REFERENCES `mibasededatos`.`HIST_MANTENIMIENTO` (`id_historial`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`LANDING_STATION`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`LANDING_STATION` (
  `id_landing` VARCHAR(10) NOT NULL,
  `nombre` VARCHAR(20) NOT NULL,
  `ciudad` VARCHAR(50) NOT NULL,
  `pais` VARCHAR(50) NOT NULL,
  `estado` VARCHAR(20) NOT NULL,
  `MANTENIMIENTO_id_mantenimiento1` VARCHAR(10) NULL,
  PRIMARY KEY (`id_landing`),
  INDEX `fk_LANDING_STATION_MANTENIMIENTO2_idx` (`MANTENIMIENTO_id_mantenimiento1` ASC) VISIBLE,
  CONSTRAINT `fk_LANDING_STATION_MANTENIMIENTO2`
    FOREIGN KEY (`MANTENIMIENTO_id_mantenimiento1`)
    REFERENCES `mibasededatos`.`MANTENIMIENTO` (`codigo_mantenimiento`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`UTILIZACION_HIST`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`UTILIZACION_HIST` (
  `id_registro` INT NOT NULL AUTO_INCREMENT,
  `fecha` DATE NOT NULL,
  `capacidad_utilizada` DECIMAL(10,2) NOT NULL,
  `capacidad_disponible` DECIMAL(10,2) NOT NULL,
  `capacidad_total` DECIMAL(10,2) NOT NULL,
  `SEGMENTO_codigo_segmento` VARCHAR(12) NULL,
  PRIMARY KEY (`id_registro`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`SEGMENTO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`SEGMENTO` (
  `codigo_segmento` VARCHAR(12) NOT NULL,
  `capacidad_total` DECIMAL(10,2) NOT NULL,
  `capacidad_utilizada` DECIMAL(10,2) NOT NULL,
  `capacidad_reservada` DECIMAL(10,2) NOT NULL,
  `estado` VARCHAR(20) NOT NULL,
  `UTILIZACION_HIST_id_registro` INT NULL,
  `LANDING_STATION_id_origen` VARCHAR(10) NOT NULL,
  `LANDING_STATION_id_destino` VARCHAR(10) NOT NULL,
  `MANTENIMIENTO_id_mantenimiento` VARCHAR(10) NULL,
  PRIMARY KEY (`codigo_segmento`),
  INDEX `fk_SEGMENTO_UTILIZACION_HIST1_idx` (`UTILIZACION_HIST_id_registro` ASC) VISIBLE,
  INDEX `fk_SEGMENTO_LANDING_STATION1_idx` (`LANDING_STATION_id_origen` ASC) VISIBLE,
  INDEX `fk_SEGMENTO_LANDING_STATION2_idx` (`LANDING_STATION_id_destino` ASC) VISIBLE,
  INDEX `fk_SEGMENTO_MANTENIMIENTO1_idx` (`MANTENIMIENTO_id_mantenimiento` ASC) VISIBLE,
  CONSTRAINT `fk_SEGMENTO_UTILIZACION_HIST1`
    FOREIGN KEY (`UTILIZACION_HIST_id_registro`)
    REFERENCES `MiBaseDeDatos`.`UTILIZACION_HIST` (`id_registro`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SEGMENTO_LANDING_STATION1`
    FOREIGN KEY (`LANDING_STATION_id_origen`)
    REFERENCES `MiBaseDeDatos`.`LANDING_STATION` (`id_landing`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SEGMENTO_LANDING_STATION2`
    FOREIGN KEY (`LANDING_STATION_id_destino`)
    REFERENCES `MiBaseDeDatos`.`LANDING_STATION` (`id_landing`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SEGMENTO_MANTENIMIENTO1`
    FOREIGN KEY (`MANTENIMIENTO_id_mantenimiento`)
    REFERENCES `MiBaseDeDatos`.`MANTENIMIENTO` (`codigo_mantenimiento`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`HIST_SOLICITUD`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`HIST_SOLICITUD` (
  `id_historial` INT NOT NULL AUTO_INCREMENT,
  `estado` VARCHAR(30) NOT NULL,
  `fecha` DATETIME NOT NULL,
  `SOLICITUD_id_solicitud` INT NULL,
  `observacion` VARCHAR(500) NULL,
  `USUARIO_dni_usuario` INT NULL,
  PRIMARY KEY (`id_historial`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`SOLICITUD_CAPACIDAD`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`SOLICITUD_CAPACIDAD` (
  `id_solicitud` INT NOT NULL AUTO_INCREMENT,
  `id_ruta_propuesta` INT NULL,
  `capacidad_requerida` DECIMAL(10,2) NOT NULL,
  `estado` VARCHAR(50) NOT NULL,
  `fecha_solicitud` DATE NOT NULL,
  `HIST_SOLICITUD_id_historial` INT NOT NULL,
  `USUARIO_id_usuario` INT NOT NULL,
  `fecha_requerida` DATE NOT NULL,
  `observaciones` VARCHAR(255) NULL,
  `CLIENTE_id_cliente` INT NOT NULL,
  `LANDING_STATION_id_origen` VARCHAR(10) NOT NULL,
  `LANDING_STATION_id_destino` VARCHAR(10) NOT NULL,
  PRIMARY KEY (`id_solicitud`),
  INDEX `fk_SOLICITUD_CAPACIDAD_HIST_SOLICITUD1_idx` (`HIST_SOLICITUD_id_historial` ASC) VISIBLE,
  INDEX `fk_SOLICITUD_CAPACIDAD_USUARIO1_idx` (`USUARIO_id_usuario` ASC) VISIBLE,
  INDEX `fk_SOLICITUD_CLIENTE_idx` (`CLIENTE_id_cliente` ASC) VISIBLE,
  INDEX `fk_SOLICITUD_ORIGEN_idx` (`LANDING_STATION_id_origen` ASC) VISIBLE,
  INDEX `fk_SOLICITUD_DESTINO_idx` (`LANDING_STATION_id_destino` ASC) VISIBLE,
  INDEX `fk_SOLICITUD_RUTA_idx` (`id_ruta_propuesta` ASC) VISIBLE,
  CONSTRAINT `fk_SOLICITUD_CAPACIDAD_HIST_SOLICITUD1`
    FOREIGN KEY (`HIST_SOLICITUD_id_historial`)
    REFERENCES `MiBaseDeDatos`.`HIST_SOLICITUD` (`id_historial`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SOLICITUD_CAPACIDAD_USUARIO1`
    FOREIGN KEY (`USUARIO_id_usuario`)
    REFERENCES `MiBaseDeDatos`.`USUARIO` (`dni_usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SOLICITUD_CLIENTE`
    FOREIGN KEY (`CLIENTE_id_cliente`)
    REFERENCES `MiBaseDeDatos`.`CLIENTE` (`id_cliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SOLICITUD_ORIGEN`
    FOREIGN KEY (`LANDING_STATION_id_origen`)
    REFERENCES `MiBaseDeDatos`.`LANDING_STATION` (`id_landing`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SOLICITUD_DESTINO`
    FOREIGN KEY (`LANDING_STATION_id_destino`)
    REFERENCES `MiBaseDeDatos`.`LANDING_STATION` (`id_landing`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SOLICITUD_RUTA`
    FOREIGN KEY (`id_ruta_propuesta`)
    REFERENCES `MiBaseDeDatos`.`RUTA` (`id_ruta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`RUTA`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`RUTA` (
  `id_ruta` INT NOT NULL AUTO_INCREMENT,
  `codigo` VARCHAR(20) NOT NULL,
  `estado` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`id_ruta`),
  UNIQUE INDEX `codigo_UNIQUE` (`codigo` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`SERVICIO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`SERVICIO` (
  `id_servicio` INT NOT NULL AUTO_INCREMENT,
  `capacidad_contratada` DECIMAL(10,2) NOT NULL,
  `estado` VARCHAR(20) NOT NULL,
  `RUTA_id_ruta` INT NOT NULL,
  `CLIENTE_id_cliente` INT NOT NULL,
  `fecha_activacion` DATE NOT NULL,
  `SOLICITUD_id_solicitud` INT NULL,
  PRIMARY KEY (`id_servicio`),
  INDEX `fk_SERVICIO_RUTA1_idx` (`RUTA_id_ruta` ASC) VISIBLE,
  INDEX `fk_SERVICIO_CLIENTE1_idx` (`CLIENTE_id_cliente` ASC) VISIBLE,
  INDEX `fk_SERVICIO_SOLICITUD_idx` (`SOLICITUD_id_solicitud` ASC) VISIBLE,
  CONSTRAINT `fk_SERVICIO_RUTA1`
    FOREIGN KEY (`RUTA_id_ruta`)
    REFERENCES `MiBaseDeDatos`.`RUTA` (`id_ruta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SERVICIO_CLIENTE1`
    FOREIGN KEY (`CLIENTE_id_cliente`)
    REFERENCES `MiBaseDeDatos`.`CLIENTE` (`id_cliente`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_SERVICIO_SOLICITUD`
    FOREIGN KEY (`SOLICITUD_id_solicitud`)
    REFERENCES `MiBaseDeDatos`.`SOLICITUD_CAPACIDAD` (`id_solicitud`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`HIST_INCIDENCIA`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`HIST_INCIDENCIA` (
  `id_historial` INT NOT NULL AUTO_INCREMENT,
  `estado` VARCHAR(30) NOT NULL,
  `fecha` DATETIME NOT NULL,
  `INCIDENCIA_codigo_incidencia` VARCHAR(10) NULL,
  `observacion` VARCHAR(500) NULL,
  `USUARIO_dni_usuario` INT NULL,
  PRIMARY KEY (`id_historial`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`INCIDENCIA`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`INCIDENCIA` (
  `codigo_incidencia` VARCHAR(10) NOT NULL,
  `descripcion` TEXT NOT NULL,
  `severidad` VARCHAR(20) NOT NULL,
  `estado` VARCHAR(50) NOT NULL,
  `fecha_deteccion` DATETIME NOT NULL,
  `titulo` TEXT NOT NULL,
  `SEGMENTO_codigo_segmento` VARCHAR(12) NOT NULL,
  `LANDING_STATION_id_landing` VARCHAR(10) NOT NULL,
  `hora` TIME NOT NULL,
  `HIST_INCIDENCIA_id_historial` INT NOT NULL,
  PRIMARY KEY (`codigo_incidencia`),
  INDEX `fk_INCIDENCIA_SEGMENTO1_idx` (`SEGMENTO_codigo_segmento` ASC) VISIBLE,
  INDEX `fk_INCIDENCIA_LANDING_STATION1_idx` (`LANDING_STATION_id_landing` ASC) VISIBLE,
  INDEX `fk_INCIDENCIA_HIST_INCIDENCIA1_idx` (`HIST_INCIDENCIA_id_historial` ASC) VISIBLE,
  CONSTRAINT `fk_INCIDENCIA_SEGMENTO1`
    FOREIGN KEY (`SEGMENTO_codigo_segmento`)
    REFERENCES `MiBaseDeDatos`.`SEGMENTO` (`codigo_segmento`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_INCIDENCIA_LANDING_STATION1`
    FOREIGN KEY (`LANDING_STATION_id_landing`)
    REFERENCES `MiBaseDeDatos`.`LANDING_STATION` (`id_landing`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_INCIDENCIA_HIST_INCIDENCIA1`
    FOREIGN KEY (`HIST_INCIDENCIA_id_historial`)
    REFERENCES `MiBaseDeDatos`.`HIST_INCIDENCIA` (`id_historial`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`RUTA_has_SEGMENTO`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`RUTA_has_SEGMENTO` (
  `RUTA_id_ruta` INT NOT NULL,
  `SEGMENTO_codigo_segmento` VARCHAR(12) NOT NULL,
  `orden` INT NOT NULL,
  PRIMARY KEY (`RUTA_id_ruta`, `SEGMENTO_codigo_segmento`),
  INDEX `fk_RUTA_has_SEGMENTO_SEGMENTO1_idx` (`SEGMENTO_codigo_segmento` ASC) VISIBLE,
  INDEX `fk_RUTA_has_SEGMENTO_RUTA1_idx` (`RUTA_id_ruta` ASC) VISIBLE,
  CONSTRAINT `fk_RUTA_has_SEGMENTO_RUTA1`
    FOREIGN KEY (`RUTA_id_ruta`)
    REFERENCES `MiBaseDeDatos`.`RUTA` (`id_ruta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_RUTA_has_SEGMENTO_SEGMENTO1`
    FOREIGN KEY (`SEGMENTO_codigo_segmento`)
    REFERENCES `MiBaseDeDatos`.`SEGMENTO` (`codigo_segmento`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`INCIDENCIA_SEGMENTO`
-- RF17: una incidencia puede afectar a uno o varios segmentos
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`INCIDENCIA_SEGMENTO` (
  `codigo_incidencia` VARCHAR(10) NOT NULL,
  `codigo_segmento` VARCHAR(12) NOT NULL,
  PRIMARY KEY (`codigo_incidencia`, `codigo_segmento`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `MiBaseDeDatos`.`RESERVA_CAPACIDAD`
-- RF10: cuánto reservó cada solicitud en cada segmento de su ruta
-- estado: Reservada / Utilizada / Liberada
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `MiBaseDeDatos`.`RESERVA_CAPACIDAD` (
  `id_reserva` INT NOT NULL AUTO_INCREMENT,
  `SOLICITUD_id_solicitud` INT NOT NULL,
  `SEGMENTO_codigo_segmento` VARCHAR(12) NOT NULL,
  `capacidad` DECIMAL(10,2) NOT NULL,
  `fecha` DATETIME NOT NULL,
  `estado` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`id_reserva`),
  INDEX `fk_RESERVA_SOLICITUD_idx` (`SOLICITUD_id_solicitud` ASC) VISIBLE,
  INDEX `fk_RESERVA_SEGMENTO_idx` (`SEGMENTO_codigo_segmento` ASC) VISIBLE,
  CONSTRAINT `fk_RESERVA_SOLICITUD`
    FOREIGN KEY (`SOLICITUD_id_solicitud`)
    REFERENCES `MiBaseDeDatos`.`SOLICITUD_CAPACIDAD` (`id_solicitud`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_RESERVA_SEGMENTO`
    FOREIGN KEY (`SEGMENTO_codigo_segmento`)
    REFERENCES `MiBaseDeDatos`.`SEGMENTO` (`codigo_segmento`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;


-- =====================================================================
-- =====================================================================
-- DATOS (baseDeDatos.sql)
-- =====================================================================
-- =====================================================================

USE mibasededatos;

SELECT DATABASE();
-- =====================================================================
-- 1. ROL
-- =====================================================================

INSERT INTO ROL (id_rol, nombre)
VALUES
(1, 'Administrador'),
(2, 'Capacity Planner'),
(3, 'Network Operator'),
(4, 'Maintenance Coordinator'),
(5, 'Supervisor')
ON DUPLICATE KEY UPDATE
nombre = VALUES(nombre);

-- =====================================================================
-- 2. USUARIO
-- Contraseña inicial: iweb
-- =====================================================================

INSERT INTO `USUARIO`
(
    dni_usuario,
    nombre,
    apellido_1,
    apellido_2,
    correo,
    password,
    estado,
    ROL_id_rol
)
VALUES

    (10056428, 'Carlos', 'Ramírez', 'Puertas',
     'carlosrp@oceanlink.pe',
     'iweb',
     'Activo',
     1),

    (6951827, 'Lucía', 'Torres', 'Linares',
     'luciatl@oceanlink.pe',
     'iweb',
     'Activo',
     2),

    (7549017, 'Andrés', 'Paredes', 'Quiroz',
     'andrespq@oceanlink.pe',
     'iweb',
     'Activo',
     2),

    (35021881, 'Diego', 'Quispe', 'Jimenez',
     'diegoqj@oceanlink.pe',
     'iweb',
     'Activo',
     3),

    (20354448, 'Valeria', 'Rojas', 'Chavez',
     'valeriarc@oceanlink.pe',
     'iweb',
     'Activo',
     3),

    (5403188, 'Miguel', 'Castillo', 'Garcia',
     'miguelcg@oceanlink.pe',
     'iweb',
     'Activo',
     4),

    (7780183, 'Grecia', 'Gutiérrez', 'Espinioza',
     'greciage@oceanlink.pe',
     'iweb',
     'Activo',
     5),

    (40218192, 'Jorge', 'Huamán', 'Cáceres',
     'jorgehc@oceanlink.pe',
     'iweb',
     'Inactivo',
     3),

    (41726391, 'Fernando', 'Salazar', 'Mendoza',
     'fernandosm@oceanlink.pe',
     'iweb',
     'Activo',
     1),

    (72841563, 'Mariana', 'Vega', 'Castro',
     'marianavc@oceanlink.pe',
     'iweb',
     'Activo',
     2),

    (46382915, 'Renato', 'Mendoza', 'Flores',
     'renatomf@oceanlink.pe',
     'iweb',
     'Activo',
     2),

    (61837425, 'Paola', 'Navarro', 'Salinas',
     'paolans@oceanlink.pe',
     'iweb',
     'Activo',
     3),

    (38271645, 'Rodrigo', 'Vargas', 'Ponce',
     'rodrigovp@oceanlink.pe',
     'iweb',
     'Activo',
     4),

    (59182736, 'Daniela', 'Morales', 'Ríos',
     'danielamr@oceanlink.pe',
     'iweb',
     'Activo',
     5);

-- =====================================================================
-- 3. CLIENTE
-- =====================================================================

INSERT INTO `CLIENTE`
(
    id_cliente,
    razon_social,
    ruc,
    correo,
    telefono
)
VALUES

(1, 'Andina Telecom S.A.C.', '20512345671',
 'contacto@andinatel.pe', '014567890'),

(2, 'Pacífico Datos S.A.', '20623456782',
 'ventas@pacificodatos.pe', '016789012'),

(3, 'Nube Sur Perú S.A.C.', '20734567893',
 'noc@nubesur.pe', '012345678'),

(4, 'Conecta Rural E.I.R.L.', '20845678904',
 'admin@conectarural.pe', '064123456'),

(5, 'Banco Unión del Perú S.A.', '20956789015',
 'ti@bancounion.pe', '017778888'),

(6, 'Minera Costa Norte S.A.', '20167890126',
 'sistemas@costanorte.pe', '073456789'),

(7, 'Red Académica Andina', '20278901237',
 'soporte@redacademica.pe', '016543210'),

(8, 'StreamLatam S.A.C.', '20389012348',
 'infra@streamlatam.com', '017001122'),

(9, 'Telecomunicaciones del Pacífico S.A.C.', '20411223349',
 'contacto@telepacifico.pe', '015551122'),

(10, 'DataNet Andina S.A.', '20522334450',
 'soporte@datanetandina.pe', '016662233'),

(11, 'Financiera Horizonte S.A.C.', '20633445561',
 'infraestructura@finhorizonte.pe', '017773344'),

(12, 'Universidad Tecnológica del Sur', '20744556672',
 'redes@utelsur.edu.pe', '016884455'),

(13, 'Servicios Mineros del Norte S.A.C.', '20855667783',
 'ti@servminorte.pe', '074556677'),

(14, 'Cloud Andean Networks S.A.C.', '20966778894',
 'noc@cloudandean.pe', '015667788'),

(15, 'Medios Digitales del Pacífico S.A.C.', '20177889905',
 'infra@mediospacifico.pe', '017889900');


-- =====================================================================
-- 4. ACTIVIDAD_MANTENIMIENTO
-- =====================================================================

INSERT INTO `ACTIVIDAD_MANTENIMIENTO`
(
    id_actividad,
    titulo,
    descripcion,
    fecha,
    hora,
    tiempo_invertido
)
VALUES
(1, 'Medición OTDR desde Lurín',
 'Medición OTDR desde Lurín',
 '2026-04-18', '01:00:00', '02:30:00'),

(2, 'Verificación de amplificadores',
 'Verificación de amplificadores y alarmas',
 '2026-04-18', '03:30:00', '02:00:00'),

(3, 'Desmontaje de fuente dañada',
 'Desmontaje de la fuente de poder dañada',
 '2026-05-03', '08:00:00', '01:30:00'),

(4, 'Instalación de nueva fuente',
 'Instalación y prueba de la nueva fuente',
 '2026-05-03', '09:30:00', '03:00:00'),

(5, 'Localización del punto de corte',
 'Localización del punto de corte con OTDR',
 '2026-06-12', '06:00:00', '06:00:00'),

(6, 'Empalme submarino',
 'Recuperación del cable y empalme submarino',
 '2026-06-13', '07:00:00', '30:00:00'),

(7, 'Pruebas de transmisión',
 'Pruebas de transmisión y puesta en servicio',
 '2026-06-14', '13:00:00', '05:00:00'),

(8, 'Respaldo de configuración',
 'Respaldo de configuración de equipos',
 '2026-09-28', '00:00:00', '02:00:00'),

(9, 'Actualización de firmware',
 'Actualización de firmware en terminales SLTE',
 '2026-09-28', '02:00:00', '06:00:00');
 



-- =====================================================================
-- 5. FINALIZACION_MANTENIMIENTO
-- =====================================================================

INSERT INTO `FINALIZACION_MANTENIMIENTO`
(
    id_finalizacion,
    resultado,
    resumen_final,
    observacion,
    fecha_fin,
    estado_servicios
)
VALUES
(1, 'Exitoso',
 'Parámetros ópticos dentro de rango',
 NULL,
 '2026-04-18 06:30:00',
 'Restablecido'),

(2, 'Exitoso',
 'Fuente reemplazada, segmento restablecido',
 'Se dejó una fuente de repuesto en sitio',
 '2026-05-03 13:00:00',
 'Restablecido'),

(3, 'Parcial',
 'Fibra empalmada, atenuación ligeramente elevada',
 'Programar nueva medición en 30 días',
 '2026-06-14 18:00:00',
 'Operativo con degradación');
 


-- =====================================================================
-- 6. HIST_MANTENIMIENTO
-- =====================================================================

INSERT INTO `HIST_MANTENIMIENTO`
(
    id_historial,
    estado,
    fecha
)
VALUES
(1, 'Programado', '2026-04-11 01:00:00'),
(2, 'En ejecución', '2026-04-18 01:00:00'),
(3, 'Finalizado', '2026-04-18 06:30:00'),

(4, 'Programado', '2026-04-26 08:00:00'),
(5, 'En ejecución', '2026-05-03 08:00:00'),
(6, 'Finalizado', '2026-05-03 13:00:00'),

(7, 'Programado', '2026-06-05 06:00:00'),
(8, 'En ejecución', '2026-06-12 06:00:00'),
(9, 'Finalizado', '2026-06-14 18:00:00'),

(10, 'Programado', '2026-08-03 09:00:00'),
(11, 'Cancelado', '2026-08-08 09:00:00'),

(12, 'Programado', '2026-09-21 00:00:00'),
(13, 'En ejecución', '2026-09-28 00:00:00'),

(14, 'Programado', '2026-09-26 06:00:00'),
(15, 'Programado', '2026-10-08 02:00:00'),

(16, 'Programado', '2026-10-20 02:00:00'),
(17, 'Programado', '2026-10-25 02:00:00');


-- =====================================================================
-- 7. MANTENIMIENTO
-- =====================================================================


INSERT INTO `MANTENIMIENTO`
(
    codigo_mantenimiento,
    tipo,
    estado,
    fecha_programada,
    hora_inicio,
    duracion_estimada,
    ACTIVIDAD_MANTENIMIENTO_id_actividad,
    FINALIZACION_MANTENIMIENTO_id_finalizacion,
    HIST_MANTENIMIENTO_id_historial
)
VALUES
(
    'MNT-001',
    'Preventivo',
    'Finalizado',
    '2026-04-18',
    '01:00:00',
    '06:00:00',
    1,
    1,
    3
),

(
    'MNT-002',
    'Correctivo',
    'Finalizado',
    '2026-05-03',
    '08:00:00',
    '05:00:00',
    3,
    2,
    6
),

(
    'MNT-003',
    'Correctivo',
    'Finalizado',
    '2026-06-12',
    '06:00:00',
    '48:00:00',
    5,
    3,
    9
),

(
    'MNT-004',
    'Preventivo',
    'Cancelado',
    '2026-08-10',
    '09:00:00',
    '04:00:00',
    2,
    NULL,
    11
),

(
    'MNT-005',
    'Preventivo',
    'En ejecución',
    '2026-09-28',
    '00:00:00',
    '72:00:00',
    8,
    NULL,
    13
),

(
    'MNT-006',
    'Correctivo',
    'Programado',
    '2026-10-03',
    '06:00:00',
    '96:00:00',
    4,
    NULL,
    14
),

(
    'MNT-007',
    'Preventivo',
    'Programado',
    '2026-10-15',
    '02:00:00',
    '08:00:00',
    7,
    NULL,
    15
),

(
    'MNT-008',
    'Preventivo',
    'Programado',
    '2026-10-20',
    '02:00:00',
    '06:00:00',
    9,
    NULL,
    16
),

(
    'MNT-009',
    'Preventivo',
    'Programado',
    '2026-10-25',
    '02:00:00',
    '06:00:00',
    6,
    NULL,
    17
);



-- Actividades y cambios de estado de cada mantenimiento (Maintenance Coordinator)
UPDATE ACTIVIDAD_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-001' WHERE id_actividad BETWEEN 1 AND 2;
UPDATE ACTIVIDAD_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-002' WHERE id_actividad BETWEEN 3 AND 4;
UPDATE ACTIVIDAD_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-003' WHERE id_actividad BETWEEN 5 AND 7;
UPDATE ACTIVIDAD_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-005' WHERE id_actividad BETWEEN 8 AND 9;

UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-001' WHERE id_historial BETWEEN 1 AND 3;
UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-002' WHERE id_historial BETWEEN 4 AND 6;
UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-003' WHERE id_historial BETWEEN 7 AND 9;
UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-004' WHERE id_historial BETWEEN 10 AND 11;
UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-005' WHERE id_historial BETWEEN 12 AND 13;
UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-006' WHERE id_historial = 14;
UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-007' WHERE id_historial = 15;
UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-008' WHERE id_historial = 16;
UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = 'MNT-009' WHERE id_historial = 17;


-- =====================================================================
-- 8. LANDING_STATION
-- =====================================================================

ALTER TABLE `LANDING_STATION` 
MODIFY COLUMN `nombre` VARCHAR(100) NOT NULL;

INSERT INTO `LANDING_STATION`
(
    id_landing,
    nombre,
    ciudad,
    pais,
    estado,
    MANTENIMIENTO_id_mantenimiento1
)
VALUES
('LS-LUR', 'Estación Lurín', 'Lima', 'Perú',
 'Operativa', 'MNT-001'),

('LS-MAN', 'Estación Máncora', 'Piura', 'Perú',
 'Operativa', 'MNT-002'),

('LS-SAL', 'Estación Salinas', 'Salinas', 'Ecuador',
 'Operativa', 'MNT-003'),

('LS-BUE', 'Estación Buenaventura', 'Buenaventura', 'Colombia',
 'Operativa', 'MNT-004'),

('LS-BAL', 'Estación Balboa', 'Ciudad de Panamá', 'Panamá',
 'Operativa', 'MNT-005'),

('LS-ARI', 'Estación Arica', 'Arica', 'Chile',
 'Operativa', 'MNT-006'),

('LS-VAL', 'Estación Valparaíso', 'Valparaíso', 'Chile',
 'Operativa', 'MNT-007'),

('LS-HER', 'Estación Hermosa Beach', 'Los Ángeles', 'Estados Unidos',
 'Operativa', 'MNT-008'),

('LS-CHA', 'Estación Chancay', 'Chancay', 'Perú',
 'Inactiva', 'MNT-009');


-- =====================================================================
-- 9. UTILIZACION_HIST
-- =====================================================================


INSERT INTO `UTILIZACION_HIST`
(
    id_registro,
    fecha,
    capacidad_utilizada,
    capacidad_disponible,
    capacidad_total
)
VALUES
(1, '2026-04-01', 2150.00, 5850.00, 8000.00),
(2, '2026-05-01', 2350.00, 5650.00, 8000.00),
(3, '2026-06-01', 2550.00, 5450.00, 8000.00),
(4, '2026-07-01', 2750.00, 5250.00, 8000.00),
(5, '2026-08-01', 2900.00, 5100.00, 8000.00),
(6, '2026-09-01', 7800.00, 200.00, 8000.00),

(7, '2026-04-01', 3500.00, 4500.00, 8000.00),
(8, '2026-05-01', 3800.00, 4200.00, 8000.00),
(9, '2026-06-01', 4100.00, 3900.00, 8000.00),
(10, '2026-07-01', 4400.00, 3600.00, 8000.00),
(11, '2026-08-01', 4700.00, 3300.00, 8000.00),
(12, '2026-09-01', 7700.00, 300.00, 8000.00),

(13, '2026-04-01', 1750.00, 4250.00, 6000.00),
(14, '2026-05-01', 1900.00, 4100.00, 6000.00),
(15, '2026-06-01', 2050.00, 3950.00, 6000.00),
(16, '2026-07-01', 2200.00, 3800.00, 6000.00),
(17, '2026-08-01', 2350.00, 3650.00, 6000.00),
(18, '2026-09-01', 1800.00, 4200.00, 6000.00),

(19, '2026-04-01', 1350.00, 1050.00, 2400.00),
(20, '2026-05-01', 1450.00, 950.00, 2400.00),
(21, '2026-06-01', 1550.00, 850.00, 2400.00),
(22, '2026-07-01', 1650.00, 750.00, 2400.00),
(23, '2026-08-01', 1800.00, 600.00, 2400.00),
(24, '2026-09-01', 1800.00, 600.00, 2400.00),

(25, '2026-04-01', 2750.00, 1250.00, 4000.00),
(26, '2026-05-01', 2950.00, 1050.00, 4000.00),
(27, '2026-06-01', 3200.00, 800.00, 4000.00),
(28, '2026-07-01', 3450.00, 550.00, 4000.00),
(29, '2026-08-01', 3650.00, 350.00, 4000.00),
(30, '2026-09-01', 1800.00, 2200.00, 4000.00),

(31, '2026-04-01', 2750.00, 1750.00, 4500.00),
(32, '2026-05-01', 2950.00, 1550.00, 4500.00),
(33, '2026-06-01', 3200.00, 1300.00, 4500.00),
(34, '2026-07-01', 3450.00, 1050.00, 4500.00),
(35, '2026-08-01', 3650.00, 850.00, 4500.00),
(36, '2026-09-01', 1800.00, 2700.00, 4500.00),

(37, '2026-04-01', 3500.00, 6500.00, 10000.00),
(38, '2026-05-01', 3800.00, 6200.00, 10000.00),
(39, '2026-06-01', 4100.00, 5900.00, 10000.00),
(40, '2026-07-01', 4400.00, 5600.00, 10000.00),
(41, '2026-08-01', 4700.00, 5300.00, 10000.00),
(42, '2026-09-01', 4200.00, 5800.00, 10000.00),

(43, '2026-04-01', 7000.00, 5000.00, 12000.00),
(44, '2026-05-01', 7600.00, 4400.00, 12000.00),
(45, '2026-06-01', 8200.00, 3800.00, 12000.00),
(46, '2026-07-01', 8800.00, 3200.00, 12000.00),
(47, '2026-08-01', 9400.00, 2600.00, 12000.00),
(48, '2026-09-01', 8100.00, 3900.00, 12000.00),

(49, '2026-04-01', 1550.00, 4450.00, 6000.00),
(50, '2026-05-01', 1650.00, 4350.00, 6000.00),
(51, '2026-06-01', 1800.00, 4200.00, 6000.00),
(52, '2026-07-01', 1950.00, 4050.00, 6000.00),
(53, '2026-08-01', 2050.00, 3950.00, 6000.00),
(54, '2026-09-01', 5900.00, 100.00, 6000.00);

-- Segmento al que pertenece cada registro (6 meses por segmento)
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-LUR-MAN' WHERE id_registro BETWEEN 1 AND 6;
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-MAN-SAL' WHERE id_registro BETWEEN 7 AND 12;
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-SAL-BUE' WHERE id_registro BETWEEN 13 AND 18;
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-BUE-BAL' WHERE id_registro BETWEEN 19 AND 24;
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-LUR-ARI' WHERE id_registro BETWEEN 25 AND 30;
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-ARI-VAL' WHERE id_registro BETWEEN 31 AND 36;
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-BAL-HER' WHERE id_registro BETWEEN 37 AND 42;
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-LUR-BAL' WHERE id_registro BETWEEN 43 AND 48;
UPDATE UTILIZACION_HIST SET SEGMENTO_codigo_segmento = 'SEG-SAL-BAL' WHERE id_registro BETWEEN 49 AND 54;


-- =====================================================================
-- 10. SEGMENTO
-- =====================================================================

INSERT INTO `SEGMENTO`
(
    codigo_segmento,
    capacidad_total,
    capacidad_utilizada,
    capacidad_reservada,
    estado,
    UTILIZACION_HIST_id_registro,
    LANDING_STATION_id_origen,
    LANDING_STATION_id_destino,
    MANTENIMIENTO_id_mantenimiento
)
VALUES
('SEG-LUR-MAN', 8000.00, 7800.00, 0.00,
 'Operativo', 6, 'LS-LUR', 'LS-MAN', 'MNT-001'),

('SEG-MAN-SAL', 8000.00, 7700.00, 0.00,
 'Operativo', 12, 'LS-MAN', 'LS-SAL', 'MNT-002'),

('SEG-SAL-BUE', 6000.00, 1800.00, 0.00,
 'Degradado', 18, 'LS-SAL', 'LS-BUE', 'MNT-003'),

('SEG-BUE-BAL', 2400.00, 1800.00, 0.00,
 'Fuera de servicio', 24, 'LS-BUE', 'LS-BAL', 'MNT-004'),

('SEG-LUR-ARI', 4000.00, 1800.00, 0.00,
 'Operativo', 30, 'LS-LUR', 'LS-ARI', 'MNT-005'),

('SEG-ARI-VAL', 4500.00, 1800.00, 0.00,
 'En mantenimiento', 36, 'LS-ARI', 'LS-VAL', 'MNT-006'),

('SEG-BAL-HER', 10000.00, 4200.00, 800.00,
 'Operativo', 42, 'LS-BAL', 'LS-HER', 'MNT-007'),

('SEG-LUR-BAL', 12000.00, 8100.00, 800.00,
 'Operativo', 48, 'LS-LUR', 'LS-BAL', 'MNT-008'),

('SEG-SAL-BAL', 6000.00, 5900.00, 0.00,
 'Operativo', 54, 'LS-SAL', 'LS-BAL', 'MNT-009');


-- =====================================================================
-- 11. RUTA
-- =====================================================================

INSERT INTO `RUTA`
(
    id_ruta,
    codigo,
    estado
)
VALUES
(1, 'RUTA-LIM-PTY-01', 'Activa'),
(2, 'RUTA-LIM-PTY-02', 'Activa'),
(3, 'RUTA-LIM-VAP-01', 'Activa'),
(4, 'RUTA-LIM-LAX-01', 'Activa'),
(5, 'RUTA-SAL-BUE-01', 'Activa'),
(6, 'RUTA-PIU-PTY-01', 'Activa'),
(7, 'RUTA-LIM-SAL-01', 'Activa'),
(8, 'RUTA-LIM-BAL-01', 'Activa');


-- =====================================================================
-- 12. RUTA_has_SEGMENTO
-- =====================================================================

INSERT INTO `RUTA_has_SEGMENTO`
(
    RUTA_id_ruta,
    SEGMENTO_codigo_segmento,
    orden
)
VALUES
(1, 'SEG-LUR-BAL', 1),

(2, 'SEG-LUR-MAN', 1),
(2, 'SEG-MAN-SAL', 2),
(2, 'SEG-SAL-BAL', 3),

(3, 'SEG-LUR-ARI', 1),
(3, 'SEG-ARI-VAL', 2),

(4, 'SEG-LUR-BAL', 1),
(4, 'SEG-BAL-HER', 2),

(5, 'SEG-SAL-BUE', 1),

(6, 'SEG-MAN-SAL', 1),
(6, 'SEG-SAL-BUE', 2),
(6, 'SEG-BUE-BAL', 3),

(7, 'SEG-LUR-MAN', 1),
(7, 'SEG-MAN-SAL', 2),

(8, 'SEG-LUR-BAL', 1),
(8, 'SEG-BAL-HER', 2);


-- =====================================================================
-- 13. SERVICIO
-- =====================================================================

INSERT INTO `SERVICIO`
(
    id_servicio,
    capacidad_contratada,
    fecha_activacion,
    estado,
    RUTA_id_ruta,
    CLIENTE_id_cliente
)
VALUES
(1, 1500.00, '2025-10-15', 'Activo', 1, 1),
(2, 2000.00, '2025-12-01', 'Activo', 1, 4),
(3, 2500.00, '2025-11-20', 'Activo', 2, 1),
(4, 1000.00, '2026-01-10', 'Activo', 3, 2),
(5, 800.00, '2026-02-05', 'Activo', 3, 3),
(6, 400.00, '2026-03-18', 'Activo', 4, 3),
(7, 1200.00, '2026-02-25', 'Activo', 6, 6),
(8, 600.00, '2026-04-02', 'Activo', 6, 5),
(9, 900.00, '2026-08-12', 'Activo', 7, 7),
(10, 3000.00, '2026-01-30', 'Activo', 8, 4),
(11, 1200.00, '2026-05-14', 'Activo', 8, 2),
(12, 500.00, '2025-09-01', 'Cancelado', 5, 3),
(13, 1000.00, '2026-07-01', 'Provisionado', 7, 1),
(14, 700.00, '2025-12-20', 'Provisionado', 2, 6),
(15, 2700.00, '2026-06-20', 'Activo', 2, 3);


-- =====================================================================
-- 14. HIST_SOLICITUD
-- =====================================================================

INSERT INTO `HIST_SOLICITUD`
(
    id_historial,
    estado,
    fecha
)
VALUES

(1, 'Registrada', '2026-07-20 09:00:00'),
(2, 'En evaluación', '2026-07-23 10:00:00'),
(3, 'Aprobada', '2026-07-26 11:00:00'),
(4, 'Provisionada', '2026-07-29 12:00:00'),
(5, 'Activa', '2026-08-01 13:00:00'),

(6, 'Registrada', '2026-09-01 09:00:00'),
(7, 'En evaluación', '2026-09-04 10:00:00'),
(8, 'Aprobada', '2026-09-07 11:00:00'),
(9, 'Provisionada', '2026-09-10 12:00:00'),

(10, 'Registrada', '2026-09-10 09:00:00'),
(11, 'En evaluación', '2026-09-13 10:00:00'),
(12, 'Aprobada', '2026-09-16 11:00:00'),

(13, 'Registrada', '2026-09-22 09:00:00'),
(14, 'En evaluación', '2026-09-25 10:00:00'),
(15, 'Registrada', '2026-09-29 09:00:00'),

(16, 'Registrada', '2026-08-05 09:00:00'),
(17, 'En evaluación', '2026-08-08 10:00:00'),
(18, 'Rechazada', '2026-08-11 11:00:00'),

(19, 'Registrada', '2026-09-15 09:00:00'),
(20, 'En evaluación', '2026-09-18 10:00:00'),
(21, 'Pendiente por capacidad', '2026-09-21 11:00:00'),

(22, 'Registrada', '2026-08-25 09:00:00'),
(23, 'En evaluación', '2026-08-28 10:00:00'),
(24, 'Aprobada', '2026-08-31 11:00:00'),
(25, 'Provisionada', '2026-09-03 12:00:00'),

(26, 'Registrada', '2026-09-20 09:30:00'),
(27, 'En evaluación', '2026-09-23 10:30:00'),

(28, 'Registrada', '2026-09-21 08:45:00'),
(29, 'Aprobada', '2026-09-24 11:00:00'),

(30, 'Registrada', '2026-09-22 14:00:00'),
(31, 'En evaluación', '2026-09-25 15:00:00'),

(32, 'Registrada', '2026-09-23 09:15:00'),
(33, 'Provisionada', '2026-09-27 12:00:00'),

(34, 'Registrada', '2026-09-24 10:00:00'),
(35, 'Rechazada', '2026-09-27 13:30:00'),

(36, 'Registrada', '2026-09-25 08:30:00'),
(37, 'Pendiente por capacidad', '2026-09-28 11:30:00'),

(38, 'Registrada', '2026-09-26 09:00:00'),
(39, 'Aprobada', '2026-09-29 10:30:00'),

(40, 'Registrada', '2026-09-27 13:00:00'),
(41, 'En evaluación', '2026-09-30 14:00:00'),

(42, 'Registrada', '2026-09-28 08:00:00'),
(43, 'Activa', '2026-10-01 09:00:00'),

(44, 'Registrada', '2026-09-29 11:00:00'),
(45, 'Provisionada', '2026-10-01 12:30:00'),

(46, 'Registrada', '2026-09-30 09:30:00'),
(47, 'En evaluación', '2026-10-01 10:30:00'),

(48, 'Registrada', '2026-09-30 14:00:00'),
(49, 'Rechazada', '2026-10-01 15:00:00'),

(50, 'Registrada', '2026-10-01 08:30:00'),
(51, 'Aprobada', '2026-10-01 11:00:00'),

(52, 'Registrada', '2026-10-01 13:00:00'),
(53, 'Pendiente por capacidad', '2026-10-01 16:00:00');

-- Solicitud a la que pertenece cada cambio
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 1 WHERE id_historial BETWEEN 1 AND 5;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 2 WHERE id_historial BETWEEN 6 AND 9;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 3 WHERE id_historial BETWEEN 10 AND 12;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 4 WHERE id_historial BETWEEN 13 AND 14;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 5 WHERE id_historial = 15;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 6 WHERE id_historial BETWEEN 16 AND 18;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 7 WHERE id_historial BETWEEN 19 AND 21;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 8 WHERE id_historial BETWEEN 22 AND 25;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 9 WHERE id_historial BETWEEN 28 AND 29;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 10 WHERE id_historial BETWEEN 30 AND 31;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 11 WHERE id_historial BETWEEN 32 AND 33;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 12 WHERE id_historial BETWEEN 34 AND 35;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 13 WHERE id_historial BETWEEN 36 AND 37;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 14 WHERE id_historial BETWEEN 38 AND 39;
UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = 15 WHERE id_historial BETWEEN 40 AND 41;

-- Usuario que registró cada cambio (el que creó la solicitud)
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 7549017 WHERE SOLICITUD_id_solicitud = 1;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 7549017 WHERE SOLICITUD_id_solicitud = 2;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 6951827 WHERE SOLICITUD_id_solicitud = 3;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 7549017 WHERE SOLICITUD_id_solicitud = 4;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 6951827 WHERE SOLICITUD_id_solicitud = 5;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 7549017 WHERE SOLICITUD_id_solicitud = 6;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 6951827 WHERE SOLICITUD_id_solicitud = 7;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 7549017 WHERE SOLICITUD_id_solicitud = 8;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 72841563 WHERE SOLICITUD_id_solicitud = 9;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 46382915 WHERE SOLICITUD_id_solicitud = 10;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 7549017 WHERE SOLICITUD_id_solicitud = 11;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 72841563 WHERE SOLICITUD_id_solicitud = 12;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 6951827 WHERE SOLICITUD_id_solicitud = 13;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 46382915 WHERE SOLICITUD_id_solicitud = 14;
UPDATE HIST_SOLICITUD SET USUARIO_dni_usuario = 72841563 WHERE SOLICITUD_id_solicitud = 15;

UPDATE HIST_SOLICITUD SET observacion = 'Solicitud registrada.'
WHERE estado = 'Registrada' AND SOLICITUD_id_solicitud IS NOT NULL;


-- =====================================================================
-- 15. SOLICITUD_CAPACIDAD
-- =====================================================================

ALTER TABLE `SOLICITUD_CAPACIDAD` 
MODIFY COLUMN `observaciones` VARCHAR(255) NULL;

ALTER TABLE `SOLICITUD_CAPACIDAD` 
MODIFY COLUMN `estado` VARCHAR(50) NOT NULL;

INSERT INTO `SOLICITUD_CAPACIDAD`
(
    id_solicitud,
    id_ruta_propuesta,
    capacidad_requerida,
    estado,
    fecha_solicitud,
    HIST_SOLICITUD_id_historial,
    USUARIO_id_usuario,
    fecha_requerida,
    observaciones,
    CLIENTE_id_cliente,
    LANDING_STATION_id_origen,
    LANDING_STATION_id_destino
)
VALUES


(1, 7, 900.00, 'Activa',
 '2026-07-20', 5, 7549017,
 '2026-08-01',
 'Enlace para interconexión académica Lima - Salinas',
 7, 'LS-LUR', 'LS-SAL'),

(2, 1, 1000.00, 'Provisionada',
 '2026-09-01', 9, 7549017,
 '2026-09-12',
 'Ampliación de capacidad Lima - Panamá',
 1, 'LS-LUR', 'LS-BAL'),

(3, 4, 800.00, 'Aprobada',
 '2026-09-10', 12, 6951827,
 '2026-10-01',
 'Nuevo enlace hacia Los Ángeles',
 4, 'LS-LUR', 'LS-HER'),

(4, 2, 600.00, 'En evaluación',
 '2026-09-22', 14, 7549017,
 '2026-10-01',
 'Respaldo de tráfico corporativo',
 2, 'LS-LUR', 'LS-BAL'),

(5, NULL, 300.00, 'Registrada',
 '2026-09-29', 15, 6951827,
 '2026-10-01',
 'Enlace temporal Salinas - Buenaventura',
 4, 'LS-SAL', 'LS-BUE'),

(6, 3, 500.00, 'Rechazada',
 '2026-08-05', 18, 7549017,
 '2026-08-30',
 'Cliente con estado Inactivo',
 5, 'LS-LUR', 'LS-VAL'),

(7, 3, 2000.00, 'Pendiente por capacidad',
 '2026-09-15', 21, 6951827,
 '2026-10-01',
 'Capacidad insuficiente en SEG-LUR-ARI y SEG-ARI-VAL',
 8, 'LS-LUR', 'LS-VAL'),

(8, 6, 700.00, 'Provisionada',
 '2026-08-25', 25, 7549017,
 '2026-10-01',
 'No se puede activar: SEG-BUE-BAL fuera de servicio',
 6, 'LS-MAN', 'LS-BAL'),

(9, 8, 1200.00, 'Aprobada',
 '2026-09-21', 29, 72841563,
 '2026-10-10',
 'Ampliación de capacidad para tráfico empresarial Lima - Panamá',
 11, 'LS-LUR', 'LS-HER'),

(10, 3, 700.00, 'En evaluación',
 '2026-09-22', 31, 46382915,
 '2026-10-12',
 'Nueva conexión para servicio internacional Lima - Valparaíso',
 10, 'LS-LUR', 'LS-VAL'),

(11, 4, 1500.00, 'Provisionada',
 '2026-09-23', 33, 7549017,
 '2026-10-05',
 'Incremento de capacidad para tráfico hacia Los Ángeles',
 15, 'LS-LUR', 'LS-HER'),

(12, 6, 400.00, 'Rechazada',
 '2026-09-24', 35, 72841563,
 '2026-10-08',
 'Solicitud no compatible con las condiciones actuales de la ruta',
 13, 'LS-MAN', 'LS-BAL'),

(13, 2, 1800.00, 'Pendiente por capacidad',
 '2026-09-25', 37, 6951827,
 '2026-10-15',
 'Capacidad insuficiente en uno de los segmentos de la ruta',
 14, 'LS-LUR', 'LS-BAL'),

(14, 7, 600.00, 'Aprobada',
 '2026-09-26', 39, 46382915,
 '2026-10-18',
 'Ampliación para interconexión de red académica',
 12, 'LS-LUR', 'LS-SAL'),

(15, 1, 1000.00, 'En evaluación',
 '2026-09-27', 41, 72841563,
 '2026-10-20',
 'Nueva demanda de capacidad Lima - Panamá',
 9, 'LS-LUR', 'LS-BAL');
-- =====================================================================
-- 16. HIST_INCIDENCIA
-- =====================================================================


INSERT INTO `HIST_INCIDENCIA`
(
    id_historial,
    fecha,
    estado
)
VALUES

(1, '2026-05-03 02:15:00', 'Detectada'),
(2, '2026-05-03 05:15:00', 'En análisis'),
(3, '2026-05-03 08:15:00', 'Reparación programada'),
(4, '2026-05-03 11:15:00', 'En reparación'),
(5, '2026-05-03 14:00:00', 'Servicio restaurado'),
(6, '2026-05-04 09:00:00', 'Cerrada'),

(7, '2026-06-11 23:40:00', 'Detectada'),
(8, '2026-06-12 02:40:00', 'En análisis'),
(9, '2026-06-12 05:40:00', 'Reparación programada'),
(10, '2026-06-12 08:40:00', 'En reparación'),
(11, '2026-06-14 18:00:00', 'Servicio restaurado'),
(12, '2026-06-15 10:00:00', 'Cerrada'),

(13, '2026-09-18 07:20:00', 'Detectada'),
(14, '2026-09-18 10:20:00', 'En análisis'),
(15, '2026-09-18 13:20:00', 'Reparación programada'),
(16, '2026-09-18 16:20:00', 'En reparación'),
(17, '2026-09-20 16:00:00', 'Servicio restaurado'),

(18, '2026-09-21 13:10:00', 'Detectada'),
(19, '2026-09-21 16:10:00', 'En análisis'),
(20, '2026-09-21 19:10:00', 'Reparación programada'),

(21, '2026-09-26 05:45:00', 'Detectada'),
(22, '2026-09-26 08:45:00', 'En análisis'),

(23, '2026-09-24 03:30:00', 'Detectada'),
(24, '2026-09-24 06:30:00', 'En análisis'),
(25, '2026-09-24 09:30:00', 'Reparación programada'),
(26, '2026-09-24 12:30:00', 'En reparación'),

(27, '2026-09-29 20:05:00', 'Detectada'),
(28, '2026-09-12 04:20:00', 'Detectada'),
(29, '2026-09-12 07:20:00', 'En análisis'),
(30, '2026-09-12 10:20:00', 'Reparación programada'),

(31, '2026-09-13 18:40:00', 'Detectada'),
(32, '2026-09-13 21:40:00', 'En análisis'),
(33, '2026-09-15 15:00:00', 'Servicio restaurado'),

(34, '2026-09-16 06:15:00', 'Detectada'),
(35, '2026-09-16 09:15:00', 'En análisis'),
(36, '2026-09-16 14:15:00', 'En reparación'),
(37, '2026-09-17 18:00:00', 'Cerrada'),

(38, '2026-09-19 11:30:00', 'Detectada'),
(39, '2026-09-19 14:30:00', 'En análisis'),

(40, '2026-09-20 03:10:00', 'Detectada'),
(41, '2026-09-20 06:10:00', 'En análisis'),
(42, '2026-09-21 12:00:00', 'Reparación programada'),

(43, '2026-09-22 17:45:00', 'Detectada'),
(44, '2026-09-22 20:45:00', 'En reparación'),
(45, '2026-09-23 16:00:00', 'Servicio restaurado'),

(46, '2026-09-25 01:25:00', 'Detectada'),
(47, '2026-09-25 04:25:00', 'En análisis'),
(48, '2026-09-25 12:00:00', 'Cerrada'),

(49, '2026-09-28 22:15:00', 'Detectada'),
(50, '2026-09-29 01:15:00', 'En análisis'),
(51, '2026-09-30 10:00:00', 'Servicio restaurado');

-- Cada cambio del historial se enlaza con su incidencia
-- y con el usuario que lo registró (Network Operator: Valeria Rojas)

UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-001' WHERE id_historial BETWEEN 1 AND 6;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-002' WHERE id_historial BETWEEN 7 AND 12;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-003' WHERE id_historial BETWEEN 13 AND 17;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-004' WHERE id_historial BETWEEN 18 AND 20;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-005' WHERE id_historial BETWEEN 21 AND 22;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-006' WHERE id_historial BETWEEN 23 AND 26;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-007' WHERE id_historial = 27;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-008' WHERE id_historial BETWEEN 28 AND 30;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-009' WHERE id_historial BETWEEN 31 AND 33;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-010' WHERE id_historial BETWEEN 34 AND 37;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-011' WHERE id_historial BETWEEN 38 AND 39;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-012' WHERE id_historial BETWEEN 40 AND 42;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-013' WHERE id_historial BETWEEN 43 AND 45;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-014' WHERE id_historial BETWEEN 46 AND 48;
UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = 'INC-015' WHERE id_historial BETWEEN 49 AND 51;

UPDATE HIST_INCIDENCIA SET USUARIO_dni_usuario = 20354448 WHERE id_historial BETWEEN 1 AND 51;


-- =====================================================================
-- 17. INCIDENCIA
-- =====================================================================



INSERT INTO `INCIDENCIA`
(
    codigo_incidencia,
    titulo,
    descripcion,
    severidad,
    estado,
    fecha_deteccion,
    SEGMENTO_codigo_segmento,
    LANDING_STATION_id_landing,
    hora,
    HIST_INCIDENCIA_id_historial
)
VALUES


('INC-001',
 'Falla de fuente de poder en PFE',
 'Falla en el equipo de alimentación (PFE) de la estación Lurín que afectó al segmento directo a Balboa',
 'Alta',
 'Cerrada',
 '2026-05-03',
 'SEG-LUR-BAL',
 'LS-LUR',
 '02:15:00',
 6),

('INC-002',
 'Corte de fibra por actividad pesquera',
 'Corte parcial de fibra en zona costera de Máncora causado por redes de arrastre',
 'Crítica',
 'Cerrada',
 '2026-06-11',
 'SEG-MAN-SAL',
 'LS-MAN',
 '23:40:00',
 12),

('INC-003',
 'Pérdida de potencia en repetidor',
 'Caída de potencia óptica en un repetidor del tramo Balboa - Hermosa Beach',
 'Alta',
 'Servicio restaurado',
 '2026-09-18',
 'SEG-BAL-HER',
 'LS-BAL',
 '07:20:00',
 17),

('INC-004',
 'Alarma de temperatura en sala de equipos',
 'Alarma intermitente de temperatura en la estación Salinas',
 'Baja',
 'Reparación programada',
 '2026-09-21',
 'SEG-SAL-BUE',
 'LS-SAL',
 '13:10:00',
 20),

('INC-005',
 'Degradación de señal OSNR',
 'Aumento de errores pre-FEC en el tramo Salinas - Buenaventura',
 'Media',
 'En análisis',
 '2026-09-26',
 'SEG-SAL-BUE',
 'LS-SAL',
 '05:45:00',
 22),

('INC-006',
 'Corte total de cable submarino',
 'Corte total del cable entre Buenaventura y Balboa, posible deslizamiento submarino',
 'Crítica',
 'En reparación',
 '2026-09-24',
 'SEG-BUE-BAL',
 'LS-BUE',
 '03:30:00',
 26),

('INC-007',
 'Alarma de alta utilización y tráfico anómalo',
 'Picos de tráfico anómalos en la ruta hacia Valparaíso',
 'Media',
 'Detectada',
 '2026-09-29',
 'SEG-ARI-VAL',
 'LS-VAL',
 '20:05:00',
 27),

(
    'INC-008',
    'Pérdida de potencia óptica',
    'Reducción de potencia óptica detectada en el segmento Lima - Máncora',
    'Media',
    'Reparación programada',
    '2026-09-12',
    'SEG-LUR-MAN',
    'LS-LUR',
    '04:20:00',
    30
),

(
    'INC-009',
    'Alarma de amplificador',
    'Alarma de funcionamiento en amplificador del tramo Máncora - Salinas',
    'Alta',
    'Servicio restaurado',
    '2026-09-13',
    'SEG-MAN-SAL',
    'LS-MAN',
    '18:40:00',
    33
),

(
    'INC-010',
    'Degradación de señal',
    'Incremento de atenuación óptica detectado en el segmento Salinas - Buenaventura',
    'Media',
    'Cerrada',
    '2026-09-16',
    'SEG-SAL-BUE',
    'LS-SAL',
    '06:15:00',
    37
),

(
    'INC-011',
    'Falla de alimentación eléctrica',
    'Interrupción temporal de alimentación en la estación Balboa',
    'Crítica',
    'En análisis',
    '2026-09-19',
    'SEG-BAL-HER',
    'LS-BAL',
    '11:30:00',
    39
),

(
    'INC-012',
    'Errores de transmisión',
    'Incremento de errores de transmisión detectados en el tramo Lima - Arica',
    'Alta',
    'Reparación programada',
    '2026-09-20',
    'SEG-LUR-ARI',
    'LS-LUR',
    '03:10:00',
    42
),

(
    'INC-013',
    'Intermitencia del enlace',
    'Intermitencia temporal en el enlace entre Arica y Valparaíso',
    'Media',
    'Servicio restaurado',
    '2026-09-22',
    'SEG-ARI-VAL',
    'LS-ARI',
    '17:45:00',
    45
),

(
    'INC-014',
    'Alarma de temperatura',
    'Incremento de temperatura detectado en equipos de la estación Buenaventura',
    'Baja',
    'Cerrada',
    '2026-09-25',
    'SEG-SAL-BUE',
    'LS-BUE',
    '01:25:00',
    48
),

(
    'INC-015',
    'Pérdida de paquetes',
    'Aumento de pérdida de paquetes en el tramo Lima - Balboa',
    'Crítica',
    'Servicio restaurado',
    '2026-09-28',
    'SEG-LUR-BAL',
    'LS-LUR',
    '22:15:00',
    51
);

-- =====================================================================
-- 18. INCIDENCIA_SEGMENTO
-- =====================================================================

INSERT INTO INCIDENCIA_SEGMENTO
(
    codigo_incidencia,
    codigo_segmento
)
VALUES
    ('INC-007', 'SEG-ARI-VAL'),
    ('INC-015', 'SEG-LUR-BAL'),
    ('INC-005', 'SEG-SAL-BUE'),
    ('INC-014', 'SEG-SAL-BUE'),
    ('INC-006', 'SEG-BUE-BAL');


-- =====================================================================
-- 19. RESERVA_CAPACIDAD
-- Los 800 Gbps reservados en SEG-LUR-BAL y SEG-BAL-HER son de SOL-003
-- (Aprobada, 800 Gbps, RUTA-LIM-LAX-01)
-- =====================================================================

INSERT INTO `RESERVA_CAPACIDAD`
(
    id_reserva,
    SOLICITUD_id_solicitud,
    SEGMENTO_codigo_segmento,
    capacidad,
    fecha,
    estado
)
VALUES
(1, 3, 'SEG-LUR-BAL', 800.00, '2026-09-17 10:00:00', 'Reservada'),
(2, 3, 'SEG-BAL-HER', 800.00, '2026-09-17 10:00:00', 'Reservada');


-- =====================================================================
-- FIN DEL DML
-- =====================================================================


SELECT COUNT(*) AS total_roles
FROM ROL;

SELECT COUNT(*) AS total_usuarios
FROM USUARIO;

SELECT COUNT(*) AS total_clientes
FROM CLIENTE;

SELECT COUNT(*) AS total_mantenimientos
FROM MANTENIMIENTO;

SELECT COUNT(*) AS total_landing_stations
FROM LANDING_STATION;

SELECT COUNT(*) AS total_segmentos
FROM SEGMENTO;

SELECT COUNT(*) AS total_historial_incidencias
FROM HIST_INCIDENCIA;

SELECT COUNT(*) AS historial_sin_enlazar
FROM HIST_INCIDENCIA
WHERE INCIDENCIA_codigo_incidencia IS NULL;

SELECT COUNT(*) AS total_rutas
FROM RUTA;

SELECT COUNT(*) AS total_servicios
FROM SERVICIO;

SELECT COUNT(*) AS total_solicitudes
FROM SOLICITUD_CAPACIDAD;

SELECT COUNT(*) AS total_incidencias
FROM INCIDENCIA;

SELECT COUNT(*) AS total_reservas
FROM RESERVA_CAPACIDAD;

-- Verificación del tipo de dato
DESCRIBE SEGMENTO;


-- ---------------------------------------------------------------------
-- 1. Landing Stations nuevas (sin mantenimiento asignado).
-- ---------------------------------------------------------------------
INSERT INTO LANDING_STATION (id_landing, nombre, ciudad, pais, estado, MANTENIMIENTO_id_mantenimiento1)
VALUES
('LS-TRU', 'Estación Trujillo', 'Trujillo', 'Perú', 'Operativa', NULL),
('LS-IQQ', 'Estación Iquique', 'Iquique', 'Chile', 'Operativa', NULL),
('LS-MTA', 'Estación Manta', 'Manta', 'Ecuador', 'Operativa', NULL);

-- ---------------------------------------------------------------------
-- 2. Segmentos nuevos (sin rutas ni servicios: se pueden eliminar)
-- ---------------------------------------------------------------------
INSERT INTO SEGMENTO (codigo_segmento, capacidad_total, capacidad_utilizada, capacidad_reservada, estado,
                      UTILIZACION_HIST_id_registro, LANDING_STATION_id_origen, LANDING_STATION_id_destino,
                      MANTENIMIENTO_id_mantenimiento)
VALUES
('SEG-SAL-MTA', 4000.00, 0.00, 0.00, 'Operativo', NULL, 'LS-SAL', 'LS-MTA', NULL),
('SEG-MTA-BUE', 4000.00, 0.00, 0.00, 'Operativo', NULL, 'LS-MTA', 'LS-BUE', NULL);

-- ---------------------------------------------------------------------
-- 3. Mantenimientos ya cerrados de meses anteriores (historial)
-- ---------------------------------------------------------------------
INSERT INTO ACTIVIDAD_MANTENIMIENTO (id_actividad, titulo, descripcion, fecha, hora, tiempo_invertido,
                                     MANTENIMIENTO_codigo_mantenimiento)
VALUES
(10, 'Inspección de repetidores', 'Revisión de alarmas y potencia de repetidores del tramo', '2026-02-10', '01:00:00', '04:00:00', 'MNT-010'),
(11, 'Limpieza de conectores', 'Limpieza e inspección de conectores ópticos en la estación', '2026-03-05', '02:00:00', '03:00:00', 'MNT-011'),
(12, 'Cambio de fuente redundante', 'Reemplazo programado de la fuente redundante del SLTE', '2026-07-20', '03:00:00', '00:00:00', 'MNT-012');

INSERT INTO FINALIZACION_MANTENIMIENTO (id_finalizacion, resultado, resumen_final, observacion, fecha_fin, estado_servicios)
VALUES
(4, 'Exitoso', 'Repetidores dentro de parámetros', NULL, '2026-02-10 05:00:00', 'Restablecido'),
(5, 'Exitoso', 'Conectores limpios, pérdidas reducidas', 'Repetir limpieza en 6 meses', '2026-03-05 05:00:00', 'Restablecido');

INSERT INTO HIST_MANTENIMIENTO (id_historial, estado, fecha, MANTENIMIENTO_codigo_mantenimiento, observacion, USUARIO_dni_usuario)
VALUES
(18, 'Programado',   '2026-02-01 09:00:00', 'MNT-010', 'Mantenimiento registrado', 5403188),
(19, 'En ejecución', '2026-02-10 01:00:00', 'MNT-010', 'Inicio de los trabajos', 5403188),
(20, 'Finalizado',   '2026-02-10 05:00:00', 'MNT-010', 'Resultado: Exitoso', 5403188),
(21, 'Programado',   '2026-02-25 10:00:00', 'MNT-011', 'Mantenimiento registrado', 5403188),
(22, 'En ejecución', '2026-03-05 02:00:00', 'MNT-011', 'Inicio de los trabajos', 5403188),
(23, 'Finalizado',   '2026-03-05 05:00:00', 'MNT-011', 'Resultado: Exitoso', 5403188),
(24, 'Programado',   '2026-07-10 11:00:00', 'MNT-012', 'Mantenimiento registrado', 5403188),
(25, 'Cancelado',    '2026-07-18 16:00:00', 'MNT-012', 'El proveedor no entregó la fuente a tiempo', 5403188);

INSERT INTO MANTENIMIENTO (codigo_mantenimiento, tipo, estado, fecha_programada, hora_inicio, duracion_estimada,
                           ACTIVIDAD_MANTENIMIENTO_id_actividad, FINALIZACION_MANTENIMIENTO_id_finalizacion,
                           HIST_MANTENIMIENTO_id_historial)
VALUES
('MNT-010', 'Preventivo', 'Finalizado', '2026-02-10', '01:00:00', '04:00:00', 10, 4, 20),
('MNT-011', 'Preventivo', 'Finalizado', '2026-03-05', '02:00:00', '03:00:00', 11, 5, 23),
('MNT-012', 'Correctivo', 'Cancelado',  '2026-07-20', '03:00:00', '05:00:00', 12, NULL, 25);
