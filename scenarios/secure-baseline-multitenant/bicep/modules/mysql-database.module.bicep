@description('Required. The name of the MySQL server resource. Lowercase letters, numbers, and hyphens. Cannot start or end with hyphen.')
@maxLength(63)
@minLength(1)
param name string

@description('Required. The name of the database. Cannot use: <>*%&:\\/? or control characters Cannot end with period or space')
@maxLength(128)
@minLength(1)
param databaseName string

@description('Optional. The location to deploy the MySQL server.')
param location string 

@description('Optional. Tags of the resource.')
param tags object = {}

@description('The name of an existing keyvault, that it will be used to store secrets (connection string)' )
param keyvaultName string

@description('An existing Log Analytics WS Id for creating app Insights, diagnostics etc.')
param logAnalyticsWsId string

@description('if empty, private dns zone will be deployed in the current RG scope')
param vnetHubResourceId string

@description('Optional. Array of custom objects describing vNet links of the DNS zone. Each object should contain vnetName, vnetId, registrationEnabled')
param virtualNetworkLinks array = []

var vnetHubSplitTokens = !empty(vnetHubResourceId) ? split(vnetHubResourceId, '/') : array('')

var mysqlDnsZoneName = 'privatelink.mysql.database.azure.com'

@description('Conditional. If sqlServerAdministrators is given, this is not required')
param mysqlAdminLogin string

@description('Conditional. If sqlServerAdministrators is given, this is not required')
@secure()
param mysqlAdminPassword string

@description('Provide Subnet ID')
param subnetId string

@description('The name of the existing VNET Hub Private DNS Zone Resource Group')
param privateDnsZoneRg string = ''

module mysqlPrivateDnsZone '../../../shared/bicep/private-dns-zone.bicep' = {
  // condiotional scope is not working: https://github.com/Azure/bicep/issues/7367
  //scope: empty(vnetHubResourceId) ? resourceGroup() : resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4]) 
  scope: resourceGroup(vnetHubSplitTokens[2], !empty(privateDnsZoneRg) ? privateDnsZoneRg : vnetHubSplitTokens[4])
  name: take('${replace(mysqlDnsZoneName, '.', '-')}-PrivateDnsZoneDeployment', 64)
  params: {
    name: mysqlDnsZoneName
    virtualNetworkLinks: virtualNetworkLinks
    tags: tags
  }
}

module mySqlDbAndServer '../../../shared/bicep/databases/mysql.bicep' = {
  name: take('mysqlDbAndServer-${name}-Deployment', 64)
  params: {
    name: name
    location: location
    tags: tags
    subnetId: subnetId
    administratorLogin: mysqlAdminLogin
    administratorLoginPassword: mysqlAdminPassword
    databaseName: databaseName
    privateDnsZoneResourceId: mysqlPrivateDnsZone.outputs.privateDnsZonesId
  }
}



