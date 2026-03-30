# Azure Container App com Deploy em OIDC - Azure User Groups

## O que é o OpenID Connect (OIDC)?

O [OpenID Connect](https://learn.microsoft.com/pt-br/entra/identity-platform/v2-protocols-oidc) é um protocolo de autenticação de identidade construído sobre o OAuth 2.0. Ele permite que clientes verifiquem a identidade do usuário final com base na autenticação realizada por um Servidor de Autorização, utilizando JSON Web Tokens (JWT) para compartilhar informações de perfil (claims) com segurança, sendo amplamente adotado para logon único (SSO).

O OIDC é essencialmente o OAuth 2.0 com uma camada de identidade, tornando-o o padrão moderno preferido para logins em aplicativos web e móveis.

## github-actions-deploy

Essa pasta contém somente um exemplo de arquivo para realizar o deploy em um Azure Container App utilizando Github Actions.

Para que o Github ative o deploy é necessário que no repo que você deseja criar o deploy esse arquivo `build-deploy.yaml` no diretório `.github/workflows`. 

Como a autenticação é totalmente feita via OIDC os únicos dados sensíveis que precisamos adicionar como secret no repo são:

- AZURE_CLIENT_ID
- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID

## infra

Esta pasta contém os arquivos de Terraform necessários para provisionar a infraestrutura necessária para a prova de conceito de criar o Azure Container App, bem como os recursos necessários para a autenticação via OIDC.

Para rodar o Terraform de forma local é necessário criar um arquivo `terraform.tfvars` seguindo a estrutura abaixo:

```terraform
resource_group_name = "resource-group-name"
location            = "East US"
subscription_id     = "subs-id"
vpn_public_ip       = "YOUR-PUBLIC-IP/32"
app_name            = "app-name"
github_username     = "your-user"
github_repository   = "your-repo"
acr_name            = "acr"
```

### `container_app.tf`

Arquivo que contém dos recursos necessários para o Azure Container App rodar:

- Resource Group
- Log Analytics Workspace
- Azure Container App Environment
- Azure Container App
- Azure Container Registry
- Permissão para o container app realizar o pull no Azure Container Registry

### `github_actions_oidc.tf`

Recursos necessários para que o Github (org/user) possa autenticar na Azure utilizando OIDC

## static-app

Aplicação REACT apenas para testar o build e push da imagem no Azure Container Registry e rodar ela no Azure Container App.

Você pode substituir essa aplicação por uma imagem do nginx ou então pela imagem `mcr.microsoft.com/mcr/hello-world`.

## Para rodar a aplicação localmente utilize

```shell
# Install dependencies
npm install
# Run locally
npm run dev
```

## Docs e Referências

- [Como configurar OIDC na Azure](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)
- [Microsoft OIDC documentação](https://learn.microsoft.com/pt-br/entra/identity-platform/v2-protocols-oidc)
