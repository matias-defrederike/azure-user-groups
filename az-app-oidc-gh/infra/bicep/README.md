# Azure Bicep Infrastructure

This folder contains the infrastructure-as-code (IaC) configurations for deploying our Azure Container App and GitHub Actions OIDC identity using Azure Bicep.

## What is Azure Bicep?

Azure Bicep is a domain-specific language (DSL) that uses declarative syntax to deploy Azure resources. It acts as a native, transparent abstraction over Azure Resource Manager (ARM) templates.

Compared to JSON-based ARM templates or third-party tools like Terraform, Bicep provides a cleaner syntax, improved type safety, and immediate zero-day support for all new Azure resource types and API versions.

### Helpful Documentation

- [What is Bicep?](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)
- [Bicep Syntax Reference](https://www.google.com/search?q=https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/syntax)
- [Deploying with Microsoft Graph Bicep Extension](https://www.google.com/search?q=https://learn.microsoft.com/en-us/graph/bicep/concept-bicep-graph)

## Prerequisites

Before deploying, ensure you have the following installed and configured:

- Azure CLI: Required to authenticate and execute the deployment commands.
- Bicep CLI: Automatically installed with the Azure CLI, but can be updated via az bicep upgrade.
- Azure Authentication: Run az login to authenticate your terminal session before deploying.

## Deployment

We use a .bicepparam file to manage environment-specific variables. The command below targets our pay-sandbox subscription and deploys the infrastructure at the subscription scope.

```bicep
using 'main.bicep'

param resourceGroupName = 'rg'
param appName = 'app-name'
param vpnPublicIp = 'your-ip/32'
param acrName = 'your-acr-name'

// GitHub OIDC Variables
param githubUsername = 'your-user'
param githubRepository = 'your-repo'
param defaultBranch = 'default-branch'
```

```shell
az deployment sub create \
  --name "PlaygroundDeployment" \
  --subscription "your_subscription" \
  --location eastus \
  --parameters prod.bicepparam
```

## 🧹 Clean Up

Because this deployment spans both Azure Resource Manager (your standard infrastructure) and Microsoft Entra ID (your GitHub Actions identity), cleanup is a two-step process.

1. Delete the Infrastructure (Resource Group)
Deleting the resource group will automatically destroy the Container App, Container Registry, Log Analytics Workspace, and Managed Identity.

    ```shell
    az group delete \
      --name "bicep-playground-resource-group" \
      --subscription "your_subscription" \
      --yes \
      --no-wait
    ```

2. Delete the GitHub Actions Identity (Entra ID)
App Registrations live at the Azure Tenant level, not inside a Resource Group. You must delete this explicitly to avoid leaving orphaned identity objects behind.

    ```shell
    # Find the Object ID of the GitHub Actions App Registration
    az ad app list --display-name "github-actions-bicep-playground" --query "[0].id" -o tsv

    # Delete the App using the retrieved ID
    az ad app delete --id <paste-the-retrieved-id-here>
    ```
