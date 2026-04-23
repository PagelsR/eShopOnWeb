targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''
param webServiceName string = ''
param appServicePlanName string = ''
param keyVaultName string = ''
param sqlServerName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Azure AD Object ID for admin user email alias - grants full Key Vault secret access for viewing/managing secrets')
param azObjectIdEmailAlias string = ''

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

@description('Deploy Application Insights for monitoring and observability')
param deployAppInsights bool = true

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Application Insights for monitoring and observability
module appInsights './modules/appinsights.bicep' = if (deployAppInsights) {
  name: 'appinsights'
  scope: rg
  params: {
    location: location
    resourceNamePrefix: resourceToken
    webAppUrl: 'https://${!empty(webServiceName) ? webServiceName : '${abbrs.webSitesAppService}web-${resourceToken}'}.azurewebsites.net'
    tags: tags
  }
}

// Azure Dashboard for Application Insights visualization
module dashboard './modules/dashboard.bicep' = if (deployAppInsights) {
  name: 'dashboard'
  scope: rg
  params: {
    location: location
    resourceNamePrefix: resourceToken
    appInsightsId: deployAppInsights ? appInsights.outputs.appInsightsId : ''
    tags: tags
  }
}

// The application frontend
module web './core/host/appservice.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: !empty(webServiceName) ? webServiceName : '${abbrs.webSitesAppService}web-${resourceToken}'
    location: location
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    runtimeName: 'dotnetcore'
    runtimeVersion: '8.0'
    tags: union(tags, { 'azd-service-name': 'web' })
    appSettings: union({
      SQL_CONNECTION_STRING_KEY: 'SQL-CONNECTION-STRING'
      AZURE_KEY_VAULT_ENDPOINT: keyVault.outputs.endpoint
    }, deployAppInsights ? {
      APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.outputs.appInsightsConnectionString
    } : {})
  }
}

module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: web.outputs.identityPrincipalId
  }
}

// The application database - single SQL Server with one database
module sqlDatabase './core/database/sqlserver/sqlserver.bicep' = {
  name: 'sql-eshoponweb'
  scope: rg
  params: {
    name: !empty(sqlServerName) ? sqlServerName : '${abbrs.sqlServers}${resourceToken}'
    databaseName: 'eShopOnWeb'
    location: location
    tags: tags
    sqlAdminPassword: sqlAdminPassword
    keyVaultName: keyVault.outputs.name
    connectionStringKey: 'SQL-CONNECTION-STRING'
  }
}

// Store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
    azObjectIdEmailAlias: azObjectIdEmailAlias
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'B1'
    }
  }
}

// Data outputs
output SQL_CONNECTION_STRING_KEY string = sqlDatabase.outputs.connectionStringKey
output SQL_DATABASE_NAME string = sqlDatabase.outputs.databaseName

// App outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name

// Deployment outputs for CI/CD pipeline
output webAppName string = web.outputs.name
output sqlServerName string = sqlDatabase.outputs.sqlServerName
output sqlServerFqdn string = sqlDatabase.outputs.sqlServerFqdn
output databaseName string = sqlDatabase.outputs.databaseName

// Application Insights outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = deployAppInsights ? appInsights.outputs.appInsightsConnectionString : ''
output APPLICATIONINSIGHTS_INSTRUMENTATION_KEY string = deployAppInsights ? appInsights.outputs.appInsightsInstrumentationKey : ''
