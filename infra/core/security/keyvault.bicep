@description('Key Vault name')
param name string

@description('Location for the Key Vault')
param location string = resourceGroup().location

@description('Tags to apply to the Key Vault')
param tags object = {}

@description('App Service Managed Identity Principal ID')
param principalId string = ''

@description('Azure AD Object ID for admin user - grants full secret permissions')
param adminObjectId string = ''

@description('Azure AD Object ID for GitHub Actions service principal')
param githubServicePrincipalObjectId string = ''

@description('Azure AD Object ID for Azure service connection')
param azureServiceConnectionObjectId string = ''

// Base access policies for App Service (read-only)
var baseAccessPolicies = !empty(principalId) ? [
  {
    tenantId: subscription().tenantId
    objectId: principalId
    permissions: {
      secrets: ['get', 'list']
    }
  }
] : []

// Admin access policy (full permissions to view/manage secrets)
var adminAccessPolicy = !empty(adminObjectId) ? [
  {
    tenantId: subscription().tenantId
    objectId: adminObjectId
    permissions: {
      secrets: ['get', 'list', 'set', 'delete', 'backup', 'restore', 'recover', 'purge']
    }
  }
] : []

// GitHub Actions access policy (read and write for CI/CD)
var githubAccessPolicy = !empty(githubServicePrincipalObjectId) ? [
  {
    tenantId: subscription().tenantId
    objectId: githubServicePrincipalObjectId
    permissions: {
      secrets: ['get', 'list', 'set']
    }
  }
] : []

// Azure service connection access policy (read-only)
var serviceConnectionAccessPolicy = !empty(azureServiceConnectionObjectId) ? [
  {
    tenantId: subscription().tenantId
    objectId: azureServiceConnectionObjectId
    permissions: {
      secrets: ['get', 'list']
    }
  }
] : []

// Concatenate all access policies
var accessPolicies = concat(baseAccessPolicies, adminAccessPolicy, githubAccessPolicy, serviceConnectionAccessPolicy)

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    accessPolicies: accessPolicies
  }
}

output endpoint string = keyVault.properties.vaultUri
output name string = keyVault.name
