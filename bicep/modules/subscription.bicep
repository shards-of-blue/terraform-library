targetScope = 'tenant'
@description('The Azure resource name to use.')
param name string
param namePrefix string = 'sub-'
param nameSuffix string = ''

@description('The Azure tags to use.')
param tags object

//@description('The Azure region into which the resources should be deployed.')
param location string

@description('Module parameters.')
param parameters object

// default properties
var defprops = {
  offerType: 'MS-AZR-0148P'
  subscriptionDisplayName: name
}

resource sub 'Microsoft.Resources/subscription@2021-10-01' = {
  name: '${namePrefix}${name}${nameSuffix}'
  location: location
  tags: tags
  properties: union(defprops, properties)
}
output subscription object = sub
