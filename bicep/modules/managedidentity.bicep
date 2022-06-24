param apiVersion string
param name string
param location string

resource mid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  apiVersion: apiVersion
  name: name
  location: location
}

output id string = mid.id

