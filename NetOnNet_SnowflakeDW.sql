
--   NetOnNet STAR DW - Full Script
--   Source OLTP: NetOnNet
--   DW Database: NetOnNet_SnowflakeDW


-- 1. Create DW database

IF DB_ID('NetOnNet_SnowflakeDW') IS NULL
BEGIN
    CREATE DATABASE NetOnNet_SnowflakeDW;
END
GO

USE NetOnNet_SnowflakeDW;
GO


-- 2. Drop tables - in dependency order (to be able to rerun the syntax)

IF OBJECT_ID('dbo.FactSales','U') IS NOT NULL DROP TABLE dbo.FactSales;
IF OBJECT_ID('dbo.DimPayment','U') IS NOT NULL DROP TABLE dbo.DimPayment;
IF OBJECT_ID('dbo.DimProduct','U') IS NOT NULL DROP TABLE dbo.DimProduct;
IF OBJECT_ID('dbo.DimCustomer','U') IS NOT NULL DROP TABLE dbo.DimCustomer;
IF OBJECT_ID('dbo.DimDate','U') IS NOT NULL DROP TABLE dbo.DimDate;
GO


-- 3. Create DIM tables

CREATE TABLE dbo.DimDate (
    DateID                  INT                 PRIMARY KEY,
    FullDate                DATE                NOT NULL,
    [Year]                  INT                 NOT NULL,
    [Quarter]               INT                 NOT NULL,
    [Month]                 INT                 NOT NULL,
    [MonthName]             NVARCHAR(50)        NOT NULL,
    [Week]                  INT                 NOT NULL,
    [DayOfWeek]             INT                 NOT NULL,
    [DayName]               NVARCHAR(50)        NOT NULL
);
GO

CREATE TABLE dbo.DimCustomer (
    CustomerID              INT                 PRIMARY KEY,
    FirstName               NVARCHAR(50)        NOT NULL,
    LastName                NVARCHAR(50)        NOT NULL,
    Email                   NVARCHAR(150)       NOT NULL,
    Phone                   NVARCHAR(50)        NULL
);
GO

CREATE TABLE dbo.DimProduct (
    ProductID               INT                 PRIMARY KEY,
    ProductName             NVARCHAR(100)       NOT NULL,
    CategoryName            NVARCHAR(50)        NOT NULL,
    SubCategoryName         NVARCHAR(50)        NOT NULL,
    SKU                     NVARCHAR(50)        NOT NULL,
    UnitPriceProduct        DECIMAL(10,2)       NOT NULL,
    PurchasePriceProduct    DECIMAL(10,2)       NOT NULL,
    Color                   NVARCHAR(20)        NULL,
    CreatedDateProduct      DATE                NOT NULL
);
GO

CREATE TABLE dbo.DimPayment (
    PaymentID               INT                 PRIMARY KEY,
    PaymentMethodName       NVARCHAR(20)        NOT NULL,
    PaymentProviderName     NVARCHAR(20)        NOT NULL
);
GO


-- 4. Create FACT table (FKs to dims)
CREATE TABLE dbo.FactSales (
    SalesID                 INT IDENTITY(1,1)   PRIMARY KEY,
    DateID                  INT                 NOT NULL,
    ProductID               INT                 NOT NULL,
    CustomerID              INT                 NOT NULL,
    PaymentID               INT                 NOT NULL,
    OrderID                 INT                 NOT NULL,   -- degenerate dimension
    OrderItemID             INT                 NOT NULL,   -- degenerate dimension (grain = order item)
    PurchasePriceSales      DECIMAL(10,2)       NOT NULL,
    Quantity                INT                 NOT NULL,
    UnitPriceSales          DECIMAL(10,2)       NOT NULL,
    TotalAmount             DECIMAL(10,2)       NOT NULL,
    DiscountAmount          DECIMAL(10,2)       NOT NULL,
    RefundedAmount          DECIMAL(10,2)       NULL,
    PaymentIsApproved       BIT                 NOT NULL,
    PaymentCreatedDate      DATETIME            NOT NULL,

    CONSTRAINT FK_FactSales_DimDate     FOREIGN KEY (DateID)     REFERENCES dbo.DimDate(DateID),
    CONSTRAINT FK_FactSales_DimProduct  FOREIGN KEY (ProductID)  REFERENCES dbo.DimProduct(ProductID),
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerID) REFERENCES dbo.DimCustomer(CustomerID),
    CONSTRAINT FK_FactSales_DimPayment  FOREIGN KEY (PaymentID)  REFERENCES dbo.DimPayment(PaymentID)
);
GO


-- 5. Load Dims


-- DimDate from OLTP OrderDate (distinct calendar days)
INSERT INTO dbo.DimDate (DateID, FullDate, [Year], [Quarter], [Month], [MonthName], [Week], [DayOfWeek], [DayName])
SELECT
    YEAR(d.FullDate) * 10000 + MONTH(d.FullDate) * 100 + DAY(d.FullDate) AS DateID,
    d.FullDate,
    YEAR(d.FullDate)                    AS [Year],
    DATEPART(QUARTER, d.FullDate)       AS [Quarter],
    MONTH(d.FullDate)                   AS [Month],
    DATENAME(MONTH, d.FullDate)         AS [MonthName],
    DATEPART(ISO_WEEK, d.FullDate)      AS [Week],
    DATEPART(WEEKDAY, d.FullDate)       AS [DayOfWeek],
    DATENAME(WEEKDAY, d.FullDate)       AS [DayName]
FROM (
    SELECT DISTINCT CAST(o.OrderDate AS DATE) AS FullDate
    FROM NetOnNet.dbo.[Order] o
) d;

-- DimCustomer
INSERT INTO dbo.DimCustomer (CustomerID, FirstName, LastName, Email, Phone)
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    CAST(c.Phone AS NVARCHAR(50)) AS Phone
FROM NetOnNet.dbo.Customer c;

-- DimProduct
INSERT INTO dbo.DimProduct (
    ProductID, ProductName, CategoryName, SubCategoryName,
    SKU, UnitPriceProduct, PurchasePriceProduct, Color, CreatedDateProduct
)
SELECT
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    sc.SubCategoryName,
    p.SKU,
    p.Price                             AS UnitPriceProduct,
    p.Cost                              AS PurchasePriceProduct,
    p.Color,
    CAST(p.CreatedAt AS DATE) AS CreatedDateProduct
FROM NetOnNet.dbo.Product p
JOIN NetOnNet.dbo.SubCategory sc ON sc.SubCategoryID = p.SubCategoryID
JOIN NetOnNet.dbo.Category cat ON cat.CategoryID = sc.CategoryID;

-- DimPayment
INSERT INTO dbo.DimPayment (PaymentID, PaymentMethodName, PaymentProviderName)
SELECT
    pay.PaymentID,
    pay.MethodName                      AS PaymentMethodName,
    pay.ProviderName                    AS PaymentProviderName
FROM NetOnNet.dbo.Payment pay;

-- 6. Load fact (grain = OrderItem)

INSERT INTO dbo.FactSales (
    DateID, ProductID, CustomerID, PaymentID,
    OrderID, OrderItemID,
    PurchasePriceSales, Quantity, UnitPriceSales,
    TotalAmount, DiscountAmount, RefundedAmount, PaymentIsApproved, PaymentCreatedDate
)
SELECT
    YEAR(o.OrderDate) * 10000 + MONTH(o.OrderDate) * 100 + DAY(o.OrderDate) AS DateID,
    oi.ProductID,
    o.CustomerID,
    o.PaymentID,
    oi.OrderID,
    oi.OrderItemID,
    p.Cost                              AS PurchasePriceSales,
    oi.Quantity,
    CAST(oi.LineTotal / NULLIF(oi.Quantity, 0) AS DECIMAL(10,2)) AS UnitPriceSales,
    CAST(oi.LineTotal AS DECIMAL(10,2)) AS TotalAmount,
    CAST(ISNULL(oi.DiscountApplied, 0) AS DECIMAL(10,2)) AS DiscountAmount,
    NULL AS RefundedAmount,
    pay.IsApproved AS PaymentIsApproved,
    pay.CreatedDate AS PaymentCreatedDate
FROM NetOnNet.dbo.OrderItem oi
JOIN NetOnNet.dbo.[Order] o ON o.OrderID = oi.OrderID
JOIN NetOnNet.dbo.Product p ON p.ProductID = oi.ProductID
JOIN NetOnNet.dbo.Payment pay ON pay.PaymentID = o.PaymentID;


-- For testing:
/*
SELECT COUNT(*)     AS DimDateRows      FROM dbo.DimDate;
SELECT COUNT(*)     AS DimCustomerRows  FROM dbo.DimCustomer;
SELECT COUNT(*)     AS DimProductRows   FROM dbo.DimProduct;
SELECT COUNT(*)     AS DimPaymentRows   FROM dbo.DimPayment;
SELECT COUNT(*)     AS FactSalesRows    FROM dbo.FactSales;

-- revenue:

SELECT TOP 10
    d.FullDate,
    SUM(f.TotalAmount) AS Revenue
FROM dbo.FactSales f
JOIN dbo.DimDate d ON d.DateID = f.DateID
GROUP BY d.FullDate
ORDER BY d.FullDate DESC;
*/