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

create procedure ej4 @vendedor numeric(6) output
AS
BEGIN
    update Empleado 
    set empl_comision = (
                        select isnull ( sum ( fact_total ) , 0 ) 
                        from factura 
                        where fact_vendedor = empl_codigo 
                        AND year ( fact_fecha ) = ( select max ( year ( fact_fecha ) ) from factura ) 
                        )
    
    select TOP 1 @vendedor = empl_codigo from empleado order by empl_comision desc
    
    
    RETURN
END
go 

update empleado set empl_comision = 0

exec dbo.ej4 1

select * from empleado order by empl_comision desc 
go 

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
    drop table fact_table

    Create table Fact_table( 
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
Debe insertar una línea por cada artículo con los movimientos de stock generados por las ventas entre esas fechas. 
La tabla se encuentra creada y vacía.
    Código --> Código del articulo
    Detalle --> Detalle del articulo
    Cant. Mov. --> Cantidad de movimientos de ventas (Item factura)
    Precio de Venta --> Precio promedio de venta
    Renglón --> Nro. de línea de la tabla
    Ganancia --> Precio de Venta – Cantidad * Costo Actual
*/

CREATE PROCEDURE Ventas 
AS
BEGIN 

    -- Eliminar la tabla Ventas si existe
    DROP TABLE IF EXISTS Ventas
    
    -- Crear la tabla Ventas
    CREATE TABLE Ventas (
        articulo char(8),           -- Código del artículo
        detalle char(30),           -- Detalle del artículo
        cant_movimientos int,       -- Cantidad de movimientos de ventas (Item Factura)
        precio_venta decimal(12,2), -- Precio promedio de venta
        renglon int,                -- Número de línea de la tabla (PK)
        ganancia NUMERIC(12,2)      -- Precio de venta - Cantidad * Costo Actual
    )

    -- Declaración de variables
    DECLARE @articulo char(8), 
            @detalle char(30), 
            @cant_movimientos int, 
            @precio_venta decimal(12,2),
            @renglon int, 
            @ganancia NUMERIC(12,2)

    -- Definición del cursor para iterar sobre los productos y sus ventas
    DECLARE cventas CURSOR FOR 
    SELECT prod_codigo, 
           prod_detalle, 
           COUNT(DISTINCT (item_numero + item_sucursal + item_tipo)), 
           AVG(item_precio), 
           SUM((item_precio * item_cantidad) - (item_cantidad * prod_precio)) 
    FROM Producto
    JOIN Item_Factura ON item_producto = prod_codigo
    GROUP BY prod_codigo, prod_detalle

    -- Abrir el cursor
    OPEN cventas

    -- Inicializar el contador de renglones
    SELECT @renglon = 1

    -- Obtener la primera fila del cursor
    FETCH NEXT FROM cventas 
    INTO @articulo, @detalle, @cant_movimientos, @precio_venta, @ganancia

    -- Bucle para recorrer el cursor
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insertar los valores en la tabla Ventas
        INSERT INTO Ventas 
        VALUES ( @articulo, 
                @detalle, 
                @cant_movimientos, 
                @precio_venta, 
                @renglon, 
                @ganancia
            )

        -- Incrementar el número de renglón
        SELECT @renglon = @renglon + 1;

        -- Obtener la siguiente fila del cursor
        FETCH NEXT FROM cventas 
        INTO @articulo, 
             @detalle, 
             @cant_movimientos, 
             @precio_venta, 
             @ganancia
    END

    -- Cerrar y desasignar el cursor
    CLOSE cventas
    DEALLOCATE cventas

RETURN
END
GO

---------------------------------------------------8---------------------------------------------------

/*
Realizar un procedimiento que complete la tabla Diferencias de precios, para los productos facturados que tengan composición y en los cuales el precio de facturación sea diferente al precio del cálculo de los precios unitarios por cantidad de sus componentes, se aclara que un producto que compone a otro, también puede estar compuesto por otros y así sucesivamente, la tabla se debe crear y está formada por las siguientes columnas:
    Código --> Código del articulo
    Detalle --> Detalle del articulo
    Cantidad --> Cantidad de productos que conforman el combo
    Precio_generado --> Precio que se compone a través de sus componentes
    Precio_facturado --> Precio del producto
*/

select comp_producto, 
    p1.prod_detalle, 
    count(*),
    sum(comp_cantidad * p2.prod_precio), 
    p1.prod_precio
from composicion 
join producto p1 on p1.prod_codigo = comp_producto
join producto p2 on p2.prod_codigo = comp_componente
where p1.prod_codigo in (select distinct item_producto from item_factura)
group by comp_producto, p1.prod_codigo, p1.prod_detalle, p1.prod_precio
GO

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
GO

---------------------------------------------------9---------------------------------------------------

-- Crear el/los objetos de base de datos que ante alguna modificación de un ítem de factura de un artículo con composición realice el movimiento de sus correspondientes componentes.

create trigger ej9 on item_factura for insert, DELETE
AS
BEGIN
    declare @producto char(8), @cantidad numeric(12,2), @deposito char(2)
    
    declare cinsert cursor for select comp_componente, comp_cantidad*item_cantidad  from inserted join composicion on item_producto = comp_producto 
    
    declare cdelete cursor for select comp_componente, comp_cantidad*item_cantidad  from deleted join composicion on item_producto = comp_producto 
    
    open cinsert
    
    fetch cinsert into @producto, @cantidad
    
    while @@FETCH_STATUS = 0
    
    BEGIN
        select top 1 @deposito = stoc_deposito from stock where stoc_producto = @producto order by stoc_cantidad desc
    
        update stock set stoc_cantidad = stoc_Cantidad - @cantidad where stoc_producto = @producto and stoc_deposito = @deposito
    
        fetch cinsert into @producto, @cantidad
    END
    
    close cinsert
    
    DEALLOCATE cinsert 
    
    open cdelete
    
    fetch cdelete into @producto, @cantidad
    
    while @@FETCH_STATUS = 0
    
    BEGIN
        select top 1 @deposito = stoc_deposito from stock where stoc_producto = @producto order by stoc_cantidad
        update stock set stoc_cantidad = stoc_Cantidad + @cantidad where stoc_producto = @producto and stoc_deposito = @deposito
        fetch cdelete into @producto, @cantidad
    END
    
    close cdelete
    
    DEALLOCATE cdelete 
END
GO

---------------------------------------------------10---------------------------------------------------

--  Crear el/los objetos de base de datos que ante el intento de borrar un artículo verifique que no exista stock y si es así lo borre en caso contrario que emita un mensaje de error.

---------------------------------------------------11---------------------------------------------------

-- Cree el/los objetos de BD necesarios para que dado un código de empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o indirectamente). 
-- Solo contar aquellos empleados (directos o indirectos) que tengan un código mayor que su jefe directo.

-- DROP FUNCTION IF EXISTS ej11; 

CREATE FUNCTION ej11 ( @empleado numeric(6) )
RETURNS INTEGER
AS
BEGIN
    DECLARE @cantidad INTEGER;
    SELECT @cantidad = 0;

    -- Si sos empleado no tenes a nadie a cargo
    IF (SELECT COUNT(*) FROM empleado WHERE empl_jefe = @empleado) = 0
        RETURN @cantidad; -- 0

    -- Contar empleados directos
    SELECT @cantidad = COUNT(*) FROM empleado WHERE empl_jefe = @empleado;
    
    -- Contar empleados indirectos
    DECLARE @jefe numeric(6);
    DECLARE cl CURSOR FOR SELECT empl_codigo FROM empleado WHERE empl_jefe = @empleado;
    
    OPEN cl;
    FETCH NEXT FROM cl INTO @jefe;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @cantidad = @cantidad + dbo.ej11(@jefe);
        FETCH NEXT FROM cl INTO @jefe;
    END;
    CLOSE cl;
    DEALLOCATE cl;
    
    RETURN @cantidad;
END
GO

SELECT dbo.ej11(1) AS TotalEmpleadosACargo 
GO
---------------------------------------------------12---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para que nunca un producto pueda ser compuesto por sí mismo. 
-- Se sabe que en la actualidad dicha regla se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías. 
-- No se conoce la cantidad de niveles de composición existentes.

-- Hay que controlar de aca en adelante --> Trigger
-- Sobre que hay que controlar --> Tabla composicion 
-- Que entren todos los porductos, o ninguno --> Afeter

CREATE TRIGGER productoCompuestoPorSiMismo ON composicion AFTER INSERT, UPDATE
AS
BEGIN
    IF ( SELECT sum ( dbo.COMPONE( comp_producto, comp_componente ) ) FROM inserted ) > 0
    BEGIN
        PRINT 'EL PRODUCTO ESTA COMPUESTO POR SI MISMO'
        ROLLBACK
    END
END
GO

CREATE FUNCTION COMPONE (@PRODUCTO CHAR(8), @COMPONENTE CHAR(8) )
RETURNS INT
AS
BEGIN
    DECLARE @COMP CHAR(8)

    IF ( @PRODUCTO = @COMPONENTE )
        RETURN 1

    DECLARE C1 CURSOR FOR SELECT comp_componente FROM Composicion WHERE comp_producto = @COMPONENTE
    OPEN C1
    FETCH NEXT FROM C1 INTO @COMP
    WHILE @@FETCH_STATUS = 0
    BEGIN 
        IF dbo.COMPONE ( @PRODUCTO, @COMP ) = 1
        BEGIN
            CLOSE C1
            DEALLOCATE C1
            RETURN 1
        END
        FETCH NEXT FROM C1 INTO @COMP
    END
    CLOSE C1
    DEALLOCATE C1
    RETURN 0
END
GO

SELECT DBO. COMPONE (PROD_CODIGO, '00001104') FROM Producto -- Aparecen con 1 el producto y los dos componentes
select * from Composicion ORDER By comp_producto
GO

---------------------------------------------------13---------------------------------------------------

-- Cree el/los objetos de BD necesarios para implantar la siguiente regla:
-- “Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de sus empleados totales (directos + indirectos)”. 
-- Se sabe que en la actualidad dicha regla se cumple y que la BD es accedida por n aplicaciones de diferentes tipos y tecnologías


CREATE TRIGGER ningúnJefe ON Empleado AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Si el sueldo del jefe es mayor al del empleado, no cumple la regla
    IF EXISTS ( SELECT * FROM inserted i WHERE dbo.ej13(empl_jefe) < ( SELECT empl_salario * 0.2 FROM empleado WHERE empl_codigo = i.empl_jefe ) ) -- El subselect trae el sueldo del jefe
    BEGIN
        PRINT 'ÉL SALARIO DEL JEFE ES MAYOR'
        ROLLBACK
    END

    IF EXISTS ( SELECT * FROM deleted d WHERE dbo.ej13(empl_jefe) < ( SELECT empl_salario * 0.2 FROM empleado WHERE empl_codigo = d.empl_jefe ) ) -- El subselect trae el sueldo del jefe
    BEGIN
        PRINT 'ÉL SALARIO DEL JEFE ES MAYOR'
        ROLLBACK
    END
    
END
GO

-- Me trae el sueldo de todos los subordinados
CREATE FUNCTION ej13 ( @empleado NUMERIC(6) )
RETURNS INTEGER
AS
BEGIN
    DECLARE @salario DECIMAL(12,2);
    SELECT @salario = 0;

    -- Si sos empleado no tenes a nadie a cargo
    IF NOT EXISTS ( SELECT SUM ( empl_salario ) FROM empleado WHERE empl_jefe = @empleado)
        RETURN @salario; -- 0

    -- Contar empleados directos
    SELECT @salario = SUM ( empl_salario ) FROM empleado WHERE empl_jefe = @empleado;

    -- Contar empleados indirectos
    DECLARE @jefe numeric(6);
    DECLARE cl CURSOR FOR SELECT empl_codigo FROM empleado WHERE empl_jefe = @empleado;
    
    OPEN cl;
    FETCH NEXT FROM cl INTO @jefe;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @salario = @salario + dbo.ej13(@jefe);
        FETCH NEXT FROM cl INTO @jefe;
    END;
    CLOSE cl;
    DEALLOCATE cl;
    
    RETURN @salario;
END
GO

SELECT dbo.ej11(1) AS TotalEmpleadosACargo 
GO
---------------------------------------------------14---------------------------------------------------

-- Agregar el/los objetos necesarios para que si:
-- Un cliente compra un producto compuesto a un precio menor que la suma de los precios de sus componentes que imprima la fecha, que cliente, que productos y a qué precio se realizó la compra. 
-- No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes.

CREATE TRIGGER TR_Validar_Precio_Producto_Compuesto
ON Item_Factura
AFTER INSERT
AS
BEGIN
    -- Primero validamos si hay algún producto con componenntes y despues si su precio es menor a la mitad del de sus productos
    IF EXISTS ( SELECT 1 
                FROM inserted i 
                WHERE i.item_producto IN (SELECT DISTINCT comp_producto FROM Composicion)
                AND i.item_precio < (dbo.precioDeComponentes(i.item_producto) / 2)
            )
    BEGIN
        PRINT('No se permite vender productos compuestos a un precio menor a la mitad del costo de sus componentes')
        ROLLBACK
        RETURN
    END

    -- Si no hay precios menores a la mitad, verificamos e imprimimos los casos bajo costo
    SELECT 'ALERTA: Venta bajo costo - ' +
            'Fecha: ' + f.fact_fecha +
            ', Cliente: ' + f.fact_cliente +
            ', Producto: ' + p.prod_detalle +
            ', Precio Venta: ' + i.item_precio +
            ', Costo Componentes: ' + dbo.precioDeComponentes(i.item_producto)
    FROM inserted i
    JOIN Factura f ON f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero
    JOIN Producto p ON p.prod_codigo = i.item_producto
    WHERE i.item_producto IN (SELECT DISTINCT comp_producto FROM Composicion)
    AND i.item_precio < dbo.precioDeComponentes(i.item_producto);
END
GO

CREATE FUNCTION precioDeComponentes ( @ProductoID VARCHAR(50) )
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @PrecioTotal DECIMAL(18,2)

    SELECT @PrecioTotal = ISNULL ( SUM ( prod_precio * comp_cantidad ) , 0)
    FROM Composicion
    JOIN Producto ON prod_codigo = comp_componente
    WHERE comp_producto = @ProductoID

    RETURN @PrecioTotal
END
GO

SELECT dbo.ej11(1) AS TotalEmpleadosACargo 
GO

---------------------------------------------------15---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para que el objeto principal reciba un producto como parametro y retorne el precio del mismo.
-- Se debe prever que el precio de los productos compuestos sera la sumatoria de los componentes del mismo multiplicado por sus respectivas cantidades. 
-- No se conocen los nivles de anidamiento posibles de los productos. 
-- Se asegura que nunca un producto esta compuesto por si mismo a ningun nivel. 
-- El objeto principal debe poder ser utilizado como filtro en el where de una sentencia select.

---------------------------------------------------16---------------------------------------------------