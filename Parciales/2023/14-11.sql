-- Sabiendo que si un producto no as vendido en un depósito determinado entonces no posee registros en él.
-- Se requiere una consulta SQL que para todos los productos que se quedaron sin stock en un depósito ( 0 o nula) y poseen un stock mayor al punto de reposición en otro deposito devuelva:
    -- Código de producto --> P
    -- Detalle del producto --> P
    -- Domicio del depósito sin stock --> D
    -- Cantidad de depósitos con un stock superior al punto de reposición --> SC
-- La consulta debe ser ordenada por el código de producto

-- NOTA: No se permite el uso de sub-selecte en el FROM

SELECT prod_codigo AS 'Codigo', 
    prod_detalle AS 'Detalle', 
    depo_domicilio AS 'Domicio del depósito sin stock',
    ( 
        SELECT COUNT(depo_codigo) 
        FROM STOCK 
        JOIN DEPOSITO ON stoc_deposito = depo_codigo 
        WHERE stoc_cantidad > stoc_punto_reposicion 
        AND prod_codigo = stoc_producto 
    ) AS 'Cantidad de depósitos con un stock superior al punto de reposición'
FROM Producto
JOIN STOCK ON prod_codigo = stoc_producto 
JOIN DEPOSITO ON stoc_deposito = depo_codigo
WHERE stoc_cantidad = 0 
OR stoc_cantidad = NULL
AND prod_codigo IN ( 
                        SELECT stoc_producto 
                        FROM STOCK 
                        WHERE stoc_cantidad > ISNULL ( stoc_stock_maximo , 0 )
                        GROUP BY stoc_producto )
ORDER BY prod_codigo
GO

---------------------------------------------------

-- Realizar un stored procedure que reciba un código de producto y una fecha y 'devuelva la mayor cantidad de días consecutivos' a partir de esa fecha que 
-- el producto tuvo al menos la venta de una unidad en el día, el sistema de ventas on line está habilitado 24-7 por lo que se deben evaluar todos los días
-- incluyendo domingos y feriados.

CREATE PROCEDURE ObtenerDiasCOnsecutivos( @producto char(8), @fecha SMALLDATETIME )
AS
BEGIN
    DECLARE @diasConsecitivos INT = 0
    DECLARE @maximaCantidad INT = 0
    DECLARE @fechaSiguiente SMALLDATETIME = @fecha + 1
    DECLARE @fechaFactura SMALLDATETIME

    DECLARE C_Fechas CURSOR FOR  
                                    SELECT fact_fecha
                                    FROM Factura 
                                    JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo 
                                    WHERE fact_fecha > @fecha
                                    AND item_producto = @producto
                                    ORDER BY fact_fecha ASC
                                    -- Todas las fechas concecutivas donde se vendio el producto
    OPEN C_Fechas
    FETCH NEXT FROM C_Fechas INTO @fechaFactura
    WHILE @@FETCH_STATUS = 0

    BEGIN
        IF ( @fechaFactura = @fechaSiguiente ) -- Hubo Ventas
            SET @diasConsecitivos +=1

        ELSE -- No Hubo Ventas
            BEGIN
                IF ( @maximaCantidad < @diasConsecitivos ) 
                    SET @maximaCantidad = @diasConsecitivos
                
                SET @diasConsecitivos = 0
            END

        FETCH NEXT FROM C_Fechas
    END
    CLOSE C_Fechas
    DEALLOCATE C_Fechas

    RETURN @maximaCantidad -- Devolvemos el resultado
END
GO