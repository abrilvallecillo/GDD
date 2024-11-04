-- EL SUBSELECT ES LA ULTIMA OPCION Y SOLO SE USA CUANDO LAS CONDICIONES SON DISTINTAS O CUANDO HAY UN TOP

-----------------------------------------------------------2-----------------------------------------------------------

-- Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por cantidad vendida.

-- 1. Empezamos por el FROM --> Donde estan las ventas de los productos (19484 Renglones de Facturas)

SELECT * FROM Item_Factura 

-- 2. Me fijo que tengo que traer y en que tabla se encuentra (19484 Prodctos, correspondientes a un Renglon de la Factura) 

SELECT * 
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 

-- 3. Que es la cantidad vendida?? Contar todas las cantidades de un producto --> Juntas el mismo codigo y luego lo sumas

SELECT Producto.prod_codigo, Producto.prod_detalle, SUM(Item_Factura.item_cantidad)
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 
GROUP BY Producto.prod_codigo, Producto.prod_detalle
ORDER BY SUM(Item_Factura.item_cantidad)

-- 4. Filtro por el año que me interesa

SELECT Producto.prod_codigo, Producto.prod_detalle, SUM(Item_Factura.item_cantidad)
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 
JOIN Factura Factura ON Factura.fact_tipo = Item_Factura.item_tipo AND Factura.fact_sucursal = Item_Factura.item_sucursal AND Factura.fact_numero = Item_Factura.item_numero
WHERE YEAR(Factura.fact_fecha) = 2012
GROUP BY Producto.prod_codigo, Producto.prod_detalle
ORDER BY SUM(Item_Factura.item_cantidad)

-----------------------------------------------------------3-----------------------------------------------------------

-- Realizar una consulta que muestre código de producto, nombre de producto y el stock total, sin importar en que deposito se encuentre, los datos deben ser ordenados por nombre del artículo de menor a mayor.

-- 1. Empezamos por el FROM --> Donde estan los productos 

SELECT * FROM Producto

-- 2. Me fijo que tengo que traer y en que tabla se encuentra

SELECT Producto.prod_codigo, Producto.prod_detalle, STOCK.stoc_cantidad
FROM Producto 
JOIN STOCK on Producto.prod_codigo = STOCK.stoc_producto

-- 3. Que es la cantidad vendida?? Contar todas las cantidades de un producto --> Juntas el mismo codigo y luego lo sumas

SELECT Producto.prod_codigo, Producto.prod_detalle, sum(isnull(stoc_cantidad, 0))
FROM Producto 
LEFT JOIN STOCK on Producto.prod_codigo = STOCK.stoc_producto -- Agregar el LEFT hace que te aparezcan los productos que no hayan en STOCK
GROUP BY Producto.prod_codigo, Producto.prod_detalle
ORDER BY Producto.prod_detalle

-----------------------------------------------------------4-----------------------------------------------------------

-- Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de artículos que lo componen. 
-- Mostrar solo aquellos artículos para los cuales el stock promedio por depósito sea mayor a 100.

-- 1. Empezamos por el FROM --> Donde estan los Articulos

SELECT * FROM Producto

SELECT * FROM Composicion

-- 2. Me fijo que tengo que traer y en que tabla se encuentra

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Nombre de los Productos',
       COUNT(Composicion.comp_componente) AS 'Cantidad de Productos que lo componene'
FROM Producto
LEFT JOIN Composicion ON Producto.prod_codigo = Composicion.comp_producto
GROUP BY Producto.prod_codigo, Producto.prod_detalle

-- 3. Filtro por la cantidad de STOCK

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Nombre de los Productos',
       COUNT( distinct Composicion.comp_componente) AS 'Cantidad de Productos que lo componene'
FROM Producto
LEFT JOIN Composicion ON Producto.prod_codigo = Composicion.comp_producto
JOIN STOCK ON Producto.prod_codigo = STOCK.stoc_producto
GROUP BY Producto.prod_codigo, Producto.prod_detalle
HAVING AVG(STOCK.stoc_cantidad) > 100

-------VEAMOS LA ATOMICIDAD... O COMO LA ROMPEMOS-

-- 2196 --> 2184 Productos simples y 6 Productos compuestos (DOS COMPONENTES), es decir que a esos los devolvio dos veces
SELECT * 
FROM Producto 
LEFT JOIN Composicion ON Producto.prod_codigo = Composicion.comp_producto

-- 5612 --> Trae los productos por cada deposito en donde se encuentra
SELECT * 
FROM Producto 
LEFT JOIN Composicion ON Producto.prod_codigo = Composicion.comp_producto
JOIN STOCK ON Producto.prod_codigo = STOCK.stoc_producto
            
---------------------------------------------------9-----------------------------------------------------------

-- Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del mismo y la cantidad de depósitos que ambos tienen asignados.

-- 1. Donde esta el codigo del Jefe?
SELECT empl_jefe 
FROM Empleado

-- 2. Código del jefe, código del empleado que lo tiene como jefe, nombre del mismo 
SELECT empl_jefe AS 'Codigo del JEFE', 
        empl_codigo AS 'Codigo del empleado',
        rtrim(empl_nombre) + ' ' +rtrim(empl_apellido)AS 'Nombre del empleado'
FROM Empleado
WHERE empl_jefe IS NOT NULL

-- 3. Que es tener asignado un deposito? Es que sea el encargado
SELECT empl_jefe AS 'Codigo del jefe', 
        empl_codigo AS 'Codigo del empleado',
        rtrim(empl_nombre) + ' ' + rtrim(empl_apellido)AS 'Nombre del empleado',
        COUNT (depo_encargado) AS 'Cantidad de depósitos que ambos tienen asignados'
FROM Empleado
JOIN DEPOSITO ON depo_encargado = empl_codigo OR depo_encargado = empl_jefe -- Que el empleado o el jefe del empleado esten a cargo de un deposito
WHERE empl_jefe IS NOT NULL
GROUP BY empl_jefe, empl_codigo, rtrim(empl_nombre)+ ' ' +rtrim(empl_apellido)

---------------------------------------------------10-----------------------------------------------------------

-- Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos vendidos en la historia. 
-- Además mostrar de esos productos, quien fue el cliente que mayor compra realizo.

-- 1. Me fijo si los productos estan en el subconjunto de los productos mas vendidos o de los menos vendidos

SELECT prod_codigo AS 'Codigo del Producto', 
       prod_detalle AS 'Detalle del Producto'
FROM Producto
WHERE prod_codigo IN (
    SELECT TOP 10 item_producto 
    FROM Item_Factura 
    GROUP BY item_producto 
    ORDER BY SUM(item_cantidad) DESC  
) -- Más vendidos
OR prod_codigo IN (
    SELECT TOP 10 item_producto 
    FROM Item_Factura 
    GROUP BY item_producto 
    ORDER BY SUM(item_cantidad) ASC 
); -- Menos vendidos

-- 2. El que mas... SELECT TOP 1...

SELECT prod_codigo AS 'Codigo del Producto', 
       prod_detalle AS 'Detalle del Producto',
        ( SELECT TOP 1 fact_cliente 
                FROM Factura
                JOIN Item_Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                WHERE prod_codigo = item_producto
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC
	) AS 'Cliente que mas compras del producto realizó'
FROM Producto
WHERE prod_codigo IN (
    SELECT TOP 10 item_producto 
    FROM Item_Factura 
    GROUP BY item_producto 
    ORDER BY SUM(item_cantidad) DESC  
) -- Más vendidos
OR prod_codigo IN (
    SELECT TOP 10 item_producto 
    FROM Item_Factura 
    GROUP BY item_producto 
    ORDER BY SUM(item_cantidad) ASC 
); -- Menos vendidos

---------------------------------------------------11-----------------------------------------------------------

-- Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de productos vendidos y el monto de dichas ventas sin impuestos. 
-- Los datos se deberán ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga, solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para el año 2012.

-- 1. Devolver el detalle de una familia, la cantidad de productos vendidos y el monto... DONDE LO ENCUENTRO??

SELECT Familia.fami_detalle AS 'Detalle de la familia',
        COUNT( DISTINCT Producto.prod_detalle) AS 'Cantidad diferentes de productos vendidos',
        SUM( item_precio * item_cantidad ) AS 'Total de ventas'
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 
JOIN Familia ON Familia.fami_id = Producto.prod_familia
GROUP BY Familia.fami_detalle

-- 2. Como pide ordenar

SELECT Familia.fami_detalle AS 'Detalle de la familia',
        COUNT( DISTINCT Producto.prod_detalle) AS 'Cantidad diferentes de productos vendidos',
        SUM( item_precio * item_cantidad ) AS 'Total de ventas'
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 
JOIN Familia ON Familia.fami_id = Producto.prod_familia
GROUP BY Familia.fami_detalle
ORDER BY COUNT( DISTINCT Producto.prod_detalle) DESC

-- 3. Aplicar la condicion  

SELECT Familia.fami_detalle AS 'Detalle de la familia',
        COUNT( DISTINCT Producto.prod_detalle) AS 'Cantidad diferentes de productos vendidos',
        SUM( item_precio * item_cantidad ) AS 'Total de ventas'
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 
JOIN Familia ON Familia.fami_id = Producto.prod_familia
WHERE Familia.fami_id IN ( 
                           SELECT Producto.prod_familia
		           FROM Producto
                           JOIN Item_Factura ON Producto.prod_codigo = Item_Factura.item_producto
                           JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
		           WHERE YEAR(fact_fecha) = 2012
		           GROUP BY Producto.prod_familia
		           HAVING SUM (item_precio * item_cantidad ) > 20000
		        )
GROUP BY Familia.fami_detalle, Familia.fami_id
ORDER BY COUNT( DISTINCT Producto.prod_detalle) DESC

---------------------------------------------------

SELECT Familia.fami_detalle AS 'Detalle de la familia',
        COUNT( DISTINCT Producto.prod_detalle) AS 'Cantidad diferentes de productos vendidos',
        SUM( item_precio * item_cantidad ) AS 'Total de ventas'
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo JOIN Familia ON Familia.fami_id = Producto.prod_familia -- Para tener la familia
GROUP BY fami_detalle, fami_id
-- Una vez que generaste el query filtras en el HAVING
HAVING fami_id IN ( 
                    SELECT prod_familia 
                    FROM factura 
                    JOIN item_factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                    JOIN producto ON prod_codigo = item_producto
                    WHERE year(fact_fecha) = 2012
                    GROUP BY prod_familia
                    HAVING sum(item_precio*item_cantidad) > 20000
                )
ORDER BY COUNT( DISTINCT Producto.prod_detalle) DESC

---------------------------------------------------12-----------------------------------------------------------

-- Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del producto y stock actual del producto en todos los depósitos. 
-- Se deberán mostrar aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán ordenarse de mayor a menor por monto vendido del producto.

-- 1. Parcializar las consultas
        -- Nombre del producto 

SELECT Producto.prod_detalle  AS 'Nombre de producto'
FROM Producto -- ACA LA ATOMICIDAD ME LA DA PRODUCTO

        -- Cantidad de clientes distintos que lo compraron 

SELECT Producto.prod_detalle  AS 'Nombre de producto',
        COUNT( DISTINCT Factura.fact_cliente) AS 'Cantidad de clientes distintos que lo compraron'
FROM Producto 
JOIN Item_Factura ON item_producto = prod_codigo -- ACA LA ATOMICIDAD ME LA DA ITEM_PRODUCTO
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
GROUP BY Producto.prod_detalle 

        -- Importe promedio pagado por el producto

SELECT Producto.prod_detalle  AS 'Nombre de producto',
        COUNT( DISTINCT Factura.fact_cliente) AS 'Cantidad de clientes distintos que lo compraron',
        AVG (Item_Factura.item_precio) AS 'Importe promedio pagado por el producto'
FROM Producto 
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
GROUP BY Producto.prod_detalle 

        -- Cantidad de depósitos en los cuales hay stock del producto

SELECT Producto.prod_detalle  AS 'Nombre de producto',
        COUNT( DISTINCT Factura.fact_cliente) AS 'Cantidad de clientes distintos que lo compraron',
        AVG (Item_Factura.item_precio) AS 'Importe promedio pagado por el producto',
       COUNT(DISTINCT STOCK.stoc_deposito)  AS 'Cantidad de depósitos en los cuales hay stock del producto'
FROM Producto 
JOIN Item_Factura ON item_producto = prod_codigo 
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
JOIN STOCK ON prod_codigo = stoc_producto
GROUP BY Producto.prod_detalle 

        -- Stock actual del producto en todos los depósitos

SELECT Producto.prod_detalle  AS 'Nombre de producto',
        COUNT( DISTINCT Factura.fact_cliente) AS 'Cantidad de clientes distintos que lo compraron',
        AVG (Item_Factura.item_precio) AS 'Importe promedio pagado por el producto',
        ( SELECT COUNT(DISTINCT stoc_deposito) FROM STOCK WHERE Producto.prod_codigo = STOCK.stoc_producto AND STOCK.stoc_cantidad > 0) AS 'Cantidad de depósitos en los cuales hay stock del producto',
        ( SELECT SUM(stoc_cantidad) FROM STOCK WHERE Producto.prod_codigo = STOCK.stoc_producto ) AS 'Stock actual del producto en todos los depósitos'
FROM Producto 
JOIN Item_Factura ON item_producto = prod_codigo 
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
WHERE prod_codigo in (SELECT item_producto 
                        FROM Item_factura 
                        JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                        WHERE year (fact_fecha) = 2012
                        ) -- Que hayan tenido operaciones en 2012, pero no necesariamente solo en 2012
GROUP BY Producto.prod_detalle, Producto.prod_codigo
ORDER BY SUM(Item_Factura.item_cantidad * Item_Factura.item_precio) DESC

---------------------------------------------------13-----------------------------------------------------------

-- Realizar una consulta que retorne para cada producto que posea composición nombre del producto, precio del producto, precio de la sumatoria de los precios por la cantidad de los productos que lo componen. 
-- Solo se deberán mostrar los productos que estén compuestos por más de 2 productos y deben ser ordenados de mayor a menor por cantidad de productos que lo componen.

-- Me trae los poductos que solo tienen composicion 
SELECT Composicion.comp_producto, 
        Composicion.comp_componente
FROM Composicion

SELECT Producto.prod_detalle AS 'Nombre del producto',
        Producto.prod_precio AS 'Precio del producto',
        SUM(comp_Cantidad * Componente.prod_precio) AS 'Precio de la sumatoria de los precios por la cantidad de los productos que lo componen'
FROM Composicion
JOIN Producto ON Composicion.comp_producto = Producto.prod_codigo
JOIN Producto Componente ON Composicion.comp_componente = Componente.prod_codigo
GROUP BY Producto.prod_detalle, Producto.prod_precio

-- Los filtros
SELECT Producto.prod_detalle AS 'Nombre del producto',
        Producto.prod_precio AS 'Precio del producto',
        SUM(comp_Cantidad * Componente.prod_precio) AS 'Precio de la sumatoria de los precios por la cantidad de los productos que lo componen'
FROM Composicion
JOIN Producto ON Composicion.comp_producto = Producto.prod_codigo
JOIN Producto Componente ON Composicion.comp_componente = Componente.prod_codigo
GROUP BY Producto.prod_detalle, Producto.prod_precio
HAVING COUNT(*) >=2 --Cuantas agrupo
ORDER BY COUNT(*) DESC 

---------------------------------------------------
-- Joineo con la PK
SELECT Composicion.comp_producto,
    Producto.prod_detalle,
    Composicion.comp_componente,
    Componente.prod_detalle
FROM Composicion
JOIN Producto ON Composicion.comp_producto = Producto.prod_codigo
JOIN Producto Componente ON Composicion.comp_componente = Componente.prod_codigo
ORDER BY Composicion.comp_producto
---------------------------------------------------

---------------------------------------------------14-----------------------------------------------------------

-- Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que debe retornar son:
-- Código del cliente
-- Cantidad de veces que compro en el último año
-- Promedio por compra en el último año
-- Cantidad de productos diferentes que compro en el último año 
-- Monto de la mayor compra que realizo en el último año
-- Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en el último año.
-- No se deberán visualizar NULLs en ninguna columna

-- Todo lo que puedo mostrar desde la tabla factura
SELECT Factura.fact_cliente AS 'Código del cliente',
        COUNT ( Factura.fact_cliente ) AS 'Cantidad de veces que compro en el último año',
        AVG ( Factura.fact_total ) AS 'Promedio por compra en el último año',
       ( select count (distinct item_producto) 
        from item_factura 
        join factura f on item_numero = fact_numero AND item_sucursal = fact_sucursal AND Item_tipo = fact_tipo
        where f.fact_cliente = Factura.fact_cliente and year (f.fact_fecha) = (select max(year(fact_fecha)) from Factura)
        ) 'Cantidad de productos diferentes que compro en el último año',
        MAX ( Factura.fact_total ) AS 'Monto de la mayor compra que realizo en el último año'
FROM Factura
where year ( Factura.fact_fecha ) = ( select max ( year (Factura.fact_fecha ) ) from Factura ) -- Ultimo año
GROUP BY Factura.fact_cliente
ORDER BY COUNT ( Factura.fact_cliente ) DESC

---------------------------------------------------15---------------------------------------------------

-- Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos (en la misma factura) más de 500 veces. 
-- El resultado debe mostrar el código y descripción de cada uno de los productos y la cantidad de veces que fueron vendidos juntos. 
-- El resultado debe estar ordenado por la cantidad de veces que se vendieron juntos dichos productos. 
-- Los distintos pares no deben retornarse más de una vez.

select p1.prod_codigo,
        p1.prod_detalle, 
        p2.prod_codigo,
        p2.prod_detalle 
FROM Item_Factura i1 
JOIN producto p1 ON p1.prod_codigo =i1.item_producto 
JOIN Item_Factura i2 ON i1.item_tipo+i1.item_sucursal+i1.item_numero = i2.item_tipo+i2.item_sucursal+i2.item_numero
JOIN producto p2 ON p2.prod_codigo = i2.item_producto
WHERE p1.prod_codigo > p2.prod_codigo
GROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle 
HAVING count(*) > 500

---------------------------------------------------16---------------------------------------------------

-- Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas compras son inferiores a 1/3 del monto de ventas del producto que más se vendió en el 2012.
-- Además mostrar
-- Nombre del Cliente
-- Cantidad de unidades totales vendidas en el 2012 para ese cliente.
-- Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1, mostrar solamente el de menor código) para ese cliente.

select clie_razon_social, 
        isnull(sum(item_cantidad),0),  
        (
                select top 1 item_producto 
                from factura 
                join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                where fact_cliente = clie_codigo and year(fact_fecha) = 2012
                group by item_producto
                order by sum(item_cantidad) desc, item_producto
        )
from cliente -- Me trae todos los clientes, incluso los que no compraron
left join factura on fact_cliente = clie_codigo and YEAR( fact_fecha ) = 2012 -- SOLO SI ES LEFT
left join item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
group by clie_razon_social, clie_codigo
having isnull(sum(item_precio*item_cantidad),0) < (
                                        select top 1 AVG(item_precio*item_cantidad) 
                                        from Item_Factura 
                                        join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                                        where year(fact_fecha) = 2012
                                        group by item_producto
                                        order by 1 desc
                                ) / 3
order by 2

---------------------------------------------------

select clie_razon_social, 
        (
                select isnull(sum(item_cantidad),0) 
                from Item_Factura 
                join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                where fact_cliente = clie_codigo and year(fact_fecha) = 2012
        ),  
        (
                select top 1 item_producto 
                from factura 
                join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                where fact_cliente = clie_codigo and year(fact_fecha) = 2012
                group by item_producto
                order by sum(item_cantidad) desc, item_producto
        )
from cliente -- Me trae todos los clientes, incluso los que no compraron
left join factura on fact_cliente = clie_codigo and YEAR( fact_fecha ) = 2012 -- SOLO SI ES LEFT
group by clie_razon_social, clie_codigo
having isnull(AVG(fact_total),0) < (
                                        select top 1 AVG(fact_total) 
                                        from Item_Factura 
                                        join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                                        where year(fact_fecha) = 2012
                                        group by item_producto
                                        order by 1 desc
                                ) / 3
order by 2
---------------------------------------------------25---------------------------------------------------

-- Realizar una consulta SQL que para cada año y familia muestre :
        -- Año
        -- El código de la familia más vendida en ese año. 
        -- Cantidad de Rubros que componen esa familia.
        -- Cantidad de productos que componen directamente al producto más vendido de esa familia.
        -- La cantidad de facturas en las cuales aparecen productos pertenecientes a esa familia.
        -- El código de cliente que más compro productos de esa familia.
        -- El porcentaje que representa la venta de esa familia respecto al total de venta del año.
        -- El resultado deberá ser ordenado por el total vendido por año y familia en forma descendente.

select year(f1.fact_fecha), 
        (
                select top 1 prod_familia 
                from factura 
                join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                join Producto on prod_codigo = item_producto
                where year(fact_fecha) = year(f1.fact_fecha)
                group by prod_familia
                order by sum(item_cantidad) desc
        ),
        (
                select count(distinct prod_rubro) 
                from producto 
                where prod_familia = (
                                        select top 1 prod_familia 
                                        from factura 
                                        join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                                        join Producto on prod_codigo = item_producto
                                        where year(fact_fecha) = year(f1.fact_fecha)
                                        group by prod_familia
                                        order by sum(item_cantidad) desc
                                      )
        ),
        (
                select count(*) 
                from composicion 
                where comp_producto = (
                                        select top 1 item_producto 
                                        from Item_Factura 
                                        join producto on item_producto = prod_codigo 
                                        where prod_familia = (
                                                                select top 1 prod_familia 
                                                                from factura 
                                                                join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                                                                join Producto on prod_codigo = item_producto
                                                                where year(fact_fecha) = year(f1.fact_fecha)
                                                                group by prod_familia
                                                                order by sum(item_cantidad) desc
                                                              )
                                        group by item_producto
                                        order by sum(item_cantidad)desc
                                        )
        ),
        (
                select count(distinct fact_tipo+fact_sucursal+fact_numero) 
                from factura 
                join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                join Producto on prod_codigo = item_producto
                where year(fact_fecha) = year(f1.fact_fecha) and prod_familia = (
                                                                                        select top 1 prod_familia 
                                                                                        from factura 
                                                                                        join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                                                                                        join Producto on prod_codigo = item_producto
                                                                                        where year(fact_fecha) = year(f1.fact_fecha)
                                                                                        group by prod_familia
                                                                                        order by sum(item_cantidad) desc
                                                                                )
        ),
        (
                select top 1 fact_cliente 
                from factura 
                join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                join Producto on prod_codigo = item_producto
                where year(fact_fecha) = year(f1.fact_fecha) and prod_familia = (
                                                                                        select top 1 prod_familia 
                                                                                        from factura 
                                                                                        join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero join Producto on prod_codigo = item_producto
                                                                                        where year(fact_fecha) = year(f1.fact_fecha)
                                                                                        group by fact_cliente, prod_familia
                                                                                        order by sum(item_cantidad) desc
                                                                                )
        ),
        (
                select sum(item_cantidad*item_precio) 
                from factura 
                join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                join Producto on prod_codigo = item_producto
                where year(fact_fecha) = year(f1.fact_fecha) and prod_familia = (
                                                                                        select top 1 prod_familia 
                                                                                        from factura
                                                                                        join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
                                                                                        join Producto on prod_codigo = item_producto
                                                                                        where year(fact_fecha) = year(f1.fact_fecha)
                                                                                )
        ) * 100 / sum(fact_total) 
from factura f1
group by year(f1.fact_fecha)
order by 1,2

---------------------------------------------------26---------------------------------------------------

-- Escriba una consulta sql que retorne un ranking de empleados devolviendo las siguientes columnas:
        -- Empleado
        -- SS - Depósitos que tiene a cargo
        -- Monto total facturado en el año corriente
        -- SS - Codigo de Cliente al que mas le vendió
        -- SS -Producto más vendido
        -- Porcentaje de la venta de ese empleado sobre el total vendido ese año.
        -- Los datos deberan ser ordenados por venta del empleado de mayor a menor.

select empl_codigo, 
        
        ( select count(*) from deposito where depo_encargado = empl_codigo ), 
        
        sum(fact_total),
        (
                select top 1 fact_cliente 
                from factura 
                where fact_vendedor = empl_codigo 
                group by fact_cliente
                order by sum(fact_total) desc
        ),
        (
                select top 1 item_producto 
                from factura 
                join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                where fact_vendedor = empl_codigo 
                group by item_producto
                order by sum(item_cantidad) desc
        ),
        sum(fact_total) * 100 / (select sum(fact_total) from factura)
from factura 
join empleado on fact_vendedor = empl_codigo
group by empl_codigo
ORDER BY 1 DESC

---------------------------------------------------28---------------------------------------------------

-- Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las siguientes columnas:
        -- Año. --> Lo tengo en Factura
        -- Codigo de Vendedor --> Lo tengo en Factura
        -- Detalle del Vendedor --> Lo tengo en Empleado --> JOIN con Factura
        -- Cantidad de facturas que realizó en ese año --> Lo tengo en Factura
        -- Cantidad de clientes a los cuales les vendió en ese año. --> Lo tengo en Factura
        -- Cantidad de productos facturados con composición en ese año --> SUBSELECT
        -- Cantidad de productos facturados sin composicion en ese año. --> SUBSELECT
        -- Monto total vendido por ese vendedor en ese año --> SUM(...)
        -- Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya vendido mas productos diferentes de mayor a menor.

select year(fact_fecha), 
        fact_vendedor, 
        ltrim(rtrim(empl_nombre))+' '+ltrim(rtrim(empl_apellido)), 
        count(distinct fact_tipo+fact_sucursal+fact_numero),
        count(distinct fact_cliente),
        (
                select count(distinct item_producto) 
                from factura 
                join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                where year(fact_fecha) = year(f1.fact_fecha) 
                and item_producto in (select comp_producto from Composicion) -- MEJOR FORMA DE VER SI TIENE COMPOSICION
        ),
        (
                select count(distinct item_producto) 
                from factura 
                join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                where year(fact_fecha) = year(f1.fact_fecha)
                and item_producto not in (select comp_producto from Composicion)
        ),
        sum(item_precio*item_cantidad)
from factura f1 
join empleado on fact_vendedor = empl_codigo
join item_factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
group by year(fact_fecha), fact_vendedor, ltrim(rtrim(empl_nombre))+' '+ltrim(rtrim(empl_apellido))
order by 1, sum(item_precio*item_cantidad) desc

