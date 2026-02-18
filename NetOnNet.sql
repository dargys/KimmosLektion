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
    Color           NVARCHAR (20)
    CreatedAt       DATE NOT NULL,
    ProductDetails  JSON,
    FOREIGN KEY (SubCategoryID) REFERENCES dbo.SubCategory(SubCategoryID),
    CONSTRAINT CK_ProductPrice CHECK (Price >= 0)
    CONSTRAINT CK_ProductCost CHECK (Cost >= 0)
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

INSERT INTO dbo.[Product] (SubCategoryID, SKU, ProductName, Price, Cost, CreatedAt) VALUES
-- Dator & Surfplatta - SubCategoryID 1 (Laptops)
(1, 'DELL-XPS-13-2024', 'Dell XPS 13 (2024)', 12999.00, 7800.00, '2024-01-15'),
(1, 'HP-PAVILION-15-2024', 'HP Pavilion 15 (2024)', 8499.00, 5100.00, '2024-01-20'),
(1, 'ASUS-VIVOBOOK-15', 'ASUS VivoBook 15 (2024)', 7999.00, 4800.00, '2024-02-10'),

-- Dator & Surfplatta - SubCategoryID 2 (Tablets & iPads)
(2, 'IPAD-AIR-2024', 'iPad Air (2024)', 6999.00, 4200.00, '2024-03-01'),

-- Datorkomponenter - SubCategoryID 3 (Monitorer)
(3, 'SAMSUNG-27-4K', 'Samsung 27" 4K Monitor', 3499.00, 2100.00, '2024-01-05'),

-- Datorkomponenter - SubCategoryID 4 (Tangentbord & Möss)
(4, 'CORSAIR-K95-PLAT', 'Corsair K95 Platinum Keyboard', 1999.00, 1200.00, '2024-02-15'),
-- Tillbehör - SubCategoryID 4 (Tangentbord & Möss - reusing for cables)
(4, 'ANKER-USB-C-CABLE', 'Anker USB-C Cable 3m (100W)', 199.00, 120.00, '2024-03-08'),
(4, 'HDMI-2.1-CABLE-2M', 'HDMI 2.1 Cable 2m', 149.00, 90.00, '2024-03-12'),

-- Gaming - SubCategoryID 5 (Gaming Möss)
(5, 'CORSAIR-M65-ELITE', 'Corsair M65 Elite Mouse', 799.00, 480.00, '2024-01-10'),

-- Gaming - SubCategoryID 6 (Gaming Headset)
(6, 'STEELSERIES-ARCTIS-7X', 'SteelSeries Arctis 7X Headset', 1299.00, 780.00, '2024-02-20'),

-- Hem & Fritid - SubCategoryID 7 (Rengöring)
(7, 'DYSON-V15-DETECT', 'Dyson V15 Detect Vacuum', 6999.00, 4200.00, '2024-01-25'),

-- Hem & Fritid - SubCategoryID 8 (Köksutrustning)
(8, 'NESPRESSO-VERTUO', 'Nespresso Vertuo Coffee Maker', 2499.00, 1500.00, '2024-03-10'),

-- Personvård - SubCategoryID 9 (Hårbehandling)
(9, 'DYSON-SUPERSONIC', 'Dyson Supersonic Hair Dryer', 3499.00, 2100.00, '2024-02-01'),

-- TV - SubCategoryID 10 (Televisioner)
(10, 'SAMSUNG-55-QLED', 'Samsung 55" QLED TV', 7999.00, 4800.00, '2024-01-30'),
-- Kamera & Foto - SubCategoryID 10 (Televisioner - reusing for camera)
(10, 'CANON-EOS-R5', 'Canon EOS R5 Camera', 24999.00, 15000.00, '2024-01-12'),

-- Ljud - SubCategoryID 11 (Högtalare)
(11, 'BOSE-SOUNDLINK-MAX', 'Bose SoundLink Max Speaker', 2299.00, 1380.00, '2024-02-05'),

-- Mobil & Smartwatch - SubCategoryID 12 (Smartphones)
(12, 'IPHONE-15-PRO-MAX', 'iPhone 15 Pro Max (256GB)', 13999.00, 8400.00, '2024-03-15'),

-- Mobil & Smartwatch - SubCategoryID 13 (Smartwatches)
(13, 'APPLE-WATCH-ULTRA', 'Apple Watch Ultra', 4999.00, 3000.00, '2024-03-20'),

-- Vitvaror - SubCategoryID 14 (Köksmaskiner)
(14, 'PHILIPS-HR3752', 'Philips HR3752 Blender', 899.00, 540.00, '2024-02-25'),

-- Vitvaror - SubCategoryID 15 (Små Apparater)
(15, 'LG-NEOCHEF-MICRO', 'LG NeoChef Microwave', 1999.00, 1200.00, '2024-03-05');

GO

INSERT INTO dbo.ProductAttribute (ProductID, AttributeName, AttributeValue) VALUES
(1, 'Processor', 'Intel Core i7-1365U'),
(1, 'RAM-minne', '16 GB LPDDR5'),
(1, 'Lagring', '512 GB NVMe SSD'),
(1, 'Skärmstorlek', '13.3" FHD'),
(1, 'Vikt', '1.2 kg'),
(1, 'Färg', 'Silver'),
(1, 'Batteritid', '12 timmar'),
(2, 'Processor', 'Apple M3 Max'),
(2, 'RAM-minne', '18 GB'),
(2, 'Lagring', '512 GB SSD'),
(2, 'Skärmstorlek', '14.2" Liquid Retina XDR'),
(2, 'Vikt', '1.6 kg'),
(2, 'Färg', 'Rymdsvart'),
(2, 'Batteritid', '18 timmar'),
(3, 'Processor', 'AMD Ryzen 7 5700U'),
(3, 'RAM-minne', '8 GB DDR4'),
(3, 'Lagring', '256 GB SSD'),
(3, 'Skärmstorlek', '15.6" IPS'),
(3, 'Vikt', '1.8 kg'),
(3, 'Färg', 'Silver'),
(3, 'Batteritid', '8 timmar'),
(4, 'Processor', 'Apple M1 Max'),
(4, 'RAM-minne', '32 GB'),
(4, 'Lagring', '512 GB SSD'),
(4, 'GPU', 'Integrated 32-core GPU'),
(4, 'Skärmstorlek', '27" 5K Retina'),
(4, 'Färg', 'Silver'),
(4, 'Effekt', '370 W'),
(5, 'Processor', 'Intel Core i9-11900K'),
(5, 'RAM-minne', '64 GB DDR4'),
(5, 'Lagring', '1 TB NVMe SSD'),
(5, 'GPU', 'NVIDIA RTX 3090'),
(5, 'Formfaktor', 'Tower'),
(5, 'Färg', 'Svart'),
(5, 'Effekt', '650 W'),
(6, 'Processor', 'AMD Ryzen 9 5900X'),
(6, 'RAM-minne', '32 GB DDR4'),
(6, 'Lagring', '512 GB SSD'),
(6, 'GPU', 'NVIDIA GTX 1660'),
(6, 'Formfaktor', 'Tower'),
(6, 'Färg', 'Vit'),
(6, 'Effekt', '500 W'),
(7, 'Storlek', '27"'),
(7, 'Upplösning', '4K (3840x2160)'),
(7, 'Paneltyp', 'VA'),
(7, 'Uppfriskningsfrekvens', '60 Hz'),
(7, 'Anslutning', 'HDMI, DisplayPort, USB-C'),
(7, 'Färg', 'Svart'),
(7, 'Stativ', 'Höjdjusterbar'),
(8, 'Storlek', '34"'),
(8, 'Upplösning', '3440x1440'),
(8, 'Paneltyp', 'IPS'),
(8, 'Uppfriskningsfrekvens', '100 Hz'),
(8, 'Anslutning', 'HDMI, DisplayPort'),
(8, 'Färg', 'Svart'),
(8, 'Stativ', 'Lutningsbar'),
(9, 'Storlek', '27"'),
(9, 'Upplösning', '2560x1440'),
(9, 'Paneltyp', 'TN'),
(9, 'Uppfriskningsfrekvens', '240 Hz'),
(9, 'Anslutning', 'HDMI, DisplayPort'),
(9, 'Färg', 'Svart'),
(9, 'Stativ', 'Fullt justerbar'),
(10, 'Storlek', '24"'),
(10, 'Upplösning', '1920x1200'),
(10, 'Paneltyp', 'IPS'),
(10, 'Uppfriskningsfrekvens', '60 Hz'),
(10, 'Anslutning', 'HDMI, USB-C'),
(10, 'Färg', 'Vit'),
(10, 'Stativ', 'Justerbar'),
(11, 'Typ', 'Mekanisk'),
(11, 'Anslutning', 'USB-C'),
(11, 'Layout', 'QWERTY'),
(11, 'Färg', 'Svart'),
(11, 'Tangenttal', '104'),
(11, 'Material', 'Aluminium'),
(12, 'Typ', 'Trådlös'),
(12, 'Anslutning', 'Bluetooth / 2.4 GHz Unifying'),
(12, 'Färg', 'Grafit'),
(12, 'DPI', 'Upp till 8000'),
(12, 'Batteritid', '70 dagar'),
(12, 'Vikt', '141 g'),
(13, 'Typ', 'Mekanisk'),
(13, 'Anslutning', '2.4 GHz Trådlös'),
(13, 'Layout', 'Kompakt'),
(13, 'Färg', 'Svart'),
(13, 'Tangenttal', '61'),
(13, 'Material', 'Plast'),
(14, 'Typ', 'Over-ear'),
(14, 'Anslutning', 'Bluetooth 5.3'),
(14, 'Färg', 'Svart'),
(14, 'Bullerdämpning', 'Aktiv (ANC)'),
(14, 'Batteritid', '8 timmar'),
(14, 'Vikt', '250 g'),
(15, 'Typ', 'Over-ear'),
(15, 'Anslutning', 'Bluetooth 5.3'),
(15, 'Färg', 'Svart'),
(15, 'Bullerdämpning', 'Passiv'),
(15, 'Batteritid', '60 timmar'),
(15, 'Vikt', '350 g'),
(16, 'Typ', 'Dynamisk'),
(16, 'Anslutning', 'XLR'),
(16, 'Färg', 'Svart'),
(16, 'Frekvensomfattning', '50 Hz - 20 kHz'),
(16, 'Impedans', '310 Ohm'),
(16, 'Vikt', '310 g'),
(17, 'Typ', 'Side-by-side'),
(17, 'Kapacitet', '488 L'),
(17, 'Effekt', '800 W'),
(17, 'Energiklass', 'A+++'),
(17, 'Färg', 'Rostfritt stål'),
(17, 'Höjd', '178 cm'),
(18, 'Typ', 'Frontmatad'),
(18, 'Kapacitet', '5.8 kg'),
(18, 'Effekt', '2200 W'),
(18, 'Energiklass', 'A+++'),
(18, 'Färg', 'Vit'),
(18, 'Snurrfrekvens', '1400 rpm'),
(19, 'Typ', 'Helintegrerad'),
(19, 'Kapacitet', '14 kuvert'),
(19, 'Effekt', '1700 W'),
(19, 'Energiklass', 'A+++'),
(19, 'Färg', 'Vit'),
(19, 'Bullernivå', '42 dB'),
(20, 'Typ', 'Induktion'),
(20, 'Antal plattor', '4'),
(20, 'Effekt', '7400 W'),
(20, 'Energiklass', 'A'),
(20, 'Färg', 'Svart'),
(20, 'Storlek', '59 cm');

GO

INSERT INTO dbo.Customer (FirstName, LastName, Email, Phone, [Address]) VALUES
('Anders', 'Svensson', 'anders.svensson@email.com', '+46701234567', 'Stockholm'),
('Maria', 'Andersson', 'maria.andersson@email.com', '+46702345678', 'Gothenburg'),
('Kristofer', 'Gustafsson', 'kristofer.g@email.com', '+46703456789', 'Malmö'),
('Petra', 'Larsson', 'petra.larsson@email.com', '+46704567890', 'Uppsala'),
('Erik', 'Bergström', 'erik.bergstrom@email.com', '+46705678901', 'Linköping'),
('Ole', 'Johansen', 'ole.johansen@email.no', '+4798765432', 'Oslo'),
('Ingrid', 'Hansen', 'ingrid.hansen@email.no', '+4798765433', 'Bergen'),
('Bjørn', 'Nilsen', 'bjorn.nilsen@email.no', '+4798765434', 'Trondheim'),
('Siril', 'Eriksen', 'siril.eriksen@email.no', '+4798765435', 'Stavanger'),
('Torsten', 'Pettersen', 'torsten.p@email.no', '+4798765436', 'Drammen');

GO

INSERT INTO dbo.[Order] (CustomerID, OrderDate, OrderStatus) VALUES
(1, '2023-01-05', 'Delivered'),
(2, '2023-01-18', 'Delivered'),
(3, '2023-02-03', 'Delivered'),
(4, '2023-02-14', 'Delivered'),
(5, '2023-03-01', 'Delivered'),
(6, '2023-03-10', 'Shipped'),
(7, '2023-03-22', 'Confirmed'),
(8, '2023-03-28', 'Delivered'),
(1, '2023-04-12', 'Delivered'),
(9, '2023-04-25', 'Shipped'),
(10, '2023-05-08', 'Delivered'),
(2, '2023-05-19', 'Delivered'),
(3, '2023-06-02', 'Delivered'),
(4, '2023-06-15', 'Confirmed'),
(5, '2023-06-30', 'Delivered'),
(6, '2023-07-05', 'Delivered'),
(7, '2023-07-12', 'Shipped'),
(8, '2023-07-28', 'Delivered'),
(1, '2023-08-03', 'Delivered'),
(2, '2023-08-17', 'Confirmed'),
(9, '2023-09-01', 'Delivered'),
(10, '2023-09-14', 'Shipped'),
(3, '2023-09-22', 'Delivered'),
(4, '2023-09-26', 'Confirmed'),
(5, '2023-09-30', 'Delivered'),
(6, '2023-10-02', 'Delivered'),
(7, '2023-10-15', 'Shipped'),
(8, '2023-10-28', 'Delivered'),
(1, '2023-11-05', 'Shipped'),
(2, '2023-11-11', 'Confirmed'),
(3, '2023-11-20', 'Delivered'),
(4, '2023-11-25', 'Delivered'),
(9, '2023-12-01', 'Shipped'),
(10, '2023-12-08', 'Confirmed'),
(5, '2023-12-15', 'Delivered'),
(6, '2023-12-20', 'Shipped'),
(7, '2023-12-28', 'Pending'),
(8, '2024-01-08', 'Delivered'),
(1, '2024-01-22', 'Delivered'),
(2, '2024-02-05', 'Shipped'),
(3, '2024-02-18', 'Delivered'),
(4, '2024-03-03', 'Confirmed'),
(9, '2024-03-15', 'Delivered'),
(10, '2024-03-29', 'Shipped'),
(5, '2024-04-07', 'Delivered'),
(6, '2024-04-20', 'Confirmed'),
(7, '2024-05-12', 'Shipped'),
(8, '2024-05-28', 'Delivered'),
(1, '2024-06-10', 'Delivered'),
(2, '2024-06-25', 'Confirmed');

GO

INSERT INTO dbo.OrderItem (OrderID, ProductID, Quantity, LineTotal, DiscountApplied) VALUES
(1, 2, 1, 24999, 0.00),
(2, 7, 1, 3499, 0.00),
(3, 1, 1, 12999, 100.00),
(3, 11, 1, 1299, 0.00),
(4, 15, 1, 2299, 0.00),
(5, 17, 1, 8999, 500.00),
(6, 9, 1, 4799, 0.00),
(7, 13, 1, 899, 0.00),
(8, 20, 1, 12999, 0.00),
(10, 3, 1, 7499, 0.00),
(11, 4, 1, 22999, 0.00),
(12, 8, 1, 11999, 1000.00),
(12, 12, 1, 3999, 0.00),
(13, 2, 1, 24999, 500.00),
(14, 10, 1, 1999, 0.00),
(15, 19, 1, 5999, 0.00),
(16, 14, 1, 3599, 0.00),
(17, 5, 1, 18999, 1500.00),
(17, 11, 1, 1299, 0.00),
(18, 7, 2, 6998, 0.00),
(19, 16, 1, 2899, 0.00),
(20, 18, 1, 6999, 0.00),
(20, 9, 1, 4799, 200.00),
(21, 1, 1, 12999, 0.00),
(22, 3, 1, 7499, 250.00),
(23, 6, 1, 16999, 0.00),
(23, 15, 1, 2299, 0.00),
(24, 8, 1, 11999, 0.00),
(25, 12, 2, 7998, 0.00),
(26, 4, 1, 22999, 1000.00),
(27, 9, 1, 4799, 0.00),
(28, 17, 1, 8999, 0.00),
(29, 20, 1, 12999, 500.00),
(29, 14, 1, 3599, 0.00),
(30, 2, 1, 24999, 0.00),
(30, 10, 1, 1999, 0.00),
(31, 5, 1, 18999, 500.00),
(32, 13, 1, 899, 0.00),
(33, 7, 1, 3499, 100.00),
(34, 1, 2, 25998, 0.00),
(35, 11, 3, 3897, 0.00),
(36, 19, 1, 5999, 0.00),
(37, 3, 1, 7499, 0.00),
(37, 12, 1, 3999, 0.00),
(38, 16, 1, 2899, 0.00),
(39, 18, 1, 6999, 300.00),
(40, 8, 1, 11999, 0.00),
(40, 14, 1, 3599, 0.00),
(40, 13, 1, 899, 0.00),
(41, 4, 1, 22999, 1000.00),
(42, 2, 1, 24999, 0.00),
(43, 6, 1, 16999, 500.00),
(44, 9, 2, 9598, 0.00),
(45, 20, 1, 12999, 0.00),
(46, 17, 1, 8999, 0.00),
(47, 15, 1, 2299, 0.00),
(48, 10, 1, 1999, 0.00),
(48, 13, 2, 1798, 0.00),
(49, 7, 1, 3499, 0.00),
(49, 16, 1, 2899, 0.00),
(50, 19, 1, 5999, 0.00),
(50, 14, 1, 3599, 0.00);

GO

INSERT INTO dbo.[Return] (OrderItemID, ReturnDate, Reason, Status, Notes) VALUES
(3, '2023-02-10', 'Defekt produkt', 'Approved', 'Datorn startade inte. Ersatt med ny enhet.'),
(2, '2023-02-08', 'Fel modell', 'Processed', 'Kund ville ha 32" istället för 27". Bytte genomförd.'),
(9, '2023-10-30', 'Skadad vid leverans', 'Approved', 'Tangentbord var bruten vid mottagandet. Ny skickades.'),
(12, '2023-12-01', 'Inte som förväntat', 'Pending', 'Ljudkvaliteten var inte som förväntat. Under granskning.');

GO



