@description('Location for the Key Vault')
param location string

@description('Key Vault name')
param keyVaultName string

@description('Tenant ID for Key Vault')
param tenantId string

@description('App Service Managed Identity Principal ID')
param appServicePrincipalId string

@description('Azure AD Object ID for admin user (e.g., your user account)')
param azObjectIdEmailAlias string = ''

@description('Azure AD Object ID for GitHub Actions service principal')
param githubServicePrincipalObjectId string = ''

@description('Azure AD Object ID for Azure service connection')
param azureServiceConnectionObjectId string = ''

@description('Tags to apply to the Key Vault')
param tags object = {}

// Base access policies for App Service
var baseAccessPolicies = [
  {
    tenantId: tenantId
    objectId: appServicePrincipalId
    permissions: {
      secrets: [
        'get'
        'list'
      ]
    }
  }
]

// Build access policies array conditionally (matching eShop pattern)
var adminAccessPolicy = !empty(azObjectIdEmailAlias) ? [
  {
    tenantId: tenantId
    objectId: azObjectIdEmailAlias
    permissions: {
      secrets: ['get', 'list', 'set', 'delete', 'backup', 'restore', 'recover', 'purge']
    }
  }
] : []

var githubAccessPolicy = !empty(githubServicePrincipalObjectId) ? [
  {
    tenantId: tenantId
    objectId: githubServicePrincipalObjectId
    permissions: {
      secrets: ['get', 'list', 'set']
    }
  }
] : []

var serviceConnectionAccessPolicy = !empty(azureServiceConnectionObjectId) ? [
  {
    tenantId: tenantId
    objectId: azureServiceConnectionObjectId
    permissions: {
      secrets: ['get', 'list']
    }
  }
] : []

var accessPolicies = concat(baseAccessPolicies, adminAccessPolicy, githubAccessPolicy, serviceConnectionAccessPolicy)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableSoftDelete: false // For dev/test environments
    accessPolicies: accessPolicies
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
