/* 19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio autom�ticamente �Ning�n jefe puede tener menos de 5 a�os de
antig�edad y tampoco puede tener m�s del 50% del personal a su cargo
(contando directos e indirectos) a excepci�n del gerente general�. Se sabe que en
la actualidad la regla se cumple y existe un �nico gerente general. */

create trigger ejer19 on Empleado after insert, update
as
BEGIN
	if exists (select 1 from empleado where empl_jefe is not null and DATEDIFF(year, empl_ingreso, GETDATE()) < 5)
	begin
		print('no se puede ser jefe con menos de 5 anios de ingreso')
		rollback
	end
	else if exists (select empl_jefe from empleado where empl_jefe is not null
					group by empl_jefe
					having count(*) > (select count(*) from empleado) / 2)
	begin
		print('no se puede tener mas del 50% del personal a cargo')
		rollback
	end
END
GO

/* 24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asign�rsele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona. */

create procedure ejer24
as
BEGIN
	declare @zonaDepartamento char(3), @zonaDeposito char(3)

	declare c1 cursor for select depo_codigo from deposito
		
						  join empleado on empl_codigo = depo_encargado
						  join departamento on depa_codigo = empl_departamento

						  where depa_zona = @zonaDepartamento and depo_zona = @zonaDeposito
	open c1
	fetch next from c1 into @zonaDepartamento, @zonaDeposito
	while @@FETCH_STATUS = 0
	begin
		if (@zonaDepartamento != @zonaDeposito)
		begin
			update DEPOSITO set depo_encargado = (select top 1 empl_codigo from empleado
							  
												  join Departamento on depa_codigo = empl_departamento
												  join DEPOSITO on depo_encargado = empl_codigo

												  where depa_zona = @zonaDeposito

												  group by empl_codigo

												  order by count(*))
		end
		fetch next from c1 into @zonaDepartamento, @zonaDeposito
	end
	close c1
	deallocate c1
END
GO
/* 30 Agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar m�s de 100 unidades en el mes de ning�n producto, si esto
ocurre no se deber� ingresar la operaci�n y se deber� emitir un mensaje �Se ha
superado el l�mite m�ximo de compra de un producto�. Se sabe que esta regla se
cumple y que las facturas no pueden ser modificadas. */

create trigger ej_30  on item_factura instead of insert
as
BEGIN
	declare @cant int, @cliente char(5), @prod_codigo char(8), @fecha date

	select @cant = i.item_cantidad, @cliente = f1.fact_cliente, @prod_codigo = i.item_producto, @fecha = f1.fact_fecha from inserted i

	join factura f1 on f1.fact_numero + f1.fact_sucursal + f1.fact_tipo = i.item_numero + i.item_sucursal + i.item_tipo

	if(select sum(i2.item_cantidad) from Item_Factura i2
	    
	   join factura f2 on f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = i2.item_numero + i2.item_sucursal + i2.item_tipo
		
	   where f2.fact_cliente = @cliente and i2.item_producto = @prod_codigo and MONTH(f2.fact_fecha) = MONTH(@fecha) and year(f2.fact_fecha) = year(@fecha)) + @cant > 100
	begin
		print('se supero la compra permitida')
		rollback
	end
	else
	begin
		insert into item_factura(item_numero, item_sucursal, item_tipo, item_producto, item_cantidad, item_precio)
		SELECT item_numero, item_sucursal, item_tipo, item_producto, item_cantidad, item_precio FROM inserted;
	end
END
GO
/* 31. Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda
tener m�s de 20 empleados a cargo, directa o indirectamente, si esto ocurre
debera asignarsele un jefe que cumpla esa condici�n, si no existe un jefe para
asignarle se le deber� colocar como jefe al gerente general que es aquel que no
tiene jefe. */

create trigger ej_31 on Empleado for update
as
BEGIN
	declare @gerente_general char(1), @cantEmpleados int, @empleado char(1), @jefe_Actual char(1), @nuevo_jefe char(1)

	select gerente_general  = empl_codigo from empleado where empl_jefe = null

	-- Crear una tabla temporal para almacenar los jefes que cumplen con la condici�n
	create table #JefesDisponibles (jefe_codigo INT)
	
	-- Insertar jefes que tienen menos de 20 empleados (directos e indirectos) a cargo
	INSERT INTO #JefesDisponibles (jefe_codigo)
    SELECT e1.empl_codigo FROM Empleado e1
    WHERE (SELECT COUNT(*) FROM Empleado e2 WHERE e2.empl_jefe = e1.empl_codigo) <= 20

	WITH EmpleadosCTE AS (SELECT empl_jefe, empl_codigo FROM Empleado WHERE empl_jefe IS NOT NULL
						  
						  UNION ALL 
						  
						  SELECT e.empl_jefe, cte.empl_codigo FROM Empleado e 

						  JOIN EmpleadosCTE cte ON e.empl_codigo = cte.empl_jefe)
    INSERT INTO #JefesDisponibles (jefe_codigo)
    SELECT e1.empl_codigo FROM Empleado e1

    LEFT JOIN EmpleadosCTE e2 ON e1.empl_codigo = e2.empl_jefe

    GROUP BY e1.empl_codigo
    HAVING COUNT(e2.empl_codigo) <= 20

	-- Crear un cursor para recorrer los jefes con m�s de 20 empleados a cargo
	DECLARE jefe_cursor CURSOR FOR WITH EmpleadosCTE AS (SELECT empl_jefe, empl_codigo FROM Empleado WHERE empl_jefe IS NOT NULL
						  
														 UNION ALL 
														 
														 SELECT e.empl_jefe, cte.empl_codigo FROM Empleado e
									 
														 JOIN EmpleadosCTE cte ON e.empl_codigo = cte.empl_jefe)
								   SELECT e1.empl_codigo FROM Empleado e1
    
								   LEFT JOIN EmpleadosCTE e2 ON e1.empl_codigo = e2.empl_jefe
    
								   GROUP BY e1.empl_codigo
								   HAVING COUNT(e2.empl_codigo) > 20
	OPEN jefe_cursor
    FETCH NEXT FROM jefe_cursor INTO @jefe_actual

    WHILE @@FETCH_STATUS = 0
    begin

		-- Crear un cursor para recorrer los empleados a cargo del jefe actual
        DECLARE empleado_cursor CURSOR FOR WITH EmpleadosCTE AS (SELECT empl_jefe, empl_codigo FROM Empleado
																 
																 WHERE empl_jefe = @jefe_actual
																 
																 UNION ALL 
																 
																 SELECT e.empl_jefe, cte.empl_codigo FROM Empleado e
																			
																 JOIN EmpleadosCTE cte ON e.empl_codigo = cte.empl_jefe)
								SELECT empl_codigo FROM EmpleadosCTE
		OPEN empleado_cursor
        FETCH NEXT FROM empleado_cursor INTO @empleado

        WHILE @@FETCH_STATUS = 0
        begin

            -- Buscar un nuevo jefe que cumpla con la condici�n
            SELECT TOP 1 @nuevo_jefe = jefe_codigo FROM #JefesDisponibles
			
			WHERE jefe_codigo <> @jefe_actual

			 -- Si no se encuentra un nuevo jefe, asignar al gerente general
            IF @nuevo_jefe IS NULL
                SET @nuevo_jefe = @gerente_general

            -- Asignar el nuevo jefe al empleado
            UPDATE Empleado SET empl_jefe = @nuevo_jefe WHERE empl_codigo = @empleado

            -- Actualizar la tabla temporal de jefes disponibles
            DELETE FROM #JefesDisponibles WHERE jefe_codigo = @nuevo_jefe

			INSERT INTO #JefesDisponibles (jefe_codigo)
			
            SELECT e1.empl_jefe, e1.empl_codigo FROM Empleado e1

			WHERE e1.empl_jefe = @nuevo_jefe

			UNION ALL 

			SELECT e2.empl_jefe, e1.empl_codigo FROM Empleado e2

			join empleado e1 on e1.empl_jefe = e2.empl_codigo
            
			GROUP BY e1.empl_codigo
            HAVING COUNT(e1.empl_codigo) <= 20

			FETCH NEXT FROM empleado_cursor INTO @empleado
		end

		close empleado_cursor
		deallocate empleado_cursor

		FETCH NEXT FROM jefe_cursor INTO @jefe_actual
	end

	CLOSE jefe_cursor
    DEALLOCATE jefe_cursor

    -- Limpiar la tabla temporal
    DROP TABLE #JefesDisponibles
END
GO
/* 22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga m�s de 20 productos asignados, si un rubro tiene m�s de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpci�n �RUBRO REASIGNADO�, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada */

CREATE PROCEDURE RecategorizarRubros
AS
BEGIN
    DECLARE @rubro_actual char(4), @familia_actual char(3), @nuevo_rubro char(4), @producto char(8)

    -- Crear un cursor para recorrer los rubros con m�s de 20 productos
    DECLARE rubro_cursor CURSOR FOR SELECT prod_rubro, prod_familia, COUNT(prod_codigo) as cantidad_productos FROM Producto
									
									GROUP BY prod_rubro, prod_familia
									
									HAVING COUNT(prod_codigo) >= 20

    OPEN rubro_cursor
    FETCH NEXT FROM rubro_cursor INTO @rubro_actual, @familia_actual

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Crear un cursor para recorrer los productos del rubro actual
        DECLARE producto_cursor CURSOR FOR SELECT prod_codigo FROM Producto WHERE prod_rubro = @rubro_actual

        OPEN producto_cursor
        FETCH NEXT FROM producto_cursor INTO @producto

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Buscar un nuevo rubro en la misma familia que tenga menos de 20 productos
            SELECT TOP 1 @nuevo_rubro = prod_rubro FROM producto 

            WHERE prod_familia = @familia_actual

            GROUP BY prod_rubro
            HAVING COUNT(prod_codigo) < 20 AND @nuevo_rubro <> @rubro_actual

            -- Si no se encuentra un nuevo rubro, crear uno nuevo
            IF @nuevo_rubro IS NULL
            BEGIN
                INSERT INTO Rubro (rubr_detalle)
                VALUES ('RUBRO REASIGNADO')

                SET @nuevo_rubro = SCOPE_IDENTITY()
            END

            -- Asignar el producto al nuevo rubro
			UPDATE Producto
            SET prod_rubro = @nuevo_rubro
            WHERE prod_codigo = @producto

            FETCH NEXT FROM producto_cursor INTO @producto
        END

        CLOSE producto_cursor
        DEALLOCATE producto_cursor

        FETCH NEXT FROM rubro_cursor INTO @rubro_actual, @familia_actual
    END

    CLOSE rubro_cursor
    DEALLOCATE rubro_cursor
END
GO
/* 23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse m�s
de dos productos con composici�n. Si esto ocurre debera rechazarse la factura. */

create trigger ej23 on item_factura instead of insert
as
BEGIN
    -- Contar la cantidad de productos con composici�n en la factura
    IF (SELECT COUNT(distinct item_producto) FROM Item_Factura i1
        
		join Composicion c1 ON c1.comp_producto = i1.item_producto
		join factura f1 on f1.fact_numero + f1.fact_sucursal + f1.fact_tipo = i1.item_numero + i1.item_sucursal + i1.item_tipo) > 2
    BEGIN
        -- Si hay m�s de 2 productos con composici�n, rechazar la factura
        print ('No se pueden vender m�s de dos productos con composici�n en una misma factura.')
        ROLLBACK
    END
END
GO
/* Implementar una regla de negocio en linea que registre los productos que al momento de venderse 
registraron un aumento superior al 10% del precio de venta que tuvieron en el mes anterior. 
Se deber� registrar el producto, la fecha en el cual se hace la venta, el precio anterior y el�precio�nuevo. */

CREATE TABLE registroAumentoPrecio (
    producto_codigo CHAR(8),
    fecha_venta DATE,
    precio_anterior int,
    precio_nuevo int
)
GO

CREATE TRIGGER trg_AumentoPrecio
ON Item_factura
AFTER INSERT
AS
BEGIN

    DECLARE @prod_codigo CHAR(8), @fecha_venta DATE, @precio_nuevo int, @precio_anterior int;

    DECLARE venta_cursor CURSOR FOR
        SELECT i1.item_producto, f1.fact_fecha, i1.item_precio FROM inserted i1
        
		JOIN Factura f1 ON f1.fact_numero + f1.fact_tipo + f1.fact_sucursal = i1.item_numero + i1.item_tipo + i1.item_sucursal

		group by i1.item_producto, f1.fact_fecha, i1.item_precio

    OPEN venta_cursor

    FETCH NEXT FROM venta_cursor INTO @prod_codigo, @fecha_venta, @precio_nuevo

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @precio_anterior = AVG(i2.item_precio) FROM Item_factura i2
       
	    JOIN Factura f2 ON f2.fact_numero + f2.fact_tipo + f2.fact_sucursal = i2.item_numero + i2.item_tipo + i2.item_sucursal
        
		WHERE i2.item_producto = @prod_codigo AND DATEDIFF(month, @fecha_venta, f2.fact_fecha) = 1

        IF @precio_nuevo > @precio_anterior * 1.1
        BEGIN
            INSERT INTO registroAumentoPrecio(producto_codigo, fecha_venta, precio_anterior, precio_nuevo)
            select @prod_codigo, @fecha_venta, @precio_anterior, @precio_nuevo
        END

        FETCH NEXT FROM venta_cursor INTO @prod_codigo, @fecha_venta, @precio_nuevo
    END

    CLOSE venta_cursor
    DEALLOCATE venta_cursor
END
GO