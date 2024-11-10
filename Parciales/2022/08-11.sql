-- Realizar una consulta SQL que permita saber si un cliente compro un producto en todos los meses del 2012.
-- Además, mostrar para el 2012:
    -- 1. El cliente --> FACTURA
    -- 2. La razón social del cliente --> CLIENTE
    -- 3. El producto comprado --> ITEM
    -- 4. El nombre del producto --> SUBCONSULTA --> PRODUCTO
    -- 5. Cantidad de productos distintos comprados por el Cliente. --> ITEM
    -- 6. Cantidad de productos con composición comprados por el cliente. --> SUBCONSULTA
    -- 7. El resultado deberá ser ordenado poniendo primero aquellos clientes que compraron más de 10 productos distintos en el 2012. !

SELECT fact_cliente AS 'Código de Cliente',
    clie_razon_social AS 'Razón Social del Cliente',
    item_producto AS 'El producto comprado',
    ( SELECT prod_detalle FROM Producto WHERE prod_codigo = item_producto ) AS 'Nombre del Producto',
    COUNT ( DISTINCT item_producto ) AS 'Cantidad de Productos Distintos Comprados',
    ( SELECT COUNT ( DISTINCT comp_producto ) FROM Composicion WHERE item_producto = comp_producto ) AS 'Cantidad de Productos con Composición Comprados'
FROM Factura
JOIN Cliente ON fact_cliente = clie_codigo
JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
WHERE YEAR(fact_fecha) = 2012
AND item_producto IN (
                        SELECT item_producto
                        FROM Item_Factura
                        JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
                        WHERE YEAR ( fact_fecha ) = 2012
                        GROUP BY item_producto
                        HAVING COUNT ( DISTINCT MONTH ( fact_fecha ) ) = 12 -- Compro un producto en todos los meses del 2012
                    )
GROUP BY fact_cliente, clie_razon_social, item_producto
ORDER BY COUNT(DISTINCT item_producto) DESC
GO

-- Los productos que se vendieron en todos los meses del 2012
SELECT item_producto
FROM Item_Factura
JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR ( fact_fecha ) = 2012
GROUP BY item_producto
HAVING COUNT ( DISTINCT MONTH ( fact_fecha ) ) = 12 -- Compro un producto en todos los meses del 2012
GO

---------------------------------------------------

-- Implementar una regla de negocio de validación en línea que permita implementar una lógica de control de precios en las ventas. 
-- Se deberá poder seleccionar una lista de rubros y aquellos productos de los rubros que sean los seleccionados no podrán aumentar por mes más de un 2 %. 
-- En caso que no se tenga referencia del mes anterior no validar dicha regia.

