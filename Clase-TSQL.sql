-- Crear la vista
CREATE VIEW v_Stok 
AS
SELECT prod_codigo AS Codigo_del_Prodcuto,
    prod_detalle AS Detalle_del_Prodcuto, 
    stoc_deposito AS Codigo_del_Deposito, 
    depo_detalle AS Deposito, 
    stoc_Cantidad AS Cantidad_en_Stock_del_Deposito
FROM Producto 
JOIN Stock ON prod_codigo = stoc_producto 
JOIN Deposito ON stoc_deposito = depo_codigo

-- Modificar la vista 
ALTER VIEW v_Stok 
AS
SELECT prod_codigo AS Codigo_del_Prodcuto,
    prod_detalle AS Detalle_del_Prodcuto, 
    stoc_deposito AS Codigo_del_Deposito, 
    depo_detalle AS Deposito, 
    stoc_Cantidad AS Cantidad_en_Stock_del_Deposito
FROM Producto 
JOIN Stock ON prod_codigo = stoc_producto 
JOIN Deposito ON stoc_deposito = depo_codigo
WHERE stoc_Cantidad > 100

-- Mostrar la vista
SELECT *
FROM v_Stok

SELECT Detalle_del_Prodcuto, 
    sum (Cantidad_en_Stock_del_Deposito),
    Deposito
FROM v_Stok 
GROUP BY Detalle_del_Prodcuto, Deposito
ORDER BY sum (Cantidad_en_Stock_del_Deposito) DESC

-- INTO 
SELECT prod_codigo AS Codigo_del_Prodcuto,
    prod_detalle AS Detalle_del_Prodcuto, 
    stoc_deposito AS Codigo_del_Deposito, 
    depo_detalle AS Deposito, 
    stoc_Cantidad AS Cantidad_en_Stock_del_Deposito
INTO V_Stock
FROM Producto 
JOIN Stock ON prod_codigo = stoc_producto 
JOIN Deposito ON stoc_deposito = depo_codigo

-- Diferencias entre INTO y la vista:
-- En INTO estan los datos, en la vista NO
-- INTO es estatico, la vista es dinamica
-- La vista devuelve lo que esta en el momento en la tabla original
-- INTO es un duplicado de una tabla, por ende sirve como back up