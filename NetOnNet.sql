IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'NetOnNet')
  BEGIN
    CREATE DATABASE NetOnNet
    END

USE NetOnNet

IF OBJECT_ID ('dbo.Category','U') IS NULL
BEGIN
CREATE TABLE Category(
    CategoryID      INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    CategoryName    NVARCHAR(50) NOT NULL
)
END;
GO

IF OBJECT_ID('dbo.SubCategory','U') IS NULL
BEGIN
CREATE TABLE dbo.SubCategory (
    SubCategoryID   INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    CategoryID      INT NOT NULL,
    SubCategoryName NVARCHAR(50) NOT NULL,
    FOREIGN KEY (CategoryID) REFERENCES dbo.Category(CategoryID)
)
END;
GO

IF OBJECT_ID('dbo.Product','U') IS NULL
BEGIN
CREATE TABLE dbo.Product (
    ProductID       INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    SubCategoryID   INT NOT NULL,
    SKU             NVARCHAR(50) NOT NULL UNIQUE,
    ProductName     NVARCHAR(255) NOT NULL,
    Price           DECIMAL(10, 2) NOT NULL,
    Cost            DECIMAL(10, 2) NOT NULL,
    CreatedAt       DATE NOT NULL,
    FOREIGN KEY (SubCategoryID) REFERENCES dbo.SubCategory(SubCategoryID)
)
END;
GO

IF OBJECT_ID('dbo.ProductAttribute','U') IS NULL
BEGIN
CREATE TABLE dbo.ProductAttribute (
    AttributeID     INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    ProductID       INT NOT NULL,
    AttributeName    NVARCHAR(100) NOT NULL,
    AttributeValue  NVARCHAR(255) NOT NULL,
    FOREIGN KEY (ProductID) REFERENCES dbo.[Product](ProductID)
)
END;
GO

IF OBJECT_ID('dbo.Customer','U') IS NULL
BEGIN
CREATE TABLE dbo.Customer (
    CustomerID  INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    FirstName   NVARCHAR(50) NOT NULL,
    LastName    NVARCHAR(50) NOT NULL,
    Email       NVARCHAR(150) NOT NULL UNIQUE,
    Phone       VARCHAR(20),
    [Address]   NVARCHAR(100)
)
END;
GO


IF OBJECT_ID('dbo.Order','U') IS NULL
BEGIN
CREATE TABLE dbo.[Order] (
    OrderID         INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    CustomerID      INT NOT NULL,
    OrderDate       DATE NOT NULL,
    OrderStatus     NVARCHAR(20) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(CustomerID)
)
END;
GO

IF OBJECT_ID('dbo.OrderItem','U') IS NULL
BEGIN
CREATE TABLE dbo.OrderItem (
    OrderItemID     INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    OrderID         INT NOT NULL,
    ProductID       INT NOT NULL,
    Quantity        INT NOT NULL,
    LineTotal       DECIMAL(10, 2) NOT NULL,
    DiscountApplied DECIMAL(10, 2),
    FOREIGN KEY (OrderID) REFERENCES dbo.[Order](OrderID),
    FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID)
)
END;
GO



IF OBJECT_ID('dbo.Return','U') IS NULL
BEGIN
CREATE TABLE dbo.[Return] (
    ReturnID    INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    OrderItemID INT NOT NULL,
    ReturnDate  DATE NOT NULL,
    Reason      NVARCHAR(255),
    Status      NVARCHAR(20) NOT NULL,
    Notes       NVARCHAR(MAX),
    FOREIGN KEY (OrderItemID) REFERENCES dbo.OrderItem(OrderItemID)
)
END;
GO

IF OBJECT_ID('dbo.Review','U') IS NULL
BEGIN
CREATE TABLE dbo.Review (
    ReviewID    INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    OrderID     INT NOT NULL,
    CustomerID  INT NOT NULL,
    Rating      INT NOT NULL,
    Comment     NVARCHAR(MAX),
    CreatedAt   DATE NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES dbo.[Order](OrderID),
    FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(CustomerID)
)
END;
GO


-- Nu tar vi det igen

