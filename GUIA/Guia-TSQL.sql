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
        RAISERROR('NO SE PUEDEN BORRAR LOS PRODUCTOS CON STOCK', 16, 1)
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
    RETURN (SELECT isnull ( count(*) + sum(dbo.ej11(empl_codigo)), 0) FROM Empleado WHERE empl_jefe = @codigo)
END
GO

---------------------------------------------------12---------------------------------------------------

-- Cree el/los objetos de BD necesarios para que nunca un producto pueda ser compuesto por sí mismo. 
-- Se sabe que en la actualidad dicha regla se cumple y que la BD es accedida por n aplicaciones de diferentes tipos y tecnologías. 
-- No se conoce la cantidad de niveles de composición existentes.

CREATE TRIGGER NoCompuestoPorSiMismo ON Composicion INSTEAD OF INSERT, UPDATE -- Utilizamos INSTEAD OF para evitar tener un porducto compuesto por si mismo
AS
BEGIN
    DECLARE @comp_producto CHAR(8), @comp_componente CHAR(8);

    DECLARE cur CURSOR FOR SELECT comp_producto, comp_componente FROM inserted;
    OPEN cur;
    FETCH NEXT FROM cur INTO @comp_producto, @comp_componente;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Usar la función para verificar si hay ciclo
        IF dbo.ExisteCicloComposicion(@comp_producto, @comp_componente) = 1
        BEGIN
            RAISERROR ('Error: Un producto no puede componerse a sí mismo ni en niveles sucesivos.', 16, 1);
            ROLLBACK;
            RETURN;
        END;

        FETCH NEXT FROM cur INTO @comp_producto, @comp_componente;
    END;

    CLOSE cur;
    DEALLOCATE cur;

    -- Si todo está bien, realizar la inserción o actualización
    INSERT INTO Composicion (comp_producto, comp_componente)
    SELECT comp_producto, comp_componente FROM inserted;
END;
GO

CREATE FUNCTION ExisteCicloComposicion ( @producto CHAR(8), @componente CHAR(8)) 
RETURNS INT
AS
BEGIN
    DECLARE @hayCiclo INT = 0;
    -- Si el componente es el mismo producto, entonces hay ciclo
    IF ( @producto = @componente ) 
        SET @hayCiclo = 1;
    ELSE
    -- Recorrer la composición para ver si se llega al mismo producto
    BEGIN 
        DECLARE cur CURSOR LOCAL FOR SELECT comp_componente FROM Composicion WHERE comp_producto = @componente;
        DECLARE @subComponente CHAR(8);
        OPEN cur;
        FETCH NEXT FROM cur INTO @subComponente;
        WHILE @@FETCH_STATUS = 0 AND @hayCiclo = 0
        -- Llamada recursiva a la función
        BEGIN  
            SET @hayCiclo = dbo.fn_ExisteCicloComposicion(@producto, @subComponente);
            FETCH NEXT FROM cur INTO @subComponente;
        END;
        CLOSE cur;
        DEALLOCATE cur;
    END;

    RETURN @hayCiclo;
END;
GO

---------------------------------------------------13---------------------------------------------------

-- Cree el/los objetos de BD necesarios para implantar la siguiente regla:
-- “Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de sus empleados totales (directos + indirectos)”. 
-- Se sabe que en la actualidad dicha regla se cumple y que la BD es accedida por n aplicaciones de diferentes tipos y tecnologías

CREATE TRIGGER VerificarSalarioJefe ON empleado FOR UPDATE, DELETE 
AS
BEGIN
    IF ( SELECT count(*) FROM inserted i WHERE ( SELECT empl_salario FROM empleado WHERE empl_codigo = i.empl_jefe ) < dbo.CalcularSalarioTotal(i.empl_jefe) * 0.2 ) < 0
        begin    
            ROLLBACK
            PRINT('El salario de la suma de los empeados no puede ser menor al 20% del salario del jefe')        
        end    
    
    if ( SELECT count(*) FROM deleted d WHERE ( SELECT empl_salario FROM empleado WHERE empl_codigo = d.empl_jefe ) < dbo.CalcularSalarioTotal(i.empl_jefe) * 0.2 ) < 0
        begin    
            ROLLBACK
            PRINT('El salario de la suma de los empeados no puede ser menor al 20% del salario del jefe')        
        end    
END
GO

CREATE FUNCTION CalcularSalarioTotal ( @Codigo INT )
RETURNS DECIMAL(10, 2)
AS
BEGIN
    RETURN ( SELECT isnull ( SUM( empl_salario ) + SUM( dbo.CalcularSalarioTotal( empl_codigo ) ), 0 ) FROM Empleado WHERE empl_jefe = @Codigo )
END 
GO

---------------------------------------------------

SELECT dbo.CalcularSalarioTotal(2)  
GO

---------------------------------------------------14---------------------------------------------------

-- Agregar el/los objetos necesarios para que si un cliente compra un producto compuesto a un precio menor que la suma de los precios de sus componentes que imprima la fecha, que cliente, que productos y a qué precio se realizó la compra. 
-- No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes.

CREATE TRIGGER VerificacionPrecios ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
    DECLARE @item_producto char(8), @item_precio decimal(12,2), @item_cantidad decimal(12,2), @fact_fecha datetime, @fact_cliente char(4), @fact_tipo char(1), @fact_sucursal char(4), @fact_numero char(8)
    
    -- Declara un cursor con todos los productos que son compuestos con todos los datos que vamos a necesitar o que nos va a pedir mostrar
    DECLARE cur CURSOR FOR SELECT item_producto, item_precio, item_cantidad, fact_fecha, fact_cliente, fact_tipo, fact_sucursal, fact_numero 
						    FROM inserted
						    JOIN factura ON fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
						    WHERE item_producto IN ( SELECT comp_producto FROM Composicion) 
    OPEN cur
    FETCH NEXT FROM cur INTO @item_producto, @item_precio, @item_cantidad, @fact_fecha, @fact_cliente, @fact_tipo, @fact_sucursal, @fact_numero
    WHILE @@FETCH_STATUS = 0
	
    BEGIN 	
        DECLARE @sum_componentes decimal(12,2);

        SELECT @sum_componentes = SUM(comp_cantidad * prod_precio) FROM Composicion JOIN Producto ON comp_componente = prod_codigo WHERE comp_producto = @item_producto GROUP BY comp_producto 

        -- No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes
        IF ( ( @item_precio * @item_cantidad ) > ( @sum_componentes ) / 2 )
            RAISERROR('El precio es menor que la mitad de la suma de componentes para el producto: %s', 16, 1, @item_producto);

        -- Si un cliente compra un producto compuesto a un precio menor que la suma de los precios de sus componentes
        IF ( ( @item_precio * @item_cantidad ) < ( @sum_componentes ) )
            -- Imprima la fecha, que cliente, que productos y a qué precio se realizó la compra
            PRINT(@fact_fecha + @fact_cliente + @item_producto + @item_precio)

        INSERT item_factura VALUES ( @fact_tipo, @fact_sucursal, @fact_numero, @item_producto, @item_cantidad, @item_precio )
        FETCH NEXT FROM cur INTO @item_producto, @item_precio, @item_cantidad, @fact_fecha, @fact_cliente, @fact_tipo, @fact_sucursal, @fact_numero
    END
    CLOSE cur;
    DEALLOCATE cur;
END
GO

---------------------------------------------------15---------------------------------------------------

-- Cree el/los objetos de BD necesarios para que el objeto principal reciba un producto como parametro y retorne el precio del mismo.
-- Se debe prever que el precio de los productos compuestos sera la sumatoria de los componentes del mismo multiplicado por sus respectivas cantidades. 
-- No se conocen los nivles de anidamiento posibles de los productos. 
-- Se asegura que nunca un producto esta compuesto por si mismo a ningun nivel. 
-- El objeto principal debe poder ser utilizado como filtro en el where de una sentencia select.

CREATE FUNCTION CalcularPrecioProducto (@producto CHAR(8))
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @precio DECIMAL(18, 2) = 0;
    -- Compuesto
    IF EXISTS ( SELECT 1 FROM Composicion WHERE comp_producto = @producto )
    BEGIN
        DECLARE @componente CHAR(8), @cantidad INT, @comp_precio DECIMAL(18, 2)
        DECLARE cur CURSOR FOR ( SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @producto ) 
        OPEN cur
        FETCH NEXT FROM cur INTO @componente, @cantidad
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Llamada recursiva para obtener el precio del componente
            SET @comp_precio = dbo.CalcularPrecioProducto ( @componente ) * @cantidad;
            SET @precio += @comp_precio;
            FETCH NEXT FROM cur INTO @componente, @cantidad;
        END
        CLOSE cur
        DEALLOCATE cur
    END 
    -- Simple
    ELSE
        SELECT @precio = prod_precio FROM Producto WHERE @producto = prod_codigo;

    RETURN @precio;
END
GO

---------------------------------------------------

CREATE FUNCTION CalcularPrecioTotal ( @Producto char(8) )
RETURNS DECIMAL(10, 2)
AS
BEGIN
    RETURN (
            SELECT ISNULL ( 
                SUM ( prod_precio ) -- Si no tiene componentes
                + SUM ( dbo.CalcularSalarioTotal ( comp_componente ) -- Precio de los componentes
                ) , 0 ) 
            FROM Producto 
            JOIN Composicion ON comp_producto = prod_codigo
            WHERE prod_codigo = @Producto 
        )
END 
GO

---------------------------------------------------

SELECT dbo.CalcularPrecioProducto('00001104')  
GO -- 6.91

SELECT dbo.CalcularPrecioProducto('00000030')  
GO -- 24483.75

SELECT * FROM Producto
GO
---------------------------------------------------16---------------------------------------------------

-- Desarrolle el/los elementos de BD necesarios para que ante una venta automaticamante se descuenten del stock los articulos vendidos. 
-- Se descontaran del deposito que mas producto poseea y se supone que el stock se almacena tanto de productos simples como compuestos (si se acaba el stock de los compuestos no se arman combos)
-- En caso que no alcance el stock de un deposito se descontara del siguiente y asi hasta agotar los depositos posibles. 
-- En ultima instancia se dejara stock negativo en el ultimo deposito que se desconto.

ALTER TRIGGER DescontarStockEnVenta ON Item_factura INSTEAD OF INSERT
AS
BEGIN
    DECLARE @producto char(8), @cantidad decimal(12,2)
    DECLARE C_P CURSOR FOR SELECT item_producto, item_cantidad FROM inserted
    OPEN C_P
    FETCH NEXT FROM C_P INTO @producto, @cantidad
    WHILE @@FETCH_STATUS = 0
    
    -- Si es compuesto o no
    BEGIN
        IF EXISTS ( SELECT * FROM composicion WHERE comp_producto = @producto )
            -- CON COMPONENTES
            BEGIN
                DECLARE @componente char(8), @cantidadDelComponenete decimal (12,2)
                DECLARE C_PC CURSOR FOR SELECT comp_componente, ( comp_cantidad * @cantidad  ) FROM Composicion WHERE comp_producto = @producto 
                OPEN C_PC
                FETCH NEXT INTO @componente, @cantidadDelComponenete
                WHILE @@FETCH_STATUS = 0

                -- Descontar STOCK
                BEGIN
                    DECLARE @deposito CHAR(2), @depo_ant CHAR(2), @depo_cantidad DECIMAL (12,2)
                    DECLARE c_deposito CURSOR FOR SELECT stoc_deposito, stoc_Cantidad FROM stock WHERE @componente = stoc_producto AND stoc_cantidad > 0 ORDER BY stoc_cantidad DESC
                    OPEN c_deposito
                    FETCH NEXT INTO @deposito, @depo_cantidad
                    WHILE @@FETCH_STATUS = 0 and @cantidad > 0
                    
                    -- Bajar el stock de todos los depositos, hasta que concuerde con lo vendido
                    BEGIN
                        IF ( @depo_cantidad >= @cantidad ) -- Descuento completo del depósito actual
                            BEGIN
                                UPDATE stock SET stoc_cantidad = stoc_cantidad - @cantidad WHERE stoc_producto = @componente AND stoc_deposito = @deposito
                                SELECT @cantidad = 0
                            END

                        ELSE -- Descontar el stock disponible y continuar con el siguiente depósito
                            BEGIN 
                                UPDATE stock SET stoc_cantidad = stoc_cantidad - @depo_cantidad WHERE stoc_producto = @componente AND stoc_deposito = @deposito
                                SELECT @cantidad = @cantidad - @depo_cantidad
                                SELECT @depo_ant = @deposito
                            END

                        FETCH NEXT FROM c_deposito INTO @deposito, @depo_cantidad
                    END

                    IF ( @cantidad > 0 ) -- Si aún queda cantidad pendiente, permitir stock negativo en el último depósito utilizado
                        UPDATE Stock SET stoc_cantidad = stoc_cantidad - @depo_cantidad WHERE stoc_producto = @producto AND stoc_deposito = @depo_ant
                    
                    FETCH NEXT INTO @producto, @cantidad
                END

                CLOSE c_comp
                DEALLOCATE c_comp
            END
		
        ELSE
            -- SIN COMPONENTES
            -- Descontar STOCK
            BEGIN
                DECLARE c_deposito CURSOR FOR SELECT stoc_deposito, stoc_Cantidad FROM stock WHERE @producto = stoc_producto AND stoc_cantidad > 0 ORDER BY stoc_cantidad DESC
                OPEN c_deposito
                FETCH NEXT INTO @deposito, @depo_cantidad
                WHILE @@FETCH_STATUS = 0 and @cantidad > 0
                
                -- Bajar el stock de todos los depositos, hasta que concuerde con lo vendido
                BEGIN
                    IF ( @depo_cantidad >= @cantidad ) -- Descuento completo del depósito actual
                        BEGIN
                            UPDATE stock SET stoc_cantidad = stoc_cantidad - @cantidad WHERE stoc_producto = @componente AND stoc_deposito = @deposito
                            SELECT @cantidad = 0
                        END

                    ELSE -- Descontar el stock disponible y continuar con el siguiente depósito
                        BEGIN 
                            UPDATE stock SET stoc_cantidad = stoc_cantidad - @depo_cantidad WHERE stoc_producto = @componente AND stoc_deposito = @deposito
                            SELECT @cantidad = @cantidad - @depo_cantidad
                            SELECT @depo_ant = @deposito
                        END

                    FETCH NEXT FROM c_deposito INTO @deposito, @depo_cantidad
                END

                IF ( @cantidad > 0 ) -- Si aún queda cantidad pendiente, permitir stock negativo en el último depósito utilizado
                    UPDATE Stock SET stoc_cantidad = stoc_cantidad - @depo_cantidad WHERE stoc_producto = @producto AND stoc_deposito = @depo_ant
                    
                FETCH NEXT INTO @producto, @cantidad
                
	        END

    END
	CLOSE C_P
	DEALLOCATE C_P
END
GO

---------------------------------------------------17---------------------------------------------------

-- Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto que se debe almacenar en el deposito y que el stock maximo es la maxima 
-- cantidad de ese producto en ese deposito, cree el/los objetos de BD necesarios para que dicha regla de negocio se cumpla automaticamente. 
-- No se conoce la forma de acceso a los datos ni el procedimiento por el cual se incrementa o descuenta stock

CREATE TRIGGER puntoDeReposicion ON STOCK AFTER UPDATE, INSERT
AS
BEGIN    
    IF EXISTS ( SELECT * FROM STOCK WHERE ( stoc_punto_reposicion > stoc_cantidad ) OR ( stoc_cantidad > stoc_stock_maximo ) )
        PRINT ( ' Controlar el STOCK ')
END
GO
---------------------------------------------------18---------------------------------------------------

-- Sabiendo que el limite de credito de un cliente es el monto maximo que se le puede facturar mensualmente, cree el/los objetos de BD necesarios 
-- para que dicha regla de negocio se cumpla automaticamente. 
-- No se conoce la forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas

CREATE TRIGGER creditoCliente ON Factura INSTEAD OF UPDATE, INSERT
AS
BEGIN    
    DECLARE @cliente CHAR(4), @anio NUMERIC(4), @mes NUMERIC(2), @totalMensual DECIMAL(12,2)
    DECLARE C_CC CURSOR FOR SELECT fact_cliente, YEAR(fact_fecha), MONTH(fact_fecha), SUM(fact_total) FROM inserted GROUP BY fact_cliente, YEAR(fact_fecha), MONTH(fact_fecha)
    OPEN C_CC
    FETCH NEXT FROM C_CC INTO @cliente, @anio, @mes, @totalMensual
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF ( ( SELECT clie_limite_credito FROM Cliente WHERE clie_codigo = @cliente) < @totalMensual )
            PRINT ( 'No supereo el monto maximo que se le puede facturar mensualmente' )
        ELSE
            BEGIN
                PRINT ( 'Se supereo el monto maximo que se le puede facturar mensualmente' )
                CLOSE C_CC
                DEALLOCATE C_CC
                ROLLBACK
            END
        FETCH NEXT FROM C_CC INTO @cliente, @anio, @mes, @totalMensual
    END
    CLOSE C_CC
	DEALLOCATE C_CC
END
GO

---------------------------------------------------19---------------------------------------------------

-- Cree el/los objetos de BD necesarios para que se cumpla la siguiente regla de negocio automáticamente 
-- “Ningún jefe puede tener menos de 5 años de antigüedad y tampoco puede tener más del 50% del personal a su cargo (contando directos e indirectos) a excepción del gerente general”. 
-- Se sabe que en la actualidad la regla se cumple y existe un único gerente general.

CREATE TRIGGER nungunJefe ON Empleado AFTER UPDATE, INSERT, DELETE
AS
BEGIN
    IF EXISTS ( 
                SELECT * 
                FROM inserted i 
                JOIN empleado e ON e.empl_codigo = i.empl_jefe 
                WHERE e.empl_ingreso > ( GETDATE() - 365*5 ) 
                AND dbo.ej11(i.empl_jefe) > ( SELECT COUNT(empl_codigo)/2 FROM empleado )    
            )
        ROLLBACK    
    
    IF EXISTS ( 
                SELECT * 
                FROM inserted i 
                WHERE dbo.ej11(i.empl_jefe) > ( SELECT COUNT(empl_codigo)/2 FROM empleado ) 
            )
        ROLLBACK 
END
GO

---------------------------------------------------20---------------------------------------------------

-- Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del vendedor.
-- El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese vendedor en ese mes,
-- más un 3% adicional en caso de que ese vendedor haya vendido por lo menos 50 productos distintos en el mes.

CREATE TRIGGER comisionesActualizadas ON Factura FOR INSERT, DELETE
AS
BEGIN
    DECLARE @vendedor numeric (6), @anio numeric(4), @mes numeric (2)
    DECLARE C_F CURSOR FOR SELECT fact_vendedor, YEAR(fact_fecha), MONTH(fact_fecha) FROM inserted
    OPEN C_F
    FETCH NEXT FROM C_F
    WHILE @@FETCH_STATUS = 0
    BEGIN
        UPDATE empleado SET empl_comision = (
                                                SELECT SUM(fact_total) * 0.05 
                                                FROM Factura 
                                                WHERE fact_vendedor = @vendedor 
                                                AND YEAR ( fact_fecha ) = @anio 
                                                AND MONTH ( fact_fecha ) = @mes 
                                            ) WHERE empl_codigo = @vendedor
        
        IF ( -- Vendio mas de 50 prodcutos distintos ese mes
                SELECT COUNT( DISTINCT item_producto ) 
                FROM Factura 
                JOIN Item_factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                WHERE fact_vendedor = @vendedor 
                AND YEAR ( fact_fecha ) = @anio 
                AND MONTH ( fact_fecha ) = @mes 
            ) >=50

            UPDATE empleado SET empl_comision = ( 
                                                    SELECT SUM(fact_total) * 1.03 -- Agrego el 3%
                                                    FROM factura 
                                                    WHERE fact_vendedor = @vendedor 
                                                    AND YEAR ( fact_fecha ) = @anio 
                                                    AND MONTH ( fact_fecha ) = @mes 
                                                ) WHERE empl_codigo = @vendedor

        FETCH NEXT FROM C_F
    END
    CLOSE C_F
    DEALLOCATE C_F
END
GO

---------------------------------------------------21---------------------------------------------------

-- Desarrolle el/los elementos de BD necesarios para que se cumpla automaticamente la regla de que en una factura no puede contener productos de diferentes familias. 
-- En caso de que esto ocurra no debe grabarse esa factura y debe emitirse un error en pantalla.

CREATE TRIGGER VerificarFamiliaFactura ON Factura INSTEAD OF INSERT -- Utilizamos INSTEAD OF para evitar tener una factura con productos diferentes
AS
BEGIN
    IF EXISTS (
        SELECT fact_numero+fact_sucursal+fact_tipo , COUNT ( DISTINCT prod_familia ) 
        FROM inserted
        JOIN Item_Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
        JOIN Producto ON item_producto = prod_codigo
        GROUP BY fact_tipo, fact_sucursal, fact_numero
        HAVING COUNT( DISTINCT prod_familia) <> 1 -- Mas de una familia
    )
    BEGIN
        RAISERROR ('Error: La factura contiene productos de diferentes familias. No se permite la grabación.', 16, 1)
        ROLLBACK
    END
END
GO

---------------------------------------------------22---------------------------------------------------

-- Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro tenga más de 20 productos asignados, si un rubro tiene más de 20 productos asignados se 
-- deberan distribuir en otros rubros que no tengan mas de 20 productos y si no entran se debra crear un nuevo rubro en la misma familia con la descirpción “RUBRO REASIGNADO”, 
-- cree el/los objetos de BD necesarios para que dicha regla de negocio quede implementada.

IF OBJECT_ID('dbo.ReasignarProductos', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ReasignarProductos;
GO

CREATE PROCEDURE ReasignarProductos -- Para que dicha regla de negocio quede implementada --> Nunca dice que automaticamente
AS
BEGIN
    -- Existen rubros que tengan más de 20 productos asignados
    IF EXISTS ( SELECT rubr_id FROM Producto JOIN Rubro ON prod_rubro = rubr_id GROUP BY rubr_id HAVING COUNT (rubr_id) > 20 )
        BEGIN
            DECLARE @rubro_actual char(4), @cantidadDeProductos int
            DECLARE cur CURSOR FOR ( SELECT rubr_id, COUNT(*) FROM Producto JOIN Rubro ON prod_rubro = Rubro.rubr_id GROUP BY rubr_id HAVING COUNT (rubr_id) > 20 )
            OPEN cur
            FETCH NEXT FROM cur INTO @rubro_actual, @cantidadDeProductos
            WHILE @@FETCH_STATUS = 0

            BEGIN
                -- Reubicar productos de @rubro_actual en otros rubros que tengan menos de 20 productos
                DECLARE @producto char(8),  @cantidadProductosEnRubro int = @cantidadDeProductos
                DECLARE cur_productos CURSOR FOR ( SELECT prod_codigo FROM Producto WHERE prod_rubro = @rubro_actual )
                OPEN cur_productos
                FETCH NEXT FROM cur_productos INTO @producto
                WHILE @@FETCH_STATUS = 0 OR @cantidadProductosEnRubro < 21

                BEGIN
                    IF EXISTS ( SELECT TOP 1 rubr_id FROM Producto JOIN Rubro ON prod_rubro = rubr_id GROUP BY rubr_id HAVING COUNT(*) < 20 ORDER BY COUNT(*) ASC )
                        -- Actualizar el producto para asignarlo al nuevo rubro
                        UPDATE Producto SET prod_rubro = ( 
                                                            SELECT TOP 1 rubr_id
                                                            FROM Rubro
                                                            JOIN Producto ON prod_rubro = rubr_id
                                                            GROUP BY rubr_id
                                                            HAVING COUNT(*) < 20
                                                            ORDER BY COUNT(*) ASC
                                                        ) 
                        WHERE prod_codigo = @producto
                    
                    ELSE
                        BEGIN
                            IF NOT EXISTS ( SELECT rubr_id FROM Rubro WHERE rubr_detalle = 'Rubro reasignado' )  
                                INSERT INTO Rubro (RUBR_ID,rubr_detalle) VALUES ('xx','Rubro reasignado')
                        
                            UPDATE Producto SET prod_rubro = ( SELECT rubr_id FROM Rubro WHERE rubr_detalle = 'Rubro reasignado' ) WHERE prod_codigo = @producto
                        END

			        SET @cantidadProductosEnRubro -= 1 -- Cuando llegue a 20 paso al siguente rubro

                    FETCH NEXT FROM cur_productos INTO @producto
                END

                    CLOSE cur_productos
                    DEALLOCATE cur_productos
                    FETCH NEXT FROM cur INTO @rubro_actual
            END
            
            CLOSE cur
            DEALLOCATE cur
        END
END
GO

---------------------------------------------------23---------------------------------------------------

-- Desarrolle el/los elementos de BD necesarios para que ante una venta automaticamante se controle que en una misma factura no puedan venderse más de dos productos con composición. 
-- Si esto ocurre de bera rechazarse la factura.


CREATE TRIGGER NoProductosCompuestosCURSOR ON Factura INSTEAD OF INSERT -- Utilizamos INSTEAD OF para evitar tener una factura con +2 productos compuestos
AS
BEGIN
    DECLARE @tipo char(1), @sucursal char(4), @numero char(8), @producto char(8)
    DECLARE cursorProductos CURSOR FOR ( SELECT item_tipo, item_sucursal, item_numero, item_producto FROM inserted JOIN Item_Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero )
    OPEN cursorProductos
    FETCH NEXT FROM cursorProductos INTO @tipo, @sucursal, @numero, @producto
    WHILE @@FETCH_STATUS = 0
    -- Contar productos compuestos
    BEGIN
        DECLARE @countCompuestos int = 0
        IF EXISTS ( SELECT 1 FROM Composicion WHERE comp_producto = @producto )
            SET @countCompuestos = @countCompuestos + 1
    
        FETCH NEXT FROM cursorProductos INTO @tipo, @sucursal, @numero, @producto;
    END
    CLOSE cursorProductos
    DEALLOCATE cursorProductos

    -- Verificar si hay más de 2 productos compuestos
    IF ( @countCompuestos >= 2 ) 
        BEGIN
            DELETE FROM Item_factura WHERE item_tipo + item_sucursal + item_numero = @tipo + @sucursal + @numero -- Borro todos los renglones de la facura
            DELETE FROM Factura WHERE fact_tipo + fact_sucursal + fact_numero = @tipo + @sucursal + @numero -- Borro la factura
            RAISERROR ('Error: La factura contiene más de dos productos compuestos. No se permite la grabación.', 16, 1);
            ROLLBACK TRANSACTION;
        END
    
    ELSE
        -- Si no hay más de 2 productos compuestos, se permite la inserción
        BEGIN    
            INSERT INTO Factura
            SELECT * FROM inserted
        END
END
GO

---------------------------------------------------24---------------------------------------------------

-- Se requiere recategorizar los encargados asignados a los depositos. 
-- Para ello cree el o los objetos de BD necesarios que lo resueva, teniendo en cuenta que un deposito no puede tener como encargado un 
-- empleado que pertenezca a un departamento que no sea de la misma zona que el deposito, si esto ocurre a dicho deposito debera asignársele el empleado 
-- con menos depositos asignados que pertenezca a un departamento de esa zona.

---------------------------------------------------

-- Todos los depósitos que no tienen como encargado un empleado que pertenezca a un departamento que no sea de la misma zona que el deposito
SELECT depo_codigo 
FROM Empleado 
JOIN Departamento ON depa_codigo = empl_departamento 
JOIN DEPOSITO ON depo_encargado = empl_codigo 
WHERE depo_zona <> depa_zona
GO

-- Empleado con menos depositos asignados que pertenezca a un departamento de esa zona. 
SELECT TOP 1 empl_codigo
FROM Empleado 
JOIN Departamento ON depa_codigo = empl_departamento 
JOIN DEPOSITO ON depo_encargado = empl_codigo 
WHERE depo_zona = depa_zona 
GROUP BY empl_codigo
ORDER BY COUNT(depo_encargado)
GO

---------------------------------------------------

IF OBJECT_ID('dbo.recategorizar', 'P') IS NOT NULL
    DROP PROCEDURE dbo.recategorizar;
GO

CREATE PROCEDURE recategorizar
AS
BEGIN
    DECLARE @depo_codigo INT, @nuevo_encargado INT
    -- Todos los depósitos que no tienen como encargado un empleado que pertenezca a un departamento que no sea de la misma zona que el deposito
    DECLARE cur CURSOR FOR ( 
                                SELECT depo_codigo 
                                FROM Empleado 
                                JOIN Departamento ON depa_codigo = empl_departamento 
                                JOIN DEPOSITO ON depo_encargado = empl_codigo 
                                WHERE depo_zona <> depa_zona
                            )
    OPEN cur
    FETCH NEXT FROM cur INTO @depo_codigo
    WHILE @@FETCH_STATUS = 0

    BEGIN
        UPDATE DEPOSITO SET depo_encargado =  ( -- Empleado con menos depositos asignados que pertenezca a un departamento de esa zona. 
                                                SELECT TOP 1 empl_codigo
                                                FROM Empleado 
                                                JOIN Departamento ON depa_codigo = empl_departamento 
                                                WHERE depa_zona = ( SELECT depo_zona FROM DEPOSITO WHERE depo_codigo = @depo_codigo)
                                                GROUP BY empl_codigo 
                                                ORDER BY COUNT(*) ASC
                                            )
        WHERE depo_codigo = @depo_codigo

        FETCH NEXT FROM cur INTO @depo_codigo
    END

    CLOSE cur
    DEALLOCATE cu

END
GO       

---------------------------------------------------25---------------------------------------------------

-- Desarrolle el/los elementos de BD necesarios para que no se permita que la composición de los productos sea recursiva, o sea, que si el 
-- producto A compone al producto B, dicho producto B no pueda ser compuesto por el producto A, hoy la regla se cumple.

CREATE TRIGGER EvitarRecursividad ON Composicion INSTEAD OF INSERT, UPDATE -- Utilizamos INSTEAD OF para evitar tener un porducto compuesto por si mismo
AS
BEGIN
    DECLARE @ProductoPadre CHAR(8), @ProductoHijo CHAR(8)
    DECLARE cur CURSOR FOR ( SELECT comp_producto, comp_componente FROM inserted )
    OPEN cur
    FETCH NEXT FROM cur INTO @ProductoPadre, @ProductoHijo
    WHILE @@FETCH_STATUS = 0
    BEGIN
    -- Verificar si existe una relación inversa que causaría recursividad
        IF EXISTS ( SELECT * FROM Composiciones WHERE comp_producto = @ProductoHijo AND comp_componente = @ProductoPadre )
            BEGIN
                RAISERROR ('No se permite la composición recursiva de productos.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN
            END
        FETCH NEXT FROM cur INTO @ProductoPadre, @ProductoHijo
    END
    CLOSE cursor_comp
	DEALLOCATE cursor_comp
    
    -- Insertar si no hay recursividad
    INSERT INTO Composicion (comp_producto, comp_componente) SELECT @ProductoPadre, @ProductoHijo FROM inserted;
    
END
GO

---------------------------------------------------26---------------------------------------------------

-- Desarrolle el/los elementos de BD necesarios para que se cumpla automaticamente la regla de que una factura no puede contener productos 
-- que sean componentes de otros productos. 
-- En caso de que esto ocurra no debe grabarse esa factura y debe emitirse un error en pantalla.

CREATE TRIGGER EvitarProductosComponentesEnFactura ON Factura INSTEAD OF INSERT -- Utilizamos INSTEAD OF para evitar tener una factura contenga productos que sean componentes de otros productos
AS
BEGIN
    IF EXISTS (
        SELECT *
        FROM inserted
        JOIN Item_Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
        WHERE item_producto IN ( SELECT comp_componente FROM Composicion )
    )
    BEGIN
        DECLARE @NUMERO char(8),@SUCURSAL char(4),@TIPO char(1)
        DECLARE CURSORFacturas CURSOR FOR SELECT fact_numero,fact_sucursal,fact_tipo FROM inserted
        OPEN CURSORFacturas
        FETCH NEXT FROM CURSORFacturas INTO @NUMERO,@SUCURSAL,@TIPO
        WHILE @@FETCH_STATUS = 0
        
        BEGIN
            DELETE FROM Item_Factura WHERE item_numero + item_sucursal + item_tipo = @NUMERO + @SUCURSAL + @TIPO
            DELETE FROM Factura WHERE fact_numero + fact_sucursal + fact_tipo = @NUMERO + @SUCURSAL + @TIPO
            
            FETCH NEXT FROM CURSORFacturas INTO @NUMERO, @SUCURSAL, @TIPO
        END
        
        CLOSE CURSORFacturas
        DEALLOCATE CURSORFacturas
        
        RAISERROR ('Error: La factura contiene productos que son componentes de otros productos. No se permite la grabación.', 16, 1)
        ROLLBACK
    END
END
GO

---------------------------------------------------27---------------------------------------------------

-- Se requiere reasignar los encargados de stock de los diferentes depósitos. 
-- Para ello se solicita que realice el o los objetos de BD necesarios para asignar a cada uno de los depósitos el encargado que le corresponda, 
-- entendiendo que el encargado que le corresponde es cualquier empleado que no es jefe y que no es vendedor, o sea, que no está asignado a ningun cliente, 
-- se deberán ir asignando tratando de que un empleado solo tenga un deposito asignado, en caso de no poder se irán aumentando la cantidad de depósitos
-- progresivamente para cada empleado.

---------------------------------------------------

-- El encargado que le corresponde es cualquier empleado que no es jefe y que no es vendedor
SELECT *
FROM Empleado
WHERE empl_codigo NOT IN ( SELECT empl_jefe FROM Empleado WHERE empl_jefe IS NOT NULL GROUP BY empl_jefe )
AND empl_codigo NOT IN ( SELECT fact_vendedor FROM Factura WHERE fact_vendedor IS NOT NULL  GROUP BY fact_vendedor )
GO

---------------------------------------------------

CREATE PROCEDURE ReasignarEncargadosDepositos
AS
BEGIN
    DECLARE @deposito char(2)
    DECLARE curDepositos CURSOR FOR ( SELECT depo_codigo FROM Deposito )
    OPEN curDepositos
    FETCH NEXT FROM curDepositos INTO @deposito
    WHILE @@FETCH_STATUS = 0
    
    BEGIN
        UPDATE Deposito SET depo_encargado = ( -- El empleado qeu menos depositos tenga a su cargo
                                                SELECT TOP 1 empl_codigo 
                                                FROM Empleado
                                                LEFT JOIN DEPOSITO ON depo_encargado = empl_codigo
                                                WHERE empl_codigo NOT IN ( SELECT empl_jefe FROM Empleado WHERE empl_jefe IS NOT NULL ) -- No es jefe
                                                AND empl_codigo NOT IN ( SELECT clie_vendedor FROM Cliente WHERE clie_vendedor IS NOT NULL ) -- No es vendedor
                                                GROUP BY empl_codigo
                                                ORDER BY COUNT ( depo_encargado ) ASC
                                            ) 
        WHERE depo_codigo = @deposito
        FETCH NEXT FROM curDepositos INTO @deposito
    END

    CLOSE curDepositos
    DEALLOCATE curDepositos
END
GO

---------------------------------------------------28---------------------------------------------------

-- Se requiere reasignar los vendedores a los clientes. 
-- Para ello se solicita que realice el o los objetos de BD necesarios para asignar a cada uno de los clientes el vendedor que le corresponda, 
-- entendiendo que el vendedor que le corresponde es aquel que le vendió más facturas a ese cliente, si en particular un cliente no tiene facturas compradas 
-- se le deberá asignar el vendedor con más venta de la empresa, o sea, el que en monto haya vendido más.

CREATE PROCEDURE ReasignarVendedoresAClientes
AS
BEGIN
    DECLARE @cliente char(8)
    DECLARE curClientes CURSOR FOR ( SELECT clie_codigo FROM Cliente )
    OPEN curClientes
    FETCH NEXT FROM curClientes INTO @cliente
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS ( SELECT * FROM Factura WHERE fact_cliente = @cliente )
            UPDATE Cliente
            SET clie_vendedor = ( -- El vendedor que le corresponde es aquel que le vendió más facturas a ese cliente
                                    SELECT TOP 1 fact_vendedor
                                    FROM Factura
                                    WHERE fact_cliente = @cliente
                                    GROUP BY fact_vendedor
                                    ORDER BY COUNT( fact_vendedor ) DESC
                                )
            WHERE clie_codigo = @cliente
        
        ELSE
            UPDATE Cliente
            SET clie_vendedor = (  -- Asignar el vendedor con mayor monto total en ventas
                                    SELECT TOP 1 fact_vendedor
                                    FROM Factura
                                    GROUP BY fact_vendedor
                                    ORDER BY SUM (fact_total) DESC
                                )
            WHERE clie_codigo = @cliente

        FETCH NEXT FROM curClientes INTO @cliente
    END

    CLOSE curClientes
    DEALLOCATE curClientes
END
GO

---------------------------------------------------29---------------------------------------------------

-- Desarrolle el/los elementos de BD necesarios para que se cumpla automaticamente la regla de que una factura no puede contener productos que 
-- sean componentes de diferentes productos. 
-- En caso de que esto ocurra no debe grabarse esa factura y debe emitirse un error en pantalla.

CREATE TRIGGER VerificarComponentesMultiples ON Factura INSTEAD OF INSERT 
AS
BEGIN
-- Una factura no puede contener productos que sean componentes de diferentes productos. 
    IF EXISTS (
        SELECT *
        FROM inserted
        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        WHERE item_producto IN (
                                    SELECT comp_componente 
                                    FROM Composicion 
                                    GROUP BY comp_componente 
                                    HAVING COUNT ( DISTINCT comp_producto ) > 2 -- Ningun componente aparece en 2 productos
                                )
    )
    BEGIN
        DECLARE @NUMERO char(8), @SUCURSAL char(4), @TIPO char(1)
        DECLARE CURSORFacturas CURSOR FOR ( SELECT fact_numero, fact_sucursal, fact_tipo FROM inserted )
        OPEN CURSORFacturas
        FETCH NEXT FROM CURSORFacturas INTO @NUMERO,@SUCURSAL,@TIPO
        WHILE @@FETCH_STATUS = 0
        
        BEGIN
            DELETE FROM Item_Factura WHERE item_numero + item_sucursal + item_tipo = @NUMERO + @SUCURSAL + @TIPO
            DELETE FROM Factura WHERE fact_numero + fact_sucursal + fact_tipo = @NUMERO + @SUCURSAL + @TIPO
            
            FETCH NEXT FROM CURSORFacturas INTO @NUMERO, @SUCURSAL, @TIPO
        END
        
        CLOSE CURSORFacturas
        DEALLOCATE CURSORFacturas
        
        RAISERROR ('Error: La factura contiene productos que son componentes de otros productos. No se permite la grabación.', 16, 1)
        ROLLBACK
    END
END
GO

---------------------------------------------------30---------------------------------------------------

-- Agregar el/los objetos necesarios para crear una regla por la cual un cliente no pueda comprar más de 100 unidades en el mes de ningún producto, 
-- si esto ocurre no se deberá ingresar la operación y se deberá emitir un mensaje “Se ha superado el límite máximo de compra de un producto”. 
-- Se sabe que esta regla se cumple y que las facturas no pueden ser modificadas.

CREATE TRIGGER LimiteMensualCompraProducto ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
-- Un cliente no pueda comprar más de 100 unidades en el mes de ningún producto
    IF EXISTS (
        SELECT fact_cliente, item_producto , SUM (item_cantidad), MONTH( fact_fecha )
        FROM inserted
        JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        GROUP BY fact_cliente , item_producto , MONTH( fact_fecha )
        HAVING SUM (item_cantidad) > 100
    )
    BEGIN
        DECLARE @NUMERO char(8), @SUCURSAL char(4), @TIPO char(1)
        DECLARE CURSORFacturas CURSOR FOR ( SELECT item_numero, item_sucursal, item_tipo FROM inserted )
        OPEN CURSORFacturas
        FETCH NEXT FROM CURSORFacturas INTO @NUMERO,@SUCURSAL,@TIPO
        WHILE @@FETCH_STATUS = 0
        
        BEGIN
            DELETE FROM Item_Factura WHERE item_numero + item_sucursal + item_tipo = @NUMERO + @SUCURSAL + @TIPO
            DELETE FROM Factura WHERE fact_numero + fact_sucursal + fact_tipo = @NUMERO + @SUCURSAL + @TIPO
            
            FETCH NEXT FROM CURSORFacturas INTO @NUMERO, @SUCURSAL, @TIPO
        END
        
        CLOSE CURSORFacturas
        DEALLOCATE CURSORFacturas
        
        RAISERROR ('Se ha superado el límite máximo de compra de un producto', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
END
GO

---------------------------------------------------31---------------------------------------------------

-- Desarrolle el o los objetos de BD necesarios, para que un jefe no pueda tener más de 20 empleados a cargo, directa o indirectamente, 
-- si esto ocurre debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para asignarle se le deberá colocar como jefe al gerente 
-- general que es aquel que no tiene jefe.

CREATE PROCEDURE ReasignarEmpleados
AS
BEGIN
    -- Verificar si algún jefe excede los 20 empleados a cargo
    IF EXISTS ( SELECT empl_codigo FROM Empleado WHERE dbo.ContarEmpleados(empl_codigo) > 20 )
        
        BEGIN
            DECLARE @JefeExcedente NUMERIC(6), @Empleado NUMERIC(6), @NuevoJefe NUMERIC(6), @cantidad int
            DECLARE CursorJefesExcedentes CURSOR FOR ( SELECT empl_codigo FROM Empleado WHERE dbo.ContarEmpleados(empl_codigo) > 20 ) -- Definir un cursor para iterar sobre los jefes que exceden el límite de empleados
            OPEN CursorJefesExcedentes
            FETCH NEXT FROM CursorJefesExcedentes INTO @JefeExcedente, @cantidad
            WHILE @@FETCH_STATUS = 0
            
            BEGIN
                DECLARE @cantidadEmpleados int = @cantidad
                DECLARE CursorEmpleados CURSOR FOR ( SELECT empl_codigo, COUNT(*)  FROM Empleado WHERE empl_jefe = @JefeExcedente GROUP BY empl_codigo ) -- Crear un cursor para los empleados del jefe excedente
                OPEN CursorEmpleados
                FETCH NEXT FROM CursorEmpleados INTO @Empleado
                WHILE @@FETCH_STATUS = 0 OR @cantidadEmpleados < 21
                
                BEGIN
                    -- Buscar un jefe alternativo con menos de 20 empleados
                    SELECT TOP 1 @NuevoJefe = empl_codigo
                    FROM Empleado
                    WHERE empl_codigo IN (SELECT empl_jefe FROM Empleado)
                    AND dbo.ContarEmpleados(empl_codigo) < 20
                    ORDER BY dbo.ContarEmpleados(empl_codigo) ASC

                    -- Si no se encuentra un jefe con capacidad, asignar al gerente general (sin jefe asignado)
                    IF ( @NuevoJefe IS NULL )
                        SELECT TOP 1 @NuevoJefe = empl_codigo FROM Empleado WHERE empl_jefe IS NULL
                        
                    -- Actualizar el jefe del empleado
                    UPDATE Empleado SET empl_jefe = @NuevoJefe WHERE empl_codigo = @Empleado

                    SET @cantidadEmpleados -= 1 

                    FETCH NEXT FROM CursorEmpleados INTO @Empleado;
                END

                CLOSE CursorEmpleados
                DEALLOCATE CursorEmpleados

                FETCH NEXT FROM CursorJefesExcedentes INTO @JefeExcedente
            END

            CLOSE CursorJefesExcedentes
            DEALLOCATE CursorJefesExcedentes
        END
END
GO




IF OBJECT_ID('dbo.ReasignarEmpleados', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ReasignarEmpleados;
GO

CREATE PROCEDURE ReasignarProductos -- Para que dicha regla de negocio quede implementada --> Nunca dice que automaticamente
AS
BEGIN
    -- Existen rubros que tengan más de 20 productos asignados
    IF EXISTS ( SELECT rubr_id FROM Producto JOIN Rubro ON prod_rubro = rubr_id GROUP BY rubr_id HAVING COUNT (rubr_id) > 20 )
        BEGIN
            DECLARE @rubro_actual char(4), @cantidadDeProductos int
            DECLARE cur CURSOR FOR ( SELECT rubr_id, COUNT(*) FROM Producto JOIN Rubro ON prod_rubro = Rubro.rubr_id GROUP BY rubr_id HAVING COUNT (rubr_id) > 20 )
            OPEN cur
            FETCH NEXT FROM cur INTO @rubro_actual, @cantidadDeProductos
            WHILE @@FETCH_STATUS = 0

            BEGIN
                -- Reubicar productos de @rubro_actual en otros rubros que tengan menos de 20 productos
                DECLARE @producto char(8),  @cantidadProductosEnRubro int = @cantidadDeProductos
                DECLARE cur_productos CURSOR FOR ( SELECT prod_codigo FROM Producto WHERE prod_rubro = @rubro_actual )
                OPEN cur_productos
                FETCH NEXT FROM cur_productos INTO @producto
                WHILE @@FETCH_STATUS = 0 OR @cantidadProductosEnRubro < 21

                BEGIN
                    IF EXISTS ( SELECT TOP 1 rubr_id FROM Producto JOIN Rubro ON prod_rubro = rubr_id GROUP BY rubr_id HAVING COUNT(*) < 20 ORDER BY COUNT(*) ASC )
                        -- Actualizar el producto para asignarlo al nuevo rubro
                        UPDATE Producto SET prod_rubro = ( 
                                                            SELECT TOP 1 rubr_id
                                                            FROM Rubro
                                                            JOIN Producto ON prod_rubro = rubr_id
                                                            GROUP BY rubr_id
                                                            HAVING COUNT(*) < 20
                                                            ORDER BY COUNT(*) ASC
                                                        ) 
                        WHERE prod_codigo = @producto
                    
                    ELSE
                        BEGIN
                            IF NOT EXISTS ( SELECT rubr_id FROM Rubro WHERE rubr_detalle = 'Rubro reasignado' )  
                                INSERT INTO Rubro (RUBR_ID,rubr_detalle) VALUES ('xx','Rubro reasignado')
                        
                            UPDATE Producto SET prod_rubro = ( SELECT rubr_id FROM Rubro WHERE rubr_detalle = 'Rubro reasignado' ) WHERE prod_codigo = @producto
                        END

			        SET @cantidadProductosEnRubro -= 1 -- Cuando llegue a 20 paso al siguente rubro

                    FETCH NEXT FROM cur_productos INTO @producto
                END

                    CLOSE cur_productos
                    DEALLOCATE cur_productos
                    FETCH NEXT FROM cur INTO @rubro_actual
            END
            
            CLOSE cur
            DEALLOCATE cur
        END
END
GO

/*
DECLARE Employee_Cursor CURSOR FOR SELECT LastName, FirstName FROM Employees
OPEN Employee_Cursor
FETCH NEXT FROM Employee_Cursor
WHILE @@FETCH_STATUS = 0
BEGIN
    FETCH NEXT FROM Employee_Cursor
END
CLOSE Employee_Cursor
DEALLOCATE Employee_Cursor
*/