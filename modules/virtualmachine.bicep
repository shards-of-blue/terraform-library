// Standard module interface
@description('Module name.')
param name string = ''
param namePrefix string = 'vm${uniqueString(resourceGroup().id)}'
param nameSuffix string = ''

@description('Azure resource location.')
param location string = ''

@description('[required] Principal to assign access to.')
param principalid string
param principaltype_apiversion string

param nicid string='/subscriptions/a6bb6a10-0083-4845-bc27-bb762faec360/resourceGroups/INFRA-Containers/providers/Microsoft.Network/virtualNetworks/INFRA-Containers-vnet'

@description('Module parameters.')
param parameters object

var vmname = (!empty(name)) ? name : parameters['name']
var vmlocation = (!empty(location)) ? location : parameters['location']
var tags = parameters['tags']
var properties = (contains(parameters,'properties')) ? parameters['properties'] : {}

//var principal = parameters['principal']
//var pid = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities',principal)

// default properties
var defprops = {
  hardwareProfile: {
    vmSize: 'Basic_A0'
  }

  storageProfile: {
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }

    dataDisks: []
  }

  networkProfile: {
    networkInterfaces: [
      {
        id: nicid
      }
    ]
  }

  osProfile: {
    windowsConfiguration: {
      provisionVMAgent: true
      enableAutomaticUpdates: true
    }
    secrets: []
  }

}

var identity = {
  type: 'UserAssigned'
  userAssignedIdentities: json(concat('{ "', principalid, '": {} }'))
}


resource symbolicname 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: '${namePrefix}${vmname}${nameSuffix}'
  location: vmlocation
  tags: tags
  identity: identity
  properties: union(defprops, properties)
}

