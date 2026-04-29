-- eShopOnWeb Catalog Seed Data
-- Runs on every CI/CD deployment to ensure consistent catalog state.
-- Tables targeted: CatalogBrands, CatalogTypes, Catalog (items)
-- Safe to re-run: wraps everything in a transaction and rolls back on error.
-- No FK constraints point at Catalog from Orders or Baskets, so DELETE is safe.

BEGIN TRANSACTION;

BEGIN TRY

    -- Clear in FK-safe order (Catalog rows reference CatalogBrands and CatalogTypes)
    DELETE FROM [dbo].[Catalog];
    DELETE FROM [dbo].[CatalogBrands];
    DELETE FROM [dbo].[CatalogTypes];

    -- ── Brands ──────────────────────────────────────────────────────────────
    INSERT INTO [dbo].[CatalogBrands] ([Id], [Brand]) VALUES
        (1, N'Azure'),
        (2, N'.NET'),
        (3, N'Visual Studio'),
        (4, N'SQL Server'),
        (5, N'Other');

    -- ── Types ───────────────────────────────────────────────────────────────
    INSERT INTO [dbo].[CatalogTypes] ([Id], [Type]) VALUES
        (1, N'Mug'),
        (2, N'T-Shirt'),
        (3, N'Sheet'),
        (4, N'USB Memory Stick');

    -- ── Items ───────────────────────────────────────────────────────────────
    -- CatalogTypeId / CatalogBrandId match the IDs inserted above.
    -- PictureUri uses the placeholder prefix; UriComposer replaces it at runtime
    -- with CatalogBaseUrl (empty string in Azure → resolves to /images/products/N.png).
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
    PRINT 'Catalog seed completed: 5 brands, 4 types, 12 items.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Catalog seed failed: ' + ERROR_MESSAGE();
    THROW;
END CATCH
