@description('name must be max 24 chars, globally unique, all lowercase letters or numbers with no spaces.')
@maxLength(24)
@minLength(1)
param name string

@description('Optional. The location to deploy the Redis cache service.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Optional. Type of Storage Account to create.')
param kind string = 'StorageV2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Optional. Storage Account Sku Name.')
param sku string = 'Standard_LRS'

@allowed([
  'Hot'
  'Cool'
])
@description('Optional. Storage Account Access Tier.')
param accessTier string = 'Hot'

@description('Optional. Allows HTTPS traffic only to storage service if sets to true.')
param supportsHttpsTrafficOnly bool = true

param networkAcls object = {}

@description('Optional. File share name.')
param fileShareName string = 'share'

// Variables
var maxNameLength = 24
var storageNameValid = toLower(replace(name, '-', ''))
var uniqueStorageName = length(storageNameValid) > maxNameLength ? substring(storageNameValid, 0, maxNameLength) : storageNameValid

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {  
  name: uniqueStorageName
  location: location  
  kind: kind
  sku: {
    name: sku
  }
  tags: union(tags, {
    displayName: uniqueStorageName
  })  
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    networkAcls: networkAcls
    publicNetworkAccess: 'Disabled'
  }  
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-04-01' = {
  parent: storage
  name: 'default'
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-04-01' = {
  parent: fileService
  name: fileShareName
}

output resourceId string = storage.id
output name string = storage.name
output location string = storage.location
output resourceGroup string = resourceGroup().name
// output primaryKey string = listKeys(storage.id, storage.apiVersion).keys[0].value
// output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value}'
