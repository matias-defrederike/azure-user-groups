#!/bin/bash

# --- Variables (Update these) ---
APP_NAME="my-app"
RG_NAME="my-resource-group"
GITHUB_ORG="your-github-username"
GITHUB_REPO="your-repo-name"
SUBSCRIPTION_ID="subscription-id-or-name"
TENANT_ID="tenant-id"

echo "1. Creating the Entra ID Application..."
APP_CLIENT_ID=$(az ad app create --display-name "github-actions-$APP_NAME" --query appId -o tsv)
APP_OBJECT_ID=$(az ad app show --id $APP_CLIENT_ID --query id -o tsv)

echo "2. Creating the Service Principal..."
SP_OBJECT_ID=$(az ad sp create --id $APP_CLIENT_ID --query id -o tsv)

# Note: Entra ID propagation can sometimes take a few seconds
echo "Waiting 15 seconds for Service Principal propagation..."
sleep 15

echo "3. Assigning the Contributor role to the Service Principal..."
az role assignment create \
  --role "Contributor" \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"

echo "4. Creating the Federated Identity Credential for GitHub Actions..."
# Creating a temporary JSON file for the federated credential parameters
cat <<EOF > credential.json
{
  "name": "github-actions-deploy",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main",
  "description": "Allows GitHub Actions to authenticate using OIDC for deploying to Azure Container Apps",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az ad app federated-credential create \
  --id "$APP_OBJECT_ID" \
  --parameters @credential.json

# Clean up the temp file
rm credential.json

echo "--------------------------------------------------------"
echo "✅ Entra ID Setup Complete!"
echo "Save these values as GitHub Secrets for your workflow:"
echo "AZURE_CLIENT_ID:       $APP_CLIENT_ID"
echo "AZURE_TENANT_ID:       $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "--------------------------------------------------------"