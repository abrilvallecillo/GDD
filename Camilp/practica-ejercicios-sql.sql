/* 1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente. */

select clie_codigo, clie_razon_social from cliente

where clie_limite_credito >= 1000

order by clie_codigo

/* 2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.*/

select prod_codigo, prod_detalle, count(*) as veces_vendido from Producto

join Item_Factura on item_producto = prod_codigo
join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

where year(fact_fecha) = 2012

group by prod_codigo, prod_detalle

order by veces_vendido

/* 3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor. */

select prod_codigo, prod_detalle, sum(isnull(stoc_cantidad, 0)) as cant_total_stock from Producto

left join stock on stoc_producto = prod_codigo

group by prod_codigo, prod_detalle

order by prod_detalle

/*4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100. */

select prod_codigo, prod_detalle, avg(isnull(stoc_cantidad, 0)) as promedio_cant_stock from producto

join stock on stoc_producto = prod_codigo

group by prod_codigo, prod_detalle

having avg(isnull(stoc_cantidad, 0)) > 100

/* 5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011. */

select prod_codigo, prod_detalle, sum(item_cantidad) as cant_egresos from Producto

join Item_Factura on item_producto = prod_codigo
join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

where year(fact_fecha) = 2012

group by prod_codigo, prod_detalle

having sum(item_cantidad) > (select sum(item_cantidad) from Item_Factura 

							join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

							where  item_producto = prod_codigo and year(fact_fecha)=2011)

order by cant_egresos

/* 6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’. */

select rubr_id, rubr_detalle, count(prod_rubro) as cant_articulos_x_rurbo, sum(stoc_cantidad) as cantidad_articulos_stock from rubro

join producto on rubr_id = prod_rubro
join stock on stoc_producto = prod_codigo

group by rubr_id, rubr_detalle

having sum(stoc_cantidad) > (select sum(stoc_cantidad) from stock
							
							  where stoc_producto = '00000000' and stoc_deposito = '00')

order by cant_articulos_x_rurbo, cantidad_articulos_stock

/* 7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =10, 
mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean stock. */

select prod_codigo, prod_detalle, max(item_precio) as maximo_precio, min(item_precio) as minimo_precio, (max(item_precio) - min(item_precio))/(min(item_precio) * 100) as porcentaje_diferencia from producto

join Item_Factura on item_producto = prod_codigo

where (select sum(isnull(stoc_cantidad, 0)) from stock
		
		where stoc_producto = prod_codigo) > 0

group by prod_codigo, prod_detalle

order by  maximo_precio, minimo_precio, porcentaje_diferencia

/* 8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene. */ 

select prod_detalle, stoc_cantidad, max(stoc_cantidad) as maximo_stock from producto

join stock on stoc_producto = prod_codigo

where stoc_cantidad > 0

group by prod_detalle, stoc_cantidad

having count(*) = (select count(*) from DEPOSITO)

order by maximo_stock

/* 9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados */

SELECT empl_jefe, empl_codigo, empl_nombre, COUNT(depo_encargado) depositos_en_comun FROM Empleado

LEFT JOIN DEPOSITO ON depo_encargado = empl_codigo OR depo_encargado = empl_jefe

GROUP BY empl_jefe, empl_codigo, empl_nombre

ORDER BY empl_jefe

/* 10) Mostrar los 10 productos más vendidos en la historia y también los 10 productos
menos vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que mayor compra realizo */

SELECT prod_codigo, (SELECT TOP 1 fact_cliente FROM Factura

                      JOIN Item_Factura ON item_numero = fact_numero

                      WHERE item_producto = prod_codigo

                      GROUP BY fact_cliente

                      ORDER BY SUM(item_cantidad) DESC) cliente_que_mas_lo_compro FROM Producto

WHERE prod_codigo IN  (SELECT TOP 10 item_producto FROM Item_Factura

                        GROUP BY item_producto

                        ORDER BY SUM(item_cantidad) DESC) OR prod_codigo IN (SELECT TOP 10 item_producto FROM Item_Factura

																			  GROUP BY item_producto

																			  ORDER BY SUM(item_cantidad)) 

/* 11) Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de productos vendidos
y el monto de dichas ventas sin impuestos. Los datos se deberán ordenar de mayor a menor, por la familia que
más productos diferentes vendidos tenga, solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para el año 2012. */

/* total sin impuestos de una venta de calcula con: item_cantidad * item_precio */
SELECT fami_detalle, COUNT(distinct prod_codigo) cantidad_de_productos_diferentes_vendidos, SUM(item_cantidad * item_precio) monto_de_ventas_sin_impuestos FROM Familia

JOIN  Producto ON prod_familia = fami_id

JOIN Item_Factura ON item_producto = prod_codigo

WHERE fami_id IN (SELECT prod_familia FROM Factura

                   JOIN Producto ON prod_codigo = item_producto

                   JOIN Item_Factura ON item_numero = fact_numero

                   WHERE YEAR(fact_fecha) = 2012

                   GROUP BY prod_familia

                   HAVING SUM(item_cantidad * item_precio) > 20000)

GROUP BY fami_detalle, fami_id

ORDER BY cantidad_de_productos_diferentes_vendidos DESC

/* 12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
producto y stock actual del producto en todos los depósitos. Se deberán mostrar
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
ordenarse de mayor a menor por monto vendido del producto */

select prod_detalle, count(distinct fact_cliente) cant_clientes_distintos, avg(item_precio) importe_pagado_promedio, count(distinct stoc_deposito) cant_depositos_con_stock, sum(stoc_cantidad) suma_total_stock from producto

join Item_Factura on item_producto = prod_codigo
join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
join stock on stoc_producto = prod_codigo

where year(fact_fecha) = 2012 and stoc_cantidad > 0

group by prod_detalle

order by sum(item_cantidad) desc, cant_clientes_distintos, importe_pagado_promedio, cant_depositos_con_stock, suma_total_stock

/* 13. Realizar una consulta que retorne para cada producto que posea composición nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
de los productos que lo componen. Solo se deberán mostrar los productos que estén
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen. */

select p1.prod_detalle, p1.prod_precio, sum(comp_cantidad * p2.prod_precio) as suma_por_cantidad from producto p1

join Composicion on comp_producto = p1.prod_codigo
join producto p2 on p2.prod_codigo = comp_componente

group by p1.prod_detalle, p1.prod_precio

having count(*) >= 2

order by count(*) desc

/* 14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que debe retornar son:

Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año

Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año. No se deberán visualizar NULLs en ninguna columna */

SELECT clie_codigo, count(fact_cliente) as cant_veces_compro, avg(fact_total) as promedio_por_compra, (select count(distinct item_producto) from Item_Factura

																										join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

																										where fact_cliente = clie_codigo and year(fact_fecha) = (select max(year(fact_fecha)) from Factura)) as cant_prod_diferentes, max(fact_total) as monto_compra_max from cliente

join factura on fact_cliente = clie_codigo

where year(fact_fecha) = (select max(year(fact_fecha)) from factura)

group by clie_codigo

order by cant_veces_compro

/* 15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.

Ejemplo de lo que retornaría la consulta:

PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2 */

select p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle, count(*) as veces_vendidos from Producto p1

join Item_Factura i1 on i1.item_producto = p1.prod_codigo
join Item_Factura i2 on i2.item_numero + i2.item_sucursal + i2.item_tipo = i1.item_numero + i1.item_sucursal + i1.item_tipo
join producto p2 on p2.prod_codigo = i2.item_producto

where p1.prod_codigo < p2.prod_codigo

group by p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle

having count(*) > 500

order by veces_vendidos

/* 16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas compras
son inferiores a 1/3 del monto de ventas del producto que más se vendió en el 2012.

Además mostrar

1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente. */

select clie_codigo, clie_razon_social, sum(item_cantidad) as cant_unidades_compradas, count(*) as cant_veces_compro, ((select top 1 prod_codigo from producto 
				   
																														join Item_Factura on item_producto = prod_codigo
																														join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

																														where fact_cliente = clie_codigo and year(fact_fecha) = 2012
				   
																														group by prod_codigo
				   
																														order by sum(item_cantidad) desc, prod_codigo)) as producto_mas_vendido from cliente

join factura on fact_cliente = clie_codigo
join Item_Factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

where year(fact_fecha) = 2012

group by clie_codigo, clie_razon_social

having count(*) < ((select top 1 sum(item_cantidad) from producto 
				   
				   join Item_Factura on item_producto = prod_codigo
				   join factura on fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo

				   where year(fact_fecha) = 2012
				   
				   group by prod_codigo
				   
				   order by sum(item_cantidad) desc) / 3)

order by cant_veces_compro, cant_unidades_compradas, producto_mas_vendido

/* 17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada producto.

La consulta debe retornar:

PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el periodo

La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto. */

select prod_codigo, prod_detalle, format(fact_fecha, 'yyyy-MM') from producto

join Item_Factura on item_producto = prod_codigo
join factura on fact_sucursal + fact_tipo + fact_numero = item_sucursal + item_tipo + item_numero

group by prod_codigo, prod_detalle, fact_fecha

order by prod_codigo