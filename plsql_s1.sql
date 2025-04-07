-- USUARIO EA1_1_MDY_FOL

/* Se modificó la contraseña del usuario de EA1_1-CreaUsuario.sql por 
   requerimiento de seguridad de Oracle SQL Developer (contraseña 'duoc')

   La línea alterada fue esta: 

   CREATE USER EA1_1_MDY_FOL IDENTIFIED BY "H0l4.O_r4cL3!"
	
*/


-- FUNCIÓN 1

/* Función almacenada para calcular el total 
   de atenciones en un periodo MM-YYYY */

CREATE OR REPLACE FUNCTION fn_total_atenciones
 (p_periodo VARCHAR2)
    RETURN NUMBER
IS
    total_atenciones NUMBER;
BEGIN

    SELECT 
        COUNT (ate_id) AS cantidad
    INTO total_atenciones
    FROM atencion
    WHERE TO_CHAR(fecha_atencion, 'MM-YYYY') = p_periodo;

    RETURN total_atenciones;

END fn_total_atenciones;
/



-- FUNCIÓN 2

/* Función almacenada para calcular el total 
   de atenciones de una especialidad 
   en un periodo MM-YYYY */

CREATE OR REPLACE FUNCTION fn_total_especialidad
 (p_esp NUMBER, p_periodo VARCHAR2)
    RETURN NUMBER
IS
    total_especialidad NUMBER;
BEGIN

    SELECT 
        COUNT (ate_id) as cantidad
    INTO total_especialidad
    FROM atencion
    WHERE TO_CHAR(fecha_atencion, 'MM-YYYY')  = p_periodo
    AND esp_id = p_esp;
    RETURN total_especialidad;

END fn_total_especialidad;
/



-- FUNCIÓN 3

/* Función almacenada para calcular el costo promedio 
   de atenciones de una especialidad 
   en un periodo MM-YYYY */


CREATE OR REPLACE FUNCTION fn_costo_especialidad
 (p_esp NUMBER, p_periodo VARCHAR2)
    RETURN VARCHAR2
IS
    costo_especialidad NUMBER;
BEGIN

    SELECT 
        NVL(AVG(costo), 0) as costo_prom
    INTO costo_especialidad
    FROM atencion
    WHERE TO_CHAR(fecha_atencion, 'MM-YYYY')  = p_periodo
    AND esp_id = p_esp;
    RETURN TO_CHAR(costo_especialidad, '$999G999');

END fn_costo_especialidad;
/




-- FUNCIÓN 4

/* Función almacenada para imprimir el listado
   de las especialidades con la 
   información solicitada de un 
   periodo MM-YYYY. 

   Además, retorna un valor Boolean
   si existen o no registros. */

CREATE OR REPLACE FUNCTION fn_informe_especialidades
 (p_periodo VARCHAR2)
    RETURN BOOLEAN 
IS
    v_registros_existentes NUMBER := 0;
    v_total_atenciones NUMBER := 0;
    v_total_especialidad NUMBER := 0;
    v_costo_especialidad VARCHAR2(20);
    v_nombre_esp VARCHAR2(40);
    v_porcentaje NUMBER;
BEGIN
    -- Comprobar si hay registros dentro del periodo
    SELECT COUNT(*)
    INTO v_registros_existentes
    FROM atencion a
    JOIN especialidad_medico em ON a.med_run = em.med_run AND a.esp_id = em.esp_id
    JOIN especialidad e ON em.esp_id = e.esp_id
    WHERE TO_CHAR(a.fecha_atencion, 'MM-YYYY') = p_periodo;

    -- Si existen registros, generar el informe
    IF v_registros_existentes > 0 THEN

        -- Obtener el total de atenciones en el periodo (función 1)
        v_total_atenciones := fn_total_atenciones(p_periodo);
        
        -- Imprimir la cantidad de atenciones del periodo
        DBMS_OUTPUT.PUT_LINE('CANTIDAD DE ATENCIONES DEL PERIODO: ' || v_total_atenciones);
        DBMS_OUTPUT.PUT_LINE('Listado emitido');
        DBMS_OUTPUT.PUT_LINE(' ');


        -- Imprimir la información de cada especialidad con ciclo FOR
        FOR i IN (
            SELECT DISTINCT e.nombre, e.esp_id
            FROM atencion a
            JOIN especialidad_medico em ON a.med_run = em.med_run AND a.esp_id = em.esp_id
            JOIN especialidad e ON em.esp_id = e.esp_id
            WHERE TO_CHAR(a.fecha_atencion, 'MM-YYYY') = p_periodo)

           LOOP -- Comenzar LOOP para imprimir la información.
            v_nombre_esp := i.nombre;

            -- Obtener total de atenciones para la especialidad (función 2)
            v_total_especialidad := fn_total_especialidad(i.esp_id, p_periodo);

            -- Obtener costo promedio para la especialidad (función 3)
            v_costo_especialidad := fn_costo_especialidad(i.esp_id, p_periodo);

            -- Calcular porcentaje de atenciones
            IF v_total_atenciones > 0 THEN
                v_porcentaje := (v_total_especialidad / v_total_atenciones) * 100;
            ELSE
                v_porcentaje := 0;
            END IF;

            -- Imprimir la información de la especialidad según formato
            DBMS_OUTPUT.PUT_LINE('++++++++++++++++++++++++++++++++++++++++++++++++');
            DBMS_OUTPUT.PUT_LINE(v_nombre_esp);
            DBMS_OUTPUT.PUT_LINE('---------- Costo promedio : ' || v_costo_especialidad);
            DBMS_OUTPUT.PUT_LINE('---------- Total atenciones : ' || v_total_especialidad);
            DBMS_OUTPUT.PUT_LINE('---------- % del total : ' || TO_CHAR(v_porcentaje, '999.99') || '%');
            DBMS_OUTPUT.PUT_LINE(' '); 
        END LOOP; -- Salir del LOOP al terminar la impresión
        
        RETURN TRUE;

    ELSE
        -- Si no existen registros, retornar FALSE
        RETURN FALSE;
    END IF;

END fn_informe_especialidades;
/




-- BLOQUE ANÓNIMO

/*  Bloque PL/SQL que llama a la función almacenada 
	que permite emitir el informe con la información
	solicitada (función 4).

	Solicita el ingreso del periodo en formato MM-YYYY
	como parámetro para la función 4.

	Además, imprime un mensaje indicando el éxito
	o fracaso en la emisión del informe. */

DECLARE
    v_periodo VARCHAR2(7);  
    v_existen_registros BOOLEAN;

BEGIN
    -- Solicitar al usuario que ingrese el periodo (ejemplo 05-2025)
    v_periodo := '&MM_guión_YYYY'; 

    -- Llamar a la función 4 para verificar si existen registros para el periodo
    v_existen_registros := fn_informe_especialidades(v_periodo);

    -- Si la función 4 devuelve TRUE, el informe se mostrará
    IF v_existen_registros THEN
        DBMS_OUTPUT.PUT_LINE('++++++++++++++++++++++++++++++++++++++++++++++++');
        DBMS_OUTPUT.PUT_LINE('Fin del listado.');

    -- Si la función 4 devuelve FALSE, se mostrará el siguiente mensaje
    ELSE
        DBMS_OUTPUT.PUT_LINE('Listado NO emitido.');
    END IF;

END;
/