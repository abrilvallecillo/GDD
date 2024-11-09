-- Se solicita estadística por Año y familia, para ello se deberá mostrar.
    -- Año --> FACTURA
    -- Código de familia --> FAMILIA
    -- Detalle de familia --> FAMILIA
    -- Cantidad de facturas --> FACTURA
    -- Cantidad de productos con Composición vendidos --> SUBSELECT
    -- Monto total vendido. --> ITEM

-- Solo se deberán considerar las familias que tengan al menos un producto con composición y que se hayan vendido conjuntamente (en la misma factura) con otra familia distinta.

-- NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto

SELECT YEAR ( fact_fecha ) AS 'Año',
        fami_id AS 'Codigo Familia',
        fami_detalle AS 'Detalle Familia',
        COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) AS 'Cantidad Facturas',
        ( 
            SELECT SUM ( item_cantidad ) 
            FROM Composicion JOIN Producto ON comp_producto = prod_codigo
            JOIN Item_Factura ON item_producto = prod_codigo JOIN Factura f1 ON f1.fact_numero + f1.fact_sucursal + f1.fact_tipo = item_numero + item_sucursal + item_tipo
            WHERE prod_familia = fami_id
            AND YEAR(Factura.fact_fecha) = YEAR(f1.fact_fecha )
        ) AS 'Cantidad Productos Compuestos Vendidos',
        SUM ( item_precio * item_cantidad ) AS 'Monto Total Vendido'
FROM Factura 
JOIN Item_Factura ON Factura.fact_tipo = Item_Factura.item_tipo AND Factura.fact_sucursal = Item_Factura.item_sucursal AND Factura.fact_numero = Item_Factura.item_numero
JOIN Producto ON item_producto = prod_codigo JOIN Familia ON prod_familia = fami_id
WHERE fami_id IN (SELECT DISTINCT prod_familia
                        FROM Producto 
                        JOIN Familia ON prod_familia = fami_id
                        JOIN Composicion ON comp_producto = prod_codigo
                    ) -- Las familias que tengan al menos un producto con composición (2)
AND fami_id IN (
                    SELECT p1.prod_familia 
                    FROM Producto p1 JOIN Item_Factura i1 ON item_producto = prod_codigo
                    JOIN Item_Factura i2 ON i1.item_numero + i1.item_sucursal + i1.item_tipo = i2.item_numero+i2.item_sucursal+i2.item_tipo JOIN Producto p2 on p2.prod_codigo = i2.item_producto -- Poducto de la misma facura
                    WHERE p2.prod_familia <> p1.prod_familia
                    GROUP BY p1.prod_familia
                ) -- Que se hayan vendido conjuntamente con otra familia distinta (82)
GROUP BY YEAR(fact_fecha), fami_id, fami_detalle
ORDER BY year(fact_fecha),fami_id,fami_detalle


SELECT year(f.fact_fecha),
    fa.fami_id,
    fami_detalle,
    COUNT(distinct f.fact_numero+f.fact_sucursal+f.fact_tipo) [CANTIDAD DE FACTURAS],
    
    (
        SELECT SUM(i1.item_cantidad) 
        FROM Composicion c1
        join Producto p1 on p1.prod_codigo = c1.comp_producto
        join Item_Factura i1 on i1.item_producto = p1.prod_codigo
        join Factura f1 on f1.fact_numero+f1.fact_sucursal+f1.fact_tipo=i1.item_numero+i1.item_sucursal+i1.item_tipo
        where p1.prod_familia =fa.fami_id and year(f1.fact_fecha) =YEAR(f.fact_fecha )
    )[CANTIDAD DE PROD COMPOSICION VENDIDOS] ,

SUM(i.item_cantidad*i.item_precio) [MONTO TOTAL]

FROM Factura f
join Item_Factura i on f.fact_numero+f.fact_sucursal+f.fact_tipo=i.item_numero+i.item_sucursal+i.item_tipo
join Producto p on p.prod_codigo = i.item_producto
join Familia fa on fa.fami_id = p.prod_familia
where fa.fami_id in (  -- Las familias que tengan al menos un producto con composición
                        select fa1.fami_id 
                        from Composicion c1
                        join Producto p1 on p1.prod_codigo = c1.comp_producto
                        join Familia fa1 on fa1.fami_id = p1.prod_familia
                        join Item_Factura i1 on i1.item_producto=p1.prod_codigo
                        join Factura f1 on f1.fact_numero+f1.fact_sucursal+f1.fact_tipo=i1.item_numero+i1.item_sucursal+i1.item_tipo
                        group by fa1.fami_id
                    )
and fa.fami_id in (
                    select p1.prod_familia 
                    from Producto p1 
                    join Item_Factura i1 on i1.item_producto = p1.prod_codigo
                    join Item_Factura i2 on i1.item_numero+i1.item_sucursal+i1.item_tipo = i2.item_numero+i2.item_sucursal+i2.item_tipo
                    join Producto p2 on p2.prod_codigo = i2.item_producto
                    where p2.prod_familia <> p1.prod_familia
                    group by p1.prod_familia
                )
group by year(f.fact_fecha),fa.fami_id,fa.fami_detalle
ORDER BY year(f.fact_fecha),fa.fami_id,fa.fami_detalle