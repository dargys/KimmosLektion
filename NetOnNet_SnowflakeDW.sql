
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
IF OBJECT_ID('dbo.DimPaymentMethod','U') IS NOT NULL DROP TABLE dbo.DimPaymentMethod;
IF OBJECT_ID('dbo.DimPaymentProvider','U') IS NOT NULL DROP TABLE dbo.DimPaymentProvider;

IF OBJECT_ID('dbo.DimProduct','U') IS NOT NULL DROP TABLE dbo.DimProduct;
IF OBJECT_ID('dbo.DimSubCategory','U') IS NOT NULL DROP TABLE dbo.DimSubCategory;
IF OBJECT_ID('dbo.DimCategory','U') IS NOT NULL DROP TABLE dbo.DimCategory;

IF OBJECT_ID('dbo.DimCustomer','U') IS NOT NULL DROP TABLE dbo.DimCustomer;
IF OBJECT_ID('dbo.DimContact','U') IS NOT NULL DROP TABLE dbo.DimContact;

IF OBJECT_ID('dbo.DimDate','U') IS NOT NULL DROP TABLE dbo.DimDate;
IF OBJECT_ID('dbo.DimMonth','U') IS NOT NULL DROP TABLE dbo.DimMonth;
IF OBJECT_ID('dbo.DimQuarter','U') IS NOT NULL DROP TABLE dbo.DimQuarter;
IF OBJECT_ID('dbo.DimYear','U') IS NOT NULL DROP TABLE dbo.DimYear;
GO


-- 3. Create DIM tables

CREATE TABLE dbo.DimYear (
    YearID INT PRIMARY KEY,
    YearNumber INT NOT NULL
);
GO

CREATE TABLE dbo.DimQuarter (
    QuarterID INT PRIMARY KEY,
    QuarterNumber INT NOT NULL,
    YearID INT NOT NULL,
    FOREIGN KEY (YearID) REFERENCES dbo.DimYear(YearID)
);
GO

CREATE TABLE dbo.DimMonth (
    MonthID INT PRIMARY KEY,
    MonthNumber INT NOT NULL,
    MonthName NVARCHAR(50) NOT NULL,
    QuarterID INT NOT NULL,
    FOREIGN KEY (QuarterID) REFERENCES dbo.DimQuarter(QuarterID)
);
GO

CREATE TABLE dbo.DimDate (
    DateID                  INT                 PRIMARY KEY,
    FullDate                DATE                NOT NULL,
    [Week]                  INT                 NOT NULL,
    [DayOfWeek]             INT                 NOT NULL,
    [DayName]               NVARCHAR(50)        NOT NULL,
    YearID                  INT                 NULL, -- starting as nullable before load
    MonthID                 INT                 NULL, -- starting as nullable before load
    FOREIGN KEY (YearID) REFERENCES dbo.DimYear(YearID),
    FOREIGN KEY (MonthID) REFERENCES dbo.DimMonth(MonthID)
);
GO

CREATE TABLE dbo.DimContact (
    ContactID                INT                PRIMARY KEY,
    Email                    NVARCHAR(150)      NOT NULL,
    Phone                    NVARCHAR(50)       NULL
);
GO

CREATE TABLE dbo.DimCustomer (
    CustomerID              INT                 PRIMARY KEY,
    FirstName               NVARCHAR(50)        NOT NULL,
    LastName                NVARCHAR(50)        NOT NULL,
    ContactID               INT                 NOT NULL,
    FOREIGN KEY (ContactID) REFERENCES dbo.DimContact(ContactID)
);
GO


CREATE TABLE DimCategory (
	CategoryID               INT                 PRIMARY KEY,
	CategoryName             NVARCHAR(50)
);
GO

CREATE TABLE DimSubCategory (
	SubCategoryID            INT                 PRIMARY KEY,
	SubCategoryName          NVARCHAR(50),
	CategoryID               INT,
	FOREIGN KEY (CategoryID) REFERENCES DimCategory(CategoryID)
);
GO

CREATE TABLE dbo.DimProduct (
    ProductID               INT                 PRIMARY KEY,
    ProductName             NVARCHAR(100)       NOT NULL,
    SKU                     NVARCHAR(50)        NOT NULL,
    UnitPriceProduct        DECIMAL(10,2)       NOT NULL,
    PurchasePriceProduct    DECIMAL(10,2)       NOT NULL,
    Color                   NVARCHAR(20)        NULL,
    CreatedDateProduct      DATE                NOT NULL,
    SubCategoryID           INT                 NOT NULL,
    FOREIGN KEY (SubCategoryID) REFERENCES DimSubCategory(SubCategoryID)
);
GO

CREATE TABLE dbo.DimPaymentMethod (
    PaymentMethodID         INT                 PRIMARY KEY,
    PaymentMethodName       NVARCHAR(20)        NOT NULL
);
GO

CREATE TABLE dbo.DimPaymentProvider (
    PaymentProviderID       INT                 PRIMARY KEY,
    PaymentProviderName     NVARCHAR(20)        NOT NULL
);
GO

CREATE TABLE dbo.DimPayment (
    PaymentID               INT                 PRIMARY KEY,
    PaymentMethodID         INT                 NOT NULL,
    PaymentProviderID       INT                 NOT NULL,
    FOREIGN KEY (PaymentMethodID) REFERENCES DimPaymentMethod(PaymentMethodID),
    FOREIGN KEY (PaymentProviderID) REFERENCES DimPaymentProvider(PaymentProviderID)
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
INSERT INTO dbo.DimDate (DateID, FullDate, [Week], [DayOfWeek], [DayName])
SELECT
    YEAR(d.FullDate) * 10000 + MONTH(d.FullDate) * 100 + DAY(d.FullDate) AS DateID,
    d.FullDate,
    DATEPART(ISO_WEEK, d.FullDate)              AS [Week],
    DATEPART(WEEKDAY, d.FullDate)               AS [DayOfWeek],
    DATENAME(WEEKDAY, d.FullDate)               AS [DayName]
FROM (
    SELECT DISTINCT CAST(o.OrderDate AS DATE) AS FullDate
    FROM NetOnNet.dbo.[Order] o
) d;

--Load DimYear
INSERT INTO dbo.DimYear (YearID, YearNumber)
SELECT DISTINCT YEAR(FullDate) AS YearID, YEAR(FullDate)
FROM dbo.DimDate;


--Load DimQuarter
INSERT INTO dbo.DimQuarter (QuarterID, QuarterNumber, YearID)
SELECT DISTINCT
    YEAR(FullDate) * 10 + DATEPART(QUARTER, FullDate) AS QuarterID,
    DATEPART(QUARTER, FullDate),
    YEAR(FullDate)
FROM dbo.DimDate;


--Load DimMonth
INSERT INTO dbo.DimMonth (MonthID, MonthNumber, MonthName, QuarterID)
SELECT DISTINCT
    YEAR(FullDate) * 100 + MONTH(FullDate) AS MonthID,
    MONTH(FullDate),
    DATENAME(MONTH,FullDate),
    YEAR(FullDate) * 10 + DATEPART(QUARTER,FullDate) AS QuarterID
FROM dbo.DimDate;

-- Update DimDate with FKs
UPDATE d
SET 
    MonthID = YEAR(d.FullDate) * 100 + MONTH(d.FullDate),
    YearID  = YEAR(d.FullDate)  
FROM dbo.DimDate d;

-- Set MonthID and YearID to NOT NULL
ALTER TABLE dbo.DimDate
ALTER COLUMN MonthID INT NOT NULL;

ALTER TABLE dbo.DimDate
ALTER COLUMN YearID INT NOT NULL;



--Load DimContact
INSERT INTO dbo.DimContact (ContactID, Email, Phone)
SELECT
    c.CustomerID AS ContactID,
    c.Email,
    CAST(c.Phone AS NVARCHAR(50)) AS Phone
FROM NetOnNet.dbo.Customer c;

-- DimCustomer
INSERT INTO dbo.DimCustomer (CustomerID, FirstName, LastName, ContactID)
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.CustomerID
FROM NetOnNet.dbo.Customer c;

-- DimCategory
INSERT INTO dbo.DimCategory (
    CategoryID, CategoryName
)
SELECT
    c.CategoryID,
    c.CategoryName
FROM NetOnNet.dbo.Category c

-- DimSubCategory (Snowflake)
INSERT INTO dbo.DimSubCategory (
    SubCategoryID, SubCategoryName, CategoryID
)
SELECT
    sc.SubCategoryID,
    sc.SubCategoryName,
    sc.CategoryID
FROM NetOnNet.dbo.SubCategory sc

-- DimProduct
INSERT INTO dbo.DimProduct (
    ProductID, ProductName, SKU, UnitPriceProduct, 
    PurchasePriceProduct, Color, CreatedDateProduct, SubCategoryID
)
SELECT
    p.ProductID,
    p.ProductName,
    p.SKU,
    p.Price                             AS UnitPriceProduct,
    p.Cost                              AS PurchasePriceProduct,
    p.Color,
    CAST(p.CreatedAt AS DATE) AS CreatedDateProduct,
    p.SubCategoryID
FROM NetOnNet.dbo.Product p

-- DimPayment

-- Generate PaymentMethodID since it does not exist in NetOnNet db
INSERT INTO dbo.DimPaymentMethod (PaymentMethodID, PaymentMethodName)
SELECT 
    ROW_NUMBER() OVER (ORDER BY MethodName) AS PaymentMethodID,
    MethodName
FROM (
    SELECT DISTINCT MethodName
    FROM NetOnNet.dbo.Payment
) AS x;

-- Generate PaymentProviderID since it does not exist in NetOnNet db
INSERT INTO dbo.DimPaymentProvider (PaymentProviderID, PaymentProviderName)
SELECT 
    ROW_NUMBER() OVER (ORDER BY ProviderName) AS PaymentProviderID,
    ProviderName
FROM (
    SELECT DISTINCT ProviderName
    FROM NetOnNet.dbo.Payment
) AS x;

-- Use PaymentMethodID and PaymentProviderID as FKs
INSERT INTO dbo.DimPayment (PaymentID, PaymentMethodID, PaymentProviderID)
SELECT 
    p.PaymentID,
    pm.PaymentMethodID,
    pp.PaymentProviderID
FROM NetOnNet.dbo.Payment p
JOIN dbo.DimPaymentMethod pm
    ON pm.PaymentMethodName = p.MethodName
JOIN dbo.DimPaymentProvider pp
    ON pp.PaymentProviderName = p.ProviderName;



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