-- Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o igual a $ 1000 ordenado por código de cliente.
SELECT clie_codigo AS 'Codigo del cliente', 
        clie_razon_social AS 'Razon Social del cliente'
FROM Cliente
WHERE clie_limite_credito >= 1000
ORDER BY clie_codigo;

--------------------------------------------------------------------------------------------------------------------------------------

-- Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por cantidad vendida.

/*
1. Empezamos por el FROM --> Donde estan las ventas de los productos (19484 Renglones de Facturas)

SELECT * 
FROM Item_Factura 

2. Me fijo que tengo que traer y en que tabla se encuentra (19484 Prodctos, correspondientes a un Renglon de la Factura) 

SELECT * 
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 

3. Que es la cantidad vendida?? Contar todas las cantidades de un producto --> Juntas el mismo codigo y luego lo sumas

SELECT Producto.prod_codigo, Producto.prod_detalle, SUM(Item_Factura.item_cantidad)
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 
GROUP BY Producto.prod_codigo, Producto.prod_detalle
ORDER BY SUM(Item_Factura.item_cantidad)

4. Filtro por el año que me interesa

SELECT Producto.prod_codigo, Producto.prod_detalle, SUM(Item_Factura.item_cantidad)
FROM Item_Factura 
JOIN Producto ON Item_Factura.item_producto = Producto.prod_codigo 
JOIN Factura Factura ON Factura.fact_tipo = Item_Factura.item_tipo AND Factura.fact_sucursal = Item_Factura.item_sucursal AND Factura.fact_numero = Item_Factura.item_numero
WHERE YEAR(Factura.fact_fecha) = 2012
GROUP BY Producto.prod_codigo, Producto.prod_detalle
ORDER BY SUM(Item_Factura.item_cantidad)

*/

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Detalle de los Productos',
        SUM(Item_Factura.item_cantidad) AS 'Cantidad vendida de los prodcutos'
FROM Producto 
JOIN Item_Factura ON Item_Factura.item_producto = Producto.prod_codigo
JOIN Factura Factura ON Factura.fact_tipo = Item_Factura.item_tipo AND Factura.fact_sucursal = Item_Factura.item_sucursal AND Factura.fact_numero = Item_Factura.item_numero
WHERE YEAR(Factura.fact_fecha) = 2012
GROUP BY Producto.prod_codigo, Producto.prod_detalle
ORDER BY SUM(Item_Factura.item_cantidad)

--------------------------------------------------------------------------------------------------------------------------------------

-- Realizar una consulta que muestre código de producto, nombre de producto y el stock total, sin importar en que deposito se encuentre, los datos deben ser ordenados por nombre del artículo de menor a mayor.

/*
1. Empezamos por el FROM --> Donde estan los productos 

SELECT * 
FROM Producto

2. Me fijo que tengo que traer y en que tabla se encuentra

SELECT Producto.prod_codigo, Producto.prod_detalle, STOCK.stoc_cantidad
FROM Producto 
JOIN STOCK on Producto.prod_codigo = STOCK.stoc_producto

3. Que es la cantidad vendida?? Contar todas las cantidades de un producto --> Juntas el mismo codigo y luego lo sumas

SELECT Producto.prod_codigo, Producto.prod_detalle, sum(isnull(stoc_cantidad, 0))
FROM Producto 
LEFT JOIN STOCK on Producto.prod_codigo = STOCK.stoc_producto -- Agregar el LEFT hace que te aparezcan los productos que no hayan en STOCK
GROUP BY Producto.prod_codigo, Producto.prod_detalle
ORDER BY Producto.prod_detalle

*/

SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Nombre de los Productos',
        SUM(STOCK.stoc_cantidad) AS 'Cantidad de Producto'
FROM Producto
JOIN STOCK ON Producto.prod_codigo = STOCK.stoc_producto
GROUP BY Producto.prod_codigo, Producto.prod_detalle
ORDER BY Producto.prod_detalle

--------------------------------------------------------------------------------------------------------------------------------------

-- Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de artículos que lo componen. 
-- Mostrar solo aquellos artículos para los cuales el stock promedio por depósito sea mayor a 100.
SELECT Producto.prod_codigo AS 'Codigo de los Productos', 
        Producto.prod_detalle AS 'Nombre de los Productos',
        AVG(STOCK.stoc_cantidad) AS 'Cantidad de Producto'
FROM Producto
LEFT JOIN Composicion ON comp_producto = prod_codigo
JOIN STOCK ON stoc_producto = prod_codigo
JOIN DEPOSITO ON stoc_deposito = depo_codigo
GROUP BY Producto.prod_codigo, Producto.prod_detalle
HAVING AVG(STOCK.stoc_cantidad) > 100

--------------------------------------------------------------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------------------------------------------------------------

-- Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese rubro y stock total de ese rubro de artículos. 
-- Solo tener en cuenta aquellos artículos que tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’
