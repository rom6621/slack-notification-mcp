/* 
  Azure KeyVault のリソース
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

var keyVaultName = take(('${environmentName}vault${resourceToken}'), 24)

//********************************************
// Azure Key Vault
//********************************************

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    accessPolicies: []
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
  }
}

//********************************************
// Output
//********************************************

output name string = kv.name
