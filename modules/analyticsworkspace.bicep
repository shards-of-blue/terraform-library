param name string = ''
param namePrefix string = 'la${uniqueString(resourceGroup().id)}'
param nameSuffix string = ''
param location string = ''
param tags object = {}
param parameters object = {}

var properties = (contains(parameters,'properties')) ? parameters['properties'] : {}

var defprops = {
  sku: {
    //capacityReservationLevel: 100
    name: 'PerGB2018'
  }

  workspaceCapping: {
    dailyQuotaGb: 1
  }

  retentionInDays: 180
}

resource ws 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${namePrefix}${name}${nameSuffix}'
  location: location
  properties: union(defprops, properties)
}

output id string = ws.id

