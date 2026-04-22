# eShopOnWeb Migration Prompt

> Send this entire file back to GitHub Copilot to execute the migration.
> All changes should be applied to the current repo root at `c:\Users\RandyPagels\source\eShopOnWeb`.
> The reference source is `ADO_VERION/eShopOnWeb/` within this workspace.
> Do NOT modify anything inside the `ADO_VERION/` folder.

---

## Context & Rules

- **Target framework**: Keep .NET 8.0 (do NOT regress to 7.0).
- **Preserve** all features already in the current codebase: Azure Key Vault, Azure App Configuration, Feature Flags (`SalesWeekend`), `SettingsViewModel` / dynamic `NoResultsMessage`, `azure.yaml`, `azd`-compatible `infra/` structure, NSubstitute/Moq test packages.
- **Do NOT** copy hardcoded secrets from `ADO_VERION` (e.g. the Azure SQL password and App Insights key in `appsettings.json`). Keep secrets externalised via Key Vault / environment variables.
- **Convert** every Azure DevOps pipeline (`.yml`) to a GitHub Actions workflow under `.github/workflows/`.
- Read every file listed before editing it. After all edits, run `dotnet build src/Web/Web.csproj` to verify there are no compile errors.

---

## Task 1 — GitHub Actions Workflows

Create `.github/workflows/` (if it doesn't exist) and add the following three workflow files. Base the logic on `ADO_VERION/eShopOnWeb/azure-pipelines-builddeploy.yml`, `azure-pipelines-pullrequest.yml`, `azure-pipelines-playwright-test.yml`, and `azure-pipelines-codeql.yml`, but rewrite as GitHub Actions YAML.

### 1a. `ci-cd.yml` — Main Build, Test, Deploy, Playwright

Trigger: push to `main`, pull_request to `main`.

Jobs (in order, each depending on the prior):

**Job: build**
- `ubuntu-latest`
- Steps:
  1. Checkout
  2. Setup .NET 8.0
  3. Generate version number using the same logic as `ADO_VERION/eShopOnWeb/GenerateVersionNumber.ps1` — copy that script to the repo root as `GenerateVersionNumber.ps1` and call it via `pwsh`. Expose output as `BUILD_NUMBER` env var.
  4. `dotnet restore eShopOnWeb.sln`
  5. `dotnet build eShopOnWeb.sln --no-restore -p:Version=$BUILD_NUMBER -p:AssemblyVersion=$BUILD_NUMBER -p:FileVersion=$BUILD_NUMBER -c Release`
  6. `dotnet test eShopOnWeb.sln --no-build -c Release --settings CodeCoverage.runsettings --collect "XPlat Code Coverage"`
  7. `dotnet publish src/Web/Web.csproj -c Release --no-build -o ./publish`
  8. Upload artifact `webapp` from `./publish`
  9. Upload artifact `dbscripts` from `DBscripts/`
  10. Upload artifact `playwright-files` from: `package.json`, `package-lock.json`, `playwright.config.ts`, `playwright.service.config.ts`, `tests/PlaywrightTests/`

**Job: deploy-infrastructure** (needs: build, only on push to main)
- `ubuntu-latest`
- Uses secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, `SQL_ADMIN_PASSWORD`
- Steps:
  1. Checkout
  2. Azure login via OIDC (`azure/login@v2` with `client-id`, `tenant-id`, `subscription-id`)
  3. Deploy Bicep: `az deployment group create --resource-group ${{ secrets.AZURE_RESOURCE_GROUP }} --template-file infra/main.bicep --parameters infra/main.parameters.json sqlAdminPassword=${{ secrets.SQL_ADMIN_PASSWORD }}` 
  4. Parse outputs with `ParseDeploymentOutputs.ps1` (copy from ADO_VERSION to repo root) to set `WEB_APP_NAME` and `SQL_SERVER_NAME` as step outputs

**Job: seed-database** (needs: deploy-infrastructure, only on push to main)
- `ubuntu-latest`
- Steps:
  1. Checkout
  2. Azure login via OIDC
  3. Download artifact `dbscripts`
  4. Run `DBscripts/CatalogDB.sql` against the Azure SQL server using `az sql db execute` or `sqlcmd`
  5. Run `DBscripts/IdentityDB.sql`

**Job: deploy-app** (needs: seed-database, only on push to main)
- `ubuntu-latest`
- Steps:
  1. Download artifact `webapp`
  2. Azure login via OIDC
  3. Deploy to Azure Web App using `azure/webapps-deploy@v3` with the web app name from `deploy-infrastructure` outputs

**Job: playwright-tests** (needs: deploy-app, only on push to main)
- `ubuntu-latest`
- Steps:
  1. Checkout
  2. Setup Node.js 18
  3. Download artifact `playwright-files`
  4. `npm ci`
  5. `npx playwright install --with-deps`
  6. `npx playwright test` using `playwright.config.ts` with `BASE_URL` set to the deployed app URL
  7. Upload artifact `playwright-report` from `playwright-report/` on failure
  8. Publish test results (junit XML) using `dorny/test-reporter@v1`

### 1b. `codeql.yml` — Security Scanning

Trigger: push to `main`, pull_request to `main`, schedule weekly.

- Single job on `ubuntu-latest`
- Uses `github/codeql-action/init@v3` with languages `csharp, javascript`
- Autobuild
- `github/codeql-action/analyze@v3`

### 1c. `dependabot.yml` — Already goes in `.github/`

Copy `ADO_VERION/eShopOnWeb/.github/dependabot.yml` verbatim to `.github/dependabot.yml`.

---

## Task 2 — Infrastructure / Bicep

Read all current files in `infra/` and all files in `ADO_VERION/eShopOnWeb/env/eshopenv/`.

The `infra/` folder should keep its `azd`-compatible, subscription-scoped structure, but be enriched with the following modules from the ADO version:

### 2a. Add `infra/modules/appinsights.bicep`
Create a new module based on `ADO_VERION/eShopOnWeb/env/eshopenv/main-appinsights.bicep`.
Include:
- Log Analytics Workspace
- Application Insights resource linked to the workspace
- A metric alert for HTTP 5xx errors
- A web availability (ping) test against the home page URL

Parameters: `location`, `resourceNamePrefix`, `webAppUrl`, `tags`.
Output: `appInsightsConnectionString`, `appInsightsInstrumentationKey`.

### 2b. Add `infra/modules/dashboard.bicep`
Create a new module based on `ADO_VERION/eShopOnWeb/env/eshopenv/main-dashboard.bicep`.
Parameters: `location`, `resourceNamePrefix`, `appInsightsId`, `tags`.

### 2c. Update `infra/main.bicep`
Read the current `infra/main.bicep` first. Then add:
- A parameter `deployAppInsights bool = true`
- A conditional module call for `appinsights.bicep` (when `deployAppInsights == true`)
- A conditional module call for `dashboard.bicep` (when `deployAppInsights == true`)
- Pass `appInsightsConnectionString` output to the web app module as an app setting (`APPLICATIONINSIGHTS_CONNECTION_STRING`)
- Do NOT change the subscription scope or azd compatibility

### 2d. Update `infra/main.parameters.json`
Add `"deployAppInsights": { "value": true }` parameter.

---

## Task 3 — Database Scripts

Copy the following files from `ADO_VERION/eShopOnWeb/DBscripts/` to `DBscripts/` at the repo root (create the folder):
- `CatalogDB.sql`
- `IdentityDB.sql`
- `EntityRelationshipDiagram.md`

Also copy:
- `ADO_VERION/eShopOnWeb/GenerateVersionNumber.ps1` → `GenerateVersionNumber.ps1` (repo root)
- `ADO_VERION/eShopOnWeb/ParseDeploymentOutputs.ps1` → `ParseDeploymentOutputs.ps1` (repo root)

---

## Task 4 — Application Insights Integration (src/)

The current codebase does NOT have Application Insights. Add it without hardcoding any keys.

### 4a. `Directory.Packages.props`
Read the current file. Add these packages (using .NET 8-compatible versions):
```xml
<PackageVersion Include="Microsoft.ApplicationInsights.AspNetCore" Version="2.22.0" />
<PackageVersion Include="Microsoft.ApplicationInsights.SnapshotCollector" Version="1.4.6" />
```

### 4b. `src/Web/Web.csproj`
Read the current file. Add:
```xml
<PackageReference Include="Microsoft.ApplicationInsights.AspNetCore" />
```

### 4c. `src/Web/Program.cs`
Read the current file. In the service registration section (after `builder.Services.AddRazorPages()`), add:
```csharp
// Application Insights — connection string injected via Key Vault / environment variable
var appInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
if (!string.IsNullOrEmpty(appInsightsConnectionString))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = appInsightsConnectionString;
    });
}
```

### 4d. `src/Web/Pages/Basket/Index.cshtml.cs`
Read the current file. Add `TelemetryClient` injection for tracking purchase telemetry:
- Add `using Microsoft.ApplicationInsights;`
- Inject `TelemetryClient? telemetryClient = null` (nullable, so it works when App Insights is not configured)
- In the `OnPost` / checkout handler, track a custom event: `telemetryClient?.TrackEvent("BasketUpdated", new Dictionary<string, string> { ["itemCount"] = basket.Items.Count.ToString() });`

---

## Task 5 — Build Version Embedding

### 5a. Create `src/Web/GetAssemblyVersion.cs`
Copy from `ADO_VERION/eShopOnWeb/src/Web/GetAssemblyVersion.cs` verbatim. Read it first.

### 5b. Update `src/Web/Views/Shared/_Layout.cshtml`
Read the current file. Replace the footer plain-text copyright line with:
```html
<footer class="esh-app-footer">
    <div class="container">
        <article class="row">
            <section class="col-sm-6">
                <img class="esh-app-footer-brand" src="~/images/brand.png" />
            </section>
            <section class="col-sm-6">
                <p class="esh-app-footer-text hidden-xs">Build @Microsoft.eShopWeb.Web.MyAppVersion.GetAssemblyVersion() | @Microsoft.eShopWeb.Web.MyAppVersion.GetDateTimeFromVersion()</p>
                <p class="esh-app-footer-text">&copy; eShopOnWeb. All rights reserved</p>
                <p class="esh-app-footer-text"><a asp-page="/privacy">Privacy</a></p>
            </section>
        </article>
    </div>
</footer>
```
Match the exact indentation of the existing footer markup.

---

## Task 6 — Playwright Component IDs in src/Web

For every file below: read the current file first, then add the `id=` attributes exactly as shown. Do NOT change any other markup.

### 6a. `src/Web/Pages/Index.cshtml`
- On the brand filter `<select>` element: add `id="Index-Select-BrandFilter"`
- On the type filter `<select>` element: add `id="Index-Select-TypeFilter"`
- On the Apply Filter `<button>` or `<input type="submit">`: add `id="Index-Button-ApplyFilter"`
- On the no-results message `<div>`: add `id="esh-pager-item-msg"` (keep the existing dynamic `@Model.SettingsModel.NoResultsMessage` content — do NOT replace it with hardcoded text)
- Split `<partial name="_pagination">` into two separate partials:
  - Top call: `<partial name="_pagination_top" model="Model.CatalogModel" />`
  - Bottom call: `<partial name="_pagination_bottom" model="Model.CatalogModel" />`

### 6b. Create `src/Web/Pages/Shared/_pagination_top.cshtml`
Based on the current `_pagination.cshtml`. Add IDs:
- Previous link: `id="PaginationTop-Link-Previous"`
- No-results message span: `id="esh-pager-item-msg-top"`
- Next link: `id="PaginationTop-Link-Next"`

### 6c. Create `src/Web/Pages/Shared/_pagination_bottom.cshtml`
Same structure as `_pagination_top.cshtml` but IDs:
- Previous link: `id="PaginationBottom-Link-Previous"`
- No-results message span: `id="esh-pager-item-msg-bottom"`
- Next link: `id="PaginationBottom-Link-Next"`

### 6d. `src/Web/Pages/Shared/_product.cshtml`
- On the Add to Basket button/form-submit: add `id="Product-Button-AddToBasket-@Model.Id"`

### 6e. `src/Web/Pages/Basket/Index.cshtml`
- Quantity `<input>`: add `id="BasketIndex-Input-Quantity-@item.Id"`
- Total `<span>` or `<div>`: add `id="basket-total"`
- Continue Shopping `<a>`: add `id="BasketIndex-Link-ContinueShopping"`
- Update basket `<button>`: add `id="BasketIndex-Button-Update"`
- Proceed to Checkout `<a>` or `<button>`: add `id="BasketIndex-Link-Checkout"`

### 6f. `src/Web/Pages/Basket/Checkout.cshtml`
- Back `<a>` link: add `id="Checkout-Link-Back"`
- Pay Now `<button>`: add `id="Checkout-Button-PayNow"`

### 6g. `src/Web/Pages/Basket/Success.cshtml`
- Continue Shopping `<a>`: add `id="Success-Link-ContinueShopping"`

### 6h. `src/Web/Views/Shared/_LoginPartial.cshtml`
Read the current file. Add IDs:
- Admin link: `id="LoginPartial-Link-Admin"`
- My Orders link: `id="LoginPartial-Link-MyOrders"`
- My Account link: `id="LoginPartial-Link-MyAccount"`
- Logout link/button: `id="LoginPartial-Link-Logout"`
- Login link (unauthenticated state): `id="LoginPartial-Link-Login"`

### 6i. `src/Web/Areas/Identity/Pages/Account/Login.cshtml`
Read the current file. Add IDs:
- Email `<input>`: `id="Login-Input-Email"` (check it doesn't conflict with the existing `asp-for` generated id; use the `id` HTML attribute explicitly)
- Password `<input>`: `id="Login-Input-Password"`
- Remember Me `<input type="checkbox">`: `id="Login-Checkbox-RememberMe"`
- Submit `<button>`: `id="Login-Button-Submit"`
- Forgot Password `<a>`: `id="Login-Link-ForgotPassword"`
- Register `<a>`: `id="Login-Link-Register"`

### 6j. `src/Web/Views/Manage/MyAccount.cshtml` (if present — check first)
If the file exists, add IDs:
- Username `<input>`: `id="MyAccount-Input-Username"`
- Email `<input>`: `id="MyAccount-Input-Email"`
- Send Verification Email `<button>`: `id="MyAccount-Button-SendVerificationEmail"`
- Phone `<input>`: `id="MyAccount-Input-PhoneNumber"`
- Save `<button>`: `id="MyAccount-Button-Save"`

---

## Task 7 — Playwright Test Infrastructure

### 7a. Copy test files
Copy these files from `ADO_VERION/eShopOnWeb/` to the repo root (create directories as needed):
- `playwright.config.ts` → `playwright.config.ts` (overwrite if exists)
- `playwright.service.config.ts` → `playwright.service.config.ts` (overwrite if exists)
- `package.json` → `package.json` (overwrite if exists)

Then update `playwright.config.ts`:
- Change `baseURL` from the hardcoded `azurewebsites.net` URL to `process.env.BASE_URL ?? 'https://localhost:5001'`
- Remove the `@alex_neo/playwright-azure-reporter` reporter entry (ADO-specific; not needed for GitHub Actions)
- Keep all other reporters (list, html, json, junit)

### 7b. Copy test specs
Copy `ADO_VERION/eShopOnWeb/tests/PlaywrightTests/` → `tests/PlaywrightTests/` (create directory).

Copy all `.ts` spec files. Then fix the two broken element IDs in `tests/PlaywrightTests/ShopForLargeQuantites.spec.ts`:
- Replace `#Header-Link-Login` with `#LoginPartial-Link-Login`
- Replace `#Header-Link-Logout` with `#LoginPartial-Link-Logout`

---

## Task 8 — Authentication Verification

Read `src/Web/appsettings.json` and `src/Web/appsettings.Development.json`. Verify:
- Authentication / Identity is configured (ASP.NET Core Identity)
- `CatalogConnection` and `IdentityConnection` in `appsettings.Development.json` use LocalDB for local dev
- `appsettings.json` does NOT contain any hardcoded production passwords or keys

If any hardcoded secrets from the ADO version were accidentally copied, remove them and replace with empty strings or environment variable references.

Read `src/Web/Program.cs` and verify that `AddDefaultIdentity` or equivalent is called. If not, add it.

---

## Task 9 — Verify & Build

1. Run: `dotnet restore eShopOnWeb.sln`
2. Run: `dotnet build eShopOnWeb.sln -c Release`
3. If there are compile errors, fix them before considering the migration complete.
4. Run: `dotnet test eShopOnWeb.sln --no-build -c Release` and report any test failures.

---

## Task 10 — Final Checklist

After all tasks complete, confirm each item:

- [ ] `.github/workflows/ci-cd.yml` exists and is valid YAML
- [ ] `.github/workflows/codeql.yml` exists and is valid YAML
- [ ] `.github/dependabot.yml` exists
- [ ] `DBscripts/CatalogDB.sql` and `DBscripts/IdentityDB.sql` exist
- [ ] `GenerateVersionNumber.ps1` and `ParseDeploymentOutputs.ps1` exist at repo root
- [ ] `infra/modules/appinsights.bicep` exists
- [ ] `infra/modules/dashboard.bicep` exists
- [ ] `infra/main.bicep` references the new App Insights module
- [ ] `src/Web/GetAssemblyVersion.cs` exists
- [ ] `src/Web/Views/Shared/_Layout.cshtml` footer shows build version
- [ ] All Playwright `id=` attributes added across 10 files
- [ ] `src/Web/Pages/Shared/_pagination_top.cshtml` and `_pagination_bottom.cshtml` exist
- [ ] `tests/PlaywrightTests/` contains all spec files with fixed IDs
- [ ] `playwright.config.ts` uses `BASE_URL` env var, not hardcoded URL
- [ ] No hardcoded secrets in any tracked file
- [ ] `dotnet build` succeeds with 0 errors
