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
    CASE WHEN SUM ( item_cantidad * item_precio ) 
            BETWEEN ( SELECT SUM (fact_total ) * 0.20 FROM Factura WHERE YEAR ( fact_fecha ) = 2012 ) 
            AND ( SELECT SUM ( fact_total) * 0.30 FROM Factura WHERE YEAR ( fact_fecha ) = 2012 ) 
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

CREATE TRIGGER ValidarStock ON Item_Factura AFTER INSERT --INSTEAD OF INSERT
AS
BEGIN
    DECLARE @TIPO CHAR(1), @SUCURSAL CHAR(4), @NUMERO CHAR(8);
    DECLARE @PRODUCTO CHAR(8), @CANTIDAD DECIMAL(12,2), @PRECIO DECIMAL(12,2);

    DECLARE CursorProductos CURSOR FOR ( SELECT * FROM inserted )
    OPEN CursorProductos;
    FETCH NEXT FROM CursorProductos INTO @TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Verificar si el producto es un combo
        IF EXISTS ( SELECT * FROM Composicion WHERE comp_producto = @PRODUCTO )
            BEGIN
                -- Procesar componentes del combo
                DECLARE @COMPONENTE CHAR(8), @CANTIDAD_COMP DECIMAL(12,2);
                
                DECLARE CursorComponentes CURSOR FOR ( SELECT comp_componente, comp_cantidad * @CANTIDAD FROM Composicion WHERE comp_producto = @PRODUCTO )
                OPEN CursorComponentes;
                FETCH NEXT FROM CursorComponentes INTO @COMPONENTE, @CANTIDAD_COMP;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Verificar si hay suficiente stock en el depósito 00 para el componente
                    IF EXISTS ( SELECT * FROM Stock WHERE stoc_producto = @COMPONENTE AND stoc_deposito = '00' AND stoc_cantidad >= @CANTIDAD_COMP )
                        BEGIN
                            -- Descontar el stock del componente
                            UPDATE Stock SET stoc_cantidad = stoc_cantidad - @CANTIDAD_COMP WHERE stoc_producto = @COMPONENTE AND stoc_deposito = '00';

                            -- Insertar el componente en la tabla Item_Factura
                            INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
                            VALUES (@TIPO, @SUCURSAL, @NUMERO, @COMPONENTE, @CANTIDAD_COMP, @PRECIO);
                        END

                    FETCH NEXT FROM CursorComponentes INTO @COMPONENTE, @CANTIDAD_COMP;
                END

                CLOSE CursorComponentes;
                DEALLOCATE CursorComponentes;
            END
        ELSE
            BEGIN
                -- Procesar un producto simple
                IF EXISTS ( SELECT * FROM dbo.Stock WHERE stoc_producto = @PRODUCTO AND stoc_deposito = '00' AND stoc_cantidad >= @CANTIDAD )
                BEGIN
                    -- Descontar el stock del producto simple
                    UPDATE Stock SET stoc_cantidad = stoc_cantidad - @CANTIDAD WHERE stoc_producto = @PRODUCTO AND stoc_deposito = '00';

                    -- Insertar el producto simple en la tabla Item_Factura
                    INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
                    VALUES (@TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO);
                END
            END

        FETCH NEXT FROM CursorProductos INTO @TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO;
    END

    CLOSE CursorProductos;
    DEALLOCATE CursorProductos;
END;
GO

---------------------------------------------------


CREATE TRIGGER tr_descontar_stock ON Item_Factura AFTER INSERT --INSTEAD OF INSERT
AS
BEGIN      
    -- Variables
    DECLARE @producto char(8), @cantidad_vendida decimal(12,2), @componente char(8), @cantidad_componente decimal(12,2)
    
    -- Cursor
    DECLARE cursor_producto CURSOR FOR ( SELECT item_producto, SUM(item_cantidad) FROM INSERTED GROUP BY item_producto )
    OPEN cursor_producto
    FETCH cursor_producto INTO @producto, @cantidad_vendida
    WHILE @@FETCH_STATUS = 0
    
    BEGIN
        -- Si no es compuesto, descuento sobre el producto original
        IF NOT EXISTS ( SELECT * FROM Composicion WHERE comp_producto = @producto )
            BEGIN
                UPDATE STOCK 
                SET stoc_cantidad = stoc_cantidad - @cantidad_vendida 
                WHERE stoc_deposito = '00' AND stoc_producto = @producto

                IF ( @@ERROR != 0 )
                    PRINT ( CONCAT ( 'EL PRODUCTO ', @producto, 'YA NO TIENE STOCK' ) )
                
                ELSE
                    BEGIN
                        INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
                        SELECT item_tipo, item_sucursal, item_numero,item_producto, item_cantidad, item_precio
                        FROM INSERTED 
                        WHERE item_producto = @producto
                    END
            END
        ELSE
            BEGIN
                -- Si es compuesto itero y descuento sobre los componentes
                DECLARE cursor_componente CURSOR FOR ( SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @producto )
                OPEN cursor_componente
                FETCH cursor_componente INTO @componente, @cantidad_componente
                WHILE @@FETCH_STATUS = 0
                
                BEGIN
                    UPDATE STOCK 
                    SET stoc_cantidad = stoc_cantidad - @cantidad_vendida * @cantidad_componente 
                    WHERE stoc_deposito = '00' AND stoc_producto = @componente

                    IF ( @@ERROR != 0 )
                        PRINT ( CONCAT ( 'EL PRODUCTO ', @producto, 'YA NO TIENE STOCK' ) )
                
                    ELSE
                        BEGIN
                            INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
                            SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio
                            FROM INSERTED 
                            WHERE item_producto = @componente
                            
                            FETCH cursor_componente INTO @componente,@cantidad_componente
                        END

                    CLOSE cursor_componente
                    DEALLOCATE cursor_componente

                    FETCH cursor_producto INTO @producto,@cantidad_vendida
                END
            END  
             
        CLOSE cursor_producto
        DEALLOCATE cursor_producto
    END
END
GO