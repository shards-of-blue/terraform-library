@description('The Azure resources name to use.')
param name string = ''
param namePrefix string = 'eur${uniqueString(resourceGroup().id)}'
param nameSuffix string = ''

param staccounts object

@description('The Azure region into which the resources should be deployed.')
param location string = ''

var stlocation = (!empty(location)) ? location : parameters['location']
var tags = parameters['tags']
var sku = (contains(parameters,'sku')) ? parameters['sku'] : {
  name: 'Standard_GRS'
}
var defaultsku = { name: 'Standard_GRS' }
var defaultkind = 'StorageV2'

var defprops = {
}

resource symbolicname 'Microsoft.Storage/storageAccounts@2021-08-01' = [ for r in items(staccounts) ]{
  name: '${namePrefix}${name}${r.value.nameSuffix}'
  location: stlocation
  tags: tags
  sku: contains(r.value.parameters,'sku')) ? r.value.parameters['sku'] : defaultsku
  kind: contains(r.value.parameters,'kind')) ? r.value.parameters['kind'] : defaultkind
  properties: union(defprops, contains(r.value.parameters,'properties')) ? r.value.parameters['properties'] : {})
}

output staccounts array = symbolicname
