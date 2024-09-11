-----------------------------------------------------------1-----------------------------------------------------------

-- Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o igual a $ 1000 ordenado por código de cliente.

SELECT clie_codigo AS 'Codigo del cliente', 
        clie_razon_social AS 'Razon Social del cliente'
FROM Cliente
WHERE clie_limite_credito >= 1000
ORDER BY clie_codigo;

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

-----------------------------------------------------------

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Detalle de los Productos',
        SUM(Item_Factura.item_cantidad) AS 'Cantidad vendida de los prodcutos'
FROM Producto 
JOIN Item_Factura ON Item_Factura.item_producto = Producto.prod_codigo
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

-----------------------------------------------------------

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Nombre de los Productos',
        SUM(STOCK.stoc_cantidad) AS 'Cantidad de Producto'
FROM Producto
JOIN STOCK ON Producto.prod_codigo = STOCK.stoc_producto
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

-----------------------------------------------------------

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Nombre de los Productos',
       COUNT(Composicion.comp_componente) AS 'Cantidad de Productos que lo componene'
FROM Producto 
LEFT JOIN Composicion ON Producto.prod_codigo = Composicion.comp_producto
GROUP BY Producto.prod_codigo, Producto.prod_detalle
HAVING Producto.prod_codigo in ( SELECT stoc_producto FROM STOCK GROUP BY stoc_producto HAVING AVG(stoc_cantidad) > 100 )
                                -- Devuelve todos productos que tienen mas de 100 unidades en stock
                                
-----------------------------------------------------------5-----------------------------------------------------------

-- Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de stock que se realizaron para ese artículo en el año 2012 
-- (egresan los productos que fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Nombre de los Productos',
        SUM(Item_Factura.item_cantidad) AS 'Cantidad de egresos de STOCK'
FROM Producto 
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON Factura.fact_tipo = Item_Factura.item_tipo AND Factura.fact_sucursal = Item_Factura.item_sucursal AND Factura.fact_numero = Item_Factura.item_numero
WHERE YEAR(Factura.fact_fecha) = 2012
GROUP BY Producto.prod_codigo, Producto.prod_detalle
HAVING SUM(Item_Factura.item_cantidad) > ( SELECT SUM(Item_Factura.item_cantidad)
		                        FROM Item_Factura
		                        JOIN Factura Factura ON Factura.fact_tipo = Item_Factura.item_tipo AND Factura.fact_sucursal = Item_Factura.item_sucursal AND Factura.fact_numero = Item_Factura.item_numero
		                        WHERE YEAR(Factura.fact_fecha) = 2011 AND Item_Factura.item_producto = Producto.prod_codigo
		                        )
ORDER BY Producto.prod_codigo

-----------------------------------------------------------6-----------------------------------------------------------

-- Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese rubro y stock total de ese rubro de artículos. 
-- Solo tener en cuenta aquellos artículos que tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’

SELECT Rubro.rubr_id AS 'ID de ese Rubro', 
        Rubro.rubr_detalle AS 'Detalle de ese Rubro', 
        COUNT(DISTINCT Producto.prod_codigo) AS 'Cantidad de artículos de ese Rubro',
        SUM(STOCK.stoc_cantidad) AS 'Stock de artículos de ese Rubro'
FROM Rubro
JOIN Producto ON Rubro.rubr_id = Producto.prod_rubro
JOIN STOCK ON Producto.prod_codigo = STOCK.stoc_producto
JOIN DEPOSITO ON STOCK.stoc_deposito = DEPOSITO.depo_codigo
WHERE STOCK.stoc_cantidad > ( SELECT stoc_cantidad
		                FROM STOCK
		                WHERE stoc_producto = '00000000' AND stoc_deposito = '00'
		                )
GROUP BY Rubro.rubr_id, Rubro.rubr_detalle
ORDER BY Rubro.rubr_detalle

-----------------------------------------------------------7-----------------------------------------------------------

-- Generar una consulta que muestre para cada artículo código, detalle, mayor precio menor precio y % de la diferencia de precios 
-- (respecto del menor Ej.: menor precio = 10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean stock.

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Nombre de los Productos',
        MAX(Item_Factura.item_precio) AS 'Mayor precio historico',
        MIN(Item_Factura.item_precio) AS 'Menor precio historico',
        ( ( MAX(Item_Factura.item_precio) - MIN(Item_Factura.item_precio) ) * 100) / MIN(Item_Factura.item_precio) AS 'Diferencia de Precios'
FROM Producto
JOIN Item_Factura ON Producto.prod_codigo = Item_Factura.item_producto
JOIN STOCK ON STOCK.stoc_producto = Producto.prod_codigo
WHERE STOCK.stoc_cantidad > 0
GROUP BY Producto.prod_detalle, Producto.prod_codigo
ORDER BY Producto.prod_detalle

---------------------------------------------------8-----------------------------------------------------------

-- Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del artículo, stock del depósito que más stock tiene.

SELECT Producto.prod_detalle AS 'Nombre de los Productos',
        ( SELECT TOP 1 STOCK.stoc_cantidad FROM STOCK JOIN Producto ON Producto.prod_codigo = STOCK.stoc_producto ORDER BY STOCK.stoc_cantidad DESC ) AS 'Stock del depósito que tiene mayor cantidad',
        count(DISTINCT STOCK.stoc_deposito) AS 'Cantidad de depocitos donde se encuentra el producto'
FROM Producto
JOIN STOCK ON STOCK.stoc_producto = Producto.prod_codigo 
GROUP BY Producto.prod_detalle
HAVING ( COUNT ( DISTINCT STOCK.stoc_deposito ) ) = ( SELECT ( COUNT(DEPOSITO.depo_codigo) - 30 ) FROM DEPOSITO )

---------------------------------------------------9-----------------------------------------------------------

-- Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del mismo y la cantidad de depósitos que ambos tienen asignados.

SELECT Jefe.empl_codigo AS 'Codigo del jefe',
        Empleado.empl_codigo AS 'Codigo del empleado',
        Empleado.empl_nombre AS 'Nombre del empleado',
        COUNT ( DEPOSITO.depo_encargado ) AS 'Depositos Empleado',
        ( SELECT COUNT ( depo_encargado ) FROM DEPOSITO WHERE Jefe.empl_codigo = depo_encargado ) AS 'Depositos Jefe'
FROM Empleado
LEFT JOIN Empleado Jefe ON Jefe.empl_codigo = Empleado.empl_jefe
LEFT JOIN DEPOSITO ON DEPOSITO.depo_encargado = Empleado.empl_codigo
GROUP BY Jefe.empl_codigo, Empleado.empl_codigo, Empleado.empl_nombre

---------------------------------------------------10-----------------------------------------------------------

-- Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos vendidos en la historia. 
-- Además mostrar de esos productos, quien fue el cliente que mayor compra realizo.



/*
SELECT
FROM
JOIN
WHERE
GROUP BY
HAVING
ORDER BY
*/
