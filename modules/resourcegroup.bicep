targetScope = 'subscription'
@description('The Azure resource name to use.')
param name string
param namePrefix string = 'rg-'
param nameSuffix string = ''

@description('The Azure tags to use.')
param tags object

//@description('The Azure region into which the resources should be deployed.')
param location string

//param parent string = subscription().subscriptionId
//description('The Azure tenant to use.')
//param tenantId string = subscription().tenantId

param managedBy string = ''

resource grp 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${namePrefix}${name}${nameSuffix}'
  location: location
  tags: tags
  //managedBy: (!empty(managedBy)) ? managedBy : json('null')
  managedBy: managedBy
}
output resourcegrp object = grp
