// Standard module interface
@description('Module name.')
param name string = ''
param namePrefix string = 'nw${uniqueString(resourceGroup().id)}'
param nameSuffix string = ''

@description('Azure resource location.')
param location string = ''

@description('Module parameters.')
param parameters object

var nwname = (!empty(name)) ? name : parameters['name']
var nwlocation = (!empty(location)) ? location : parameters['location']
var tags = parameters['tags']


resource symbolicname 'Microsoft.Network/networkWatchers@2021-05-01' = {
  name: '${namePrefix}${nwname}${nameSuffix}'
  location: nwlocation
  tags: tags
  properties: {}
}
