---------------------------------------------------12-11-2019---------------------------------------------------

-- Estadistica de ventas especiales --> MI UNIVERSO SON LAS F_E
-- La factura es especial si tiene mas de 1 producto con composicion vendido.
    -- year --> F_E
    -- cant_fact --> F_E
    -- total_facturado_especial --> F_E
    -- porc_especiales 
    -- max_factura --> F_E
    -- monto_total_vendido --> F --> SUBSELECT
    -- Order: cant_fact DESC, monto_total_vendido DESC

SELECT YEAR( F_E.fact_fecha ) AS 'AÑO',
    
    COUNT( F_E.fact_tipo + F_E.fact_sucursal + F_E.fact_numero ) AS 'CANTIDAD F_E',
    
    SUM( F_E.fact_total ) AS 'TOTAL F_E',
    
    -- ( SELECT SUM ( F.fact_total ) FROM Factura F WHERE YEAR ( F.fact_fecha ) = YEAR ( F_E.fact_fecha) ) AS 'TOTAL F',
    
    ( SUM ( F_E.fact_total ) / ( SELECT SUM ( F.fact_total ) FROM Factura F WHERE YEAR ( F.fact_fecha ) = YEAR ( F_E.fact_fecha) ) ) * 100 AS 'PORCENTAJE F_E', 
    
    MAX( F_E.fact_total ) AS 'F_E MAXIMA',
    
    ( SELECT SUM( F.fact_total ) FROM Factura F WHERE YEAR( F.fact_fecha ) = YEAR( F_E.fact_fecha ) ) AS 'MONTO TOTAL DE LO VENDIDO'

FROM Factura F_E
WHERE F_E.fact_tipo + F_E.fact_sucursal + F_E.fact_numero IN ( -- F_E si tiene mas de 1 producto con composicion vendido.
                                                                SELECT F_E.fact_tipo + F_E.fact_sucursal + F_E.fact_numero
                                                                FROM Factura F_E
                                                                JOIN Item_Factura IF_E ON F_E.fact_tipo = IF_E.item_tipo AND F_E.fact_sucursal = IF_E.item_sucursal AND F_E.fact_numero = IF_E.item_numero
                                                                JOIN Composicion ON IF_E.item_producto = comp_producto
                                                                GROUP BY F_E.fact_tipo + F_E.fact_sucursal + F_E.fact_numero
                                                                HAVING COUNT ( DISTINCT ( comp_producto ) ) > 1
                                                            )
GROUP BY YEAR( F_E.fact_fecha)
ORDER BY 2 DESC, 6 DESC;

---------------------------------------------------03-03-2022---------------------------------------------------

-- Armar una consulta Sql que retorne:
    -- Razón social del cliente
    -- Límite de crédito del cliente
    -- Producto más comprado en la historia (en unidades)

-- Solamente deberá mostrar aquellos clientes que: 
    -- Tuvieron mayor cantidad de ventas en el 2012 que en el 2011 en cantidades 
    -- Cuyos montos de ventas en dichos años sean un 30 % mayor el 2012 con respecto al 2011. 
-- El resultado deberá ser ordenado por código de cliente ascendente

-- NOTA: No se permite el uso de sub-selects en el FROM.

SELECT clie_razon_social AS 'Razón social del cliente',
    clie_limite_credito AS 'Límite de crédito del cliente',
    ISNULL ( (
                SELECT TOP 1 prod_detalle
                FROM Factura
                JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
                JOIN Producto ON item_producto = prod_codigo
                WHERE fact_cliente = clie_codigo
                GROUP BY prod_detalle
                ORDER BY SUM ( item_cantidad ) DESC                      
            ), '-'
          ) AS 'Producto más comprado en la historia -por el cliente- (en unidades)'
FROM Cliente
WHERE 
-- Condición para que las ventas en unidades sean mayores en 2012 que en 2011
    ( 
        SELECT SUM(i_2012.item_cantidad) FROM Item_Factura i_2012 JOIN Factura f_2012 ON i_2012.item_tipo = f_2012.fact_tipo AND i_2012.item_sucursal = f_2012.fact_sucursal AND i_2012.item_numero = f_2012.fact_numero WHERE f_2012.fact_cliente = clie_codigo AND YEAR(f_2012.fact_fecha) = 2012
    ) 
    >
    (
        SELECT SUM(i_2011.item_cantidad)FROM Item_Factura i_2011 JOIN Factura f_2011 ON i_2011.item_tipo = f_2011.fact_tipo AND i_2011.item_sucursal = f_2011.fact_sucursal AND i_2011.item_numero = f_2011.fact_numero WHERE f_2011.fact_cliente = clie_codigo AND YEAR(f_2011.fact_fecha) = 2011
    )
AND 
-- Condición para que el monto total en 2012 sea al menos un 30% mayor que en 2011
    ( 
        SELECT SUM(f_2012.fact_total) FROM Factura f_2012 WHERE f_2012.fact_cliente = clie_codigo AND YEAR(f_2012.fact_fecha) = 2012
    ) 
    >= 
    (
        SELECT SUM(f_2011.fact_total) * 1.3 FROM Factura f_2011 WHERE f_2011.fact_cliente = clie_codigo AND YEAR(f_2011.fact_fecha) = 2011
    )
ORDER BY clie_codigo ASC
    
SELECT COUNT( DISTINCT fact_cliente) FROM Factura -- COMO SOLO 70 CLIENTES COMPRARON - HASTA EL CLIENTE 70 APARECE SU PORDUCTO MAS COMPRADO

---------------------------------------------------03-03-2022---------------------------------------------------

-- Armar una consulta que muestre para todos los productos:
    -- Producto --> P
    -- Detalle del producto --> P
    -- Detalle composicion (si no es compuesto un string �SIN COMPOSICION�, si es compuesto un string �CON COMPOSICION�) --> C
    -- Cantidad de Componentes (si no es compuesto, tiene que mostrar 0) --> C
    -- Cantidad de veces que fue comprado por distintos clientes --> SUBSELECT

-- Nota: No se permiten sub select en el FROM.

SELECT prod_codigo AS 'Producto',
    prod_detalle AS 'Detalle del producto',
    ( CASE WHEN comp_producto is NULL THEN 'SIN COMPOSICION'ELSE 'CON COMPOSICION' END ) AS 'Detalle composicion',
    ISNULL ( COUNT ( comp_componente ) , 0 ) AS "Cantidad de Componentes",
    (
        SELECT COUNT( DISTINCT fact_cliente ) 
        FROM Factura
        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        WHERE item_producto = prod_codigo
    ) AS "Cantidad de veces comprado por distintos clientes"
FROM Producto
LEFT JOIN Composicion ON prod_codigo = comp_producto
GROUP BY prod_codigo, prod_detalle, comp_producto
ORDER BY 4 desc,5 desc

---------------------------------------------------15-11-2022---------------------------------------------------

-- Realizar una consulta SQL que permita saber los clientes que compraron todos los rubros disponibles del sistema en el 2012.
-- De estos clientes mostrar, siempre para el 2012:
    -- El código del cliente --> C
    -- La razón social del cliente --> C
    -- Código de producto que en cantidades más compro. --> SUBSELECT
    -- El nombre del producto del punto 3 --> SUBSELECT
    -- Cantidad de productos distintos comprados por el cliente. --> SUBSELECT
    -- Cantidad de productos con composición comprados por el cliente. --> SUBSELECT
    -- El resultado deberá ser ordenado por 
        -- Razón social del cliente alfabéticamente primero 
        -- Los clientes que compraron entre un 20% y 30% del total facturado en el 2012 primero, luego, los restantes.

-- Nota: No se permiten select en el from.

SELECT clie_codigo AS 'El código del cliente',
    clie_razon_social AS 'La razón social del cliente',

    (
        SELECT TOP 1 item_producto
        FROM Item_Factura
        JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        WHERE fact_cliente = clie_codigo AND YEAR ( fact_fecha ) = 2012
        GROUP BY item_producto
        ORDER BY SUM (item_cantidad) DESC
    ) AS 'Código de producto que en cantidades más compro',

    (
        SELECT TOP 1 prod_detalle
        FROM Item_Factura
        JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        JOIN Producto ON item_producto = prod_codigo
        WHERE fact_cliente = clie_codigo AND YEAR ( fact_fecha ) = 2012
        GROUP BY item_producto, prod_detalle
        ORDER BY SUM (item_cantidad) DESC
    ) AS 'El nombre del producto que en cantidades más compro',

    COUNT( DISTINCT item_producto ) AS 'Cantidad de productos distintos comprados',

    (
        SELECT ISNULL ( SUM ( item_cantidad ) , 0 )
        FROM Item_Factura
        JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        WHERE fact_cliente = clie_codigo AND YEAR ( fact_fecha ) = 2012 AND item_producto IN ( SELECT comp_producto FROM Composicion )
    ) AS 'Cantidad de productos con composición comprados por el cliente.'
FROM Cliente
JOIN Factura ON fact_cliente = clie_codigo
JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
WHERE YEAR ( fact_fecha ) = 2012
GROUP BY clie_codigo, clie_razon_social
HAVING SUM ( item_cantidad * item_precio ) > ( SELECT AVG ( fact_total ) FROM  Factura WHERE YEAR ( fact_fecha ) = 2012 )
order by clie_razon_social ASC,
    CASE WHEN SUM(item_cantidad * item_precio) BETWEEN (SELECT SUM(fact_total) * 0.20 FROM Factura WHERE YEAR(fact_fecha) = 2012) AND (SELECT SUM(fact_total) * 0.30 FROM Factura WHERE YEAR(fact_fecha) = 2012) 
        THEN 0
        ELSE 1
    END,
    SUM(item_cantidad * item_precio) DESC;
