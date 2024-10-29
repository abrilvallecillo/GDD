---------------------------------------------------VISTAS---------------------------------------------------
/*
CREATE VIEW [ < database_name > . ] [ < owner > . ] nombre [ ( column_ name [ ,...n ] ) ]
AS
select_statement
*/

-- Crear la vista
CREATE VIEW v_Stok 
AS
SELECT prod_codigo AS Codigo_del_Prodcuto,
    prod_detalle AS Detalle_del_Prodcuto, 
    stoc_deposito AS Codigo_del_Deposito, 
    depo_detalle AS Deposito, 
    stoc_Cantidad AS Cantidad_en_Stock_del_Deposito
FROM Producto 
JOIN Stock ON prod_codigo = stoc_producto 
JOIN Deposito ON stoc_deposito = depo_codigo
GO

-- Modificar la vista 
ALTER VIEW v_Stok 
AS
SELECT prod_codigo AS Codigo_del_Prodcuto,
    prod_detalle AS Detalle_del_Prodcuto, 
    stoc_deposito AS Codigo_del_Deposito, 
    depo_detalle AS Deposito, 
    stoc_Cantidad AS Cantidad_en_Stock_del_Deposito
FROM Producto 
JOIN Stock ON prod_codigo = stoc_producto 
JOIN Deposito ON stoc_deposito = depo_codigo
WHERE stoc_Cantidad > 100
GO

-- Mostrar la vista
SELECT * FROM v_Stok

SELECT Detalle_del_Prodcuto, 
    sum (Cantidad_en_Stock_del_Deposito),
    Deposito
FROM v_Stok 
GROUP BY Detalle_del_Prodcuto, Deposito
ORDER BY sum (Cantidad_en_Stock_del_Deposito) DESC
GO

-- INTO 
SELECT prod_codigo AS Codigo_del_Prodcuto,
    prod_detalle AS Detalle_del_Prodcuto, 
    stoc_deposito AS Codigo_del_Deposito, 
    depo_detalle AS Deposito, 
    stoc_Cantidad AS Cantidad_en_Stock_del_Deposito
INTO INTO_Stock
FROM Producto 
JOIN Stock ON prod_codigo = stoc_producto 
JOIN Deposito ON stoc_deposito = depo_codigo
GO

-- Diferencias entre INTO y la vista:
-- En INTO estan los datos, en la vista NO
-- INTO es estatico, la vista es dinamica
-- La vista devuelve lo que esta en el momento en la tabla original
-- INTO es un duplicado de una tabla, por ende sirve como back up

-- Crea la vista materializada
CREATE VIEW V_FACTURAS (CLIENTE, PRODUCTO, TOTAL)
WITH SCHEMABINDING
AS
SELECT FACT_CLIENTE, item_producto, COUNT_BIG(*) -- La diferencia entre COUNT(*) y COUNT_BIG(*) es que COUNT(*) devuelve un número de 4 bytes y COUNT_BIG(*) un número de 8 bytes
FROM dbo.FACTURA F 
JOIN dbo.Item_Factura I ON (fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero)
group by FACT_CLIENTE, item_producto
GO

-- Crea el índice CLUSTERED
CREATE UNIQUE CLUSTERED INDEX CI_Facturas_Ventas ON V_FACTURAS (Cliente, PRODUCTO)
GO

---------------------------------------------------FUNCIONES---------------------------------------------------
/*
Funciones escalares -- Devulve un valor de la tabla, un escalar

CREATE FUNCTION [ owner_name. ] nombre ( [ @parameter_name [AS] tipo_dato [ = default ] [ ...n ] ] )
RETURNS tipo_dato
[AS]
BEGIN function_body
RETURN valor
END

Funciones de valores de tabla en linea -- Devuelve una variable de tipo tabla (Matriz)

CREATE FUNCION [ owner_name. ] nombre ( [ @parameter_name [AS] tipo_dato [ = default ] [ ...n ] ] )
RETURNS TABLES
[AS]
RETURN [ ( ] select-statment [ ) ]

Funciones de valores de tabla de múltiples instrucciones -- Devuelve una variable de tipo tabla, que sea de tipo...

CREATE FUNCION [ owner_name. ] nombre ( [ @parameter_name [AS] tipo_dato [ = default ] [ ...n ] ] )
RETURNS @return_variable TABLE ( column_definition | table_constraint [ ...n ])
[AS]
BEGIN function_body
RETURN
END
*/

---------------------------------------------------PRODEDURES---------------------------------------------------
/*
CREATE PROC[EDURE] nombre [ @parameter tipo_dato ] [ = default ] [ OUTPUT ] [ ...n ]
AS sql_statement [ ...n ]
GO
*/

-- DIFERENCIAS ENTRE FUNCIONES Y PRODEDURES
-- 1. EL PRODEDURES NO DEVULVE RESULTADOS, solo true o false
-- 2. PUEDE TENER O NO PARAMETROS
-- 3. EL PRODEDURES PUEDE MODIFICAR LOS VALORES DE LA BDD
-- 4. EL PRODEDURES NO SE PUEDE USAR EN UN SELECT
-- 5. EL PRODEDURES NO SE INVOCAN A TRAVES DE SU NOMBRE, como con las funciones

---------------------------------------------------TRIGGER---------------------------------------------------
/*
CREATE TRIGGER nombre ON table | view 
FOR | AFTER | INSTEAD OF [ INSERT ] [ , ] [ UPDATE ] [ , ] [ DELETE ]
AS
sql_statement [ ...n ]
*/

-- 1. EL TRIGGER NO TIENE PARAMETROS
-- 2. EL TRIGGER NO SE INVOCA, se ejecuta cuando sucede un evento -- Cuando sucede un INSERT, UPDATE o DELETE.
-- 3. DIRECTAMENTE ASOCIADO A UNA TABLA

/*---------------------------------------------------DECLARACIONES---------------------------------------------------
DECLARE @local_variable data_type
---------------------------------------------------IMPRESIÓN---------------------------------------------------
PRINT msg_str | @local_variable | string_expr
---------------------------------------------------BEGIN...END---------------------------------------------------
BEGIN
    sql_statement | statement_block
END
---------------------------------------------------IF...ELSE---------------------------------------------------
IF Boolean_expression
    sql_statement | statement_block
[ ELSE
    sql_statement | statement_block ]
---------------------------------------------------RETURN---------------------------------------------------
RETURN [ integer_expression ]
---------------------------------------------------WAITFOR---------------------------------------------------
WAITFOR { DELAY 'time' | TIME 'time' }
---------------------------------------------------WHILE---------------------------------------------------
WHILE Boolean_expression
    {sql_statement | statement_block}
[BREAK]
    {sql_statement | statement_block}
[CONTINUE]
---------------------------------------------------CURSOR---------------------------------------------------
• Declarar el cursor definiendo su contenido

DECLARE cursor_name CURSOR 
-- Caracterizaciones optativas
[LOCAL | GLOBAL ] -- Visibilidad 
[ FORWARD_ONLY | SCROLL] -- Movimiento -- Solo para adelante -- Para adelante y para atras
[ STATIC | DYNAMIC ] -- Dinamismo -- A medida que lo voy recorriendo no lo cambia -- Se ejecuta al momento de abrirse (Se mantiene siempre actualizado)
FOR select_statement
---------------------------------------------------
• Abrir el cursor

OPEN [ GLOBAL ] cursor_name -- Ejecuta el SELECT
---------------------------------------------------
• Recorrido

FETCH [ NEXT | PRIOR | FIRST | LAST]
FROM [ GLOBAL ] cursor_name
[INTO @variable_name [....n ]]

@@FETCH_STATUS --> Devuelve el estado de la última instrucción FETCH de cursor ejecutada sobre cualquier cursor que la conexión haya abierto. 
                --> Esto se usa para leer un cursos 

0 --> La instrucción FETCH se ejecutó correctamente.
-1 --> La instrucción FETCH ha finalizado con error o la fila estaba más allá del conjunto de resultados.
-2 --> Falta la fila

@@CURSOR_ROWS --> Devuelve el número de filas correspondientes actualmente al último cursor abierto en la conexión. 
                --> Para determinar que el número de filas que cumplan las condiciones del cursor se recuperen en el momento en que se vuelve a llamar

-m --> El cursor se llena de forma asincrónica. El valor devuelto (-m) es el número de filas que contiene actualmente el conjunto de claves.
-1 --> El cursor es dinámico. Como los cursores dinámicos reflejan todos los cambios, el número de filas correspondientes al cursor cambia constantemente. Nunca se puede afirmar que se han recuperado todas las filas que correspondan.
0 --> No se han abierto cursores, no hay filas calificadas para el último cursor abierto, o éste se ha cerrado o su asignación se ha cancelado.
n --> El cursor está completamente lleno. El valor obtenido (n) es el número total de filas del cursor.
---------------------------------------------------
• Estado 

CURSOR_STATUS (local", 'cursor_name" | 'global", 'cursor _name')

1 --> El conjunto de resultados del cursor tiene al menos una fila
0 --> El conjunto de resultados del cursor está vacío.
-1 --> El cursor está cerrado.
-2 --> No aplicable. (Cuando es variable, osea dinamico)
-3 --> No existe ningún cursor con el nombre indicado.
---------------------------------------------------
• Cerrar el cursor

CLOSE [ GLOBAL ] cursor_name -- No deja disponible esa variable
---------------------------------------------------
• Liberar la memoria del cursor

DEALLOCATE [ GLOBAL ] cursor_name -- Borra el contenido -- Libera memoria

---------------------------------------------------EJEMPLO---------------------------------------------------

Este ejemplo utiliza @@FETCH_STATUS para controlar las actividades del cursor en un bucle WHILE.

DECLARE Employee_Cursor CURSOR 
FOR SELECT LastName, FirstName FROM Employees

OPEN Employee_Cursor

FETCH NEXT FROM Employee_Cursor
WHILE @@FETCH_STATUS = 0
BEGIN
    FETCH NEXT FROM Employee_Cursor
END

CLOSE Employee_Cursor

DEALLOCATE Employee_Cursor

---------------------------------------------------RAISERROR---------------------------------------------------

RAISERROR (msg_id | msg_str, severity) -- Muestra el error y aborta lo que estaba ejecutando

---------------------------------------------------TRY CATCH---------------------------------------------------

BEGIN TRY
    Instrucciones Transact -- Lo que quiere ejecutar
END TRY

BEGIN CATCH
    Instrucciones Transact -- Lo que va a ejecutar si TRY tira un error
END CATCH

---------------------------------------------------BEGIN TRANSACTION---------------------------------------------------

BEGIN TRAN[SACTION] [transaction_name |@tran_name_variable] -- Puede meterse en el medio de la transaccion, generando una nueva atomicidad

---------------------------------------------------COMMIT TRANSACTION---------------------------------------------------

COMMIT [TRAN [SACTION] [transaction_name | @tran_name_variable]] -- PARA CONFIRMAR LA TRANSACCION

-- Si @@TRANCOUNT es 1, COMMIT TRANSACTION hace que todas las modificaciones efectuadas sobre los datos desde el inicio de la transacción sean parte permanente de la base de datos, libera los recursos mantenidos por la conexión y reduce @@TRANCOUNT a O. 
-- Si @@TRANCOUNT es mayor que 1, COMMIT TRANSACTION sólo reduce @@TRANCOUNT en 1

---------------------------------------------------ROLLBACK TRANSACTION---------------------------------------------------

ROLLBACK [TRANISACTION] [transaction_name |@tran_name_variable] -- Vuelve para atras la ultima transaccion si tira error

---------------------------------------------------SET TRANSACTION ISOLATION LEVEL---------------------------------------------------

SET TRANSACTION ISOLATION LEVEL READ COMMITTED | READ UNCOMMITTED | REPEATABLE READ | SERIALIZABLE

*/

