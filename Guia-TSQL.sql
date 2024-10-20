---------------------------------------------------1---------------------------------------------------

-- Hacer una función que dado un artículo y un deposito devuelva un string que indique el estado del depósito según el artículo. 
-- Si la cantidad almacenada es menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el % de ocupación. 
-- Si la cantidad almacenada es mayor o igual al límite retornar “DEPOSITO COMPLETO”.

-- 1. Ver que parametros vamos a usar y de que tipo son 
-- 2. Que devuelve la funcion
-- 3. Cual es la logica de la funcion?? Que debe hacer?? -- Ver el stock de ese producto en el deposito

CREATE FUNCTION estadoDelDeposito(@articulo char(8), @deposito char(2) )
RETURNS VARCHAR(50)
AS
BEGIN 
    DECLARE @stoc_cantidad NUMERIC(12,2)
    DECLARE @stock_maximo NUMERIC(12,2)
    DECLARE @respuesta VARCHAR(50)

    SELECT @stoc_cantidad = STOCK.stoc_cantidad, @stock_maximo = STOCK.stoc_stock_maximo -- Los valores que necesito para saber si esta lleno
            FROM STOCK 
            WHERE STOCK.stoc_producto = @articulo and STOCK.stoc_deposito = @deposito

    IF @stock_maximo IS NULL OR @stoc_cantidad >= @stock_maximo
        SET @respuesta = 'DEPOSITO COMPLETO'
    ELSE
        SET @respuesta = 'OCUPACION DEL DEPOSITO '+ @deposito + STR( @stoc_cantidad / @stock_maximo * 100 ) + ' %'
    RETURN @respuesta
END 
GO

---------------------------------------------------

SELECT STOCK.stoc_producto, 
        STOCK.stoc_deposito, 
        STOCK.stoc_cantidad, 
        STOCK.stoc_stock_maximo,
        DBO.estadoDelDeposito( STOCK.stoc_producto , STOCK.stoc_deposito ) 
FROM STOCK
GO
---------------------------------------------------2---------------------------------------------------

-- Realizar una función que dado un artículo y una fecha, retorne el stock que existía a esa fecha

-- 1. Los productos de STOCK
SELECT stoc_producto, SUM(stoc_cantidad) 
FROM STOCK
GROUP BY stoc_producto
GO

-- 2. Lo que vendi hasta la fecha
SELECT item_producto, SUM(item_cantidad)
FROM Item_Factura
JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND Item_tipo = fact_tipo
WHERE fact_fecha < '2011-12-16'
GROUP BY item_producto
GO

---------------------------------------------------ABRIL---------------------------------------------------

CREATE FUNCTION stockEn(@articulo CHAR(8), @fecha SMALLDATETIME )
RETURNS NUMERIC(12,2)
AS
BEGIN 
    DECLARE @stoc_actual NUMERIC(12,2)
    DECLARE @vendido NUMERIC(12,2)

    SELECT @stoc_actual = ISNULL ( SUM ( stoc_cantidad ), 0) -- Los que tengo
    FROM STOCK
    WHERE stoc_producto = @articulo -- NO SE USA GROUP BY

    SELECT @vendido = ISNULL ( SUM ( item_cantidad ) , 0 ) -- Los que vendi
    FROM Item_Factura
    JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND Item_tipo = fact_tipo
    WHERE item_producto = @articulo AND fact_fecha <= @fecha

    RETURN (@stoc_actual + @vendido)
END 
GO

---------------------------------------------------

SELECT Producto.prod_codigo, dbo.stockEn(Producto.prod_codigo, '01/01/2010')
FROM Producto
GO

---------------------------------------------------DOCENTE---------------------------------------------------

CREATE FUNCTION stockEn2(@articulo CHAR(8), @fecha SMALLDATETIME )
RETURNS DECIMAL(12,2)
AS
BEGIN 
    RETURN 
    ( 
        SELECT ISNULL ( SUM ( stoc_cantidad  ) , 0 ) -- Los que tengo
        FROM STOCK
        WHERE stoc_producto = @articulo
    )
    +
    ( 
        SELECT  ISNULL ( SUM ( item_cantidad ) , 0 )  -- Los que vendi
        FROM Item_Factura
        JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND Item_tipo = fact_tipo
        WHERE item_producto = @articulo AND fact_fecha <= @fecha 
    )
END 
GO

---------------------------------------------------

SELECT Producto.prod_codigo, dbo.stockEn2(Producto.prod_codigo, '01/01/2010')
FROM Producto
GO

---------------------------------------------------3---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para corregir la tabla empleado en caso que sea necesario. 
-- Se sabe que debería existir un único gerente general (debería ser el único empleado sin jefe). 
-- Si detecta que hay más de un empleado sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por mayor salario. 
-- Si hay más de uno se seleccionara el de mayor antigüedad en la empresa. 
-- Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad de empleados que había sin jefe antes de la ejecución.

-- 1. Que objeto voy a tener que crear?? 
    --> Modificar datos => Procedimiento / Trigger
    --> Ejecutar en un momento determinado que NO depende de un evento => Procedimiento

-- 2. Necesitamos parametros?? 
    --> Como un porcedimiento no puede retornar valores vamos a tener que crear una variable que simbolice nuestro resultado

CREATE PROCEDURE empleados @vendedor INT OUTPUT
AS
BEGIN
    UPDATE Empleado
    SET empl_comision = (
                            SELECT ISNULL ( SUM( fact_total) , 0 )
                            FROM Factura 
                            WHERE fact_vendedor = empl_codigo AND YEAR (fact_fecha) = ( SELECT MAX ( YEAR ( fact_fecha ) ) FROM Factura ) 
                        )
    SELECT TOP 1 @vendedor = empl_codigo FROM Empleado ORDER BY empl_comision DESC
    RETURN
END
GO

EXEC dbo.comisiones 1
SELECT * FROM Empleado ORDER BY empl_comision DESC
GO

---------------------------------------------------4---------------------------------------------------

-- Cree el/los objetos de BDD necesarios para actualizar la columna de empleado empl_comision con la sumatoria del total de lo vendido por ese empleado a lo largo del último año. 
-- Se deberá retornar el código del vendedor que más vendió (en monto) a lo largo del último año.

CREATE PROCEDURE comisiones @vendedor INT OUTPUT
AS
BEGIN
    UPDATE Empleado
    SET empl_comision = (
                            SELECT ISNULL ( SUM( fact_total) , 0 )
                            FROM Factura 
                            WHERE fact_vendedor = empl_codigo AND YEAR (fact_fecha) = ( SELECT MAX ( YEAR ( fact_fecha ) ) FROM Factura ) 
                        )
    SELECT TOP 1 @vendedor = empl_codigo FROM Empleado ORDER BY empl_comision DESC
    RETURN
END
GO

EXEC dbo.comisiones 1

SELECT * FROM Empleado ORDER BY empl_comision DESC
GO

---------------------------------------------------7---------------------------------------------------
-- NO LO TERMINE DE COPIAR
-- Cursor

CREATE PROCEDURE Ejercicio7 
AS
BEGIN

	--DROP TABLE Ventas 
    CREATE TABLE Ventas(
        articulo char(8), -- Código del articulo
        detalle char(30), -- Detalle del articulo
        cant_movimientos int, -- Cantidad de movimientos de ventas (Item Factura)
        precio_venta decimal(12,2), -- Precio promedio de venta
        renglon int, -- Nro de linea de la tabla (PK)
        ganancia NUMERIC(12,2) -- Precio de venta - Cantidad * Costo Actual
    )
    
    DECLARE @articulo char(8), 
            @detalle char(30), 
            @cant_movimientos int, 
            @precio_venta decimal(12,2),
            @renglon int, 
            @ganancia NUMERIC(12,2)

	DECLARE cursor_articulos CURSOR
	FOR (
        SELECT prod_codigo,
            prod_detalle,
            COUNT ( DISTINCT ( item_numero + item_sucursal + Item_tipo ) ),
            AVG ( item_precio ),
            SUM ( item_cantidad * item_precio ) - ( item_cantidad * item_precio )
			FROM Producto
			JOIN Item_Factura ON item_producto = prod_codigo
			GROUP BY prod_codigo, prod_detalle
        )

		OPEN cursor_articulos

		FETCH cursor_articulos
		INTO @articulo, 
            @detalle,
            @cant_movimientos,
            @precio_venta,
            @ganancia

		WHILE @@FETCH_STATUS = 0

		BEGIN
			INSERT Ventas
			VALUES ( @articulo, 
                    @detalle,
                    @cant_movimientos,
                    @precio_venta,
                    @ganancia
            )
			SELECT @renglon = @renglon + 1

            FETCH cursor_articulos 
            INTO @articulo, 
                    @detalle,
                    @cant_movimientos,
                    @precio_venta,
                    @ganancia
            
		END

		CLOSE cursor_articulos

		DEALLOCATE cursor_articulos

	END
GO


EXEC Ejercicio7

---------------------------------------------------7---------------------------------------------------

SELECT comp_producto, 

    p1.prod_detalle, 

    COUNT( DISTINCT comp_componente ), 

    ( SELECT SUM( comp_cantidad * p2.prod_precio ) 
    FROM Producto p2
    JOIN Composicion ON comp_componente = p2.prod_codigo AND comp_producto = p1.prod_codigo
    ),

    p1.prod_precio

FROM Composicion
JOIN Item_Factura ON comp_producto = item_producto
JOIN Producto p1 ON comp_producto = p1.prod_codigo
GROUP BY comp_producto, p1.prod_detalle, p1.prod_precio, p1.prod_codigo

---------------------------------------------------9---------------------------------------------------