-- Listado de aquellos productos cuyas ventas de lo que va en el año 2012 fueron superiores al 15% del promedio de ventas de productos vendidos entre los años 2010 y 2011 
-- En base a lo solicitado, armar una consulta que retorne:
    -- 1. Detalle del producto --> Producto
    -- 2. Mostrar la leyenda "Popular" si dicho producto figura en más de 100 facturas realizadas en el 2012. 
        -- Caso contrario, mostrar la leyenda "Sin interes" 
    -- 3. Cantidad de facturas en las que aparece el producto en año 2012. 
    -- 4. Código del cliente que más compró dicho producto en 2012. (en caso de existir más de un cliente, mostrar solamente el de menor codigo)

SELECT prod_detalle AS 'Detalle del Producto',
    CASE WHEN (
                SELECT COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero )
                FROM Item_Factura
                JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
                WHERE item_producto = prod_codigo 
                AND YEAR(fact_fecha) = 2012 ) > 100 
        THEN 'Popular'
        ELSE 'Sin interés'
    END AS 'Popularidad del Producto',
    
    (
        SELECT COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero )
        FROM Item_Factura
        JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        WHERE item_producto = prod_codigo 
        AND YEAR(fact_fecha) = 2012
    ) AS 'Cantidad de Facturas en 2012',
    
    ( 
        SELECT TOP 1 fact_cliente
        FROM Factura
        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        WHERE item_producto = prod_codigo 
        AND YEAR(fact_fecha) = 2012
        GROUP BY fact_cliente
        ORDER BY SUM(item_cantidad) DESC, fact_cliente ASC
    ) AS 'Código del Cliente que Más Compró en 2012'
-- Aquellos productos cuyas ventas de lo que va en el año 2012 fueron superiores al 15% del promedio de ventas de productos vendidos entre los años 2010 y 2011 
FROM Producto
WHERE 
( 
    SELECT SUM ( item_cantidad * item_precio ) 
    FROM Item_Factura
    JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
    WHERE item_producto = prod_codigo AND YEAR(fact_fecha) = 2012
) > 0.15 *  
( -- Promedio de ventas de productos vendidos entre los años 2010 y 2011
    SELECT AVG ( item_cantidad * item_precio ) 
    FROM Item_Factura
    JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
    WHERE YEAR(fact_fecha) BETWEEN 2010 AND 2011
)
ORDER BY prod_detalle
GO

---------------------------------------------------

-- Realizar el o los objetos de base de datos que dado un código de producto y una
-- fecha y devuelva la mayor cantidad de días consecutivos a partir de esa
-- fecha que el producto tuvo al menos la venta de una unidad en el día, el
-- sistema de ventas on line está habilitado 24-7 por lo que se deben evaluar
-- todos los días incluyendo domingos y feriados.