using System.Net.Mime;
using Azure.Identity;
using BlazorAdmin;
using BlazorAdmin.Services;
using Blazored.LocalStorage;
using BlazorShared;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.ApplicationModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.eShopWeb;
using Microsoft.eShopWeb.ApplicationCore.Interfaces;
using Microsoft.eShopWeb.Infrastructure.Data;
using Microsoft.eShopWeb.Infrastructure.Identity;
using Microsoft.eShopWeb.Web;
using Microsoft.eShopWeb.Web.Configuration;
using Microsoft.eShopWeb.Web.HealthChecks;
using Microsoft.eShopWeb.Web.Pages;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.FeatureManagement;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.AddConsole();

builder.Configuration.AddEnvironmentVariables();

// Configure SQL Server via Azure Key Vault
var credential = new ChainedTokenCredential(new AzureDeveloperCliCredential(), new DefaultAzureCredential());
var keyVaultEndpoint = builder.Configuration["AZURE_KEY_VAULT_ENDPOINT"]
    ?? throw new InvalidOperationException("AZURE_KEY_VAULT_ENDPOINT app setting is not configured.");
builder.Configuration.AddAzureKeyVault(new Uri(keyVaultEndpoint), credential);

var connectionStringKey = builder.Configuration["SQL_CONNECTION_STRING_KEY"] ?? "SQL-CONNECTION-STRING";
var connectionString = builder.Configuration[connectionStringKey];

if (string.IsNullOrEmpty(connectionString))
{
    throw new InvalidOperationException($"Connection string '{connectionStringKey}' not found in Key Vault.");
}

builder.Services.AddDbContext<CatalogContext>(c =>
{
    c.UseSqlServer(connectionString, sqlOptions => sqlOptions.EnableRetryOnFailure());
});

builder.Services.AddDbContext<AppIdentityDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions => sqlOptions.EnableRetryOnFailure());
});

builder.Services.AddCookieSettings();

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        options.Cookie.SameSite = SameSiteMode.Lax;
    });

builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
           .AddDefaultUI()
           .AddEntityFrameworkStores<AppIdentityDbContext>()
                           .AddDefaultTokenProviders();

builder.Services.AddScoped<ITokenClaimsService, IdentityTokenClaimService>();
builder.Services.AddCoreServices(builder.Configuration);
builder.Services.AddWebServices(builder.Configuration);

builder.Services.AddMemoryCache();
builder.Services.AddRouting(options =>
{
    options.ConstraintMap["slugify"] = typeof(SlugifyParameterTransformer);
});

builder.Services.AddMvc(options =>
{
    options.Conventions.Add(new RouteTokenTransformerConvention(new SlugifyParameterTransformer()));
});
builder.Services.AddControllersWithViews();
builder.Services.AddRazorPages(options =>
{
    options.Conventions.AuthorizePage("/Basket/Checkout");
});
builder.Services.AddHttpContextAccessor();

// Application Insights — connection string injected via Key Vault / environment variable
var appInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
if (!string.IsNullOrEmpty(appInsightsConnectionString))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = appInsightsConnectionString;
    });
}

builder.Services
    .AddHealthChecks()
    .AddCheck<ApiHealthCheck>("api_health_check", tags: new[] { "apiHealthCheck" })
    .AddCheck<HomePageHealthCheck>("home_page_health_check", tags: new[] { "homePageHealthCheck" });

// Initialize useAppConfig parameter
var useAppConfig = false;
Boolean.TryParse(builder.Configuration["UseAppConfig"], out useAppConfig);

if (useAppConfig)
{
    builder.Services.AddAzureAppConfiguration();
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        var appConfigEndpoint = builder.Configuration["AppConfigEndpoint"];

        if (string.IsNullOrEmpty(appConfigEndpoint))
        {
            throw new Exception("AppConfigEndpoint is not set in the configuration. Please set AppConfigEndpoint in the configuration.");
        }

        options.Connect(new Uri(appConfigEndpoint), new DefaultAzureCredential())
            .ConfigureRefresh(refresh =>
            {
                refresh.Register("eShopWeb:Settings:NoResultsMessage").SetRefreshInterval(TimeSpan.FromSeconds(10));
            })
            .UseFeatureFlags(featureFlagOptions =>
            {
                featureFlagOptions.SetRefreshInterval(TimeSpan.FromSeconds(10));
            });
    });
}

// Add Feature Management AFTER Azure App Configuration is loaded
builder.Services.AddFeatureManagement();

// Bind configuration "eShopWeb:Settings" section to the Settings object
// Must be AFTER Azure App Configuration is added so it picks up remote values
builder.Services.Configure<SettingsViewModel>(builder.Configuration.GetSection("eShopWeb:Settings"));

// Blazor configuration
var configSection = builder.Configuration.GetRequiredSection(BaseUrlConfiguration.CONFIG_NAME);
builder.Services.Configure<BaseUrlConfiguration>(configSection);
var baseUrlConfig = configSection.Get<BaseUrlConfiguration>();

builder.Services.AddScoped<HttpClient>(s => new HttpClient
{
    BaseAddress = new Uri(baseUrlConfig!.WebBase)
});

builder.Services.AddBlazoredLocalStorage();
builder.Services.AddServerSideBlazor();
builder.Services.AddScoped<ToastService>();
builder.Services.AddScoped<HttpService>();
builder.Services.AddBlazorServices();

var app = builder.Build();

if (useAppConfig)
{
    app.UseAzureAppConfiguration();
}

app.Logger.LogInformation("App created...");

app.Logger.LogInformation("Applying migrations and seeding database...");

using (var scope = app.Services.CreateScope())
{
    var scopedProvider = scope.ServiceProvider;
    try
    {
        var catalogContext = scopedProvider.GetRequiredService<CatalogContext>();
        await CatalogContextSeed.SeedAsync(catalogContext, app.Logger);

        var userManager = scopedProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scopedProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var identityContext = scopedProvider.GetRequiredService<AppIdentityDbContext>();
        await AppIdentityDbContextSeed.SeedAsync(identityContext, userManager, roleManager);
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "An error occurred seeding the DB.");
    }
}

var catalogBaseUrl = builder.Configuration.GetValue(typeof(string), "CatalogBaseUrl") as string;
if (!string.IsNullOrEmpty(catalogBaseUrl))
{
    app.Use((context, next) =>
    {
        context.Request.PathBase = new PathString(catalogBaseUrl);
        return next();
    });
}

app.UseHealthChecks("/health",
    new HealthCheckOptions
    {
        ResponseWriter = async (context, report) =>
        {
            var result = new
            {
                status = report.Status.ToString(),
                errors = report.Entries.Select(e => new
                {
                    key = e.Key,
                    value = Enum.GetName(typeof(HealthStatus), e.Value.Status)
                })
            }.ToJson();
            context.Response.ContentType = MediaTypeNames.Application.Json;
            await context.Response.WriteAsync(result);
        }
    });

app.UseExceptionHandler("/Error");
app.UseHsts();

app.UseHttpsRedirection();
app.UseBlazorFrameworkFiles();
app.UseStaticFiles();
app.UseRouting();

app.UseCookiePolicy();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute("default", "{controller:slugify=Home}/{action:slugify=Index}/{id?}");
app.MapRazorPages();
app.MapHealthChecks("home_page_health_check", new HealthCheckOptions { Predicate = check => check.Tags.Contains("homePageHealthCheck") });
app.MapHealthChecks("api_health_check", new HealthCheckOptions { Predicate = check => check.Tags.Contains("apiHealthCheck") });
app.MapFallbackToFile("index.html");

app.Logger.LogInformation("LAUNCHING");
app.Run();
