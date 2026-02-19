IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'NetOnNet')
  BEGIN
    CREATE DATABASE NetOnNet
    END
GO

USE NetOnNet
GO

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
    Color           NVARCHAR (20),
    CreatedAt       DATETIME DEFAULT GETDATE() NOT NULL,
    ProductDetails  NVARCHAR(MAX) NULL,
    FOREIGN KEY (SubCategoryID) REFERENCES dbo.SubCategory(SubCategoryID),
    CONSTRAINT CK_ProductPrice CHECK (Price >= 0),
    CONSTRAINT CK_ProductCost CHECK (Cost >= 0),
    CONSTRAINT CK_ProductDetails_JSON CHECK (ProductDetails IS NULL OR ISJSON(ProductDetails) = 1)

)
END;
GO

/*ALTER TABLE dbo.Product
ADD WarrantyYears AS JSON_VALUE(ProductDetails, '$.warrantyYears') PERSISTED;

CREATE INDEX IX_Product_WarrantyYears
ON dbo.Product(WarrantyYears);*/

IF OBJECT_ID('dbo.Customer','U') IS NULL
BEGIN
CREATE TABLE dbo.Customer (
    CustomerID  INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    FirstName   NVARCHAR(50) NOT NULL,
    LastName    NVARCHAR(50) NOT NULL,
    Email       NVARCHAR(150) NOT NULL UNIQUE,
    Phone       VARCHAR(20)
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
    FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(CustomerID),
    CONSTRAINT CK_OrderStatus CHECK (OrderStatus IN('Väntande','Bearbetas', 'Skickat','Levererat', 'Avbrutet','Returerat'))
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
    FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID),
    CONSTRAINT CK_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_LineTotal CHECK (LineTotal >= 0)
)
END;
GO



IF OBJECT_ID('dbo.Return','U') IS NULL
BEGIN
CREATE TABLE dbo.[Return] (
    ReturnID    INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    OrderItemID INT NOT NULL,
    ReturnDate  DATE NOT NULL,
    Reason      NVARCHAR(100),
    Status      NVARCHAR(20) NOT NULL,
    Notes       NVARCHAR(MAX),
    FOREIGN KEY (OrderItemID) REFERENCES dbo.OrderItem(OrderItemID),
    CONSTRAINT CK_ReturnReason CHECK (ReturnReason IN ('Defekt', 'StämmerInte', 'Skadad', 'KundRequest', 'Övrigt')),
    CONSTRAINT CK_ReturnStatus CHECK (ReturnStatus IN ('Initierad', 'Godkänd', 'Avvisad', 'Slutförd'))
)
END;
GO



INSERT INTO dbo.Category (CategoryName) VALUES
('Dator & Surfplatta'),
('Datorkomponenter'),
('Gaming'),
('Hem & Fritid'),
('Personvård'),
('TV'),
('Ljud'),
('Mobil & Smartwatch'),
('Vitvaror'),
('Kamera & Foto'),
('Tillbehör');

GO

INSERT INTO dbo.SubCategory (CategoryID, SubCategoryName) VALUES
-- Dator & Surfplatta (1)
(1, 'Laptops'),
(1, 'Tablets & iPads'),

-- Datorkomponenter (2)
(2, 'Monitorer'),
(2, 'Tangentbord & Möss'),

-- Gaming (3)
(3, 'Gaming Möss'),
(3, 'Gaming Headset'),

-- Hem & Fritid (4)
(4, 'Rengöring'),
(4, 'Köksutrustning'),

-- Personvård (5)
(5, 'Hårbehandling'),

-- TV (6)
(6, 'Televisioner'),

-- Ljud (7)
(7, 'Högtalare'),

-- Mobil & Smartwatch (8)
(8, 'Smartphones'),
(8, 'Smartwatches'),

-- Vitvaror (9)
(9, 'Köksmaskiner'),
(9, 'Små Apparater');

GO

INSERT INTO dbo.[Product] (SubCategoryID, SKU, ProductName, Price, Cost, Color, ProductDetails) VALUES
-- Laptops (SubCategoryID 1)
(1, 'LAP-001', 'Dell XPS 13', 12999.00, 7000.00, 'Silver', '{"processor":"Intel i7","ram":"16GB","storage":"512GB SSD"}'),
(1, 'LAP-002', 'MacBook Pro 14"', 18999.00, 10000.00, 'Space Gray', '{"processor":"M3 Pro","ram":"8GB","storage":"512GB SSD"}'),
(1, 'LAP-003', 'ASUS VivoBook 15', 7499.00, 4000.00, 'Silver', '{"processor":"Ryzen 5","ram":"8GB","storage":"256GB SSD"}'),
(1, 'LAP-004', 'Lenovo ThinkPad X1', 11999.00, 6500.00, 'Black', '{"processor":"Intel i5","ram":"16GB","storage":"256GB SSD"}'),

-- Tablets & iPads (SubCategoryID 2)
(2, 'TAB-001', 'iPad Pro 12.9"', 13999.00, 8000.00, 'Space Gray', '{"processor":"M2","storage":"256GB","screen":"12.9 inch"}'),
(2, 'TAB-002', 'Samsung Galaxy Tab S9', 8999.00, 5000.00, 'Graphite', '{"processor":"Snapdragon 8 Gen 1","storage":"128GB","screen":"11 inch"}'),
(2, 'TAB-003', 'iPad Air', 8499.00, 4800.00, 'Silver', '{"processor":"M1","storage":"64GB","screen":"10.9 inch"}'),

-- Monitorer (SubCategoryID 3)
(3, 'MON-001', '27" 4K Monitor LG', 3499.00, 1800.00, 'Black', '{"resolution":"4K","refreshRate":"60Hz","panel":"IPS"}'),
(3, 'MON-002', '24" FHD Monitor ASUS', 1899.00, 900.00, 'Black', '{"resolution":"1920x1080","refreshRate":"144Hz","panel":"TN"}'),
(3, 'MON-003', '32" Curved Samsung', 4999.00, 2500.00, 'Black', '{"resolution":"2560x1440","refreshRate":"165Hz","panel":"VA"}'),

-- Tangentbord & Möss (SubCategoryID 4)
(4, 'KBD-001', 'Mechanical Gaming Keyboard', 1299.00, 600.00, 'Black', '{"switchType":"Cherry MX","layout":"Full Size","backlight":"RGB"}'),
(4, 'MUS-001', 'Gaming Mouse Razer', 599.00, 250.00, 'Black', '{"dpi":"16000","buttons":"8","weight":"95g"}'),
(4, 'KBD-002', 'Wireless Office Keyboard', 499.00, 200.00, 'White', '{"switchType":"Membrane","layout":"Compact","backlight":"No"}'),

-- Gaming Möss (SubCategoryID 5)
(5, 'GMU-001', 'Lightweight Gaming Mouse', 899.00, 350.00, 'White', '{"dpi":"8000","weight":"65g","buttons":"6"}'),
(5, 'GMU-002', 'SteelSeries Gaming Mouse', 1199.00, 500.00, 'Black', '{"dpi":"18000","weight":"98g","buttons":"8"}'),

-- Gaming Headset (SubCategoryID 6)
(6, 'HDS-001', 'Surround Sound Gaming Headset', 1299.00, 550.00, 'Black', '{"sound":"7.1","microphone":"Removable","impedance":"32 Ohm"}'),
(6, 'HDS-002', 'Wireless Gaming Headset', 1699.00, 700.00, 'Black/Red', '{"sound":"5.1","connection":"2.4GHz Wireless","battery":"30 hours"}'),

-- Rengöring (SubCategoryID 7)
(7, 'CLN-001', 'Datorrengöring Kit', 299.00, 100.00, 'Blue', '{"items":"Brush, Blower, Cloth"}'),

-- Köksutrustning (SubCategoryID 8)
(8, 'KIT-001', 'Blender 2000W', 899.00, 400.00, 'Black', '{"power":"2000W","capacity":"2L"}'),
(8, 'KIT-002', 'Kaffebryggare', 599.00, 250.00, 'Silver', '{"capacity":"12 cups","type":"Drip Coffee"}'),

-- Hårbehandling (SubCategoryID 9)
(9, 'HLB-001', 'Hårföner 2200W', 799.00, 300.00, 'Black', '{"power":"2200W","speed":"3 settings"}'),

-- Televisioner (SubCategoryID 11)
(11, 'TV-001', '65" OLED TV Samsung', 19999.00, 10000.00, 'Black', '{"size":"65 inch","resolution":"4K","technology":"OLED"}'),
(11, 'TV-002', '55" 4K TV LG', 8999.00, 4500.00, 'Black', '{"size":"55 inch","resolution":"4K","technology":"QLED"}'),

-- Högtalare (SubCategoryID 12)
(12, 'SPK-001', 'Bluetooth Högtalare JBL', 699.00, 300.00, 'Black', '{"power":"20W","connection":"Bluetooth 5.0"}'),
(12, 'SPK-002', 'Smart Speaker', 1299.00, 500.00, 'White', '{"ai":"Alexa","power":"40W"}'),

-- Smartphones (SubCategoryID 13)
(13, 'PHN-001', 'iPhone 15 Pro Max', 16999.00, 9000.00, 'Titanium Black', '{"processor":"A17 Pro","storage":"256GB","camera":"12MP"}'),
(13, 'PHN-002', 'Samsung Galaxy S24', 12999.00, 7000.00, 'Phantom Black', '{"processor":"Snapdragon 8 Gen 3","storage":"256GB","camera":"50MP"}'),
(13, 'PHN-003', 'Google Pixel 8', 10999.00, 5800.00, 'Obsidian', '{"processor":"Tensor G3","storage":"128GB","camera":"50MP"}'),

-- Smartwatches (SubCategoryID 14)
(14, 'SMW-001', 'Apple Watch Series 9', 4999.00, 2500.00, 'Silver', '{"screen":"45mm","processor":"S9","battery":"18 hours"}'),
(14, 'SMW-002', 'Samsung Galaxy Watch 6', 3499.00, 1700.00, 'Black', '{"screen":"40mm","processor":"Exynos W920","battery":"40 hours"}'),

-- Köksmaskiner (SubCategoryID 15)
(15, 'APP-001', 'Diskmaskin Siemens', 7999.00, 4000.00, 'Silver', '{"capacity":"14 place settings","energy":"A++"}'),
(15, 'APP-002', 'Tvättmaskin LG', 8999.00, 4500.00, 'White', '{"capacity":"9kg","speed":"1400 rpm","energy":"A+++"}'),

-- Små Apparater (SubCategoryID 16)
(16, 'APP-003', 'Mikrovågsugn', 1299.00, 500.00, 'Black', '{"power":"900W","capacity":"25L"}'),
(16, 'APP-004', 'Brödrost 4-slits', 599.00, 200.00, 'Silver', '{"power":"1800W","slots":"4"}');
GO

INSERT INTO dbo.Customer (FirstName, LastName, Email, Phone) VALUES
('Anders', 'Andersson', 'anders.andersson@netonnet.se', '+46701234567'),
('Birgitta', 'Bergström', 'birgitta.bergstrom@netonnet.se', '+46702345678'),
('Carlos', 'Caridad', 'carlos.caridad@netonnet.se', '+46703456789'),
('Dag', 'Dagvardsson', 'dag.dagvardsson@netonnet.se', '+46704567890'),
('Eva', 'Eriksson', 'eva.eriksson@netonnet.se', '+46705678901'),
('Fredrik', 'Fransson', 'fredrik.fransson@netonnet.se', '+46706789012'),
('Gunnar', 'Gustafsson', 'gunnar.gustafsson@netonnet.se', '+46707890123'),
('Helena', 'Holm', 'helena.holm@netonnet.se', '+46708901234'),
('Isak', 'Isaksson', 'isak.isaksson@netonnet.se', '+46709012345'),
('Johan', 'Johansson', 'johan.johansson@netonnet.se', '+46710123456'),
('Karin', 'Karlsson', 'karin.karlsson@netonnet.se', '+46711234567'),
('Lars', 'Larsson', 'lars.larsson@netonnet.se', '+46712345678'),
('Maria', 'Månsson', 'maria.mansson@netonnet.se', '+46713456789'),
('Nils', 'Nilsson', 'nils.nilsson@netonnet.se', '+46714567890'),
('Olivia', 'Olsson', 'olivia.olsson@netonnet.se', '+46715678901');

GO

INSERT INTO dbo.[Order] (CustomerID, OrderDate, OrderStatus) VALUES
(1, '2024-01-05', 'Levererat'),
(1, '2024-02-12', 'Levererat'),
(2, '2024-01-15', 'Levererat'),
(2, '2024-03-20', 'Avbrutet'),
(3, '2024-02-01', 'Levererat'),
(3, '2024-05-10', 'Returerat'),
(4, '2024-01-22', 'Levererat'),
(4, '2024-04-08', 'Bearbetas'),
(5, '2024-02-28', 'Levererat'),
(5, '2024-06-05', 'Skickat'),
(6, '2024-01-10', 'Levererat'),
(6, '2024-03-15', 'Levererat'),
(7, '2024-02-18', 'Levererat'),
(7, '2024-04-25', 'Väntande'),
(8, '2024-01-30', 'Levererat'),
(8, '2024-05-12', 'Levererat'),
(9, '2024-03-05', 'Levererat'),
(9, '2024-04-18', 'Bearbetas'),
(10, '2024-02-08', 'Levererat'),
(10, '2024-06-01', 'Skickat'),
(11, '2024-01-20', 'Levererat'),
(11, '2024-05-30', 'Levererat'),
(12, '2024-02-25', 'Levererat'),
(12, '2024-04-10', 'Levererat'),
(13, '2024-03-08', 'Levererat'),
(14, '2024-05-20', 'Väntande'),
(15, '2024-04-15', 'Skickat'),
(1, '2024-06-02', 'Bearbetas'),
(2, '2024-03-25', 'Levererat'),
(3, '2024-05-05', 'Returerat');

GO

INSERT INTO dbo.OrderItem (OrderID, ProductID, Quantity, LineTotal, DiscountApplied) VALUES
(1, 1, 1, 12999.00, 0.00),
(1, 4, 1, 499.00, 0.00),
(2, 5, 1, 13999.00, 0.00),
(3, 2, 1, 18999.00, 500.00),
(3, 6, 1, 8999.00, 0.00),
(4, 3, 1, 7499.00, 0.00),
(5, 7, 3, 897.00, 0.00),
(5, 8, 1, 899.00, 0.00),
(6, 9, 1, 3499.00, 0.00),
(6, 10, 1, 1899.00, 0.00),
(7, 11, 1, 1299.00, 100.00),
(7, 12, 1, 699.00, 0.00),
(8, 13, 1, 12999.00, 0.00),
(8, 14, 1, 4999.00, 0.00),
(9, 15, 1, 16999.00, 0.00),
(9, 16, 2, 9998.00, 0.00),
(10, 17, 1, 10999.00, 0.00),
(10, 18, 1, 4999.00, 0.00),
(11, 19, 1, 7999.00, 0.00),
(11, 20, 1, 8999.00, 0.00),
(12, 1, 2, 25998.00, 0.00),
(12, 3, 1, 7499.00, 0.00),
(13, 2, 1, 18999.00, 0.00),
(13, 5, 2, 27998.00, 0.00),
(14, 9, 1, 3499.00, 0.00),
(14, 10, 1, 1899.00, 0.00),
(15, 4, 2, 998.00, 0.00),
(15, 6, 1, 8999.00, 0.00),
(16, 11, 2, 2598.00, 150.00),
(16, 12, 1, 699.00, 0.00),
(17, 13, 1, 12999.00, 0.00),
(17, 14, 2, 9998.00, 0.00),
(18, 3, 1, 7499.00, 0.00),
(18, 7, 2, 1794.00, 0.00),
(19, 1, 1, 12999.00, 0.00),
(19, 17, 1, 10999.00, 0.00),
(20, 8, 1, 899.00, 0.00),
(20, 19, 2, 15998.00, 0.00),
(21, 2, 1, 18999.00, 0.00),
(21, 5, 1, 13999.00, 0.00),
(22, 9, 1, 3499.00, 0.00),
(22, 13, 1, 12999.00, 0.00),
(23, 10, 1, 1899.00, 0.00),
(23, 16, 1, 9998.00, 0.00),
(24, 18, 1, 4999.00, 0.00),
(24, 20, 1, 8999.00, 0.00),
(25, 4, 1, 499.00, 0.00),
(25, 6, 2, 17998.00, 0.00),
(26, 1, 1, 12999.00, 200.00),
(27, 15, 1, 16999.00, 0.00),
(27, 17, 1, 10999.00, 0.00),
(28, 3, 2, 14998.00, 0.00),
(28, 11, 1, 1299.00, 0.00),
(29, 5, 1, 13999.00, 0.00),
(29, 14, 1, 4999.00, 0.00),
(30, 2, 1, 18999.00, 0.00),
(30, 19, 1, 7999.00, 0.00);

GO

INSERT INTO dbo.[Return] (OrderItemID, ReturnDate, Reason, Status, Notes) VALUES
(9, '2024-05-26', 'Defekt', 'Slutförd', 'Enheten hade döda pixlar, ersatt med ny enhet'),
(10, '2024-05-27', 'StämmerInte', 'Godkänd', 'Kund beställde fel modell, initierad byte'),
(23, '2024-04-20', 'Skadad', 'Slutförd', 'Produkten var skadad vid ankomst'),
(31, '2024-05-25', 'KundRequest', 'Slutförd', 'Kund ändrade sig om köpet'),
(40, '2024-06-08', 'StämmerInte', 'Initierad', 'Kund begärde retur, väntar på inspektion');

GO

