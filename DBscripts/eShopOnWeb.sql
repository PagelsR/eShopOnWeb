-- eShopOnWeb.sql
-- Combined database seeding script for eShopOnWeb
-- This script creates and seeds both catalog and identity tables in a single database

USE [eShopOnWeb];
GO

-- ============================================================================
-- CATALOG TABLES
-- ============================================================================

-- Create Catalog tables if they don't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CatalogBrands')
BEGIN
    CREATE TABLE [dbo].[CatalogBrands] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Brand] NVARCHAR(100) NOT NULL,
        CONSTRAINT [PK_CatalogBrands] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CatalogTypes')
BEGIN
    CREATE TABLE [dbo].[CatalogTypes] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Type] NVARCHAR(100) NOT NULL,
        CONSTRAINT [PK_CatalogTypes] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Catalog')
BEGIN
    CREATE TABLE [dbo].[Catalog] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Name] NVARCHAR(50) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [Price] DECIMAL(18, 2) NOT NULL,
        [PictureFileName] NVARCHAR(MAX) NULL,
        [PictureUri] NVARCHAR(MAX) NULL,
        [CatalogTypeId] INT NOT NULL,
        [CatalogBrandId] INT NOT NULL,
        [AvailableStock] INT NOT NULL DEFAULT 0,
        [RestockThreshold] INT NOT NULL DEFAULT 0,
        [MaxStockThreshold] INT NOT NULL DEFAULT 0,
        [OnReorder] BIT NOT NULL DEFAULT 0,
        CONSTRAINT [PK_Catalog] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Catalog_CatalogBrands] FOREIGN KEY ([CatalogBrandId]) REFERENCES [CatalogBrands]([Id]),
        CONSTRAINT [FK_Catalog_CatalogTypes] FOREIGN KEY ([CatalogTypeId]) REFERENCES [CatalogTypes]([Id])
    );
END
GO

-- Clear existing catalog data
DELETE FROM [dbo].[Catalog];
DELETE FROM [dbo].[CatalogBrands];
DELETE FROM [dbo].[CatalogTypes];
GO

-- Seed Catalog Brands
SET IDENTITY_INSERT [dbo].[CatalogBrands] ON;
GO

INSERT INTO [dbo].[CatalogBrands] ([Id], [Brand]) VALUES
(1, N'Azure'),
(2, N'.NET'),
(3, N'Visual Studio'),
(4, N'SQL Server'),
(5, N'Other');
GO

SET IDENTITY_INSERT [dbo].[CatalogBrands] OFF;
GO

-- Seed Catalog Types
SET IDENTITY_INSERT [dbo].[CatalogTypes] ON;
GO

INSERT INTO [dbo].[CatalogTypes] ([Id], [Type]) VALUES
(1, N'Mug'),
(2, N'T-Shirt'),
(3, N'Sheet'),
(4, N'USB Memory Stick');
GO

SET IDENTITY_INSERT [dbo].[CatalogTypes] OFF;
GO

-- Seed Catalog Items
SET IDENTITY_INSERT [dbo].[Catalog] ON;
GO

INSERT INTO [dbo].[Catalog] ([Id], [Name], [Description], [Price], [PictureFileName], [PictureUri], [CatalogTypeId], [CatalogBrandId], [AvailableStock], [RestockThreshold], [MaxStockThreshold], [OnReorder]) VALUES
(1, N'.NET Bot Black Hoodie', N'.NET Bot Black Hoodie, and more', 19.50, N'1.png', NULL, 2, 2, 100, 10, 200, 0),
(2, N'.NET Black & White Mug', N'.NET Black & White Mug', 8.50, N'2.png', NULL, 1, 2, 89, 5, 150, 0),
(3, N'Prism White T-Shirt', N'Prism White T-Shirt', 12.00, N'3.png', NULL, 2, 5, 56, 5, 100, 0),
(4, N'.NET Foundation T-shirt', N'.NET Foundation T-shirt', 12.00, N'4.png', NULL, 2, 2, 120, 10, 200, 0),
(5, N'Roslyn Red Sheet', N'Roslyn Red Sheet', 8.50, N'5.png', NULL, 3, 2, 55, 5, 100, 0),
(6, N'.NET Blue Hoodie', N'.NET Blue Hoodie', 12.00, N'6.png', NULL, 2, 2, 17, 5, 100, 0),
(7, N'Roslyn Red T-Shirt', N'Roslyn Red T-Shirt', 12.00, N'7.png', NULL, 2, 2, 8, 5, 100, 0),
(8, N'Kudu Purple Hoodie', N'Kudu Purple Hoodie', 8.50, N'8.png', NULL, 2, 5, 34, 5, 100, 0),
(9, N'Cup<T> White Mug', N'Cup<T> White Mug', 12.00, N'9.png', NULL, 1, 2, 76, 10, 150, 0),
(10, N'.NET Foundation Sheet', N'.NET Foundation Sheet', 12.00, N'10.png', NULL, 3, 2, 11, 5, 100, 0),
(11, N'Cup<T> Sheet', N'Cup<T> Sheet', 8.50, N'11.png', NULL, 3, 2, 3, 5, 100, 0),
(12, N'Prism White TShirt', N'Prism White TShirt', 12.00, N'12.png', NULL, 2, 5, 0, 5, 100, 1);
GO

SET IDENTITY_INSERT [dbo].[Catalog] OFF;
GO

PRINT 'Catalog tables seeded successfully';
GO

-- ============================================================================
-- IDENTITY TABLES (seeding only - tables created by EF migrations)
-- ============================================================================

-- Note: ASP.NET Core Identity tables are created automatically by Entity Framework migrations
-- This script only seeds test data

-- AspNetRoles table should already exist from EF migrations
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'AspNetRoles')
BEGIN
    -- Seed roles if they don't exist
    IF NOT EXISTS (SELECT * FROM AspNetRoles WHERE Name = 'Administrators')
    BEGIN
        INSERT INTO AspNetRoles (Id, Name, NormalizedName, ConcurrencyStamp)
        VALUES (
            NEWID(),
            'Administrators',
            'ADMINISTRATORS',
            NEWID()
        );
    END

    IF NOT EXISTS (SELECT * FROM AspNetRoles WHERE Name = 'Users')
    BEGIN
        INSERT INTO AspNetRoles (Id, Name, NormalizedName, ConcurrencyStamp)
        VALUES (
            NEWID(),
            'Users',
            'USERS',
            NEWID()
        );
    END

    PRINT 'Identity roles seeded successfully';
END
ELSE
BEGIN
    PRINT 'AspNetRoles table not found. Ensure Entity Framework migrations have been run first.';
END
GO

-- Seed demo users (passwords will be set by the application on first run)
-- Note: In production, users should be created through the application UI
-- The application uses ASP.NET Core Identity password hashing

-- Demo admin user: admin@example.com / Pass@word1
-- Demo regular user: demo@example.com / Pass@word1

-- These will be created by the application startup seeding logic

PRINT 'eShopOnWeb database seeded successfully';
GO
