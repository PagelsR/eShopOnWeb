---
name: Conversion.ADO_GitHub
description: "Migrate the eShopOnWeb codebase to be on par with the enhanced ADO_VERSION: convert Azure DevOps pipelines to GitHub Actions, enrich Bicep infra with App Insights, add DB seed scripts, add Application Insights SDK, add Playwright component IDs, and copy Playwright test specs. Use when: ADO to GitHub migration, update infra, add playwright IDs, seed database, sync ADO_VERSION."
agent: agent
tools: [read_file, create_file, replace_string_in_file, multi_replace_string_in_file, list_dir, file_search, grep_search, execution_subagent]
argument-hint: "Run full ADO→GitHub migration (all 10 tasks), or specify a subset e.g. 'Task 6 only'"
---

## Context & Ground Rules

- **Reference source**: `ADO_VERION/eShopOnWeb/` inside this workspace. Read files from there before copying.
- **Do NOT modify** anything inside `ADO_VERION/`.
- **Target framework**: Keep .NET 8.0. Do NOT regress to .NET 7.
- **Preserve** existing current-codebase features: Azure Key Vault, Azure App Configuration, Feature Flags (`SalesWeekend`), `SettingsViewModel`, `azure.yaml`, `azd`-compatible `infra/` structure, NSubstitute/Moq packages.
- **No hardcoded secrets**: Do not copy the plain-text Azure SQL password or App Insights instrumentation key from `ADO_VERION/eShopOnWeb/src/Web/appsettings.json`. Keep all secrets externalised.
- Read every file before editing it. After all edits, run `dotnet build eShopOnWeb.sln` to verify zero compile errors.

---

## Task 1 — GitHub Actions Workflows

Create `.github/workflows/` and add three workflow files. Base logic on the ADO pipelines in `ADO_VERION/eShopOnWeb/`, but rewrite as GitHub Actions YAML targeting .NET 8.

### 1a. `.github/workflows/ci-cd.yml` — Build → Infra → DB Seed → Deploy → Playwright

Trigger: `push` to `main`, `pull_request` to `main`.

Define these as workflow-level `env:` variables (hardcoded, not secrets) at the top of the file:
```yaml
env:
  AZURE_RESOURCE_GROUP: rg-eshoponweb
  AZURE_LOCATION: eastus
```
Reference them as `${{ env.AZURE_RESOURCE_GROUP }}` and `${{ env.AZURE_LOCATION }}` throughout the workflow instead of `${{ secrets.AZURE_RESOURCE_GROUP }}` and `${{ secrets.AZURE_LOCATION }}`.

**Job: build** (`ubuntu-latest`)
1. Checkout
2. Setup .NET 8.0
3. Run `GenerateVersionNumber.ps1` via `pwsh`; expose result as `BUILD_NUMBER` env var
4. `dotnet restore eShopOnWeb.sln`
5. `dotnet build eShopOnWeb.sln --no-restore -c Release -p:Version=$BUILD_NUMBER -p:AssemblyVersion=$BUILD_NUMBER -p:FileVersion=$BUILD_NUMBER`
6. `dotnet test eShopOnWeb.sln --no-build -c Release --settings CodeCoverage.runsettings --collect "XPlat Code Coverage"`
7. `dotnet publish src/Web/Web.csproj -c Release --no-build -o ./publish`
8. Upload artifact `webapp` from `./publish`
9. Upload artifact `dbscripts` from `DBscripts/`
10. Upload artifact `playwright-files` from `package.json`, `package-lock.json`, `playwright.config.ts`, `playwright.service.config.ts`, `tests/PlaywrightTests/`

**Job: deploy-infrastructure** (needs: build; only on push to main)
- OIDC login via `azure/login@v2` using secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- **Create resource group if it does not exist** (idempotent):
  ```bash
  az group create --name ${{ env.AZURE_RESOURCE_GROUP }} --location ${{ env.AZURE_LOCATION }} --output none
  ```
- **Assign Contributor role to the service principal on the resource group if not already assigned** (idempotent):
  ```bash
  az role assignment create \
    --assignee ${{ secrets.AZURE_CLIENT_ID }} \
    --role Contributor \
    --scope "/subscriptions/${{ secrets.AZURE_SUBSCRIPTION_ID }}/resourceGroups/${{ env.AZURE_RESOURCE_GROUP }}" \
    --output none 2>/dev/null || true
  ```
  The `|| true` prevents failure if the assignment already exists.
- `az deployment group create --resource-group ${{ env.AZURE_RESOURCE_GROUP }} --template-file infra/main.bicep --parameters infra/main.parameters.json sqlAdminPassword=${{ secrets.SQL_ADMIN_PASSWORD }}`
- Parse outputs with `ParseDeploymentOutputs.ps1` to set `WEB_APP_NAME` as a step output

**Job: seed-database** (needs: deploy-infrastructure; only on push to main)
- Download artifact `dbscripts`
- Azure OIDC login
- Run `DBscripts/CatalogDB.sql` and `DBscripts/IdentityDB.sql` against the Azure SQL server

**Job: deploy-app** (needs: seed-database; only on push to main)
- Download artifact `webapp`
- Azure OIDC login
- Deploy with `azure/webapps-deploy@v3` using `WEB_APP_NAME` from prior job output

**Job: playwright-tests** (needs: deploy-app; only on push to main)
- Setup Node.js 18
- Download artifact `playwright-files`
- `npm ci`
- `npx playwright install --with-deps`
- `npx playwright test` with `BASE_URL` set to deployed app URL
- Upload `playwright-report/` on failure
- Publish junit results with `dorny/test-reporter@v1`

### 1b. `.github/workflows/codeql.yml` — Security Scanning

Trigger: push to `main`, pull_request to `main`, weekly schedule.
- `github/codeql-action/init@v3` with `languages: ['csharp', 'javascript']`
- Autobuild
- `github/codeql-action/analyze@v3`

### 1c. `.github/dependabot.yml`

Copy `ADO_VERION/eShopOnWeb/.github/dependabot.yml` verbatim.

---

## Task 2 — Infra / Bicep Enrichment

Read all files in `infra/` and `ADO_VERION/eShopOnWeb/env/eshopenv/`. Keep the existing `azd`-compatible, subscription-scoped structure.

### 2a. Create `infra/modules/appinsights.bicep`
Based on `ADO_VERION/eShopOnWeb/env/eshopenv/main-appinsights.bicep`. Include:
- Log Analytics Workspace
- Application Insights linked to the workspace
- Metric alert for HTTP 5xx errors
- Web availability ping test against the home page URL

Parameters: `location`, `resourceNamePrefix`, `webAppUrl`, `tags`.  
Outputs: `appInsightsConnectionString`, `appInsightsInstrumentationKey`.

### 2b. Create `infra/modules/dashboard.bicep`
Based on `ADO_VERION/eShopOnWeb/env/eshopenv/main-dashboard.bicep`.  
Parameters: `location`, `resourceNamePrefix`, `appInsightsId`, `tags`.

### 2c. Update `infra/main.bicep`
Add:
- Parameter `deployAppInsights bool = true`
- Conditional module call for `appinsights.bicep`
- Conditional module call for `dashboard.bicep`
- Pass `appInsightsConnectionString` to the web app module as app setting `APPLICATIONINSIGHTS_CONNECTION_STRING`

### 2d. Update `infra/main.parameters.json`
Add `"deployAppInsights": { "value": true }`.

---

## Task 3 — Database Scripts & Helper Scripts

Copy to repo root / `DBscripts/` (create folder):
- `ADO_VERION/eShopOnWeb/DBscripts/CatalogDB.sql` → `DBscripts/CatalogDB.sql`
- `ADO_VERION/eShopOnWeb/DBscripts/IdentityDB.sql` → `DBscripts/IdentityDB.sql`
- `ADO_VERION/eShopOnWeb/DBscripts/EntityRelationshipDiagram.md` → `DBscripts/EntityRelationshipDiagram.md`
- `ADO_VERION/eShopOnWeb/GenerateVersionNumber.ps1` → `GenerateVersionNumber.ps1`
- `ADO_VERION/eShopOnWeb/ParseDeploymentOutputs.ps1` → `ParseDeploymentOutputs.ps1`

---

## Task 4 — Application Insights Integration

### 4a. `Directory.Packages.props`
Add (using .NET 8-compatible versions):
```xml
<PackageVersion Include="Microsoft.ApplicationInsights.AspNetCore" Version="2.22.0" />
<PackageVersion Include="Microsoft.ApplicationInsights.SnapshotCollector" Version="1.4.6" />
```

### 4b. `src/Web/Web.csproj`
Add:
```xml
<PackageReference Include="Microsoft.ApplicationInsights.AspNetCore" />
```

### 4c. `src/Web/Program.cs`
After `builder.Services.AddRazorPages()`, add:
```csharp
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
- Add `using Microsoft.ApplicationInsights;`
- Inject `TelemetryClient? telemetryClient = null` (nullable — works without App Insights configured)
- In the basket update/checkout handler, track: `telemetryClient?.TrackEvent("BasketUpdated", new Dictionary<string, string> { ["itemCount"] = basket.Items.Count.ToString() });`

---

## Task 5 — Build Version in Footer

### 5a. Create `src/Web/GetAssemblyVersion.cs`
Copy from `ADO_VERION/eShopOnWeb/src/Web/GetAssemblyVersion.cs` verbatim.

### 5b. Update `src/Web/Views/Shared/_Layout.cshtml`
Replace the plain-text footer copyright line with a version-aware footer that calls `@Microsoft.eShopWeb.Web.MyAppVersion.GetAssemblyVersion()` and `@Microsoft.eShopWeb.Web.MyAppVersion.GetDateTimeFromVersion()`. Keep the privacy link and copyright text alongside.

---

## Task 6 — Playwright Component IDs

For each file: **read it first**, then add only the `id=` attributes listed. Change nothing else.

| File | IDs to Add |
|---|---|
| `src/Web/Pages/Index.cshtml` | `id="Index-Select-BrandFilter"` on brand `<select>`, `id="Index-Select-TypeFilter"` on type `<select>`, `id="Index-Button-ApplyFilter"` on Apply button, `id="esh-pager-item-msg"` on no-results div. Split `<partial name="_pagination">` into `_pagination_top` (top) and `_pagination_bottom` (bottom). |
| `src/Web/Pages/Shared/_pagination_top.cshtml` *(create)* | Previous link `id="PaginationTop-Link-Previous"`, msg span `id="esh-pager-item-msg-top"`, Next link `id="PaginationTop-Link-Next"` |
| `src/Web/Pages/Shared/_pagination_bottom.cshtml` *(create)* | Previous link `id="PaginationBottom-Link-Previous"`, msg span `id="esh-pager-item-msg-bottom"`, Next link `id="PaginationBottom-Link-Next"` |
| `src/Web/Pages/Shared/_product.cshtml` | Add to Basket button: `id="Product-Button-AddToBasket-@Model.Id"` |
| `src/Web/Pages/Basket/Index.cshtml` | Quantity input: `id="BasketIndex-Input-Quantity-@item.Id"`, total span: `id="basket-total"`, Continue Shopping: `id="BasketIndex-Link-ContinueShopping"`, Update button: `id="BasketIndex-Button-Update"`, Checkout link: `id="BasketIndex-Link-Checkout"` |
| `src/Web/Pages/Basket/Checkout.cshtml` | Back link: `id="Checkout-Link-Back"`, Pay Now button: `id="Checkout-Button-PayNow"` |
| `src/Web/Pages/Basket/Success.cshtml` | Continue Shopping: `id="Success-Link-ContinueShopping"` |
| `src/Web/Views/Shared/_LoginPartial.cshtml` | Admin: `id="LoginPartial-Link-Admin"`, My Orders: `id="LoginPartial-Link-MyOrders"`, My Account: `id="LoginPartial-Link-MyAccount"`, Logout: `id="LoginPartial-Link-Logout"`, Login: `id="LoginPartial-Link-Login"` |
| `src/Web/Areas/Identity/Pages/Account/Login.cshtml` | Email: `id="Login-Input-Email"`, Password: `id="Login-Input-Password"`, Remember Me: `id="Login-Checkbox-RememberMe"`, Submit: `id="Login-Button-Submit"`, Forgot Password: `id="Login-Link-ForgotPassword"`, Register: `id="Login-Link-Register"` |
| `src/Web/Views/Manage/MyAccount.cshtml` *(if exists)* | Username: `id="MyAccount-Input-Username"`, Email: `id="MyAccount-Input-Email"`, Send Verification: `id="MyAccount-Button-SendVerificationEmail"`, Phone: `id="MyAccount-Input-PhoneNumber"`, Save: `id="MyAccount-Button-Save"` |

---

## Task 7 — Playwright Test Infrastructure

### 7a. Copy and patch config files
- `ADO_VERION/eShopOnWeb/playwright.config.ts` → `playwright.config.ts`
- `ADO_VERION/eShopOnWeb/playwright.service.config.ts` → `playwright.service.config.ts`
- `ADO_VERION/eShopOnWeb/package.json` → `package.json`

After copying `playwright.config.ts`:
- Replace hardcoded `azurewebsites.net` URL with `process.env.BASE_URL ?? 'https://localhost:5001'`
- Remove the `@alex_neo/playwright-azure-reporter` reporter entry (ADO-specific)

### 7b. Copy and fix test specs
Copy all files from `ADO_VERION/eShopOnWeb/tests/PlaywrightTests/` → `tests/PlaywrightTests/`.

Fix broken IDs in `tests/PlaywrightTests/ShopForLargeQuantites.spec.ts`:
- `#Header-Link-Login` → `#LoginPartial-Link-Login`
- `#Header-Link-Logout` → `#LoginPartial-Link-Logout`

---

## Task 8 — Authentication Verification

Read `src/Web/appsettings.json` and `src/Web/appsettings.Development.json`.
- Confirm LocalDB connection strings for local dev.
- Confirm NO hardcoded production passwords or App Insights keys are present.
- Read `src/Web/Program.cs` and verify `AddDefaultIdentity` (or equivalent) is called.

If any hardcoded secrets were accidentally introduced, remove them.

---

## Task 9 — Build Verification

```
dotnet restore eShopOnWeb.sln
dotnet build eShopOnWeb.sln -c Release
dotnet test eShopOnWeb.sln --no-build -c Release
```

Fix any compile errors before declaring the migration complete. Report test failures.

---

## Task 10 — Final Checklist

Confirm each item is done before finishing:

- [ ] `.github/workflows/ci-cd.yml` created and valid YAML (includes `az group create` and `az role assignment create` steps)
- [ ] `.github/workflows/codeql.yml` created and valid YAML
- [ ] `.github/dependabot.yml` created
- [ ] `DBscripts/CatalogDB.sql` and `DBscripts/IdentityDB.sql` exist
- [ ] `GenerateVersionNumber.ps1` and `ParseDeploymentOutputs.ps1` at repo root
- [ ] `infra/modules/appinsights.bicep` exists
- [ ] `infra/modules/dashboard.bicep` exists
- [ ] `infra/main.bicep` conditionally calls both new modules
- [ ] `src/Web/GetAssemblyVersion.cs` exists
- [ ] `_Layout.cshtml` footer shows build version
- [ ] All Playwright `id=` attributes added across 10 files
- [ ] `_pagination_top.cshtml` and `_pagination_bottom.cshtml` created
- [ ] `tests/PlaywrightTests/` contains all spec files with fixed IDs
- [ ] `playwright.config.ts` uses `BASE_URL` env var (not hardcoded URL)
- [ ] No hardcoded secrets in any tracked file
- [ ] `dotnet build` succeeds with 0 errors
