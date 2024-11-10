SELECT YEAR(f.fact_fecha) AS Año,
        f.fact_cliente AS ClienteID,
        c.clie_razon_social AS RazonSocial
FROM Factura f
JOIN Cliente c ON f.fact_cliente = c.clie_codigo
WHERE f.fact_cliente = ( -- EL CLIENTE QUE MAS COMPRO
                            SELECT TOP 1 f2.fact_cliente
                            FROM Factura f2 WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) -- OTRA FACURA DEL MISMO AÑO
                            AND f2.fact_cliente IN ( -- Y QUE COMPRO EN AÑOS CONSECUTIVOS
                                                        SELECT f3.fact_cliente
                                                        FROM Factura f3 WHERE f3.fact_cliente = f2.fact_cliente -- OTRA FACURA DEL MISMO CLIENTE
                                                        AND YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) + 1 OR YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) - 1 -- QUE SEA EN AÑOS CONSECUTIVOS
                                                        GROUP BY f3.fact_cliente
                                                    )
                            GROUP BY f2.fact_cliente
                            ORDER BY SUM(f2.fact_total) DESC
                        )
GROUP BY YEAR(f.fact_fecha), f.fact_cliente, c.clie_razon_social;
