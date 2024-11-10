-- Realizar una consulta SQL que retorne la cantidad total de clientes que cumplen con las siguientes reglas
-- Reglas
-- Tener compras en años pares
-- Haber comprado en cantidades del último año de compra un 10% más que en su anteúltimo año de compra.
-- Tener más de 10 productos distintos comprados en el último año de compra
-- Solamente mostrar resultados si la cantidad total de clientes es mayor a 10.

-- Nota:Nose permiten select en el from, es decir, select ... from (select ...) as T,...

---------------------------------------------------

-- Implementar el/los objetos de base de datos necesarios para tener el historial de modificaciones de la tabla familia. 
-- Luego, presente un objeto de base de datos que dado una fecha [@fecha smalldatetime] se pueda saber qué valor tenía la 
-- tabla familia en esa @fecha.

-- Nota: Se entiende por historial de modificaciones a una estructura que permita conocer los valores de los atributos que 
-- tenía la tabla familia a una fecha dada.