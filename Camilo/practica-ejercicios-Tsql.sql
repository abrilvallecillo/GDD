/* 1. Hacer una funci�n que dado un art�culo y un deposito devuelva un string que
indique el estado del dep�sito seg�n el art�culo. Si la cantidad almacenada es
menor al l�mite retornar �OCUPACION DEL DEPOSITO XX %� siendo XX el
% de ocupaci�n. Si la cantidad almacenada es mayor o igual al l�mite retornar
�DEPOSITO COMPLETO�. */

--"create" para crear la funcion. Una vez creada, si la quiero modificar, uso "alter"

create function ej1 (@articulo char(8), @deposito char(2))
returns varchar(50)
as 
BEGIN
	declare @cantidad decimal(12,2), @limite decimal(12, 2)
	select @cantidad = isnull(stoc_cantidad, 0), @limite = isnull(stoc_stock_maximo, 1) from stock where stoc_producto = @articulo and stoc_deposito = @deposito

	if @cantidad >= @limite 
		return 'DEPOSITO COMPLETO' 
	return 'OCUPACION DEL DEPOSITO ' + @deposito + ' ' + str((@cantidad / @limite) * 100) + '%'
end
go

select prod_codigo, prod_detalle, stoc_deposito, stoc_cantidad, stoc_stock_maximo, dbo.ej1(stoc_producto, stoc_deposito) from producto 

join stock on prod_codigo = stoc_producto

order by prod_detalle

/* 3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que deber�a existir un �nico gerente general
(deber�a ser el �nico empleado sin jefe). Si detecta que hay m�s de un empleado
sin jefe deber� elegir entre ellos el gerente general, el cual ser� seleccionado por
mayor salario. Si hay m�s de uno se seleccionara el de mayor antig�edad en la
empresa. Al finalizar la ejecuci�n del objeto la tabla deber� cumplir con la regla
de un �nico empleado sin jefe (el gerente general) y deber� retornar la cantidad
de empleados que hab�a sin jefe antes de la ejecuci�n. */

create procedure ej3 (@cantidad int output)
as 
begin
	declare @gerenteGeneral numeric(6)

	select @cantidad = count(*) from empleado where empl_jefe is NULL

	if @cantidad > 1 
		begin
			select top 1 @gerenteGeneral = empl_codigo from empleado where empl_jefe is NULL
			order by empl_salario desc, empl_ingreso

			update empleado set empl_jefe = @gerenteGeneral where empl_jefe is NULL and empl_codigo <> @gerenteGeneral
		end
end
go

begin
declare @cant integer 
exec dbo.ej3 @cant
print @cant
end
go
/* 6. Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deber� reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda */

create procedure ej6
AS
BEGIN
	declare @combo char(8)
	declare @comboCant integer
	declare @fact_tipo char(1)
	declare @fact_suc char(4)
	declare @fact_num char(8)

	declare cFacturas cursor for 
		select fact_tipo, fact_sucursal, fact_numero FROM factura

		open cFacturas

		fetch next from cFacturas
		into @fact_tipo, @fact_suc, @fact_num

		while @@FETCH_STATUS = 0
		begin 
			declare cProducto cursor for 
			select comp_producto from Item_Factura
			join Composicion C1 on item_producto = C1.comp_componente
			where item_cantidad >= C1.comp_cantidad and
				  item_sucursal = @fact_suc and
				  item_numero = @fact_num and
				  item_tipo = @fact_tipo
			group by C1.comp_producto
			having count(*) = (select count(*) from Composicion C2 where C2.comp_producto = C1.comp_producto)

			open Cproducto

			fetch next from cProducto into @combo
			while @@FETCH_STATUS = 0
			begin
				select @comboCant = min(floor((item_cantidad / c1.comp_cantidad))) from Item_Factura
				join Composicion C1 on item_producto = C1.comp_componente

				where item_cantidad >= C1.comp_cantidad and
				      item_sucursal = @fact_suc and
					  item_numero = @fact_num and
					  item_tipo = @fact_tipo and
					  C1.comp_producto = @combo

				insert into item_factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
				select @fact_tipo, @fact_suc, @fact_num, @combo, @comboCant, (@comboCant * (select prod_precio from producto where prod_codigo = @combo))

				update item_factura 
				set 
				item_cantidad = I1.item_cantidad - (@comboCant * (select comp_cantidad from Composicion 
																  where I1.item_producto = comp_componente and comp_producto = @combo)),
				item_precio = (I1.item_cantidad - (@comboCant * (select comp_cantidad from Composicion 
																 where I1.item_producto = comp_componente and comp_producto = @combo))) * (select prod_precio from producto
																																		   where prod_codigo = I1.item_producto)
				from item_factura I1, composicion C1
				where I1.item_sucursal = @fact_suc and
					  I1.item_numero = @fact_num and
					  I1.item_tipo = @fact_tipo and
					  I1.item_producto = C1.comp_componente and
					  C1.comp_producto = @combo

				delete from Item_Factura
				where item_sucursal = @fact_suc and
					  item_numero = @fact_num and
					  item_tipo = @fact_tipo and
					  item_cantidad = 0

			    fetch next from cProducto into @combo
			end
			close cProducto
			deallocate cProducto

			fetch next from cFacturas into @fact_tipo, @fact_suc, @fact_num
		end
		close cFacturas 
		deallocate cFacturas
end
go
/* 9. Crear el/los objetos de base de datos que ante alguna modificaci�n de un �tem de
factura de un art�culo con composici�n realice el movimiento de sus
correspondientes componentes. */

create trigger ej9 on item_factura for insert 
as
begin
	declare @prod char(8), @cant decimal(12,2), @deposito char(2)
	declare c1 cursor for

	select comp_componente, item_cantidad * comp_cantidad from inserted join composicion on item_producto = comp_producto

	open c1
	fetch next from c1 into @prod, @cant

	while @@FETCH_STATUS = 0
	begin
		select @deposito = stoc_deposito from stock where stoc_producto = @prod

		order by stoc_cantidad desc

		update stock set stoc_cantidad = stoc_cantidad - @cant

		where stoc_producto = @prod and stoc_deposito = @deposito

		fetch next from c1 into @prod, @cant
	end
	close c1
	deallocate c1
end
go

/* 10. Crear el/los objetos de base de datos que ante el intento de borrar un art�culo
verifique que no exista stock y si es as� lo borre en caso contrario que emita un
mensaje de error. */

create trigger ej10 on producto instead of delete
AS
BEGIN
	declare @prod char(8)
	declare c1 cursor for select prod_codigo from deleted
	open c1
	fetch next into @prod
	while @@FETCH_STATUS = 0
	begin
		if (select count(*) from stock where stoc_producto = @prod and stoc_cantidad > 0) > 0
			print('no se pueden borrar productos con stock ' + @prod)
		else
			begin
				delete from stock where stoc_producto = @prod
				delete from producto where prod_codigo = @prod
			end
		fetch next into @prod
	end
	close c1
	deallocate c1
END
go
/* 11. Cree el/los objetos de base de datos necesarios para que dado un c�digo de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un c�digo mayor que su jefe directo. */

create function ej11 (@empleado numeric(6))
returns integer
AS
BEGIN
	declare @cantidad integer
	select @cantidad  = 0
	if (select count(*) from empleado where empl_jefe = @empleado) = 0
		return @cantidad
	select @cantidad = count(*) from empleado where empl_jefe = @empleado

	declare @jefe numeric(6)
	declare c1 cursor for select empl_codigo from empleado where empl_jefe = @empleado
	open c1
	fetch next into @jefe 
	while @@FETCH_STATUS = 0
	begin
		select @cantidad = @cantidad + dbo.ej11(@jefe)
		fetch next into @jefe 
	end
	close c1
	deallocate c1
	return @cantidad
END
go
/* 12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por s� mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnolog�as. No se conoce la cantidad de niveles de composici�n existentes. */

create trigger ej12 on composicion after insert, update
AS
BEGIN
	if (select sum(dbo.compone(comp_producto, comp_componente)) from inserted) > 0
	begin
		print('el producto esta compuesto por si mismo')
		rollback
	end
END
go

create function compone (@producto char(8), @componente char(8))
returns int
AS
BEGIN
	declare @comp char(8)
	if @componente = @producto 
		return 1
	declare c1 cursor for select comp_componente from composicion where comp_producto = @componente
	open c1
	fetch next from c1 into @comp
	while @@FETCH_STATUS = 0
	begin
		if dbo.compone(@producto, @comp) > 0
		begin
			close c1
			deallocate c1
			return 1
		end
		fetch next from c1 into @comp
	end
	close c1
	deallocate c1
	return 0
END
go
/* 13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
�Ning�n jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)�. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnolog�as */

create trigger eje13 on empleado for insert, update, delete
AS
BEGIN
	if exists (select * from inserted i
			   where dbo.ej13(empl_jefe) < (select empl_salario * 0.2 from empleado where empl_codigo =i.empl_jefe))
	begin
		print('el salario del jefe es mayor')
		rollback
	end
	if exists (select * from deleted d
			   where dbo.ej13(empl_jefe) < (select empl_salario * 0.2 from empleado where empl_codigo =d.empl_jefe))
	begin
		print('el salario del jefe es mayor')
		rollback
	end
END
go
create function [dbo].[ej13] (@empleado numeric(6))
returns integer
AS
BEGIN
	declare @salario decimal(12,2)
	select @salario  = 0
	if not exists (select sum(empl_salario) from empleado where empl_jefe = @empleado)
		return @salario
	select @salario = sum(empl_salario) from empleado where empl_jefe = @empleado
	declare @jefe numeric(6)
	declare c1 cursor for select empl_codigo from empleado where empl_jefe = @empleado
	open c1
	fetch next into @jefe 
	while @@FETCH_STATUS = 0
	begin
		select @salario = @salario + dbo.ej13(@jefe)
		fetch next into @jefe 
	end
	close c1
	deallocate c1
	return @salario
END
go
/* 14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qu� precio se realiz� la
compra. No se deber� permitir que dicho precio sea menor a la mitad de la suma
de los componentes. */

create trigger ej14 on item_factura instead of insert 
AS
BEGIN
	declare @prod char(8), 
			@precio decimal(12,4), 
			@fecha datetime, 
			@cliente char(4), 
			@tipo char(1), 
			@sucursal char(4), 
			@numero char(8), 
			@cantidad decimal(12,2)
	
	declare c1 cursor for select item_producto, item_precio, fact_fecha, fact_cliente, fact_tipo, fact_sucursal, fact_numero, item_cantidad 
						from inserted
						join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
						where item_producto in (select comp_producto from Composicion)
	
	open c1
	fetch next into @prod, 
					@precio, 
					@fecha, 
					@cliente, 
					@tipo, 
					@sucursal, 
					@numero, 
					@cantidad

	while @@FETCH_STATUS = 0
	begin
		if @precio < (select sum(prod_precio * comp_cantidad) 
						from composicion 
						join producto on prod_codigo = comp_componente 
						group by comp_producto
					) * 2
		
		begin
			print('no se puede ingresar el producto ' + @prod)
			fetch next into @prod, @precio, @fecha, @cliente, @tipo, @sucursal, @numero, @cantidad
			continue
		end
		
		if @precio < (select sum(prod_precio * comp_cantidad)
						from composicion 
						join producto on prod_codigo = comp_componente 
						group by comp_producto
					)
			print(@prod + @fecha + @cliente)

		insert item_factura(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
		
		values(@tipo, @sucursal, @numero, @prod, @cantidad, @precio)
		
		fetch next into @prod, @precio, @fecha, @cliente, @tipo, @sucursal, @numero, @cantidad
	end
	close c1
	deallocate c1
END
go
/* 18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas */

CREATE TRIGGER ej18 ON Factura AFTER INSERT
AS
BEGIN
	declare @cliente char(4), @anio numeric(4), @mes numeric(2)
	declare c1 cursor for select fact_cliente, year(fact_fecha), month(fact_fecha) from inserted
	open c1
	fetch next from c1 into @cliente, @anio, @mes
	while @@FETCH_STATUS = 0
	begin
		if (SELECT SUM(fact_total) FROM inserted WHERE fact_cliente = @cliente and year(fact_fecha) = @anio and MONTH(fact_fecha) = @mes) > 
			(SELECT clie_limite_credito FROM cliente where (@cliente = clie_codigo)) 
		begin
			PRINT 'Se supero el limite de credito'
			close c1
			deallocate c1
			ROLLBACK
		end
	fetch next from c1 into @cliente, @anio, @mes
	end
	close c1
	deallocate c1
END
go