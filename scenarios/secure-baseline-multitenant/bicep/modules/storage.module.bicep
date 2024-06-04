@description('Required. The name of the storage account resource. Start and end with alphanumeric. Consecutive hyphens not allowed')
@maxLength(24)
@minLength(1)
param name string

@description('Optional. The location to deploy the Redis cache service.')
param location string 

@description('Optional. Tags of the resource.')
param tags object = {}

@description('The name of an existing keyvault, that it will be used to store secrets (connection string)' )
param keyvaultName string

@description('An existing Log Analytics WS Id for creating app Insights, diagnostics etc.')
param logAnalyticsWsId string

@description('Default is empty. If empty no Private endpoint will be created fro the resoure. Otherwise, the subnet where the private endpoint will be attached to')
param subnetPrivateEndpointId string = ''

@description('if empty, private dns zone will be deployed in the current RG scope')
param vnetHubResourceId string

@description('Optional. Array of custom objects describing vNet links of the DNS zone. Each object should contain vnetName, vnetId, registrationEnabled')
param virtualNetworkLinks array = []

@description('Optional. File share name.')
param fileShareName string = 'share'

@description('The name of the existing VNET Hub Private DNS Zone Resource Group')
param privateDnsZoneRg string = ''

var vnetHubSplitTokens = !empty(vnetHubResourceId) ? split(vnetHubResourceId, '/') : array('')

var filesDnsZoneName = 'privatelink.file.core.windows.net'

module storage '../../../shared/bicep/storage/storage.bicep' = {
  name: take('${name}-storageAccount-deployment', 64)
  params: {
    location: location
    name: name
    tags: tags
    fileShareName: fileShareName

  }
}


module filesPrivateDnsZone '../../../shared/bicep/private-dns-zone.bicep' = if ( !empty(subnetPrivateEndpointId) ) {
  // condiotional scope is not working: https://github.com/Azure/bicep/issues/7367
  //scope: empty(vnetHubResourceId) ? resourceGroup() : resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4]) 
  scope: resourceGroup(vnetHubSplitTokens[2], !empty(privateDnsZoneRg) ? privateDnsZoneRg : vnetHubSplitTokens[4])
  name: take('${replace(filesDnsZoneName, '.', '-')}-PrivateDnsZoneDeployment', 64)
  params: {
    name: filesDnsZoneName
    virtualNetworkLinks: virtualNetworkLinks
    tags: tags
  }
}

module peFiles '../../../shared/bicep/private-endpoint.bicep' = if ( !empty(subnetPrivateEndpointId) ) {
  name: take('pe-sa-${name}-Deployment', 64)
  params: {
    name: take('pe-sa-${storage.outputs.name}', 64)
    location: location
    tags: tags
    privateDnsZonesId: filesPrivateDnsZone.outputs.privateDnsZonesId
    privateLinkServiceId: storage.outputs.resourceId
    snetId: subnetPrivateEndpointId
    subresource: 'File'
  }
}

// Add the storage account key to the keyvault
// Add siteConfig with the connection string to the app service --> https://github.com/Azure/app-service-linux-docs/blob/master/BringYourOwnStorage/BYOS_azureFiles.json


@description('The resource name.')
output name string = storage.outputs.name

@description('The resource ID.')
output resourceId string = storage.outputs.resourceId

@description('The name of the resource group the storage account was created in.')
output resourceGroupName string = resourceGroup().name

