@description('Location for all resources')
param location string

@description('Base name for the application')
param appName string

@description('Allowed VPN Public IP for App Ingress')
param vpnPublicIp string

@description('Name of the Container Registry')
param acrName string

@description('Object ID of the GitHub Service Principal for ACR Push')
param githubSpObjectId string

// ---------------------------------------------------------
// Log Analytics Workspace
// ---------------------------------------------------------
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'logs-${appName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ---------------------------------------------------------
// Container App Environment
// ---------------------------------------------------------
resource cae 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: 'cae-${appName}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
  }
}

// ---------------------------------------------------------
// Container Registry
// ---------------------------------------------------------
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
  }
}

// ---------------------------------------------------------
// Identity & Role Assignments
// ---------------------------------------------------------
resource acaIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-aca-acrpull'
  location: location
}

// Bicep requires specific GUIDs for built-in roles
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var acrPushRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')

resource acaAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, acaIdentity.id, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: acaIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource acrPushAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, githubSpObjectId, acrPushRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPushRoleDefinitionId
    principalId: githubSpObjectId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------
// Container App
// ---------------------------------------------------------
resource app 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'app-${appName}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acaIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: cae.id
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: acr.properties.loginServer
          identity: acaIdentity.id
        }
      ]
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: true
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        ipSecurityRestrictions: [
          {
            name: 'AllowMyIP'
            action: 'Allow'
            ipAddressRange: vpnPublicIp
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'container-${appName}'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5') // Handled as numeric decimal internally
            memory: '1Gi'
          }
        }
      ]
    }
  }
  dependsOn: [
    acaAcrPull // Wait for pull permissions before attempting to pull
  ]
}

// ---------------------------------------------------------
// ACR Task (Purge Old Images)
// ---------------------------------------------------------
resource purgeTask 'Microsoft.ContainerRegistry/registries/tasks@2019-06-01-preview' = {
  parent: acr
  name: 'PurgeOldImages'
  location: location
  properties: {
    platform: {
      os: 'Linux'
    }
    step: {
      type: 'EncodedTask'
      // Bicep handles multi-line strings easily inside the base64 function
      encodedTaskContent: base64('''
version: v1.1.0
steps:
  - cmd: acr purge --filter 'static-app:.*' --keep 10 --untagged
''')
      contextPath: '/dev/null'
    }
    trigger: {
      timerTriggers: [
        {
          name: 'daily_purge_schedule'
          schedule: '0 0 * * *'
          status: 'Enabled'
        }
      ]
    }
  }
}
