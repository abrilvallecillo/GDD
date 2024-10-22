/* 23. Realizar una consulta SQL que para cada año muestre :

 Año
 El producto con composición más vendido para ese año.
 Cantidad de productos que componen directamente al producto más vendido
 La cantidad de facturas en las cuales aparece ese producto.
 El código de cliente que más compro ese producto.
 El porcentaje que representa la venta de ese producto respecto al total de venta
del año.

El resultado deberá ser ordenado por el total vendido por año en forma descendente. */

select year(f1.fact_fecha) as anio, p1.prod_codigo, (select count(*) from Composicion c1 where c1.comp_producto = p1.prod_codigo) as cant_componentes,
	   (select count(distinct(fact_numero)) from factura f2

	    join item_factura i2 on i2.item_producto = p1.prod_codigo

		where f2.fact_numero + f2.fact_tipo + f2.fact_sucursal = i2.item_numero + i2.item_tipo + i2.item_sucursal and year(f2.fact_fecha) = year(f1.fact_fecha)) as cant_facturas,
	   (select top 1 fact_cliente from factura f3
		
		join Item_Factura i3 on i3.item_numero + i3.item_tipo + i3.item_sucursal = f3.fact_numero + f3.fact_tipo + f3.fact_sucursal
		
		where i3.item_producto = p1.prod_codigo and year(f3.fact_fecha) = year(f1.fact_fecha)
		
		group by f3.fact_cliente
		
		order by sum(i3.item_cantidad) desc) as cliente_mas_compro,
		
		(fact_total / (select sum(fact_total) from factura f4
		
		 join item_factura i4 on i4.item_numero + i4.item_tipo + i4.item_sucursal = f4.fact_numero + f4.fact_tipo + f4.fact_sucursal
		 
		 where i4.item_producto = p1.prod_codigo and year(f4.fact_fecha) = year(f1.fact_fecha))) * 100 as porcentaje_venta,
		 
		 (select sum(fact_total) from factura f4
		
		 join item_factura i4 on i4.item_numero + i4.item_tipo + i4.item_sucursal = f4.fact_numero + f4.fact_tipo + f4.fact_sucursal
		 
		 where i4.item_producto = p1.prod_codigo and year(f4.fact_fecha) = year(f1.fact_fecha)) as total_vendido_anio from Producto p1

join item_factura i1 on i1.item_producto = p1.prod_codigo
join factura f1 on f1.fact_numero + f1.fact_tipo + f1.fact_sucursal = item_numero + item_tipo + item_sucursal

where p1.prod_codigo = (select top 1 p2.prod_codigo from producto p2
						
						join Composicion c2 on c2.comp_producto = p2.prod_codigo
						join item_factura i5 on i5.item_producto = p1.prod_codigo
						join factura f5 on f5.fact_numero + f5.fact_tipo + f5.fact_sucursal = i5.item_numero + i5.item_tipo + i5.item_sucursal
						
						where year(f5.fact_fecha) = year(f1.fact_fecha)

						group by p2.prod_codigo

						order by sum(i1.item_cantidad) desc)

group by year(f1.fact_fecha), p1.prod_codigo

order by cant_componentes, cant_facturas, cliente_mas_compro, porcentaje_venta, total_vendido_anio desc

/* 25. Realizar una consulta SQL que para cada año y familia muestre:

a. Año
b. El código de la familia más vendida en ese año.
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto más vendido de
esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
familia.
f. El código de cliente que más compro productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta
del año.

El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente. */

select year(fac1.fact_fecha) as anio, f1.fami_id as familia_mas_vendida, (select count(distinct prod_rubro) from producto where f1.fami_id = prod_familia) as cant_rubros,
	   isnull((select sum(comp_cantidad) from composicion
		
	   join producto on prod_codigo = comp_producto
	   join Item_Factura on item_producto = prod_codigo
	   join factura on fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal

	   where year(fact_fecha) = year(fac1.fact_fecha) and f1.fami_id = prod_familia and prod_codigo = (select top 1 item_producto from Item_Factura
					 
																									   join producto on prod_codigo = item_producto
																									   join factura on fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal

																									   where prod_familia = f1.fami_id and year(fact_fecha) = year(fac1.fact_fecha)

																									   group by item_producto
												   
																									   order by sum(item_cantidad) desc)

	   group by comp_producto), 1) as cant_prod_comp_mas_vendido, (select count(distinct item_numero) from Item_Factura

																   join Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
																   join producto on prod_codigo = item_producto 

																   where f1.fami_id = prod_familia and year(fact_fecha) = year(fac1.fact_fecha)) as cant_fact_pertenecientes, (select top 1 clie_codigo from cliente

																																											   join Factura on fact_cliente = clie_codigo
																																											   join Item_Factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
																																											   join Producto on prod_codigo = item_producto

																																											   where f1.fami_id = prod_familia and year(fact_fecha) = year(fac1.fact_fecha)

																																											   group by clie_codigo

																																											   order by count(distinct fact_numero) desc) as cliente_mas_compro, (select ((sum(i1.item_precio * i1.item_cantidad))/(select sum(item_precio * item_cantidad) from Item_Factura
												 
																																																																									join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
												 
																																																																									where year(fact_fecha) = year(fac1.fact_fecha))) * 100 from Item_Factura i1

																																																												  join producto on prod_codigo = i1.item_producto
																																																											      join factura on fact_numero + fact_sucursal + fact_tipo = i1.item_numero + i1.item_sucursal + i1.item_tipo

																																																												  where f1.fami_id = prod_familia and year(fact_fecha) = year(fac1.fact_fecha)) as porcentaje_venta_familia from familia f1

join producto on prod_familia = f1.fami_id
join Item_Factura on item_producto = prod_codigo
join factura fac1 on fac1.fact_numero + fac1.fact_sucursal + fac1.fact_tipo = item_numero + item_sucursal + item_tipo
									   
where f1.fami_id = (select top 1 fami_id from familia
									   
					join Producto on prod_familia = fami_id
					join Item_Factura on item_producto = prod_codigo
					join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
									   
					where year(fact_fecha) = year(fac1.fact_fecha)
									   
					group by fami_id
									   
					order by sum(item_cantidad) desc)

group by year(fac1.fact_fecha), f1.fami_id
					
order by sum(item_cantidad) desc, f1.fami_id,  anio

/* 28. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:

 Año.
 Codigo de Vendedor
 Detalle del Vendedor
 Cantidad de facturas que realizó en ese año
 Cantidad de clientes a los cuales les vendió en ese año.
 Cantidad de productos facturados con composición en ese año
 Cantidad de productos facturados sin composicion en ese año.
 Monto total vendido por ese vendedor en ese año

Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor. */

select year(f1.fact_fecha) as anio , f1.fact_vendedor, empl_nombre, 
	   (select count(*) from factura where fact_vendedor = f1.fact_vendedor and year(fact_fecha) = year(f1.fact_fecha)) as cant_fact_realizadas,
	   (select count(distinct fact_cliente) from factura where fact_vendedor = f1.fact_vendedor and year(fact_fecha) = year(f1.fact_fecha)) as cant_clientes_vendidos,
	   (select count(distinct comp_producto) from Composicion
	    
		join producto on prod_codigo = comp_producto
		join Item_Factura on item_producto = prod_codigo
		join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
		
		where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor) as prod_facturados_con_comp,
		(select count(distinct prod_codigo) from producto
		 
		 join Item_Factura on item_producto = prod_codigo
		 join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
		 
		 where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor and prod_codigo not in (select comp_producto from Composicion)) as prod_facturados_sin_comp,
		 (select sum(fact_total) from factura
		  
		  join empleado on empl_codigo = fact_vendedor
		  
		  where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor) as monto_total_vendido

from factura f1

join empleado on empl_codigo = f1.fact_vendedor

group by year(f1.fact_fecha), f1.fact_vendedor, empl_nombre

order by year(f1.fact_fecha), (select count(distinct prod_codigo) from producto
							   
		  join item_factura on item_producto = prod_codigo
		  join Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

		  where fact_vendedor = f1.fact_vendedor) desc

/* 31. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:

 Año.
 Codigo de Vendedor
 Detalle del Vendedor
 Cantidad de facturas que realizó en ese año
 Cantidad de clientes a los cuales les vendió en ese año.
 Cantidad de productos facturados con composición en ese año
 Cantidad de productos facturados sin composicion en ese año.
 Monto total vendido por ese vendedor en ese año

Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor. */

select year(f1.fact_fecha) as anio, f1.fact_vendedor as codig_vendedor, empl_nombre as nombre_vendedor, 
	   (select count(distinct fact_numero) from factura where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor) as cant_facturas,
	   (select count(distinct fact_cliente) from factura where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor) as cant_clientes, 
	   (select count(distinct comp_producto) from Composicion
	   
	    join Producto on prod_codigo = comp_producto
		join Item_Factura on item_producto = prod_codigo
		join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal
		
		where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor) as cant_prod_con_comp_vendidos,
		(select count(distinct prod_codigo) from producto

		join Item_Factura on item_producto = prod_codigo
		join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal
		
		where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor and prod_codigo not in (select comp_producto from composicion)) as cant_prod_sin_comp_vendidos,
		(select sum(fact_total) from factura where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor) as monto_total_vendido

from factura f1

join empleado on empl_codigo = fact_vendedor

group by year(f1.fact_fecha), f1.fact_vendedor, empl_nombre

order by anio, (select count(distinct prod_codigo) from producto
				
				join Item_Factura on item_producto = prod_codigo
				join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal
				
				where year(fact_fecha) = year(f1.fact_fecha) and fact_vendedor = f1.fact_vendedor) desc

/* 35. Se requiere realizar una estadística de ventas por año y producto, para ello se solicita
que escriba una consulta sql que retorne las siguientes columnas:

 Año
 Codigo de producto
 Detalle del producto
 Cantidad de facturas emitidas a ese producto ese año
 Cantidad de clientes diferentes que compraron ese producto ese año.
 Cantidad de productos a los cuales compone ese producto, si no compone a ninguno
se debera retornar 0.
 Porcentaje de la venta de ese producto respecto a la venta total de ese año.

Los datos deberan ser ordenados por año y por producto con mayor cantidad vendida. */

select year(f1.fact_fecha) as anio, p1.prod_codigo as producto, p1.prod_detalle as nombre_producto,
	   (select count(*) from factura
	   
	    join Item_Factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
		join producto on prod_codigo = item_producto
		
		where year(fact_fecha) = year(f1.fact_fecha) and prod_codigo = p1.prod_codigo) as cant_facturas_emitidas,
		(select count(distinct fact_cliente) from factura
		 
		 join Item_Factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
		 join producto on prod_codigo = item_producto
		
		 where year(fact_fecha) = year(f1.fact_fecha) and prod_codigo = p1.prod_codigo) as cant_clientes_dife,
		 isnull((select count(comp_producto) from Composicion where comp_producto = p1.prod_codigo), 0) as cant_prod_componen,
		 ((select sum(item_cantidad * item_precio) from Item_Factura
		  
		  join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
		  join producto on prod_codigo = item_producto
		  
		  where year(fact_fecha) = year(f1.fact_fecha) and prod_codigo = p1.prod_codigo) / (select sum(item_cantidad * item_precio) from item_factura 
																							
																							join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

																							where year(fact_fecha) = year(f1.fact_fecha))) * 100 as porcentaje_venta_producto

from factura f1

join Item_Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
join producto p1 on p1.prod_codigo = item_producto

group by year(f1.fact_fecha), p1.prod_codigo, p1.prod_detalle

order by anio, (select sum(item_cantidad) from Item_Factura
				
				join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

				where item_producto = p1.prod_codigo and year(fact_fecha) = year(f1.fact_fecha)) desc

select * from Composicion

/* 33. Se requiere obtener una estadística de venta de productos que sean componentes. Para
ello se solicita que realiza la siguiente consulta que retorne la venta de los
componentes del producto más vendido del año 2012. Se deberá mostrar:

a. Código de producto
b. Nombre del producto
c. Cantidad de unidades vendidas
d. Cantidad de facturas en la cual se facturo
e. Precio promedio facturado de ese producto.
f. Total facturado para ese producto

El resultado deberá ser ordenado por el total vendido por producto para el año 2012 */

select c1.comp_producto as producto_compuesto, p1.prod_codigo as codigo_prod_componente, p1.prod_detalle as nombre_prod_componente,
	   (select sum(item_cantidad) from item_factura
																	   
		join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

		where item_producto = p1.prod_codigo and year(fact_fecha) = '2012') as cant_vendida,
	    (select count(*) from factura
	    
		 join Item_Factura on item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo
		
		 where item_producto = p1.prod_codigo and year(fact_fecha) = '2012') as cant_facturas,
		 (select sum((item_cantidad * item_precio)) / sum(item_cantidad) from Item_Factura
		 
		  join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
		 
		  where item_producto = p1.prod_codigo and year(fact_fecha) = '2012') as promedio_facturado,
		  (select sum((item_cantidad * item_precio)) from Item_Factura
		 
		   join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
		 
		   where item_producto = p1.prod_codigo and year(fact_fecha) = '2012') as total_facturado

from producto p1

right join Composicion c1 on c1.comp_componente = p1.prod_codigo
join Item_Factura on item_producto = comp_producto
join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

where comp_producto = (select top 1 comp_producto from Composicion
													 
					   join Item_Factura on item_producto = comp_producto
					   join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
													 
					   where year(fact_fecha) = '2012' 

					   group by comp_producto

					   order by sum(item_cantidad) desc)

group by c1.comp_producto, p1.prod_codigo, p1.prod_detalle

order by (select sum((item_cantidad * item_precio)) from Item_Factura
		  
		  join Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
		  
		  where year(fact_fecha) = '2012' and item_producto = p1.prod_codigo) desc

/* 32. Se desea conocer las familias que sus productos se facturaron juntos en las mismas
facturas para ello se solicita que escriba una consulta sql que retorne los pares de
familias que tienen productos que se facturaron juntos. Para ellos deberá devolver las
siguientes columnas:

 Código de familia
 Detalle de familia
 Código de familia
 Detalle de familia
 Cantidad de facturas
 Total vendido

Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
que se vendieron juntas más de 10 veces. */

select fam1.fami_id as familia_id_1, fam1.fami_detalle as nombre_familia_1, fam2.fami_id as familia_id_2, fam2.fami_detalle as familia_nombre_2,
       count(distinct fact_numero) as cant_facturas_juntas, sum(fact_total) as total_vendido from familia fam1

join Producto p1 on p1.prod_familia = fam1.fami_id
join Item_Factura i1 on i1.item_producto = p1.prod_codigo
join factura on fact_numero + fact_sucursal + fact_tipo = i1.item_numero + i1.item_sucursal + i1.item_tipo
join Item_Factura i2 on i2.item_numero + i2.item_sucursal + i2.item_tipo = fact_numero + fact_sucursal + fact_tipo
join Producto p2 on p2.prod_codigo = i2.item_producto
join familia fam2 on fam2.fami_id = p2.prod_familia

where i1.item_producto != i2.item_producto and fam1.fami_id = p1.prod_familia and fam2.fami_id = p2.prod_familia

group by fam1.fami_id, fam1.fami_detalle, fam2.fami_id, fam2.fami_detalle

having count(distinct fact_numero) > 10 and fam1.fami_id < fam2.fami_id

order by total_vendido desc

/* 30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
consulta que retorne las siguientes columnas:

 Nombre del Jefe
 Cantidad de empleados a cargo
 Monto total vendido de los empleados a cargo
 Cantidad de facturas realizadas por los empleados a cargo
 Nombre del empleado con mejor ventas de ese jefe

Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
necesario.
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas. */

select e1.empl_nombre as jefe, 
       count(distinct e2.empl_codigo) as cant_empleados, 
	   isnull(sum(f1.fact_total), 0) as monto_total_vendido,
	   count(distinct f1.fact_numero) as cant_facturas_realizadas,
	   (select top 1 e3.empl_nombre from empleado e3
	    
		join empleado e4 on e4.empl_nombre = e1.empl_nombre
		join factura f2 on f2.fact_vendedor = e3.empl_codigo

		where e3.empl_jefe = e4.empl_codigo and year(f2.fact_fecha) = '2012'
		
		group by e3.empl_nombre
		
		order by sum(fact_total) desc) as empleado_con_mejor_ventas
from empleado e1

join empleado e2 on e2.empl_jefe = e1.empl_codigo
left join factura f1 on f1.fact_vendedor = e2.empl_codigo

where year(f1.fact_fecha) = '2012'

group by e1.empl_nombre

having count(distinct f1.fact_numero) > 10

order by monto_total_vendido desc