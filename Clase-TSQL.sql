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
---------------------------------------------------IF...ELSE---------------------------------------------------