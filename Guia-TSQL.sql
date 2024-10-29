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
    DECLARE @stoc_cantidad NUMERIC(12,2), @stock_maximo NUMERIC(12,2), @respuesta VARCHAR(50)

    -- Los valores que necesito para saber si esta lleno
    SELECT @stoc_cantidad = STOCK.stoc_cantidad, @stock_maximo = STOCK.stoc_stock_maximo FROM STOCK WHERE STOCK.stoc_producto = @articulo and STOCK.stoc_deposito = @deposito

    IF @stock_maximo IS NULL OR @stoc_cantidad >= @stock_maximo
        SET @respuesta = 'DEPOSITO COMPLETO'
    ELSE
        SET @respuesta = 'OCUPACION DEL DEPOSITO '+ @deposito + STR( @stoc_cantidad / @stock_maximo * 100 ) + ' %'
    RETURN @respuesta
END 
GO

---------------------------------------------------

SELECT stoc_producto, stoc_deposito, stoc_cantidad, stoc_stock_maximo, DBO.estadoDelDeposito( stoc_producto , stoc_deposito ) 
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
    DECLARE @stoc_actual NUMERIC(12,2), @vendido NUMERIC(12,2)
    
    -- Los que tengo
    SELECT @stoc_actual = ISNULL ( SUM ( stoc_cantidad ), 0) FROM STOCK WHERE stoc_producto = @articulo
    
    -- Los que vendi
    SELECT @vendido = ISNULL ( SUM ( item_cantidad ) , 0 )
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
    ( -- Los que tengo
        SELECT ISNULL ( SUM ( stoc_cantidad  ) , 0 ) FROM STOCK WHERE stoc_producto = @articulo
    )
    +
    ( -- Los que vendi
        SELECT  ISNULL ( SUM ( item_cantidad ) , 0 )  
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

-- Cree el/los objetos de BD necesarios para corregir la tabla empleado en caso que sea necesario. 
-- Se sabe que debería existir un único gerente general (debería ser el único empleado sin jefe). 
-- Si detecta que hay más de un empleado sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por mayor salario. 
-- Si hay más de uno se seleccionara el de mayor antigüedad en la empresa. 
-- Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad de empleados que había sin jefe antes de la ejecución.

-- 1. Que objeto voy a tener que crear?? 
    --> Modificar datos => Procedimiento / Trigger
    --> Ejecutar en un momento determinado que NO depende de un evento => Procedimiento

-- 2. Necesitamos parametros?? 
    --> Como un porcedimiento no puede retornar valores vamos a tener que crear una variable que simbolice nuestro resultado

CREATE PROCEDURE UnicoGerenteGeneral @cantidad INT OUTPUT
AS
BEGIN
  
RETURN
END
GO

---------------------------------------------------

EXEC dbo.UnicoGerenteGeneral 1
SELECT * FROM Empleado ORDER BY empl_comision DESC
GO

---------------------------------------------------4---------------------------------------------------

-- Cree el/los objetos de BDD necesarios para actualizar la columna de empleado empl_comision con la sumatoria del total de lo vendido por ese empleado a lo largo del último año. 
-- Se deberá retornar el código del vendedor que más vendió (en monto) a lo largo del último año.

CREATE PROCEDURE comisiones @vendedor numeric(6) OUTPUT
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
                            AND YEAR(fact_fecha) = ( SELECT MAX(YEAR(fact_fecha)) FROM Factura ) -- Se obtiene el último año en el que se registraron facturas.
                        )
    
    -- Luego de actualizar la columna 'empl_comision' con las ventas del último año,
    -- se selecciona el código del empleado que más vendió, basándonos en la comisión calculada.
    SELECT TOP 1 @vendedor = empl_codigo FROM Empleado ORDER BY empl_comision DESC  -- Se ordenan los empleados por comisión en orden descendente (de mayor a menor).
    
    -- El procedimiento retorna el código del empleado con la mayor comisión (ventas) en la variable de salida @vendedor.
    RETURN
END
GO

---------------------------------------------------

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

CREATE PROCEDURE Fact_table 
AS
BEGIN 
    -- Si existe se borra, para poder volver a ejecutarse
    DROP TABLE fact_table 

    -- Crea la tabla con la estructura del enunciado
    CREATE TABLE Fact_table(  
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
    
    -- Inserta los valores requeridos
    INSERT Fact_table  
        SELECT year(fact_fecha),
                month(fact_fecha), 
                prod_familia, 
                prod_rubro, 
                depa_zona, 
                fact_cliente, 
                prod_codigo, 
                sum(item_cantidad), 
                sum(item_precio * item_cantidad)
    from item_factura 
    join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
    join Producto on prod_codigo = item_producto 
    join Empleado on empl_codigo = fact_vendedor 
    join Departamento on depa_codigo = empl_departamento
    group by year(fact_fecha), month(fact_fecha), prod_familia, prod_rubro, depa_zona, fact_cliente, prod_codigo
RETURN
END
GO

---------------------------------------------------7---------------------------------------------------

/*
Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. 
Debe insertar una línea por cada artículo  /* CURSOR */ con los movimientos de stock generados por las ventas entre esas fechas. 
La tabla se encuentra creada y vacía.
    Código --> Código del articulo
    Detalle --> Detalle del articulo
    Cant. Mov. --> Cantidad de movimientos de ventas (Item factura)
    Precio de Venta --> Precio promedio de venta
    Renglón --> Nro. de línea de la tabla
    Ganancia --> Precio de Venta – Cantidad * Precio
*/

CREATE PROCEDURE Venta 
AS
BEGIN 
    -- Si existe se borra, para poder volver a ejecutarse
    DROP TABLE IF EXISTS Vent 

    -- Crea la tabla con la estructura del enunciado
    CREATE TABLE Vent( codigo char(8), detalle char(30), cant_movimientos int, precio_venta decimal(12,2), renglon int, ganancia numeric(12,2) )
    
    -- Declaración de variables
    DECLARE @codigo char(8), @detalle char(30), @cant_movimientos int, @precio_venta decimal(12,2), @renglon int, @ganancia numeric(12,2)
    
    -- Definición del cursor para iterar sobre los productos y sus ventas
    DECLARE cventas CURSOR FOR SELECT prod_codigo, 
                                        prod_detalle, 
                                        COUNT ( DISTINCT (item_numero + item_sucursal + item_tipo ) ), 
                                        AVG ( item_precio ), 
                                        SUM ( ( item_precio * item_cantidad ) - ( item_cantidad * prod_precio ) ) 
                    FROM Producto
                    JOIN Item_Factura ON item_producto = prod_codigo
                    GROUP BY prod_codigo, prod_detalle

    /* Abrir el cursor */ OPEN cventas
    /* Inicializar el contador de renglones */ SELECT @renglon = 1
    /* Obtener la primera fila del cursor */ FETCH NEXT FROM cventas INTO @codigo, @detalle, @cant_movimientos, @precio_venta, @ganancia

    /* Bucle para recorrer el cursor */
    WHILE @@FETCH_STATUS = 0
    BEGIN
        /* Insertar los valores en la tabla Ventas */ INSERT INTO Vent VALUES ( @codigo, @detalle, @cant_movimientos, @precio_venta, @renglon, @ganancia )
        /* Incrementar el número de renglón */ SELECT @renglon = @renglon + 1;
        /*  Obtener la siguiente fila del cursor */ FETCH NEXT FROM cventas INTO @codigo, @detalle, @cant_movimientos, @precio_venta, @ganancia
    END
    /* Cerrar y desasignar el cursor */
    CLOSE cventas
    DEALLOCATE cventas
RETURN
END
GO
---------------------------------------------------8---------------------------------------------------

/*
Realizar un procedimiento que complete la tabla Diferencias de precios, para los productos facturados que tengan composición y en los cuales el precio de 
facturación sea diferente al precio del cálculo de los precios unitarios por cantidad de sus componentes, se aclara que un producto que compone a otro, 
también puede estar compuesto por otros y así sucesivamente, la tabla se debe crear y está formada por las siguientes columnas:

    Código --> Código del articulo
    Detalle --> Detalle del articulo
    Cantidad --> Cantidad de productos que conforman el combo
    Precio_generado --> Precio que se compone a través de sus componentes
    Precio_facturado --> Precio del producto
*/

CREATE PROCEDURE DiferenciasDePrecios 
AS
BEGIN 
    -- Si existe se borra, para poder volver a ejecutarse
    DROP TABLE IF EXISTS Diferencias_de_precios 

    -- Crea la tabla con la estructura del enunciado
    CREATE TABLE Diferencias_de_precios( codigo char(8), detalle char(30), cantidad int, precio_generado decimal(12,2), precio_facturado decimal(12,2) )
    
    -- Declaración de variables
    DECLARE @codigo char(8), @detalle char(30), @cantidad int, @precio_generado decimal(12,2), @precio_facturado decimal(12,2)
    
    -- Definición del cursor para iterar 
    DECLARE c1 CURSOR FOR SELECT P.prod_codigo, P.prod_detalle, COUNT ( DISTINCT COMBO.comp_componente ), SUM ( COMBO.comp_cantidad * COMPONENTE.prod_precio ), P.prod_precio
                            FROM Producto P
                            JOIN Composicion COMBO ON P.prod_codigo = COMBO.comp_producto
                            JOIN Producto COMPONENTE ON COMBO.comp_componente = COMPONENTE.prod_codigo -- Precio de los componentes
                            GROUP BY P.prod_codigo, P.prod_detalle, P.prod_precio
                            ORDER BY P.prod_codigo

    /* Abrir el cursor */ OPEN c1
    /* Obtener la primera fila del cursor */ FETCH NEXT FROM c1 INTO @codigo, @detalle, @cantidad, @precio_generado, @precio_facturado

    /* Bucle para recorrer el cursor */
    WHILE @@FETCH_STATUS = 0
    BEGIN
        /* Insertar los valores en la tabla */ INSERT INTO Diferencias_de_precios VALUES ( @codigo, @detalle, @cantidad, @precio_generado, @precio_facturado )
        /*  Obtener la siguiente fila del cursor */ FETCH NEXT FROM c1 INTO @codigo, @detalle, @cantidad, @precio_generado, @precio_facturado
    END
    /* Cerrar y desasignar el cursor */
    CLOSE c1
    DEALLOCATE c1
RETURN
END
GO

---------------------------------------------------9---------------------------------------------------

-- Crear el/los objetos de BD que ante alguna modificación de un ítem de factura de un artículo con composición realice el movimiento de sus correspondientes componentes.

CREATE TRIGGER  modificacionItemFactura ON Item_Factura FOR INSERT, DELETE
AS
BEGIN
    DECLARE @producto char(8), @cantidad numeric(12,2), @deposito char(2)
    -- Caso INSERT
    IF EXISTS ( SELECT 1 FROM inserted ) 
    BEGIN
        -- Cursor para obtener componentes y cantidades vendidas para actualizar stock
        DECLARE cur_insert CURSOR FOR SELECT comp_componente, ( comp_cantidad * item_cantidad ) FROM inserted JOIN Composicion ON item_producto = comp_producto
        OPEN cur_insert
        FETCH cur_insert INTO @producto, @cantidad
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Seleccionar el depósito con la mayor cantidad disponible para reducir el stock
            SELECT TOP 1 @deposito = stoc_deposito FROM STOCK WHERE stoc_producto = @producto ORDER BY stoc_cantidad DESC
            -- Actualizar la cantidad en el depósito seleccionado
            UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad WHERE stoc_producto = @producto AND stoc_deposito = @deposito
            FETCH cur_insert INTO @producto, @cantidad
        END
        CLOSE cur_insert
        DEALLOCATE cur_insert
    END

    -- Caso DELETE
    IF EXISTS ( SELECT 1 FROM deleted )
    BEGIN
        -- Cursor para obtener componentes y cantidades devultas para actualizar stock
        DECLARE cur_delete CURSOR FOR SELECT comp_componente, ( comp_cantidad * item_cantidad ) FROM inserted JOIN Composicion ON item_producto = comp_producto
        OPEN cur_delete
        FETCH cur_delete INTO @producto, @cantidad
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Seleccionar el depósito con la menor cantidad disponible para aumentar el stock
            SELECT TOP 1 @deposito = stoc_deposito FROM STOCK WHERE stoc_producto = @producto ORDER BY stoc_cantidad ASC
            -- Actualizar la cantidad en el depósito seleccionado
            UPDATE STOCK SET stoc_cantidad = stoc_cantidad + @cantidad WHERE stoc_producto = @producto AND stoc_deposito = @deposito
            FETCH cur_delete INTO @producto, @cantidad
        END
        CLOSE cur_delete
        DEALLOCATE cur_delete
    END
END
GO

---------------------------------------------------10---------------------------------------------------

--  Crear el/los objetos de BD que ante el intento de borrar un artículo verifique que no exista stock y si es así lo borre en caso contrario que emita un mensaje de error.

CREATE TRIGGER BorrarArticulo ON Producto INSTEAD OF DELETE -- Utilizamos INSTEAD OF para evitar la eliminación si hay stock
AS
BEGIN -- Verificamos si el artículo a borrar tiene stock
    IF EXISTS ( SELECT * FROM deleted JOIN STOCK ON prod_codigo = stoc_producto WHERE stoc_cantidad > 0 ) -- lo tiene
        RAISERROR('NO SE PUEDEN BORRAR LOS PRODUCTOS CON STOCK')
    ELSE
    BEGIN -- no lo tiene
        DELETE FROM Producto WHERE prod_codigo IN (SELECT prod_codigo FROM deleted);
    END
END 
GO

---------------------------------------------------11---------------------------------------------------

-- Cree el/los objetos de BD necesarios para que dado un código de empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o indirectamente). 
-- Solo contar aquellos empleados (directos o indirectos) que tengan un código mayor que su jefe directo.

-- SELECT empl_codigo, empl_jefe FROM Empleado ORDER BY empl_jefe

CREATE FUNCTION ContarEmpleados ( @JefeCodigo INT )
RETURNS INT
AS
BEGIN
    DECLARE @TotalEmpleados INT = 0;
    DECLARE @EmpCodigo INT;

    DECLARE empleado_cursor CURSOR FOR SELECT empl_codigo FROM Empleado WHERE empl_jefe = @JefeCodigo -- Cursor para recorrer empleados 
    OPEN empleado_cursor; 
    FETCH empleado_cursor INTO @EmpCodigo -- Obtener el primer empleado
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TotalEmpleados = @TotalEmpleados + 1 -- Contar el empleado actual
        SET @TotalEmpleados = @TotalEmpleados + dbo.ContarEmpleados(@EmpCodigo) -- Llamar a la función recursivamente para contar empleados a cargo del empleado actual
        FETCH empleado_cursor INTO @EmpCodigo -- Obtener el siguiente empleado
    END

    CLOSE empleado_cursor;
    DEALLOCATE empleado_cursor;
    RETURN @TotalEmpleados;
END
GO

---------------------------------------------------

SELECT dbo.ContarEmpleados(1) AS TotalEmpleadosACargo 
GO

---------------------------------------------------

CREATE FUNCTION ej11b (@codigo NUMERIC(6))
RETURNS INT
AS 
BEGIN
    RETURN (SELECT isnull(count(*) + sum(dbo.ej11(empl_codigo)), 0) FROM Empleado WHERE empl_jefe = @codigo)
END
GO

---------------------------------------------------12---------------------------------------------------

-- Cree el/los objetos de BD necesarios para que nunca un producto pueda ser compuesto por sí mismo. 
-- Se sabe que en la actualidad dicha regla se cumple y que la BD es accedida por n aplicaciones de diferentes tipos y tecnologías. No se conoce la cantidad de niveles de composición existentes.

---------------------------------------------------13---------------------------------------------------

-- Cree el/los objetos de BD necesarios para implantar la siguiente regla “Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de sus empleados totales (directos + indirectos)”. 
-- Se sabe que en la actualidad dicha regla se cumple y que la BD es accedida por n aplicaciones de diferentes tipos y tecnologías

---------------------------------------------------14---------------------------------------------------

-- Agregar el/los objetos necesarios para que si un cliente compra un producto compuesto a un precio menor que la suma de los precios de sus componentes que imprima la fecha, que cliente, que productos y a qué precio se realizó la compra. 
-- No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes.

---------------------------------------------------15---------------------------------------------------

-- Cree el/los objetos de BD necesarios para que el objeto principal reciba un producto como parametro y retorne el precio del mismo.
-- Se debe prever que el precio de los productos compuestos sera la sumatoria de los componentes del mismo multiplicado por sus respectivas cantidades. 
-- No se conocen los nivles de anidamiento posibles de los productos. 
-- Se asegura que nunca un producto esta compuesto por si mismo a ningun nivel. 
-- El objeto principal debe poder ser utilizado como filtro en el where de una sentencia select.

---------------------------------------------------16---------------------------------------------------

-- Desarrolle el/los elementos de BD necesarios para que ante una venta automaticamante se descuenten del stock los articulos vendidos. 
-- Se descontaran del deposito que mas producto poseea y se supone que el stock se almacena tanto de productos simples como compuestos (si se acaba el stock de los compuestos no se arman combos)
-- En caso que no alcance el stock de un deposito se descontara del siguiente y asi hasta agotar los depositos posibles. 
-- En ultima instancia se dejara stock negativo en el ultimo deposito que se desconto.

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
---------------------------------------------------30---------------------------------------------------
---------------------------------------------------31---------------------------------------------------


/*
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
*/