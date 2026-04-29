-- ============================================================================
-- eShopOnWeb Database Initialization
-- Runs on every CI/CD deployment BEFORE the app starts.
-- Drops and recreates ALL tables and sequences from scratch.
-- Catalog data is seeded here. User accounts are created by the app on startup
-- (ASP.NET Core Identity API handles password hashing).
-- ============================================================================

BEGIN TRANSACTION;
BEGIN TRY

-- ── Drop Tables (reverse FK order) ──────────────────────────────────────────

IF OBJECT_ID('dbo.AspNetUserTokens',     'U') IS NOT NULL DROP TABLE [dbo].[AspNetUserTokens];
IF OBJECT_ID('dbo.AspNetUserRoles',      'U') IS NOT NULL DROP TABLE [dbo].[AspNetUserRoles];
IF OBJECT_ID('dbo.AspNetUserLogins',     'U') IS NOT NULL DROP TABLE [dbo].[AspNetUserLogins];
IF OBJECT_ID('dbo.AspNetUserClaims',     'U') IS NOT NULL DROP TABLE [dbo].[AspNetUserClaims];
IF OBJECT_ID('dbo.AspNetRoleClaims',     'U') IS NOT NULL DROP TABLE [dbo].[AspNetRoleClaims];
IF OBJECT_ID('dbo.BasketItems',          'U') IS NOT NULL DROP TABLE [dbo].[BasketItems];
IF OBJECT_ID('dbo.Catalog',              'U') IS NOT NULL DROP TABLE [dbo].[Catalog];
IF OBJECT_ID('dbo.OrderItems',           'U') IS NOT NULL DROP TABLE [dbo].[OrderItems];
IF OBJECT_ID('dbo.AspNetRoles',          'U') IS NOT NULL DROP TABLE [dbo].[AspNetRoles];
IF OBJECT_ID('dbo.AspNetUsers',          'U') IS NOT NULL DROP TABLE [dbo].[AspNetUsers];
IF OBJECT_ID('dbo.Baskets',              'U') IS NOT NULL DROP TABLE [dbo].[Baskets];
IF OBJECT_ID('dbo.CatalogBrands',        'U') IS NOT NULL DROP TABLE [dbo].[CatalogBrands];
IF OBJECT_ID('dbo.CatalogTypes',         'U') IS NOT NULL DROP TABLE [dbo].[CatalogTypes];
IF OBJECT_ID('dbo.Orders',               'U') IS NOT NULL DROP TABLE [dbo].[Orders];
IF OBJECT_ID('dbo.__EFMigrationsHistory','U') IS NOT NULL DROP TABLE [dbo].[__EFMigrationsHistory];

-- ── Drop Sequences ───────────────────────────────────────────────────────────

IF OBJECT_ID('dbo.catalog_brand_hilo', 'SO') IS NOT NULL DROP SEQUENCE [dbo].[catalog_brand_hilo];
IF OBJECT_ID('dbo.catalog_hilo',       'SO') IS NOT NULL DROP SEQUENCE [dbo].[catalog_hilo];
IF OBJECT_ID('dbo.catalog_type_hilo',  'SO') IS NOT NULL DROP SEQUENCE [dbo].[catalog_type_hilo];

-- ── Create Sequences ─────────────────────────────────────────────────────────
-- EF Core uses HiLo sequences for catalog ID generation. Start values are set
-- above the seed data IDs (brands 1–5, types 1–4, items 1–12) so new records
-- added through the UI never collide with the seed data.

CREATE SEQUENCE [dbo].[catalog_brand_hilo] START WITH 100 INCREMENT BY 10;
CREATE SEQUENCE [dbo].[catalog_hilo]       START WITH 100 INCREMENT BY 10;
CREATE SEQUENCE [dbo].[catalog_type_hilo]  START WITH 100 INCREMENT BY 10;

-- ── Catalog Tables ───────────────────────────────────────────────────────────

CREATE TABLE [dbo].[CatalogBrands] (
    [Id]    int           NOT NULL,
    [Brand] nvarchar(100) NOT NULL,
    CONSTRAINT [PK_CatalogBrands] PRIMARY KEY ([Id])
);

CREATE TABLE [dbo].[CatalogTypes] (
    [Id]   int           NOT NULL,
    [Type] nvarchar(100) NOT NULL,
    CONSTRAINT [PK_CatalogTypes] PRIMARY KEY ([Id])
);

CREATE TABLE [dbo].[Catalog] (
    [Id]             int           NOT NULL,
    [Name]           nvarchar(50)  NOT NULL,
    [Description]    nvarchar(max) NULL,
    [Price]          decimal(18,2) NOT NULL,
    [PictureUri]     nvarchar(max) NULL,
    [CatalogTypeId]  int           NOT NULL,
    [CatalogBrandId] int           NOT NULL,
    CONSTRAINT [PK_Catalog] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Catalog_CatalogBrands_CatalogBrandId]
        FOREIGN KEY ([CatalogBrandId]) REFERENCES [dbo].[CatalogBrands] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Catalog_CatalogTypes_CatalogTypeId]
        FOREIGN KEY ([CatalogTypeId])  REFERENCES [dbo].[CatalogTypes]  ([Id]) ON DELETE CASCADE
);

CREATE INDEX [IX_Catalog_CatalogBrandId] ON [dbo].[Catalog] ([CatalogBrandId]);
CREATE INDEX [IX_Catalog_CatalogTypeId]  ON [dbo].[Catalog] ([CatalogTypeId]);

-- ── Basket Tables ────────────────────────────────────────────────────────────

CREATE TABLE [dbo].[Baskets] (
    [Id]      int           IDENTITY(1,1) NOT NULL,
    [BuyerId] nvarchar(256) NOT NULL,
    CONSTRAINT [PK_Baskets] PRIMARY KEY ([Id])
);

CREATE TABLE [dbo].[BasketItems] (
    [Id]            int           IDENTITY(1,1) NOT NULL,
    [UnitPrice]     decimal(18,2) NOT NULL,
    [Quantity]      int           NOT NULL,
    [CatalogItemId] int           NOT NULL,
    [BasketId]      int           NOT NULL,
    CONSTRAINT [PK_BasketItems] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_BasketItems_Baskets_BasketId]
        FOREIGN KEY ([BasketId]) REFERENCES [dbo].[Baskets] ([Id]) ON DELETE CASCADE
);

CREATE INDEX [IX_BasketItems_BasketId] ON [dbo].[BasketItems] ([BasketId]);

-- ── Order Tables ─────────────────────────────────────────────────────────────

CREATE TABLE [dbo].[Orders] (
    [Id]                    int            IDENTITY(1,1) NOT NULL,
    [BuyerId]               nvarchar(256)  NOT NULL DEFAULT '',
    [OrderDate]             datetimeoffset NOT NULL,
    [ShipToAddress_Street]  nvarchar(180)  NOT NULL DEFAULT '',
    [ShipToAddress_City]    nvarchar(100)  NOT NULL DEFAULT '',
    [ShipToAddress_State]   nvarchar(60)   NULL,
    [ShipToAddress_Country] nvarchar(90)   NOT NULL DEFAULT '',
    [ShipToAddress_ZipCode] nvarchar(18)   NOT NULL DEFAULT '',
    CONSTRAINT [PK_Orders] PRIMARY KEY ([Id])
);

CREATE TABLE [dbo].[OrderItems] (
    [Id]                        int           IDENTITY(1,1) NOT NULL,
    [ItemOrdered_CatalogItemId] int           NULL,
    [ItemOrdered_ProductName]   nvarchar(50)  NULL,
    [ItemOrdered_PictureUri]    nvarchar(max) NULL,
    [UnitPrice]                 decimal(18,2) NOT NULL,
    [Units]                     int           NOT NULL,
    [OrderId]                   int           NULL,
    CONSTRAINT [PK_OrderItems] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_OrderItems_Orders_OrderId]
        FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([Id]) ON DELETE NO ACTION
);

CREATE INDEX [IX_OrderItems_OrderId] ON [dbo].[OrderItems] ([OrderId]);

-- ── Identity Tables ───────────────────────────────────────────────────────────
-- Rows are NOT seeded here — ASP.NET Core Identity API creates roles and users
-- at app startup (AppIdentityDbContextSeed) with proper password hashing.

CREATE TABLE [dbo].[AspNetRoles] (
    [Id]               nvarchar(450) NOT NULL,
    [Name]             nvarchar(256) NULL,
    [NormalizedName]   nvarchar(256) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoles] PRIMARY KEY ([Id])
);

CREATE UNIQUE INDEX [RoleNameIndex] ON [dbo].[AspNetRoles] ([NormalizedName])
    WHERE [NormalizedName] IS NOT NULL;

CREATE TABLE [dbo].[AspNetUsers] (
    [Id]                   nvarchar(450)  NOT NULL,
    [UserName]             nvarchar(256)  NULL,
    [NormalizedUserName]   nvarchar(256)  NULL,
    [Email]                nvarchar(256)  NULL,
    [NormalizedEmail]      nvarchar(256)  NULL,
    [EmailConfirmed]       bit            NOT NULL,
    [PasswordHash]         nvarchar(max)  NULL,
    [SecurityStamp]        nvarchar(max)  NULL,
    [ConcurrencyStamp]     nvarchar(max)  NULL,
    [PhoneNumber]          nvarchar(max)  NULL,
    [PhoneNumberConfirmed] bit            NOT NULL,
    [TwoFactorEnabled]     bit            NOT NULL,
    [LockoutEnd]           datetimeoffset NULL,
    [LockoutEnabled]       bit            NOT NULL,
    [AccessFailedCount]    int            NOT NULL,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY ([Id])
);

CREATE INDEX        [EmailIndex]    ON [dbo].[AspNetUsers] ([NormalizedEmail]);
CREATE UNIQUE INDEX [UserNameIndex] ON [dbo].[AspNetUsers] ([NormalizedUserName])
    WHERE [NormalizedUserName] IS NOT NULL;

CREATE TABLE [dbo].[AspNetRoleClaims] (
    [Id]         int           IDENTITY(1,1) NOT NULL,
    [RoleId]     nvarchar(450) NOT NULL,
    [ClaimType]  nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId]
        FOREIGN KEY ([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE
);

CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [dbo].[AspNetRoleClaims] ([RoleId]);

CREATE TABLE [dbo].[AspNetUserClaims] (
    [Id]         int           IDENTITY(1,1) NOT NULL,
    [UserId]     nvarchar(450) NOT NULL,
    [ClaimType]  nvarchar(max) NULL,
    [ClaimValue] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId]
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
);

CREATE INDEX [IX_AspNetUserClaims_UserId] ON [dbo].[AspNetUserClaims] ([UserId]);

CREATE TABLE [dbo].[AspNetUserLogins] (
    [LoginProvider]       nvarchar(450) NOT NULL,
    [ProviderKey]         nvarchar(450) NOT NULL,
    [ProviderDisplayName] nvarchar(max) NULL,
    [UserId]              nvarchar(450) NOT NULL,
    CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY ([LoginProvider], [ProviderKey]),
    CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId]
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
);

CREATE INDEX [IX_AspNetUserLogins_UserId] ON [dbo].[AspNetUserLogins] ([UserId]);

CREATE TABLE [dbo].[AspNetUserRoles] (
    [UserId] nvarchar(450) NOT NULL,
    [RoleId] nvarchar(450) NOT NULL,
    CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY ([UserId], [RoleId]),
    CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId]
        FOREIGN KEY ([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId]
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
);

CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [dbo].[AspNetUserRoles] ([RoleId]);

CREATE TABLE [dbo].[AspNetUserTokens] (
    [UserId]        nvarchar(450) NOT NULL,
    [LoginProvider] nvarchar(450) NOT NULL,
    [Name]          nvarchar(450) NOT NULL,
    [Value]         nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY ([UserId], [LoginProvider], [Name]),
    CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId]
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
);

-- ── Catalog Seed Data ─────────────────────────────────────────────────────────

INSERT INTO [dbo].[CatalogBrands] ([Id], [Brand]) VALUES
    (1, N'Azure'),
    (2, N'.NET'),
    (3, N'Visual Studio'),
    (4, N'SQL Server'),
    (5, N'Other');

INSERT INTO [dbo].[CatalogTypes] ([Id], [Type]) VALUES
    (1, N'Mug'),
    (2, N'T-Shirt'),
    (3, N'Sheet'),
    (4, N'USB Memory Stick');

-- PictureUri placeholder is replaced at runtime by UriComposer:
--   "http://catalogbaseurltobereplaced" → CatalogBaseUrl (empty string in Azure)
--   Result: /images/products/N.png  →  served from wwwroot as a static file
INSERT INTO [dbo].[Catalog]
    ([Id], [CatalogTypeId], [CatalogBrandId], [Description], [Name], [Price], [PictureUri])
VALUES
    ( 1, 2, 2, N'.NET Bot Black Sweatshirt',   N'.NET Bot Black Sweatshirt',   19.50, N'http://catalogbaseurltobereplaced/images/products/1.png'),
    ( 2, 1, 2, N'.NET Black & White Mug',       N'.NET Black & White Mug',       8.50, N'http://catalogbaseurltobereplaced/images/products/2.png'),
    ( 3, 2, 5, N'Prism White T-Shirt',           N'Prism White T-Shirt',          12.00, N'http://catalogbaseurltobereplaced/images/products/3.png'),
    ( 4, 2, 2, N'.NET Foundation Sweatshirt',    N'.NET Foundation Sweatshirt',   12.00, N'http://catalogbaseurltobereplaced/images/products/4.png'),
    ( 5, 3, 5, N'Roslyn Red Sheet',              N'Roslyn Red Sheet',              8.50, N'http://catalogbaseurltobereplaced/images/products/5.png'),
    ( 6, 2, 2, N'.NET Blue Sweatshirt',          N'.NET Blue Sweatshirt',         12.00, N'http://catalogbaseurltobereplaced/images/products/6.png'),
    ( 7, 2, 5, N'Roslyn Red T-Shirt',            N'Roslyn Red T-Shirt',           12.00, N'http://catalogbaseurltobereplaced/images/products/7.png'),
    ( 8, 2, 5, N'Kudu Purple Sweatshirt',        N'Kudu Purple Sweatshirt',        8.50, N'http://catalogbaseurltobereplaced/images/products/8.png'),
    ( 9, 1, 5, N'Cup<T> White Mug',             N'Cup<T> White Mug',             12.00, N'http://catalogbaseurltobereplaced/images/products/9.png'),
    (10, 3, 2, N'.NET Foundation Sheet',         N'.NET Foundation Sheet',        12.00, N'http://catalogbaseurltobereplaced/images/products/10.png'),
    (11, 3, 2, N'Cup<T> Sheet',                 N'Cup<T> Sheet',                  8.50, N'http://catalogbaseurltobereplaced/images/products/11.png'),
    (12, 2, 5, N'Prism White TShirt',            N'Prism White TShirt',           12.00, N'http://catalogbaseurltobereplaced/images/products/12.png');

COMMIT TRANSACTION;
PRINT 'Database initialized: all tables created, catalog data seeded.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Database initialization failed: ' + ERROR_MESSAGE();
    THROW;
END CATCH
