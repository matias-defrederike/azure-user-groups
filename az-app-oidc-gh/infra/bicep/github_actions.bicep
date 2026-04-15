// Instructs Bicep to load the Microsoft Graph types
extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:0.2.0-preview'

@description('Base name for the application')
param appName string

@description('GitHub Username')
param githubUsername string

@description('GitHub Repository')
param githubRepository string

@description('Default Branch')
param defaultBranch string


// ---------------------------------------------------------
// Entra ID Application (App Registration)
// ---------------------------------------------------------
resource app 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: 'github-actions-${appName}'
  displayName: 'github-actions-${appName}'
}

// ---------------------------------------------------------
// Service Principal
// ---------------------------------------------------------
resource sp 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: app.appId
}

// ---------------------------------------------------------
// Federated Identity Credential (OIDC for GitHub Actions)
// ---------------------------------------------------------
resource fedId 'Microsoft.Graph/applications/federatedIdentityCredentials@v1.0' = {
  name: '${app.uniqueName}/github-actions-deploy'
  description: 'Allows GitHub Actions to authenticate using OIDC for deploying to Azure Container Apps'
  audiences: [
    'api://AzureADTokenExchange'
  ]
  issuer: 'https://token.actions.githubusercontent.com'
  // Constructs the exact subject string expected by GitHub Actions
  subject: 'repo:${githubUsername}/${githubRepository}:ref:refs/heads/${defaultBranch}'
}

// ---------------------------------------------------------
// Role Assignment (Contributor)
// ---------------------------------------------------------
// Bicep requires the static GUID for the Built-In 'Contributor' role
var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource contributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
name: guid(resourceGroup().id, appName, contributorRoleDefinitionId)  
properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: sp.id
    principalType: 'ServicePrincipal'
  }
}

output spObjectId string = sp.id
