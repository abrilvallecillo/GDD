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
GO

---------------------------------------------------

-- Implementar una regla de negocio de validación en línea que permita validar el STOCK al realizarse una venta. 
-- Cada venta se debe descontar sobre el depósito 00.
-- En caso de que se venda un producto compuesto, el descuento de stock se debe realizar por sus componentes. 
-- Si no hay STOCK para ese artículo, no se deberá guardar ese artículo, pero si los otros en los cuales hay stock positivo. 
-- Es decir, solamente se deberán guardar aquellos para los cuales si hay stock, sin guardarse los que no poseen cantidades suficientes.

CREATE TRIGGER ValidarStockAntesDeInsertarVenta ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
    DECLARE @Producto CHAR(8), @Cantidad DECIMAL(12,2), @Deposito CHAR(2) = '00', @Resultado INT, @StockActual DECIMAL(12,2)
    DECLARE cursor_inserted CURSOR FOR ( SELECT item_producto, item_cantidad FROM inserted )-- Cursor para iterar por cada fila insertada en Item_Factura
    OPEN cursor_inserted
    FETCH NEXT FROM cursor_inserted INTO @Producto, @Cantidad 
    WHILE @@FETCH_STATUS = 0
    
    BEGIN
        -- Llamada a la función para validar si se puede descontar el stock
        SET @Resultado = dbo.DescontarStock(@Producto, @Cantidad, @Deposito)
        
        IF ( @Resultado > 0 )
            BEGIN
                -- Obtener stock actual después de validación
                SELECT @StockActual = stoc_cantidad FROM Stock WHERE stoc_producto = @Producto AND stoc_deposito = @Deposito
                -- Actualizas
                UPDATE Stock SET stoc_cantidad = @StockActual - @Cantidad WHERE stoc_producto = @Producto AND stoc_deposito = @Deposito
                -- Insertar el producto en Item_Factura si hay suficiente stock
                INSERT INTO Item_Factura (item_producto, item_cantidad) VALUES (@Producto, @Cantidad)
                PRINT 'Se redujo el stock para el producto ' + @Producto
            END
        ELSE
        
        BEGIN
            PRINT 'No hay suficiente stock para el producto ' + @Producto
        END
        
        FETCH NEXT FROM cursor_inserted INTO @Producto, @Cantidad
    END

    CLOSE cursor_inserted
    DEALLOCATE cursor_inserted
END
GO

CREATE FUNCTION DescontarStock (@Producto CHAR(8), @Cantidad DECIMAL(12,2), @Deposito CHAR(2))
RETURNS INT
AS
BEGIN
    DECLARE @Resultado INT = 1, @StockActual DECIMAL(12,2)
    
    -- Comprobar si el producto es compuesto
    IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @Producto)
        BEGIN
            -- Procesar componentes del producto compuesto
            DECLARE @Componente CHAR(8), @CantidadRestante DECIMAL(12,2)
            DECLARE componente_cursor CURSOR FOR ( SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @Producto )
            OPEN componente_cursor
            FETCH NEXT FROM componente_cursor INTO @Componente, @CantidadRestante
            WHILE @@FETCH_STATUS = 0
            
            BEGIN
                -- Llamada recursiva a DescontarStock para verificar cada componente
                SET @Resultado = dbo.DescontarStock(@Componente, @CantidadRestante * @Cantidad, @Deposito)
                
                IF ( @Resultado < 0 )
                    BEGIN
                        CLOSE componente_cursor
                        DEALLOCATE componente_cursor
                        RETURN -1
                    END
                
                FETCH NEXT FROM componente_cursor INTO @Componente, @CantidadRestante
            END
            
            CLOSE componente_cursor
            DEALLOCATE componente_cursor
        END
    ELSE
        BEGIN
            -- Procesar producto simple
            SELECT @StockActual = stoc_cantidad FROM Stock WHERE stoc_producto = @Producto AND stoc_deposito = @Deposito

            IF @StockActual < @Cantidad
                RETURN -1  -- Indica stock insuficiente
        END

    RETURN @Resultado  -- Indica éxito en la validación de stock
END
GO
