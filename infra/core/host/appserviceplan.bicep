@description('App Service Plan name')
param name string

@description('Location for the App Service Plan')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

@description('Kind of App Service Plan - empty for Windows, linux for Linux')
param kind string = ''

@description('Whether to use Linux workers')
param reserved bool = true

@description('SKU configuration for the App Service Plan')
param sku object

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  kind: kind
  properties: {
    reserved: reserved
  }
}

output id string = appServicePlan.id
