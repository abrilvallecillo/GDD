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
       COUNT( DISTINCT Composicion.comp_componente) AS 'Cantidad de Productos que lo componene'
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

SELECT Empleado.empl_jefe AS 'Codigo del jefe',
        Empleado.empl_codigo AS 'Codigo del empleado',
        rtrim(Empleado.empl_nombre) + ' ' + rtrim(Empleado.empl_apellido) AS 'Nombre del empleado',
        COUNT ( DEPOSITO.depo_encargado ) AS 'Depositos Empleado',
        ( SELECT COUNT ( depo_encargado ) FROM DEPOSITO WHERE empl_jefe = depo_encargado ) AS 'Depositos Jefe'
FROM Empleado
LEFT JOIN DEPOSITO ON DEPOSITO.depo_encargado = Empleado.empl_codigo
WHERE Empleado.empl_jefe IS NOT NULL
GROUP BY Empleado.empl_jefe, Empleado.empl_codigo, rtrim(Empleado.empl_nombre) + ' ' + rtrim(Empleado.empl_apellido)

--------------------------------------------------

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

SELECT Producto.prod_codigo AS 'Codigo del Producto', 
        
        Producto.prod_detalle AS 'Detalle del Producto', 
        
        SUM(Item_Factura.item_cantidad) AS 'Cantidades',

        ( SELECT TOP 1 Factura.fact_cliente 
                FROM Factura
                JOIN Item_Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                WHERE Producto.prod_codigo = Item_Factura.item_producto
		GROUP BY Factura.fact_cliente
		ORDER BY SUM(Item_Factura.item_cantidad) DESC
	) AS 'Cliente que mas compras del producto realizó'

FROM Producto
JOIN Item_Factura ON Producto.prod_codigo = Item_Factura.item_producto
WHERE Producto.prod_codigo IN ( SELECT TOP 10 item_producto FROM Item_Factura GROUP BY item_producto ORDER BY SUM(item_cantidad) DESC ) -- Menos vendidas
   OR Producto.prod_codigo IN( SELECT TOP 10 item_producto FROM Item_Factura GROUP BY item_producto ORDER BY SUM(item_cantidad) ASC ) -- Mas vendidas
GROUP BY Producto.prod_detalle, Producto.prod_codigo
ORDER BY SUM(Item_Factura.item_cantidad) 

---------------------------------------------------

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


---------------------------------------------------

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
WHERE Familia.fami_id IN ( SELECT Producto.prod_familia
		        FROM Producto
                        JOIN Item_Factura ON Producto.prod_codigo = Item_Factura.item_producto
                        JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
		        WHERE YEAR(fact_fecha) = 2012
		        GROUP BY Producto.prod_familia
		        HAVING SUM (item_precio * item_cantidad ) > 20000
		        )
GROUP BY Familia.fami_detalle, Familia.fami_id
ORDER BY COUNT( DISTINCT Producto.prod_detalle) DESC

---------------------------------------------------12-----------------------------------------------------------

-- Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del producto y stock actual del producto en todos los depósitos. 
-- Se deberán mostrar aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán ordenarse de mayor a menor por monto vendido del producto.

SELECT Producto.prod_detalle AS 'Nombre de producto',
       
        COUNT(DISTINCT Factura.fact_cliente) AS 'Cantidad de clientes distintos que lo compraron',
        
        AVG (Item_Factura.item_precio) AS 'Importe promedio pagado por el producto',
        
        ( SELECT COUNT(DISTINCT stoc_deposito) 
        FROM STOCK 
        WHERE Producto.prod_codigo = STOCK.stoc_producto AND STOCK.stoc_cantidad > 0
        ) AS 'Cantidad de depósitos en los cuales hay stock del producto',
        
        ( SELECT SUM(stoc_cantidad) 
        FROM STOCK 
        WHERE Producto.prod_codigo = STOCK.stoc_producto 
        ) AS 'Stock actual del producto en todos los depósitos'

-- CONVIENE USAR SUBS SELECTS PARA OBTENER UN RESULTADO PUNTUAL
-- NO CONVENIA HACER JOIN CON STOCK PORQUE ME AGRANDABA DEMASIADO EL UNIVERSO
FROM Producto
JOIN Item_Factura ON Producto.prod_codigo = Item_Factura.item_producto
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
WHERE Producto.prod_codigo in (SELECT Item_factura.item_producto 
                        FROM Item_factura 
                        JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
                        WHERE year (Factura.fact_fecha) = 2012
                        )
GROUP BY Producto.prod_detalle, Producto.prod_codigo
ORDER BY SUM(Item_Factura.item_cantidad * Item_Factura.item_precio) DESC

---------------------------------------------------

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
        
        ( SELECT COUNT(DISTINCT stoc_deposito) 
        FROM STOCK 
        WHERE Producto.prod_codigo = STOCK.stoc_producto AND STOCK.stoc_cantidad > 0
        ) AS 'Cantidad de depósitos en los cuales hay stock del producto',
        
        ( SELECT SUM(stoc_cantidad) 
        FROM STOCK 
        WHERE Producto.prod_codigo = STOCK.stoc_producto 
        ) AS 'Stock actual del producto en todos los depósitos'

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

SELECT Producto.prod_detalle AS 'Nombre del producto',
        Producto.prod_precio AS 'Precio del producto',
        SUM(Componente.prod_precio * Composicion.comp_cantidad) AS 'Precio de la sumatoria de los precios por la cantidad de los productos que lo componen'
FROM Composicion -- Una composicion tienen un producto y un componente
JOIN Producto ON Composicion.comp_producto = Producto.prod_codigo
JOIN Producto Componente ON Composicion.comp_componente = Componente.prod_codigo
GROUP BY Producto.prod_detalle, Producto.prod_precio
HAVING SUM(Composicion.comp_cantidad) > 2
ORDER BY SUM(Composicion.comp_cantidad) DESC

---------------------------------------------------14-----------------------------------------------------------

-- Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que debe retornar son:
        -- Código del cliente
        -- Cantidad de veces que compro en el último año
        -- Promedio por compra en el último año
        -- Cantidad de productos diferentes que compro en el último año 
        -- Monto de la mayor compra que realizo en el último año
        -- Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en el último año.
        -- No se deberán visualizar NULLs en ninguna columna

SELECT Factura.fact_cliente AS 'Código del cliente',
        
        COUNT ( DISTINCT Factura.fact_numero ) AS 'Cantidad de veces que compro en el último año',
        
        AVG ( Factura.fact_total ) AS 'Promedio por compra en el ultimo año',
        
        ( SELECT COUNT ( DISTINCT Item_factura.item_producto ) 
        FROM Item_factura 
        JOIN Factura f ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
        where f.fact_cliente = Factura.fact_cliente and year (f.fact_fecha) = (select max(year(fact_fecha)) from Factura)
        ) 'Cantidad de productos diferentes que compro en el último año',
        
        MAX ( Factura.fact_total ) AS 'Monto de la mayor compra que realizo en el último año'

FROM Factura 
WHERE YEAR ( Factura.fact_fecha ) = ( SELECT MAX ( YEAR ( Factura.fact_fecha ) ) FROM Factura ) -- Ultimo año
GROUP BY Factura.fact_cliente
ORDER BY 2 DESC

---------------------------------------------------15---------------------------------------------------

-- Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos (en la misma factura) más de 500 veces. 
        -- El resultado debe mostrar el código y descripción de cada uno de los productos y la cantidad de veces que fueron vendidos juntos. 
        -- El resultado debe estar ordenado por la cantidad de veces que se vendieron juntos dichos productos. 
        -- Los distintos pares no deben retornarse más de una vez.
        -- PROD1     DETALLE1        PROD2       DETALLE2         VECES
        -- 1731    MARLBORO KS       1718   PHILIPS MORRIS KS      507
        -- 1718  PHILIPS MORRIS KS   1705   PHILIPS MORRIS BOX    10562

SELECT  P1.prod_codigo 'Código Producto 1',
	P1.prod_detalle 'Detalle Producto 1',
	P2.prod_codigo 'Código Producto 2',
	P2.prod_detalle 'Detalle Producto 2',
	COUNT(*) 'Cantidad de veces que se vendieron juntos dichos productos'
FROM Producto P1 
JOIN Item_Factura I1 ON P1.prod_codigo = I1.item_producto, 
Producto P2 
JOIN Item_Factura I2 ON P2.prod_codigo = I2.item_producto
WHERE I1.item_tipo+I1.item_sucursal+I1.item_numero = I2.item_tipo+I2.item_sucursal+I2.item_numero -- Que sea la misma factura
        AND I1.item_producto < I2.item_producto -- Que no se repitan los productos
GROUP BY P1.prod_codigo, P1.prod_detalle, P2.prod_codigo, P2.prod_detalle
HAVING COUNT(*) > 500 -- Que se hayan vendido juntos mas de 500 veces
ORDER BY 5 DESC

---------------------------------------------------16---------------------------------------------------

-- Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran en la empresa, se pide una consulta SQL que retorne aquellos 
        -- Clientes cuyas compras son inferiores a 1/3 del monto de ventas del producto que más se vendió en el 2012.
        -- Además mostrar
        -- Nombre del Cliente
        -- Cantidad de unidades totales vendidas en el 2012 para ese cliente.
        -- Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1, mostrar solamente el de menor código) para ese cliente.

---------------------------------------------------

-- Monto de ventas del producto que más se vendió en el 2012
SELECT AVG(item_precio), item_cantidad
FROM Item_Factura
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
WHERE YEAR ( fact_fecha ) = 2012
GROUP BY item_producto, item_cantidad
ORDER BY item_cantidad DESC

-- Cantidad de compras de los clientes
SELECT fact_cliente, COUNT(fact_cliente) FROM Factura GROUP BY fact_cliente

-- Que producto fue el mas comprado para ese cliente
SELECT fact_cliente, item_producto, item_cantidad
FROM Item_Factura
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
ORDER BY (item_cantidad) DESC

---------------------------------------------------

SELECT clie_razon_social AS 'Nombre del Cliente', 

       isnull ( sum ( item_cantidad ) , 0 )  AS 'Cantidad de unidades totales vendidas en el 2012 para ese cliente',

       ( SELECT TOP 1 item_producto
	FROM Item_Factura
	JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
        WHERE clie_codigo = fact_cliente AND YEAR(fact_fecha) = 2012
	GROUP BY item_producto
	ORDER BY SUM(item_cantidad) DESC, item_producto ASC
	) AS 'Código de producto que mayor venta tuvo en el 2012 para ese cliente'

FROM Cliente-- Me trae todos los clientes, incluso los que no compraron
LEFT JOIN Factura ON fact_cliente = clie_codigo and YEAR( fact_fecha ) = 2012 -- SOLO SI ES LEFT
LEFT JOIN Item_Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
GROUP BY clie_razon_social, clie_codigo
HAVING isnull(sum(item_precio*item_cantidad),0) < ( ( SELECT TOP 1 AVG ( item_precio*item_cantidad ) 
                                        FROM Item_Factura
                                        JOIN Factura ON item_tipo = fact_tipo AND item_numero = fact_numero AND item_sucursal = fact_sucursal
                                        WHERE YEAR(fact_fecha) = 2012
                                        GROUP BY item_producto
                                        ORDER BY 1 DESC
                                        ) /3
                                     )
ORDER BY 2

---------------------------------------------------17---------------------------------------------------

-- Escriba una consulta que retorne una estadística de ventas por año y mes para cada producto.
-- La consulta debe retornar:
        -- PERIODO = Año y mes de la estadística con el formato YYYYMM
        -- PROD = Código de producto
        -- DETALLE = Detalle del producto
        -- CANTIDAD_VENDIDA = Cantidad vendida del producto en el periodo 
        -- VENTAS_AÑO_ANT = Cantidad vendida del producto en el mismo mes del periodo pero del año anterior
        -- CANT_FACTURAS = Cantidad de facturas en las que se vendió el producto en el periodo
        -- La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada por periodo y código de producto.

SELECT STR ( YEAR ( Factura.fact_fecha ) ) + STR ( MONTH ( Factura.fact_fecha ) ) AS 'Periodo',

        Producto.prod_codigo AS 'Código de producto',

        Producto.prod_detalle AS 'Detalle del producto',

        SUM ( ISNULL ( Item_Factura.item_cantidad , 0 ) ) AS 'Cantidad vendida del producto en el periodo',

       ( SELECT ISNULL ( SUM ( ISNULL ( item_cantidad , 0 ) ) , 0 )
        FROM Item_Factura
        JOIN Factura f ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
        WHERE YEAR(f.fact_fecha) = ( YEAR ( Factura.fact_fecha ) - 1 ) -- Año anterior
                AND MONTH ( f.fact_fecha ) =  MONTH ( Factura.fact_fecha ) -- Mismo mes
                AND Producto.prod_codigo = item_producto -- Mismo producto
        ) AS 'Cantidad vendida del producto en el mismo mes del periodo pero del año anterior',

        COUNT(fact_tipo+fact_sucursal+fact_numero) AS 'Cantidad de facturas en las que se vendió el producto en el periodo'

FROM Item_Factura
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
JOIN Producto ON prod_codigo = item_producto
GROUP BY  Producto.prod_codigo, Producto.prod_detalle, Factura.fact_fecha
ORDER BY Factura.fact_fecha, Producto.prod_codigo DESC

---------------------------------------------------18---------------------------------------------------

-- Escriba una consulta que retorne una estadística de ventas para todos los rubros. 
-- La consulta debe retornar:
        -- DETALLE_RUBRO: Detalle del rubro
        -- VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
        -- PROD1: Código del producto más vendido de dicho rubro
        -- PROD2: Código del segundo producto más vendido de dicho rubro
        -- CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30 días
        -- La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada por cantidad de productos diferentes vendidos del rubro.

SELECT Rubro.rubr_detalle AS 'Detalle del rubro',

        SUM(item_precio * item_cantidad) AS  'Suma de las ventas en pesos de productos vendidos de dicho rubro',

        ( SELECT TOP 1 item_producto
        FROM Producto p
        JOIN  Item_Factura ON item_producto = p.prod_codigo
        WHERE Rubro.rubr_id = p.prod_rubro
        GROUP BY item_producto
	ORDER BY SUM(item_cantidad) DESC
        ) AS 'Código del producto más vendido de dicho rubro',

        ISNULL ( ( SELECT TOP 1 item_producto
        FROM Producto p
        JOIN  Item_Factura ON item_producto = p.prod_codigo
        WHERE Rubro.rubr_id = p.prod_rubro AND prod_codigo <> ( SELECT TOP 1 item_producto
                                                                FROM Producto p
                                                                JOIN Item_Factura ON item_producto = p.prod_codigo
                                                                WHERE Rubro.rubr_id = prod_rubro
                                                                GROUP BY item_producto
                                                                ORDER BY SUM(item_cantidad) DESC
						                )
        GROUP BY item_producto
	ORDER BY SUM(item_cantidad) DESC
        ) , '-' ) AS 'Código del segundo producto más vendido de dicho rubro',

        ISNULL ( ( SELECT TOP 1 fact_cliente
        FROM Factura
        JOIN  Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
        JOIN  Producto p ON item_producto = prod_codigo
        WHERE Rubro.rubr_id = p.prod_rubro AND fact_fecha > DATEADD(DAY,-30,(SELECT MAX(fact_fecha) FROM Factura))
        GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad) DESC
        ) , '-' ) AS 'Código del cliente que compro más productos del rubro en los últimos 30 días'

FROM Producto
JOIN  Rubro ON rubr_id = prod_rubro
JOIN  Item_Factura ON item_producto = prod_codigo
GROUP BY Rubro.rubr_detalle, Rubro.rubr_id
ORDER BY COUNT(DISTINCT item_producto)

---------------------------------------------------19---------------------------------------------------

-- En virtud de una recategorizacion de productos referida a la familia de los mismos se solicita que desarrolle una consulta sql que retorne para todos los productos:
        -- Codigo de producto
        -- Detalle del producto
        -- Codigo de la familia del producto
        -- Detalle de la familia actual del producto
        -- Codigo de la familia sugerido para el producto
        -- Detalla de la familia sugerido para el producto
        -- La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo detalle coinciden en los primeros 5 caracteres.
        -- En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor codigo. 
        -- Solo se deben mostrar los productos para los cuales la familia actual sea diferente a la sugerida
        -- Los resultados deben ser ordenados por detalle de producto de manera ascendente

SELECT prod_codigo AS 'Codigo de producto',
        prod_detalle AS 'Detalle del producto',
        fami_id AS 'Codigo de la familia del producto',
        fami_detalle AS 'Detalle de la familia actual del producto',

       (
                SELECT TOP 1 fami_id
                FROM Familia
                WHERE SUBSTRING(fami_detalle, 0, 5) = SUBSTRING(prod_detalle, 0, 5)
                ORDER BY fami_id ASC
        ) AS 'Codigo de la familia sugerida para el producto',

       (
                SELECT TOP 1 fami_detalle
                FROM Familia
                WHERE SUBSTRING(fami_detalle, 0, 5) = SUBSTRING(prod_detalle, 0, 5)
                ORDER BY fami_id ASC
        ) AS 'Detalle de la familia sugerida para el producto'
  
FROM Producto
JOIN Familia ON prod_familia = fami_id 
WHERE prod_familia <> ( SELECT TOP 1 fami_id
                        FROM Familia
                        WHERE SUBSTRING(fami_detalle, 0, 5) = SUBSTRING(prod_detalle, 0, 5)
                        ORDER BY fami_id ASC
                         )
ORDER BY prod_detalle ASC

---------------------------------------------------20---------------------------------------------------

-- Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
-- Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje 2012. 
-- El puntaje de cada empleado se calculara de la siguiente manera:
        -- Para los que hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas que superen los 100 pesos que haya vendido en el año
        -- Para los que tengan mas de 50 facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas por sus subordinados directos en dicho año.

SELECT TOP 3 empl_codigo AS 'Legajo',
        empl_nombre AS 'Nombre',
        empl_apellido AS 'Apellido', 
        empl_ingreso AS 'Año de ingreso', 

        CASE WHEN ( SELECT COUNT(fact_vendedor) FROM Factura  WHERE empl_codigo = fact_vendedor AND YEAR(fact_fecha) = 2011 ) >= 50 
        -- Vendieron menos de 50 facturas
        THEN ( SELECT COUNT(*) FROM FACTURA WHERE fact_total > 100 AND empl_codigo = fact_vendedor AND YEAR(fact_fecha) = 2011 )
        -- Vendieron mas de 50 facturas
        ELSE ( SELECT COUNT(*) * 0.5 FROM Factura WHERE fact_vendedor IN ( SELECT empl_codigo FROM Empleado WHERE empl_jefe = empl_codigo ) AND YEAR(fact_fecha) = 2011 )													   
        END
        AS 'Puntaje 2011',

        CASE WHEN ( SELECT COUNT(fact_vendedor) FROM Factura  WHERE empl_codigo = fact_vendedor AND YEAR(fact_fecha) = 2012 ) >= 50 
        -- Vendieron menos de 50 facturas
        THEN ( SELECT COUNT(*) FROM FACTURA WHERE fact_total > 100 AND empl_codigo = fact_vendedor AND YEAR(fact_fecha) = 2012 )
        -- Vendieron mas de 50 facturas
        ELSE ( SELECT COUNT(*) * 0.5 FROM Factura WHERE fact_vendedor IN ( SELECT empl_codigo FROM Empleado WHERE empl_jefe = empl_codigo ) AND YEAR(fact_fecha) = 2012 )													   
        END
        AS 'Puntaje 2012'

FROM Empleado
ORDER BY 6 DESC

---------------------------------------------------21---------------------------------------------------

-- Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. 
-- Se considera que una factura es incorrecta cuando la diferencia entre el total de la factura menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de los costos de cada uno de los items de dicha factura. 
-- Las columnas que se deben mostrar son:
        -- Año
        -- Clientes a los que se les facturo mal en ese año
        -- Facturas mal realizadas en ese año

SELECT YEAR ( fact_fecha ) 'Año',
        fact_cliente 'Cliente facturado incorrectamente',
        COUNT(fact_cliente) 'Facturas mal realizadas'
FROM Factura
WHERE ( fact_total - fact_total_impuestos ) /* Total - Impuesto = Productos */ 
        - 
        ( 
                SELECT SUM ( item_cantidad * item_precio ) /* item_cantidad * item_precio = Productos */ 
                FROM Item_Factura 
                WHERE FACT_TIPO = ITEM_TIPO AND FACT_SUCURSAL = ITEM_SUCURSAL AND FACT_NUMERO = ITEM_NUMERO 
        ) > 1 -- Si la diferencia es mayor que 1 la factura se realizo mal
group by YEAR ( fact_fecha ) , fact_cliente
order by 1 asc, 2 asc, 3 desc

---------------------------------------------------22---------------------------------------------------

-- Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por trimestre contabilizando todos los años. 
-- Se mostraran como maximo 4 filas por rubro (1 por cada trimestre).
-- Se deben mostrar 4 columnas:
        -- Detalle del rubro
        -- Numero de trimestre del año (1 a 4)
        -- Cantidad de facturas emitidas en el trimestre en las que se haya vendido al menos un producto del rubro
        -- Cantidad de productos diferentes del rubro vendidos en el trimestre
        -- El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada rubro primero el trimestre en el que mas facturas se emitieron.
        -- No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas no superen las 100.
        -- En ningun momento se tendran en cuenta los productos compuestos para esta estadistica.

SELECT rubr_detalle AS "Detalle del rubro",
    DATEPART ( QUARTER, fact_fecha ) AS "Número de trimestre del año", -- DATEPART : Extraer una parte específica de una fecha / QUARTER : Indica que queremos obtener el trimestre de la fecha (es decir, en qué trimestre del año cae la fecha).
    COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) AS "Cantidad de facturas emitidas",
    COUNT ( DISTINCT item_producto ) AS "Cantidad de productos diferentes vendidos"
FROM Factura
JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
JOIN Producto ON item_producto = prod_codigo
JOIN Rubro ON prod_rubro = rubr_id
LEFT JOIN Composicion ON prod_codigo = comp_producto
WHERE comp_producto IS NULL
GROUP BY rubr_detalle, DATEPART(QUARTER, fact_fecha)
HAVING COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) > 100
ORDER BY rubr_detalle ASC, COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) DESC;

---------------------------------------------------

SELECT rubr_detalle 'Rubro',
	DATEPART(QUARTER, fact_fecha) 'Trimestre',
        COUNT(DISTINCT fact_tipo + fact_sucursal + fact_numero) 'Facturas',
	COUNT(DISTINCT prod_codigo) 'Productos Diferentes'
FROM Rubro 
JOIN Producto ON rubr_id = prod_rubro
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE prod_codigo NOT IN (SELECT comp_producto FROM Composicion) -- OTRA FORMA DE DECIR QUE NO TIENE COMPOSICION 
GROUP BY rubr_detalle, DATEPART(QUARTER, fact_fecha)
HAVING COUNT(DISTINCT fact_tipo + fact_sucursal + fact_numero) > 100
ORDER BY 1, 3 DESC

---------------------------------------------------

SELECT rubr_detalle AS "Detalle del rubro",
    DATEPART ( QUARTER, fact_fecha ) AS "Número de trimestre del año", 
    COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) AS "Cantidad de facturas emitidas",
    COUNT ( DISTINCT item_producto ) AS "Cantidad de productos diferentes vendidos"
-- Para la fecha    
FROM Factura JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero 
-- Para el detalle
JOIN Producto ON item_producto = prod_codigo JOIN Rubro ON prod_rubro = rubr_id  
-- Para que no tenga composicion 
LEFT JOIN Composicion ON prod_codigo = comp_producto WHERE comp_producto IS NULL
-- Agrupo para poder usar el COUNT
GROUP BY rubr_detalle, DATEPART(QUARTER, fact_fecha)
-- Para mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas no superen las 100
HAVING COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) > 100
-- Oredeno 
ORDER BY rubr_detalle ASC, COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) DESC;

---------------------------------------------------23---------------------------------------------------

-- Realizar una consulta SQL que para cada año muestre :
        -- Año
        -- El producto con composición más vendido para ese año.
        -- Cantidad de productos que componen directamente al producto más vendido
        -- La cantidad de facturas en las cuales aparece ese producto.
        -- El código de cliente que más compro ese producto.
        -- El porcentaje que representa la venta de ese producto respecto al total de venta del año.
-- El resultado deberá ser ordenado por el total vendido por año en forma descendente.

SELECT YEAR ( fact_fecha ) AS "Año",
    
    item_producto AS "Producto más vendido",
    
    -- (SELECT COUNT(*) FROM Composicion WHERE comp_producto = item_producto) 'Cant. Componentes',
    ( 
        SELECT COUNT ( DISTINCT c2.comp_componente ) 
        FROM Composicion c2 
        WHERE c2.comp_producto = item_producto
    ) AS "Cantidad de productos que componen directamente al producto más vendido",
    
    COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) AS "Cantidad de facturas en las cuales aparece ese producto",
    
    ( 
        SELECT TOP 1  fact_cliente 
        FROM Factura f2 
        JOIN Item_Factura i2 ON  fact_tipo = i2.item_tipo AND  fact_sucursal = i2.item_sucursal AND  fact_numero = i2.item_numero 
        WHERE i2.item_producto = item_producto AND YEAR (  fact_fecha ) = YEAR ( fact_fecha ) 
        GROUP BY  fact_cliente
        ORDER BY SUM(item_cantidad) DESC
    ) AS "Código de cliente que más compró ese producto",
    
    ( SUM ( ISNULL ( item_cantidad , 0 ) )* 100 / ( SELECT SUM ( i2.item_cantidad )
                                                        FROM Factura f2 
                                                        JOIN Item_Factura i2 ON  fact_tipo = i2.item_tipo AND  fact_sucursal = i2.item_sucursal AND  fact_numero = i2.item_numero
                                                        WHERE YEAR (  fact_fecha ) = YEAR ( fact_fecha )
                                                        ) 
        ) AS "Porcentaje de venta del producto respecto al total de ventas del año"

FROM Factura
JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero 
WHERE item_producto = (
                        SELECT TOP 1 i2.item_producto
                        FROM Factura f2
                        JOIN Item_Factura i2 ON  fact_tipo = i2.item_tipo AND  fact_sucursal = i2.item_sucursal AND  fact_numero = i2.item_numero
                        JOIN Composicion c2 ON i2.item_producto = c2.comp_producto
                        WHERE YEAR( fact_fecha) = YEAR ( fact_fecha )
                        GROUP BY i2.item_producto
                        ORDER BY SUM(i2.item_cantidad) DESC
                        )-- Aquí seleccionamos solo el producto más vendido para cada año
GROUP BY YEAR ( fact_fecha ), item_producto
ORDER BY SUM ( item_cantidad ) DESC;

---------------------------------------------------

SELECT  YEAR(F.fact_fecha) 'Año',

        I.item_producto 'Producto mas vendido',
	
        (SELECT COUNT(*) FROM Composicion WHERE comp_producto = I.item_producto) 'Cant. Componentes',
	
        COUNT(DISTINCT F.fact_tipo + F.fact_sucursal + F.fact_numero) 'Facturas',
	
        (
                SELECT TOP 1 fact_cliente
                FROM Factura 
                JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
                WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND item_producto = I.item_producto
                GROUP BY fact_cliente
                ORDER BY SUM(item_cantidad) DESC
        ) 'Cliente mas Compras',

	SUM(ISNULL(I.item_cantidad, 0)) / (SELECT SUM(item_cantidad) 
                                        FROM Factura 
                                        JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
                                        WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
                                        ) * 100 'Porcentaje'
FROM Factura F 
JOIN Item_Factura I ON (F.fact_tipo + F.fact_sucursal + F.fact_numero = I.item_tipo + I.item_sucursal + I.item_numero)
WHERE  I.item_producto = (SELECT TOP 1 item_producto FROM Item_Factura
						        JOIN Composicion ON item_producto = comp_producto
							JOIN Factura  ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
							WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
							GROUP BY item_producto
							ORDER BY SUM(item_cantidad) DESC)
GROUP BY YEAR(F.fact_fecha), I.item_producto
ORDER BY SUM(I.item_cantidad) DESC

---------------------------------------------------24---------------------------------------------------

-- Escriba una consulta que considerando solamente las facturas correspondientes a los dos vendedores con mayores comisiones, retorne los productos con composición facturados al menos en cinco facturas
-- La consulta debe retornar las siguientes columnas:
        -- Código de Producto
        -- Nombre del Producto
        -- Unidades facturadas
        -- El resultado deberá ser ordenado por las unidades facturadas descendente.

SELECT prod_codigo AS 'Código de Producto',
        prod_detalle AS 'Nombre del Producto',
        SUM ( item_cantidad ) AS 'Unidades facturadas'
FROM Factura
JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero 
JOIN Producto ON item_producto = prod_codigo
WHERE fact_vendedor IN ( SELECT TOP 2 empl_codigo FROM Empleado ORDER BY empl_comision DESC ) -- Identificar a los dos vendedores con mayores comisiones
AND prod_codigo IN ( SELECT comp_producto FROM Composicion ) -- Productos que tengan composición
GROUP BY prod_codigo, prod_detalle
HAVING  COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) >= 5  -- Facturados al menos en cinco facturas
-- HAVING COUNT(IFACT.item_producto) > 5
ORDER BY SUM ( item_cantidad ) DESC

---------------------------------------------------25---------------------------------------------------

-- Realizar una consulta SQL que para cada año y familia muestre :
        -- Año
        -- El código de la familia más vendida en ese año. --> TOP 1 --> SUBSELECT
        -- Cantidad de Rubros que componen esa familia. --> SUBSELECT
        -- Cantidad de productos que componen directamente al producto más vendido de esa familia. --> SUBSELECT
        -- La cantidad de facturas en las cuales aparecen productos pertenecientes a esa familia. --> SUBSELECT
        -- El código de cliente que más compro productos de esa familia. --> TOP 1 --> SUBSELECT
        -- El porcentaje que representa la venta de esa familia respecto al total de venta del año. --> SUBSELECT
        -- El resultado deberá ser ordenado por el total vendido por año y familia en forma descendente. 

SELECT 
    YEAR(F.fact_fecha) AS 'Año',

    (
        SELECT TOP 1 prod_familia 
        FROM Factura 
        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero 
        JOIN Producto ON prod_codigo = item_producto
        WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
        GROUP BY prod_familia
        ORDER BY SUM(item_cantidad) DESC 
    ) AS 'Código de la familia más vendida en ese año',

    (
        SELECT COUNT(DISTINCT prod_rubro) 
        FROM Producto 
        WHERE prod_familia = ( -- FAMILIA MAS VENDIDA
                                SELECT TOP 1 prod_familia
                                FROM Factura 
                                JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero 
                                JOIN Producto ON prod_codigo = item_producto
                                WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
                                GROUP BY prod_familia
                                ORDER BY SUM(item_cantidad) DESC
                            )
    ) AS 'Cantidad de Rubros que componen esa familia',

   (
        SELECT COUNT(*)
        FROM Composicion 
        WHERE comp_producto = ( -- EL PRODUCTO DE ESA FAMILIA QUE MAS SE VENDIO
                                SELECT TOP 1 item_producto
                                FROM Factura 
                                JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero 
                                JOIN Producto ON prod_codigo = item_producto
                                WHERE prod_familia = ( -- FAMILIA MAS VENDIDA
                                                        SELECT TOP 1 prod_familia
                                                        FROM Factura 
                                                        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero 
                                                        JOIN Producto ON prod_codigo = item_producto
                                                        WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
                                                        GROUP BY prod_familia
                                                        ORDER BY SUM(item_cantidad) DESC
                                                     )
                                GROUP BY item_producto
                                ORDER BY SUM(item_cantidad) DESC
                              )
    ) AS 'Cantidad de productos que componen directamente al producto más vendido de esa familia',

    (
        SELECT COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero )
        FROM Factura 
        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        JOIN Producto ON prod_codigo = item_producto
        WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND prod_familia = ( -- FAMILIA MAS VENDIDA
                                                                                SELECT TOP 1 prod_familia 
                                                                                FROM Factura 
                                                                                JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
                                                                                JOIN Producto ON prod_codigo = item_producto
                                                                                WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
                                                                                GROUP BY prod_familia
                                                                                ORDER BY SUM(item_cantidad) DESC
                                                                        )
    ) AS 'Cantidad de facturas con productos de esa familia',

    (
        SELECT TOP 1 fact_cliente
        FROM Factura 
        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        JOIN Producto ON prod_codigo = item_producto
        WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND prod_familia = ( -- FAMILIA MAS VENDIDA
                                                                                SELECT TOP 1 prod_familia 
                                                                                FROM Factura 
                                                                                JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
                                                                                JOIN Producto ON prod_codigo = item_producto
                                                                                WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
                                                                                GROUP BY prod_familia
                                                                                ORDER BY SUM(item_cantidad) DESC
                                                                        )
        GROUP BY fact_cliente
        ORDER BY SUM(item_cantidad) DESC
    ) AS 'Cliente con mayor cantidad en familia más vendida',

    (
        SELECT SUM(item_cantidad * item_precio) * 100.0 / SUM(fact_total)
        FROM Factura 
        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        JOIN Producto ON prod_codigo = item_producto
        WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND prod_familia = ( -- FAMILIA MAS VENDIDA
                                                                                SELECT TOP 1 prod_familia 
                                                                                FROM Factura 
                                                                                JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
                                                                                JOIN Producto ON prod_codigo = item_producto
                                                                                WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
                                                                                GROUP BY prod_familia
                                                                                ORDER BY SUM(item_cantidad) DESC
                                                                        )
    ) AS 'Porcentaje del monto de familia sobre total anual'

FROM Factura F
GROUP BY YEAR(F.fact_fecha)
ORDER BY 1;

---------------------------------------------------26---------------------------------------------------

-- Escriba una consulta sql que retorne un ranking de empleados devolviendo las siguientes columnas:
        -- Empleado
        -- Depósitos que tiene a cargo
        -- Monto total facturado en el año corriente
        -- Codigo de Cliente al que mas le vendió
        -- Producto más vendido
        -- Porcentaje de la venta de ese empleado sobre el total vendido ese año.
        -- Los datos deberan ser ordenados por venta del empleado de mayor a menor.

SELECT E.empl_codigo AS 'Empleado',

    COUNT ( DISTINCT D.depo_codigo ) AS 'Depósitos que tiene a cargo',
 
    ( SELECT SUM ( fact_total ) FROM Factura WHERE fact_vendedor = E.empl_codigo ) AS 'Monto total facturado en el año corriente',

    (
        SELECT TOP 1 F.fact_cliente
        FROM Factura F
        WHERE F.fact_vendedor = E.empl_codigo 
        GROUP BY F.fact_cliente
        ORDER BY SUM ( fact_total ) DESC
    ) AS 'Codigo de Cliente al que más le vendió',

    (
        SELECT TOP 1 I.item_producto
        FROM Factura F
        JOIN Item_Factura I ON F.fact_numero = I.item_numero AND F.fact_sucursal = I.item_sucursal AND F.fact_tipo = I.item_tipo
        WHERE F.fact_vendedor = E.empl_codigo
        GROUP BY I.item_producto
        ORDER BY SUM ( I.item_cantidad ) DESC
    ) AS 'Producto más vendido',

        ( SELECT SUM ( fact_total ) FROM Factura WHERE fact_vendedor = E.empl_codigo ) * 100 / ( SELECT SUM ( fact_total ) FROM Factura ) AS 'Porcentaje de la venta de ese empleado sobre el total vendido ese año'

FROM Empleado E
LEFT JOIN Deposito D ON D.depo_encargado = E.empl_codigo  -- Para que el que no tenga depositos a cargo tambien me lo traiga
JOIN Factura F ON F.fact_vendedor = E.empl_codigo
GROUP BY E.empl_codigo
ORDER BY 1 DESC

---------------------------------------------------27---------------------------------------------------

-- Escriba una consulta sql que retorne una estadística basada en la facturacion por año y envase devolviendo las siguientes columnas:
        -- Año
        -- Codigo de envase
        -- Detalle del envase
        -- Cantidad de productos que tienen ese envase
        -- Cantidad de productos facturados de ese envase
        -- Producto mas vendido de ese envase
        -- Monto total de venta de ese envase en ese año
        -- Porcentaje de la venta de ese envase respecto al total vendido de ese año
        -- Los datos deberan ser ordenados por año y dentro del año por el envase con más facturación de mayor a menor

SELECT YEAR(F.fact_fecha) AS 'Año',

    E.enva_codigo AS 'Codigo de envase', 

    E.enva_detalle AS 'Detalle del envase',

    COUNT ( DISTINCT P.prod_codigo ) AS 'Cantidad de productos que tienen ese envase',

    SUM ( I.item_cantidad ) AS 'Cantidad de productos facturados de ese envase',

    (
        SELECT TOP 1 prod_codigo
        FROM Producto
        JOIN Item_Factura ON item_producto = prod_codigo
        JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
        WHERE prod_envase = E.enva_codigo AND YEAR ( fact_fecha ) = YEAR ( F.fact_fecha )
        GROUP BY prod_codigo
        ORDER BY SUM ( item_cantidad ) DESC
    ) AS 'Producto más vendido de ese envase',

    SUM ( I.item_cantidad * I.item_precio ) AS 'Monto total de venta de ese envase en ese año',

     SUM ( I.item_cantidad * I.item_precio ) * 100  / (  SELECT SUM ( item_cantidad * item_precio )
                                                        FROM Item_Factura
                                                        JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
                                                        WHERE YEAR ( fact_fecha ) = YEAR ( F.fact_fecha )
    ) AS 'Porcentaje de la venta de ese envase respecto al total vendido de ese año'

FROM Producto P
JOIN Envases E ON P.prod_envase = E.enva_codigo
JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero = I.item_numero AND F.fact_sucursal = I.item_sucursal AND F.fact_tipo = I.item_tipo 
GROUP BY YEAR(F.fact_fecha), E.enva_codigo, E.enva_detalle
ORDER BY YEAR(F.fact_fecha), enva_codigo

---------------------------------------------------28---------------------------------------------------

-- Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las siguientes columnas:
        -- Año.
        -- Codigo de Vendedor
        -- Detalle del Vendedor
        -- Cantidad de facturas que realizó en ese año
        -- Cantidad de clientes a los cuales les vendió en ese año.
        -- Cantidad de productos facturados con composición en ese año
        -- Cantidad de productos facturados sin composicion en ese año.
        -- Monto total vendido por ese vendedor en ese año
        -- Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya vendido mas productos diferentes de mayor a menor.

SELECT YEAR(F.fact_fecha) AS 'Año',

    F.fact_vendedor AS 'Codigo de Vendedor',
    
    E.empl_nombre AS 'Detalle del Vendedor',
    
    COUNT ( F.fact_tipo + F.fact_sucursal + F.fact_numero) AS 'Cantidad de facturas que realizó en ese año',
    
    COUNT ( DISTINCT F.fact_cliente) AS 'Cantidad de clientes a los cuales les vendió en ese año',
    
        (
		SELECT COUNT(DISTINCT prod_codigo)
		FROM Producto
		JOIN Item_Factura ON item_producto = prod_codigo
		JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) 
                AND prod_codigo IN (SELECT comp_producto FROM Composicion)
	) AS 'Cantidad de productos facturados con composición en ese año',
    
        ( 
                SELECT COUNT ( DISTINCT prod_codigo )
		FROM Producto
		JOIN Item_Factura
		ON item_producto = prod_codigo
		JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) 
                AND prod_codigo NOT IN (SELECT comp_producto FROM Composicion)
	) AS 'Cantidad de productos facturados sin composición en ese año',
    
    SUM( F.fact_total ) AS 'Monto total vendido por ese vendedor en ese año'

FROM Factura F
JOIN Empleado E ON F.fact_vendedor = E.empl_codigo
GROUP BY YEAR(F.fact_fecha), F.fact_vendedor, E.empl_nombre
ORDER BY 1, SUM( F.fact_total ) desc

---------------------------------------------------29---------------------------------------------------

-- Se solicita que realice una estadística de venta por producto para el año 2011, solo para los productos que pertenezcan a las familias que tengan más de 20 productos asignados a ellas, la cual deberá devolver las siguientes columnas:
        -- Código de producto
        -- Descripción del producto
        -- Cantidad vendida
        -- Cantidad de facturas en la que esta ese producto
        -- Monto total facturado de ese producto
-- Solo se deberá mostrar un producto por fila en función a los considerandos establecidos antes. 
-- El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor.

SELECT prod_codigo AS 'Código de producto',
        prod_detalle AS 'Descripción del producto',
        SUM ( I.item_cantidad ) AS 'Cantidad vendida',
        COUNT( F.fact_tipo + F.fact_sucursal + F.fact_numero) AS 'Cantidad de facturas en la que esta ese producto',
        SUM ( I.item_cantidad * I.item_precio ) AS 'Monto total facturado de ese producto'
FROM Producto P
JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero = I.item_numero AND F.fact_sucursal = I.item_sucursal AND F.fact_tipo = I.item_tipo 
WHERE YEAR ( fact_fecha ) = 2011
AND P.prod_familia IN ( SELECT prod_familia FROM Producto GROUP BY prod_familia HAVING COUNT(prod_codigo) > 20 )
GROUP BY P.prod_codigo, P.prod_detalle
ORDER BY SUM( I.item_cantidad ) DESC; 

---------------------------------------------------30---------------------------------------------------

-- Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la consulta que retorne las siguientes columnas:
        -- Nombre del Jefe
        -- Cantidad de empleados a cargo
        -- Monto total vendido de los empleados a cargo
        -- Cantidad de facturas realizadas por los empleados a cargo
        -- Nombre del empleado con mejor ventas de ese jefe
-- Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese necesario.
-- Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.

SELECT J.empl_nombre AS 'Nombre del Jefe',
        COUNT ( E.empl_codigo ) AS 'Cantidad de empleados a cargo',
        SUM( F.fact_total ) AS'Monto total vendido de los empleados a cargo',
        COUNT( F.fact_vendedor ) AS 'Cantidad de facturas realizadas por los empleados a cargo',
       (
                SELECT TOP 1 empl_codigo
		FROM Empleado
		JOIN Factura ON fact_vendedor = empl_codigo
		WHERE empl_jefe = J.empl_codigo AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY empl_codigo
		ORDER BY SUM(fact_total) DESC
	) AS 'Nombre del empleado con mejor ventas de ese jefe'
FROM Empleado E
JOIN Empleado J ON E.empl_jefe = J.empl_codigo
JOIN Factura F ON F.fact_vendedor = E.empl_codigo
WHERE YEAR(F.fact_fecha) = 2012
GROUP BY J.empl_nombre, J.empl_apellido, J.empl_codigo, YEAR(F.fact_fecha)
HAVING COUNT(F.fact_numero+F.fact_tipo+F.fact_sucursal) > 10
ORDER BY 4 DESC

---------------------------------------------------31---------------------------------------------------

-- Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las siguientes columnas:
        -- Año.
        -- Codigo de Vendedor
        -- Detalle del Vendedor
        -- Cantidad de facturas que realizó en ese año
        -- Cantidad de clientes a los cuales les vendió en ese año.
        -- Cantidad de productos facturados con composición en ese año
        -- Cantidad de productos facturados sin composicion en ese año.
        -- Monto total vendido por ese vendedor en ese año
-- Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya vendido mas productos diferentes de mayor a menor.

SELECT YEAR ( F.fact_fecha ) AS 'Año',
    
    F.fact_vendedor AS 'Codigo de Vendedor',
    
    E.empl_nombre AS 'Detalle del Vendedor',
    
    COUNT ( F.fact_tipo + F.fact_sucursal + F.fact_numero) AS 'Cantidad de facturas que realizó en ese año',
    
    COUNT ( DISTINCT F.fact_cliente) AS 'Cantidad de clientes a los cuales les vendió en ese año',
    
        (
		SELECT COUNT(DISTINCT item_producto)
		FROM Item_Factura
		JOIN Composicion ON comp_producto = item_producto
		JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) 
                AND fact_vendedor = F.fact_vendedor
	) AS 'Cantidad de productos facturados con composición en ese año',
    
        ( 
                SELECT COUNT ( DISTINCT item_producto )
		FROM Item_Factura
		JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND fact_vendedor = F.fact_vendedor AND item_producto NOT IN (SELECT comp_producto FROM Composicion)
	) AS 'Cantidad de productos facturados sin composición en ese año',
    
    SUM( F.fact_total ) AS 'Monto total vendido por ese vendedor en ese año'

FROM Factura F
JOIN Empleado E ON F.fact_vendedor = E.empl_codigo
GROUP BY YEAR(F.fact_fecha), F.fact_vendedor, E.empl_nombre
ORDER BY YEAR(F.fact_fecha) DESC

---------------------------------------------------32---------------------------------------------------

-- Se desea conocer las familias que sus productos se facturaron juntos en las mismas facturas para ello se solicita que escriba una consulta sql que retorne los pares de familias que tienen productos que se facturaron juntos. 
-- Para ellos deberá devolver las siguientes columnas:
        -- Código de familia
        -- Detalle de familia
        -- Código de familia
        -- Detalle de familia
        -- Cantidad de facturas
        -- Total vendido
-- Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias que se vendieron juntas más de 10 veces.

SELECT 
    FAM1.fami_id AS 'Código de familia 1',
    FAM1.fami_detalle AS 'Detalle de familia 1',
    FAM2.fami_id AS 'Código de familia 2',
    FAM2.fami_detalle AS 'Detalle de familia 2',
    COUNT(DISTINCT I1.item_tipo + I1.item_sucursal + I1.item_numero) AS 'Cantidad de facturas',
    SUM(I1.item_cantidad * I1.item_precio) + SUM(I2.item_cantidad * I2.item_precio) AS 'Total vendido entre items de ambas familias'
FROM Familia FAM1
JOIN Producto P1 ON P1.prod_familia = FAM1.fami_id
JOIN Item_Factura I1 ON I1.item_producto = P1.prod_codigo
JOIN Familia FAM2 ON FAM2.fami_id > FAM1.fami_id -- Aseguramos que sea un par único, evitando duplicados
JOIN Producto P2 ON P2.prod_familia = FAM2.fami_id
JOIN Item_Factura I2 ON I2.item_producto = P2.prod_codigo 
        AND I1.item_numero = I2.item_numero AND I1.item_tipo = I2.item_tipo  AND I1.item_sucursal = I2.item_sucursal -- Solo productos en la misma factura
GROUP BY FAM1.fami_id, FAM1.fami_detalle, FAM2.fami_id, FAM2.fami_detalle
HAVING COUNT(DISTINCT I1.item_tipo + I1.item_sucursal + I1.item_numero) > 10 -- Más de 10 facturas
ORDER BY 'Total vendido entre items de ambas familias' DESC;

---------------------------------------------------33---------------------------------------------------

-- Se requiere obtener una estadística de venta de productos que sean componentes. 
-- Para ello se solicita que realiza la siguiente consulta que retorne la venta de los componentes del producto más vendido del año 2012. 
-- Se deberá mostrar:
        -- Código de producto
        -- Nombre del producto
        -- Cantidad de unidades vendidas
        -- Cantidad de facturas en la cual se facturo
        -- Precio promedio facturado de ese producto.
        -- Total facturado para ese producto
-- El resultado deberá ser ordenado por el total vendido por producto para el año 2012.

SELECT 
    prod_codigo AS 'Código de producto',
    prod_detalle AS 'Nombre del producto',
    SUM(item_cantidad) AS 'Cantidad de unidades vendidas',
    COUNT(DISTINCT CONCAT(item_tipo, item_sucursal, item_numero)) AS 'Cantidad de facturas en las cuales se facturó',
    AVG(item_precio) AS 'Precio promedio facturado de ese producto',
    SUM(item_cantidad * item_precio) AS 'Total facturado para ese producto'
FROM Item_Factura
JOIN Producto ON item_producto = prod_codigo
WHERE CONCAT(item_tipo, item_sucursal, item_numero) IN ( SELECT CONCAT(fact_tipo, fact_sucursal, fact_numero) FROM Factura WHERE YEAR(fact_fecha) = 2012 ) 
AND item_producto IN ( SELECT TOP 1 item_producto 
                        FROM Item_Factura
                        JOIN Factura ON CONCAT(item_tipo, item_sucursal, item_numero) = CONCAT(fact_tipo, fact_sucursal, fact_numero)
                        WHERE YEAR(fact_fecha) = 2012 AND item_producto IN ( SELECT comp_componente FROM Composicion )-- Productos que son componentes
                        GROUP BY item_producto
                        ORDER BY SUM(item_cantidad) DESC
                ) -- Solo el producto más vendido
GROUP BY prod_codigo, prod_detalle
ORDER BY SUM(item_cantidad * item_precio) DESC

---------------------------------------------------CHEQUEO

SELECT COUNT(DISTINCT CONCAT(item_tipo, item_sucursal, item_numero)) AS 'Cantidad de facturas',
    SUM(item_cantidad) AS 'Total unidades vendidas'
FROM Item_Factura
JOIN Producto ON item_producto = prod_codigo
JOIN Factura ON CONCAT(item_tipo, item_sucursal, item_numero) = CONCAT(fact_tipo, fact_sucursal, fact_numero)
WHERE prod_detalle = 'PILAS E 91 u.' AND YEAR(fact_fecha) = 2012;

---------------------------------------------------34---------------------------------------------------

-- Escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal facturadas por cada mes del año 2011 
-- Se considera que una factura es incorrecta cuando en la misma factura se factutan productos de dos rubros diferentes. 
-- Si no hay facturas mal hechas se debe retornar 0. 
-- Las columnas que se deben mostrar son:
        -- Codigo de Rubro
        -- Mes
        -- Cantidad de facturas mal realizadas.

SELECT P.prod_rubro AS 'Código de Rubro', 
    MONTH(F.fact_fecha) AS 'Mes', 
    COUNT ( DISTINCT F.fact_tipo + F.fact_sucursal + F.fact_numero ) AS 'Cantidad de facturas mal realizadas'
FROM Producto P
JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero = I.item_numero AND F.fact_sucursal = I.item_sucursal AND F.fact_tipo = I.item_tipo 
WHERE YEAR(F.fact_fecha) = 2011
AND ( SELECT COUNT ( DISTINCT prod_rubro ) FROM Producto JOIN Item_Factura ON item_producto = prod_codigo WHERE item_tipo+item_sucursal+item_numero = I.item_tipo+I.item_sucursal+I.item_numero GROUP BY item_tipo+item_sucursal+item_numero ) > 1
GROUP BY P.prod_rubro, MONTH(F.fact_fecha)
ORDER BY 1 DESC

---------------------------------------------------35---------------------------------------------------

-- Se requiere realizar una estadística de ventas por año y producto, para ello se solicita que escriba una consulta sql que retorne las siguientes columnas
        -- Año
        -- Codigo de producto
        -- Detalle del producto
        -- Cantidad de facturas emitidas a ese producto ese año
        -- Cantidad de vendedores diferentes que compraron ese producto ese año.
        -- Cantidad de productos a los cuales compone ese producto, si no compone a ninguno se debera retornar 0.
        -- Porcentaje de la venta de ese producto respecto a la venta total de ese año.
-- Los datos deberan ser ordenados por año y por producto con mayor cantidad vendida.

SELECT YEAR(F.fact_fecha),
        P.prod_codigo,
        P.prod_detalle, 
        COUNT ( DISTINCT F.fact_tipo + F.fact_sucursal + F.fact_numero ),
        COUNT ( DISTINCT F.fact_vendedor ),
        ISNULL ( ( SELECT COUNT ( comp_componente ) FROM Composicion PC WHERE PC.comp_componente = P.prod_codigo ) , 0 ),
        SUM( I.item_cantidad * I.item_precio ) / ( SELECT SUM ( I2.item_cantidad * I2.item_precio)
                                                FROM Item_Factura I2
                                                JOIN Factura F2 ON F2.fact_numero = I2.item_numero AND F2.fact_sucursal = I2.item_sucursal AND F2.fact_tipo = I2.item_tipo
                                                WHERE YEAR(F2.fact_fecha) = YEAR(F.fact_fecha)
                                                ) * 100 
FROM Producto P
JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero = I.item_numero AND F.fact_sucursal = I.item_sucursal AND F.fact_tipo = I.item_tipo 
GROUP BY YEAR(F.fact_fecha), P.prod_codigo, P.prod_detalle
ORDER BY YEAR(F.fact_fecha), SUM(I.item_cantidad) DESC;
