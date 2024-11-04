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
ORDER BY 2 DESC, 6 DESC
GO

---------------------------------------------------

-- Recalcular precios de productos con composicion
-- Nuevo precio: Suma de precio compontentes * 0,8

CREATE PROCEDURE RecalcularPreciosProductosCompuestos
AS
BEGIN
    DECLARE @Producto char(8)
    DECLARE CursorProductosCompuestos CURSOR FOR ( SELECT DISTINCT prod_codigo FROM Producto JOIN Composicion ON comp_producto = prod_codigo ) -- Cursor para iterar sobre los productos compuestos
    OPEN CursorProductosCompuestos
    FETCH NEXT FROM CursorProductosCompuestos INTO @Producto
    WHILE @@FETCH_STATUS = 0
    
    BEGIN
        UPDATE Producto SET prod_precio = dbo.precio_compuesto(@Producto) WHERE prod_codigo = @Producto -- Actualizar el precio del producto compuesto
        FETCH NEXT FROM CursorProductosCompuestos INTO @Producto
    END

    CLOSE CursorProductosCompuestos
    DEALLOCATE CursorProductosCompuestos
END
GO

CREATE FUNCTION precio_compuesto ( @Producto char(8) ) 
RETURNS decimal(12,2)
AS
BEGIN
    DECLARE @precio decimal(12,2)
    -- Es producto
    IF NOT EXISTS ( SELECT * FROM Composicion WHERE comp_producto = @producto )
		SET @precio = ( SELECT prod_precio FROM Producto WHERE prod_codigo = @producto )
    -- Es componente
    ELSE
        BEGIN
            DECLARE @componente CHAR(8), @componente_cant DECIMAL(12, 2)
            DECLARE CursorComponentes CURSOR FOR ( SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @Producto) -- Cursor para iterar sobre los productos que componen AL PRODUCTO
            OPEN CursorComponentes
            FETCH NEXT FROM CursorComponentes INTO @componente, @componente_cant 
	        WHILE @@FETCH_STATUS = 0
		    
            BEGIN
                SET @precio = @precio + dbo.precio_compuesto(@componente) * @componente_cant * 0.8  -- El 80% del costo del componente
                FETCH NEXT FROM CursorComponentes INTO @componente, @componente_cant
            END
        END
    RETURN @precio
END
GO