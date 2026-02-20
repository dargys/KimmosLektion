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
    Price           DECIMAL(10, 2) NOT NULL,
    Cost            DECIMAL(10, 2) NOT NULL,
    Color           NVARCHAR (20) NULL,
    CreatedAt       DATETIME DEFAULT GETDATE() NOT NULL,
    ProductDetails  NVARCHAR(MAX) NULL,
    FOREIGN KEY (SubCategoryID) REFERENCES dbo.SubCategory(SubCategoryID),
    CONSTRAINT CK_ProductPrice CHECK (Price >= 0),
    CONSTRAINT CK_ProductCost CHECK (Cost >= 0),
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
    CreatedDate     DATETIME DEFAULT GETDATE() NOT NULL,
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
    OrderDate       DATETIME DEFAULT GETDATE() NOT NULL,
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
    [Status]      NVARCHAR(20) NOT NULL,
    Notes       NVARCHAR(MAX),
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


INSERT INTO dbo.[Product] (SubCategoryID, SKU, ProductName, Price, Cost, Color, CreatedAt, ProductDetails) VALUES

-- Laptops (SubCategoryID 1) - 3 products
(1, 'DATOR-001', 'Dell XPS 13 Plus', 12999.00, 7800.00, 'Silver', GETDATE(), '{"brand": "Dell", "model": "XPS 13 Plus", "warrantyYears": 2, "specifications": {"processor": "Intel Core i7-1365U", "ram": "16GB LPDDR5", "storage": "512GB NVMe SSD", "display": "13.4-inch OLED 2880x1920"}}'),
(1, 'DATOR-002', 'HP Pavilion 15', 8999.00, 5400.00, 'Charcoal', GETDATE(), '{"brand": "HP", "model": "Pavilion 15-eh1000", "warrantyYears": 1, "specifications": {"processor": "AMD Ryzen 5 7520U", "ram": "8GB DDR5", "storage": "256GB SSD", "display": "15.6-inch FHD 1920x1080"}}'),
(1, 'DATOR-003', 'Lenovo ThinkPad X1 Carbon', 14999.00, 9000.00, 'Black', GETDATE(), '{"brand": "Lenovo", "model": "ThinkPad X1 Carbon Gen 11", "warrantyYears": 3, "specifications": {"processor": "Intel Core i7-1365U", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "14-inch OLED 2880x1880"}}'),

-- Tablets (SubCategoryID 2) - 3 products
(2, 'DATOR-004', 'Apple iPad Air 5', 8999.00, 5400.00, 'Space Gray', GETDATE(), '{"brand": "Apple", "model": "iPad Air 5", "warrantyYears": 1, "specifications": {"processor": "Apple M1", "ram": "8GB", "storage": "256GB", "display": "10.9-inch Liquid Retina 2360x1640"}}'),
(2, 'DATOR-005', 'Samsung Galaxy Tab S8 Ultra', 9999.00, 6000.00, 'Gray', GETDATE(), '{"brand": "Samsung", "model": "Galaxy Tab S8 Ultra", "warrantyYears": 1, "specifications": {"processor": "Snapdragon 8 Gen 1", "ram": "12GB", "storage": "256GB", "display": "14.6-inch AMOLED 2960x1848"}}'),
(2, 'DATOR-006', 'Apple iPad Pro 12.9', 14999.00, 9000.00, 'Silver', GETDATE(), '{"brand": "Apple", "model": "iPad Pro 12.9-inch M2", "warrantyYears": 1, "specifications": {"processor": "Apple M2", "ram": "8GB", "storage": "256GB", "display": "12.9-inch Liquid Retina XDR 2732x2048"}}'),

-- Ultrabooks (SubCategoryID 3) - 3 products
(3, 'DATOR-007', 'MacBook Air M2', 15999.00, 9600.00, 'Space Gray', GETDATE(), '{"brand": "Apple", "model": "MacBook Air M2", "warrantyYears": 1, "specifications": {"processor": "Apple M2", "ram": "16GB Unified Memory", "storage": "512GB SSD", "display": "13.6-inch Liquid Retina 2560x1600"}}'),
(3, 'DATOR-008', 'Microsoft Surface Laptop 5', 13499.00, 8100.00, 'Platinum', GETDATE(), '{"brand": "Microsoft", "model": "Surface Laptop 5", "warrantyYears": 2, "specifications": {"processor": "Intel Core i7-1285U", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "13.5-inch PixelSense 2256x1504"}}'),
(3, 'DATOR-009', 'ASUS ZenBook 14', 9999.00, 6000.00, 'Icy Silver', GETDATE(), '{"brand": "ASUS", "model": "ZenBook 14 OLED", "warrantyYears": 2, "specifications": {"processor": "Intel Core i7-1360P", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "14-inch OLED 2880x1800"}}'),

-- 2-in-1 Devices (SubCategoryID 4) - 2 products
(4, 'DATOR-010', 'Microsoft Surface Pro 9', 11999.00, 7200.00, 'Platinum', GETDATE(), '{"brand": "Microsoft", "model": "Surface Pro 9", "warrantyYears": 1, "specifications": {"processor": "Intel Core i7-1255U", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "13-inch PixelSense 2880x1920"}}'),
(4, 'DATOR-011', 'Lenovo Yoga 9i', 10999.00, 6600.00, 'Oatmeal', GETDATE(), '{"brand": "Lenovo", "model": "Yoga 9i Gen 7", "warrantyYears": 2, "specifications": {"processor": "Intel Core i7-1360P", "ram": "16GB LPDDR5", "storage": "512GB SSD", "display": "14-inch IPS touchscreen 2240x1400"}}'),

-- ========================================
-- DATORKOMPONENTER (8 products)
-- ========================================

-- CPUs (SubCategoryID 5) - 2 products
(5, 'COMP-001', 'Intel Core i7-13700K', 4999.00, 3000.00, NULL, GETDATE(), '{"brand": "Intel", "model": "Core i7-13700K", "warrantyYears": 3, "specifications": {"cores": "16 cores (8P+8E)", "frequency": "3.4-5.4 GHz", "tdp": "125W", "socket": "LGA1700"}}'),
(5, 'COMP-002', 'AMD Ryzen 7 7700X', 4499.00, 2700.00, NULL, GETDATE(), '{"brand": "AMD", "model": "Ryzen 7 7700X", "warrantyYears": 3, "specifications": {"cores": "8 cores", "frequency": "4.5-5.4 GHz", "tdp": "105W", "socket": "AM5"}}'),

-- GPUs (SubCategoryID 6) - 2 products
(6, 'COMP-003', 'NVIDIA RTX 4080', 12999.00, 7800.00, NULL, GETDATE(), '{"brand": "NVIDIA", "model": "GeForce RTX 4080", "warrantyYears": 2, "specifications": {"memory": "16GB GDDR6X", "cuda_cores": "9728", "memory_bandwidth": "576 GB/s", "power_consumption": "320W"}}'),
(6, 'COMP-004', 'AMD RX 7900 XTX', 11999.00, 7200.00, NULL, GETDATE(), '{"brand": "AMD", "model": "Radeon RX 7900 XTX", "warrantyYears": 2, "specifications": {"memory": "24GB GDDR6", "stream_processors": "6144", "memory_bandwidth": "576 GB/s", "power_consumption": "420W"}}'),

-- RAM Memory (SubCategoryID 7) - 2 products
(7, 'COMP-005', 'Corsair Vengeance DDR5 32GB', 2499.00, 1500.00, NULL, GETDATE(), '{"brand": "Corsair", "model": "Vengeance DDR5", "warrantyYears": 1, "specifications": {"capacity": "32GB (2x16GB)", "speed": "5600MHz", "cas_latency": "CL36", "voltage": "1.25V"}}'),
(7, 'COMP-006', 'G.Skill Trident Z5 64GB', 4999.00, 3000.00, NULL, GETDATE(), '{"brand": "G.Skill", "model": "Trident Z5", "warrantyYears": 1, "specifications": {"capacity": "64GB (2x32GB)", "speed": "6000MHz", "cas_latency": "CL30", "voltage": "1.4V"}}'),

-- ========================================
-- GAMING (10 products)
-- ========================================

-- Consoles (SubCategoryID 10) - 3 products
(10, 'GAME-001', 'PlayStation 5', 5999.00, 3600.00, 'White', GETDATE(), '{"brand": "Sony", "model": "PlayStation 5", "warrantyYears": 2, "specifications": {"processor": "AMD Zen 2 8-core 3.5 GHz", "memory": "16GB GDDR6", "storage": "825GB SSD", "resolution": "Up to 4K 120fps"}}'),
(10, 'GAME-002', 'Xbox Series X', 5499.00, 3300.00, 'Black', GETDATE(), '{"brand": "Microsoft", "model": "Xbox Series X", "warrantyYears": 2, "specifications": {"processor": "AMD Zen 2 8-core 3.8 GHz", "memory": "16GB GDDR6", "storage": "1TB SSD", "resolution": "Up to 4K 120fps"}}'),
(10, 'GAME-003', 'Nintendo Switch OLED', 3999.00, 2400.00, 'White', GETDATE(), '{"brand": "Nintendo", "model": "Switch OLED Model", "warrantyYears": 1, "specifications": {"processor": "NVIDIA Tegra X1", "memory": "4GB LPDDR4", "storage": "64GB", "display": "7-inch OLED 1280x720"}}'),

-- Gaming Monitors (SubCategoryID 11) - 2 products
(11, 'GAME-004', 'ASUS ROG Swift PG279QM', 4999.00, 3000.00, 'Black', GETDATE(), '{"brand": "ASUS", "model": "ROG Swift PG279QM", "warrantyYears": 2, "specifications": {"size": "27 inch", "resolution": "2560x1440 QHD", "refresh_rate": "240Hz", "response_time": "1ms GTG"}}'),
(11, 'GAME-005', 'LG UltraGear 32GN750', 5999.00, 3600.00, 'Black', GETDATE(), '{"brand": "LG", "model": "UltraGear 32GN750-B", "warrantyYears": 2, "specifications": {"size": "32 inch", "resolution": "2560x1440 QHD", "refresh_rate": "240Hz", "response_time": "1ms GTG"}}'),

-- Gaming Keyboards (SubCategoryID 12) - 2 products
(12, 'GAME-006', 'Corsair K95 Platinum XT', 1999.00, 1200.00, 'Black', GETDATE(), '{"brand": "Corsair", "model": "K95 Platinum XT", "warrantyYears": 2, "specifications": {"switches": "Cherry MX Red", "layout": "Full Size 104-key", "backlighting": "RGB per-key", "connection": "Wired USB"}}'),
(12, 'GAME-007', 'Razer BlackWidow V4', 1699.00, 1020.00, 'Black', GETDATE(), '{"brand": "Razer", "model": "BlackWidow V4", "warrantyYears": 2, "specifications": {"switches": "Razer Green", "layout": "Full Size 104-key", "backlighting": "RGB per-key", "connection": "Wired USB"}}'),

-- Gaming Mice (SubCategoryID 13) - 3 products
(13, 'GAME-008', 'Logitech G Pro X Superlight 2', 999.00, 600.00, 'Black', GETDATE(), '{"brand": "Logitech", "model": "G Pro X Superlight 2", "warrantyYears": 2, "specifications": {"sensor": "HERO 25K", "dpi": "25600", "weight": "63g", "connectivity": "Wireless 2.4GHz"}}'),
(13, 'GAME-009', 'Razer DeathAdder V3', 899.00, 540.00, 'Black', GETDATE(), '{"brand": "Razer", "model": "DeathAdder V3", "warrantyYears": 2, "specifications": {"sensor": "Focus Pro 30K", "dpi": "30000", "weight": "63g", "connectivity": "Wired USB"}}'),
(13, 'GAME-010', 'SteelSeries Rival 5', 799.00, 480.00, 'Black', GETDATE(), '{"brand": "SteelSeries", "model": "Rival 5", "warrantyYears": 1, "specifications": {"sensor": "TrueMove Core", "dpi": "18000", "weight": "78g", "connectivity": "Wired USB"}}'),

-- ========================================
-- HEM & FRITID (6 products)
-- ========================================

-- Smart Home (SubCategoryID 14) - 2 products
(14, 'HOME-001', 'Google Nest Hub Max', 2499.00, 1500.00, 'Charcoal', GETDATE(), '{"brand": "Google", "model": "Nest Hub Max", "warrantyYears": 1, "specifications": {"display": "10 inch touchscreen", "resolution": "2200x1600", "connectivity": "WiFi 5 802.11ac", "assistant": "Google Assistant"}}'),
(14, 'HOME-002', 'Amazon Echo Show 15', 1999.00, 1200.00, 'Black', GETDATE(), '{"brand": "Amazon", "model": "Echo Show 15", "warrantyYears": 1, "specifications": {"display": "15.6 inch touchscreen", "resolution": "1920x1080", "connectivity": "WiFi 6 802.11ax", "assistant": "Alexa"}}'),

-- Sports Equipment (SubCategoryID 15) - 2 products
(15, 'HOME-003', 'Fitbit Charge 5', 1499.00, 900.00, 'Black', GETDATE(), '{"brand": "Fitbit", "model": "Charge 5", "warrantyYears": 1, "specifications": {"display": "AMOLED touchscreen", "battery": "7 days", "water_resistance": "50m", "sensors": "heart rate, SpO2, EDA"}}'),
(15, 'HOME-004', 'Apple Watch Series 8', 3999.00, 2400.00, 'Silver', GETDATE(), '{"brand": "Apple", "model": "Watch Series 8 45mm", "warrantyYears": 1, "specifications": {"display": "Retina LTPO OLED", "battery": "18 hours", "water_resistance": "50m", "sensors": "ECG, temperature, blood oxygen"}}'),

-- Furniture (SubCategoryID 16) - 1 product
(16, 'HOME-005', 'IKEA LINNMON Desk', 999.00, 600.00, NULL, GETDATE(), '{"brand": "IKEA", "model": "LINNMON", "warrantyYears": 1, "specifications": {"material": "particle board veneer", "size": "140x60 cm", "height_adjustable": "no", "load_capacity": "50 kg"}}'),

-- Lighting (SubCategoryID 17) - 1 product
(17, 'HOME-006', 'Philips Hue Smart Bulbs', 1299.00, 780.00, 'White', GETDATE(), '{"brand": "Philips", "model": "Hue White A19", "warrantyYears": 2, "specifications": {"brightness": "1600 lumens", "color_temperature": "2700K 6500K", "connectivity": "Bluetooth ZigBee", "lifespan": "25000 hours"}}'),

-- ========================================
-- PERSONVÅRD (5 products)
-- ========================================

-- Hair Care (SubCategoryID 18) - 2 products
(18, 'CARE-001', 'Dyson SuperSonic Hair Dryer', 3999.00, 2400.00, 'Platinum', GETDATE(), '{"brand": "Dyson", "model": "SuperSonic", "warrantyYears": 2, "specifications": {"power": "1600W", "air_speed": "40 mph", "heat_levels": "3", "ionic_technology": "yes"}}'),
(18, 'CARE-002', 'GHD Platinum+ Hair Styler', 1999.00, 1200.00, 'Black', GETDATE(), '{"brand": "GHD", "model": "Platinum+ Styler", "warrantyYears": 2, "specifications": {"plate_width": "28mm", "heat_levels": "5", "temperature_range": "140-365F", "plate_technology": "Dual-zone"}}'),

-- Skincare (SubCategoryID 19) - 2 products
(19, 'CARE-003', 'Clarisonic Mia Smart', 1299.00, 780.00, 'Rose Gold', GETDATE(), '{"brand": "Clarisonic", "model": "Mia Smart", "warrantyYears": 1, "specifications": {"frequency": "300 oscillations/sec", "brush_types": "sensitive, normal, deep", "battery": "22 uses per charge", "waterproof": "IPX7"}}'),
(19, 'CARE-004', 'NuFace Trinity Pro', 699.00, 420.00, 'Rose Gold', GETDATE(), '{"brand": "NuFace", "model": "Trinity PRO", "warrantyYears": 1, "specifications": {"microcurrent": "yes", "treatment_time": "5 minutes", "attachments": "facial, lips, eye", "battery": "2-3 hours"}}'),

-- Health Devices (SubCategoryID 20) - 1 product
(20, 'CARE-005', 'Withings Body+ Smart Scale', 1299.00, 780.00, 'Black', GETDATE(), '{"brand": "Withings", "model": "Body+", "warrantyYears": 2, "specifications": {"measurements": "weight, BMI, water%, muscle mass", "connectivity": "WiFi Bluetooth", "max_weight": "180kg", "accuracy": "0.1kg"}}'),

-- ========================================
-- TV (8 products)
-- ========================================

-- OLED TV (SubCategoryID 21) - 2 products
(21, 'TV-001', 'LG OLED55C3PUA 55"', 9999.00, 6000.00, 'Black', GETDATE(), '{"brand": "LG", "model": "OLED55C3PUA", "warrantyYears": 2, "specifications": {"size": "55 inch", "resolution": "4K OLED 3840x2160", "refresh_rate": "120Hz", "brightness": "200 nits peak"}}'),
(21, 'TV-002', 'Sony K-55XR80 55"', 11999.00, 7200.00, 'Black', GETDATE(), '{"brand": "Sony", "model": "K-55XR80", "warrantyYears": 3, "specifications": {"size": "55 inch", "resolution": "4K Mini-LED 3840x2160", "refresh_rate": "120Hz", "brightness": "3000 nits peak"}}'),

-- LED TV (SubCategoryID 22) - 3 products
(22, 'TV-003', 'Samsung QN55Q80C 55"', 7999.00, 4800.00, 'Black', GETDATE(), '{"brand": "Samsung", "model": "QN55Q80C", "warrantyYears": 2, "specifications": {"size": "55 inch", "resolution": "4K QLED 3840x2160", "refresh_rate": "120Hz", "brightness": "2500 nits peak"}}'),
(22, 'TV-004', 'TCL 65\" 4K Smart TV', 4999.00, 3000.00, 'Black', GETDATE(), '{"brand": "TCL", "model": "65Q640", "warrantyYears": 1, "specifications": {"size": "65 inch", "resolution": "4K LED 3840x2160", "refresh_rate": "60Hz", "smart_platform": "Google TV"}}'),
(22, 'TV-005', 'Hisense 55" 4K Smart TV', 3999.00, 2400.00, 'Black', GETDATE(), '{"brand": "Hisense", "model": "55A6G", "warrantyYears": 1, "specifications": {"size": "55 inch", "resolution": "4K LED 3840x2160", "refresh_rate": "60Hz", "smart_platform": "Android TV"}}'),

-- Smart TV (SubCategoryID 23) - 3 products
(23, 'TV-006', 'Samsung QN65Q90D 65"', 12999.00, 7800.00, 'Black', GETDATE(), '{"brand": "Samsung", "model": "QN65Q90D", "warrantyYears": 2, "specifications": {"size": "65 inch", "resolution": "4K QLED 3840x2160", "refresh_rate": "144Hz", "brightness": "3000 nits peak"}}'),
(23, 'TV-007', 'LG 65UP7550 65"', 8999.00, 5400.00, 'Black', GETDATE(), '{"brand": "LG", "model": "65UP7550", "warrantyYears": 2, "specifications": {"size": "65 inch", "resolution": "4K LED 3840x2160", "refresh_rate": "60Hz", "smart_platform": "webOS"}}'),
(23, 'TV-008', 'Panasonic 55HX950 55"', 6999.00, 4200.00, 'Black', GETDATE(), '{"brand": "Panasonic", "model": "55HX950", "warrantyYears": 2, "specifications": {"size": "55 inch", "resolution": "4K LED 3840x2160", "refresh_rate": "60Hz", "smart_platform": "my Home Screen"}}'),

-- ========================================
-- LJUD (8 products)
-- ========================================

-- Speakers (SubCategoryID 24) - 3 products
(24, 'AUDIO-001', 'Bose SoundLink Max', 2999.00, 1800.00, 'Black', GETDATE(), '{"brand": "Bose", "model": "SoundLink Max", "warrantyYears": 1, "specifications": {"power": "60W", "battery": "20 hours", "connectivity": "Bluetooth 5.3 WiFi", "water_resistance": "IPX7"}}'),
(24, 'AUDIO-002', 'Marshall Stanmore III', 1999.00, 1200.00, 'Black', GETDATE(), '{"brand": "Marshall", "model": "Stanmore III", "warrantyYears": 2, "specifications": {"power": "80W RMS", "drivers": "dual woofer dual tweeter", "connectivity": "Bluetooth RCA 3.5mm", "dimensions": "560x380x250mm"}}'),
(24, 'AUDIO-003', 'Harman Kardon Onyx Studio 7', 1499.00, 900.00, 'Black', GETDATE(), '{"brand": "Harman Kardon", "model": "Onyx Studio 7", "warrantyYears": 2, "specifications": {"power": "110W RMS", "drivers": "50mm woofers", "connectivity": "Bluetooth Aux Optical", "design": "Premium wool mesh"}}'),

-- Headphones (SubCategoryID 25) - 4 products
(25, 'AUDIO-004', 'Sony WH-1000XM5', 3699.00, 2220.00, 'Black', GETDATE(), '{"brand": "Sony", "model": "WH-1000XM5", "warrantyYears": 1, "specifications": {"noise_cancellation": "industry-leading ANC", "battery": "30 hours", "driver_size": "40mm", "connectivity": "Bluetooth 5.3"}}'),
(25, 'AUDIO-005', 'Bose QuietComfort 45', 3499.00, 2100.00, 'Black', GETDATE(), '{"brand": "Bose", "model": "QuietComfort 45", "warrantyYears": 1, "specifications": {"noise_cancellation": "dual-microphone ANC", "battery": "24 hours", "driver_type": "custom transducers", "connectivity": "Bluetooth USB-C"}}'),
(25, 'AUDIO-006', 'Apple AirPods Pro Max', 4999.00, 3000.00, 'Silver', GETDATE(), '{"brand": "Apple", "model": "AirPods Pro Max", "warrantyYears": 1, "specifications": {"noise_cancellation": "Active Noise Cancellation", "battery": "20 hours", "audio": "Spatial audio with Dolby Atmos", "drivers": "40mm custom drivers"}}'),
(25, 'AUDIO-007', 'Sennheiser Momentum 4', 2999.00, 1800.00, 'Black', GETDATE(), '{"brand": "Sennheiser", "model": "Momentum 4", "warrantyYears": 2, "specifications": {"noise_cancellation": "Adaptive NC", "battery": "60 hours", "driver_size": "42mm", "connectivity": "Bluetooth 5.3"}}'),

-- Microphones (SubCategoryID 26) - 1 product
(26, 'AUDIO-008', 'Blue Yeti USB Microphone', 999.00, 600.00, 'Black', GETDATE(), '{"brand": "Blue", "model": "Yeti", "warrantyYears": 2, "specifications": {"capsules": "quad condenser", "pickup_patterns": "4 (cardioid omni bidirectional stereo)", "frequency": "20Hz-20kHz", "connection": "USB"}}'),

-- ========================================
-- MOBIL & SMARTWATCH (14 products)
-- ========================================

-- Smartphones (SubCategoryID 27) - 5 products
(27, 'MOBIL-001', 'iPhone 15 Pro Max 256GB', 15999.00, 9600.00, 'Titanium Blue', GETDATE(), '{"brand": "Apple", "model": "iPhone 15 Pro Max", "warrantyYears": 1, "specifications": {"processor": "A17 Pro", "ram": "8GB", "storage": "256GB", "display": "6.7-inch Super Retina XDR"}}'),
(27, 'MOBIL-002', 'Samsung Galaxy S24 Ultra', 15499.00, 9300.00, 'Phantom Black', GETDATE(), '{"brand": "Samsung", "model": "Galaxy S24 Ultra", "warrantyYears": 1, "specifications": {"processor": "Snapdragon 8 Gen 3", "ram": "12GB", "storage": "256GB", "display": "6.8-inch Dynamic AMOLED 2X"}}'),
(27, 'MOBIL-003', 'Google Pixel 8 Pro', 12999.00, 7800.00, 'Porcelain', GETDATE(), '{"brand": "Google", "model": "Pixel 8 Pro", "warrantyYears": 1, "specifications": {"processor": "Tensor G3", "ram": "12GB", "storage": "256GB", "display": "6.7-inch LTPO OLED 120Hz"}}'),
(27, 'MOBIL-004', 'OnePlus 12', 9999.00, 6000.00, 'Black', GETDATE(), '{"brand": "OnePlus", "model": "12", "warrantyYears": 1, "specifications": {"processor": "Snapdragon 8 Gen 3", "ram": "12GB", "storage": "256GB", "display": "6.7-inch AMOLED 120Hz"}}'),
(27, 'MOBIL-005', 'Xiaomi 14 Ultra', 11999.00, 7200.00, 'Black', GETDATE(), '{"brand": "Xiaomi", "model": "14 Ultra", "warrantyYears": 1, "specifications": {"processor": "Snapdragon 8 Gen 3", "ram": "16GB", "storage": "512GB", "display": "6.73-inch AMOLED 120Hz"}}'),

-- Smartwatch Accessories (SubCategoryID 28) - 2 products
(28, 'MOBIL-006', 'Apple Watch Series 9 Band', 499.00, 300.00, 'Red', GETDATE(), '{"brand": "Apple", "model": "Sport Band", "warrantyYears": 1, "specifications": {"material": "fluoroelastomer", "sizes": "S/M M/L", "waterproof": "yes", "quick_change": "yes"}}'),
(28, 'MOBIL-007', 'Samsung Galaxy Watch Strap', 399.00, 240.00, 'Black', GETDATE(), '{"brand": "Samsung", "model": "Sport Band", "warrantyYears": 1, "specifications": {"material": "silicone", "sizes": "S M L", "waterproof": "yes", "quick_release": "yes"}}'),

-- Smartwatches (SubCategoryID 29) - 3 products
(29, 'MOBIL-008', 'Apple Watch Ultra 2', 5999.00, 3600.00, 'Titanium', GETDATE(), '{"brand": "Apple", "model": "Watch Ultra 2", "warrantyYears": 1, "specifications": {"display": "2.04-inch Retina", "processor": "S9", "battery": "36 hours", "water_resistance": "100m"}}'),
(29, 'MOBIL-009', 'Samsung Galaxy Watch 6 Classic', 3999.00, 2400.00, 'Silver', GETDATE(), '{"brand": "Samsung", "model": "Galaxy Watch 6 Classic", "warrantyYears": 1, "specifications": {"display": "1.3-inch AMOLED", "processor": "Exynos W930", "battery": "40+ hours", "water_resistance": "50m"}}'),
(29, 'MOBIL-010', 'Garmin Epix Gen 2', 4999.00, 3000.00, 'Black', GETDATE(), '{"brand": "Garmin", "model": "Epix Gen 2", "warrantyYears": 1, "specifications": {"display": "1.4-inch AMOLED", "battery": "11 days smartwatch mode", "gps": "yes", "water_resistance": "100m"}}'),

-- Mobile Cases (SubCategoryID 30) - 4 products
(30, 'MOBIL-011', 'OtterBox Defender iPhone 15', 599.00, 360.00, 'Black', GETDATE(), '{"brand": "OtterBox", "model": "Defender Series", "warrantyYears": 1, "specifications": {"protection_level": "heavy-duty", "material": "polycarbonate rubber", "drop_tested": "14ft", "port_access": "precise cutouts"}}'),
(30, 'MOBIL-012', 'Spigen Tough Armor Samsung', 399.00, 240.00, 'Black', GETDATE(), '{"brand": "Spigen", "model": "Tough Armor", "warrantyYears": 1, "specifications": {"protection": "dual-layer", "material": "TPU hard PC", "weight": "minimal", "shock_absorption": "yes"}}'),
(30, 'MOBIL-013', 'Apple Silicone Case', 699.00, 420.00, 'Midnight', GETDATE(), '{"brand": "Apple", "model": "Silicone Case", "warrantyYears": 1, "specifications": {"material": "soft silicone", "lining": "velvety microfiber", "wireless_charging": "compatible", "colors_available": "10"}}'),
(30, 'MOBIL-014', 'Samsung Leather Case', 799.00, 480.00, 'Brown', GETDATE(), '{"brand": "Samsung", "model": "Leather Case", "warrantyYears": 1, "specifications": {"material": "genuine leather", "protection_level": "standard", "aesthetic": "premium look", "wireless_charging": "compatible"}}'),

-- ========================================
-- VITVAROR (5 products)
-- ========================================

-- Washing Machines (SubCategoryID 31) - 2 products
(31, 'VITV-001', 'LG Front Load Washer 8kg', 9999.00, 6000.00, 'White', GETDATE(), '{"brand": "LG", "model": "WF80T4000AW", "warrantyYears": 3, "specifications": {"capacity": "8kg", "programs": "14", "rpm": "1200", "energy_class": "A+++"}}'),
(31, 'VITV-002', 'Bosch Series 8 Washer 9kg', 11999.00, 7200.00, 'White', GETDATE(), '{"brand": "Bosch", "model": "WAX32EH00", "warrantyYears": 3, "specifications": {"capacity": "9kg", "programs": "15", "rpm": "1400", "energy_class": "A+++"}}'),

-- Dryers (SubCategoryID 32) - 1 product
(32, 'VITV-003', 'Samsung DV22N6800HX Dryer', 8999.00, 5400.00, 'Stainless Steel', GETDATE(), '{"brand": "Samsung", "model": "DV22N6800HX", "warrantyYears": 1, "specifications": {"capacity": "7.4 cu.ft", "type": "electric", "technology": "AI optimal dry", "energy_class": "A++"}}'),

-- Refrigerators (SubCategoryID 33) - 2 products
(33, 'VITV-004', 'Samsung French Door Fridge 650L', 19999.00, 12000.00, 'Stainless Steel', GETDATE(), '{"brand": "Samsung", "model": "RF65R9000", "warrantyYears": 3, "specifications": {"capacity": "650L", "type": "French Door", "technology": "Twin Cooling Plus", "energy_class": "A+"}}'),
(33, 'VITV-005', 'LG Side-by-Side Fridge 700L', 18999.00, 11400.00, 'Black', GETDATE(), '{"brand": "LG", "model": "GSXV90BSAE", "warrantyYears": 3, "specifications": {"capacity": "700L", "type": "Side-by-Side", "technology": "LinearCooling", "energy_class": "A+"}}'),

-- ========================================
-- KAMERA & FOTO (8 products)
-- ========================================

-- DSLR Cameras (SubCategoryID 34) - 2 products
(34, 'CAM-001', 'Canon EOS R5', 24999.00, 15000.00, 'Black', GETDATE(), '{"brand": "Canon", "model": "EOS R5", "warrantyYears": 2, "specifications": {"sensor": "Full Frame 45MP", "iso_range": "100-51200", "autofocus": "5655 AF points", "video": "8K 60fps"}}'),
(34, 'CAM-002', 'Nikon D850', 19999.00, 12000.00, 'Black', GETDATE(), '{"brand": "Nikon", "model": "D850", "warrantyYears": 2, "specifications": {"sensor": "Full Frame 45.7MP", "iso_range": "64-25600", "autofocus": "153 AF points", "video": "4K 30fps"}}'),

-- Mirrorless Cameras (SubCategoryID 35) - 2 products
(35, 'CAM-003', 'Sony A7R V', 22999.00, 13800.00, 'Black', GETDATE(), '{"brand": "Sony", "model": "Alpha 7R V", "warrantyYears": 2, "specifications": {"sensor": "Full Frame 61MP", "iso_range": "80-32000", "autofocus": "693 AF points", "video": "4K 120fps"}}'),
(35, 'CAM-004', 'Fujifilm X-T5', 15999.00, 9600.00, 'Silver', GETDATE(), '{"brand": "Fujifilm", "model": "X-T5", "warrantyYears": 2, "specifications": {"sensor": "APS-C 40.2MP", "iso_range": "160-12800", "autofocus": "425 AF points", "video": "4K 60fps"}}'),

-- Lenses (SubCategoryID 36) - 4 products
(36, 'CAM-005', 'Canon RF 28-70mm f/2L', 4999.00, 3000.00, 'Black', GETDATE(), '{"brand": "Canon", "model": "RF 28-70mm f/2L", "warrantyYears": 2, "specifications": {"focal_length": "28-70mm", "aperture": "f/2", "elements": "23 elements", "filter_size": "82mm"}}'),
(36, 'CAM-006', 'Sony FE 24-70mm f/2.8 GM II', 5999.00, 3600.00, 'Black', GETDATE(), '{"brand": "Sony", "model": "FE 24-70mm f/2.8 GM II", "warrantyYears": 2, "specifications": {"focal_length": "24-70mm", "aperture": "f/2.8", "elements": "21 elements", "filter_size": "77mm"}}'),
(36, 'CAM-007', 'Nikon Z 70-200mm f/2.8S', 6999.00, 4200.00, 'Black', GETDATE(), '{"brand": "Nikon", "model": "Z 70-200mm f/2.8S", "warrantyYears": 2, "specifications": {"focal_length": "70-200mm", "aperture": "f/2.8", "elements": "21 elements", "filter_size": "77mm"}}'),
(36, 'CAM-008', 'Fujifilm XF 35mm f/1.4 R', 1999.00, 1200.00, 'Black', GETDATE(), '{"brand": "Fujifilm", "model": "XF 35mm f/1.4 R", "warrantyYears": 2, "specifications": {"focal_length": "35mm", "aperture": "f/1.4", "elements": "8 elements", "filter_size": "52mm"}}'),

-- ========================================
-- TILLBEHÖR (12 products)
-- ========================================

-- Phone Cases (SubCategoryID 37) - 3 products
(37, 'ACC-001', 'OtterBox Defender Case', 599.00, 360.00, 'Black', GETDATE(), '{"brand": "OtterBox", "model": "Defender Series", "warrantyYears": 1, "specifications": {"protection": "heavy-duty", "material": "polycarbonate rubber", "drop_tested": "14ft", "port_protection": "precise cutouts"}}'),
(37, 'ACC-002', 'Spigen Tough Armor Case', 299.00, 180.00, 'Black', GETDATE(), '{"brand": "Spigen", "model": "Tough Armor", "warrantyYears": 1, "specifications": {"protection": "dual-layer", "material": "TPU hard PC", "weight": "minimal", "shock_protection": "yes"}}'),
(37, 'ACC-003', 'Apple Silicone Case', 699.00, 420.00, 'Midnight', GETDATE(), '{"brand": "Apple", "model": "Silicone Case", "warrantyYears": 1, "specifications": {"material": "soft silicone", "lining": "microfiber", "wireless_charging": "compatible", "colors": "10 available"}}'),

-- Cables (SubCategoryID 38) - 3 products
(38, 'ACC-004', 'Anker USB-C Cable 2m', 199.00, 120.00, 'Black', GETDATE(), '{"brand": "Anker", "model": "USB-C to USB-C", "warrantyYears": 1, "specifications": {"length": "2m", "power_delivery": "100W", "data_speed": "480Mbps USB 3.1", "certification": "USB certified"}}'),
(38, 'ACC-005', 'Belkin Lightning Cable 1m', 249.00, 150.00, 'White', GETDATE(), '{"brand": "Belkin", "model": "USB-A to Lightning", "warrantyYears": 1, "specifications": {"length": "1m", "current": "2.4A", "mfi_certified": "yes", "durability": "reinforced connector"}}'),
(38, 'ACC-006', 'HDMI 2.1 Cable 2m', 299.00, 180.00, 'Black', GETDATE(), '{"brand": "Generic", "model": "HDMI 2.1", "warrantyYears": 1, "specifications": {"length": "2m", "bandwidth": "48Gbps", "support": "8K 60Hz", "certification": "HDMI 2.1 certified"}}'),

-- Chargers (SubCategoryID 39) - 3 products
(39, 'ACC-007', 'Anker 67W GaN Charger', 599.00, 360.00, 'Black', GETDATE(), '{"brand": "Anker", "model": "67W GaN Charger", "warrantyYears": 1, "specifications": {"power": "67W", "ports": "1x USB-C", "technology": "GaN", "compatible_devices": "3 devices"}}'),
(39, 'ACC-008', 'Apple 20W USB-C Power Adapter', 399.00, 240.00, 'White', GETDATE(), '{"brand": "Apple", "model": "20W USB-C", "warrantyYears": 1, "specifications": {"power": "20W", "compatibility": "iPhone 12+, iPad", "technology": "USB Power Delivery", "size": "compact"}}'),
(39, 'ACC-009', 'Samsung 45W Fast Charger', 449.00, 270.00, 'Black', GETDATE(), '{"brand": "Samsung", "model": "45W Charger", "warrantyYears": 1, "specifications": {"power": "45W", "compatibility": "Samsung Galaxy", "fast_charge": "35W super fast", "port": "USB-C"}}'),

-- Adapters (SubCategoryID 40) - 2 products
(40, 'ACC-010', 'Anker USB-C Hub 7-in-1', 699.00, 420.00, 'Silver', GETDATE(), '{"brand": "Anker", "model": "7-in-1 USB-C Hub", "warrantyYears": 1, "specifications": {"ports": "HDMI, USB 3.0 x3, SD, microSD, USB-C", "compatibility": "MacBook, iPad Pro, laptops", "data_speed": "5Gbps", "power_delivery": "60W"}}'),
(40, 'ACC-011', 'Belkin USB-C Multiport Hub', 799.00, 480.00, 'Gray', GETDATE(), '{"brand": "Belkin", "model": "USB-C Multiport Hub", "warrantyYears": 2, "specifications": {"ports": "HDMI, USB 3.0 x2, USB-C, SD", "compatibility": "universal USB-C devices", "data_speed": "5Gbps", "power_delivery": "100W"}}'),

-- Screen Protectors (SubCategoryID 41) - 2 products
(41, 'ACC-012', 'Spigen Tempered Glass iPhone', 299.00, 180.00, 'Clear', GETDATE(), '{"brand": "Spigen", "model": "Tempered Glass", "warrantyYears": 1, "specifications": {"hardness": "9H", "oleophobic_coating": "yes", "transparency": "ultra-clear", "installation": "alignment kit included"}}'),
(41, 'ACC-013', 'ZAGG InvisibleShield Glass', 249.00, 150.00, 'Clear', GETDATE(), '{"brand": "ZAGG", "model": "InvisibleShield", "warrantyYears": 1, "specifications": {"material": "tempered glass", "hardness": "9H", "self_healing": "anti-microbial", "warranty": "drop protection warranty"}}');

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
('Wendla', 'Udén', 'wendla.uden@gmail.com', '0706667777'),
('Xerxes', 'Viklund', 'xerxes.viklund@outlook.se', NULL),
('Yoko', 'Wahl', 'yoko.wahl@gmail.com', '0708889999'),
('Zigge', 'Xanthopoulos', 'zigge.xanthopoulos@outlook.se', '0707778888'),
('Astrid', 'Åberg', 'astrid.aberg@gmail.com', '0700011111'),
('Bengt', 'Åström', 'bengt.astrom@outlook.se', NULL),
('Cecilia', 'Börjelsson', 'cecilia.borjelsson@gmail.com', '0701223334'),
('Didrik', 'Öberg', 'didrik.oberg@outlook.se', '0702334445'),
('Ebba', 'Östberg', 'ebba.ostberg@gmail.com', '0703445556'),
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
('Pär', 'Eklund', 'par.eklund@outlook.se', '0702223334'),
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
Summary:

INSERT INTO dbo.[Order] (PaymentID, CustomerID, OrderDate, OrderStatus, OrderTotalAmount) VALUES
-- JANUARY (20 orders)
(1, 1, '2024-01-05 00:00:00', 'Levererat', 24999.00),
(2, 2, '2024-01-08 00:00:00', 'Levererat', 8999.00),
(3, 3, '2024-01-10 00:00:00', 'Bearbetas', 12999.00),
(4, 4, '2024-01-12 00:00:00', 'Levererat', 5999.00),
(5, 5, '2024-01-15 00:00:00', 'Skickat', 9999.00),
(6, 6, '2024-01-18 00:00:00', 'Levererat', 3999.00),
(7, 7, '2024-01-20 00:00:00', 'Bearbetas', 4999.00),
(8, 8, '2024-01-22 00:00:00', 'Levererat', 7999.00),
(9, 9, '2024-01-24 00:00:00', 'Skickat', 1999.00),
(10, 10, '2024-01-26 00:00:00', 'Levererat', 6999.00),
(11, 11, '2024-01-27 00:00:00', 'Väntande', 2999.00),
(12, 12, '2024-01-28 00:00:00', 'Levererat', 4499.00),
(13, 1, '2024-01-29 00:00:00', 'Bearbetas', 11999.00),
(14, 13, '2024-01-30 00:00:00', 'Levererat', 3699.00),
(15, 14, '2024-01-02 00:00:00', 'Levererat', 5999.00),
(16, 15, '2024-01-03 00:00:00', 'Skickat', 2499.00),
(17, 16, '2024-01-04 00:00:00', 'Levererat', 999.00),
(18, 17, '2024-01-06 00:00:00', 'Bearbetas', 8999.00),
(19, 18, '2024-01-07 00:00:00', 'Levererat', 4999.00),
(20, 19, '2024-01-09 00:00:00', 'Avbrutet', 1999.00),

-- FEBRUARY (12 orders)
(21, 20, '2024-02-01 00:00:00', 'Levererat', 3999.00),
(22, 21, '2024-02-05 00:00:00', 'Levererat', 5999.00),
(23, 22, '2024-02-08 00:00:00', 'Skickat', 7999.00),
(24, 23, '2024-02-10 00:00:00', 'Bearbetas', 2999.00),
(25, 24, '2024-02-12 00:00:00', 'Levererat', 4499.00),
(26, 1, '2024-02-15 00:00:00', 'Levererat', 6999.00),
(27, 25, '2024-02-18 00:00:00', 'Skickat', 1999.00),
(28, 26, '2024-02-20 00:00:00', 'Levererat', 9999.00),
(29, 27, '2024-02-22 00:00:00', 'Bearbetas', 3699.00),
(30, 28, '2024-02-24 00:00:00', 'Levererat', 2499.00),
(31, 29, '2024-02-26 00:00:00', 'Väntande', 5999.00),
(32, 30, '2024-02-28 00:00:00', 'Levererat', 4999.00),

-- MARCH (15 orders)
(33, 2, '2024-03-02 00:00:00', 'Levererat', 8999.00),
(34, 31, '2024-03-05 00:00:00', 'Levererat', 3999.00),
(35, 32, '2024-03-08 00:00:00', 'Bearbetas', 5999.00),
(36, 33, '2024-03-10 00:00:00', 'Levererat', 12999.00),
(37, 34, '2024-03-12 00:00:00', 'Skickat', 4999.00),
(38, 35, '2024-03-15 00:00:00', 'Levererat', 6999.00),
(39, 36, '2024-03-18 00:00:00', 'Be
The operation was aborted.
but gime me some realistisc time when the customers are shopping
Good idea! Here's the INSERT with realistic shopping times throughout the day:

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

INSERT INTO dbo.OrderItem (OrderID, ProductID, Quantity, LineTotal, DiscountApplied) VALUES
-- Order 1 (2 items)
(1, 1, 1, 12999.00, 0.00),
(1, 38, 1, 11999.00, 0.00),

-- Order 2 (2 items)
(2, 5, 1, 8999.00, 0.00),
(2, 88, 1, 2499.00, 0.00),

-- Order 3 (3 items)
(3, 3, 1, 12999.00, 1300.00),
(3, 15, 1, 6999.00, 0.00),
(3, 45, 1, 8999.00, 900.00),

-- Order 4 (1 item)
(4, 10, 1, 5999.00, 0.00),

-- Order 5 (2 items)
(5, 2, 2, 17998.00, 1800.00),
(5, 39, 1, 3999.00, 0.00),

-- Order 6 (1 item)
(6, 18, 1, 3999.00, 0.00),

-- Order 7 (2 items)
(7, 20, 1, 4999.00, 500.00),
(7, 87, 1, 1999.00, 0.00),

-- Order 8 (1 item)
(8, 22, 1, 7999.00, 0.00),

-- Order 9 (2 items)
(9, 89, 2, 1998.00, 200.00),
(9, 54, 1, 4999.00, 0.00),

-- Order 10 (1 item)
(10, 15, 1, 6999.00, 0.00),

-- Order 11 (2 items)
(11, 24, 1, 2999.00, 300.00),
(11, 71, 1, 2999.00, 0.00),

-- Order 12 (1 item)
(12, 14, 1, 4499.00, 0.00),

-- Order 13 (2 items)
(13, 4, 2, 14998.00, 1500.00),
(13, 50, 1, 4999.00, 0.00),

-- Order 14 (1 item)
(14, 26, 1, 3699.00, 0.00),

-- Order 15 (2 items)
(15, 31, 1, 5999.00, 600.00),
(15, 62, 1, 1999.00, 0.00),

-- Order 16 (1 item)
(16, 88, 1, 2499.00, 0.00),

-- Order 17 (2 items)
(17, 6, 1, 8999.00, 0.00),
(17, 93, 1, 4999.00, 0.00),

-- Order 18 (1 item)
(18, 20, 1, 4999.00, 0.00),

-- Order 19 (2 items)
(19, 89, 2, 1998.00, 200.00),
(19, 81, 1, 4999.00, 0.00),

-- Order 20 (1 item)
(20, 39, 1, 3999.00, 0.00),

-- Order 21 (2 items)
(21, 30, 1, 5999.00, 0.00),
(21, 73, 1, 3999.00, 0.00),

-- Order 22 (2 items)
(22, 24, 1, 7999.00, 800.00),
(22, 12, 1, 4499.00, 0.00),

-- Order 23 (1 item)
(23, 27, 1, 2999.00, 0.00),

-- Order 24 (2 items)
(24, 16, 1, 4499.00, 0.00),
(24, 56, 1, 11999.00, 1200.00),

-- Order 25 (1 item)
(25, 2, 1, 6999.00, 700.00),

-- Order 26 (2 items)
(26, 48, 1, 1999.00, 0.00),
(26, 85, 1, 5999.00, 600.00),

-- Order 27 (2 items)
(27, 60, 2, 9998.00, 1000.00),
(27, 38, 1, 11999.00, 0.00),

-- Order 28 (1 item)
(28, 35, 1, 3699.00, 0.00),

-- Order 29 (2 items)
(29, 12, 1, 2499.00, 0.00),
(29, 78, 1, 3999.00, 0.00),

-- Order 30 (2 items)
(30, 40, 1, 4999.00, 500.00),
(30, 18, 1, 3999.00, 0.00),

-- Order 31 (1 item)
(31, 9, 1, 3999.00, 0.00),

-- Order 32 (2 items)
(32, 28, 1, 5999.00, 0.00),
(32, 90, 1, 7999.00, 0.00),

-- Order 33 (2 items)
(33, 65, 1, 12999.00, 1300.00),
(33, 50, 1, 4999.00, 0.00),

-- Order 34 (1 item)
(34, 29, 1, 4999.00, 0.00),

-- Order 35 (2 items)
(35, 42, 1, 6999.00, 0.00),
(35, 72, 1, 7999.00, 800.00),

-- Order 36 (2 items)
(36, 19, 1, 2999.00, 300.00),
(36, 45, 1, 8999.00, 900.00),

-- Order 37 (1 item)
(37, 70, 1, 9999.00, 0.00),

-- Order 38 (2 items)
(38, 25, 1, 3699.00, 0.00),
(38, 87, 1, 1999.00, 0.00),

-- Order 39 (2 items)
(39, 56, 1, 11999.00, 1200.00),
(39, 38, 1, 11999.00, 0.00),

-- Order 40 (1 item)
(40, 8, 1, 1999.00, 0.00),

-- Order 41 (2 items)
(41, 90, 1, 7999.00, 0.00),
(41, 30, 1, 5999.00, 0.00),

-- Order 42 (2 items)
(42, 21, 1, 4999.00, 500.00),
(42, 62, 1, 1999.00, 0.00),

-- Order 43 (1 item)
(43, 17, 1, 2999.00, 0.00),

-- Order 44 (2 items)
(44, 50, 1, 6999.00, 700.00),
(44, 81, 1, 4999.00, 0.00),

-- Order 45 (2 items)
(45, 3, 1, 3999.00, 0.00),
(45, 72, 1, 7999.00, 800.00),

-- Order 46 (2 items)
(46, 85, 1, 5999.00, 600.00),
(46, 45, 1, 8999.00, 900.00),

-- Order 47 (1 item)
(47, 45, 1, 8999.00, 900.00),

-- Order 48 (1 item)
(48, 72, 1, 7999.00, 0.00),

-- Order 49 (2 items)
(49, 11, 1, 2499.00, 250.00),
(49, 80, 1, 6999.00, 0.00),

-- Order 50 (1 item)
(50, 52, 1, 4999.00, 0.00),

-- Order 51 (2 items)
(51, 77, 1, 9999.00, 1000.00),
(51, 38, 1, 11999.00, 0.00),

-- Order 52 (1 item)
(52, 34, 1, 3699.00, 0.00),

-- Order 53 (2 items)
(53, 62, 1, 1999.00, 0.00),
(53, 15, 1, 6999.00, 0.00),

-- Order 54 (2 items)
(54, 91, 1, 5999.00, 600.00),
(54, 50, 1, 4999.00, 0.00),

-- Order 55 (1 item)
(55, 41, 1, 4999.00, 0.00),

-- Order 56 (2 items)
(56, 13, 1, 2999.00, 300.00),
(56, 70, 1, 9999.00, 0.00),

-- Order 57 (1 item)
(57, 80, 1, 6999.00, 0.00),

-- Order 58 (2 items)
(58, 23, 1, 3999.00, 0.00),
(58, 85, 1, 5999.00, 0.00),

-- Order 59 (2 items)
(59, 58, 1, 5999.00, 600.00),
(59, 38, 1, 11999.00, 0.00),

-- Order 60 (1 item)
(60, 94, 1, 4999.00, 500.00),

-- Order 61 (2 items)
(61, 7, 1, 8999.00, 0.00),
(61, 45, 1, 8999.00, 0.00),

-- Order 62 (1 item)
(62, 47, 1, 1999.00, 0.00),

-- Order 63 (2 items)
(63, 32, 1, 7999.00, 800.00),
(63, 50, 1, 4999.00, 0.00),

-- Order 64 (1 item)
(64, 51, 1, 2999.00, 0.00),

-- Order 65 (2 items)
(65, 68, 1, 4999.00, 0.00),
(65, 30, 1, 5999.00, 0.00),

-- Order 66 (2 items)
(66, 38, 1, 9999.00, 1000.00),
(66, 56, 1, 11999.00, 0.00),

-- Order 67 (2 items)
(67, 76, 1, 12999.00, 1300.00),
(67, 38, 1, 11999.00, 0.00),

-- Order 68 (1 item)
(68, 22, 1, 8999.00, 900.00),

-- Order 69 (2 items)
(69, 44, 1, 2999.00, 0.00),
(69, 70, 1, 9999.00, 0.00),

-- Order 70 (2 items)
(70, 37, 1, 6999.00, 700.00),
(70, 45, 1, 8999.00, 0.00),

-- Order 71 (1 item)
(71, 81, 1, 4999.00, 0.00),

-- Order 72 (2 items)
(72, 59, 1, 11999.00, 1200.00),
(72, 38, 1, 11999.00, 0.00),

-- Order 73 (1 item)
(73, 18, 1, 3699.00, 0.00),

-- Order 74 (2 items)
(74, 26, 1, 1999.00, 0.00),
(74, 30, 1, 5999.00, 0.00),

-- Order 75 (2 items)
(75, 83, 1, 7999.00, 800.00),
(75, 50, 1, 4999.00, 0.00),

-- Order 76 (2 items)
(76, 5, 1, 5999.00, 600.00),
(76, 45, 1, 8999.00, 0.00),

-- Order 77 (1 item)
(77, 49, 1, 4999.00, 0.00),

-- Order 78 (2 items)
(78, 92, 1, 11999.00, 1200.00),
(78, 38, 1, 11999.00, 0.00),

-- Order 79 (2 items)
(79, 33, 1, 8999.00, 900.00),
(79, 70, 1, 9999.00, 0.00),

-- Order 80 (1 item)
(80, 61, 1, 2999.00, 0.00),

-- Order 81 (2 items)
(81, 20, 1, 6999.00, 700.00),
(81, 45, 1, 8999.00, 0.00),

-- Order 82 (1 item)
(82, 73, 1, 3999.00, 0.00),

-- Order 83 (2 items)
(83, 46, 1, 4999.00, 500.00),
(83, 30, 1, 5999.00, 0.00),

-- Order 84 (2 items)
(84, 36, 1, 2999.00, 0.00),
(84, 70, 1, 9999.00, 0.00),

-- Order 85 (2 items)
(85, 69, 1, 5999.00, 600.00),
(85, 38, 1, 11999.00, 0.00),

-- Order 86 (2 items)
(86, 84, 1, 9999.00, 1000.00),
(86, 45, 1, 8999.00, 0.00),

-- Order 87 (1 item)
(87, 16, 1, 3699.00, 0.00),

-- Order 88 (2 items)
(88, 67, 1, 1999.00, 0.00),
(88, 30, 1, 5999.00, 0.00),

-- Order 89 (2 items)
(89, 30, 1, 7999.00, 800.00),
(89, 50, 1, 4999.00, 0.00),

-- Order 90 (2 items)
(90, 86, 1, 5999.00, 600.00),
(90, 38, 1, 11999.00, 0.00),

-- Order 91 (1 item)
(91, 6, 1, 4999.00, 0.00),

-- Order 92 (2 items)
(92, 43, 1, 2999.00, 300.00),
(92, 70, 1, 9999.00, 0.00),

-- Order 93 (1 item)
(93, 57, 1, 6999.00, 0.00),

-- Order 94 (2 items)
(94, 27, 1, 3999.00, 0.00),
(94, 45, 1, 8999.00, 0.00),

-- Order 95 (2 items)
(95, 72, 1, 5999.00, 600.00),
(95, 38, 1, 11999.00, 0.00),

-- Order 96 (2 items)
(96, 12, 1, 8999.00, 900.00),
(96, 50, 1, 4999.00, 0.00),

-- Order 97 (1 item)
(97, 53, 1, 1999.00, 0.00),

-- Order 98 (2 items)
(98, 74, 1, 7999.00, 800.00),
(98, 30, 1, 5999.00, 0.00),

-- Order 99 (2 items)
(99, 35, 1, 4999.00, 500.00),
(99, 70, 1, 9999.00, 0.00),

-- Order 100 (1 item)
(100, 64, 1, 2999.00, 0.00),

-- Order 101 (2 items)
(101, 15, 1, 6999.00, 700.00),
(101, 45, 1, 8999.00, 0.00),

-- Order 102 (1 item)
(102, 45, 1, 3999.00, 0.00),

-- Order 103 (2 items)
(103, 82, 1, 11999.00, 1200.00),
(103, 38, 1, 11999.00, 0.00),

-- Order 104 (2 items)
(104, 28, 1, 8999.00, 900.00),
(104, 50, 1, 4999.00, 0.00),

-- Order 105 (1 item)
(105, 40, 1, 2999.00, 0.00),

-- Order 106 (2 items)
(106, 55, 1, 5999.00, 600.00),
(106, 30, 1, 5999.00, 0.00),

-- Order 107 (1 item)
(107, 9, 1, 4999.00, 0.00),

-- Order 108 (2 items)
(108, 78, 1, 3999.00, 0.00),
(108, 70, 1, 9999.00, 0.00),

-- Order 109 (2 items)
(109, 39, 1, 7999.00, 800.00),
(109, 45, 1, 8999.00, 0.00),

-- Order 110 (1 item)
(110, 87, 1, 2999.00, 300.00),

-- Order 111 (2 items)
(111, 22, 1, 6999.00, 700.00),
(111, 38, 1, 11999.00, 0.00),

-- Order 112 (1 item)
(112, 50, 1, 4999.00, 0.00),

-- Order 113 (2 items)
(113, 14, 1, 8999.00, 900.00),
(113, 30, 1, 5999.00, 0.00),

-- Order 114 (1 item)
(114, 31, 1, 3699.00, 0.00),

-- Order 115 (2 items)
(115, 67, 1, 1999.00, 0.00),
(115, 70, 1, 9999.00, 0.00),

-- Order 116 (2 items)
(116, 41, 1, 11999.00, 1200.00),
(116, 45, 1, 8999.00, 0.00),

-- Order 117 (1 item)
(117, 58, 1, 5999.00, 600.00),

-- Order 118 (2 items)
(118, 24, 1, 4999.00, 500.00),
(118, 38, 1, 11999.00, 0.00),

-- Order 119 (1 item)
(119, 71, 1, 2999.00, 0.00),

-- Order 120 (2 items)
(120, 19, 1, 6999.00, 700.00),
(120, 50, 1, 4999.00, 0.00),

-- Order 121 (2 items)
(121, 51, 1, 3999.00, 0.00),
(121, 70, 1, 9999.00, 0.00),

-- Order 122 (2 items)
(122, 3, 1, 7999.00, 800.00),
(122, 45, 1, 8999.00, 0.00),

-- Order 123 (1 item)
(123, 44, 1, 2999.00, 0.00),

-- Order 124 (2 items)
(124, 75, 1, 4999.00, 500.00),
(124, 30, 1, 5999.00, 0.00),

-- Order 125 (2 items)
(125, 29, 1, 5999.00, 600.00),
(125, 38, 1, 11999.00, 0.00),

-- Order 126 (2 items)
(126, 62, 1, 8999.00, 900.00),
(126, 50, 1, 4999.00, 0.00),

-- Order 127 (1 item)
(127, 11, 1, 3699.00, 0.00),

-- Order 128 (2 items)
(128, 85, 1, 1999.00, 0.00),
(128, 70, 1, 9999.00, 0.00),

-- Order 129 (2 items)
(129, 21, 1, 7999.00, 800.00),
(129, 45, 1, 8999.00, 0.00),

-- Order 130 (1 item)
(130, 36, 1, 2999.00, 300.00),

-- Order 131 (2 items)
(131, 54, 1, 6999.00, 700.00),
(131, 38, 1, 11999.00, 0.00),

-- Order 132 (1 item)
(132, 17, 1, 4999.00, 0.00),

-- Order 133 (2 items)
(133, 68, 1, 9999.00, 1000.00),
(133, 50, 1, 4999.00, 0.00),

-- Order 134 (1 item)
(134, 32, 1, 3999.00, 0.00),

-- Order 135 (2 items)
(135, 79, 1, 11999.00, 1200.00),
(135, 30, 1, 5999.00, 0.00),

-- Order 136 (2 items)
(136, 47, 1, 5999.00, 600.00),
(136, 70, 1, 9999.00, 0.00),

-- Order 137 (1 item)
(137, 10, 1, 4999.00, 500.00),

-- Order 138 (2 items)
(138, 37, 1, 2999.00, 0.00),
(138, 45, 1, 8999.00, 0.00),

-- Order 139 (2 items)
(139, 60, 1, 6999.00, 700.00),
(139, 38, 1, 11999.00, 0.00),

-- Order 140 (1 item)
(140, 26, 1, 3999.00, 0.00),

-- Order 141 (2 items)
(141, 81, 1, 7999.00, 800.00),
(141, 50, 1, 4999.00, 0.00),

-- Order 142 (1 item)
(142, 18, 1, 1999.00, 0.00),

-- Order 143 (2 items)
(143, 52, 1, 4999.00, 500.00),
(143, 30, 1, 5999.00, 0.00),

-- Order 144 (2 items)
(144, 8, 1, 2999.00, 300.00),
(144, 70, 1, 9999.00, 0.00),

-- Order 145 (2 items)
(145, 43, 1, 5999.00, 600.00),
(145, 45, 1, 8999.00, 0.00),

-- Order 146 (2 items)
(146, 65, 1, 8999.00, 900.00),
(146, 38, 1, 11999.00, 0.00),

-- Order 147 (1 item)
(147, 23, 1, 3699.00, 0.00),

-- Order 148 (2 items)
(148, 70, 1, 1999.00, 0.00),
(148, 50, 1, 4999.00, 0.00),

-- Order 149 (2 items)
(149, 15, 1, 7999.00, 800.00),
(149, 30, 1, 5999.00, 0.00),

-- Order 150 (1 item)
(150, 34, 1, 6999.00, 700.00),

-- Order 151 (2 items)
(151, 57, 1, 4999.00, 0.00),
(151, 70, 1, 9999.00, 0.00),

-- Order 152 (2 items)
(152, 48, 1, 2999.00, 0.00),
(152, 45, 1, 8999.00, 0.00),

-- Order 153 (2 items)
(153, 20, 1, 11999.00, 1200.00),
(153, 38, 1, 11999.00, 0.00),

-- Order 154 (1 item)
(154, 39, 1, 5999.00, 600.00),

-- Order 155 (2 items)
(155, 73, 1, 4999.00, 500.00),
(155, 50, 1, 4999.00, 0.00),

-- Order 156 (2 items)
(156, 12, 1, 8999.00, 900.00),
(156, 30, 1, 5999.00, 0.00),

-- Order 157 (1 item)
(157, 28, 1, 3999.00, 0.00),

-- Order 158 (2 items)
(158, 66, 1, 6999.00, 700.00),
(158, 70, 1, 9999.00, 0.00),

-- Order 159 (2 items)
(159, 40, 1, 7999.00, 800.00),
(159, 45, 1, 8999.00, 0.00),

-- Order 160 (1 item)
(160, 30, 1, 2999.00, 0.00),

-- Order 161 (2 items)
(161, 55, 1, 4999.00, 500.00),
(161, 38, 1, 11999.00, 0.00),

-- Order 162 (2 items)
(162, 83, 1, 5999.00, 600.00),
(162, 50, 1, 4999.00, 0.00),

-- Order 163 (2 items)
(163, 16, 1, 9999.00, 1000.00),
(163, 30, 1, 5999.00, 0.00),

-- Order 164 (1 item)
(164, 50, 1, 3699.00, 0.00),

-- Order 165 (2 items)
(165, 22, 1, 1999.00, 0.00),
(165, 70, 1, 9999.00, 0.00),

-- Order 166 (2 items)
(166, 62, 1, 11999.00, 1200.00),
(166, 45, 1, 8999.00, 0.00),

-- Order 167 (1 item)
(167, 41, 1, 7999.00, 800.00),

-- Order 168 (2 items)
(168, 14, 1, 2999.00, 300.00),
(168, 38, 1, 11999.00, 0.00),

-- Order 169 (1 item)
(169, 74, 1, 6999.00, 700.00),

-- Order 170 (2 items)
(170, 29, 1, 4999.00, 0.00),
(170, 50, 1, 4999.00, 0.00),

-- Order 171 (2 items)
(171, 58, 1, 8999.00, 900.00),
(171, 30, 1, 5999.00, 0.00),

-- Order 172 (1 item)
(172, 11, 1, 3999.00, 0.00),

-- Order 173 (2 items)
(173, 44, 1, 5999.00, 600.00),
(173, 70, 1, 9999.00, 0.00),

-- Order 174 (2 items)
(174, 36, 1, 2999.00, 0.00),
(174, 45, 1, 8999.00, 0.00),

-- Order 175 (2 items)
(175, 52, 1, 4999.00, 500.00),
(175, 38, 1, 11999.00, 0.00),

-- Order 176 (1 item)
(176, 71, 1, 7999.00, 800.00),

-- Order 177 (2 items)
(177, 25, 1, 3999.00, 0.00),
(177, 50, 1, 4999.00, 0.00),

-- Order 178 (2 items)
(178, 69, 1, 6999.00, 700.00),
(178, 30, 1, 5999.00, 0.00),

-- Order 179 (1 item)
(179, 15, 1, 1999.00, 0.00),

-- Order 180 (2 items)
(180, 35, 1, 5999.00, 600.00),
(180, 70, 1, 9999.00, 0.00),

-- Order 181 (2 items)
(181, 1, 1, 4999.00, 0.00),
(181, 38, 1, 11999.00, 0.00),

-- Order 182 (1 item)
(182, 5, 1, 2999.00, 0.00),

-- Order 183 (2 items)
(183, 3, 1, 6999.00, 700.00),
(183, 50, 1, 4999.00, 0.00),

-- Order 184 (2 items)
(184, 10, 1, 3999.00, 0.00),
(184, 45, 1, 8999.00, 0.00),

-- Order 185 (1 item)
(185, 2, 1, 5999.00, 0.00),

-- Order 186 (2 items)
(186, 18, 1, 9999.00, 0.00),
(186, 30, 1, 5999.00, 0.00),

-- Order 187 (2 items)
(187, 20, 1, 12999.00, 1300.00),
(187, 70, 1, 9999.00, 0.00),

-- Order 188 (1 item)
(188, 22, 1, 8999.00, 900.00),

-- Order 189 (2 items)
(189, 87, 1, 2999.00, 0.00),
(189, 45, 1, 8999.00, 0.00),

-- Order 190 (1 item)
(190, 15, 1, 6999.00, 0.00),

-- Order 191 (2 items)
(191, 24, 1, 4999.00, 0.00),
(191, 38, 1, 11999.00, 0.00),

-- Order 192 (2 items)
(192, 14, 1, 11999.00, 0.00),
(192, 50, 1, 4999.00, 0.00),

-- Order 193 (1 item)
(193, 26, 1, 3699.00, 0.00),

-- Order 194 (2 items)
(194, 88, 1, 1999.00, 0.00),
(194, 30, 1, 5999.00, 0.00),

-- Order 195 (2 items)
(195, 6, 1, 7999.00, 0.00),
(195, 70, 1, 9999.00, 0.00),

-- Order 196 (1 item)
(196, 20, 1, 5999.00, 0.00),

-- Order 197 (2 items)
(197, 89, 1, 8999.00, 0.00),
(197, 45, 1, 8999.00, 0.00),

-- Order 198 (2 items)
(198, 39, 1, 4999.00, 0.00),
(198, 38, 1, 11999.00, 0.00),

-- Order 199 (1 item)
(199, 30, 1, 2999.00, 0.00),

-- Order 200 (2 items)
(200, 24, 1, 6999.00, 0.00),
(200, 50, 1, 4999.00, 0.00),

-- Order 201 (2 items)
(201, 27, 1, 3999.00, 0.00),
(201, 70, 1, 9999.00, 0.00),

-- Order 202 (1 item)
(202, 16, 1, 5999.00, 0.00),

-- Order 203 (2 items)
(203, 2, 1, 9999.00, 0.00),
(203, 45, 1, 8999.00, 0.00),

-- Order 204 (2 items)
(204, 48, 1, 11999.00, 0.00),
(204, 38, 1, 11999.00, 0.00),

-- Order 205 (1 item)
(205, 60, 1, 8999.00, 0.00),

-- Order 206 (2 items)
(206, 35, 1, 2999.00, 0.00),
(206, 30, 1, 5999.00, 0.00),

-- Order 207 (2 items)
(207, 12, 1, 6999.00, 0.00),
(207, 70, 1, 9999.00, 0.00),

-- Order 208 (1 item)
(208, 40, 1, 4999.00, 0.00),

-- Order 209 (2 items)
(209, 9, 1, 11999.00, 0.00),
(209, 45, 1, 8999.00, 0.00),

-- Order 210 (2 items)
(210, 28, 1, 3699.00, 0.00),
(210, 38, 1, 11999.00, 0.00),

-- Order 211 (1 item)
(211, 67, 1, 1999.00, 0.00),

-- Order 212 (2 items)
(212, 41, 1, 7999.00, 0.00),
(212, 50, 1, 4999.00, 0.00);

-- DELETE FROM dbo.[OrderItem];
-- DBCC CHECKIDENT ('dbo.[OrderItem]', RESEED, 0);

INSERT INTO dbo.[Return] (ReturnID, OrderItemID, ReturnDate, Reason, [Status], Notes) VALUES
(1, 15, '2025-03-10', 'Defekt', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 8999.00 SEK'),
(2, 42, '2025-03-15', 'StämmerInte', 'Initierad', 'Returnerad artikel - Returnerat belopp: 3499.00 SEK'),
(3, 67, '2025-03-20', 'Skadad', 'Slutförd', 'Returnerad artikel - Returnerat belopp: 14999.00 SEK'),
(4, 89, '2025-03-18', 'KundRequest', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 1299.00 SEK'),
(5, 103, '2025-03-22', 'Övrigt', 'Avvisad', 'Returnerad artikel - Returnerat belopp: 599.00 SEK'),
(6, 128, '2025-03-25', 'Defekt', 'Initierad', 'Returnerad artikel - Returnerat belopp: 4999.00 SEK'),
(7, 145, '2025-03-28', 'StämmerInte', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 6999.00 SEK'),
(8, 162, '2025-04-02', 'Skadad', 'Slutförd', 'Returnerad artikel - Returnerat belopp: 11999.00 SEK'),
(9, 178, '2025-04-05', 'Defekt', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 7999.00 SEK'),
(10, 195, '2025-04-10', 'KundRequest', 'Initierad', 'Returnerad artikel - Returnerat belopp: 3999.00 SEK'),
(11, 210, '2025-04-12', 'StämmerInte', 'Avvisad', 'Returnerad artikel - Returnerat belopp: 1999.00 SEK'),
(12, 228, '2025-04-15', 'Övrigt', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 9999.00 SEK'),
(13, 245, '2025-04-20', 'Defekt', 'Slutförd', 'Returnerad artikel - Returnerat belopp: 24999.00 SEK'),
(14, 262, '2025-04-22', 'Skadad', 'Initierad', 'Returnerad artikel - Returnerat belopp: 2499.00 SEK'),
(15, 278, '2025-04-25', 'KundRequest', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 5999.00 SEK'),
(16, 295, '2025-05-01', 'StämmerInte', 'Slutförd', 'Returnerad artikel - Returnerat belopp: 749.00 SEK'),
(17, 312, '2025-05-05', 'Defekt', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 14999.00 SEK'),
(18, 328, '2025-05-08', 'Övrigt', 'Initierad', 'Returnerad artikel - Returnerat belopp: 1299.00 SEK'),
(19, 345, '2025-05-12', 'Skadad', 'Avvisad', 'Returnerad artikel - Returnerat belopp: 3999.00 SEK'),
(20, 346, '2025-05-15', 'KundRequest', 'Slutförd', 'Returnerad artikel - Returnerat belopp: 12999.00 SEK'),
(21, 38, '2025-05-20', 'StämmerInte', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 449.00 SEK'),
(22, 347, '2025-05-25', 'Defekt', 'Initierad', 'Returnerad artikel - Returnerat belopp: 6999.00 SEK'),
(23, 348, '2025-06-01', 'Övrigt', 'Slutförd', 'Returnerad artikel - Returnerat belopp: 9999.00 SEK'),
(24, 328, '2025-06-05', 'Skadad', 'Godkänd', 'Returnerad artikel - Returnerat belopp: 4999.00 SEK'),
(25, 315, '2025-06-10', 'KundRequest', 'Avvisad', 'Returnerad artikel - Returnerat belopp: 1499.00 SEK'),
(26, 311, '2025-06-15', 'StämmerInte', 'Initierad', 'Returnerad artikel - Returnerat belopp: 7999.00 SEK'),
(27, 310, '2025-06-20', 'Defekt', 'Slutförd', 'Returnerad artikel - Returnerat belopp: 34999.00 SEK');
