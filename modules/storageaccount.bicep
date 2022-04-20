@description('The Azure resources name to use.')
param name string = ''
param namePrefix string = 'eur${uniqueString(resourceGroup().id)}'
param nameSuffix string = ''

param parameters object

@description('The Azure region into which the resources should be deployed.')
param location string = ''

var stlocation = (!empty(location)) ? location : parameters['location']
var tags = parameters['tags']
var sku = (contains(parameters,'sku')) ? parameters['sku'] : {
  name: 'Standard_GRS'
}
var kind = (contains(parameters,'kind')) ? parameters['kind'] : 'StorageV2'
var properties = (contains(parameters,'properties')) ? parameters['properties'] : {}

var defprops = {
}

resource symbolicname 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: '${namePrefix}${name}${nameSuffix}'
  location: stlocation
  tags: tags
  sku: sku
  kind: kind
  properties: union(defprops, properties)
}
