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

@description('Conditional. If sqlServerAdministrators is given, this is not required')
param mysqlAdminLogin string

@description('Conditional. If sqlServerAdministrators is given, this is not required')
@secure()
param mysqlAdminPassword string

@description('Provide Subnet ID')
param subnetId string

module mySqlDbAndServer '../../../shared/bicep/databases/mysql.bicep' = {
  name: take('mysqlDbAndServer-${name}-Deployment', 64)
  params: {
    administratorLogin: mysqlAdminLogin
    administratorLoginPassword: mysqlAdminPassword
    databaseName: databaseName
    name: name
    subnetId: subnetId
  }
}
