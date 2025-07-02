targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module monitor 'modules/monitor.bicep' = {
  name: 'monitor'
  scope: rg
  params: {
    environmentName: replace(environmentName, '-', '')
    location: location
    resourceToken: resourceToken
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyVault'
  scope: rg
  params: {
    environmentName: replace(environmentName, '-', '')
    location: location
    resourceToken: resourceToken
  }
}

module webApp 'modules/appService.bicep' = {
  name: 'webApp'
  scope: rg
  params: {
    location: location
    environmentName: replace(environmentName, '-', '')
    resourceToken: resourceToken
    keyVaultName: keyVault.outputs.name
    logAnalyticsWorkspaceId: monitor.outputs.logAnalyticsWorkspaceId
    slackBotToken: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.name};SecretName=SLACK-BOT-TOKEN)'
    slackSigningSecret: '@Microsoft.KeyVault(VaultName=${keyVault.outputs.name};SecretName=SLACK-SIGNING-SECRET)'
    tags: union(tags, { 'azd-service-name': 'app' })
  }
}

output APP_URL string = webApp.outputs.endpoint
output AZURE_LOCATION string = location
