# Azure Container App com Deploy em OIDC - Azure User Groups

## github-actions-deploy

Essa pasta contém somente um exemplo de arquivo para realizar o deploy em um Azure Container App utilizando Github Actions.

Para que o Github ative o deploy é necessário que no repo que você deseja criar o deploy esse arquivo `build-deploy.yaml` no diretório `.github/workflows`. 

Como a autenticação é totalmente feita via OIDC os únicos dados sensíveis que precisamos adicionar como secret no repo são:

- AZURE_CLIENT_ID
- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID

## infra
