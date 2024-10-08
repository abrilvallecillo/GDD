---------------------------------------------------1---------------------------------------------------

-- Hacer una función que dado un artículo y un deposito devuelva un string que indique el estado del depósito según el artículo. 
-- Si la cantidad almacenada es menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el % de ocupación. 
-- Si la cantidad almacenada es mayor o igual al límite retornar “DEPOSITO COMPLETO”.

-- 1. Ver que parametros vamos a usar y de que tipo son 
-- 2. Que devuelve la funcion
-- 3. Cual es la logica de la funcion?? Que debe hacer?? -- Ver el stock de ese producto en el deposito

CREATE FUNCTION estadoDeposito(@articulo char(8), @deposito char(2) )
RETURNS VARCHAR(50)
AS
BEGIN 
    DECLARE @stoc_cantidad NUMERIC(12,2)
    DECLARE @stock_maximo NUMERIC(12,2)
    DECLARE @respuesta VARCHAR(50)

    SELECT @stoc_cantidad = STOCK.stoc_cantidad, -- Asigno una fila a la variable
            @stock_maximo = STOCK.stoc_stock_maximo 
            FROM STOCK 
            WHERE STOCK.stoc_producto = @articulo and STOCK.stoc_deposito = @deposito

    IF @stock_maximo IS NULL OR @stoc_cantidad >= @stock_maximo
        SET @respuesta =  'DEPOSITO COMPLETO'
    ELSE
        SET @respuesta =  'OCUPACION DEL DEPOSITO '+ @deposito + STR( @stoc_cantidad / @stock_maximo * 100 ) + ' %'
    RETURN @respuesta
END 
GO

-- 4. Como ejercutar la funcion??
SELECT STOCK.stoc_producto, 
        STOCK.stoc_deposito, 
        STOCK.stoc_cantidad, 
        STOCK.stoc_stock_maximo,
        DBO.estadoDeposito( STOCK.stoc_producto , STOCK.stoc_deposito ) 
FROM STOCK
GO

---------------------------------------------------

CREATE FUNCTION estadoDeposito2 ( @articulo char (8) , @deposito char (2) )
RETURNS VARCHAR (50)
AS
BEGIN
RETURN (
    SELECT 
        CASE WHEN  STOCK.stoc_stock_maximo IS NULL OR STOCK.stoc_cantidad >=  STOCK.stoc_stock_maximo THEN 'DEPOSITO COMPLETO'
        ELSE 'OCUPACION DEL DEPOSITO' +  STOCK.stoc_deposito + str( STOCK.stoc_cantidad /  STOCK.stoc_stock_maximo * 100) + ' %'
        END
    From STOCK where STOCK.stoc_producto = @articulo and  STOCK.stoc_deposito = @deposito
    )
END
GO

---------------------------------------------------2---------------------------------------------------

-- Realizar una función que dado un artículo y una fecha, retorne el stock que existía a esa fecha

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

CREATE PROCEDURE GerenteGeneral @cantidad INT OUTPUT
AS
BEGIN
    DECLARE @GerenteGeneral NUMERIC(6)
    
    -- La cantidad de empleados que no tienen Jefe
    SELECT @cantidad = count(*) 
    FROM Empleado 
    WHERE empl_jefe IS NULL

    -- El que tiene el salario mas alto y mayor antigüedad
    SELECT TOP 1 @GerenteGeneral = empl_codigo 
    FROM Empleado 
    WHERE empl_jefe IS NULL 
    ORDER BY empl_salario DESC, empl_ingreso ASC 

    -- Actualizar los empleados
    UPDATE Empleado 
    SET empl_jefe = @GerenteGeneral 
    WHERE empl_jefe IS NULL AND empl_codigo <> @GerenteGeneral

    RETURN
END
GO

BEGIN
    DECLARE @cantidad INT EXEC dbo.GerenteGeneral @cantidad
    PRINT @cantidad
END
GO

---------------------------------------------------

CREATE PROCEDURE GerenteGeneralCursor @cantidad INT OUTPUT
AS
BEGIN
    DECLARE @GerenteGeneral NUMERIC(6)
    DECLARE @empleado NUMERIC(6)
    
    -- El que tiene el salario mas alto y mayor antigüedad
    SELECT TOP 1 @GerenteGeneral = empl_codigo 
    FROM Empleado 
    WHERE empl_jefe IS NULL 
    ORDER BY empl_salario DESC, empl_ingreso ASC 

    -- Crea el cursor que va a traer los empleados que tengo que modificar
    DECLARE GerenteGeneralCursor CURSOR 
    FOR SELECT empl_codigo 
        FROM Empleado 
        WHERE empl_jefe IS NULL AND empl_codigo <> @GerenteGeneral

    -- Lo abre
    OPEN GerenteGeneralCursor

    -- Lo ejecuta
    FETCH GerenteGeneralCursor INTO @empleado
    WHILE @@FETCH_STATUS = 0
    BEGIN
         -- Actualizar los empleados
        UPDATE Empleado 
        SET empl_jefe = @GerenteGeneral 
        WHERE empl_jefe = @empleado

        FETCH GerenteGeneralCursor INTO @empleado
    END

    -- Lo cierra
    CLOSE GerenteGeneralCursor

    -- Lo destruye
    DEALLOCATE GerenteGeneralCursor

    RETURN
END
GO

BEGIN
    DECLARE @cant INT EXEC dbo.GerenteGeneralCursor @cant
    PRINT @cant
END
GO
---------------------------------------------------4---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para actualizar la columna de empleado empl_comision con la sumatoria del total de lo vendido por ese empleado a lo largo del último año. 
-- Se deberá retornar el código del vendedor que más vendió (en monto) a lo largo del último año.

