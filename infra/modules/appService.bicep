/* 
  MCPサーバーをデプロイするWeb Appのリソース
*/

//********************************************
// Parameters
//********************************************
@description('リソースのプライマリーリージョン')
@minLength(1)
param location string = resourceGroup().location 

@description('リソースの命名に使用する環境名')
@minLength(1)
param environmentName string

@description('リソースの命名に使用するユニークなトークン')
@minLength(3)
param resourceToken string = toLower(uniqueString(subscription().id, location))

@description('KeyVaultのリソース名')
@minLength(1)
param keyVaultName string

@description('LogAnalyticsワークスペースのID')
@minLength(1)
param logAnalyticsWorkspaceId string

@description('SlackのBotトークン')
@minLength(1)
param slackBotToken string

@secure()
@description('Slackの署名シークレット')
@minLength(1)
param slackSigningSecret string

@description('WebAppに設定するタグ')
param tags object = {}

//********************************************
// Variables
//********************************************

// AppService プラン
var appServicePlanName = toLower('${environmentName}slackmcpasp${resourceToken}')

// Application Insights
var appInsightsName = toLower('${environmentName}slackmcpappi${resourceToken}')

// WebApps
var appName = toLower('${environmentName}slackmcp${resourceToken}')

//********************************************
// AppService プラン
//********************************************

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: 'B1'
  }
  kind: 'linux'
}

//********************************************
// Application Insights
//********************************************

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    DisableLocalAuth: true
  }
}

//********************************************
// Web Apps
//********************************************

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  tags: tags
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'node|20-lts'
    }
  }
  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: {
        SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
        SLACK_BOT_TOKEN: slackBotToken
        SLACK_SIGNING_SECRET: slackSigningSecret
        APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
      }
  }
}

//********************************************
// マネージドIDのロール設定
// NOTE: AppServiceのシステム割り当てマネージドIDに対してロールを割り当てる
//********************************************

resource roleAssignmentAppInsights 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, applicationInsights.id, webApp.id, 'Monitoring Metrics Publisher')
  scope: applicationInsights
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// KeyVaultに対するアクセス権限の付与
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, kv.id, webApp.id, 'Key Vault Secrets User')
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

//********************************************
// Output
//********************************************

output endpoint string = 'https://${webApp.properties.defaultHostName}'
output principalId string = webApp.identity.principalId
