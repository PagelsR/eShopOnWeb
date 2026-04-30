// Azure Load Testing resource for eShopOnWeb
// Provisions the Azure Load Testing service used by CI/CD pipeline

param location string
param loadTestingName string

@description('Resource tags')
param tags object = {}

resource loadTesting 'Microsoft.LoadTestService/loadTests@2024-12-01-preview' = {
  name: loadTestingName
  location: location
  tags: tags
  properties: {
    description: 'Azure Load Testing for eShopOnWeb'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output loadTestingName string = loadTesting.name
output loadTestingId string = loadTesting.id
output loadTestingPrincipalId string = loadTesting.identity.principalId
