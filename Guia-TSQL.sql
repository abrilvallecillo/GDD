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
    -- Actualizamos la columna 'empl_comision' de la tabla Empleado. 
    -- Esta columna se actualiza con la suma de los montos totales de las facturas (fact_total) emitidas por el vendedor (empl_codigo).
    -- Se asegura que se sumen solo las facturas correspondientes al último año de facturación.
    UPDATE Empleado
    SET empl_comision = ( SELECT ISNULL(SUM(fact_total), 0)  -- Suma el total de las facturas y si no hay facturas, devuelve 0.
                            FROM Factura 
                            WHERE fact_vendedor = empl_codigo  -- Filtra las facturas que fueron emitidas por el vendedor correspondiente.
                            AND YEAR(fact_fecha) = ( SELECT MAX(YEAR(fact_fecha))  -- Considera solo las facturas del año más reciente.
                                                        FROM Factura
                                                    ) 
                        )
    -- Después de actualizar la comisión de los empleados, se selecciona el vendedor con la mayor comisión.
    -- Se usa 'TOP 1' para obtener el código del vendedor con la mayor comisión.
    SELECT TOP 1 @vendedor = empl_codigo 
    FROM Empleado 
    ORDER BY empl_comision DESC  -- Ordena los empleados por comisión de mayor a menor y selecciona el primero (mayor comisión).
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
    -- Actualizamos la columna 'empl_comision' en la tabla Empleado.
    -- Esta columna se establece con la suma del total de lo vendido por cada empleado durante el último año.
    UPDATE Empleado
    SET empl_comision = (
                            -- Subconsulta que obtiene la suma del total de ventas (fact_total) realizadas por cada empleado.
                            -- Se utiliza ISNULL para asegurar que si no hay ventas, el valor devuelto sea 0.
                            SELECT ISNULL(SUM(fact_total), 0) 
                            FROM Factura 
                            WHERE fact_vendedor = empl_codigo  -- Se filtran las ventas correspondientes al vendedor específico (empl_codigo).
                            AND YEAR(fact_fecha) = ( SELECT MAX(YEAR(fact_fecha))  -- Se obtiene el último año en el que se registraron facturas.
                                                        FROM Factura
                                                     )
                        )
    
    -- Luego de actualizar la columna 'empl_comision' con las ventas del último año,
    -- se selecciona el código del empleado que más vendió, basándonos en la comisión calculada.
    SELECT TOP 1 @vendedor = empl_codigo 
    FROM Empleado 
    ORDER BY empl_comision DESC  -- Se ordenan los empleados por comisión en orden descendente (de mayor a menor).
    
    -- El procedimiento retorna el código del empleado con la mayor comisión (ventas) en la variable de salida @vendedor.
    RETURN
END
GO

EXEC dbo.comisiones 1
SELECT * FROM Empleado ORDER BY empl_comision DESC
GO
---------------------------------------------------5---------------------------------------------------

/* 
Realizar un procedimiento que complete con los datos existentes en el modelo provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
    Create table Fact_table ( 
        anio char(4),
        mes char(2),
        familia char(3),
        rubro char(4),
        zona char(3),
        cliente char(6), 
        producto char(8), 
        cantidad decimal(12,2), 
        monto decimal(12,2)
    )
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/

---------------------------------------------------7---------------------------------------------------

/*
Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. 
Debe insertar una línea por cada artículo con los movimientos de stock generados por las ventas entre esas fechas. 
La tabla se encuentra creada y vacía.
    Código --> Código del articulo
    Detalle --> Detalle del articulo
    Cant. Mov. --> Cantidad de movimientos de ventas (Item factura)
    Precio de Venta --> Precio promedio de venta
    Renglón --> Nro. de línea de la tabla
    Ganancia --> Precio de Venta – Cantidad * Costo Actual
*/


---------------------------------------------------8---------------------------------------------------

/*
Realizar un procedimiento que complete la tabla Diferencias de precios, para los productos facturados que tengan composición y en los cuales el precio de facturación sea diferente al precio del cálculo de los precios unitarios por cantidad de sus componentes, se aclara que un producto que compone a otro, también puede estar compuesto por otros y así sucesivamente, la tabla se debe crear y está formada por las siguientes columnas:
    Código --> Código del articulo
    Detalle --> Detalle del articulo
    Cantidad --> Cantidad de productos que conforman el combo
    Precio_generado --> Precio que se compone a través de sus componentes
    Precio_facturado --> Precio del producto
*/

---------------------------------------------------9---------------------------------------------------

-- Crear el/los objetos de base de datos que ante alguna modificación de un ítem de factura de un artículo con composición realice el movimiento de sus correspondientes componentes.

---------------------------------------------------10---------------------------------------------------

--  Crear el/los objetos de base de datos que ante el intento de borrar un artículo verifique que no exista stock y si es así lo borre en caso contrario que emita un mensaje de error.

---------------------------------------------------11---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para que dado un código de empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o indirectamente). 
-- Solo contar aquellos empleados (directos o indirectos) que tengan un código mayor que su jefe directo.

-- SELECT empl_codigo, empl_jefe FROM Empleado ORDER BY empl_jefe

CREATE FUNCTION ContarEmpleadosBajo ( @CodigoEmpleado INT )
RETURNS INT
AS
BEGIN
    DECLARE @Conteo INT = 0;

    -- Contar empleados directos
    SELECT @Conteo = COUNT(*) FROM Empleado WHERE empl_jefe = @CodigoEmpleado

    -- Contar empleados indirectos --> Mis subordinados son jefes 
    SELECT @Conteo = @Conteo + COUNT(*) FROM Empleado e WHERE e.empl_jefe IN ( SELECT empl_codigo FROM Empleado WHERE empl_jefe = @CodigoEmpleado )
    RETURN @Conteo;
END
GO

SELECT dbo.ContarEmpleadosBajo(1) AS TotalEmpleadosACargo 
GO

---------------------------------------------------12---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para que nunca un producto pueda ser compuesto por sí mismo. 
-- Se sabe que en la actualidad dicha regla se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías. No se conoce la cantidad de niveles de composición existentes.

---------------------------------------------------13---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para implantar la siguiente regla “Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de sus empleados totales (directos + indirectos)”. 
-- Se sabe que en la actualidad dicha regla se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías

---------------------------------------------------14---------------------------------------------------

-- Agregar el/los objetos necesarios para que si un cliente compra un producto compuesto a un precio menor que la suma de los precios de sus componentes que imprima la fecha, que cliente, que productos y a qué precio se realizó la compra. 
-- No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes.

---------------------------------------------------15---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para que el objeto principal reciba un producto como parametro y retorne el precio del mismo.
-- Se debe prever que el precio de los productos compuestos sera la sumatoria de los componentes del mismo multiplicado por sus respectivas cantidades. 
-- No se conocen los nivles de anidamiento posibles de los productos. 
-- Se asegura que nunca un producto esta compuesto por si mismo a ningun nivel. 
-- El objeto principal debe poder ser utilizado como filtro en el where de una sentencia select.

---------------------------------------------------16---------------------------------------------------
---------------------------------------------------17---------------------------------------------------
---------------------------------------------------18---------------------------------------------------
---------------------------------------------------19---------------------------------------------------
---------------------------------------------------20---------------------------------------------------
---------------------------------------------------21---------------------------------------------------
---------------------------------------------------22---------------------------------------------------
---------------------------------------------------23---------------------------------------------------
---------------------------------------------------24---------------------------------------------------
---------------------------------------------------25---------------------------------------------------
---------------------------------------------------26---------------------------------------------------
---------------------------------------------------27---------------------------------------------------
---------------------------------------------------28---------------------------------------------------
---------------------------------------------------29---------------------------------------------------