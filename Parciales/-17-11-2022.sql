---------------------------------------------------17-11-2022---------------------------------------------------

-- Armar una consulta que muestre para todos los productos:
    -- Producto --> P
    -- Detalle del producto --> P
    -- Detalle composicion (si no es compuesto un string �SIN COMPOSICION�, si es compuesto un string �CON COMPOSICION�) --> C
    -- Cantidad de Componentes (si no es compuesto, tiene que mostrar 0) --> C
    -- Cantidad de veces que fue comprado por distintos clientes --> SUBSELECT

-- Nota: No se permiten sub select en el FROM.

SELECT prod_codigo AS 'Producto',
    prod_detalle AS 'Detalle del producto',
    ( CASE WHEN comp_producto is NULL THEN 'SIN COMPOSICION'ELSE 'CON COMPOSICION' END ) AS 'Detalle composicion',
    ISNULL ( COUNT ( comp_componente ) , 0 ) AS "Cantidad de Componentes",
    (
        SELECT COUNT( DISTINCT fact_cliente ) 
        FROM Factura
        JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        WHERE item_producto = prod_codigo
    ) AS "Cantidad de veces comprado por distintos clientes"
FROM Producto
LEFT JOIN Composicion ON prod_codigo = comp_producto
GROUP BY prod_codigo, prod_detalle, comp_producto
ORDER BY 4 desc,5 desc
GO

---------------------------------------------------

-- Implementar el/los objetos necesarios para implementar la siguiente restriccion en linea:
-- Cuando se inserta en una venta un COMBO, nunca se debera guardar el producto COMBO, sino, la descomposicion de sus componentes.

-- Nota: Se sabe que actualmente todos los articulos guardados de ventas estan descompuestos en sus componentes

ALTER TRIGGER InsertarComponentesEnLugarDeCombo ON Item_Factura AFTER INSERT--INSTEAD OF INSERT
AS
BEGIN
	DECLARE @TIPO CHAR(1), @SUCURSAL CHAR(4), @NUMERO char(8)
    DECLARE @PRODUCTO CHAR(8), @CANTIDAD DECIMAL(12,2), @PRECIO DECIMAL(12,2)
    DECLARE CursorProductos CURSOR FOR ( SELECT * FROM inserted )
    OPEN CursorProductos
    FETCH NEXT FROM CursorProductos INTO @TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO
    WHILE @@FETCH_STATUS = 0
    
    BEGIN
        -- Verificar si el producto es un combo
        IF EXISTS ( SELECT * FROM Composicion WHERE comp_producto = @Producto )
            -- Insertar los componentes en lugar del combo
            
        
        -- Si no es un combo, insertar el producto normalmente
        ELSE
            INSERT INTO Item_Factura VALUES( @TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO )

        FETCH NEXT FROM CursorProductos INTO @TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO
    END

    CLOSE CursorProductos
    DEALLOCATE CursorProductos
END
GO


-- Obtener los componentes asociados a un producto

ALTER FUNCTION ObtenerComponentes(@Producto CHAR(8))
RETURNS CHAR(8) 
AS
BEGIN
    -- Compuesto
    IF EXISTS ( SELECT * FROM Composicion WHERE comp_producto = @Producto )
        BEGIN
            DECLARE @componente CHAR(8)
            DECLARE CursorComponentes CURSOR FOR ( SELECT comp_componente FROM Composicion WHERE comp_producto = @Producto )
            OPEN CursorComponentes
            FETCH NEXT FROM @componente
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Llamada recursiva para obtener componente
                
                FETCH NEXT FROM @componente
            END
            CLOSE CursorComponentes
            DEALLOCATE CursorComponentes
        END

    ELSE
        BEGIN
        END
END
GO


-- Obtener la cantidad total de componentes asociados a un producto
ALTER FUNCTION ObtenerCantidad(@Producto CHAR(8))
RETURNS int
AS
BEGIN
    RETURN (
        SELECT ISNULL( SUM ( comp_cantidad ) - 1 , 0)
        FROM Composicion 
        WHERE comp_producto = @Producto
    )
END
GO



SELECT dbo.ObtenerComponentes('00001104')  
GO -- 6.91

SELECT dbo.ObtenerCantidad('00001104')  
GO -- 24483.75

SELECT dbo.ObtenerComponentes('00000030')  
GO -- 6.91

SELECT dbo.ObtenerCantidad('00000030')  
GO -- 24483.75