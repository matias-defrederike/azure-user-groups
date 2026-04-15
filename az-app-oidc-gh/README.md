# Azure Container App com Deploy em OIDC - Azure User Groups

## github-actions-deploy

Esta pasta contém o arquivo de workflow para realizar o deploy em um Azure Container App utilizando GitHub Actions.

Para que o GitHub execute o pipeline automaticamente, é necessário que o arquivo `build-deploy.yaml` seja colocado no diretório `.github/workflows/` do repositório.

Como a autenticação é totalmente feita via OIDC, os únicos dados de configuração que precisamos adicionar como *secrets* no repositório (e que não são senhas) são:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

## infra/terraform

Esta pasta contém os códigos em Terraform para provisionar toda a infraestrutura da prova de conceito, incluindo o Azure Container App e os recursos exigidos para a autenticação via OIDC.

Para rodar o Terraform localmente, crie um arquivo chamado `terraform.tfvars` na raiz desta pasta, seguindo a estrutura abaixo:

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

Arquivo que provisiona os recursos fundamentais para a execução da aplicação:

- Resource Group
- Log Analytics Workspace
- Azure Container App Environment
- Azure Container App
- Azure Container Registry (ACR)
- Permissões (Role Assignments) para o Container App realizar o pull da imagem no ACR.

### `github_actions_oidc.tf`

Provisiona a identidade (Service Principal) e as credenciais federadas para que o repositório do GitHub possa se autenticar de forma segura na Azure utilizando OIDC.

## static-app

Aplicação frontend em React criada para testar o processo de build, o push da imagem Docker para o Azure Container Registry e a execução no Azure Container App.

Nota: Você pode substituir esta aplicação por uma imagem padrão do Nginx ou pela imagem oficial `mcr.microsoft.com/mcr/hello-world`

### Para rodar a aplicação localmente utilize

```shell
# Instale as dependências
npm install
# Inicie o servidor de desenvolvimento
npm run dev
```

## Docs e Referências

- [Como configurar OIDC na Azure](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure)
- [Microsoft OIDC documentação](https://learn.microsoft.com/pt-br/entra/identity-platform/v2-protocols-oidc)
