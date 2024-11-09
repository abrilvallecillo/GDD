-- Realizar una consulta SQL que retorne para todas las zonas que tengan 3 (tres) o más depósitos. 
    -- 1. Detalle Zona --> ZONA
    -- 2. Cantidad de Depósitos x Zona --> DEPOSITO
    -- 3. Cantidad de Productos distintos compuestos en sus depósitos --> SUBCONSULTA
    -- 4. Producto mas vendido en el año 2012 que tenga stock en al menos uno de sus depósitos.  --> SUBCONSULTA
    -- 5. Mejor encargado perteneciente a esa zona (El que mas vendió en la historia).  --> SUBCONSULTA
    -- 6. El resultado deberá ser ordenado por monto total vendido del encargado descendiente.

SELECT zona_detalle AS 'Detalle Zona',
        COUNT ( DISTINCT depo_codigo ) AS 'Cantidad de Depósitos x Zona',
        (
            SELECT  COUNT ( DISTINCT stoc_producto ) -- Cantidad de Productos distintos
            FROM STOCK
            JOIN Composicion ON stoc_producto = comp_producto -- Compuestos
            JOIN DEPOSITO ON stoc_deposito = depo_codigo 
            WHERE depo_zona = zona_codigo -- Que este en la zona
        ) AS 'Cantidad de Productos distintos compuestos en sus depósitos',
        (
            SELECT TOP 1 item_producto
            FROM Item_Factura 
            JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
            WHERE YEAR ( fact_fecha ) = 2012
            AND item_producto IN ( -- Que tenga stock en al menos uno de sus depósitos
                                    SELECT stoc_producto
                                    FROM STOCK
                                    JOIN DEPOSITO ON stoc_deposito = depo_codigo 
                                    WHERE depo_zona = zona_codigo 
                                    AND stoc_cantidad > 0 
                                    )
            GROUP BY item_producto
            ORDER BY SUM ( item_cantidad ) DESC
        ) AS 'Producto mas vendido en el año 2012 que tenga stock en al menos uno de sus depósitos',
        (
            SELECT TOP 1 fact_vendedor
            FROM Factura
            WHERE fact_vendedor IN ( -- Perteneciente a esa zona
                                    SELECT depo_encargado
                                    FROM DEPOSITO
                                    WHERE depo_zona = zona_codigo
                                    )
            GROUP BY fact_vendedor
            ORDER BY SUM (fact_total) DESC
        ) AS 'Mejor encargado perteneciente a esa zona (El que mas vendió en la historia)'
FROM Zona
JOIN DEPOSITO ON zona_codigo = depo_zona
GROUP BY zona_detalle, zona_codigo
HAVING COUNT ( DISTINCT depo_codigo ) >= 3 -- Todas las zonas que tengan 3 (tres) o más depósitos
ORDER BY zona_detalle -- Ordenado por monto total vendido del encargado descendiente


---------------------------------------------------

-- Implementar una regla de negocio en línea donde se valide que nunca un producto compuesto pueda estar compuesto por 
-- componentes de rubros distintos a el.