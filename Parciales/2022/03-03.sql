
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
GO

SELECT COUNT( DISTINCT fact_cliente) FROM Factura -- COMO SOLO 70 CLIENTES COMPRARON - HASTA EL CLIENTE 70 APARECE SU PORDUCTO MAS COMPRADO
GO

---------------------------------------------------

-- Realizar un stored procedure que reciba un código de producto y una fecha y 'devuelva la mayor cantidad de días consecutivos' a partir de esa fecha que 
-- el producto tuvo al menos la venta de una unidad en el día, el sistema de ventas on line está habilitado 24-7 por lo que se deben evaluar todos los días
-- incluyendo domingos y feriados.

CREATE PROCEDURE ObtenerDiasConsecutivosVentas ( @Producto char(8), @FechaInicio smalldatetime )
AS
BEGIN
    DECLARE @FechaActual DATE = @FechaInicio, @DiasConsecutivos INT = 0, @MaxDiasConsecutivos INT = 0

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Verificar si hubo ventas en el día actual
        IF EXISTS (
                    SELECT * 
                    FROM Item_Factura
                    JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
                    WHERE item_producto = @Producto
                    AND YEAR(fact_fecha) = YEAR(@FechaActual)
                    AND MONTH(fact_fecha) = MONTH(@FechaActual)
                    AND DAY(fact_fecha) = DAY(@FechaActual)
                )
            BEGIN
                -- Incrementar el conteo de días consecutivos con ventas
                SET @DiasConsecutivos = @DiasConsecutivos + 1

                -- Actualizar el máximo de días consecutivos si es mayor
                IF ( @DiasConsecutivos > @MaxDiasConsecutivos )
                    SET @MaxDiasConsecutivos = @DiasConsecutivos
            END
       
        ELSE -- No hay ventas en el día actual, reiniciar el contador de días consecutivos    
            SET @DiasConsecutivos = 0;

        -- Avanzar al día siguiente
        SET @FechaActual = DATEADD (DAY , 1, @FechaActual )
        
    END

    RETURN @MaxDiasConsecutivos -- Devolver el resultado
END
GO