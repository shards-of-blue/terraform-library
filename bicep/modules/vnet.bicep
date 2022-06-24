param prefixes array
param subnets array
param location string = resourceGroup().location

#    subnets: [
#      {
#        name: 'Subnet-1'
#        properties: {
#          addressPrefix: '10.0.0.0/24'
#        }
#      }
#      {
#        name: 'Subnet-2'
#        properties: {
#          addressPrefix: '10.0.1.0/24'
#        }
#      }
#    ]


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'name'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: prefixes
    }
    subnets: subnets
  }
}
