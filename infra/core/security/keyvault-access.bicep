@description('Access policy operation - typically "add"')
param name string = 'add'

@description('Name of the Key Vault to add access policy to')
param keyVaultName string

@description('Permissions to grant - defaults to get and list secrets')
param permissions object = { secrets: [ 'get', 'list' ] }

@description('Principal ID (Object ID) to grant access to')
param principalId string

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVault
  name: name
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: principalId
        permissions: permissions
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}
