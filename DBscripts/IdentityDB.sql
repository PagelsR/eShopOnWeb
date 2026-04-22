-- IdentityDB.sql
-- eShopOnWeb Identity Database Seeding Script
-- This script creates and seeds the identity database with ASP.NET Core Identity tables and test users

USE [identityDatabase];
GO

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
-- This script ensures the database structure is ready

PRINT 'Identity database prepared for user seeding by application';
GO
