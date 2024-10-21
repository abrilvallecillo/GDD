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
    drop table ventas

    Create table ventas( 
        articulo char(8),
        detalle char(30),
        cant_movimientos int,
        precio_venta numeric(12,2),
        renglon int,
        ganancia numeric(12,2)
    )

    declare @articulo char(8),
    @detalle char(30),
    @cant_movimientos int,
    @precio_venta numeric(12,2),
    @renglon int,
    @ganancia numeric(12,2)
    
    declare cventas cursor for ( SELECT prod_codigo, 
                                        prod_Detalle,
                                        count ( distinct item_tipo+item_sucursal+item_numero ), 
                                        avg ( item_precio ), 
                                        sum ( ( item_precio * item_cantidad ) - ( item_cantidad * prod_precio ) ) 
                                        from item_factura 
                                        join producto on prod_codigo = item_producto
                                        group by prod_codigo, prod_Detalle
                                )

    open cventas

    fetch cventas into @articulo, @detalle, @cant_movimientos, @precio_venta, @ganancia

    select @renglon = 1

    while @@FETCH_STATUS = 0

    BEGIN
        insert ventas values (@articulo, @detalle, @cant_movimientos, @precio_venta, @renglon, @ganancia)
        
        select @renglon = @renglon + 1
        
        fetch cventas into @articulo, @detalle, @cant_movimientos, @precio_venta, @ganancia
    END
    
    close cventas
    
    deallocate cventas

RETURN
END
GO

exec dbo.Ventas
go

---------------------------------------------------8---------------------------------------------------

/*
Realizar un procedimiento que complete la tabla Diferencias de precios, para los productos facturados que tengan composición y en los cuales el precio de facturación sea diferente al precio del cálculo de los precios unitarios por cantidad de sus componentes, se aclara que un producto que compone a otro, también puede estar compuesto por otros y así sucesivamente, la tabla se debe crear y está formada por las siguientes columnas:
Código --> Código del articulo
Detalle --> Detalle del articulo
Cantidad --> Cantidad de productos que conforman el combo
Precio_generado --> Precio que se compone a través de sus componentes
Precio_facturado --> Precio del producto
*/
select comp_producto, p1.prod_detalle, count(*),sum(comp_cantidad*p2.prod_precio), p1.prod_precio
from composicion join producto p1 on p1.prod_codigo = comp_producto
join producto p2 on p2.prod_codigo = comp_componente
where p1.prod_codigo in (select distinct item_producto from item_factura)
group by comp_producto, p1.prod_codigo, p1.prod_detalle, p1.prod_precio
GO

---------------------------------------------------8---------------------------------------------------

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

select * from composicion

select top 1 * from Factura

select * from item_factura where item_numero = '00068710'

insert item_Factura values ('A', '0003','00068710','00001104',10,12)

select * from stock where stoc_producto = '00001123'
