// Application Insights module with Log Analytics Workspace, metric alerts, and availability tests

@description('Location for all resources')
param location string

@description('Resource name prefix for generating unique names')
param resourceNamePrefix string

@description('Web app URL for availability testing')
param webAppUrl string

@description('Resource tags')
param tags object = {}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${resourceNamePrefix}-law'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourceNamePrefix}-ai'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Metric Alert for HTTP 5xx errors
resource http5xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${resourceNamePrefix}-http5xx-alert'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when HTTP 5xx errors exceed threshold'
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'High5xxRate'
          metricName: 'requests/failed'
          operator: 'GreaterThan'
          threshold: 10
          timeAggregation: 'Count'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    autoMitigate: true
    actions: []
  }
}

// Web Availability Test (ping test)
resource availabilityTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: '${resourceNamePrefix}-availability-test'
  location: location
  tags: union(tags, {
    'hidden-link:${appInsights.id}': 'Resource'
  })
  kind: 'ping'
  properties: {
    Name: '${resourceNamePrefix} Home Page Availability'
    Description: 'Ping test for home page availability'
    Enabled: true
    Frequency: 300
    Timeout: 120
    Kind: 'ping'
    RetryEnabled: true
    Locations: [
      {
        Id: 'us-va-ash-azr'
      }
      {
        Id: 'us-ca-sjc-azr'
      }
      {
        Id: 'emea-nl-ams-azr'
      }
    ]
    Configuration: {
      WebTest: '<WebTest Name="${resourceNamePrefix}" Id="${guid(resourceNamePrefix)}" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="120" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale=""><Items><Request Method="GET" Guid="${guid(resourceNamePrefix, 'request')}" Version="1.1" Url="${webAppUrl}" ThinkTime="0" Timeout="120" ParseDependentRequests="False" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" /></Items></WebTest>'
    }
    SyntheticMonitorId: '${resourceNamePrefix}-availability-test'
  }
}

// Outputs
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
