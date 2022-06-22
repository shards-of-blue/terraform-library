// we start in subscription scope
targetScope = 'subscription'

@description('Name of this azure profile.')
param profilename string

@description('The Azure region into which the resources should be deployed.')
param location string

@description('Tags to propagate')
param tags object

@description('The name of a service account.')
param serviceaccount string = ''

@description('Module parameters.')
param parameters object

var appOwner = '${profilename}-owner'

// parameters to propagate to modules
var defparams = {
  name: profilename
  location: location
  tags: tags
}

resource resourcegrp 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${profilename}'
  location: location
  tags: tags
}

// Find the service account id
var managedAccountApiversion = '2018-11-30'
module managedAccount '../modules/managedidentity.bicep' = {
  name: 'mid${profilename}'
  scope: resourcegrp
  params: {
    name: profilename
    name: serviceaccount
    location: location
    tags: tags
    apiVersion: managedAccountApiversion
  }
}

module profileStorageAccount '../modules/storageaccount.bicep' = if (contains(parameters,'module::storageaccount')) {
  name: 'st${profilename}'
  scope: resourcegrp
  params: {
    name: profilename
    location: location
    tags: tags
    parameters: contains(parameters,'module::storageaccount') ? parameters['module::storageaccount'] : {}
  }
}

module profileKeyvault '../modules/keyvault.bicep' = if (contains(parameters,'module::keyvault')) {
  name: 'kv${profilename}'
  scope: resourcegrp
  dependsOn: [
    managedAccount
  ]
  params: {
    name: profilename
    location: location
    tags: tags
    principalid: managedAccount.outputs.id
    principaltype_apiversion: managedAccountApiversion
    parameters: contains(parameters,'module::keyvault') ? parameters['module::keyvault'] : {}
  }
}

module profileNW '../modules/networkwatcher.bicep' = if (contains(parameters,'module::nwwatcher')) {
  name: 'nw${profilename}'
  scope: resourcegrp
  params: {
    parameters: union(defparams, contains(parameters,'module::nwwatcher') ? parameters['module::nwwatcher'] : {})
  }
}

module profileAW '../modules/analyticsworkspace.bicep' = if (contains(parameters,'module::analyticsworkspace')) {
  name: 'aw${profilename}'
  scope: resourcegrp
  params: {
    name: profilename
    location: location
    parameters: union(defparams, contains(parameters,'module::analyticsworkspace') ? parameters['module::analyticsworkspace'] : {})
  }
}

module profileVM '../modules/virtualmachine.bicep' = if (contains(parameters,'module::virtualmachine')) {
  name: 'vm${profilename}'
  scope: resourcegrp
  dependsOn: [
    managedAccount
  ]
  params: {
    name: profilename
    location: location
    principalid: managedAccount.outputs.id
    principaltype_apiversion: managedAccountApiversion
    //nicid: nicid
    parameters: union(defparams, contains(parameters,'module::virtualmachine') ? parameters['module::virtualmachine'] : {})
  }
}

//module profileVnet '../modules/Vnet.bicep' = {
//  name: '${profilename}-vnet'
//  params: {
//    parameters: parameters['module::vnet']
//  }
//}
