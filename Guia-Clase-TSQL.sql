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
            WHERE STOCK.stoc_producto = @articulo AND STOCK.stoc_deposito = @deposito

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
    FROM STOCK WHERE STOCK.stoc_producto = @articulo AND  STOCK.stoc_deposito = @deposito
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
    SELECT @cantidad = count(*) FROM Empleado WHERE empl_jefe IS NULL

    -- El que tiene el salario mas alto y mayor antigüedad
    SELECT TOP 1 @GerenteGeneral = empl_codigo FROM Empleado WHERE empl_jefe IS NULL ORDER BY empl_salario DESC, empl_ingreso ASC 

    -- Actualizar los empleados
    UPDATE Empleado SET empl_jefe = @GerenteGeneral WHERE empl_jefe IS NULL AND empl_codigo <> @GerenteGeneral

    RETURN
END
GO

BEGIN
    DECLARE @cantidad INT EXEC dbo.GerenteGeneral @cantidad
    PRINT @cantidad
END
GO

---------------------------------------------------

CREATE PROCEDURE GerenteGeneralCURSOR @cantidad INT OUTPUT
AS
BEGIN
    DECLARE @GerenteGeneral NUMERIC(6)
    DECLARE @empleado NUMERIC(6)
    
    -- El que tiene el salario mas alto y mayor antigüedad
    SELECT TOP 1 @GerenteGeneral = empl_codigo FROM Empleado WHERE empl_jefe IS NULL ORDER BY empl_salario DESC, empl_ingreso ASC 

    -- Crea el CURSOR que va a traer los empleados que tengo que modificar
    DECLARE GerenteGeneralCURSOR CURSOR 
    FOR SELECT empl_codigo FROM Empleado WHERE empl_jefe IS NULL AND empl_codigo <> @GerenteGeneral

    -- Lo abre
    OPEN GerenteGeneralCURSOR

    -- Lo ejecuta
    FETCH GerenteGeneralCURSOR INTO @empleado
    WHILE @@FETCH_STATUS = 0
    BEGIN
         -- Actualizar los empleados
        UPDATE Empleado SET empl_jefe = @GerenteGeneral WHERE empl_jefe = @empleado

        FETCH GerenteGeneralCURSOR INTO @empleado
    END

    -- Lo cierra
    CLOSE GerenteGeneralCURSOR

    -- Lo destruye
    DEALLOCATE GerenteGeneralCURSOR

    RETURN
END
GO

BEGIN
    DECLARE @cant INT EXEC dbo.GerenteGeneralCURSOR @cant
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
                        SELECT isnull ( sum ( fact_total ) , 0 ) 
                        FROM factura 
                        WHERE fact_vendedor = empl_codigo 
                        AND year ( fact_fecha ) = ( SELECT max ( year ( fact_fecha ) ) FROM factura ) 
                        )
    
    SELECT TOP 1 @vendedor = empl_codigo FROM empleado order by empl_comision desc
 
    RETURN
END
go 

update empleado set empl_comision = 0

exec dbo.ej4 1

SELECT * FROM empleado order by empl_comision desc 
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
    FROM item_factura 
    JOIN factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
    JOIN Producto on prod_codigo = item_producto 
    JOIN Empleado on empl_codigo = fact_vendedor 
    JOIN Departamento on depa_codigo = empl_departamento
    GROUP BY year(fact_fecha), month(fact_fecha), prod_familia, prod_rubro, depa_zona, fact_cliente, prod_codigo
RETURN
END
GO

---------------------------------------------------6---------------------------------------------------

create PROCEDURE SP_UNIFICAR_PRODUCTO
AS
BEGIN
	DECLARE @combo char(8), @combocantidad integer -- COMBOS
    DECLARE @fact_tipo char(1), @fact_suc char(4), @fact_nro char(8) -- FACTURAS
    
    -- CURSOR PARA RECORRER LAS FACTURAS
	DECLARE cFacturas CURSOR FOR SELECT fact_tipo, fact_sucursal, fact_numero FROM Factura
	OPEN cFacturas
	FETCH NEXT FROM cFacturas into @fact_tipo, @fact_suc, @fact_nro
	WHILE @@FETCH_STATUS = 0
	
    -- ACA NECESITAMOS UN CURSOR PORQUE PUEDE HABER MAS DE UN COMBO EN UNA FACTURA	
    BEGIN	
		DECLARE cProducto CURSOR FOR ( 
                                        SELECT comp_producto -- Me trae todos los combos que yo puedo armar con esta factura
                                        FROM Item_Factura 
                                        JOIN Composicion C1 on ( item_producto = C1.comp_componente ) 
                                        WHERE item_cantidad >= C1.comp_cantidad AND item_sucursal = @fact_suc AND item_numero = @fact_nro AND item_tipo = @fact_tipo
                                        GROUP BY C1.comp_producto
                                        HAVING COUNT(*) = ( SELECT COUNT(*) FROM Composicion as C2 WHERE C2.comp_producto= C1.comp_producto ) -- Me fijo tener todos los componentes
                                    )
		OPEN cProducto
		FETCH NEXT FROM cProducto into @combo
		WHILE @@FETCH_STATUS = 0 

        --SACAMOS CUANTOS COMBOS PUEDO ARMAR COMO MÁXIMO (POR ESO EL MIN)
		BEGIN		
			SELECT @combocantidad = MIN ( FLOOR ( ( item_cantidad / c1.comp_cantidad ) ) )
			FROM Item_Factura 
            JOIN Composicion C1 on (item_producto = C1.comp_componente)
			WHERE item_cantidad >= C1.comp_cantidad AND item_sucursal = @fact_suc AND item_numero = @fact_nro AND item_tipo = @fact_tipo AND c1.comp_producto = @combo	
				
			--INSERTAMOS LA FILA DEL COMBO CON EL PRECIO QUE CORRESPONDE
			INSERT INTO Item_Factura ( item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio )
			
            SELECT @fact_tipo, @fact_suc, @fact_nro, @combo, @combocantidad, ( @combocantidad * (SELECT prod_precio FROM Producto WHERE prod_codigo = @combo) )
			
            UPDATE Item_Factura 
                SET item_cantidad = i1.item_cantidad - ( @combocantidad * ( SELECT comp_cantidad FROM Composicion WHERE i1.item_producto = comp_componente AND comp_producto = @combo ) ),
                    item_precio = ( i1.item_cantidad - ( @combocantidad * ( SELECT comp_cantidad FROM Composicion WHERE i1.item_producto = comp_componente AND comp_producto = @combo ) ) ) * ( SELECT prod_precio FROM Producto WHERE prod_codigo = I1.item_producto )											  															  
                FROM Item_Factura I1, Composicion C1 
                WHERE I1.item_sucursal = @fact_suc AND I1.item_numero = @fact_nro AND I1.item_tipo = @fact_tipo AND I1.item_producto = C1.comp_componente AND C1.comp_producto = @combo
			
            DELETE FROM Item_Factura WHERE item_sucursal = @fact_suc AND item_numero = @fact_nro AND item_tipo = @fact_tipo AND item_cantidad = 0 
			
            FETCH NEXT FROM cproducto into @combo

    	END
		CLOSE cProducto;
		DEALLOCATE cProducto;
			
	    FETCH NEXT FROM cFacturas into @fact_tipo, @fact_suc, @fact_nro
	END
	CLOSE cFacturas;
	DEALLOCATE cFacturas;
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

    -- Definición del CURSOR para iterar sobre los productos y sus ventas
    DECLARE cventas CURSOR FOR 
    SELECT prod_codigo, 
           prod_detalle, 
           COUNT(DISTINCT (item_numero + item_sucursal + item_tipo)), 
           AVG(item_precio), 
           SUM((item_precio * item_cantidad) - (item_cantidad * prod_precio)) 
    FROM Producto
    JOIN Item_Factura ON item_producto = prod_codigo
    GROUP BY prod_codigo, prod_detalle

    -- Abrir el CURSOR
    OPEN cventas

    -- Inicializar el contador de renglones
    SELECT @renglon = 1

    -- Obtener la primera fila del CURSOR
    FETCH NEXT FROM cventas 
    INTO @articulo, @detalle, @cant_movimientos, @precio_venta, @ganancia

    -- Bucle para recorrer el CURSOR
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

        -- Obtener la siguiente fila del CURSOR
        FETCH NEXT FROM cventas 
        INTO @articulo, 
             @detalle, 
             @cant_movimientos, 
             @precio_venta, 
             @ganancia
    END

    -- Cerrar y desasignar el CURSOR
    CLOSE cventas
    DEALLOCATE cventas

RETURN
END
GO

---------------------------------------------------9---------------------------------------------------

-- Crear el/los objetos de base de datos que ante alguna modificación de un ítem de factura de un artículo con composición realice el movimiento de sus correspondientes componentes.

create trigger ej9 on item_factura FOR INSERT, DELETE
AS
BEGIN
    DECLARE @producto char(8), @cantidad numeric(12,2), @deposito char(2)

    -- Caso INSERT
    DECLARE cinsert CURSOR for SELECT comp_componente, comp_cantidad*item_cantidad  FROM inserted JOIN composicion on item_producto = comp_producto 
    open cinsert
    fetch cinsert into @producto, @cantidad
    while @@FETCH_STATUS = 0
    BEGIN
        SELECT top 1 @deposito = stoc_deposito FROM stock WHERE stoc_producto = @producto order by stoc_cantidad desc
        update stock set stoc_cantidad = stoc_Cantidad - @cantidad WHERE stoc_producto = @producto AND stoc_deposito = @deposito
        fetch cinsert into @producto, @cantidad
    END
    close cinsert
    DEALLOCATE cinsert 

    -- Caso DELETE
    DECLARE cdelete CURSOR for SELECT comp_componente, comp_cantidad*item_cantidad  FROM deleted JOIN composicion on item_producto = comp_producto   
    open cdelete
    fetch cdelete into @producto, @cantidad
    while @@FETCH_STATUS = 0
    BEGIN
        SELECT top 1 @deposito = stoc_deposito FROM stock WHERE stoc_producto = @producto order by stoc_cantidad
        update stock set stoc_cantidad = stoc_Cantidad + @cantidad WHERE stoc_producto = @producto AND stoc_deposito = @deposito
        fetch cdelete into @producto, @cantidad
    END
    close cdelete
    DEALLOCATE cdelete 
END
GO
---------------------------------------------------10---------------------------------------------------

-- Crear el/los objetos de base de datos que ante el intento de borrar un artículo verifique que no exista stock y si es así lo borre en caso contrario que emita un mensaje de error.

create trigger ej10 on producto after delete --> Evalua todos los artuculos juntos
AS
begin
    if (SELECT count (*) FROM deleted JOIN stock on stoc_producto = prod_codigo WHERE stoc_cantidad > 0) > 0
    BEGIN
        ROLLBACK --> Si habia alguno con stock --> NO BORRA NINGUNO
        RAISERROR( 'NO SE PUEDEN BORRAR LOS PRODUCTOS CON STOCK', 16, 1)
    END
END
GO

create trigger ej10 on producto INSTEAD of delete --> Va evaluando articulo por articulo
AS
begin
    if (SELECT count (*) FROM deleted JOIN stock on stoc_producto = prod_codigo WHERE stoc_cantidad > 0) > 0
    BEGIN
        ROLLBACK --> BORRA SOLO LOS QUE TIENEN STOCK
        RAISERROR( 'NO SE PUEDEN BORRAR LOS PRODUCTOS CON STOCK', 16, 1)
    END
END
GO

---------------------------------------------------

/* QUEREMOS BORRAR LOS QUE SE PUEDA */

create trigger ej10 on producto INSTEAD OF delete 
AS
begin 
    DELETE FROM PRODUCTO WHERE PROD_CODIGO IN (
                                                SELECT PROD_CODIGO 
                                                FROM deleted 
                                                WHERE PROD_CODIGO NOT IN (
                                                                            SELECT DISTINCT STOC_PRODUCTO 
                                                                            FROM STOCK 
                                                                            WHERE stoc_cantidad > 0
                                                                        )
                                            )
END
GO 

---------------------------------------------------

/* QUEREMOS BORRAR LOS QUE SE PUEDA E INFORMAR UNO POR UNO LOS QUE NO BORRRE*/

create trigger ej10 on producto INSTEAD OF delete 
AS
begin 
    DECLARE @PRODUCTO CHAR(8)
    DELETE FROM PRODUCTO WHERE PROD_CODIGO IN (
                                                SELECT PROD_CODIGO 
                                                FROM deleted 
                                                WHERE PROD_CODIGO NOT IN (
                                                                            SELECT DISTINCT STOC_PRODUCTO 
                                                                            FROM STOCK 
                                                                            WHERE stoc_cantidad > 0
                                                                        )
                                                )
    DECLARE C1 CURSOR FOR SELECT DISTINCT STOC_PRODUCTO FROM deleted JOIN stock on stoc_producto = prod_codigo WHERE stoc_cantidad > 0
    OPEN C1 
    FETCH NEXT C1 INTO @PRODUCTO
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT ('EL PRODUCTO '+@PRODUCTO+' NO SE PUDO BORRAR PORQUE TIENE STOCK')
        FETCH NEXT C1 INTO @PRODUCTO
    END
    CLOSE C1
    DEALLOCATE C1
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
    DECLARE @cantidad INTEGER = 0;

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

---------------------------------------------------

CREATE FUNCTION ej11a(@CodigoEmpleado INT)
RETURNS INT
AS
BEGIN
    DECLARE @Conteo INT = 0, @empleado NUMERIC(6);

    DECLARE c1 CURSOR FOR SELECT empl_codigo FROM Empleado WHERE empl_jefe = @CodigoEmpleado AND empl_codigo > @CodigoEmpleado;
    OPEN c1;
    FETCH NEXT FROM c1 INTO @empleado;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Conteo = @Conteo + 1 + dbo.ej11a(@empleado);
        FETCH NEXT FROM c1 INTO @empleado;
    END;
    CLOSE c1;
    DEALLOCATE c1;

    RETURN @Conteo;
END;
GO

---------------------------------------------------

CREATE FUNCTION ej11b (@codigo NUMERIC(6))
RETURNS INT
AS 
BEGIN
    RETURN (SELECT isnull(count(*) + sum(dbo.ej11(empl_codigo)), 0) FROM Empleado WHERE empl_jefe = @codigo)
END
GO

---------------------------------------------------

SELECT dbo.ej11a(4) AS TotalEmpleadosACargo 
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
    
    -- Composicion directa
    IF ( @PRODUCTO = @COMPONENTE ) 
        RETURN 1

    -- Composicion indirecta
    DECLARE C1 CURSOR FOR SELECT comp_componente FROM Composicion WHERE comp_producto = @COMPONENTE 
    OPEN C1
    FETCH NEXT FROM C1 INTO @COMP
    WHILE @@FETCH_STATUS = 0
   
    BEGIN 
        IF ( dbo.COMPONE ( @PRODUCTO, @COMP ) = 1 )
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

---------------------------------------------------

create function ej1q2 (@producto char(8),@componente char(8))
returns int
as 
BEGIN
    DECLARE @ret int, @comp char(8) 
   
    if ( @producto = @componente )
        SELECT @ret = 1
   
    ELSE
        begin
            DECLARE cur_comp CURSOR for SELECT comp_componente FROM composicion WHERE comp_producto = @producto
            open cur_comp
            fetch cur_comp into @comp
            while @@FETCH_STATUS = 0 AND @ret = 0
            
            begin 
                SELECT @ret = dbo.ej1q2(@producto, @comp)
                fetch cur_comp into @comp
            END
            
            close cur_comp
            deallocate cur_comp
        end

    return @ret
END
go 

---------------------------------------------------

CREATE FUNCTION eje12 (@producto char(8), @componente char(8))
RETURNS INT
AS 
BEGIN
    DECLARE @ret int = 0
    if ( @producto = @componente )
        SELECT @ret = 1
    ELSE
        SELECT @ret = MAX ( dbo.eje12 ( @producto, @componente ) ) FROM Composicion WHERE comp_producto = @componente
    return @ret
END
GO

---------------------------------------------------

SELECT DBO. COMPONE (PROD_CODIGO, '00001104') FROM Producto -- Aparecen con 1 el producto y los dos componentes
SELECT * FROM Composicion ORDER By comp_producto
GO

---------------------------------------------------13---------------------------------------------------

-- Cree el/los objetos de BD necesarios para implantar la siguiente regla:
-- “Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de sus empleados totales (directos + indirectos)”. 
-- Se sabe que en la actualidad dicha regla se cumple y que la BD es accedida por n aplicaciones de diferentes tipos y tecnologías


CREATE TRIGGER ningúnJefe ON Empleado AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Si el sueldo del jefe es mayor al del empleado, no cumple la regla
    IF EXISTS ( SELECT * FROM inserted i WHERE dbo.ej13(empl_jefe) < ( SELECT empl_salario * 0.2 FROM empleado WHERE empl_codigo = i.empl_jefe ) ) -- El subSELECT trae el sueldo del jefe
    BEGIN
        PRINT 'ÉL SALARIO DEL JEFE ES MAYOR'
        ROLLBACK
    END

    IF EXISTS ( SELECT * FROM deleted d WHERE dbo.ej13(empl_jefe) < ( SELECT empl_salario * 0.2 FROM empleado WHERE empl_codigo = d.empl_jefe ) ) -- El subSELECT trae el sueldo del jefe
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

---------------------------------------------------

create trigger ejer13 on empleado for update, delete  
AS
BEGIN
    if ( SELECT count(*) FROM inserted i WHERE ( SELECT empl_salario FROM empleado WHERE empl_codigo = i.empl_jefe ) < dbo.ejer13(i.empl_jefe) * 0.2 ) < 0
        begin    
            ROLLBACK
            PRINT('El salario de la suma de los empeados no puede ser menor al 20% del salario del jefe')        
        end    
    
    if ( SELECT count(*) FROM deleted i WHERE (SELECT empl_salario FROM empleado WHERE empl_codigo = i.empl_jefe) < dbo.ejer13(i.empl_jefe) * 0.2 ) < 0
        begin    
            ROLLBACK
            PRINT('El salario de la suma de los empeados no puede ser menor al 20% del salario del jefe')        
        end    
END
GO

CREATE FUNCTION ejer13 (@codigo NUMERIC(6))
RETURNS INT
AS 
BEGIN
    RETURN ( SELECT sum(empl_salario) + dbo.ejer13(empl_codigo) FROM Empleado WHERE empl_jefe = @codigo )
END
GO

---------------------------------------------------

SELECT dbo.ej11(1) AS TotalEmpleadosACargo 
GO

---------------------------------------------------14---------------------------------------------------PARCIAL

-- Agregar el/los objetos necesarios para que si:
-- Un cliente compra un producto compuesto a un precio menor que la suma de los precios de sus componentes que imprima la fecha, que cliente, que productos y a qué precio se realizó la compra. 
-- No se deberá permitir que dicho precio sea menor a la mitad de la suma de los componentes.

CREATE TRIGGER ej14 ON item_factura instead of INSERT  
-- AFTER --> Entran todos los renglones o ninguno, para que no quede inconsistente la factura
-- instead of -- CURSORes --> Algunos entraran y otros tiraran error 
                          --> Tratamiento individual
-- SIMPRE instead of VA CON CURSORes
AS
BEGIN
	DECLARE @prod char(8), @precio decimal(12,4), @fecha datetime, @cliente char(4), @tipo char(1), @sucursal char(4), @numero char(8), @cantidad decimal(12,2)
	
    -- Declara un CURSOR con todos los productos que son compuestos
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

---------------------------------------------------

create trigger ej14 on item_factura instead of insert 
as
begin 
    DECLARE @producto char(8), @precio numeric(12,2), @sucursal char(4), @cantidad numeric(12,2), @fecha smalldatetime, @cliente char(4), @tipo char, @numero char(8)
    
    -- Definir el CURSOR para obtener los datos de la factura
    DECLARE cfact CURSOR for (
                                SELECT item_tipo, item_sucursal, item_numero, fact_fecha, fact_cliente 
                                FROM inserted 
                                JOIN factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                                GROUP BY item_tipo, item_sucursal+item_numero
                            )
    open cfact
    fetch cfact netx into @tipo, @sucursal,@numero, @fehca, @cliente
    while @@FETCH_STATUS = 0
   
    BEGIN
        -- Definir el CURSOR para obtener los productos de cada factura
        DECLARE c1 CURSOR for SELECT item_producto, item_precio, item_cantidad FROM inserted WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
        open c1 fetch c1 netx into @producto, @precio, @cantidad
        DECLARE @nocumple int = 0
        while @@FETCH_STATUS = 0 AND @nocumple = 0
        
        BEGIN
            -- Verificación de precios
            if @precio > (SELECT isnull(sum(prod_precio),0) FROM producto JOIN composicion on comp_producto = @producto AND comp_componente = prod_codigo) 
                insert item_factura values(@tipo,@sucursal,@numero, @producto, @cantidad,@precio)
            
            else if @precio < (SELECT isnull(sum(prod_precio),0) FROM producto JOIN composicion on comp_producto = @producto AND comp_componente = prod_codigo) * 0.5 
                begin
                    print('la suma de los componentes es menor que 50% del precio del producto '+@producto+' para la fecha '+@fecha+' del cliente '+@cliente)
                    SELECT @nocumple = 1
                end
            
            else 
                begin
                    insert item_factura values(@tipo,@sucursal,@numero, @producto, @cantidad,@precio)
                    print('la suma de los componentes es menor que el precio del producto '+@producto+' para la fecha '+@fecha+' del cliente '+@cliente)
                end

            fetch c1 netx into @producto, @precio 
        END
        close c1
        DEALLOCATE c1
        if @nocumple = 1
       
        begin
            -- Eliminar la factura si alguna condición no cumple
            DELETE FROM ITEM_FACTURA WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
            DELETE FROM FACTURA WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
        end

        fetch cfact netx into @tipo, @sucursal,@numero

    END
end 
go 

---------------------------------------------------

create trigger ej14 on item_factura instead of insert
as
begin
    declare @producto char(8), @precio numeric(12,2), @sucursal char(4), @cantidad numeric(12,2), @tipo char, @numero char(8)
    declare cl cursor for select item_producto, item_precio from inserted
    open cl
    fetch cl netx into @producto, @precio, @cantidad, @tipo, @sucursal, @numero
    while @@FETCH_STATUS = 0
    BEGIN
        if @precio > (select isnull(sum(prod_precio),0) from producto join composicion on comp_producto = @producto and comp_componente = prod_codigo)
            insert item_factura values(@tipo,@sucursal,@numero, @producto, @cantidad, @precio)
        
        else
            if @precio < (select isnull(sum(prod_precio),0) from producto join composicion on comp_producto = @producto and comp_componente = prod_codigo) * 0.5
                print('la suma de los componentes es menor que 505 del precio del producto '+ @producto)

            else
                begin
                    insert item_factura values(@tipo,@sucursal,@numero, @producto, @cantidad,@precio)
                    print('la suma de los componetes es menor que el precio del producto' +@producto)
                end
        
        fetch cl netx into @producto, @precio
    END
END
GO

---------------------------------------------------15---------------------------------------------------

-- Cree el/los objetos de base de datos necesarios para que el objeto principal reciba un producto como parametro y retorne el precio del mismo.
-- Se debe prever que el precio de los productos compuestos sera la sumatoria de los componentes del mismo multiplicado por sus respectivas cantidades. 
-- No se conocen los nivles de anidamiento posibles de los productos. 
-- Se asegura que nunca un producto esta compuesto por si mismo a ningun nivel. 
-- El objeto principal debe poder ser utilizado como filtro en el WHERE de una sentencia SELECT.

CREATE FUNCTION precioDeComponentes ( @ProductoID char(8) )
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @PrecioTotal DECIMAL(12,2) = 0

    -- Si no tenes componentes - Tu precio es lo que es
    IF NOT EXISTS ( SELECT * FROM composicion WHERE comp_producto = @ProductoID )
        RETURN ( SELECT @PrecioTotal = prod_precio FROM producto WHERE prod_codigo = @ProductoID  )
   
    -- Si tenes componentes - Tu precio es el de ellos
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
                WHILE @@FETCH_STATUS = 0 AND @cantidad > 0
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
                    FETCH NEXT FROM c_deposito into @deposito, @depo_cantidad
                END
                -- Se queda con el ultimo stock que desconto
                update stock set stoc_cantidad = stoc_cantidad - @depo_cantidad WHERE stoc_producto = @producto AND stoc_deposito = @depo_ant
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
                WHILE @@FETCH_STATUS = 0 AND @cantidad > 0
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
                    FETCH NEXT FROM c_deposito into @deposito, @depo_cantidad
                END
                -- Se queda con el ultimo stock que desconto
                update stock set stoc_cantidad = stoc_cantidad - @depo_cantidad WHERE stoc_producto = @producto AND stoc_deposito = @depo_ant
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

---------------------------------------------------

CREATE TRIGGER reposicion2 ON STOCK AFTER UPDATE, INSERT
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted i WHERE ( i.stoc_cantidad < i.stoc_punto_reposicion ) OR ( i.stoc_cantidad > i.stoc_stock_maximo ) )
    BEGIN
        print 'Hay que controlar la cantidad de STOCK'
        ROLLBACK
    END
END
GO

---------------------------------------------------18---------------------------------------------------

-- Sabiendo que el limite de credito de un cliente es el monto maximo que se le puede facturar mensualmente, cree el/los objetos de BD necesarios para que dicha regla de negocio se cumpla automaticamente. 
-- No se conoce la forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas

CREATE TRIGGER limiteDeCredito ON Factura INSTEAD OF INSERT -- Las facturas no se modifican
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
-- "Ningún jefe puede tener menos de 5 años de antiguedad y tampoco puede tener más del 50% del personal a su cargo (contANDo directos e indirectos) a excepción del gerente general". 
-- Se sabe que en la actualidad la regla se cumple y existe un único gerente general.

CREATE TRIGGER ningunJefe2 ON Empleado FOR INSERT, UPDATE, DELETE 
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
        UPDATE empleado SET empl_comision = (
                                                SELECT SUM(fact_total)*0.05 
                                                FROM factura 
                                                WHERE fact_vendedor = @vendedor 
                                                AND YEAR ( fact_fecha ) = @anio 
                                                AND MONTH ( fact_fecha ) = @mes 
                                            ) WHERE empl_codigo = @vendedor
        
        IF ( 
                SELECT COUNT( distinct item_producto ) 
                FROM factura 
                JOIN item_factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                WHERE fact_vendedor = @vendedor 
                AND year (fact_fecha) = @anio 
                AND month (fact_fecha) = @mes 
            ) >=50

            UPDATE empleado SET empl_comision = ( 
                                                    SELECT SUM(fact_total)*1.03 
                                                    FROM factura 
                                                    WHERE fact_vendedor = @vendedor 
                                                    AND YEAR ( fact_fecha ) = @anio 
                                                    AND MONTH ( fact_fecha ) = @mes 
                                                ) WHERE empl_codigo = @vendedor

        FETCH NEXT FROM c1 INTO @vendedor, @anio, @mes
    END
    CLOSE c1
    DEALLOCATE c1
END
GO

---------------------------------------------------21---------------------------------------------------

CREATE TRIGGER ej21 ON FACTURA FOR INSERT
AS
BEGIN
    IF EXISTS ( 
                SELECT fact_numero+fact_sucursal+fact_tipo, COUNT ( DISTINCT prod_familia ) 
                FROM inserted
				JOIN Item_Factura ON item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
				JOIN Producto ON prod_codigo = item_producto 
                GROUP BY fact_numero+fact_sucursal+fact_tipo
                HAVING COUNT ( DISTINCT prod_familia) <> 1 -- Mas de una familia
            )
            
    BEGIN
        DECLARE @NUMERO char(8),@SUCURSAL char(4),@TIPO char(1)
        DECLARE CURSORFacturas CURSOR FOR SELECT fact_numero,fact_sucursal,fact_tipo FROM inserted
        OPEN CURSORFacturas
        FETCH NEXT FROM CURSORFacturas INTO @NUMERO,@SUCURSAL,@TIPO
        WHILE @@FETCH_STATUS = 0
        
        BEGIN
            DELETE FROM Item_Factura WHERE item_numero+item_sucursal+item_tipo = @NUMERO+@SUCURSAL+@TIPO
            DELETE FROM Factura WHERE fact_numero+fact_sucursal+fact_tipo = @NUMERO+@SUCURSAL+@TIPO
            FETCH NEXT FROM CURSORFacturas INTO @NUMERO,@SUCURSAL,@TIPO
        END
        
        CLOSE CURSORFacturas
        DEALLOCATE CURSORFacturas
        RAISERROR ('no puede ingresar productos de mas de una familia en una misma factura.',1,1)
        ROLLBACK
    END
END
GO

---------------------------------------------------22---------------------------------------------------

CREATE PROC dbo.Ejercicio22
AS
BEGIN
	declare @rubro char(4), @cantProdRubro int
	declare cursor_rubro CURSOR FOR ( SELECT R.rubr_id,COUNT(*) FROM rubro R JOIN Producto P ON P.prod_rubro = R.rubr_id GROUP BY R.rubr_id HAVING COUNT(*) > 20 )
	OPEN cursor_rubro
	FETCH NEXT FROM cursor_rubro INTO @rubro,@cantProdRubro
	WHILE @@FETCH_STATUS = 0

	BEGIN
		declare @cantProdRubroIndividual int = @cantProdRubro, @prodCod char(8), @rubroLibre char(4)
		declare cursor_productos CURSOR FOR ( SELECT prod_codigo FROM Producto WHERE prod_rubro = @rubro )
		OPEN cursor_productos
		FETCH NEXT FROM cursor_productos INTO @prodCod
		WHILE @@FETCH_STATUS = 0 OR @cantProdRubroIndividual < 21
		BEGIN
			IF EXISTS ( SELECT TOP 1 rubr_id FROM Rubro JOIN Producto ON prod_rubro = rubr_id GROUP BY rubr_id HAVING COUNT(*) < 20 ORDER BY COUNT(*) ASC )
			    BEGIN
				    SET @rubroLibre = ( SELECT TOP 1 rubr_id
                                        FROM Rubro
										JOIN Producto ON prod_rubro = rubr_id
                                        GROUP BY rubr_id
                                        HAVING COUNT(*) < 20
                                        ORDER BY COUNT(*) ASC
                                        )
				    UPDATE Producto SET prod_rubro = @rubroLibre WHERE prod_codigo = @prodCod
			    END
			
            ELSE
			    BEGIN
			    	IF NOT EXISTS ( SELECT rubr_id FROM Rubro WHERE rubr_detalle = 'Rubro reasignado' )  
                        INSERT INTO Rubro (RUBR_ID,rubr_detalle) VALUES ('xx','Rubro reasignado')
                    
                    UPDATE Producto set prod_rubro = ( SELECT rubr_id FROM Rubro WHERE rubr_detalle = 'Rubro reasignado' ) WHERE prod_codigo = @prodCod
			    END

			SET @cantProdRubroIndividual -= 1

		    FETCH NEXT FROM cursor_productos INTO @prodCod
		END
		
        CLOSE cursor_productos
		DEALLOCATE cursor_productos
	    FETCH NEXT FROM cursor_rubro INTO @rubro,@cantProdRubro
	
    END
	
    CLOSE cursor_rubro
	DEALLOCATE cursor_productos
END
GO

---------------------------------------------------23---------------------------------------------------

-- Desarrolle el/los elementos de BD necesarios para que ante una venta automaticamante se controle que en una misma factura no puedan venderse más de dos productos con composición. 
-- Si esto ocurre de bera rechazarse la factura.

CREATE TRIGGER dbo.Ejercicio23 ON item_factura FOR INSERT
AS
BEGIN
	DECLARE @tipo char(1), @sucursal char(4), @numero char(8), @producto char(8)
	DECLARE cursor_ifact CURSOR FOR ( SELECT item_tipo,item_sucursal,item_numero,item_producto FROM inserted )
	OPEN cursor_ifact
	FETCH NEXT FROM cursor_ifact INTO @tipo,@sucursal,@numero,@producto
	WHILE @@FETCH_STATUS = 0
	
    BEGIN
		IF ( SELECT COUNT(*) FROM inserted WHERE item_tipo + item_sucursal + item_numero = @tipo + @sucursal + @numero AND item_producto IN ( SELECT comp_producto FROM Composicion ) ) >= 2
            BEGIN
                DELETE FROM Item_factura WHERE item_tipo + item_sucursal + item_numero = @tipo + @sucursal + @numero
                DELETE FROM Factura WHERE fact_tipo + fact_sucursal + fact_numero = @tipo + @sucursal + @numero
                RAISERROR('En una misma factura no pueden venderse mas de dos productos con composicion',1,1)
                ROLLBACK TRANSACTION
            END

	    FETCH NEXT FROM cursor_ifact INTO @tipo,@sucursal,@numero,@producto
    END
    
	CLOSE cursor_ifact
	DEALLOCATE cursor_ifact
END
GO

---------------------------------------------------24---------------------------------------------------

IF OBJECT_ID('dbo.ejercicio24', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ejercicio24;
GO

CREATE PROCEDURE dbo.ejercicio24
AS
BEGIN
	DECLARE @depocitoCodigo char(2), @depocitoEncargado numeric(6,0), @depocitoZona char(3)
	DECLARE cursor_zona CURSOR FOR SELECT depo_codigo, depo_encargado, depo_zona FROM DEPOSITO
	OPEN cursor_zona
	FETCH NEXT FROM cursor_zona INTO @depocitoCodigo, @depocitoEncargado, @depocitoZona
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF ( @depocitoZona <> ( SELECT depa_zona FROM Departamento JOIN Empleado ON empl_departamento = depa_codigo WHERE empl_codigo = @depocitoEncargado ) )
		    UPDATE DEPOSITO SET depo_encargado = (
                                                    SELECT TOP 1 empl_codigo
                                                    FROM Empleado
                                                    JOIN DEPOSITO ON depo_encargado = empl_codigo
                                                    JOIN Departamento ON depa_codigo = empl_departamento
                                                    WHERE depa_zona = @depocitoZona
                                                    GROUP BY empl_codigo
                                                    ORDER BY COUNT(*) ASC
										        ) 
            
            WHERE depo_codigo = @depocitoCodigo
            

	    FETCH NEXT FROM cursor_zona INTO @depocitoCodigo, @depocitoEncargado, @depocitoZona
	END
	CLOSE cursor_zona
	DEALLOCATE cursor_zona
END
GO

---------------------------------------------------31---------------------------------------------------

CREATE PROCEDURE ej31 
AS 
BEGIN
    DECLARE @EMPLEADO NUMERIC(6), @JEFE_ALTERNATIVO NUMERIC(6), @CANTIDAD INT 
    DECLARE CURSOR_empleado CURSOR FOR SELECT empl_codigo FROM Empleado WHERE dbo.ej11(empl_codigo) > 20
    OPEN CURSOR_empleado
    FETCH NEXT FROM CURSOR_empleado INTO @EMPLEADO
    WHILE (@@FETCH_STATUS = 0)
    -- Busco a un jefe alternativo para redistribuir
    BEGIN
        SELECT @JEFE_ALTERNATIVO = empl_codigo FROM Empleado WHERE empl_codigo = @empleado AND dbo.ej11(empl_codigo) < 20
        
        -- Si no tengo un jefe alternativo, busco al gerente gral
        IF @JEFE_ALTERNATIVO IS NULL
            SELECT @JEFE_ALTERNATIVO = empl_codigo FROM Empleado WHERE empl_jefe IS NULL
        
        -- Redistribuyo a los excedentes
        UPDATE Empleado SET empl_jefe = @JEFE_ALTERNATIVO WHERE empl_jefe = @EMPLEADO
        
        FETCH NEXT FROM CURSOR_empleado INTO @EMPLEADO
    END
    CLOSE CURSOR_empleado
    DEALLOCATE CURSOR_empleado
END
GO
