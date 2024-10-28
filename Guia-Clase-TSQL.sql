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
        ganancia NUMERIC(12,2)      -- Precio de venta - Cantidad * Precio
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

---------------------------------------------------14---------------------------------------------------PARCIAL

-- Agregar el/los objetos necesarios para que si:
-- Un cliente compra un producto compuesto a un precio menor que la suma de los precios de sus componentes que imprima la fecha, que cliente, que productos y a qué precio se realizó la compra. 
-- No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes.

CREATE TRIGGER ej14 ON item_factura instead of INSERT  
-- AFTER --> Entran todos los renglones o ninguno, para que no quede inconsistente la factura
-- instead of -- Cursores --> Algunos entraran y otros tiraran error 
                          --> Tratamiento individual
-- SIMPRE instead of VA CON Cursores
AS
BEGIN
	DECLARE @prod char(8), @precio decimal(12,4), @fecha datetime, @cliente char(4), @tipo char(1), @sucursal char(4), @numero char(8), @cantidad decimal(12,2)
	
    -- Declara un cursor con todos los productos que son compuestos
	DECLARE c1 CURSOR FOR SELECT item_producto, item_precio, fact_fecha, fact_cliente, fact_tipo, fact_sucursal, fact_numero, item_cantidad 
						    FROM inserted
						    JOIN factura ON fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
						    WHERE item_producto IN ( SELECT comp_producto FROM Composicion) 
	
	OPEN c1

	FETCH NEXT INTO @prod, @precio, @fecha, @cliente, @tipo, @sucursal, @numero, @cantidad

	WHILE @@FETCH_STATUS = 0

    -- Que voy a controlar --> Si su precio es menor a la mitad del de sus componentes
	BEGIN 
		IF @precio < ( SELECT sum(prod_precio * comp_cantidad) FROM composicion JOIN producto ON prod_codigo = comp_componente GROUP BY comp_producto ) * 2 
        BEGIN
			PRINT('no se puede ingresar el producto ' + @prod)

			FETCH NEXT INTO @prod, @precio, @fecha, @cliente, @tipo, @sucursal, @numero, @cantidad

			CONTINUE
		END
		
        -- Si es precio es menor a lo que salen por separado
		IF @precio < ( SELECT sum(prod_precio * comp_cantidad) FROM composicion JOIN producto ON prod_codigo = comp_componente GROUP BY comp_producto )
			PRINT(@prod + @fecha + @cliente)

		INSERT item_factura( item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio )

		VALUES( @tipo, @sucursal, @numero, @prod, @cantidad, @precio )
		
		FETCH NEXT INTO @prod, @precio, @fecha, @cliente, @tipo, @sucursal, @numero, @cantidad

	END

	CLOSE c1
    
	DEALLOCATE c1
END
GO

---------------------------------------------------15---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para que el objeto principal reciba un producto como parametro y retorne el precio del mismo.
-- Se debe prever que el precio de los productos compuestos sera la sumatoria de los componentes del mismo multiplicado por sus respectivas cantidades. 
-- No se conocen los nivles de anidamiento posibles de los productos. 
-- Se asegura que nunca un producto esta compuesto por si mismo a ningun nivel. 
-- El objeto principal debe poder ser utilizado como filtro en el where de una sentencia select.

CREATE FUNCTION precioDeComponentes ( @ProductoID char(8) )
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @PrecioTotal DECIMAL(12,2)

    -- Si no tenes componentes - Tu precio es lo que es
    IF NOT EXISTS ( SELECT * FROM composicion WHERE comp_producto = @ProductoID )
        BEGIN
            SELECT @PrecioTotal = prod_precio FROM producto WHERE prod_codigo = @ProductoID  
            RETURN @PrecioTotal
        END
   
    -- Si tenes componentes - Tu precio es el de ellos
    SELECT @PrecioTotal = 0

    DECLARE @comp char(8), @cantidad DECIMAL (12,2)

    DECLARE cl CURSOR FOR SELECT comp_componente, comp_cantidad, prod_precio FROM composicion JOIN producto ON comp_componente = prod_codigo

    OPEN cl;
    
   FETCH NEXT INTO @comp, @cantidad, @PrecioTotal;
    
    WHILE @@FETCH_STATUS = 0
    
    BEGIN
        SELECT @PrecioTotal = @PrecioTotal + @cantidad * dbo.precioDeComponentes(@ProductoID);
    
        FETCH NEXT INTO @comp, @cantidad, @PrecioTotal;
    
    END;
    
    CLOSE cl;
    
    DEALLOCATE cl;
    
    RETURN @PrecioTotal;
END
GO

---------------------------------------------------16---------------------------------------------------

-- Desarrolle el/los elementos de base de datos necesarios para que ante una venta automaticamante se descuenten del stock los articulos vendidos. 
-- Se descontaran del deposito que mas producto poseea y se supone que el stock se almacena tanto de productos simples como compuestos (si se acaba el stock de los compuestos no se arman combos)
-- En caso que no alcance el stock de un deposito se descontara del siguiente y asi hasta agotar los depositos posibles. 
-- En ultima instancia se dejara stock negativo en el ultimo deposito que se desconto.

CREATE TRIGGER articuloVendido ON Item_factura INSTEAD OF INSERT
AS
BEGIN

-- 1. Me fijo si es compuestoo o no 
-- 2. En base a eso veo como bajo la cantidad en STOCK

	DECLARE @producto char(8), @cantidad decimal(12,2), @deposito CHAR(2), @depo_ant CHAR(2), @depo_cantidad DECIMAL (12,2)
    DECLARE c1 CURSOR FOR SELECT item_producto, item_cantidad FROM inserted   -- CURSOR : Simpre que tengamos situaciones distintas vamos a tener que usarlo, ya que vamos a tener que darle un trato distinto a cada uno
	OPEN c1
	FETCH NEXT INTO @producto, @cantidad
	WHILE @@FETCH_STATUS = 0
    -- Que voy a controlar --> Si es compuesto o no
	BEGIN 
		IF EXISTS ( SELECT * FROM composicion WHERE comp_producto = @producto )
            -- CON COMPONENTES
            BEGIN
                DECLARE @componente char(8), @cantcomp decimal (12,2)
                DECLARE c_comp CURSOR FOR SELECT comp_componente, comp_cantidad * @cantidad FROM Composicion WHERE comp_producto = @producto -- Trae los productos de ese componenete
                OPEN c_comp
                FETCH NEXT INTO @componente, @cantcomp
                WHILE @@FETCH_STATUS = 0
                -- Que voy a controlar --> Si es compuesto o no
                BEGIN
                DECLARE c_deposito CURSOR FOR SELECT  stoc_deposito, stoc_Cantidad FROM stock WHERE @componente = stoc_producto AND stoc_cantidad > 0 ORDER BY stoc_cantidad DESC
                OPEN c_deposito
                FETCH NEXT INTO @deposito, @depo_cantidad
                WHILE @@FETCH_STATUS = 0 and @cantidad > 0
                -- Que voy a controlar --> Bajar el stock de todos los depositos, hasta que concuerde con lo vendido
                BEGIN
                    if @depo_cantidad >= @cantidad -- El deposito tenia mas productos en stock que los vendidos
                        BEGIN
                            UPDATE stock SET stoc_cantidad = stoc_cantidad - @cantidad WHERE stoc_producto = @componente AND stoc_deposito = @deposito
                            SELECT @cantidad = 0
                        END
                    else -- El deposito tenia menos productos en stock que los vendidos
                        BEGIN
                            UPDATE stock SET stoc_cantidad = stoc_cantidad - @depo_cantidad WHERE stoc_producto = @componente AND stoc_deposito = @deposito
                            SELECT @cantidad = @cantidad - @depo_cantidad
                            SELECT @depo_ant = @deposito
                        END
                    fetch next from c_deposito into @deposito, @depo_cantidad
                END
                -- Se queda con el ultimo stock que desconto
                update stock set stoc_cantidad = stoc_cantidad - @depo_cantidad where stoc_producto = @producto and stoc_deposito = @depo_ant
                FETCH NEXT INTO @producto, @cantidad
            END

            CLOSE c_comp
	        DEALLOCATE c_comp
            END
		ELSE
        -- SIN COMPONENTES
            BEGIN
                DECLARE c_deposito CURSOR FOR SELECT  stoc_deposito, stoc_Cantidad FROM stock WHERE @producto = stoc_producto AND stoc_cantidad > 0 ORDER BY stoc_cantidad DESC
                OPEN c_deposito
                FETCH NEXT INTO @deposito, @depo_cantidad
                WHILE @@FETCH_STATUS = 0 and @cantidad > 0
                -- Que voy a controlar --> Bajar el stock de todos los depositos, hasta que concuerde con lo vendido
                BEGIN
                    if @depo_cantidad >= @cantidad -- El deposito tenia mas productos en stock que los vendidos
                        BEGIN
                            UPDATE stock SET stoc_cantidad = stoc_cantidad - @cantidad WHERE stoc_producto = @producto AND stoc_deposito = @deposito
                            SELECT @cantidad = 0
                        END
                    else -- El deposito tenia menos productos en stock que los vendidos
                        BEGIN
                            UPDATE stock SET stoc_cantidad = stoc_cantidad - @depo_cantidad WHERE stoc_producto = @producto AND stoc_deposito = @deposito
                            SELECT @cantidad = @cantidad - @depo_cantidad
                            SELECT @depo_ant = @deposito
                        END
                    fetch next from c_deposito into @deposito, @depo_cantidad
                END
                -- Se queda con el ultimo stock que desconto
                update stock set stoc_cantidad = stoc_cantidad - @depo_cantidad where stoc_producto = @producto and stoc_deposito = @depo_ant
                FETCH NEXT INTO @producto, @cantidad
            END
	END
	CLOSE c1
	DEALLOCATE c1
END
GO

DROP TRIGGER IF EXISTS articulosVendidos;
GO

---------------------------------------------------17---------------------------------------------------

-- Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto que se debe almacenar en el deposito y que el stock maximo es la maxima cantidad de ese producto en ese deposito, cree el/los objetos de base de datos necesarios para que dicha regla de negocio se cumpla automaticamente. 
-- No se conoce la forma de acceso a los datos ni el procedimiento por el cual se incrementa o descuenta stock

SELECT stoc_cantidad AS 'Lo que tengo', 
stoc_punto_reposicion AS 'Lo minimo que tengo', 
stoc_stock_maximo AS 'Lo maximo que tengo'
FROM STOCK
GO

CREATE TRIGGER reposicion ON STOCK AFTER UPDATE, INSERT
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted i WHERE i.stoc_cantidad < i.stoc_punto_reposicion)
    BEGIN
        print 'Reponer producto'
        ROLLBACK
    END
    
    IF EXISTS (SELECT * FROM inserted i WHERE i.stoc_cantidad > i.stoc_stock_maximo)
    BEGIN
        print 'Se supero el stock'
        ROLLBACK
    END
END
GO

CREATE TRIGGER reposicion2 ON STOCK AFTER UPDATE, INSERT
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted i WHERE i.stoc_cantidad < i.stoc_punto_reposicion OR i.stoc_cantidad > i.stoc_stock_maximo)
    BEGIN
        print 'Hay que controlar la cantidad de STOCK'
        ROLLBACK
    END
END
GO

---------------------------------------------------18---------------------------------------------------

-- Sabiendo que el limite de credito de un cliente es el monto maximo que se le puede facturar mensualmente, cree el/los objetos de BD necesarios para que dicha regla de negocio se cumpla automaticamente. 
-- No se conoce la forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas

CREATE TRIGGER limiteDeCredito ON Factura AFTER INSERT -- Las facturas no se modifican
AS
BEGIN
    DECLARE @cliente char (4), @anio numeric(4), @mes numeric (2)
    DECLARE c1 CURSOR FOR SELECT fact_cliente, year(fact_fecha), month(fact_fecha) FROM inserted
    OPEN c1
    FETCH NEXT FROM c1 INTO @cliente, @anio, @mes
    WHILE @@FETCH_STATUS = 0 
    BEGIN
        IF ( SELECT SUM(fact_total) FROM factura WHERE fact_cliente = @cliente AND YEAR ( fact_fecha ) = @anio AND MONTH ( fact_fecha ) = @mes ) > ( SELECT clie_limite_credito FROM Cliente WHERE ( @cliente = clie_codigo ) )
        BEGIN
            PRINT 'Se supero el limite de credito' 
            CLOSE c1
            DEALLOCATE c1
            ROLLBACK
        END
        FETCH NEXT FROM c1 INTO @cliente, @anio, @mes
    END
    CLOSE c1
    DEALLOCATE c1
END
GO

---------------------------------------------------19---------------------------------------------------

-- Cree el/los objetos de BD necesarios para que se cumpla la siguiente regla de negocio automáticamente
-- "Ningún jefe puede tener menos de 5 años de antiguedad y tampoco puede tener más del 50% del personal a su cargo (contando directos e indirectos) a excepción del gerente general". 
-- Se sabe que en la actualidad la regla se cumple y existe un único gerente general.

CREATE TRIGGER ningunJefe ON Empleado FOR INSERT, UPDATE, DELETE 
AS
-- Puede tener menos de 5 años de antiguedad y tampoco puede tener más del 50% del personal a su cargo
BEGIN
    IF EXISTS ( SELECT * FROM inserted i JOIN empleado e ON e.empl_codigo = i.empl_jefe WHERE dbo.ej11(i.empl_jefe) > ( SELECT COUNT(empl_codigo)/2 FROM empleado ) AND e.empl_ingreso > ( GETDATE() - 365*5 ) )
        ROLLBACK    
    
    IF EXISTS ( SELECT * FROM inserted i WHERE dbo.ej11(i.empl_jefe) > ( SELECT COUNT(empl_codigo)/2 FROM empleado ) )
        ROLLBACK 
END
GO

---------------------------------------------------20---------------------------------------------------

-- Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del vendedor.
-- El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya vendido por lo menos 50 productos distintos en el mes.

CREATE TRIGGER comisionVendedor ON Factura FOR INSERT, DELETE
AS
BEGIN
    DECLARE @vendedor numeric (6), @anio numeric(4), @mes numeric (2)
    DECLARE c1 CURSOR FOR SELECT fact_vendedor, year(fact_fecha), month(fact_fecha) FROM inserted
    OPEN c1
    FETCH NEXT FROM c1 INTO @vendedor, @anio, @mes
    WHILE @@FETCH_STATUS = 0 
    BEGIN
        UPDATE empleado SET empl_comision = ( SELECT SUM(fact_total)*0.05 FROM factura WHERE fact_vendedor = @vendedor AND YEAR ( fact_fecha ) = @anio AND MONTH ( fact_fecha ) = @mes ) WHERE empl_codigo = @vendedor
        
        IF ( SELECT COUNT( distinct item_producto ) FROM factura JOIN item_factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero WHERE fact_vendedor = @vendedor AND year (fact_fecha) = @anio AND month (fact_fecha) = @mes ) >=50
            UPDATE empleado SET empl_comision = ( SELECT SUM(fact_total)*1.03 FROM factura WHERE fact_vendedor = @vendedor AND YEAR ( fact_fecha ) = @anio AND MONTH ( fact_fecha ) = @mes ) WHERE empl_codigo = @vendedor

        FETCH NEXT FROM c1 INTO @vendedor, @anio, @mes
    END
    CLOSE c1
    DEALLOCATE c1
END
GO

---------------------------------------------------31---------------------------------------------------

CREATE PROCEDURE ej31 
AS 
BEGIN
    DECLARE @EMPLEADO NUMERIC(6), @JEFE_ALTERNATIVO NUMERIC(6), @CANTIDAD INT 
    DECLARE cursor_empleado CURSOR FOR SELECT empl_codigo FROM Empleado where dbo.ej11(empl_codigo) > 20
    OPEN cursor_empleado
    FETCH NEXT FROM cursor_empleado INTO @EMPLEADO
    WHILE (@@FETCH_STATUS = 0)
    -- Busco a un jefe alternativo para redistribuir
    BEGIN
        SELECT @JEFE_ALTERNATIVO = empl_codigo FROM Empleado WHERE empl_codigo = @empleado AND dbo.ej11(empl_codigo) < 20
        
        -- Si no tengo un jefe alternativo, busco al gerente gral
        IF @JEFE_ALTERNATIVO IS NULL
            SELECT @JEFE_ALTERNATIVO = empl_codigo FROM Empleado WHERE empl_jefe IS NULL
        
        -- Redistribuyo a los excedentes
        UPDATE Empleado SET empl_jefe = @JEFE_ALTERNATIVO WHERE empl_jefe = @EMPLEADO
        
        FETCH NEXT FROM cursor_empleado INTO @EMPLEADO
    END
    CLOSE cursor_empleado
    DEALLOCATE cursor_empleado
END