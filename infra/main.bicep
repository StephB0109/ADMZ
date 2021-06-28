targetScope = 'subscription'

// General parameters
@description('Specifies the location for all resources.')
param location string
@allowed([
  'dev'
  'tst'
  'prd'
])
@description('Specifies the environment of the deployment.')
param environment string = 'dev'
@minLength(2)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string
@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

// Network parameters
@description('Specifies the address space of the vnet.')
param vnetAddressPrefix string = '10.0.0.0/16'
@description('Specifies the address space of the subnet that is use for Azure Firewall.')
param azureFirewallSubnetAddressPrefix string = '10.0.0.0/24'
@description('Specifies the address space of the subnet that is used for the services.')
param servicesSubnetAddressPrefix string = '10.0.1.0/24'
@description('Specifies the private IP address of the central firewall.')
param firewallPrivateIp string = '10.0.0.4'
@description('Specifies the private IP addresses of the dns servers.')
param dnsServerAdresses array = [
  '10.0.0.4'
]

// Variables
var name = toLower('${prefix}-${environment}')
var tagsDefault = {
  Owner: 'Enterprise Scale Analytics'
  Project: 'Enterprise Scale Analytics'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}
var tagsJoined = union(tagsDefault, tags)

// Network resources
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-network'
  location: location
  tags: tagsJoined
  properties: {}
}

module networkServices 'modules/network.bicep' = {
  name: 'networkServices'
  scope: networkResourceGroup
  params: {
    prefix: name
    location: location
    tags: tagsJoined
    vnetAddressPrefix: vnetAddressPrefix
    azureFirewallSubnetAddressPrefix: azureFirewallSubnetAddressPrefix
    servicesSubnetAddressPrefix: servicesSubnetAddressPrefix
    dnsServerAdresses: dnsServerAdresses
    enableDnsAndFirewallDeployment: true
    firewallPrivateIp: firewallPrivateIp
  }
}

// Private DNS zones
resource globalDnsResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-global-dns'
  location: location
  tags: tagsJoined
  properties: {}
}

module globalDnsZones 'modules/services/privatednszones.bicep' = {
  name: 'globalDnsZones'
  scope: globalDnsResourceGroup
  params: {
    tags: tagsJoined
    vnetId: networkServices.outputs.vnetId
  }
}

// Governance resources
resource governanceResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-governance'
  location: location
  tags: tagsJoined
  properties: {}
}

module governanceResources 'modules/governance.bicep' = {
  name: 'governanceResources'
  scope: governanceResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdPurview: globalDnsZones.outputs.privateDnsZoneIdPurview
    privateDnsZoneIdStorageBlob: globalDnsZones.outputs.privateDnsZoneIdBlob
    privateDnsZoneIdStorageQueue: globalDnsZones.outputs.privateDnsZoneIdQueue
    privateDnsZoneIdEventhubNamespace: globalDnsZones.outputs.privateDnsZoneIdNamespace
    privateDnsZoneIdKeyVault: globalDnsZones.outputs.privateDnsZoneIdKeyVault
  }
}

// Container resources
resource containerResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-container'
  location: location
  tags: tagsJoined
  properties: {}
}

module containerResources 'modules/container.bicep' = {
  name: 'containerResources'
  scope: containerResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdContainerRegistry: globalDnsZones.outputs.privateDnsZoneIdContainerRegistry
  }
}

// Consumption resources
resource consumptionResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-consumption'
  location: location
  tags: tagsJoined
  properties: {}
}

module consumptionResources 'modules/consumption.bicep' = {
  name: 'consumptionResources'
  scope: consumptionResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.serviceSubnet
    privateDnsZoneIdSynapseprivatelinkhub: globalDnsZones.outputs.privateDnsZoneIdSynapse
    privateDnsZoneIdAnalysis: globalDnsZones.outputs.privateDnsZoneIdAnalysis
    privateDnsZoneIdPbiDedicated: globalDnsZones.outputs.privateDnsZoneIdPbiDedicated
    privateDnsZoneIdPowerQuery: globalDnsZones.outputs.privateDnsZoneIdPowerQuery
  }
}

// Automation services
resource automationResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-automation'
  location: location
  tags: tagsJoined
  properties: {}
}

// Management services
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-mgmt'
  location: location
  tags: tagsJoined
  properties: {}
}

// Outputs
output vnetId string = networkServices.outputs.vnetId
output firewallPrivateIp string = networkServices.outputs.firewallPrivateIp
output purviewId string = governanceResources.outputs.purviewId
output privateDnsZoneIdKeyVault string = globalDnsZones.outputs.privateDnsZoneIdKeyVault
output privateDnsZoneIdDataFactory string = globalDnsZones.outputs.privateDnsZoneIdDataFactory
output privateDnsZoneIdDataFactoryPortal string = globalDnsZones.outputs.privateDnsZoneIdDataFactoryPortal
output privateDnsZoneIdBlob string = globalDnsZones.outputs.privateDnsZoneIdBlob
output privateDnsZoneIdDfs string = globalDnsZones.outputs.privateDnsZoneIdDfs
output privateDnsZoneIdSqlServer string = globalDnsZones.outputs.privateDnsZoneIdSqlServer
output privateDnsZoneIdMySqlServer string = globalDnsZones.outputs.privateDnsZoneIdMySqlServer
output privateDnsZoneIdNamespace string = globalDnsZones.outputs.privateDnsZoneIdNamespace
output privateDnsZoneIdSynapseDev string = globalDnsZones.outputs.privateDnsZoneIdSynapseDev
output privateDnsZoneIdSynapseSql string = globalDnsZones.outputs.privateDnsZoneIdSynapseSql