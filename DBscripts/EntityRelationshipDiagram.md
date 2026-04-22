# eShopOnWeb Database Entity Relationship Diagram

## Overview
The eShopOnWeb application uses two separate databases for separation of concerns:
- **CatalogDB**: Product catalog and inventory management
- **IdentityDB**: User authentication and authorization (ASP.NET Core Identity)

---

## CatalogDB Schema

### Tables

#### CatalogBrands
Stores product brands (e.g., Azure, .NET, Visual Studio)
- `Id` (INT, PK, IDENTITY): Primary key
- `Brand` (NVARCHAR(100), NOT NULL): Brand name

#### CatalogTypes
Stores product categories/types (e.g., Mug, T-Shirt, USB Memory Stick)
- `Id` (INT, PK, IDENTITY): Primary key
- `Type` (NVARCHAR(100), NOT NULL): Type/category name

#### CatalogItems
Stores individual products with pricing and inventory information
- `Id` (INT, PK, IDENTITY): Primary key
- `Name` (NVARCHAR(50), NOT NULL): Product name
- `Description` (NVARCHAR(MAX), NULL): Product description
- `Price` (DECIMAL(18,2), NOT NULL): Product price
- `PictureFileName` (NVARCHAR(MAX), NULL): Image filename
- `PictureUri` (NVARCHAR(MAX), NULL): Image URI
- `CatalogTypeId` (INT, FK, NOT NULL): Foreign key to CatalogTypes
- `CatalogBrandId` (INT, FK, NOT NULL): Foreign key to CatalogBrands
- `AvailableStock` (INT, NOT NULL, DEFAULT 0): Current stock quantity
- `RestockThreshold` (INT, NOT NULL, DEFAULT 0): Minimum stock before reorder
- `MaxStockThreshold` (INT, NOT NULL, DEFAULT 0): Maximum stock capacity
- `OnReorder` (BIT, NOT NULL, DEFAULT 0): Whether product is on reorder

### Relationships

```
CatalogBrands (1) ----< (M) CatalogItems
CatalogTypes  (1) ----< (M) CatalogItems
```

- Each CatalogItem belongs to one CatalogBrand (Many-to-One)
- Each CatalogItem belongs to one CatalogType (Many-to-One)
- Each Brand can have many CatalogItems (One-to-Many)
- Each Type can have many CatalogItems (One-to-Many)

---

## IdentityDB Schema

### Tables (ASP.NET Core Identity)

The Identity database uses standard ASP.NET Core Identity schema:

#### AspNetUsers
Stores user accounts
- `Id` (NVARCHAR(450), PK): User identifier
- `UserName` (NVARCHAR(256)): Username
- `NormalizedUserName` (NVARCHAR(256)): Normalized username for lookups
- `Email` (NVARCHAR(256)): Email address
- `NormalizedEmail` (NVARCHAR(256)): Normalized email for lookups
- `EmailConfirmed` (BIT): Whether email is confirmed
- `PasswordHash` (NVARCHAR(MAX)): Hashed password
- `SecurityStamp` (NVARCHAR(MAX)): Security stamp for invalidation
- `ConcurrencyStamp` (NVARCHAR(MAX)): Concurrency token
- `PhoneNumber` (NVARCHAR(MAX)): Phone number
- `PhoneNumberConfirmed` (BIT): Whether phone is confirmed
- `TwoFactorEnabled` (BIT): 2FA enabled flag
- `LockoutEnd` (DATETIMEOFFSET): Lockout expiration
- `LockoutEnabled` (BIT): Whether lockout is enabled
- `AccessFailedCount` (INT): Failed login attempts

#### AspNetRoles
Stores user roles (e.g., Administrators, Users)
- `Id` (NVARCHAR(450), PK): Role identifier
- `Name` (NVARCHAR(256)): Role name
- `NormalizedName` (NVARCHAR(256)): Normalized role name
- `ConcurrencyStamp` (NVARCHAR(MAX)): Concurrency token

#### AspNetUserRoles
Many-to-many relationship between users and roles
- `UserId` (NVARCHAR(450), FK, PK): User identifier
- `RoleId` (NVARCHAR(450), FK, PK): Role identifier

#### AspNetUserClaims
Stores user claims
- `Id` (INT, PK, IDENTITY): Claim identifier
- `UserId` (NVARCHAR(450), FK): User identifier
- `ClaimType` (NVARCHAR(MAX)): Claim type
- `ClaimValue` (NVARCHAR(MAX)): Claim value

#### AspNetUserLogins
Stores external login provider information
- `LoginProvider` (NVARCHAR(450), PK): Login provider name
- `ProviderKey` (NVARCHAR(450), PK): Provider key
- `ProviderDisplayName` (NVARCHAR(MAX)): Provider display name
- `UserId` (NVARCHAR(450), FK): User identifier

#### AspNetUserTokens
Stores authentication tokens
- `UserId` (NVARCHAR(450), FK, PK): User identifier
- `LoginProvider` (NVARCHAR(450), PK): Login provider
- `Name` (NVARCHAR(450), PK): Token name
- `Value` (NVARCHAR(MAX)): Token value

#### AspNetRoleClaims
Stores role claims
- `Id` (INT, PK, IDENTITY): Claim identifier
- `RoleId` (NVARCHAR(450), FK): Role identifier
- `ClaimType` (NVARCHAR(MAX)): Claim type
- `ClaimValue` (NVARCHAR(MAX)): Claim value

### Relationships

```
AspNetUsers (1) ----< (M) AspNetUserRoles >---- (M) AspNetRoles (1)
AspNetUsers (1) ----< (M) AspNetUserClaims
AspNetUsers (1) ----< (M) AspNetUserLogins
AspNetUsers (1) ----< (M) AspNetUserTokens
AspNetRoles (1) ----< (M) AspNetRoleClaims
```

---

## Database Seeding

### Catalog Database
- **5 Brands**: Azure, .NET, Visual Studio, SQL Server, Other
- **4 Types**: Mug, T-Shirt, Sheet, USB Memory Stick
- **12 Products**: Various .NET and Azure branded merchandise

### Identity Database
- **2 Roles**: Administrators, Users
- **Test Users**: Created by application startup logic
  - Admin user: admin@example.com
  - Demo user: demo@example.com

---

## Connection Strings

Connection strings are stored securely in Azure Key Vault and referenced via configuration:
- `AZURE-SQL-CATALOG-CONNECTION-STRING`: Catalog database connection
- `AZURE-SQL-IDENTITY-CONNECTION-STRING`: Identity database connection

The application retrieves these from Key Vault at runtime using Azure Managed Identity.
