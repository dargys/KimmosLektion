IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'NetOnNet')
  BEGIN
    CREATE DATABASE NetOnNet
    END;
GO

USE NetOnNet;
GO


-- DELETE FROM dbo.[OrderItem];
-- DBCC CHECKIDENT ('dbo.[OrderItem]', RESEED, 0);

IF OBJECT_ID ('dbo.Category','U') IS NULL
BEGIN
CREATE TABLE Category(
    CategoryID      INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    CategoryName    NVARCHAR(50) UNIQUE NOT NULL
)
END;
GO

IF OBJECT_ID('dbo.SubCategory','U') IS NULL
BEGIN
CREATE TABLE dbo.SubCategory (
    SubCategoryID   INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    CategoryID      INT NOT NULL,
    SubCategoryName NVARCHAR(50) UNIQUE NOT NULL,
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
    UnitPrice       DECIMAL(10, 2) NOT NULL,
    PurchasePrice   DECIMAL(10, 2) NOT NULL,
    Color           NVARCHAR (20) NULL,
    CreatedDate     DATETIME2(0) NOT NULL,
    ProductDetails  NVARCHAR(MAX) NULL,
    FOREIGN KEY (SubCategoryID) REFERENCES dbo.SubCategory(SubCategoryID),
    CONSTRAINT CK_ProductPrice CHECK (UnitPrice >= 0),
    CONSTRAINT CK_PurchasePrice CHECK (PurchasePrice >= 0),
    CONSTRAINT CK_ProductDetails_JSON CHECK (ProductDetails IS NULL OR ISJSON(ProductDetails) = 1)

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
    Phone       VARCHAR(20) NULL
)
END;
GO

IF OBJECT_ID('dbo.Payment','U') IS NULL
BEGIN
CREATE TABLE dbo.Payment (
    PaymentID       INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    MethodName      NVARCHAR (15) NOT NULL,
    ProviderName    NVARCHAR (15) NOT NULL,
    IsApproved      BIT NOT NULL,
    CreatedDate     DATETIME NOT NULL,
    CONSTRAINT CK_ValidCombination CHECK (
    (MethodName = 'Kort' AND ProviderName IN ('Visa','Mastercard')) OR
    (MethodName = 'Faktura' AND ProviderName = 'Klarna') OR
    (MethodName = 'Swish' AND ProviderName = 'Swish') OR
    (MethodName = 'Paypal' AND ProviderName = 'Paypal') OR
    (MethodName = 'Avbetalning' AND ProviderName = 'Klarna')
)
)
END;
GO



IF OBJECT_ID('dbo.Order','U') IS NULL
BEGIN
CREATE TABLE dbo.[Order] (
    OrderID         INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    PaymentID       INT NOT NULL,
    CustomerID      INT NOT NULL,
    OrderDate       DATETIME NOT NULL,
    OrderStatus     NVARCHAR(20) NOT NULL,
    OrderTotalAmount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES dbo.Customer(CustomerID),
    FOREIGN KEY (PaymentID) REFERENCES dbo.Payment (PaymentID),
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
    LineTotal       DECIMAL(10, 2) NOT NULL,
    DiscountApplied DECIMAL(10, 2),
    FOREIGN KEY (OrderID) REFERENCES dbo.[Order](OrderID),
    FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID),
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
    [Status]    NVARCHAR(20) NOT NULL,
    ReturnedAmount DECIMAL (10,2) NULL,
    Notes       NVARCHAR(MAX) NULL,
    FOREIGN KEY (OrderItemID) REFERENCES dbo.OrderItem(OrderItemID),
    CONSTRAINT CK_ReturnReason CHECK (Reason IN ('Defekt', 'StämmerInte', 'Skadad', 'KundRequest', 'Övrigt')),
    CONSTRAINT CK_ReturnStatus CHECK ([Status] IN ('Initierad', 'Godkänd', 'Avvisad', 'Slutförd'))
)
END;
GO




USE NetOnNet
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

INSERT INTO dbo.SubCategory (CategoryID, SubCategoryName) VALUES
-- Dator & Surfplatta (CategoryID 1) - 4 subcategories
(1, 'Laptops'),
(1, 'Tablets'),
(1, 'Ultrabooks'),
(1, '2-in-1 Devices'),

-- Datorkomponenter (CategoryID 2) - 5 subcategories
(2, 'CPUs'),
(2, 'GPUs'),
(2, 'RAM Memory'),
(2, 'SSDs'),
(2, 'Power Supplies'),

-- Gaming (CategoryID 3) - 4 subcategories
(3, 'Consoles'),
(3, 'Gaming Monitors'),
(3, 'Gaming Keyboards'),
(3, 'Gaming Mice'),

-- Hem & Fritid (CategoryID 4) - 4 subcategories
(4, 'Smart Home'),
(4, 'Sports Equipment'),
(4, 'Furniture'),
(4, 'Lighting'),

-- Personvård (CategoryID 5) - 3 subcategories
(5, 'Hair Care'),
(5, 'Skincare'),
(5, 'Health Devices'),

-- TV (CategoryID 6) - 3 subcategories
(6, 'OLED TV'),
(6, 'LED TV'),
(6, 'Smart TV'),

-- Ljud (CategoryID 7) - 3 subcategories
(7, 'Speakers'),
(7, 'Headphones'),
(7, 'Microphones'),

-- Mobil & Smartwatch (CategoryID 8) - 4 subcategories (CORRECTED - No duplicate Tablets)
(8, 'Smartphones'),
(8, 'Smartwatch Accessories'),
(8, 'Smartwatches'),
(8, 'Mobile Cases'),

-- Vitvaror (CategoryID 9) - 3 subcategories
(9, 'Washing Machines'),
(9, 'Dryers'),
(9, 'Refrigerators'),

-- Kamera & Foto (CategoryID 10) - 3 subcategories
(10, 'DSLR Cameras'),
(10, 'Mirrorless Cameras'),
(10, 'Lenses'),

-- Tillbehör (CategoryID 11) - 5 subcategories
(11, 'Phone Cases'),
(11, 'Cables'),
(11, 'Chargers'),
(11, 'Adapters'),
(11, 'Screen Protectors');


INSERT INTO dbo.[Product] (SubCategoryID, SKU, ProductName, UnitPrice, PurchasePrice, Color, CreatedDate, ProductDetails) VALUES
(1, 'DATOR-001', 'Dell XPS 13 Plus', 12999.00, 7800.00, 'Silver', '2023-09-01 10:00:00', '{"brand": "Dell", "model": "XPS 13 Plus", "warrantyYears": 2, "specifications": {"processor": "Intel Core i7-1365U", "ram": "16GB LPDDR5", "storage": "512GB NVMe SSD", "display": "13.4-inch OLED 2880x1920"}}'),
(1, 'DATOR-002', 'HP Pavilion 15', 8999.00, 5400.00, 'Charcoal', '2023-09-01 10:00:00', '{"brand": "HP", "model": "Pavilion 15-eh1000", "warrantyYears": 1, "specifications": {"processor": "AMD Ryzen 5 7520U", "ram": "8GB DDR5", "storage": "256GB SSD", "display": "15.6-inch FHD 1920x1080"}}'),
(1, 'DATOR-003', 'Lenovo ThinkPad X1 Carbon', 14999.00, 9000.00, 'Black', '2023-09-01 10:00:00', '{"brand": "Lenovo", "model": "ThinkPad X1 Carbon Gen 11", "warrantyYears": 3, "specifications": {"processor": "Intel Core i7-1365U", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "14-inch OLED 2880x1880"}}'),
(2, 'DATOR-004', 'Apple iPad Air 5', 8999.00, 5400.00, 'Space Gray', '2023-09-03 10:00:00', '{"brand": "Apple", "model": "iPad Air 5", "warrantyYears": 1, "specifications": {"processor": "Apple M1", "ram": "8GB", "storage": "256GB", "display": "10.9-inch Liquid Retina 2360x1640"}}'),
(2, 'DATOR-005', 'Samsung Galaxy Tab S8 Ultra', 9999.00, 6000.00, 'Gray', '2023-09-03 10:00:00', '{"brand": "Samsung", "model": "Galaxy Tab S8 Ultra", "warrantyYears": 1, "specifications": {"processor": "Snapdragon 8 Gen 1", "ram": "12GB", "storage": "256GB", "display": "14.6-inch AMOLED 2960x1848"}}'),
(2, 'DATOR-006', 'Apple iPad Pro 12.9', 14999.00, 9000.00, 'Silver', '2023-09-03 10:00:00', '{"brand": "Apple", "model": "iPad Pro 12.9-inch M2", "warrantyYears": 1, "specifications": {"processor": "Apple M2", "ram": "8GB", "storage": "256GB", "display": "12.9-inch Liquid Retina XDR 2732x2048"}}'),
(3, 'DATOR-007', 'MacBook Air M2', 15999.00, 9600.00, 'Space Gray', '2023-09-05 10:00:00', '{"brand": "Apple", "model": "MacBook Air M2", "warrantyYears": 1, "specifications": {"processor": "Apple M2", "ram": "16GB Unified Memory", "storage": "512GB SSD", "display": "13.6-inch Liquid Retina 2560x1600"}}'),
(3, 'DATOR-008', 'Microsoft Surface Laptop 5', 13499.00, 8100.00, 'Platinum', '2023-09-05 10:00:00', '{"brand": "Microsoft", "model": "Surface Laptop 5", "warrantyYears": 2, "specifications": {"processor": "Intel Core i7-1285U", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "13.5-inch PixelSense 2256x1504"}}'),
(3, 'DATOR-009', 'ASUS ZenBook 14', 9999.00, 6000.00, 'Icy Silver', '2023-09-05 10:00:00', '{"brand": "ASUS", "model": "ZenBook 14 OLED", "warrantyYears": 2, "specifications": {"processor": "Intel Core i7-1360P", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "14-inch OLED 2880x1800"}}'),
(4, 'DATOR-010', 'Microsoft Surface Pro 9', 11999.00, 7200.00, 'Platinum', '2023-09-07 10:00:00', '{"brand": "Microsoft", "model": "Surface Pro 9", "warrantyYears": 1, "specifications": {"processor": "Intel Core i7-1255U", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "13-inch PixelSense 2880x1920"}}'),
(4, 'DATOR-011', 'Lenovo Yoga 9i', 10999.00, 6600.00, 'Oatmeal', '2023-09-07 10:00:00', '{"brand": "Lenovo", "model": "Yoga 9i Gen 7", "warrantyYears": 2, "specifications": {"processor": "Intel Core i7-1360P", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "14-inch IPS touchscreen 2240x1400"}}'),
(5, 'COMP-001', 'Intel Core i7-13700K', 4999.00, 3000.00, NULL, '2023-09-09 10:00:00', '{"brand": "Intel", "model": "Core i7-13700K", "warrantyYears": 3, "specifications": {"cores": "16 cores (8P+8E)", "frequency": "3.4-5.4 GHz", "tdp": "125W", "socket": "LGA1700"}}'),
(5, 'COMP-002', 'AMD Ryzen 7 7700X', 4499.00, 2700.00, NULL, '2023-09-09 10:00:00', '{"brand": "AMD", "model": "Ryzen 7 7700X", "warrantyYears": 3, "specifications": {"cores": "8 cores", "frequency": "4.5-5.4 GHz", "tdp": "105W", "socket": "AM5"}}'),
(6, 'COMP-003', 'NVIDIA RTX 4080', 12999.00, 7800.00, NULL, '2023-09-11 10:00:00', '{"brand": "NVIDIA", "model": "GeForce RTX 4080", "warrantyYears": 2, "specifications": {"memory": "16GB GDDR6X", "cuda_cores": "9728", "memory_bandwidth": "576 GB/s", "power_consumption": "320W"}}'),
(6, 'COMP-004', 'AMD RX 7900 XTX', 11999.00, 7200.00, NULL, '2023-09-11 10:00:00', '{"brand": "AMD", "model": "Radeon RX 7900 XTX", "warrantyYears": 2, "specifications": {"memory": "24GB GDDR6", "stream_processors": "6144", "memory_bandwidth": "576 GB/s", "power_consumption": "420W"}}'),
(7, 'COMP-005', 'Corsair Vengeance DDR5 32GB', 2499.00, 1500.00, NULL, '2023-09-13 10:00:00', '{"brand": "Corsair", "model": "Vengeance DDR5", "warrantyYears": 1, "specifications": {"capacity": "32GB (2x16GB)", "speed": "5600MHz", "cas_latency": "CL36", "voltage": "1.25V"}}'),
(7, 'COMP-006', 'G.Skill Trident Z5 64GB', 4999.00, 3000.00, NULL, '2023-09-13 10:00:00', '{"brand": "G.Skill", "model": "Trident Z5", "warrantyYears": 1, "specifications": {"capacity": "64GB (2x32GB)", "speed": "6000MHz", "cas_latency": "CL30", "voltage": "1.4V"}}'),
(10, 'GAME-001', 'PlayStation 5', 5999.00, 3600.00, 'White', '2023-09-19 10:00:00', '{"brand": "Sony", "model": "PlayStation 5", "warrantyYears": 2, "specifications": {"processor": "AMD Zen 2 8-core 3.5 GHz", "memory": "16GB GDDR6", "storage": "825GB SSD", "resolution": "Up to 4K 120fps"}}'),
(10, 'GAME-002', 'Xbox Series X', 5499.00, 3300.00, 'Black', '2023-09-19 10:00:00', '{"brand": "Microsoft", "model": "Xbox Series X", "warrantyYears": 2, "specifications": {"processor": "AMD Zen 2 8-core 3.8 GHz", "memory": "16GB GDDR6", "storage": "1TB SSD", "resolution": "Up to 4K 120fps"}}'),
(10, 'GAME-003', 'Nintendo Switch OLED', 3999.00, 2400.00, 'White', '2023-09-19 10:00:00', '{"brand": "Nintendo", "model": "Switch OLED Model", "warrantyYears": 1, "specifications": {"processor": "NVIDIA Tegra X1", "memory": "4GB LPDDR4", "storage": "64GB", "display": "7-inch OLED 1280x720"}}'),
(11, 'GAME-004', 'ASUS ROG Swift PG279QM', 4999.00, 3000.00, 'Black', '2023-09-21 10:00:00', '{"brand": "ASUS", "model": "ROG Swift PG279QM", "warrantyYears": 2, "specifications": {"size": "27 inch", "resolution": "2560x1440 QHD", "refresh_rate": "240Hz", "response_time": "1ms GTG"}}'),
(11, 'GAME-005', 'LG UltraGear 32GN750', 5999.00, 3600.00, 'Black', '2023-09-21 10:00:00', '{"brand": "LG", "model": "UltraGear 32GN750-B", "warrantyYears": 2, "specifications": {"size": "32 inch", "resolution": "2560x1440 QHD", "refresh_rate": "240Hz", "response_time": "1ms GTG"}}'),
(12, 'GAME-006', 'Corsair K95 Platinum XT', 1999.00, 1200.00, 'Black', '2023-09-23 10:00:00', '{"brand": "Corsair", "model": "K95 Platinum XT", "warrantyYears": 2, "specifications": {"switches": "Cherry MX Red", "layout": "Full Size 104-key", "backlighting": "RGB per-key", "connection": "Wired USB"}}'),
(12, 'GAME-007', 'Razer BlackWidow V4', 1699.00, 1020.00, 'Black', '2023-09-23 10:00:00', '{"brand": "Razer", "model": "BlackWidow V4", "warrantyYears": 2, "specifications": {"switches": "Razer Green", "layout": "Full Size 104-key", "backlighting": "RGB per-key", "connection": "Wired USB"}}'),
(13, 'GAME-008', 'Logitech G Pro X Superlight 2', 999.00, 600.00, 'Black', '2023-09-25 10:00:00', '{"brand": "Logitech", "model": "G Pro X Superlight 2", "warrantyYears": 2, "specifications": {"sensor": "HERO 25K", "dpi": "25600", "weight": "63g", "connectivity": "Wireless 2.4GHz"}}'),
(13, 'GAME-009', 'Razer DeathAdder V3', 899.00, 540.00, 'Black', '2023-09-25 10:00:00', '{"brand": "Razer", "model": "DeathAdder V3", "warrantyYears": 2, "specifications": {"sensor": "Focus Pro 30K", "dpi": "30000", "weight": "63g", "connectivity": "Wired USB"}}'),
(13, 'GAME-010', 'SteelSeries Rival 5', 799.00, 480.00, 'Black', '2023-09-25 10:00:00', '{"brand": "SteelSeries", "model": "Rival 5", "warrantyYears": 1, "specifications": {"sensor": "TrueMove Core", "dpi": "18000", "weight": "78g", "connectivity": "Wired USB"}}'),
(14, 'HOME-001', 'Google Nest Hub Max', 2499.00, 1500.00, 'Charcoal', '2023-09-27 10:00:00', '{"brand": "Google", "model": "Nest Hub Max", "warrantyYears": 1, "specifications": {"display": "10 inch touchscreen", "resolution": "2200x1600", "connectivity": "WiFi 5 802.11ac", "assistant": "Google Assistant"}}'),
(14, 'HOME-002', 'Amazon Echo Show 15', 1999.00, 1200.00, 'Black', '2023-09-27 10:00:00', '{"brand": "Amazon", "model": "Echo Show 15", "warrantyYears": 1, "specifications": {"display": "15.6 inch touchscreen", "resolution": "1920x1080", "connectivity": "WiFi 6 802.11ax", "assistant": "Alexa"}}'),
(15, 'HOME-003', 'Fitbit Charge 5', 1499.00, 900.00, 'Black', '2023-09-29 10:00:00', '{"brand": "Fitbit", "model": "Charge 5", "warrantyYears": 1, "specifications": {"display": "AMOLED touchscreen", "battery": "7 days", "water_resistance": "50m", "sensors": "heart rate, SpO2, EDA"}}'),
(15, 'HOME-004', 'Apple Watch Series 8', 3999.00, 2400.00, 'Silver', '2023-09-29 10:00:00', '{"brand": "Apple", "model": "Watch Series 8 45mm", "warrantyYears": 1, "specifications": {"display": "Retina LTPO OLED", "battery": "18 hours", "water_resistance": "50m", "sensors": "ECG, temperature, blood oxygen"}}'),
(16, 'HOME-005', 'IKEA LINNMON Desk', 999.00, 600.00, NULL, '2023-10-01 10:00:00', '{"brand": "IKEA", "model": "LINNMON", "warrantyYears": 1, "specifications": {"material": "particle board veneer", "size": "140x60 cm", "height_adjustable": "no", "load_capacity": "50 kg"}}'),
(17, 'HOME-006', 'Philips Hue Smart Bulbs', 1299.00, 780.00, 'White', '2023-10-03 10:00:00', '{"brand": "Philips", "model": "Hue White A19", "warrantyYears": 2, "specifications": {"brightness": "1600 lumens", "color_temperature": "2700K 6500K", "connectivity": "Bluetooth ZigBee", "lifespan": "25000 hours"}}'),
(18, 'CARE-001', 'Dyson SuperSonic Hair Dryer', 3999.00, 2400.00, 'Platinum', '2023-10-05 10:00:00', '{"brand": "Dyson", "model": "SuperSonic", "warrantyYears": 2, "specifications": {"power": "1600W", "air_speed": "40 mph", "heat_levels": "3", "ionic_technology": "yes"}}'),
(18, 'CARE-002', 'GHD Platinum+ Hair Styler', 1999.00, 1200.00, 'Black', '2023-10-05 10:00:00', '{"brand": "GHD", "model": "Platinum+ Styler", "warrantyYears": 2, "specifications": {"plate_width": "28mm", "heat_levels": "5", "temperature_range": "140-365F", "plate_technology": "Dual-zone"}}'),
(19, 'CARE-003', 'Clarisonic Mia Smart', 1299.00, 780.00, 'Rose Gold', '2023-10-07 10:00:00', '{"brand": "Clarisonic", "model": "Mia Smart", "warrantyYears": 1, "specifications": {"frequency": "300 oscillations/sec", "brush_types": "sensitive, normal, deep", "battery": "22 uses per charge", "waterproof": "IPX7"}}'),
(19, 'CARE-004', 'NuFace Trinity Pro', 699.00, 420.00, 'Rose Gold', '2023-10-07 10:00:00', '{"brand": "NuFace", "model": "Trinity PRO", "warrantyYears": 1, "specifications": {"microcurrent": "yes", "treatment_time": "5 minutes", "attachments": "facial, lips, eye", "battery": "2-3 hours"}}'),
(20, 'CARE-005', 'Withings Body+ Smart Scale', 1299.00, 780.00, 'Black', '2023-10-09 10:00:00', '{"brand": "Withings", "model": "Body+", "warrantyYears": 2, "specifications": {"measurements": "weight, BMI, water%, muscle mass", "connectivity": "WiFi Bluetooth", "max_weight": "180kg", "accuracy": "0.1kg"}}'),
(21, 'TV-001', 'LG OLED55C3PUA 55"', 9999.00, 6000.00, 'Black', '2023-10-11 10:00:00', '{"brand": "LG", "model": "OLED55C3PUA", "warrantyYears": 2, "specifications": {"size": "55 inch", "resolution": "4K OLED 3840x2160", "refresh_rate": "120Hz", "brightness": "200 nits peak"}}'),
(21, 'TV-002', 'Sony K-55XR80 55"', 11999.00, 7200.00, 'Black', '2023-10-11 10:00:00', '{"brand": "Sony", "model": "K-55XR80", "warrantyYears": 3, "specifications": {"size": "55 inch", "resolution": "4K Mini-LED 3840x2160", "refresh_rate": "120Hz", "brightness": "3000 nits peak"}}'),
(22, 'TV-003', 'Samsung QN55Q80C 55"', 7999.00, 4800.00, 'Black', '2023-10-13 10:00:00', '{"brand": "Samsung", "model": "QN55Q80C", "warrantyYears": 2, "specifications": {"size": "55 inch", "resolution": "4K QLED 3840x2160", "refresh_rate": "120Hz", "brightness": "2500 nits peak"}}'),
(22, 'TV-004', 'TCL 65" 4K Smart TV', 4999.00, 3000.00, 'Black', '2023-10-13 10:00:00', '{"brand": "TCL", "model": "65Q640", "warrantyYears": 1, "specifications": {"size": "65 inch", "resolution": "4K LED 3840x2160", "refresh_rate": "60Hz", "smart_platform": "Google TV"}}'),
(22, 'TV-005', 'Hisense 55" 4K Smart TV', 3999.00, 2400.00, 'Black', '2023-10-13 10:00:00', '{"brand": "Hisense", "model": "55A6G", "warrantyYears": 1, "specifications": {"size": "55 inch", "resolution": "4K LED 3840x2160", "refresh_rate": "60Hz", "smart_platform": "Android TV"}}'),
(23, 'TV-006', 'Samsung QN65Q90D 65"', 12999.00, 7800.00, 'Black', '2023-10-15 10:00:00', '{"brand": "Samsung", "model": "QN65Q90D", "warrantyYears": 2, "specifications": {"size": "65 inch", "resolution": "4K QLED 3840x2160", "refresh_rate": "144Hz", "brightness": "3000 nits peak"}}'),
(23, 'TV-007', 'LG 65UP7550 65"', 8999.00, 5400.00, 'Black', '2023-10-15 10:00:00', '{"brand": "LG", "model": "65UP7550", "warrantyYears": 2, "specifications": {"size": "65 inch", "resolution": "4K LED 3840x2160", "refresh_rate": "60Hz", "smart_platform": "webOS"}}'),
(23, 'TV-008', 'Panasonic 55HX950 55"', 6999.00, 4200.00, 'Black', '2023-10-15 10:00:00', '{"brand": "Panasonic", "model": "55HX950", "warrantyYears": 2, "specifications": {"size": "55 inch", "resolution": "4K LED 3840x2160", "refresh_rate": "60Hz", "smart_platform": "my Home Screen"}}'),
(24, 'AUDIO-001', 'Bose SoundLink Max', 2999.00, 1800.00, 'Black', '2023-10-17 10:00:00', '{"brand": "Bose", "model": "SoundLink Max", "warrantyYears": 1, "specifications": {"power": "60W", "battery": "20 hours", "connectivity": "Bluetooth 5.3 WiFi", "water_resistance": "IPX7"}}'),
(24, 'AUDIO-002', 'Marshall Stanmore III', 1999.00, 1200.00, 'Black', '2023-10-17 10:00:00', '{"brand": "Marshall", "model": "Stanmore III", "warrantyYears": 2, "specifications": {"power": "80W RMS", "drivers": "dual woofer dual tweeter", "connectivity": "Bluetooth RCA 3.5mm", "dimensions": "560x380x250mm"}}'),
(24, 'AUDIO-003', 'Harman Kardon Onyx Studio 7', 1499.00, 900.00, 'Black', '2023-10-17 10:00:00', '{"brand": "Harman Kardon", "model": "Onyx Studio 7", "warrantyYears": 2, "specifications": {"power": "110W RMS", "drivers": "50mm woofers", "connectivity": "Bluetooth Aux Optical", "design": "Premium wool mesh"}}'),
(25, 'AUDIO-004', 'Sony WH-1000XM5', 3699.00, 2220.00, 'Black', '2023-10-19 10:00:00', '{"brand": "Sony", "model": "WH-1000XM5", "warrantyYears": 1, "specifications": {"noise_cancellation": "industry-leading ANC", "battery": "30 hours", "driver_size": "40mm", "connectivity": "Bluetooth 5.3"}}'),
(25, 'AUDIO-005', 'Bose QuietComfort 45', 3499.00, 2100.00, 'Black', '2023-10-19 10:00:00', '{"brand": "Bose", "model": "QuietComfort 45", "warrantyYears": 1, "specifications": {"noise_cancellation": "dual-microphone ANC", "battery": "24 hours", "driver_type": "custom transducers", "connectivity": "Bluetooth USB-C"}}'),
(25, 'AUDIO-006', 'Apple AirPods Pro Max', 4999.00, 3000.00, 'Silver', '2023-10-19 10:00:00', '{"brand": "Apple", "model": "AirPods Pro Max", "warrantyYears": 1, "specifications": {"noise_cancellation": "Active Noise Cancellation", "battery": "20 hours", "audio": "Spatial audio with Dolby Atmos", "drivers": "40mm custom drivers"}}'),
(25, 'AUDIO-007', 'Sennheiser Momentum 4', 2999.00, 1800.00, 'Black', '2023-10-19 10:00:00', '{"brand": "Sennheiser", "model": "Momentum 4", "warrantyYears": 2, "specifications": {"noise_cancellation": "Adaptive NC", "battery": "60 hours", "driver_size": "42mm", "connectivity": "Bluetooth 5.3"}}'),
(26, 'AUDIO-008', 'Blue Yeti USB Microphone', 999.00, 600.00, 'Black', '2023-10-21 10:00:00', '{"brand": "Blue", "model": "Yeti", "warrantyYears": 2, "specifications": {"capsules": "quad condenser", "pickup_patterns": "4 (cardioid omni bidirectional stereo)", "frequency": "20Hz-20kHz", "connection": "USB"}}'),
(27, 'MOBIL-001', 'iPhone 15 Pro Max 256GB', 15999.00, 9600.00, 'Titanium Blue', '2023-10-23 10:00:00', '{"brand": "Apple", "model": "iPhone 15 Pro Max", "warrantyYears": 1, "specifications": {"processor": "A17 Pro", "ram": "8GB", "storage": "256GB", "display": "6.7-inch Super Retina XDR"}}'),
(27, 'MOBIL-002', 'Samsung Galaxy S24 Ultra', 15499.00, 9300.00, 'Phantom Black', '2023-10-23 10:00:00', '{"brand": "Samsung", "model": "Galaxy S24 Ultra", "warrantyYears": 1, "specifications": {"processor": "Snapdragon 8 Gen 3", "ram": "12GB", "storage": "256GB", "display": "6.8-inch Dynamic AMOLED 2X"}}'),
(27, 'MOBIL-003', 'Google Pixel 8 Pro', 12999.00, 7800.00, 'Porcelain', '2023-10-23 10:00:00', '{"brand": "Google", "model": "Pixel 8 Pro", "warrantyYears": 1, "specifications": {"processor": "Tensor G3", "ram": "12GB", "storage": "256GB", "display": "6.7-inch LTPO OLED 120Hz"}}'),
(27, 'MOBIL-004', 'OnePlus 12', 9999.00, 6000.00, 'Black', '2023-10-23 10:00:00', '{"brand": "OnePlus", "model": "12", "warrantyYears": 1, "specifications": {"processor": "Snapdragon 8 Gen 3", "ram": "12GB", "storage": "256GB", "display": "6.7-inch AMOLED 120Hz"}}'),
(27, 'MOBIL-005', 'Xiaomi 14 Ultra', 11999.00, 7200.00, 'Black', '2023-10-23 10:00:00', '{"brand": "Xiaomi", "model": "14 Ultra", "warrantyYears": 1, "specifications": {"processor": "Snapdragon 8 Gen 3", "ram": "16GB", "storage": "512GB", "display": "6.73-inch AMOLED 120Hz"}}'),
(28, 'MOBIL-006', 'Apple Watch Series 9 Band', 499.00, 300.00, 'Red', '2023-10-25 10:00:00', '{"brand": "Apple", "model": "Sport Band", "warrantyYears": 1, "specifications": {"material": "fluoroelastomer", "sizes": "S/M M/L", "waterproof": "yes", "quick_change": "yes"}}'),
(28, 'MOBIL-007', 'Samsung Galaxy Watch Strap', 399.00, 240.00, 'Black', '2023-10-25 10:00:00', '{"brand": "Samsung", "model": "Sport Band", "warrantyYears": 1, "specifications": {"material": "silicone", "sizes": "S M L", "waterproof": "yes", "quick_release": "yes"}}'),
(29, 'MOBIL-008', 'Apple Watch Ultra 2', 5999.00, 3600.00, 'Titanium', '2023-10-27 10:00:00', '{"brand": "Apple", "model": "Watch Ultra 2", "warrantyYears": 1, "specifications": {"display": "2.04-inch Retina", "processor": "S9", "battery": "36 hours", "water_resistance": "100m"}}'),
(29, 'MOBIL-009', 'Samsung Galaxy Watch 6 Classic', 3999.00, 2400.00, 'Silver', '2023-10-27 10:00:00', '{"brand": "Samsung", "model": "Galaxy Watch 6 Classic", "warrantyYears": 1, "specifications": {"display": "1.3-inch AMOLED", "processor": "Exynos W930", "battery": "40+ hours", "water_resistance": "50m"}}'),
(29, 'MOBIL-010', 'Garmin Epix Gen 2', 4999.00, 3000.00, 'Black', '2023-10-27 10:00:00', '{"brand": "Garmin", "model": "Epix Gen 2", "warrantyYears": 1, "specifications": {"display": "1.4-inch AMOLED", "battery": "11 days smartwatch mode", "gps": "yes", "water_resistance": "100m"}}'),
(30, 'MOBIL-011', 'OtterBox Defender iPhone 15', 599.00, 360.00, 'Black', '2023-10-29 10:00:00', '{"brand": "OtterBox", "model": "Defender Series", "warrantyYears": 1, "specifications": {"protection_level": "heavy-duty", "material": "polycarbonate rubber", "drop_tested": "14ft", "port_access": "precise cutouts"}}'),
(30, 'MOBIL-012', 'Spigen Tough Armor Samsung', 399.00, 240.00, 'Black', '2023-10-29 10:00:00', '{"brand": "Spigen", "model": "Tough Armor", "warrantyYears": 1, "specifications": {"protection": "dual-layer", "material": "TPU hard PC", "weight": "minimal", "shock_absorption": "yes"}}'),
(30, 'MOBIL-013', 'Apple Silicone Case', 699.00, 420.00, 'Midnight', '2023-10-29 10:00:00', '{"brand": "Apple", "model": "Silicone Case", "warrantyYears": 1, "specifications": {"material": "soft silicone", "lining": "velvety microfiber", "wireless_charging": "compatible", "colors_available": "10"}}'),
(30, 'MOBIL-014', 'Samsung Leather Case', 799.00, 480.00, 'Brown', '2023-10-29 10:00:00', '{"brand": "Samsung", "model": "Leather Case", "warrantyYears": 1, "specifications": {"material": "genuine leather", "protection_level": "standard", "aesthetic": "premium look", "wireless_charging": "compatible"}}'),
(31, 'VITV-001', 'LG Front Load Washer 8kg', 9999.00, 6000.00, 'White', '2023-10-31 10:00:00', '{"brand": "LG", "model": "WF80T4000AW", "warrantyYears": 3, "specifications": {"capacity": "8kg", "programs": "14", "rpm": "1200", "energy_class": "A+++"}}'),
(31, 'VITV-002', 'Bosch Series 8 Washer 9kg', 11999.00, 7200.00, 'White', '2023-10-31 10:00:00', '{"brand": "Bosch", "model": "WAX32EH00", "warrantyYears": 3, "specifications": {"capacity": "9kg", "programs": "15", "rpm": "1400", "energy_class": "A+++"}}'),
(32, 'VITV-003', 'Samsung DV22N6800HX Dryer', 8999.00, 5400.00, 'Stainless Steel', '2023-11-02 10:00:00', '{"brand": "Samsung", "model": "DV22N6800HX", "warrantyYears": 1, "specifications": {"capacity": "7.4 cu.ft", "type": "electric", "technology": "AI optimal dry", "energy_class": "A++"}}'),
(33, 'VITV-004', 'Samsung French Door Fridge 650L', 19999.00, 12000.00, 'Stainless Steel', '2023-11-04 10:00:00', '{"brand": "Samsung", "model": "RF65R9000", "warrantyYears": 3, "specifications": {"capacity": "650L", "type": "French Door", "technology": "Twin Cooling Plus", "energy_class": "A+"}}'),
(33, 'VITV-005', 'LG Side-by-Side Fridge 700L', 18999.00, 11400.00, 'Black', '2023-11-04 10:00:00', '{"brand": "LG", "model": "GSXV90BSAE", "warrantyYears": 3, "specifications": {"capacity": "700L", "type": "Side-by-Side", "technology": "LinearCooling", "energy_class": "A+"}}'),
(34, 'CAM-001', 'Canon EOS R5', 24999.00, 15000.00, 'Black', '2023-11-06 10:00:00', '{"brand": "Canon", "model": "EOS R5", "warrantyYears": 2, "specifications": {"sensor": "Full Frame 45MP", "iso_range": "100-51200", "autofocus": "5655 AF points", "video": "8K 60fps"}}'),
(34, 'CAM-002', 'Nikon D850', 19999.00, 12000.00, 'Black', '2023-11-06 10:00:00', '{"brand": "Nikon", "model": "D850", "warrantyYears": 2, "specifications": {"sensor": "Full Frame 45.7MP", "iso_range": "64-25600", "autofocus": "153 AF points", "video": "4K 30fps"}}'),
(35, 'CAM-003', 'Sony A7R V', 22999.00, 13800.00, 'Black', '2023-11-08 10:00:00', '{"brand": "Sony", "model": "Alpha 7R V", "warrantyYears": 2, "specifications": {"sensor": "Full Frame 61MP", "iso_range": "80-32000", "autofocus": "693 AF points", "video": "4K 120fps"}}'),
(35, 'CAM-004', 'Fujifilm X-T5', 15999.00, 9600.00, 'Silver', '2023-11-08 10:00:00', '{"brand": "Fujifilm", "model": "X-T5", "warrantyYears": 2, "specifications": {"sensor": "APS-C 40.2MP", "iso_range": "160-12800", "autofocus": "425 AF points", "video": "4K 60fps"}}'),
(36, 'CAM-005', 'Canon RF 28-70mm f/2L', 4999.00, 3000.00, 'Black', '2023-11-10 10:00:00', '{"brand": "Canon", "model": "RF 28-70mm f/2L", "warrantyYears": 2, "specifications": {"focal_length": "28-70mm", "aperture": "f/2", "elements": "23 elements", "filter_size": "82mm"}}'),
(36, 'CAM-006', 'Sony FE 24-70mm f/2.8 GM II', 5999.00, 3600.00, 'Black', '2023-11-10 10:00:00', '{"brand": "Sony", "model": "FE 24-70mm f/2.8 GM II", "warrantyYears": 2, "specifications": {"focal_length": "24-70mm", "aperture": "f/2.8", "elements": "21 elements", "filter_size": "77mm"}}'),
(36, 'CAM-007', 'Nikon Z 70-200mm f/2.8S', 6999.00, 4200.00, 'Black', '2023-11-10 10:00:00', '{"brand": "Nikon", "model": "Z 70-200mm f/2.8S", "warrantyYears": 2, "specifications": {"focal_length": "70-200mm", "aperture": "f/2.8", "elements": "21 elements", "filter_size": "77mm"}}'),
(36, 'CAM-008', 'Fujifilm XF 35mm f/1.4 R', 1999.00, 1200.00, 'Black', '2023-11-10 10:00:00', '{"brand": "Fujifilm", "model": "XF 35mm f/1.4 R", "warrantyYears": 2, "specifications": {"focal_length": "35mm", "aperture": "f/1.4", "elements": "8 elements", "filter_size": "52mm"}}'),
(37, 'ACC-001', 'OtterBox Defender Case', 599.00, 360.00, 'Black', '2023-11-12 10:00:00', '{"brand": "OtterBox", "model": "Defender Series", "warrantyYears": 1, "specifications": {"protection": "heavy-duty", "material": "polycarbonate rubber", "drop_tested": "14ft", "port_protection": "precise cutouts"}}'),
(37, 'ACC-002', 'Spigen Tough Armor Case', 299.00, 180.00, 'Black', '2023-11-12 10:00:00', '{"brand": "Spigen", "model": "Tough Armor", "warrantyYears": 1, "specifications": {"protection": "dual-layer", "material": "TPU hard PC", "weight": "minimal", "shock_protection": "yes"}}'),
(37, 'ACC-003', 'Apple Silicone Case', 699.00, 420.00, 'Midnight', '2023-11-12 10:00:00', '{"brand": "Apple", "model": "Silicone Case", "warrantyYears": 1, "specifications": {"material": "soft silicone", "lining": "microfiber", "wireless_charging": "compatible", "colors": "10 available"}}'),
(38, 'ACC-004', 'Anker USB-C Cable 2m', 199.00, 120.00, 'Black', '2023-11-14 10:00:00', '{"brand": "Anker", "model": "USB-C to USB-C", "warrantyYears": 1, "specifications": {"length": "2m", "power_delivery": "100W", "data_speed": "480Mbps USB 3.1", "certification": "USB certified"}}'),
(38, 'ACC-005', 'Belkin Lightning Cable 1m', 249.00, 150.00, 'White', '2023-11-14 10:00:00', '{"brand": "Belkin", "model": "USB-A to Lightning", "warrantyYears": 1, "specifications": {"length": "1m", "current": "2.4A", "mfi_certified": "yes", "durability": "reinforced connector"}}'),
(38, 'ACC-006', 'HDMI 2.1 Cable 2m', 299.00, 180.00, 'Black', '2023-11-14 10:00:00', '{"brand": "Generic", "model": "HDMI 2.1", "warrantyYears": 1, "specifications": {"length": "2m", "bandwidth": "48Gbps", "support": "8K 60Hz", "certification": "HDMI 2.1 certified"}}'),
(39, 'ACC-007', 'Anker 67W GaN Charger', 599.00, 360.00, 'Black', '2023-11-16 10:00:00', '{"brand": "Anker", "model": "67W GaN Charger", "warrantyYears": 1, "specifications": {"power": "67W", "ports": "1x USB-C", "technology": "GaN", "compatible_devices": "3 devices"}}'),
(39, 'ACC-008', 'Apple 20W USB-C Power Adapter', 399.00, 240.00, 'White', '2023-11-16 10:00:00', '{"brand": "Apple", "model": "20W USB-C", "warrantyYears": 1, "specifications": {"power": "20W", "compatibility": "iPhone 12+, iPad", "technology": "USB Power Delivery", "size": "compact"}}'),
(39, 'ACC-009', 'Samsung 45W Fast Charger', 449.00, 270.00, 'Black', '2023-11-16 10:00:00', '{"brand": "Samsung", "model": "45W Charger", "warrantyYears": 1, "specifications": {"power": "45W", "compatibility": "Samsung Galaxy", "fast_charge": "35W super fast", "port": "USB-C"}}'),
(40, 'ACC-010', 'Anker USB-C Hub 7-in-1', 699.00, 420.00, 'Silver', '2023-11-18 10:00:00', '{"brand": "Anker", "model": "7-in-1 USB-C Hub", "warrantyYears": 1, "specifications": {"ports": "HDMI, USB 3.0 x3, SD, microSD, USB-C", "compatibility": "MacBook, iPad Pro, laptops", "data_speed": "5Gbps", "power_delivery": "60W"}}'),
(40, 'ACC-011', 'Belkin USB-C Multiport Hub', 799.00, 480.00, 'Gray', '2023-11-18 10:00:00', '{"brand": "Belkin", "model": "USB-C Multiport Hub", "warrantyYears": 2, "specifications": {"ports": "HDMI, USB 3.0 x2, USB-C, SD", "compatibility": "universal USB-C devices", "data_speed": "5Gbps", "power_delivery": "100W"}}'),
(41, 'ACC-012', 'Spigen Tempered Glass iPhone', 299.00, 180.00, 'Clear', '2023-11-20 10:00:00', '{"brand": "Spigen", "model": "Tempered Glass", "warrantyYears": 1, "specifications": {"hardness": "9H", "oleophobic_coating": "yes", "transparency": "ultra-clear", "installation": "alignment kit included"}}'),
(41, 'ACC-013', 'ZAGG InvisibleShield Glass', 249.00, 150.00, 'Clear', '2023-11-20 10:00:00', '{"brand": "ZAGG", "model": "InvisibleShield", "warrantyYears": 1, "specifications": {"material": "tempered glass", "hardness": "9H", "self_healing": "anti-microbial", "warranty": "drop protection warranty"}}');


INSERT INTO dbo.Customer (FirstName, LastName, Email, Phone) VALUES
('Anders', 'Svensson', 'anders.svensson@gmail.com', '0701234567'),
('Birgitta', 'Andersson', 'birgitta.andersson@outlook.se', NULL),
('Carl', 'Bergström', 'carl.bergstrom@gmail.com', '0709876543'),
('Dagny', 'Carlsson', 'dagny.carlsson@outlook.se', '0702345678'),
('Erik', 'Dahlqvist', 'erik.dahlqvist@gmail.com', NULL),
('Freja', 'Ekström', 'freja.ekstrom@outlook.se', '0703456789'),
('Gunnar', 'Fransson', 'gunnar.fransson@gmail.com', '0704567890'),
('Hilda', 'Gustafsson', 'hilda.gustafsson@outlook.se', '0705678901'),
('Ivar', 'Hansson', 'ivar.hansson@gmail.com', NULL),
('Johanna', 'Isaksson', 'johanna.isaksson@outlook.se', '0706789012'),
('Knut', 'Jansson', 'knut.jansson@gmail.com', '0707890123'),
('Linnea', 'Karlsson', 'linnea.karlsson@outlook.se', '0708901234'),
('Magnus', 'Larsson', 'magnus.larsson@gmail.com', NULL),
('Nina', 'Lundström', 'nina.lundstrom@outlook.se', '0709012345'),
('Olof', 'Mattsson', 'olof.mattsson@gmail.com', '0700123456'),
('Pernilla', 'Nilsson', 'pernilla.nilsson@outlook.se', '0701112222'),
('Quinton', 'Olsson', 'quinton.olsson@gmail.com', NULL),
('Rune', 'Pettersson', 'rune.pettersson@outlook.se', '0702223333'),
('Sigrid', 'Qvarnström', 'sigrid.qvarnstrom@gmail.com', '0703334444'),
('Torsten', 'Ragnarsson', 'torsten.ragnarsson@outlook.se', '0704445555'),
('Ulla', 'Sahlström', 'ulla.sahlstrom@gmail.com', NULL),
('Viktor', 'Tagesson', 'viktor.tagesson@outlook.se', '0705556666'),
('Wendla', 'Udön', 'wendla.uden@gmail.com', '0706667777'),
('Xerxes', 'Viklund', 'xerxes.viklund@outlook.se', NULL),
('Yoko', 'Wahl', 'yoko.wahl@gmail.com', '0708889999'),
('Zigge', 'Xanthopoulos', 'zigge.xanthopoulos@outlook.se', '0707778888'),
('Astrid', 'Åberg', 'astrid.aberg@gmail.com', '0700011111'),
('Bengt', 'Åström', 'bengt.astrom@outlook.se', NULL),
('Cecilia', 'Börjelsson', 'cecilia.borjelsson@gmail.com', '0701223334'),
('Didrik', 'Åberg', 'didrik.oberg@outlook.se', '0702334445'),
('Ebba', 'Åstberg', 'ebba.ostberg@gmail.com', '0703445556'),
('Fredrik', 'Åkerman', 'fredrik.akerman@outlook.se', NULL),
('Greta', 'Blomqvist', 'greta.blomqvist@gmail.com', '0704556667'),
('Harald', 'Borgström', 'harald.borgstrom@outlook.se', '0705667778'),
('Ingrid', 'Bredström', 'ingrid.bredstrom@gmail.com', '0706778889'),
('Johan', 'Bryntsson', 'johan.bryntsson@outlook.se', NULL),
('Kajsa', 'Brunström', 'kajsa.brunstrom@gmail.com', '0707889990'),
('Lennart', 'Cedström', 'lennart.cedstrom@outlook.se', '0708990001'),
('Marta', 'Dahlström', 'marta.dahlstrom@gmail.com', '0700001112'),
('Nils', 'Danielsson', 'nils.danielsson@outlook.se', NULL),
('Olivia', 'Dohlström', 'olivia.dohlstrom@gmail.com', '0701112223'),
('P�r', 'Eklund', 'par.eklund@outlook.se', '0702223334'),
('Ragnhild', 'Engström', 'ragnhild.engstrom@gmail.com', '0703334445'),
('Sture', 'Ericsson', 'sture.ericsson@outlook.se', NULL),
('Tekla', 'Eriksson', 'tekla.eriksson@gmail.com', '0704445556'),
('Urban', 'Fernström', 'urban.fernstrom@outlook.se', '0705556667'),
('Viveca', 'Fritzson', 'viveca.fritzson@gmail.com', '0706667778'),
('Wolff', 'Gabrielsson', 'wolff.gabrielsson@outlook.se', NULL),
('Ximena', 'Gartner', 'ximena.gartner@gmail.com', '0707778889'),
('Yuri', 'Garvey', 'yuri.garvey@outlook.se', '0708889990'),
('Zara', 'Gerell', 'zara.gerell@gmail.com', '0700990001'),
('Aksel', 'Gerner', 'aksel.gerner@outlook.se', NULL),
('Berta', 'Gessler', 'berta.gessler@gmail.com', '0701001112'),
('Christer', 'Geter', 'christer.geter@outlook.se', '0702112223');

-- =====================================================
-- INSERT PAYMENTS (180 Payments with Realistic Distribution)
-- =====================================================

USE NetOnNet
GO

INSERT INTO dbo.Payment (MethodName, ProviderName, IsApproved, CreatedDate) VALUES
-- JANUARY (20 payments)
('Kort', 'Visa', 1, '2024-01-05 09:15:00'),
('Kort', 'Mastercard', 1, '2024-01-08 14:32:00'),
('Kort', 'Visa', 1, '2024-01-10 11:47:00'),
('Swish', 'Swish', 1, '2024-01-12 16:20:00'),
('Kort', 'Mastercard', 1, '2024-01-15 10:05:00'),
('Swish', 'Swish', 1, '2024-01-18 13:45:00'),
('Faktura', 'Klarna', 1, '2024-01-20 08:30:00'),
('Kort', 'Visa', 1, '2024-01-22 15:10:00'),
('Swish', 'Swish', 1, '2024-01-24 12:25:00'),
('Kort', 'Mastercard', 1, '2024-01-26 09:40:00'),
('Kort', 'Visa', 1, '2024-01-27 14:55:00'),
('Swish', 'Swish', 0, '2024-01-28 11:30:00'),
('Kort', 'Visa', 1, '2024-01-29 16:15:00'),
('Faktura', 'Klarna', 1, '2024-01-30 10:20:00'),
('Kort', 'Mastercard', 1, '2024-01-02 13:35:00'),
('Swish', 'Swish', 1, '2024-01-03 09:50:00'),
('Kort', 'Visa', 1, '2024-01-04 15:00:00'),
('Avbetalning', 'Klarna', 1, '2024-01-06 12:10:00'),
('Kort', 'Mastercard', 1, '2024-01-07 08:45:00'),
('Paypal', 'Paypal', 1, '2024-01-09 14:30:00'),

-- FEBRUARY (12 payments)
('Kort', 'Visa', 1, '2024-02-01 10:15:00'),
('Swish', 'Swish', 1, '2024-02-05 13:40:00'),
('Kort', 'Mastercard', 1, '2024-02-08 09:25:00'),
('Kort', 'Visa', 1, '2024-02-10 15:50:00'),
('Swish', 'Swish', 1, '2024-02-12 11:35:00'),
('Kort', 'Mastercard', 1, '2024-02-15 14:20:00'),
('Faktura', 'Klarna', 1, '2024-02-18 08:00:00'),
('Kort', 'Visa', 1, '2024-02-20 16:45:00'),
('Swish', 'Swish', 1, '2024-02-22 12:30:00'),
('Kort', 'Mastercard', 1, '2024-02-24 10:10:00'),
('Kort', 'Visa', 0, '2024-02-26 13:25:00'),
('Avbetalning', 'Klarna', 1, '2024-02-28 09:55:00'),

-- MARCH (15 payments)
('Kort', 'Visa', 1, '2024-03-02 11:40:00'),
('Swish', 'Swish', 1, '2024-03-05 14:55:00'),
('Kort', 'Mastercard', 1, '2024-03-08 10:30:00'),
('Kort', 'Visa', 1, '2024-03-10 15:15:00'),
('Swish', 'Swish', 1, '2024-03-12 09:45:00'),
('Kort', 'Mastercard', 1, '2024-03-15 13:20:00'),
('Faktura', 'Klarna', 1, '2024-03-18 08:50:00'),
('Kort', 'Visa', 1, '2024-03-20 16:10:00'),
('Swish', 'Swish', 1, '2024-03-22 12:35:00'),
('Kort', 'Mastercard', 1, '2024-03-24 11:05:00'),
('Kort', 'Visa', 1, '2024-03-26 14:40:00'),
('Paypal', 'Paypal', 1, '2024-03-28 10:15:00'),
('Avbetalning', 'Klarna', 1, '2024-03-29 15:50:00'),
('Kort', 'Mastercard', 1, '2024-03-01 09:30:00'),
('Swish', 'Swish', 1, '2024-03-03 13:45:00'),

-- APRIL (15 payments)
('Kort', 'Visa', 1, '2024-04-02 10:20:00'),
('Swish', 'Swish', 1, '2024-04-05 14:35:00'),
('Kort', 'Mastercard', 1, '2024-04-08 11:50:00'),
('Faktura', 'Klarna', 1, '2024-04-10 16:00:00'),
('Kort', 'Visa', 1, '2024-04-12 09:15:00'),
('Swish', 'Swish', 1, '2024-04-15 13:40:00'),
('Kort', 'Mastercard', 1, '2024-04-18 10:55:00'),
('Kort', 'Visa', 1, '2024-04-20 15:25:00'),
('Swish', 'Swish', 1, '2024-04-22 12:10:00'),
('Avbetalning', 'Klarna', 1, '2024-04-24 08:45:00'),
('Kort', 'Mastercard', 1, '2024-04-26 14:30:00'),
('Kort', 'Visa', 1, '2024-04-27 11:00:00'),
('Faktura', 'Klarna', 1, '2024-04-28 16:20:00'),
('Swish', 'Swish', 1, '2024-04-29 09:35:00'),
('Kort', 'Visa', 1, '2024-04-30 13:15:00'),

-- MAY (15 payments)
('Kort', 'Mastercard', 1, '2024-05-02 10:40:00'),
('Swish', 'Swish', 1, '2024-05-05 14:20:00'),
('Kort', 'Visa', 1, '2024-05-08 11:30:00'),
('Kort', 'Mastercard', 1, '2024-05-10 15:45:00'),
('Faktura', 'Klarna', 1, '2024-05-12 09:50:00'),
('Kort', 'Visa', 1, '2024-05-15 13:35:00'),
('Swish', 'Swish', 1, '2024-05-18 12:05:00'),
('Kort', 'Mastercard', 1, '2024-05-20 16:15:00'),
('Kort', 'Visa', 1, '2024-05-22 10:25:00'),
('Avbetalning', 'Klarna', 1, '2024-05-24 14:00:00'),
('Swish', 'Swish', 1, '2024-05-26 11:40:00'),
('Kort', 'Mastercard', 1, '2024-05-27 09:10:00'),
('Kort', 'Visa', 0, '2024-05-28 15:55:00'),
('Paypal', 'Paypal', 1, '2024-05-29 12:20:00'),
('Kort', 'Visa', 1, '2024-05-30 13:50:00'),

-- JUNE (10 payments)
('Kort', 'Mastercard', 1, '2024-06-02 11:15:00'),
('Swish', 'Swish', 1, '2024-06-05 14:45:00'),
('Kort', 'Visa', 1, '2024-06-08 10:30:00'),
('Kort', 'Mastercard', 1, '2024-06-10 16:00:00'),
('Faktura', 'Klarna', 1, '2024-06-15 09:20:00'),
('Kort', 'Visa', 1, '2024-06-18 13:35:00'),
('Swish', 'Swish', 1, '2024-06-20 12:50:00'),
('Kort', 'Mastercard', 1, '2024-06-22 15:10:00'),
('Kort', 'Visa', 1, '2024-06-25 10:40:00'),
('Avbetalning', 'Klarna', 1, '2024-06-28 14:25:00'),

-- JULY (10 payments)
('Kort', 'Visa', 1, '2024-07-02 11:50:00'),
('Swish', 'Swish', 1, '2024-07-05 14:10:00'),
('Kort', 'Mastercard', 1, '2024-07-08 10:15:00'),
('Kort', 'Visa', 1, '2024-07-10 16:30:00'),
('Faktura', 'Klarna', 1, '2024-07-15 09:45:00'),
('Kort', 'Mastercard', 1, '2024-07-18 13:20:00'),
('Swish', 'Swish', 1, '2024-07-20 12:35:00'),
('Kort', 'Visa', 1, '2024-07-22 15:50:00'),
('Kort', 'Mastercard', 1, '2024-07-25 10:05:00'),
('Paypal', 'Paypal', 1, '2024-07-28 14:40:00'),

-- AUGUST (13 payments)
('Kort', 'Visa', 1, '2024-08-01 11:20:00'),
('Kort', 'Mastercard', 1, '2024-08-03 14:50:00'),
('Swish', 'Swish', 1, '2024-08-05 10:25:00'),
('Kort', 'Visa', 1, '2024-08-08 16:15:00'),
('Kort', 'Mastercard', 1, '2024-08-10 09:40:00'),
('Swish', 'Swish', 1, '2024-08-12 13:55:00'),
('Faktura', 'Klarna', 1, '2024-08-15 12:10:00'),
('Kort', 'Visa', 1, '2024-08-18 15:35:00'),
('Kort', 'Mastercard', 1, '2024-08-20 10:50:00'),
('Swish', 'Swish', 1, '2024-08-22 14:20:00'),
('Kort', 'Visa', 1, '2024-08-24 11:30:00'),
('Avbetalning', 'Klarna', 1, '2024-08-26 09:05:00'),
('Kort', 'Mastercard', 0, '2024-08-28 15:45:00'),

-- SEPTEMBER (16 payments)
('Kort', 'Visa', 1, '2024-09-02 10:35:00'),
('Kort', 'Mastercard', 1, '2024-09-04 14:15:00'),
('Swish', 'Swish', 1, '2024-09-06 11:50:00'),
('Kort', 'Visa', 1, '2024-09-08 16:40:00'),
('Kort', 'Mastercard', 1, '2024-09-10 09:25:00'),
('Swish', 'Swish', 1, '2024-09-12 13:10:00'),
('Faktura', 'Klarna', 1, '2024-09-14 12:35:00'),
('Kort', 'Visa', 1, '2024-09-16 15:50:00'),
('Kort', 'Mastercard', 1, '2024-09-18 10:20:00'),
('Swish', 'Swish', 1, '2024-09-20 14:00:00'),
('Kort', 'Visa', 1, '2024-09-22 11:15:00'),
('Avbetalning', 'Klarna', 1, '2024-09-24 09:45:00'),
('Kort', 'Mastercard', 1, '2024-09-26 15:30:00'),
('Kort', 'Visa', 1, '2024-09-27 10:55:00'),
('Paypal', 'Paypal', 1, '2024-09-28 13:40:00'),
('Kort', 'Mastercard', 1, '2024-09-29 12:05:00'),

-- OCTOBER (16 payments)
('Kort', 'Visa', 1, '2024-10-01 11:30:00'),
('Kort', 'Mastercard', 1, '2024-10-03 14:50:00'),
('Swish', 'Swish', 1, '2024-10-05 10:15:00'),
('Kort', 'Visa', 1, '2024-10-07 15:45:00'),
('Kort', 'Mastercard', 1, '2024-10-09 09:20:00'),
('Faktura', 'Klarna', 1, '2024-10-11 13:35:00'),
('Kort', 'Visa', 1, '2024-10-13 12:50:00'),
('Swish', 'Swish', 1, '2024-10-15 16:10:00'),
('Kort', 'Mastercard', 1, '2024-10-17 10:40:00'),
('Kort', 'Visa', 1, '2024-10-19 14:25:00'),
('Kort', 'Mastercard', 1, '2024-10-21 11:05:00'),
('Avbetalning', 'Klarna', 1, '2024-10-23 09:30:00'),
('Kort', 'Visa', 1, '2024-10-25 15:15:00'),
('Swish', 'Swish', 1, '2024-10-27 12:40:00'),
('Kort', 'Mastercard', 1, '2024-10-29 13:55:00'),
('Kort', 'Visa', 1, '2024-10-30 10:20:00'),

-- NOVEMBER (37 payments - BLACK FRIDAY/CYBER MONDAY)
('Kort', 'Visa', 1, '2024-11-01 11:45:00'),
('Kort', 'Mastercard', 1, '2024-11-03 14:30:00'),
('Swish', 'Swish', 1, '2024-11-05 10:50:00'),
('Kort', 'Visa', 1, '2024-11-07 15:20:00'),
('Kort', 'Mastercard', 1, '2024-11-09 09:35:00'),
('Faktura', 'Klarna', 1, '2024-11-11 13:15:00'),
('Kort', 'Visa', 1, '2024-11-13 12:25:00'),
('Swish', 'Swish', 1, '2024-11-14 16:40:00'),
('Kort', 'Mastercard', 1, '2024-11-15 10:10:00'),
('Kort', 'Visa', 1, '2024-11-16 14:55:00'),
('Avbetalning', 'Klarna', 1, '2024-11-17 11:30:00'),
('Kort', 'Mastercard', 1, '2024-11-18 09:05:00'),
('Kort', 'Visa', 1, '2024-11-19 15:50:00'),
('Swish', 'Swish', 1, '2024-11-20 12:20:00'),
('Kort', 'Mastercard', 1, '2024-11-21 13:45:00'),
('Kort', 'Visa', 1, '2024-11-22 10:35:00'),
('Faktura', 'Klarna', 1, '2024-11-23 14:10:00'),
('Kort', 'Mastercard', 0, '2024-11-24 11:50:00'),
('Swish', 'Swish', 1, '2024-11-25 09:15:00'),
('Kort', 'Visa', 1, '2024-11-26 16:30:00'),
('Kort', 'Mastercard', 1, '2024-11-27 12:05:00'),
('Avbetalning', 'Klarna', 1, '2024-11-28 13:40:00'),
('Kort', 'Visa', 1, '2024-11-29 10:25:00'),
('Kort', 'Mastercard', 1, '2024-11-30 14:55:00'),
('Swish', 'Swish', 1, '2024-11-02 11:20:00'),
('Kort', 'Visa', 1, '2024-11-04 15:35:00'),
('Kort', 'Mastercard', 1, '2024-11-06 10:50:00'),
('Faktura', 'Klarna', 1, '2024-11-08 13:15:00'),
('Kort', 'Visa', 1, '2024-11-10 12:40:00'),
('Kort', 'Mastercard', 1, '2024-11-12 09:55:00'),
('Swish', 'Swish', 1, '2024-11-19 14:20:00'),
('Kort', 'Visa', 1, '2024-11-21 11:35:00'),
('Kort', 'Mastercard', 1, '2024-11-23 15:50:00'),
('Avbetalning', 'Klarna', 1, '2024-11-25 10:10:00'),
('Kort', 'Visa', 1, '2024-11-26 13:45:00'),
('Kort', 'Mastercard', 1, '2024-11-27 12:30:00'),
('Swish', 'Swish', 1, '2024-11-28 16:05:00'),

-- DECEMBER (33 payments - CHRISTMAS)
('Kort', 'Visa', 1, '2024-12-01 10:40:00'),
('Kort', 'Mastercard', 1, '2024-12-02 14:25:00'),
('Swish', 'Swish', 1, '2024-12-03 11:50:00'),
('Kort', 'Visa', 1, '2024-12-04 15:30:00'),
('Kort', 'Mastercard', 1, '2024-12-05 09:15:00'),
('Faktura', 'Klarna', 1, '2024-12-06 13:40:00'),
('Kort', 'Visa', 1, '2024-12-07 12:10:00'),
('Kort', 'Mastercard', 1, '2024-12-08 16:55:00'),
('Swish', 'Swish', 1, '2024-12-09 10:20:00'),
('Kort', 'Visa', 1, '2024-12-10 14:35:00'),
('Kort', 'Mastercard', 1, '2024-12-11 11:45:00'),
('Avbetalning', 'Klarna', 1, '2024-12-12 09:25:00'),
('Kort', 'Visa', 1, '2024-12-13 15:10:00'),
('Kort', 'Mastercard', 1, '2024-12-14 12:50:00'),
('Swish', 'Swish', 1, '2024-12-15 13:20:00'),
('Kort', 'Visa', 1, '2024-12-16 10:05:00'),
('Kort', 'Mastercard', 1, '2024-12-17 14:40:00'),
('Faktura', 'Klarna', 1, '2024-12-18 11:55:00'),
('Kort', 'Visa', 1, '2024-12-19 16:15:00'),
('Kort', 'Mastercard', 1, '2024-12-20 10:30:00'),
('Swish', 'Swish', 1, '2024-12-21 13:50:00'),
('Kort', 'Visa', 1, '2024-12-22 12:20:00'),
('Kort', 'Mastercard', 1, '2024-12-23 15:45:00'),
('Avbetalning', 'Klarna', 1, '2024-12-24 09:10:00'),
('Kort', 'Visa', 1, '2024-12-21 14:35:00'),
('Kort', 'Mastercard', 1, '2024-12-22 11:50:00'),
('Swish', 'Swish', 1, '2024-12-23 10:15:00'),
('Kort', 'Visa', 1, '2024-12-24 16:40:00'),
('Kort', 'Mastercard', 1, '2024-12-25 12:05:00'),
('Faktura', 'Klarna', 1, '2024-12-26 13:30:00'),
('Kort', 'Visa', 1, '2024-12-27 10:50:00'),
('Kort', 'Mastercard', 1, '2024-12-28 14:15:00'),
('Swish', 'Swish', 1, '2024-12-29 11:35:00');

INSERT INTO dbo.Payment (MethodName, ProviderName, IsApproved, CreatedDate) VALUES
-- JANUARY (20 payments)
('Kort', 'Visa', 1, '2024-01-05 09:15:00'),
('Kort', 'Mastercard', 1, '2024-01-08 14:32:00'),
('Kort', 'Visa', 1, '2024-01-10 11:47:00'),
('Swish', 'Swish', 1, '2024-01-12 16:20:00'),
('Kort', 'Mastercard', 1, '2024-01-15 10:05:00'),
('Swish', 'Swish', 1, '2024-01-18 13:45:00'),
('Faktura', 'Klarna', 1, '2024-01-20 08:30:00'),
('Kort', 'Visa', 1, '2024-01-22 15:10:00'),
('Swish', 'Swish', 1, '2024-01-24 12:25:00'),
('Kort', 'Mastercard', 1, '2024-01-26 09:40:00'),
('Kort', 'Visa', 1, '2024-01-27 14:55:00'),
('Swish', 'Swish', 0, '2024-01-28 11:30:00'),
('Kort', 'Visa', 1, '2024-01-29 16:15:00'),
('Faktura', 'Klarna', 1, '2024-01-30 10:20:00'),
('Kort', 'Mastercard', 1, '2024-01-02 13:35:00'),
('Swish', 'Swish', 1, '2024-01-03 09:50:00'),
('Kort', 'Visa', 1, '2024-01-04 15:00:00'),
('Avbetalning', 'Klarna', 1, '2024-01-06 12:10:00'),
('Kort', 'Mastercard', 1, '2024-01-07 08:45:00'),
('Paypal', 'Paypal', 1, '2024-01-09 14:30:00'),

-- FEBRUARY (12 payments)
('Kort', 'Visa', 1, '2024-02-01 10:15:00'),
('Swish', 'Swish', 1, '2024-02-05 13:40:00'),
('Kort', 'Mastercard', 1, '2024-02-08 09:25:00'),
('Kort', 'Visa', 1, '2024-02-10 15:50:00'),
('Swish', 'Swish', 1, '2024-02-12 11:35:00'),
('Kort', 'Mastercard', 1, '2024-02-15 14:20:00'),
('Faktura', 'Klarna', 1, '2024-02-18 08:00:00'),
('Kort', 'Visa', 1, '2024-02-20 16:45:00'),
('Swish', 'Swish', 1, '2024-02-22 12:30:00'),
('Kort', 'Mastercard', 1, '2024-02-24 10:10:00'),
('Kort', 'Visa', 0, '2024-02-26 13:25:00'),
('Avbetalning', 'Klarna', 1, '2024-02-28 09:55:00'),

-- MARCH (15 payments)
('Kort', 'Visa', 1, '2024-03-02 11:40:00'),
('Swish', 'Swish', 1, '2024-03-05 14:55:00'),
('Kort', 'Mastercard', 1, '2024-03-08 10:30:00'),
('Kort', 'Visa', 1, '2024-03-10 15:15:00'),
('Swish', 'Swish', 1, '2024-03-12 09:45:00'),
('Kort', 'Mastercard', 1, '2024-03-15 13:20:00'),
('Faktura', 'Klarna', 1, '2024-03-18 08:50:00'),
('Kort', 'Visa', 1, '2024-03-20 16:10:00'),
('Swish', 'Swish', 1, '2024-03-22 12:35:00'),
('Kort', 'Mastercard', 1, '2024-03-24 11:05:00'),
('Kort', 'Visa', 1, '2024-03-26 14:40:00'),
('Paypal', 'Paypal', 1, '2024-03-28 10:15:00'),
('Avbetalning', 'Klarna', 1, '2024-03-29 15:50:00'),
('Kort', 'Mastercard', 1, '2024-03-01 09:30:00'),
('Swish', 'Swish', 1, '2024-03-03 13:45:00'),

-- APRIL (15 payments)
('Kort', 'Visa', 1, '2024-04-02 10:20:00'),
('Swish', 'Swish', 1, '2024-04-05 14:35:00'),
('Kort', 'Mastercard', 1, '2024-04-08 11:50:00'),
('Faktura', 'Klarna', 1, '2024-04-10 16:00:00'),
('Kort', 'Visa', 1, '2024-04-12 09:15:00'),
('Swish', 'Swish', 1, '2024-04-15 13:40:00'),
('Kort', 'Mastercard', 1, '2024-04-18 10:55:00'),
('Kort', 'Visa', 1, '2024-04-20 15:25:00'),
('Swish', 'Swish', 1, '2024-04-22 12:10:00'),
('Avbetalning', 'Klarna', 1, '2024-04-24 08:45:00'),
('Kort', 'Mastercard', 1, '2024-04-26 14:30:00'),
('Kort', 'Visa', 1, '2024-04-27 11:00:00'),
('Faktura', 'Klarna', 1, '2024-04-28 16:20:00'),
('Swish', 'Swish', 1, '2024-04-29 09:35:00'),
('Kort', 'Visa', 1, '2024-04-30 13:15:00'),

-- MAY (15 payments)
('Kort', 'Mastercard', 1, '2024-05-02 10:40:00'),
('Swish', 'Swish', 1, '2024-05-05 14:20:00'),
('Kort', 'Visa', 1, '2024-05-08 11:30:00'),
('Kort', 'Mastercard', 1, '2024-05-10 15:45:00'),
('Faktura', 'Klarna', 1, '2024-05-12 09:50:00'),
('Kort', 'Visa', 1, '2024-05-15 13:35:00'),
('Swish', 'Swish', 1, '2024-05-18 12:05:00'),
('Kort', 'Mastercard', 1, '2024-05-20 16:15:00'),
('Kort', 'Visa', 1, '2024-05-22 10:25:00'),
('Avbetalning', 'Klarna', 1, '2024-05-24 14:00:00'),
('Swish', 'Swish', 1, '2024-05-26 11:40:00'),
('Kort', 'Mastercard', 1, '2024-05-27 09:10:00'),
('Kort', 'Visa', 0, '2024-05-28 15:55:00'),
('Paypal', 'Paypal', 1, '2024-05-29 12:20:00'),
('Kort', 'Visa', 1, '2024-05-30 13:50:00'),

-- JUNE (10 payments)
('Kort', 'Mastercard', 1, '2024-06-02 11:15:00'),
('Swish', 'Swish', 1, '2024-06-05 14:45:00'),
('Kort', 'Visa', 1, '2024-06-08 10:30:00'),
('Kort', 'Mastercard', 1, '2024-06-10 16:00:00'),
('Faktura', 'Klarna', 1, '2024-06-15 09:20:00'),
('Kort', 'Visa', 1, '2024-06-18 13:35:00'),
('Swish', 'Swish', 1, '2024-06-20 12:50:00'),
('Kort', 'Mastercard', 1, '2024-06-22 15:10:00'),
('Kort', 'Visa', 1, '2024-06-25 10:40:00'),
('Avbetalning', 'Klarna', 1, '2024-06-28 14:25:00'),

-- JULY (10 payments)
('Kort', 'Visa', 1, '2024-07-02 11:50:00'),
('Swish', 'Swish', 1, '2024-07-05 14:10:00'),
('Kort', 'Mastercard', 1, '2024-07-08 10:15:00'),
('Kort', 'Visa', 1, '2024-07-10 16:30:00'),
('Faktura', 'Klarna', 1, '2024-07-15 09:45:00'),
('Kort', 'Mastercard', 1, '2024-07-18 13:20:00'),
('Swish', 'Swish', 1, '2024-07-20 12:35:00'),
('Kort', 'Visa', 1, '2024-07-22 15:50:00'),
('Kort', 'Mastercard', 1, '2024-07-25 10:05:00'),
('Paypal', 'Paypal', 1, '2024-07-28 14:40:00'),

-- AUGUST (13 payments)
('Kort', 'Visa', 1, '2024-08-01 11:20:00'),
('Kort', 'Mastercard', 1, '2024-08-03 14:50:00'),
('Swish', 'Swish', 1, '2024-08-05 10:25:00'),
('Kort', 'Visa', 1, '2024-08-08 16:15:00'),
('Kort', 'Mastercard', 1, '2024-08-10 09:40:00'),
('Swish', 'Swish', 1, '2024-08-12 13:55:00'),
('Faktura', 'Klarna', 1, '2024-08-15 12:10:00'),
('Kort', 'Visa', 1, '2024-08-18 15:35:00'),
('Kort', 'Mastercard', 1, '2024-08-20 10:50:00'),
('Swish', 'Swish', 1, '2024-08-22 14:20:00'),
('Kort', 'Visa', 1, '2024-08-24 11:30:00'),
('Avbetalning', 'Klarna', 1, '2024-08-26 09:05:00'),
('Kort', 'Mastercard', 0, '2024-08-28 15:45:00'),

-- SEPTEMBER (16 payments)
('Kort', 'Visa', 1, '2024-09-02 10:35:00'),
('Kort', 'Mastercard', 1, '2024-09-04 14:15:00'),
('Swish', 'Swish', 1, '2024-09-06 11:50:00'),
('Kort', 'Visa', 1, '2024-09-08 16:40:00'),
('Kort', 'Mastercard', 1, '2024-09-10 09:25:00'),
('Swish', 'Swish', 1, '2024-09-12 13:10:00'),
('Faktura', 'Klarna', 1, '2024-09-14 12:35:00'),
('Kort', 'Visa', 1, '2024-09-16 15:50:00'),
('Kort', 'Mastercard', 1, '2024-09-18 10:20:00'),
('Swish', 'Swish', 1, '2024-09-20 14:00:00'),
('Kort', 'Visa', 1, '2024-09-22 11:15:00'),
('Avbetalning', 'Klarna', 1, '2024-09-24 09:45:00'),
('Kort', 'Mastercard', 1, '2024-09-26 15:30:00'),
('Kort', 'Visa', 1, '2024-09-27 10:55:00'),
('Paypal', 'Paypal', 1, '2024-09-28 13:40:00'),
('Kort', 'Mastercard', 1, '2024-09-29 12:05:00'),

-- OCTOBER (16 payments)
('Kort', 'Visa', 1, '2024-10-01 11:30:00'),
('Kort', 'Mastercard', 1, '2024-10-03 14:50:00'),
('Swish', 'Swish', 1, '2024-10-05 10:15:00'),
('Kort', 'Visa', 1, '2024-10-07 15:45:00'),
('Kort', 'Mastercard', 1, '2024-10-09 09:20:00'),
('Faktura', 'Klarna', 1, '2024-10-11 13:35:00'),
('Kort', 'Visa', 1, '2024-10-13 12:50:00'),
('Swish', 'Swish', 1, '2024-10-15 16:10:00'),
('Kort', 'Mastercard', 1, '2024-10-17 10:40:00'),
('Kort', 'Visa', 1, '2024-10-19 14:25:00'),
('Kort', 'Mastercard', 1, '2024-10-21 11:05:00'),
('Avbetalning', 'Klarna', 1, '2024-10-23 09:30:00'),
('Kort', 'Visa', 1, '2024-10-25 15:15:00'),
('Swish', 'Swish', 1, '2024-10-27 12:40:00'),
('Kort', 'Mastercard', 1, '2024-10-29 13:55:00'),
('Kort', 'Visa', 1, '2024-10-30 10:20:00'),

-- NOVEMBER (37 payments - BLACK FRIDAY/CYBER MONDAY)
('Kort', 'Visa', 1, '2024-11-01 11:45:00'),
('Kort', 'Mastercard', 1, '2024-11-03 14:30:00'),
('Swish', 'Swish', 1, '2024-11-05 10:50:00'),
('Kort', 'Visa', 1, '2024-11-07 15:20:00'),
('Kort', 'Mastercard', 1, '2024-11-09 09:35:00'),
('Faktura', 'Klarna', 1, '2024-11-11 13:15:00'),
('Kort', 'Visa', 1, '2024-11-13 12:25:00'),
('Swish', 'Swish', 1, '2024-11-14 16:40:00'),
('Kort', 'Mastercard', 1, '2024-11-15 10:10:00'),
('Kort', 'Visa', 1, '2024-11-16 14:55:00'),
('Avbetalning', 'Klarna', 1, '2024-11-17 11:30:00'),
('Kort', 'Mastercard', 1, '2024-11-18 09:05:00'),
('Kort', 'Visa', 1, '2024-11-19 15:50:00'),
('Swish', 'Swish', 1, '2024-11-20 12:20:00'),
('Kort', 'Mastercard', 1, '2024-11-21 13:45:00'),
('Kort', 'Visa', 1, '2024-11-22 10:35:00'),
('Faktura', 'Klarna', 1, '2024-11-23 14:10:00'),
('Kort', 'Mastercard', 0, '2024-11-24 11:50:00'),
('Swish', 'Swish', 1, '2024-11-25 09:15:00'),
('Kort', 'Visa', 1, '2024-11-26 16:30:00'),
('Kort', 'Mastercard', 1, '2024-11-27 12:05:00'),
('Avbetalning', 'Klarna', 1, '2024-11-28 13:40:00'),
('Kort', 'Visa', 1, '2024-11-29 10:25:00'),
('Kort', 'Mastercard', 1, '2024-11-30 14:55:00'),
('Swish', 'Swish', 1, '2024-11-02 11:20:00'),
('Kort', 'Visa', 1, '2024-11-04 15:35:00'),
('Kort', 'Mastercard', 1, '2024-11-06 10:50:00'),
('Faktura', 'Klarna', 1, '2024-11-08 13:15:00'),
('Kort', 'Visa', 1, '2024-11-10 12:40:00'),
('Kort', 'Mastercard', 1, '2024-11-12 09:55:00'),
('Swish', 'Swish', 1, '2024-11-19 14:20:00'),
('Kort', 'Visa', 1, '2024-11-21 11:35:00'),
('Kort', 'Mastercard', 1, '2024-11-23 15:50:00'),
('Avbetalning', 'Klarna', 1, '2024-11-25 10:10:00'),
('Kort', 'Visa', 1, '2024-11-26 13:45:00'),
('Kort', 'Mastercard', 1, '2024-11-27 12:30:00'),
('Swish', 'Swish', 1, '2024-11-28 16:05:00'),

-- DECEMBER (33 payments - CHRISTMAS)
('Kort', 'Visa', 1, '2024-12-01 10:40:00'),
('Kort', 'Mastercard', 1, '2024-12-02 14:25:00'),
('Swish', 'Swish', 1, '2024-12-03 11:50:00'),
('Kort', 'Visa', 1, '2024-12-04 15:30:00'),
('Kort', 'Mastercard', 1, '2024-12-05 09:15:00'),
('Faktura', 'Klarna', 1, '2024-12-06 13:40:00'),
('Kort', 'Visa', 1, '2024-12-07 12:10:00'),
('Kort', 'Mastercard', 1, '2024-12-08 16:55:00'),
('Swish', 'Swish', 1, '2024-12-09 10:20:00'),
('Kort', 'Visa', 1, '2024-12-10 14:35:00'),
('Kort', 'Mastercard', 1, '2024-12-11 11:45:00'),
('Avbetalning', 'Klarna', 1, '2024-12-12 09:25:00'),
('Kort', 'Visa', 1, '2024-12-13 15:10:00'),
('Kort', 'Mastercard', 1, '2024-12-14 12:50:00'),
('Swish', 'Swish', 1, '2024-12-15 13:20:00'),
('Kort', 'Visa', 1, '2024-12-16 10:05:00'),
('Kort', 'Mastercard', 1, '2024-12-17 14:40:00'),
('Faktura', 'Klarna', 1, '2024-12-18 11:55:00'),
('Kort', 'Visa', 1, '2024-12-19 16:15:00'),
('Kort', 'Mastercard', 1, '2024-12-20 10:30:00'),
('Swish', 'Swish', 1, '2024-12-21 13:50:00'),
('Kort', 'Visa', 1, '2024-12-22 12:20:00'),
('Kort', 'Mastercard', 1, '2024-12-23 15:45:00'),
('Avbetalning', 'Klarna', 1, '2024-12-24 09:10:00'),
('Kort', 'Visa', 1, '2024-12-21 14:35:00'),
('Kort', 'Mastercard', 1, '2024-12-22 11:50:00'),
('Swish', 'Swish', 1, '2024-12-23 10:15:00'),
('Kort', 'Visa', 1, '2024-12-24 16:40:00'),
('Kort', 'Mastercard', 1, '2024-12-25 12:05:00'),
('Faktura', 'Klarna', 1, '2024-12-26 13:30:00'),
('Kort', 'Visa', 1, '2024-12-27 10:50:00'),
('Kort', 'Mastercard', 1, '2024-12-28 14:15:00'),
('Swish', 'Swish', 1, '2024-12-29 11:35:00');


INSERT INTO dbo.[Order] (PaymentID, CustomerID, OrderDate, OrderStatus, OrderTotalAmount) VALUES
-- JANUARY (20 orders)
(1, 1, '2024-01-05 09:15:30', 'Levererat', 24999.00),
(2, 2, '2024-01-08 14:45:22', 'Levererat', 8999.00),
(3, 3, '2024-01-10 11:32:15', 'Bearbetas', 12999.00),
(4, 4, '2024-01-12 19:28:44', 'Levererat', 5999.00),
(5, 5, '2024-01-15 08:22:10', 'Skickat', 9999.00),
(6, 6, '2024-01-18 16:54:33', 'Levererat', 3999.00),
(7, 7, '2024-01-20 13:11:18', 'Bearbetas', 4999.00),
(8, 8, '2024-01-22 10:47:25', 'Levererat', 7999.00),
(9, 9, '2024-01-24 21:35:52', 'Skickat', 1999.00),
(10, 10, '2024-01-26 15:19:07', 'Levererat', 6999.00),
(11, 11, '2024-01-27 09:44:41', 'Väntande', 2999.00),
(12, 12, '2024-01-28 17:26:14', 'Levererat', 4499.00),
(13, 1, '2024-01-29 12:03:56', 'Bearbetas', 11999.00),
(14, 13, '2024-01-30 20:18:29', 'Levererat', 3699.00),
(15, 14, '2024-01-02 08:56:12', 'Levererat', 5999.00),
(16, 15, '2024-01-03 14:33:48', 'Skickat', 2499.00),
(17, 16, '2024-01-04 10:12:36', 'Levererat', 999.00),
(18, 17, '2024-01-06 18:47:19', 'Bearbetas', 8999.00),
(19, 18, '2024-01-07 11:25:05', 'Levererat', 4999.00),
(20, 19, '2024-01-09 22:14:38', 'Avbrutet', 1999.00),

-- FEBRUARY (12 orders)
(21, 20, '2024-02-01 09:30:12', 'Levererat', 3999.00),
(22, 21, '2024-02-05 15:48:33', 'Levererat', 5999.00),
(23, 22, '2024-02-08 11:17:44', 'Skickat', 7999.00),
(24, 23, '2024-02-10 19:52:21', 'Bearbetas', 2999.00),
(25, 24, '2024-02-12 08:41:15', 'Levererat', 4499.00),
(26, 1, '2024-02-15 16:25:38', 'Levererat', 6999.00),
(27, 25, '2024-02-18 12:36:49', 'Skickat', 1999.00),
(28, 26, '2024-02-20 20:19:24', 'Levererat', 9999.00),
(29, 27, '2024-02-22 10:08:57', 'Bearbetas', 3699.00),
(30, 28, '2024-02-24 14:53:12', 'Levererat', 2499.00),
(31, 29, '2024-02-26 21:42:33', 'Väntande', 5999.00),
(32, 30, '2024-02-28 09:19:44', 'Levererat', 4999.00),

-- MARCH (15 orders)
(33, 2, '2024-03-02 13:27:16', 'Levererat', 8999.00),
(34, 31, '2024-03-05 10:15:29', 'Levererat', 3999.00),
(35, 32, '2024-03-08 17:49:38', 'Bearbetas', 5999.00),
(36, 33, '2024-03-10 08:34:52', 'Levererat', 12999.00),
(37, 34, '2024-03-12 15:22:11', 'Skickat', 4999.00),
(38, 35, '2024-03-15 11:56:44', 'Levererat', 6999.00),
(39, 36, '2024-03-18 20:11:23', 'Bearbetas', 2999.00),
(40, 37, '2024-03-20 09:48:35', 'Levererat', 9999.00),
(41, 38, '2024-03-22 16:33:19', 'Skickat', 3699.00),
(42, 39, '2024-03-24 12:07:46', 'Levererat', 11999.00),
(43, 40, '2024-03-26 19:44:12', 'Väntande', 1999.00),
(44, 3, '2024-03-28 10:21:53', 'Levererat', 7999.00),
(45, 41, '2024-03-29 14:36:28', 'Bearbetas', 5999.00),
(46, 42, '2024-03-01 08:12:41', 'Levererat', 4499.00),
(47, 43, '2024-03-03 18:58:14', 'Levererat', 9999.00),

-- APRIL (15 orders)
(48, 44, '2024-04-02 11:43:27', 'Levererat', 2999.00),
(49, 45, '2024-04-05 09:26:35', 'Levererat', 6999.00),
(50, 46, '2024-04-08 15:39:18', 'Skickat', 4999.00),
(51, 47, '2024-04-10 20:55:42', 'Bearbetas', 11999.00),
(52, 48, '2024-04-12 10:14:11', 'Levererat', 3999.00),
(53, 49, '2024-04-15 16:47:29', 'Levererat', 5999.00),
(54, 50, '2024-04-18 12:32:53', 'Skickat', 8999.00),
(55, 4, '2024-04-20 08:19:36', 'Levererat', 7999.00),
(56, 5, '2024-04-22 17:04:15', 'Bearbetas', 2499.00),
(57, 51, '2024-04-24 13:50:44', 'Levererat', 4999.00),
(58, 52, '2024-04-26 21:23:18', 'Väntande', 9999.00),
(59, 53, '2024-04-27 09:11:52', 'Levererat', 3699.00),
(60, 54, '2024-04-28 14:45:33', 'Levererat', 1999.00),
(61, 1, '2024-04-29 11:08:19', 'Levererat', 5999.00),
(62, 2, '2024-04-30 19:37:47', 'Skickat', 6999.00),

-- MAY (15 orders)
(63, 3, '2024-05-02 10:22:14', 'Levererat', 8999.00),
(64, 6, '2024-05-05 16:11:38', 'Levererat', 4999.00),
(65, 7, '2024-05-08 12:49:25', 'Bearbetas', 2999.00),
(66, 8, '2024-05-10 08:36:52', 'Levererat', 11999.00),
(67, 9, '2024-05-12 15:28:19', 'Skickat', 3999.00),
(68, 10, '2024-05-15 20:44:33', 'Levererat', 5999.00),
(69, 11, '2024-05-18 09:17:46', 'Bearbetas', 9999.00),
(70, 12, '2024-05-20 17:02:11', 'Levererat', 7999.00),
(71, 13, '2024-05-22 13:31:44', 'Skickat', 2499.00),
(72, 14, '2024-05-24 10:55:28', 'Levererat', 4999.00),
(73, 15, '2024-05-26 18:20:19', 'Väntande', 6999.00),
(74, 16, '2024-05-27 11:44:52', 'Levererat', 3699.00),
(75, 17, '2024-05-28 14:12:37', 'Levererat', 1999.00),
(76, 18, '2024-05-29 21:33:15', 'Levererat', 5999.00),
(77, 19, '2024-05-30 09:48:23', 'Skickat', 8999.00),

-- JUNE (10 orders)
(78, 20, '2024-06-02 15:17:44', 'Levererat', 3999.00),
(79, 21, '2024-06-05 10:39:12', 'Levererat', 6999.00),
(80, 22, '2024-06-08 18:52:37', 'Skickat', 4999.00),
(81, 23, '2024-06-10 12:26:19', 'Bearbetas', 2999.00),
(82, 24, '2024-06-15 08:44:53', 'Levererat', 11999.00),
(83, 25, '2024-06-18 16:15:24', 'Levererat', 5999.00),
(84, 26, '2024-06-20 11:33:46', 'Bearbetas', 8999.00),
(85, 27, '2024-06-22 20:07:18', 'Levererat', 3699.00),
(86, 28, '2024-06-25 13:42:29', 'Skickat', 1999.00),
(87, 29, '2024-06-28 09:19:51', 'Levererat', 7999.00),

-- JULY (10 orders)
(88, 30, '2024-07-02 17:35:22', 'Levererat', 2999.00),
(89, 31, '2024-07-05 10:48:14', 'Levererat', 4999.00),
(90, 1, '2024-07-08 14:21:38', 'Bearbetas', 9999.00),
(91, 32, '2024-07-10 19:11:45', 'Levererat', 6999.00),
(92, 33, '2024-07-15 08:53:19', 'Skickat', 3999.00),
(93, 34, '2024-07-18 15:26:32', 'Levererat', 5999.00),
(94, 35, '2024-07-20 11:39:47', 'Bearbetas', 11999.00),
(95, 36, '2024-07-22 20:14:23', 'Levererat', 8999.00),
(96, 37, '2024-07-25 12:42:16', 'Väntande', 1999.00),
(97, 38, '2024-07-28 09:27:51', 'Levererat', 7999.00),

-- AUGUST (13 orders)
(98, 39, '2024-08-01 16:44:38', 'Levererat', 4999.00),
(99, 40, '2024-08-03 11:12:25', 'Levererat', 2999.00),
(100, 41, '2024-08-05 18:37:12', 'Skickat', 6999.00),
(101, 42, '2024-08-08 10:19:44', 'Bearbetas', 9999.00),
(102, 43, '2024-08-10 15:51:33', 'Levererat', 3699.00),
(103, 44, '2024-08-12 09:26:18', 'Levererat', 5999.00),
(104, 45, '2024-08-15 20:48:52', 'Bearbetas', 11999.00),
(105, 46, '2024-08-18 13:17:29', 'Levererat', 8999.00),
(106, 47, '2024-08-20 08:35:14', 'Skickat', 1999.00),
(107, 48, '2024-08-22 17:22:41', 'Levererat', 7999.00),
(108, 1, '2024-08-24 12:09:37', 'Väntande', 4999.00),
(109, 49, '2024-08-26 14:44:19', 'Levererat', 3999.00),
(110, 50, '2024-08-28 10:31:52', 'Levererat', 5999.00),

-- SEPTEMBER (16 orders)
(111, 51, '2024-09-02 09:15:23', 'Levererat', 12999.00),
(112, 52, '2024-09-04 16:48:47', 'Levererat', 8999.00),
(113, 53, '2024-09-06 12:31:15', 'Bearbetas', 2999.00),
(114, 54, '2024-09-08 20:44:28', 'Levererat', 6999.00),
(115, 1, '2024-09-10 10:19:52', 'Skickat', 4999.00),
(116, 2, '2024-09-12 15:36:11', 'Levererat', 9999.00),
(117, 3, '2024-09-14 08:22:39', 'Bearbetas', 3699.00),
(118, 4, '2024-09-16 18:11:44', 'Levererat', 11999.00),
(119, 5, '2024-09-18 13:47:33', 'Levererat', 5999.00),
(120, 6, '2024-09-20 11:25:19', 'Skickat', 8999.00),
(121, 7, '2024-09-22 21:13:56', 'Väntande', 1999.00),
(122, 8, '2024-09-24 09:44:27', 'Levererat', 7999.00),
(123, 9, '2024-09-26 17:32:14', 'Levererat', 4999.00),
(124, 10, '2024-09-27 12:18:38', 'Levererat', 2999.00),
(125, 11, '2024-09-28 14:55:22', 'Bearbetas', 6999.00),
(126, 12, '2024-09-29 10:03:47', 'Levererat', 3999.00),

-- OCTOBER (16 orders)
(127, 13, '2024-10-01 15:39:12', 'Levererat', 5999.00),
(128, 14, '2024-10-03 11:17:35', 'Levererat', 11999.00),
(129, 15, '2024-10-05 19:44:58', 'Bearbetas', 8999.00),
(130, 16, '2024-10-07 09:26:21', 'Levererat', 3699.00),
(131, 17, '2024-10-09 16:52:44', 'Skickat', 1999.00),
(132, 18, '2024-10-11 13:08:19', 'Levererat', 7999.00),
(133, 19, '2024-10-13 20:31:37', 'Levererat', 4999.00),
(134, 20, '2024-10-15 10:47:22', 'Bearbetas', 2999.00),
(135, 21, '2024-10-17 14:23:51', 'Levererat', 6999.00),
(136, 22, '2024-10-19 08:36:18', 'Väntande', 3999.00),
(137, 23, '2024-10-21 17:19:44', 'Levererat', 5999.00),
(138, 24, '2024-10-23 12:42:33', 'Skickat', 9999.00),
(139, 25, '2024-10-25 21:15:27', 'Levererat', 12999.00),
(140, 26, '2024-10-27 09:53:14', 'Levererat', 8999.00),
(141, 27, '2024-10-29 15:28:46', 'Bearbetas', 2999.00),
(142, 1, '2024-10-30 11:04:35', 'Levererat', 6999.00),

-- NOVEMBER (37 orders - BLACK FRIDAY)
(143, 28, '2024-11-01 10:12:44', 'Levererat', 4999.00),
(144, 29, '2024-11-03 16:38:21', 'Levererat', 11999.00),
(145, 30, '2024-11-05 13:25:55', 'Bearbetas', 8999.00),
(146, 31, '2024-11-07 20:47:18', 'Levererat', 3699.00),
(147, 32, '2024-11-09 09:31:29', 'Skickat', 1999.00),
(148, 33, '2024-11-11 17:14:36', 'Levererat', 7999.00),
(149, 34, '2024-11-13 11:49:52', 'Levererat', 4999.00),
(150, 35, '2024-11-14 14:22:17', 'Bearbetas', 2999.00),
(151, 2, '2024-11-15 08:44:33', 'Levererat', 6999.00),
(152, 36, '2024-11-16 18:36:14', 'Väntande', 3999.00),
(153, 37, '2024-11-17 12:11:48', 'Levererat', 5999.00),
(154, 38, '2024-11-18 21:27:39', 'Skickat', 9999.00),
(155, 39, '2024-11-19 10:13:22', 'Levererat', 12999.00),
(156, 40, '2024-11-20 15:44:51', 'Levererat', 8999.00),
(157, 41, '2024-11-21 09:19:37', 'Bearbetas', 2999.00),
(158, 42, '2024-11-22 17:02:14', 'Levererat', 6999.00),
(159, 43, '2024-11-23 13:35:48', 'Levererat', 4999.00),
(160, 44, '2024-11-24 20:58:25', 'Skickat', 11999.00),
(161, 3, '2024-11-25 08:26:19', 'Levererat', 8999.00),
(162, 45, '2024-11-26 14:51:42', 'Bearbetas', 3699.00),
(163, 46, '2024-11-27 11:38:57', 'Levererat', 1999.00),
(164, 47, '2024-11-28 19:12:33', 'Väntande', 7999.00),
(165, 48, '2024-11-29 12:44:16', 'Levererat', 4999.00),
(166, 49, '2024-11-30 10:17:29', 'Levererat', 2999.00),
(167, 4, '2024-11-02 16:23:38', 'Bearbetas', 6999.00),
(168, 50, '2024-11-04 09:47:52', 'Levererat', 3999.00),
(169, 51, '2024-11-06 17:15:44', 'Levererat', 5999.00),
(170, 52, '2024-11-08 13:09:21', 'Skickat', 9999.00),
(171, 53, '2024-11-10 20:32:15', 'Levererat', 12999.00),
(172, 54, '2024-11-12 10:58:38', 'Levererat', 8999.00),
(173, 5, '2024-11-19 15:41:44', 'Bearbetas', 2999.00),
(174, 1, '2024-11-21 11:26:33', 'Levererat', 6999.00),
(175, 2, '2024-11-23 18:19:51', 'Levererat', 4999.00),
(176, 6, '2024-11-25 09:35:28', 'Skickat', 11999.00),
(177, 7, '2024-11-26 16:48:14', 'Levererat', 3699.00),
(178, 8, '2024-11-27 12:12:47', 'Väntande', 1999.00),
(179, 9, '2024-11-28 20:04:32', 'Levererat', 7999.00),
(180, 10, '2024-11-29 14:39:19', 'Levererat', 5999.00),

-- DECEMBER (33 orders - CHRISTMAS)
(181, 11, '2024-12-01 10:21:15', 'Levererat', 4999.00),
(182, 12, '2024-12-02 15:47:38', 'Levererat', 2999.00),
(183, 13, '2024-12-03 09:34:22', 'Bearbetas', 6999.00),
(184, 14, '2024-12-04 17:12:51', 'Levererat', 3999.00),
(185, 15, '2024-12-05 13:26:44', 'Skickat', 5999.00),
(186, 16, '2024-12-06 20:55:17', 'Levererat', 9999.00),
(187, 17, '2024-12-07 08:19:33', 'Levererat', 12999.00),
(188, 18, '2024-12-08 16:43:29', 'Bearbetas', 8999.00),
(189, 19, '2024-12-09 11:37:45', 'Levererat', 2999.00),
(190, 20, '2024-12-10 19:18:52', 'Väntande', 6999.00),
(191, 21, '2024-12-11 12:52:14', 'Levererat', 4999.00),
(192, 22, '2024-12-12 21:14:36', 'Skickat', 11999.00),
(193, 23, '2024-12-13 10:39:28', 'Levererat', 3699.00),
(194, 24, '2024-12-14 14:05:47', 'Levererat', 1999.00),
(195, 25, '2024-12-15 18:31:19', 'Levererat', 7999.00),
(196, 26, '2024-12-16 09:44:23', 'Bearbetas', 5999.00),
(197, 27, '2024-12-17 17:19:11', 'Levererat', 8999.00),
(198, 28, '2024-12-18 13:28:47', 'Levererat', 4999.00),
(199, 29, '2024-12-19 20:12:33', 'Skickat', 2999.00),
(200, 30, '2024-12-20 11:21:18', 'Levererat', 6999.00),
(201, 1, '2024-12-21 15:47:39', 'Väntande', 3999.00),
(202, 31, '2024-12-22 08:33:26', 'Levererat', 5999.00),
(203, 32, '2024-12-23 16:18:44', 'Levererat', 9999.00),
(204, 33, '2024-12-24 21:26:15', 'Bearbetas', 11999.00),
(205, 34, '2024-12-21 10:14:52', 'Levererat', 8999.00),
(206, 35, '2024-12-22 14:39:31', 'Levererat', 2999.00),
(207, 36, '2024-12-23 12:11:47', 'Skickat', 6999.00),
(208, 37, '2024-12-24 19:47:28', 'Levererat', 4999.00),
(209, 38, '2024-12-25 09:55:33', 'Väntande', 11999.00),
(210, 39, '2024-12-26 17:32:19', 'Levererat', 3699.00),
(211, 40, '2024-12-27 11:08:41', 'Levererat', 1999.00),
(212, 41, '2024-12-28 20:24:14', 'Levererat', 7999.00),
(213, 2, '2024-12-29 13:49:36', 'Bearbetas', 5999.00),
(214, 3, '2024-12-30 10:17:52', 'Levererat', 8999.00);



USE NetOnNet
GO

INSERT INTO dbo.OrderItem (OrderID, ProductID, LineTotal, DiscountApplied) VALUES
-- Order 1 (2 items)
(1, 1, 12999.00, 0.00),        -- 12999 - 0 = 12999
(1, 38, 1299.00, 0.00),         -- 1299 - 0 = 1299
-- OrderTotal = 14298

-- Order 2 (2 items)
(2, 5, 9999.00, 0.00),          -- 9999 - 0 = 9999
(2, 88, 599.00, 0.00),          -- 599 - 0 = 599
-- OrderTotal = 10598

-- Order 3 (3 items)
(3, 3, 13699.00, 1300.00),     -- 14999 - 1300 = 13699
(3, 15, 11999.00, 0.00),       -- 11999 - 0 = 11999
(3, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 33797

-- Order 4 (1 item)
(4, 10, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 11999

-- Order 5 (2 items)
(5, 2, 7199.00, 1800.00),      -- 8999 - 1800 = 7199
(5, 39, 9999.00, 0.00),        -- 9999 - 0 = 9999
-- OrderTotal = 17198

-- Order 6 (1 item)
(6, 18, 5999.00, 0.00),         -- 5999 - 0 = 5999
-- OrderTotal = 5999

-- Order 7 (2 items)
(7, 20, 3499.00, 500.00),       -- 3999 - 500 = 3499
(7, 87, 299.00, 0.00),          -- 299 - 0 = 299
-- OrderTotal = 3798

-- Order 8 (1 item)
(8, 22, 5999.00, 0.00),         -- 5999 - 0 = 5999
-- OrderTotal = 5999

-- Order 9 (2 items)
(9, 89, 399.00, 0.00),          -- 399 - 0 = 399
(9, 54, 999.00, 0.00),          -- 999 - 0 = 999
-- OrderTotal = 1398

-- Order 10 (1 item)
(10, 15, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 11999

-- Order 11 (2 items)
(11, 24, 1399.00, 300.00),      -- 1699 - 300 = 1399
(11, 71, 8999.00, 0.00),        -- 8999 - 0 = 8999
-- OrderTotal = 10398

-- Order 12 (1 item)
(12, 14, 12999.00, 0.00),       -- 12999 - 0 = 12999
-- OrderTotal = 12999

-- Order 13 (2 items)
(13, 4, 7499.00, 1500.00),     -- 8999 - 1500 = 7499
(13, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 11198

-- Order 14 (1 item)
(14, 26, 899.00, 0.00),         -- 899 - 0 = 899
-- OrderTotal = 899

-- Order 15 (2 items)
(15, 31, 3399.00, 600.00),     -- 3999 - 600 = 3399
(15, 62, 5999.00, 0.00),        -- 5999 - 0 = 5999
-- OrderTotal = 9398

-- Order 16 (1 item)
(16, 88, 599.00, 0.00),          -- 599 - 0 = 599
-- OrderTotal = 599

-- Order 17 (2 items)
(17, 6, 14999.00, 0.00),        -- 14999 - 0 = 14999
(17, 93, 299.00, 0.00),         -- 299 - 0 = 299
-- OrderTotal = 15298

-- Order 18 (1 item)
(18, 20, 3999.00, 0.00),        -- 3999 - 0 = 3999
-- OrderTotal = 3999

-- Order 19 (2 items)
(19, 89, 399.00, 0.00),         -- 399 - 0 = 399
(19, 81, 1999.00, 0.00),       -- 1999 - 0 = 1999
-- OrderTotal = 2398

-- Order 20 (1 item)
(20, 39, 9999.00, 0.00),        -- 9999 - 0 = 9999
-- OrderTotal = 9999

-- Order 21 (2 items)
(21, 30, 1499.00, 0.00),        -- 1499 - 0 = 1499
(21, 73, 18999.00, 0.00),      -- 18999 - 0 = 18999
-- OrderTotal = 20498

-- Order 22 (2 items)
(22, 24, 899.00, 800.00),       -- 1699 - 800 = 899
(22, 12, 4999.00, 0.00),       -- 4999 - 0 = 4999
-- OrderTotal = 5898

-- Order 23 (1 item)
(23, 27, 799.00, 0.00),         -- 799 - 0 = 799
-- OrderTotal = 799

-- Order 24 (2 items)
(24, 16, 2499.00, 0.00),        -- 2499 - 0 = 2499
(24, 56, 14499.00, 1000.00),   -- 15499 - 1000 = 14499
-- OrderTotal = 16998

-- Order 25 (1 item)
(25, 2, 8299.00, 700.00),       -- 8999 - 700 = 8299
-- OrderTotal = 8299

-- Order 26 (2 items)
(26, 48, 1999.00, 0.00),        -- 1999 - 0 = 1999
(26, 85, 199.00, 0.00),         -- 199 - 0 = 199
-- OrderTotal = 2198

-- Order 27 (2 items)
(27, 60, 3999.00, 0.00),        -- 3999 - 0 = 3999
(27, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 5298

-- Order 28 (1 item)
(28, 35, 1999.00, 0.00),        -- 1999 - 0 = 1999
-- OrderTotal = 1999

-- Order 29 (2 items)
(29, 12, 4999.00, 0.00),        -- 4999 - 0 = 4999
(29, 78, 4999.00, 0.00),        -- 4999 - 0 = 4999
-- OrderTotal = 9998

-- Order 30 (2 items)
(30, 40, 11499.00, 500.00),     -- 11999 - 500 = 11499
(30, 18, 5999.00, 0.00),        -- 5999 - 0 = 5999
-- OrderTotal = 17498

-- Order 31 (1 item)
(31, 9, 9999.00, 0.00),         -- 9999 - 0 = 9999
-- OrderTotal = 9999

-- Order 32 (2 items)
(32, 28, 2499.00, 0.00),        -- 2499 - 0 = 2499
(32, 90, 449.00, 0.00),         -- 449 - 0 = 449
-- OrderTotal = 2948

-- Order 33 (2 items)
(33, 65, 13699.00, 1300.00),    -- 14999 - 1300 = 13699
(33, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 17398

-- Order 34 (1 item)
(34, 29, 1999.00, 0.00),        -- 1999 - 0 = 1999
-- OrderTotal = 1999

-- Order 35 (2 items)
(35, 42, 4999.00, 0.00),        -- 4999 - 0 = 4999
(35, 72, 19199.00, 800.00),     -- 19999 - 800 = 19199
-- OrderTotal = 24198

-- Order 36 (2 items)
(36, 19, 5199.00, 300.00),      -- 5499 - 300 = 5199
(36, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 13298

-- Order 37 (1 item)
(37, 70, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 11999

-- Order 38 (2 items)
(38, 25, 999.00, 0.00),         -- 999 - 0 = 999
(38, 87, 299.00, 0.00),         -- 299 - 0 = 299
-- OrderTotal = 1298

-- Order 39 (2 items)
(39, 56, 14499.00, 1000.00),   -- 15499 - 1000 = 14499
(39, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 15798

-- Order 40 (1 item)
(40, 8, 13499.00, 0.00),        -- 13499 - 0 = 13499
-- OrderTotal = 13499

-- Order 41 (2 items)
(41, 90, 449.00, 0.00),          -- 449 - 0 = 449
(41, 30, 1499.00, 0.00),        -- 1499 - 0 = 1499
-- OrderTotal = 1948

-- Order 42 (2 items)
(42, 21, 4499.00, 500.00),      -- 4999 - 500 = 4499
(42, 62, 5999.00, 0.00),        -- 5999 - 0 = 5999
-- OrderTotal = 10498

-- Order 43 (1 item)
(43, 17, 4999.00, 0.00),        -- 4999 - 0 = 4999
-- OrderTotal = 4999

-- Order 44 (2 items)
(44, 50, 2999.00, 700.00),      -- 3699 - 700 = 2999
(44, 81, 1999.00, 0.00),        -- 1999 - 0 = 1999
-- OrderTotal = 4998

-- Order 45 (2 items)
(45, 3, 14999.00, 0.00),        -- 14999 - 0 = 14999
(45, 72, 19199.00, 800.00),     -- 19999 - 800 = 19199
-- OrderTotal = 34198

-- Order 46 (2 items)
(46, 85, 199.00, 0.00),         -- 199 - 0 = 199
(46, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 8298

-- Order 47 (1 item)
(47, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 8099

-- Order 48 (1 item)
(48, 72, 19999.00, 0.00),       -- 19999 - 0 = 19999
-- OrderTotal = 19999

-- Order 49 (2 items)
(49, 11, 8499.00, 2500.00),     -- 10999 - 2500 = 8499
(49, 80, 6999.00, 0.00),        -- 6999 - 0 = 6999
-- OrderTotal = 15498

-- Order 50 (1 item)
(50, 52, 4999.00, 0.00),        -- 4999 - 0 = 4999
-- OrderTotal = 4999

-- Order 51 (2 items)
(51, 77, 14499.00, 1500.00),    -- 15999 - 1500 = 14499
(51, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 15798

-- Order 52 (1 item)
(52, 34, 3999.00, 0.00),        -- 3999 - 0 = 3999
-- OrderTotal = 3999

-- Order 53 (2 items)
(53, 62, 5999.00, 0.00),        -- 5999 - 0 = 5999
(53, 15, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 17998

-- Order 54 (2 items)
(54, 91, 3999.00, 300.00),      -- 699 - 300 = 399?? ERROR in original - should be 699, not 3999
-- Wait, Product 91 = 699, Product 50 = 3699
(54, 91, 399.00, 300.00),       -- 699 - 300 = 399
(54, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 4098

-- Order 55 (1 item)
(55, 41, 7999.00, 0.00),        -- 7999 - 0 = 7999
-- OrderTotal = 7999

-- Order 56 (2 items)
(56, 13, 4199.00, 300.00),      -- 4499 - 300 = 4199
(56, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 16198

-- Order 57 (1 item)
(57, 80, 6999.00, 0.00),        -- 6999 - 0 = 6999
-- OrderTotal = 6999

-- Order 58 (2 items)
(58, 23, 1999.00, 0.00),         -- 1999 - 0 = 1999
(58, 85, 199.00, 0.00),          -- 199 - 0 = 199
-- OrderTotal = 2198

-- Order 59 (2 items)
(59, 58, 9399.00, 600.00),      -- 9999 - 600 = 9399
(59, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 10698

-- Order 60 (1 item)
(60, 94, 49.00, 200.00),        -- 249 - 200 = 49
-- OrderTotal = 49

-- Order 61 (2 items)
(61, 7, 15999.00, 0.00),        -- 15999 - 0 = 15999
(61, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 24098

-- Order 62 (1 item)
(62, 47, 2999.00, 0.00),        -- 2999 - 0 = 2999
-- OrderTotal = 2999

-- Order 63 (2 items)
(63, 32, 199.00, 800.00),        -- 999 - 800 = 199
(63, 50, 3699.00, 0.00),        -- 3699 - 0 = 3699
-- OrderTotal = 3898

-- Order 64 (1 item)
(64, 51, 3499.00, 0.00),        -- 3499 - 0 = 3499
-- OrderTotal = 3499

-- Order 65 (2 items)
(65, 68, 799.00, 0.00),          -- 799 - 0 = 799
(65, 30, 1499.00, 0.00),        -- 1499 - 0 = 1499
-- OrderTotal = 2298

-- Order 66 (2 items)
(66, 38, 8999.00, 0.00),        -- 8999 - 0 = 8999
(66, 56, 15499.00, 0.00),       -- 15499 - 0 = 15499
-- OrderTotal = 24498

-- Order 67 (2 items)
(67, 76, 10999.00, 12000.00),   -- 22999 - 12000 = 10999
(67, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 12298

-- Order 68 (1 item)
(68, 22, 5099.00, 900.00),      -- 5999 - 900 = 5099
-- OrderTotal = 5099

-- Order 69 (2 items)
(69, 44, 12999.00, 0.00),       -- 12999 - 0 = 12999
(69, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 24998

-- Order 70 (2 items)
(70, 37, 199.00, 500.00),        -- 699 - 500 = 199
(70, 45, 8999.00, 0.00),        -- 8999 - 0 = 8999
-- OrderTotal = 9198

-- Order 71 (1 item)
(71, 81, 1999.00, 0.00),         -- 1999 - 0 = 1999
-- OrderTotal = 1999

-- Order 72 (2 items)
(72, 59, 10699.00, 1300.00),    -- 11999 - 1300 = 10699
(72, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 11998

-- Order 73 (1 item)
(73, 18, 5999.00, 0.00),         -- 5999 - 0 = 5999
-- OrderTotal = 5999

-- Order 74 (2 items)
(74, 26, 899.00, 0.00),          -- 899 - 0 = 899
(74, 30, 1499.00, 0.00),         -- 1499 - 0 = 1499
-- OrderTotal = 2398

-- Order 75 (2 items)
(75, 83, 199.00, 100.00),        -- 299 - 100 = 199
(75, 50, 3699.00, 0.00),         -- 3699 - 0 = 3699
-- OrderTotal = 3898

-- Order 76 (2 items)
(76, 5, 9399.00, 600.00),       -- 9999 - 600 = 9399
(76, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 17498

-- Order 77 (1 item)
(77, 49, 1499.00, 0.00),        -- 1499 - 0 = 1499
-- OrderTotal = 1499

-- Order 78 (2 items)
(78, 92, 199.00, 600.00),        -- 799 - 600 = 199
(78, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 1498

-- Order 79 (2 items)
(79, 33, 199.00, 1100.00),       -- 1299 - 1100 = 199
(79, 70, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 12198

-- Order 80 (1 item)
(80, 61, 399.00, 0.00),          -- 399 - 0 = 399
-- OrderTotal = 399

-- Order 81 (2 items)
(81, 20, 3299.00, 700.00),       -- 3999 - 700 = 3299
(81, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 11398

-- Order 82 (1 item)
(82, 73, 18999.00, 0.00),       -- 18999 - 0 = 18999
-- OrderTotal = 18999

-- Order 83 (2 items)
(83, 46, 6499.00, 500.00),       -- 6999 - 500 = 6499
(83, 30, 1499.00, 0.00),        -- 1499 - 0 = 1499
-- OrderTotal = 7998

-- Order 84 (2 items)
(84, 36, 1299.00, 0.00),         -- 1299 - 0 = 1299
(84, 70, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 13298

-- Order 85 (2 items)
(85, 69, 9399.00, 600.00),      -- 9999 - 600 = 9399
(85, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 10698

-- Order 86 (2 items)
(86, 84, 399.00, 300.00),       -- 699 - 300 = 399
(86, 45, 8999.00, 0.00),        -- 8999 - 0 = 8999
-- OrderTotal = 9398

-- Order 87 (1 item)
(87, 16, 2499.00, 0.00),        -- 2499 - 0 = 2499
-- OrderTotal = 2499

-- Order 88 (2 items)
(88, 67, 699.00, 0.00),          -- 699 - 0 = 699
(88, 30, 1499.00, 0.00),        -- 1499 - 0 = 1499
-- OrderTotal = 2198

-- Order 89 (2 items)
(89, 30, 699.00, 800.00),       -- 1499 - 800 = 699
(89, 50, 3699.00, 0.00),        -- 3699 - 0 = 3699
-- OrderTotal = 4398

-- Order 90 (2 items)
(90, 86, 49.00, 200.00),        -- 249 - 200 = 49
(90, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 1348

-- Order 91 (1 item)
(91, 6, 14999.00, 0.00),        -- 14999 - 0 = 14999
-- OrderTotal = 14999

-- Order 92 (2 items)
(92, 43, 3699.00, 300.00),      -- 3999 - 300 = 3699
(92, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 15698

-- Order 93 (1 item)
(93, 57, 12999.00, 0.00),       -- 12999 - 0 = 12999
-- OrderTotal = 12999

-- Order 94 (2 items)
(94, 27, 799.00, 0.00),          -- 799 - 0 = 799
(94, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 8898

-- Order 95 (2 items)
(95, 72, 19399.00, 600.00),     -- 19999 - 600 = 19399
(95, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 20698

-- Order 96 (2 items)
(96, 12, 4099.00, 900.00),      -- 4999 - 900 = 4099
(96, 50, 3699.00, 0.00),        -- 3699 - 0 = 3699
-- OrderTotal = 7798

-- Order 97 (1 item)
(97, 53, 2999.00, 0.00),        -- 2999 - 0 = 2999
-- OrderTotal = 2999

-- Order 98 (2 items)
(98, 74, 24199.00, 800.00),     -- 24999 - 800 = 24199
(98, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 25698

-- Order 99 (2 items)
(99, 35, 1499.00, 500.00),      -- 1999 - 500 = 1499
(99, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 13498

-- Order 100 (1 item)
(100, 54, 999.00, 0.00),        -- 999 - 0 = 999
-- OrderTotal = 999

-- Order 101 (2 items)
(101, 15, 11299.00, 700.00),    -- 11999 - 700 = 11299
(101, 45, 8099.00, 900.00),    -- 8999 - 900 = 8099
-- OrderTotal = 19398

-- Order 102 (1 item)
(102, 45, 8099.00, 900.00),    -- 8999 - 900 = 8099
-- OrderTotal = 8099

-- Order 103 (2 items)
(103, 82, 399.00, 200.00),      -- 599 - 200 = 399
(103, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 1698

-- Order 104 (2 items)
(104, 28, 2499.00, 0.00),       -- 2499 - 0 = 2499
(104, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 6198

-- Order 105 (1 item)
(105, 40, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 11999

-- Order 106 (2 items)
(106, 55, 15399.00, 600.00),    -- 15999 - 600 = 15399
(106, 30, 1499.00, 0.00),      -- 1499 - 0 = 1499
-- OrderTotal = 16898

-- Order 107 (1 item)
(107, 9, 9999.00, 0.00),        -- 9999 - 0 = 9999
-- OrderTotal = 9999

-- Order 108 (2 items)
(108, 78, 4999.00, 0.00),       -- 4999 - 0 = 4999
(108, 70, 11999.00, 0.00),     -- 11999 - 0 = 11999
-- OrderTotal = 16998

-- Order 109 (2 items)
(109, 39, 9199.00, 800.00),     -- 9999 - 800 = 9199
(109, 45, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 17298

-- Order 110 (1 item)
(110, 87, 99.00, 200.00),       -- 299 - 200 = 99
-- OrderTotal = 99

-- Order 111 (2 items)
(111, 22, 5299.00, 700.00),      -- 5999 - 700 = 5299
(111, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 6598

-- Order 112 (1 item)
(112, 50, 3699.00, 0.00),        -- 3699 - 0 = 3699
-- OrderTotal = 3699

-- Order 113 (2 items)
(113, 14, 11999.00, 1000.00),   -- 12999 - 1000 = 11999
(113, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 13498

-- Order 114 (1 item)
(114, 31, 3999.00, 0.00),        -- 3999 - 0 = 3999
-- OrderTotal = 3999

-- Order 115 (2 items)
(115, 67, 699.00, 0.00),         -- 699 - 0 = 699
(115, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 12698

-- Order 116 (2 items)
(116, 41, 6999.00, 1000.00),     -- 7999 - 1000 = 6999
(116, 45, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 15098

-- Order 117 (1 item)
(117, 58, 9399.00, 600.00),     -- 9999 - 600 = 9399
-- OrderTotal = 9399

-- Order 118 (2 items)
(118, 24, 1699.00, 0.00),        -- 1699 - 0 = 1699
(118, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 2998

-- Order 119 (1 item)
(119, 71, 8999.00, 0.00),        -- 8999 - 0 = 8999
-- OrderTotal = 8999

-- Order 120 (2 items)
(120, 19, 4799.00, 700.00),     -- 5499 - 700 = 4799
(120, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 8498

-- Order 121 (2 items)
(121, 51, 3499.00, 0.00),       -- 3499 - 0 = 3499
(121, 70, 11999.00, 0.00),     -- 11999 - 0 = 11999
-- OrderTotal = 15498

-- Order 122 (2 items)
(122, 3, 6999.00, 8000.00),     -- 14999 - 8000 = 6999
(122, 45, 8099.00, 900.00),    -- 8999 - 900 = 8099
-- OrderTotal = 15098

-- Order 123 (1 item)
(123, 44, 12999.00, 0.00),      -- 12999 - 0 = 12999
-- OrderTotal = 12999

-- Order 124 (2 items)
(124, 75, 15999.00, 4000.00),   -- 19999 - 4000 = 15999
(124, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 17498

-- Order 125 (2 items)
(125, 29, 1999.00, 0.00),        -- 1999 - 0 = 1999
(125, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 3298

-- Order 126 (2 items)
(126, 62, 5099.00, 900.00),     -- 5999 - 900 = 5099
(126, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 8798

-- Order 127 (1 item)
(127, 11, 10999.00, 0.00),      -- 10999 - 0 = 10999
-- OrderTotal = 10999

-- Order 128 (2 items)
(128, 85, 199.00, 0.00),        -- 199 - 0 = 199
(128, 70, 11999.00, 0.00),     -- 11999 - 0 = 11999
-- OrderTotal = 12198

-- Order 129 (2 items)
(129, 21, 4499.00, 500.00),     -- 4999 - 500 = 4499
(129, 45, 8099.00, 900.00),    -- 8999 - 900 = 8099
-- OrderTotal = 12598

-- Order 130 (1 item)
(130, 36, 999.00, 300.00),      -- 1299 - 300 = 999
-- OrderTotal = 999

-- Order 131 (2 items)
(131, 54, 199.00, 800.00),       -- 999 - 800 = 199
(131, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 1498

-- Order 132 (1 item)
(132, 17, 4999.00, 0.00),        -- 4999 - 0 = 4999
-- OrderTotal = 4999

-- Order 133 (2 items)
(133, 68, 199.00, 600.00),       -- 799 - 600 = 199
(133, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 3898

-- Order 134 (1 item)
(134, 32, 999.00, 0.00),         -- 999 - 0 = 999
-- OrderTotal = 999

-- Order 135 (2 items)
(135, 79, 4799.00, 1200.00),    -- 5999 - 1200 = 4799
(135, 30, 1499.00, 0.00),      -- 1499 - 0 = 1499
-- OrderTotal = 6298

-- Order 136 (2 items)
(136, 47, 2399.00, 600.00),     -- 2999 - 600 = 2399
(136, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 14398

-- Order 137 (1 item)
(137, 10, 8499.00, 3500.00),    -- 11999 - 3500 = 8499
-- OrderTotal = 8499

-- Order 138 (2 items)
(138, 37, 699.00, 0.00),         -- 699 - 0 = 699
(138, 45, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 8798

-- Order 139 (2 items)
(139, 59, 10999.00, 1000.00),   -- 11999 - 1000 = 10999
(139, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 12298

-- Order 140 (1 item)
(140, 26, 899.00, 0.00),         -- 899 - 0 = 899
-- OrderTotal = 899

-- Order 141 (2 items)
(141, 81, 199.00, 1800.00),      -- 1999 - 1800 = 199
(141, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 3898

-- Order 142 (1 item)
(142, 18, 5999.00, 0.00),        -- 5999 - 0 = 5999
-- OrderTotal = 5999

-- Order 143 (2 items)
(143, 52, 4499.00, 500.00),      -- 4999 - 500 = 4499
(143, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 5998

-- Order 144 (2 items)
(144, 8, 9999.00, 3500.00),      -- 13499 - 3500 = 9999
(144, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 21998

-- Order 145 (2 items)
(145, 43, 3399.00, 600.00),     -- 3999 - 600 = 3399
(145, 45, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 11498

-- Order 146 (2 items)
(146, 65, 499.00, 100.00),       -- 599 - 100 = 499
(146, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 1798

-- Order 147 (1 item)
(147, 23, 1999.00, 0.00),        -- 1999 - 0 = 1999
-- OrderTotal = 1999

-- Order 148 (2 items)
(148, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
(148, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 15698

-- Order 149 (2 items)
(149, 15, 10999.00, 1000.00),    -- 11999 - 1000 = 10999
(149, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 12498

-- Order 150 (1 item)
(150, 34, 3299.00, 700.00),     -- 3999 - 700 = 3299
-- OrderTotal = 3299

-- Order 151 (2 items)
(151, 57, 12999.00, 0.00),       -- 12999 - 0 = 12999
(151, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 24998

-- Order 152 (2 items)
(152, 48, 1999.00, 0.00),        -- 1999 - 0 = 1999
(152, 45, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 10098

-- Order 153 (2 items)
(153, 20, 2799.00, 1200.00),    -- 3999 - 1200 = 2799
(153, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 4098

-- Order 154 (1 item)
(154, 39, 9399.00, 600.00),     -- 9999 - 600 = 9399
-- OrderTotal = 9399

-- Order 155 (2 items)
(155, 73, 18499.00, 500.00),    -- 18999 - 500 = 18499
(155, 50, 3699.00, 0.00),      -- 3699 - 0 = 3699
-- OrderTotal = 22198

-- Order 156 (2 items)
(156, 12, 4099.00, 900.00),     -- 4999 - 900 = 4099
(156, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 5598

-- Order 157 (1 item)
(157, 28, 2499.00, 0.00),       -- 2499 - 0 = 2499
-- OrderTotal = 2499

-- Order 158 (2 items)
(158, 66, 99.00, 300.00),        -- 399 - 300 = 99
(158, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 12098

-- Order 159 (2 items)
(159, 40, 11199.00, 800.00),   -- 11999 - 800 = 11199
(159, 45, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 19298

-- Order 160 (1 item)
(160, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 1499

-- Order 161 (2 items)
(161, 55, 15399.00, 600.00),    -- 15999 - 600 = 15399
(161, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 16698

-- Order 162 (2 items)
(162, 83, 199.00, 100.00),       -- 299 - 100 = 199
(162, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 3898

-- Order 163 (2 items)
(163, 16, 499.00, 2000.00),     -- 2499 - 2000 = 499
(163, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 1998

-- Order 164 (1 item)
(164, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 3699

-- Order 165 (2 items)
(165, 22, 5999.00, 0.00),       -- 5999 - 0 = 5999
(165, 70, 11999.00, 0.00),     -- 11999 - 0 = 11999
-- OrderTotal = 17998

-- Order 166 (2 items)
(166, 62, 4799.00, 1200.00),    -- 5999 - 1200 = 4799
(166, 45, 8099.00, 900.00),    -- 8999 - 900 = 8099
-- OrderTotal = 12898

-- Order 167 (1 item)
(167, 41, 6999.00, 1000.00),    -- 7999 - 1000 = 6999
-- OrderTotal = 6999

-- Order 168 (2 items)
(168, 14, 12699.00, 300.00),    -- 12999 - 300 = 12699
(168, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 13998

-- Order 169 (1 item)
(169, 74, 24299.00, 700.00),    -- 24999 - 700 = 24299
-- OrderTotal = 24299

-- Order 170 (2 items)
(170, 29, 1999.00, 0.00),        -- 1999 - 0 = 1999
(170, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 5698

-- Order 171 (2 items)
(171, 58, 9099.00, 900.00),      -- 9999 - 900 = 9099
(171, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 10598

-- Order 172 (1 item)
(172, 11, 10999.00, 0.00),      -- 10999 - 0 = 10999
-- OrderTotal = 10999

-- Order 173 (2 items)
(173, 44, 12399.00, 600.00),    -- 12999 - 600 = 12399
(173, 70, 11999.00, 0.00),     -- 11999 - 0 = 11999
-- OrderTotal = 24398

-- Order 174 (2 items)
(174, 36, 1299.00, 0.00),       -- 1299 - 0 = 1299
(174, 45, 8099.00, 900.00),    -- 8999 - 900 = 8099
-- OrderTotal = 9398

-- Order 175 (2 items)
(175, 52, 4499.00, 500.00),     -- 4999 - 500 = 4499
(175, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 5798

-- Order 176 (1 item)
(176, 71, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 8099

-- Order 177 (2 items)
(177, 25, 999.00, 0.00),         -- 999 - 0 = 999
(177, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 4698

-- Order 178 (2 items)
(178, 69, 9399.00, 600.00),     -- 9999 - 600 = 9399
(178, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 10898

-- Order 179 (1 item)
(179, 15, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 11999

-- Order 180 (2 items)
(180, 35, 1499.00, 500.00),      -- 1999 - 500 = 1499
(180, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 13498

-- Order 181 (2 items)
(181, 1, 12999.00, 0.00),        -- 12999 - 0 = 12999
(181, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 14298

-- Order 182 (1 item)
(182, 5, 9999.00, 0.00),         -- 9999 - 0 = 9999
-- OrderTotal = 9999

-- Order 183 (2 items)
(183, 3, 10699.00, 4300.00),     -- 14999 - 4300 = 10699
(183, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 14398

-- Order 184 (2 items)
(184, 10, 11999.00, 0.00),      -- 11999 - 0 = 11999
(184, 45, 8099.00, 900.00),    -- 8999 - 900 = 8099
-- OrderTotal = 20098

-- Order 185 (1 item)
(185, 2, 8999.00, 0.00),        -- 8999 - 0 = 8999
-- OrderTotal = 8999

-- Order 186 (2 items)
(186, 18, 5999.00, 0.00),       -- 5999 - 0 = 5999
(186, 30, 1499.00, 0.00),      -- 1499 - 0 = 1499
-- OrderTotal = 7498

-- Order 187 (2 items)
(187, 20, 2699.00, 1300.00),    -- 3999 - 1300 = 2699
(187, 70, 11999.00, 0.00),    -- 11999 - 0 = 11999
-- OrderTotal = 14698

-- Order 188 (1 item)
(188, 22, 5099.00, 900.00),     -- 5999 - 900 = 5099
-- OrderTotal = 5099

-- Order 189 (2 items)
(189, 87, 299.00, 0.00),         -- 299 - 0 = 299
(189, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 8398

-- Order 190 (1 item)
(190, 15, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 11999

-- Order 191 (2 items)
(191, 24, 1699.00, 0.00),        -- 1699 - 0 = 1699
(191, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 2998

-- Order 192 (2 items)
(192, 14, 12999.00, 0.00),       -- 12999 - 0 = 12999
(192, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 16698

-- Order 193 (1 item)
(193, 26, 899.00, 0.00),          -- 899 - 0 = 899
-- OrderTotal = 899

-- Order 194 (2 items)
(194, 88, 599.00, 0.00),          -- 599 - 0 = 599
(194, 30, 1499.00, 0.00),        -- 1499 - 0 = 1499
-- OrderTotal = 2098

-- Order 195 (2 items)
(195, 6, 14999.00, 0.00),         -- 14999 - 0 = 14999
(195, 70, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 26998

-- Order 196 (1 item)
(196, 20, 3999.00, 0.00),         -- 3999 - 0 = 3999
-- OrderTotal = 3999

-- Order 197 (2 items)
(197, 89, 399.00, 0.00),          -- 399 - 0 = 399
(197, 45, 8099.00, 900.00),      -- 8999 - 900 = 8099
-- OrderTotal = 8498

-- Order 198 (2 items)
(198, 39, 9999.00, 0.00),        -- 9999 - 0 = 9999
(198, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 11298

-- Order 199 (1 item)
(199, 30, 1499.00, 0.00),        -- 1499 - 0 = 1499
-- OrderTotal = 1499

-- Order 200 (2 items)
(200, 24, 1699.00, 0.00),        -- 1699 - 0 = 1699
(200, 50, 3699.00, 0.00),       -- 3699 - 0 = 3699
-- OrderTotal = 5398

-- Order 201 (2 items)
(201, 27, 799.00, 0.00),         -- 799 - 0 = 799
(201, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 12798

-- Order 202 (1 item)
(202, 16, 2499.00, 0.00),        -- 2499 - 0 = 2499
-- OrderTotal = 2499

-- Order 203 (2 items)
(203, 2, 8999.00, 0.00),         -- 8999 - 0 = 8999
(203, 45, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 17098

-- Order 204 (2 items)
(204, 48, 1999.00, 0.00),        -- 1999 - 0 = 1999
(204, 38, 1299.00, 0.00),        -- 1299 - 0 = 1299
-- OrderTotal = 3298

-- Order 205 (1 item)
(205, 60, 499.00, 0.00),         -- 499 - 0 = 499
-- OrderTotal = 499

-- Order 206 (2 items)
(206, 35, 1999.00, 0.00),        -- 1999 - 0 = 1999
(206, 30, 1499.00, 0.00),       -- 1499 - 0 = 1499
-- OrderTotal = 3498

-- Order 207 (2 items)
(207, 12, 4999.00, 0.00),        -- 4999 - 0 = 4999
(207, 70, 11999.00, 0.00),      -- 11999 - 0 = 11999
-- OrderTotal = 16998

-- Order 208 (1 item)
(208, 40, 11999.00, 0.00),       -- 11999 - 0 = 11999
-- OrderTotal = 11999

-- Order 209 (2 items)
(209, 9, 6999.00, 3000.00),      -- 9999 - 3000 = 6999
(209, 45, 8099.00, 900.00),     -- 8999 - 900 = 8099
-- OrderTotal = 15098

-- Order 210 (2 items)
(210, 28, 2499.00, 0.00),        -- 2499 - 0 = 2499
(210, 38, 1299.00, 0.00),       -- 1299 - 0 = 1299
-- OrderTotal = 3798

-- Order 211 (1 item)
(211, 67, 699.00, 0.00),         -- 699 - 0 = 699
-- OrderTotal = 699

-- Order 212 (2 items)
(212, 41, 4999.00, 3000.00),     -- 7999 - 3000 = 4999
(212, 50, 3699.00, 0.00);       -- 3699 - 0 = 3699
-- OrderTotal = 8698


INSERT INTO dbo.[Return] (OrderItemID, ReturnDate, Reason, [Status], ReturnedAmount, Notes) VALUES
(15, '2025-03-10', 'Defekt', 'Godkänd', 8999.00, 'Returnerad artikel'),
(42, '2025-03-15', 'StämmerInte', 'Initierad', 3499.00, 'Returnerad artikel'),
(67, '2025-03-20', 'Skadad', 'Slutförd', 14999.00, 'Returnerad artikel'),
(89, '2025-03-18', 'KundRequest', 'Godkänd', 1299.00, 'Returnerad artikel'),
(103, '2025-03-22', 'Övrigt', 'Avvisad', 599.00, 'Returnerad artikel'),
(128, '2025-03-25', 'Defekt', 'Initierad', 4999.00, 'Returnerad artikel'),
(145, '2025-03-28', 'StämmerInte', 'Godkänd', 6999.00, 'Returnerad artikel'),
(162, '2025-04-02', 'Skadad', 'Slutförd', 11999.00, 'Returnerad artikel'),
(178, '2025-04-05', 'Defekt', 'Godkänd', 7999.00, 'Returnerad artikel'),
(195, '2025-04-10', 'KundRequest', 'Initierad', 3999.00, 'Returnerad artikel'),
(210, '2025-04-12', 'StämmerInte', 'Avvisad', 1999.00, 'Returnerad artikel'),
(228, '2025-04-15', 'Övrigt', 'Godkänd', 9999.00, 'Returnerad artikel'),
(245, '2025-04-20', 'Defekt', 'Slutförd', 24999.00, 'Returnerad artikel'),
(262, '2025-04-22', 'Skadad', 'Initierad', 2499.00, 'Returnerad artikel'),
(278, '2025-04-25', 'KundRequest', 'Godkänd', 5999.00, 'Returnerad artikel'),
(295, '2025-05-01', 'StämmerInte', 'Slutförd', 749.00, 'Returnerad artikel'),
(312, '2025-05-05', 'Defekt', 'Godkänd', 14999.00, 'Returnerad artikel'),
(328, '2025-05-08', 'Övrigt', 'Initierad', 1299.00, 'Returnerad artikel'),
(345, '2025-05-12', 'Skadad', 'Avvisad', 3999.00, 'Returnerad artikel'),
(346, '2025-05-15', 'KundRequest', 'Slutförd', 12999.00, 'Returnerad artikel'),
(38, '2025-05-20', 'StämmerInte', 'Godkänd', 449.00, 'Returnerad artikel'),
(347, '2025-05-25', 'Defekt', 'Initierad', 6999.00, 'Returnerad artikel'),
(348, '2025-06-01', 'Övrigt', 'Slutförd', 9999.00, 'Returnerad artikel'),
(328, '2025-06-05', 'Skadad', 'Godkänd', 4999.00, 'Returnerad artikel'),
(315, '2025-06-10', 'KundRequest', 'Avvisad', 1499.00, 'Returnerad artikel'),
(311, '2025-06-15', 'StämmerInte', 'Initierad', 7999.00, 'Returnerad artikel'),
(310, '2025-06-20', 'Defekt', 'Slutförd', 34999.00, 'Returnerad artikel');

