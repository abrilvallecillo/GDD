select clie_razon_social, clie_vendedor from Cliente, Empleado -- Solo me trae las columnas especificadas
select * from Cliente, Empleado -- Me trae todas las columnas del Cliente y luego todas las columnas del Empleado
select Empleado.*, clie_razon_social from Cliente, Empleado -- Trae todas las columnas del Empleado y la razon social

select * from Cliente -- Trae 3687 filas
select * from Empleado -- Trae 9
select Cliente.* from Cliente, Empleado -- Trae 33183 filas -- Me hace un producto cartesiano entre las tablas, 3687 filas de Cliente con 9 filas de Empleado
select Cliente.clie_codigo, Empleado.empl_nombre from Cliente, Empleado

select clie_codigo, clie_razon_social from cliente where clie_codigo between 1 and 3
select * from Cliente where clie_razon_social like 'A%' -- Que empiece con A y que siga cualquier cosa
select * from Cliente where clie_razon_social like 'A_A%' -- Que empiece con A, segida de una cualquier cosa, seguida de una A y que siga cualquier cosa
select * from Cliente where clie_razon_social like '%A%' -- Que contenga una A
select * from Cliente where clie_razon_social like '%A' -- Que termine con A

select clie_razon_social, isnull(clie_telefono, 'NO TIENE') from Cliente -- Si el valor del telefono es NULL cambialo por NO TIENE

-- Total de las facturas que se hicieron en 2011 y cual fue la menor de ellas
select year(fact_fecha) AS 'AÑO', 
        count (*) AS 'CANTIDAD DE FACTURAS', 
        min(fact_total) AS 'MENOR DE LAS FACTURAS',
        max(fact_total) AS 'MAYOR DE LAS FACTURAS', 
        avg(fact_total) AS 'PROMEDIO DE LAS FACTURAS',
        sum(fact_total) AS 'VENTA TOTAL'
from Factura
where year(fact_fecha) = 2011
group by year(fact_fecha)

select year(fact_fecha) AS 'AÑO', 
        month(fact_fecha) AS 'MES', 
        count (*) AS 'CANTIDAD DE FACTURAS', 
        min(fact_total) AS 'MENOR DE LAS FACTURAS',
        max(fact_total) AS 'MAYOR DE LAS FACTURAS', 
        avg(fact_total) AS 'PROMEDIO DE LAS FACTURAS',
        sum(fact_total) AS 'VENTA TOTAL'
from Factura
where year(fact_fecha) = 2011
group by year(fact_fecha), month(fact_fecha)

-- No es necesario el group by ya que son todos campos calculados
-- Todo lo que no sean campos calculados debe estar en el group by
select count (*) AS 'CANTIDAD DE FACTURAS', 
        min(fact_total) AS 'MENOR DE LAS FACTURAS',
        max(fact_total) AS 'MAYOR DE LAS FACTURAS', 
        avg(fact_total) AS 'PROMEDIO DE LAS FACTURAS',
        sum(fact_total) AS 'VENTA TOTAL'
from Factura

select empl_codigo, empl_nombre from Empleado group by empl_codigo -- Esto da error porque la fila empl_nombre no es calculable y no esta en el group by
select empl_codigo, empl_nombre from Empleado group by empl_codigo, empl_nombre

-- count cuenta las filas distintas de NULL
select count (clie_codigo) from Cliente
select count (clie_telefono) from Cliente

select count (*) AS 'CANTIDAD DE FACTURAS DE 2011', 
        count(distinct fact_cliente) AS 'CANTIDAD DE CLIENTES DE 2011' 
from Factura 
where year (fact_fecha) = 2011

select year(fact_fecha) AS 'AÑO', 
       count (*) AS 'CANTIDAD DE FACTURAS', 
        count(distinct fact_cliente) AS 'CANTIDAD DE CLIENTES',
        min(fact_total) AS 'MENOR DE LAS FACTURAS',
        max(fact_total) AS 'MAYOR DE LAS FACTURAS', 
        avg(fact_total) AS 'PROMEDIO DE LAS FACTURAS',
        sum(fact_total) AS 'VENTA TOTAL'
from Factura
group by year(fact_fecha) -- Cambia el universo
having sum(fact_total) > 1000 -- Filtra algo que surguio del group by -- Una vez agrupado, filtra
order by year(fact_fecha) asc -- desc

select clie_codigo, clie_razon_social from Cliente order by clie_domicilio

-- JOIN implicito
select clie_codigo, clie_vendedor, empl_apellido from cliente, Empleado where clie_vendedor = empl_codigo

-- JOIN explicito
select clie_codigo, clie_vendedor, empl_apellido from cliente join Empleado on clie_vendedor = empl_codigo

select * from cliente -- Me trae los 3687 clientes
select * from cliente join factura on clie_codigo = fact_cliente -- Me trae las 3000 facturas con sus clientes

-- Trae el nombre del cliente y la cantidad de facturas que tiene
select clie_razon_social, count(*) 
from cliente 
join factura on clie_codigo = fact_cliente -- LEFT JOIN me trae todos los clientes aunque no tengan facturass
group by clie_razon_social

select clie_razon_social AS 'Nombre', 
        count(fact_cliente) AS 'Cantidad de Facturas',
        case when count(fact_cliente) = 0 then 'NINGUNA' 
                when count(fact_cliente) < 100 then 'POCAS' 
                ELSE 'MUCHAS' END
from factura 
right join Cliente on clie_codigo = fact_cliente
group by clie_razon_social 
order by clie_razon_social

-- Los 10 clientes que mas nos compraron
select top 10 clie_razon_social AS 'Nombre', 
        count(fact_cliente) AS 'Cantidad de Facturas'
from factura 
right join Cliente on clie_codigo = fact_cliente
group by clie_razon_social 
order by count(fact_cliente) desc

-- Clientes que compraron alguna vez
select clie_codigo, count( distinct clie_razon_social )
from cliente 
join factura on clie_codigo = fact_cliente
group by clie_codigo

-- Consulta con select estatico
select clie_razon_social 
from cliente
where clie_codigo in (select fact_cliente from Factura) --Interseccion entre todos los clientes que tiene y los clientes que tienen factura, y las intersecciones que dan true, las trae

-- Consulta con select dinamico
select clie_razon_social 
from cliente
where exists (select fact_cliente from Factura where clie_codigo = fact_cliente) 

-- HAY DOS CLIENTES CON LA MISMA RAZON SOCIAL Y DISTINTO CODIGO
select clie_razon_social, count( distinct clie_codigo )
from cliente 
join factura on clie_codigo = fact_cliente
group by clie_razon_social

select clie_codigo, 
        (select distinct fact_cliente 
        from factura 
        where clie_codigo = fact_cliente) 
from Cliente

select distinct fact_cliente 
from factura, cliente --Para que el sub select funcione cono una consulta, se debe agregar el universo completo, el CLiente
where clie_codigo = fact_cliente
