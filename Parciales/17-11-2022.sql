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

ALTER TRIGGER InsertarComponentesEnLugarDeCombo ON Item_Factura AFTER INSERT
AS
BEGIN
    DECLARE @TIPO CHAR(1), @SUCURSAL CHAR(4), @NUMERO CHAR(8);
    DECLARE @PRODUCTO CHAR(8), @CANTIDAD DECIMAL(12,2), @PRECIO DECIMAL(12,2);

    DECLARE CursorProductos CURSOR FOR ( SELECT * FROM inserted WHERE item_producto IN (SELECT DISTINCT comp_producto FROM Composicion) )
    OPEN CursorProductos;
    FETCH NEXT FROM CursorProductos INTO @TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO;
    WHILE @@FETCH_STATUS = 0
    
    BEGIN
        -- Elimina el registro de combo original en la tabla item_factura
        DELETE FROM item_factura WHERE item_tipo = @TIPO AND item_sucursal = @SUCURSAL AND item_numero = @NUMERO AND item_producto = @PRODUCTO;

        -- Inserta los componentes en lugar del combo
        INSERT INTO item_factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
        SELECT 
            @TIPO,
            @SUCURSAL,
            @NUMERO,
            comp_componente,
            comp_cantidad * @CANTIDAD,
            prod_precio
        FROM composicion 
        JOIN producto ON comp_componente = prod_codigo 
        WHERE comp_producto = @PRODUCTO;

        FETCH NEXT FROM CursorProductos INTO @TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO;
    END

    CLOSE CursorProductos;
    DEALLOCATE CursorProductos;
END;
GO
