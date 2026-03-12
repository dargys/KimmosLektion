--1. Kontrollera produktkatalogen (Snowflake-testet)
--Denna fråga visar att kopplingen mellan Kategorier, Underkategorier och Produkter fungerar.
-- Den bevisar att Snowflake-struktur hänger ihop och att man kan navigera från en stor kategori ner till en specifik produkt.

SELECT 
    c.CategoryName AS Kategori, 
    sc.SubCategoryName AS Underkategori, 
    p.ProductName AS Produkt, 
    p.UnitPrice AS Pris
FROM dbo.Product p
JOIN dbo.SubCategory sc ON p.SubCategoryID = sc.SubCategoryID
JOIN dbo.Category c ON sc.CategoryID = c.CategoryID;

-- 2. Denna visar att när en kund köper något, så loggas det korrekt i både Order och Customer.
--Den visar att databasen fungerar som en motor för webbutiken – den håller koll på vem som handlat, när, och för hur mycket

SELECT 
    o.OrderID, 
    o.OrderDate AS Datum, 
    c.FirstName + ' ' + c.LastName AS Kund, 
    o.OrderTotalAmount AS Summa, 
    o.OrderStatus AS Status
FROM dbo.[Order] o
JOIN dbo.Customer c ON o.CustomerID = c.CustomerID;

-- 3. Denna fråga visar att kopplingen mellan en Order och de specifika produkterna OrderItem fungerar.
-- Den bevisar att OrderItem-tabellen gör sitt jobb: att länka samman produkter med rätt beställning.
SELECT 
    oi.OrderID, 
    p.ProductName AS Produkt, 
    oi.LineTotal AS RadSumma,
    p.SKU
FROM dbo.OrderItem oi
JOIN dbo.Product p ON oi.ProductID = p.ProductID
WHERE oi.OrderID = 1; -- Visar innehållet för order nummer 1