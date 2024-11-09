-- Realizar una consulta SQL que retorne para los 10 clientes que más compraron en el 2012 y que fueron atendidos por más de 3 vendedores distintos:
        -- 1. Apellido y Nombre del Cliente. --> CLIENTE
        -- 2. Cantidad de Productos distintos comprados en el 2012. --> ITEMFACTURA
        -- 3. Cantidad de unidades compradas dentro del primer semestre del 2012. --> SUBSELECT
        -- 4. El resultado deberá mostrar ordenado la cantidad de ventas descendente del 2012 de cada cliente, en caso de igualdad de ventas, ordenar por código de cliente.

SELECT TOP 10 -- Para los 10 clientes
        clie_razon_social AS 'Nombre y Apellido Cliente',
        COUNT ( DISTINCT item_producto ) AS 'Cantidad de productos comprados en el 2012',
        (
            SELECT SUM ( item_cantidad ) 
            FROM Factura 
		    JOIN Item_Factura ON fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
		    WHERE YEAR ( fact_fecha ) = 2012 
            AND DATEPART ( QUARTER, fact_fecha ) = 1 
            AND fact_cliente = clie_codigo
        ) AS 'Cantidad de unidades compradas dentro del primer semestre del 2012.'
FROM CLIENTE
JOIN FACTURA ON clie_codigo = fact_cliente
JOIN Item_Factura ON fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
WHERE YEAR(fact_fecha) = 2012 -- Compraron en el 2012
GROUP BY clie_razon_social, clie_codigo
HAVING COUNT ( DISTINCT fact_vendedor) >= 3 -- Atendidos por más de 3 vendedores distintos
ORDER BY COUNT ( DISTINCT fact_numero + fact_sucursal + fact_tipo ) DESC, -- La cantidad de ventas descendente
        clie_codigo


-- En 2012 todos los clientes fueron atendidos por el mismo vendedor.
SELECT fact_cliente, COUNT ( DISTINCT fact_vendedor)
FROM FACTURA
WHERE YEAR(fact_fecha) = 2012 
GROUP BY fact_cliente
ORDER BY fact_cliente

---------------------------------------------------

-- Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor cantidad de días 
-- consecutivos a partir de esa fecha que el producto tuvo al menos la venta de una unidad en el día, el sistema de
-- ventas on line está habilitado 24-7 por lo que se deben evaluar todos los días incluyendo domingos y feriados.