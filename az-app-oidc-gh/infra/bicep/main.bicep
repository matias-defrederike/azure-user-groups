targetScope = 'subscription'

param resourceGroupName string
param location string = 'eastus'
param appName string
param vpnPublicIp string
param acrName string

// New parameters for GitHub Actions
param githubUsername string
param githubRepository string
param defaultBranch string

// 1. Create the Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

// 2. Deploy GitHub Actions Identity Infrastructure 
module githubActions 'github_actions.bicep' = {
  name: 'githubActionsDeployment'
  scope: rg
  params: {
    appName: appName
    githubUsername: githubUsername
    githubRepository: githubRepository
    defaultBranch: defaultBranch
  }
}

// 3. Deploy Container App Infrastructure
module containerApp 'container_app.bicep' = {
  name: 'containerAppDeployment'
  scope: rg
  params: {
    location: location
    appName: appName
    vpnPublicIp: vpnPublicIp
    acrName: acrName
    githubSpObjectId: githubActions.outputs.spObjectId 
  }
}
