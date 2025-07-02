/*
  Azure Monitor のリソース
*/

//********************************************
// Parameters
//********************************************

param environmentName string

@description('Primary region for all Azure resources.')
@minLength(1)
param location string = resourceGroup().location 

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string = toLower(uniqueString(subscription().id, location))

//********************************************
// Variables
//********************************************

var la_workspace_name = toLower('${environmentName}-log-${resourceToken}')

//********************************************
// Log Analytics Workspace
//********************************************

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: la_workspace_name
  location: location
  properties: {
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
