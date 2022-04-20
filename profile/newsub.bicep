// we start in tenant scope
targetScope = 'tenant'

@description('Name of this azure profile.')
param profilename string

@description('The Azure region into which the resources should be deployed.')
param location string

@description('Tags to propagate')
param tags object

@description('The name of a service account.')
param serviceaccount string = ''

@description('Module parameters.')
param parameters object = {}

param billingScope string
param workload string

//var appOwner = '${profilename}-owner'

// parameters to propagate to modules
var defparams = {
  name: profilename
  location: location
  tags: tags
}

// default properties
var subprops = {
  offerType: 'MS-AZR-0148P'
  subscriptionDisplayName: profilename
}

//resource sub 'Microsoft.Resources/subscriptionDefinitions@2021-04-01' = {
//  name: 'sub-${profilename}'
//  location: location
//  tags: tags
//  properties: union(subprops, {})
//}

resource sub 'Microsoft.Subscription/aliases@2020-09-01' = {
  name: 'sub-${profilename}'
  location: location
  tags: tags
  properties: {
    displayName: 'sub-${profilename}'
    billingScope: billingScope
    workload: workload
  }
}
