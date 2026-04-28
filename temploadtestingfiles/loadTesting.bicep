// Azure Load Testing resource for Gino's Gelato
// Provisions the Azure Load Testing service used by CI/CD pipeline

param location string
param loadTestingName string
param defaultTags object

resource loadTesting 'Microsoft.LoadTestService/loadTests@2024-12-01-preview' = {
  name: loadTestingName
  location: location
  tags: defaultTags
  properties: {
    description: 'Azure Load Testing for Gino\'s Gelato API endpoints'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output loadTestingName string = loadTesting.name
output loadTestingId string = loadTesting.id
output loadTestingPrincipalId string = loadTesting.identity.principalId
