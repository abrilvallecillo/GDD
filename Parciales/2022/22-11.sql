-- Realizar una consulta SQL que muestre aquellos productos que tengan 3 componentes a nivel producto y cuyos componentes tengan 2 rubros distintos.
-- De estos productos mostrar:
    -- 1. El código de producto. --> PRODUCTO
    -- 2. El nombre del producto. --> PRODUCTO
    -- 3. La cantidad de veces que fueron vendidos sus componentes en el 2012. --> SUBCONSULTA
    -- 4. Monto total vendido del producto. --> Item_Factura
    -- 5. El resultado deberá ser ordenado por cantidad de facturas del 2012 en las cuales se vendieron los componentes. --> FACTURA

SELECT 
    prod_codigo AS 'Código de Producto',
    prod_detalle AS 'Nombre del Producto',
    (
        SELECT COUNT(*)
        FROM Item_Factura AS item
        JOIN Factura AS fact ON fact.fact_tipo = item.item_tipo AND fact.fact_sucursal = item.item_sucursal AND fact.fact_numero = item.item_numero
        WHERE item.item_producto IN ( SELECT comp_componente FROM Composicion WHERE comp_producto = prod_codigo )
        AND YEAR(fact.fact_fecha) = 2012
    ) AS 'Cantidad de veces que fueron vendidos sus componentes en 2012',
    SUM(item_precio * item_cantidad) AS 'Monto Total Vendido del Producto'  
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
WHERE prod_codigo IN (
                        SELECT comp_producto
                        FROM Composicion
                        JOIN Producto AS p ON comp_componente = p.prod_codigo
                        JOIN Rubro ON p.prod_rubro = rubr_id
                        GROUP BY comp_producto
                        HAVING COUNT(DISTINCT comp_componente) = 3  -- Producto con 3 componentes
                        AND COUNT(DISTINCT prod_rubro) = 2       -- Componentes con 2 rubros distintos
                    )
GROUP BY prod_codigo, prod_detalle
ORDER BY (
    SELECT COUNT(DISTINCT fact.fact_tipo + fact.fact_sucursal + fact.fact_numero)
    FROM Factura AS fact
    JOIN Item_Factura AS item ON fact.fact_tipo = item.item_tipo AND fact.fact_sucursal = item.item_sucursal AND fact.fact_numero = item.item_numero
    WHERE item.item_producto IN ( SELECT comp_componente FROM Composicion WHERE comp_producto = prod_codigo )
    AND YEAR(fact.fact_fecha) = 2012
) DESC;

---------------------------------------------------

-- Implementar una regla de negocio en linea donde se valide que nunca un producto compuesto pueda estar compuesto por componentes de rubros distintos a el.