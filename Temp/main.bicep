// Deploy Azure infrastructure for FIFAWorldCup Prediction Hub
// Based on proven eShop patterns
// Assumes resource group already exists

targetScope = 'resourceGroup'

// Parameters
@description('Azure region for all resources')
param location string = 'eastus'

@description('Created by')
param createdBy string = 'Randy Pagels'

@description('Cost center')
param costCenter string = 'FIFAWorldCup'

// SQL Server administrator credentials
@description('SQL Server administrator login')
@secure()
param sqlAdminLogin string

@description('SQL Server administrator password')
@secure()
param sqlAdminPassword string

// ObjectId of user/alias that needs Key Vault access (RPagels)
@description('Azure AD Object ID for admin user - RPagels')
param azObjectIdEmailAlias string = '0aa95253-9e37-4af9-a63a-3b35ed78e98b'

// Object Id of Azure Service Principal for GitHub Actions
@description('Azure AD Object ID for GitHub Actions service principal')
param githubServicePrincipalObjectId string = ''

// Object Id of Azure service connection
@description('Azure AD Object ID for Azure service connection')
param azureServiceConnectionObjectId string = ''

// Variables - Centralized resource naming
// Recommended abbreviations: https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
var appServicePlanName = 'plan-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
var appServiceName = 'app-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
var sqlServerName = toLower('sql-${uniqueString(subscription().subscriptionId, resourceGroup().id)}')
var sqlDatabaseName = toLower('sqldb-${uniqueString(subscription().subscriptionId, resourceGroup().id)}')
var staticWebAppName = 'swa-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
var keyVaultName = 'kv-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
var appInsightsName = 'appi-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
var appInsightsWorkspaceName = 'appw-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
var appInsightsAlertName = 'alert-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'

// Tags
var defaultTags = {
  App: 'FIFAWorldCup'
  Environment: 'Production'
  CostCenter: costCenter
  CreatedBy: createdBy
}

// KeyVault Secret Names (these are just names, not actual secrets)
var kvSecretSqlConnectionString = 'SqlConnectionString'
var kvSecretFifaApiKey = 'FifaApiKey'

// Deploy App Service Plan
module appServicePlan 'appServicePlan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    defaultTags: defaultTags
  }
}

// Deploy Static Web App (needed early for CORS configuration and availability tests)
module staticWebApp 'staticWebApp.bicep' = {
  name: 'staticWebAppDeployment'
  params: {
    location: location
    staticWebAppName: staticWebAppName
    defaultTags: defaultTags
  }
}

// Deploy Application Insights (depends on Static Web App URL for availability tests)
module appInsights 'appInsights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    location: location
    appInsightsName: appInsightsName
    appInsightsWorkspaceName: appInsightsWorkspaceName
    appInsightsAlertName: appInsightsAlertName
    appServiceUrl: 'https://${appServiceName}.azurewebsites.net'
    staticWebAppUrl: staticWebApp.outputs.staticWebAppUrl
    defaultTags: defaultTags
  }
}

// Deploy SQL Server
module sqlServer 'sqlServer.bicep' = {
  name: 'sqlServerDeployment'
  params: {
    location: location
    sqlServerName: sqlServerName
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    defaultTags: defaultTags
  }
}

// Deploy SQL Database
module sqlDatabase 'sqlDatabase.bicep' = {
  name: 'sqlDatabaseDeployment'
  params: {
    location: location
    sqlDatabaseName: sqlDatabaseName
    sqlServerName: sqlServer.outputs.sqlServerName
    defaultTags: defaultTags
  }
}

// Deploy App Service (depends on App Service Plan and Static Web App for CORS)
module appService 'appService.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    appServiceName: appServiceName
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    appInsightsName: appInsightsName
    staticWebAppUrl: staticWebApp.outputs.staticWebAppUrl
    defaultTags: defaultTags
  }
}

// Deploy Key Vault (depends on App Service for Managed Identity)
module keyVault 'keyVault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    tenantId: subscription().tenantId
    appServicePrincipalId: appService.outputs.appServicePrincipalId
    azObjectIdEmailAlias: azObjectIdEmailAlias
    githubServicePrincipalObjectId: githubServicePrincipalObjectId
    azureServiceConnectionObjectId: azureServiceConnectionObjectId
    tags: defaultTags
  }
}

// Configure App Settings and Secrets
module configSettings 'configSettings.bicep' = {
  name: 'configSettingsDeployment'
  dependsOn: [
    keyVault
    sqlDatabase
  ]
  params: {
    keyVaultName: keyVaultName
    appServiceName: appServiceName
    sqlServerFQDN: sqlServer.outputs.sqlServerFullyQualifiedDomainName
    sqlDatabaseName: sqlDatabaseName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    sqlConnectionStringSecretName: kvSecretSqlConnectionString
    fifaApiKeySecretName: kvSecretFifaApiKey
  }
}

// Outputs for pipeline and verification
output appServiceName string = appServiceName
output appServiceUrl string = 'https://${appService.outputs.appServiceDefaultHostName}'
output appServicePrincipalId string = appService.outputs.appServicePrincipalId
output staticWebAppName string = staticWebAppName
output staticWebAppUrl string = staticWebApp.outputs.staticWebAppUrl
output sqlServerName string = sqlServerName
output sqlServerFQDN string = sqlServer.outputs.sqlServerFullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabaseName
output keyVaultName string = keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output appInsightsName string = appInsightsName
output appInsightsInstrumentationKey string = appInsights.outputs.appInsightsInstrumentationKey
output appInsightsConnectionString string = appInsights.outputs.appInsightsConnectionString
