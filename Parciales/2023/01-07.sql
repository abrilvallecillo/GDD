-- Realizar una consulta SQL que muestre aquellos clientes que en 2 años consecutivos compraron.
-- De estos clientes mostrar:
-- El código de cliente. --> Cliente/Factura
-- El nombre del cliente. --> Cliente
-- El numero de rubros que compro el cliente. --> Subconsulta
-- La cantidad de productos con composición que compro el cliente en el 2012.  --> Subconsulta
-- El resultado deberá ser ordenado por cantidad de facturas del cliente en toda la historia, de manera ascendente.

-- Nota: No se permiten select en el from, es decir, select. from (select ..a.s) T.

SELECT fact_cliente AS 'Código de Cliente',
    clie_razon_social AS 'Nombre del Cliente',
    (
        SELECT COUNT ( DISTINCT prod_rubro )
        FROM Item_Factura
        JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        JOIN Producto ON item_producto = prod_codigo
        WHERE fact_cliente = clie_codigo
    ) AS 'Número de Rubros Comprados',
    (
        SELECT COUNT ( DISTINCT item_producto )
        FROM Item_Factura
        JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
        WHERE fact_cliente = clie_codigo
        AND YEAR(fact_fecha) = 2012
        AND item_producto IN ( SELECT DISTINCT comp_producto FROM Composicion )
    ) AS 'Cantidad de Productos con Composición Comprados en 2012'
FROM Cliente
JOIN Factura ON fact_cliente = clie_codigo
WHERE clie_codigo IN (
                SELECT DISTINCT F1.fact_cliente -- 69 clientes compraron en dos años consecutivos 
                FROM Factura AS F1 JOIN Factura AS F2 ON F1.fact_cliente = F2.fact_cliente -- FACTURAS DEL MISMO CLIENTE
                AND YEAR(F1.fact_fecha) = YEAR(F2.fact_fecha) - 1 OR YEAR(F1.fact_fecha) = YEAR(F2.fact_fecha) + 1 --> Que compraron en 2 años consecutivos
                WHERE F1.fact_cliente = clie_codigo
            )
GROUP BY fact_cliente, clie_razon_social, clie_codigo
ORDER BY COUNT ( DISTINCT fact_tipo + fact_sucursal + fact_numero ) ASC
GO

---------------------------------------------------

-- Implementar una regla de negocio para mantener siempre consistente (actualizada bajo cualquier circunstancia) 
-- una nueva tabla llamada PRODUCTOS_VENDIDOS. 
-- En esta tabla debe registrar: 
    -- el periodo (YYYYMM)
    -- el código de producto 
    -- el precio máximo de venta 
    -- las unidades vendidas. 
    
-- Toda esta información debe estar por periodo (YYYYMM).

-- Crea la tabla con la estructura del enunciado
CREATE TABLE PRODUCTOS_VENDIDOS( periodo CHAR(6), prod_codigo char(8), precio DECIMAL(12, 2), cantidad INT)
GO 

CREATE TRIGGER ActualizarProductosVendidos ON Item_Factura AFTER INSERT, UPDATE
AS
BEGIN 
    -- Declaración de variables
    DECLARE @periodo CHAR(6), @prod_codigo char(8), @precio DECIMAL(12, 2), @cantidad INT
    
    -- Definición del cursor para iterar sobre los productos y sus ventas
    DECLARE cventas CURSOR FOR (
                                    SELECT CONCAT ( YEAR ( fact_fecha ) , '-',  MONTH ( fact_fecha ) ) ,
                                            item_producto,
                                            item_precio,
                                            item_cantidad
                                    FROM inserted
                                    JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
                                )

    OPEN cventas
    FETCH NEXT FROM cventas INTO @periodo, @prod_codigo, @precio, @cantidad
    WHILE @@FETCH_STATUS = 0
    
    BEGIN
        -- Insertar o actualizar la tabla PRODUCTOS_VENDIDOS con la información agregada
        IF EXISTS ( SELECT * FROM PRODUCTOS_VENDIDOS WHERE periodo = @periodo AND prod_codigo = @prod_codigo)
            -- Actualizar el registro si ya existe: sumar las unidades y actualizar el precio máximo
            UPDATE PRODUCTOS_VENDIDOS
            SET cantidad = cantidad + @cantidad,
                precio = CASE WHEN ( @precio > precio ) THEN @precio ELSE precio END
            WHERE periodo = @periodo AND prod_codigo = @prod_codigo;
        
        ELSE
        -- Insertar un nuevo registro si no existe
                INSERT INTO PRODUCTOS_VENDIDOS VALUES (@periodo, @prod_codigo, @precio, @cantidad);
    
        FETCH NEXT FROM cventas INTO @periodo, @prod_codigo, @precio, @cantidad
    
    END

    CLOSE cventas
    DEALLOCATE cventas
END