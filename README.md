# GHAzDO Vulnerabilities Added on Purpose

# Build Status
[![Build Status](https://dev.azure.com/xpirit/eShopOnWeb/_apis/build/status%2FeShopOnWeb-Build?branchName=main)](https://dev.azure.com/xpirit/eShopOnWeb/_build/latest?definitionId=746&branchName=main)

# Code Scanning Status
[![Code Scanning Status](https://dev.azure.com/xpirit/eShopOnWeb/_apis/build/status%2FeShopOnWeb-CodeScanning?branchName=main)](https://dev.azure.com/xpirit/eShopOnWeb/_build/latest?definitionId=747&branchName=main)

## Dependency Scanning

### Critical
> .NET Core Remote Code Execution Vulnerability (GHSA-rxg9-xrhp-64gj)
Upgrade System.Drawing.Common from 5.0.0 to 5.0.3 to fix the vulnerability.
src/Infrastructure/Infrastructure.csproj

### High
> Cookie parsing failure (GHSA-hxrm-9w7p-39cc)
Upgrade Microsoft.AspNetCore.Http from 2.1.0 to 2.1.22 to fix the vulnerability.
src/PublicApi/PublicApi.csproj


## Code Scanning

### Critical
> Resource injection (cs/resource-injection)
in src/Web/Controllers/ManageController.cs:557 (+1)

> Hard-coded credentials (cs/hardcoded-credentials)
in src/ApplicationCore/Constants/AuthorizationConstants.cs:8

> Hard-coded credentials (cs/hardcoded-credentials)
in src/Infrastructure/Identity/AppIdentityDbContextSeed.cs:20

> Hard-coded credentials (cs/hardcoded-credentials)
in src/Infrastructure/Identity/AppIdentityDbContextSeed.cs:23

### High
> SQL query built from user-controlled sources (cs/sql-injection)
in src/Web/Controllers/ManageController.cs:559 (+1)

> SQL query built from stored user-controlled sources (cs/second-order-sql-injection)
in src/Web/Controllers/ManageController.cs:559 (+1)

> Insecure SQL connection (cs/insecure-sql-connection)
in src/Web/Controllers/ManageController.cs:557 (+1)

## Secret Scanning

### Critical
> Microsoft Azure CosmosDB identifiable master key …d9Vg==
in src/Web/appsettings.json:7

# Reference Application
[Microsoft eShopOnWeb ASP.NET Core Reference Application](https://github.com/dotnet-architecture/eShopOnWeb) 
