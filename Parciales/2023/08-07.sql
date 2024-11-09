-- Se pide que realice un reporte generado por una sola query que de cortes de informacion por periodos (anual,semestral y bimestral). 
-- Un corte por el año, un corte por el semestre el año y un corte por bimestre el año. 
-- En el corte por año mostrar:
    -- Las ventas totales realizadas por año --> FACTURA
    -- La cantidad de rubros distintos comprados por año --> SUBCONSULTA
    -- La cantidad de productos con composicion distintos comporados por año --> SUBCONSULTA
    -- La cantidad de clientes que compraron por año. --> FACTURA
-- Luego, en la informacion del semestre mostrar la misma informacion, es decir, las ventas totales por semestre, cantidad de rubros por semestre, etc. y la misma logica por bimestre. 
-- El orden tiene que ser cronologico.

SELECT 
    CAST(YEAR(f.fact_fecha) AS VARCHAR) AS 'Periodo',
    SUM(f.fact_total) AS 'Ventas totales',
    
    (
        SELECT COUNT(DISTINCT prod_rubro)
        FROM Producto
        JOIN Item_Factura i ON prod_codigo = i.item_producto
        JOIN Factura f2 ON f2.fact_tipo = i.item_tipo AND f2.fact_sucursal = i.item_sucursal AND f2.fact_numero = i.item_numero
        WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
    ) AS 'Rubros distintos',

    (
        SELECT COUNT(DISTINCT prod_codigo)
        FROM Producto
        JOIN Item_Factura i ON prod_codigo = i.item_producto
        JOIN Factura f2 ON f2.fact_tipo = i.item_tipo AND f2.fact_sucursal = i.item_sucursal AND f2.fact_numero = i.item_numero
        WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
          AND prod_codigo IN (SELECT comp_producto FROM Composicion)
    ) AS 'Composiciones distintas',

    COUNT( fact_cliente) AS 'Clientes distintos'
FROM Factura f
GROUP BY YEAR(f.fact_fecha)

UNION

SELECT 
    CONCAT('Semestre ', CASE WHEN MONTH(f.fact_fecha) <= 6 THEN 1 ELSE 2 END) AS 'Periodo',
    SUM(f.fact_total) AS 'Ventas totales',
    
    (
        SELECT COUNT(DISTINCT prod_rubro)
        FROM Producto
        JOIN Item_Factura i ON prod_codigo = i.item_producto
        JOIN Factura f2 ON f2.fact_tipo = i.item_tipo AND f2.fact_sucursal = i.item_sucursal AND f2.fact_numero = i.item_numero
        WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
    ) AS 'Rubros distintos',

    (
        SELECT COUNT(DISTINCT prod_codigo)
        FROM Producto
        JOIN Item_Factura i ON prod_codigo = i.item_producto
        JOIN Factura f2 ON f2.fact_tipo = i.item_tipo AND f2.fact_sucursal = i.item_sucursal AND f2.fact_numero = i.item_numero
        WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
          AND prod_codigo IN (SELECT comp_producto FROM Composicion)
    ) AS 'Composiciones distintas',

    COUNT( fact_cliente) AS 'Clientes distintos'
FROM Factura f
GROUP BY YEAR(f.fact_fecha), CASE WHEN MONTH(f.fact_fecha) <= 6 THEN 1 ELSE 2 END

UNION

SELECT 
    CONCAT('Bimestre ', FLOOR((MONTH(f.fact_fecha) - 1) / 2) + 1) AS 'Periodo',
    SUM(f.fact_total) AS 'Ventas totales',
    
    (
        SELECT COUNT(DISTINCT prod_rubro)
        FROM Producto
        JOIN Item_Factura i ON prod_codigo = i.item_producto
        JOIN Factura f2 ON f2.fact_tipo = i.item_tipo AND f2.fact_sucursal = i.item_sucursal AND f2.fact_numero = i.item_numero
        WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
    ) AS 'Rubros distintos',

    (
        SELECT COUNT(DISTINCT prod_codigo)
        FROM Producto
        JOIN Item_Factura i ON prod_codigo = i.item_producto
        JOIN Factura f2 ON f2.fact_tipo = i.item_tipo AND f2.fact_sucursal = i.item_sucursal AND f2.fact_numero = i.item_numero
        WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
          AND prod_codigo IN (SELECT comp_producto FROM Composicion)
    ) AS 'Composiciones distintas',

    COUNT( fact_cliente) AS 'Clientes distintos'
FROM Factura f
GROUP BY YEAR(f.fact_fecha), FLOOR((MONTH(f.fact_fecha) - 1) / 2) + 1
