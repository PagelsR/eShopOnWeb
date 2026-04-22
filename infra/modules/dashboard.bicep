// Azure Dashboard module for Application Insights visualization

@description('Location for the dashboard')
param location string

@description('Resource name prefix for generating unique names')
param resourceNamePrefix string

@description('Application Insights resource ID')
param appInsightsId string

@description('Resource tags')
param tags object = {}

resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: '${resourceNamePrefix}-dashboard'
  location: location
  tags: tags
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'ComponentId'
                  value: appInsightsId
                }
                {
                  name: 'TimeContext'
                  value: {
                    durationMs: 86400000
                    createdTime: '2024-01-01T00:00:00.000Z'
                    isInitialTime: false
                    grain: 1
                    useDashboardTimeRange: false
                  }
                }
              ]
              type: 'Extension/AppInsightsExtension/PartType/AspNetOverviewPinnedPart'
              asset: {
                idInputName: 'ComponentId'
                type: 'ApplicationInsights'
              }
              defaultMenuItemId: 'overview'
            }
          }
          {
            position: {
              x: 6
              y: 0
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'ComponentId'
                  value: appInsightsId
                }
                {
                  name: 'MetricsExplorerJsonDefinitionId'
                  value: 'pinJson:?name={"version":"1.4.1","chartSettings":{"title":"Server response time","visualization":{"chartType":3}},"openBladeOnClick":{"openBlade":true}}'
                }
                {
                  name: 'TimeContext'
                  value: {
                    durationMs: 86400000
                  }
                }
              ]
              type: 'Extension/AppInsightsExtension/PartType/MetricsExplorerBladePinnedPart'
              asset: {
                idInputName: 'ComponentId'
                type: 'ApplicationInsights'
              }
            }
          }
          {
            position: {
              x: 0
              y: 4
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'ComponentId'
                  value: appInsightsId
                }
                {
                  name: 'MetricsExplorerJsonDefinitionId'
                  value: 'pinJson:?name={"version":"1.4.1","chartSettings":{"title":"Server requests","visualization":{"chartType":2}},"openBladeOnClick":{"openBlade":true}}'
                }
                {
                  name: 'TimeContext'
                  value: {
                    durationMs: 86400000
                  }
                }
              ]
              type: 'Extension/AppInsightsExtension/PartType/MetricsExplorerBladePinnedPart'
              asset: {
                idInputName: 'ComponentId'
                type: 'ApplicationInsights'
              }
            }
          }
          {
            position: {
              x: 6
              y: 4
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'ComponentId'
                  value: appInsightsId
                }
                {
                  name: 'MetricsExplorerJsonDefinitionId'
                  value: 'pinJson:?name={"version":"1.4.1","chartSettings":{"title":"Failed requests","visualization":{"chartType":2}},"openBladeOnClick":{"openBlade":true}}'
                }
                {
                  name: 'TimeContext'
                  value: {
                    durationMs: 86400000
                  }
                }
              ]
              type: 'Extension/AppInsightsExtension/PartType/MetricsExplorerBladePinnedPart'
              asset: {
                idInputName: 'ComponentId'
                type: 'ApplicationInsights'
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 24
              timeUnit: 1
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
      }
    }
  }
}

output dashboardId string = dashboard.id
output dashboardName string = dashboard.name
