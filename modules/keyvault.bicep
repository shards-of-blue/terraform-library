// Standard module interface
@description('Module name.')
param name string = ''
param namePrefix string = 'kv${uniqueString(resourceGroup().id)}'
param nameSuffix string = ''

@description('Azure resource location.')
param location string = ''

@description('[required] Principal to assign access to.')
param principalid string
param principaltype_apiversion string

@description('Module parameters.')
param parameters object

var kvname = (!empty(name)) ? name : parameters['name']
var kvlocation = (!empty(location)) ? location : parameters['location']
var tags = parameters['tags']
var properties = (contains(parameters,'properties')) ? parameters['properties'] : {}

//var principal = parameters['principal']
//var pid = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities',principal)

// default properties
var defprops = {
  accessPolicies: [
    {
      objectId: reference(principalid,principaltype_apiversion).principalId
      tenantId: reference(principalid,principaltype_apiversion).tenantId
      permissions: {
        secrets: [
          'all'
        ]
        certificates: [
          'all'
        ]
        keys: [
          'all'
        ]
      }
    }
  ]

  sku: {
    family: 'A'
    name: 'standard'
  }

  tenantId: subscription().tenantId

}

resource symbolicname 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: '${namePrefix}${kvname}${nameSuffix}'
  location: kvlocation
  tags: tags
  properties: union(defprops, properties)
}
