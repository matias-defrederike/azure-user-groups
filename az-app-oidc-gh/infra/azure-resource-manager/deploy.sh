SUBSCRIPTION="your-subscription-id-or-name"
RESOURCE_GROUP="my-resource-group"
LOCATION="eastus"
APP_NAME="my-app"
ACR_NAME="myuniqueregistryname"
VPN_PUBLIC_IP="XXXXX/32"

az deployment sub create \
  --subscription "$SUBSCRIPTION" \
  --location "$LOCATION" \
  --template-file azuredeploy.json \
  --parameters \
      rgName="$RESOURCE_GROUP" \
      location="$LOCATION" \
      appName="$APP_NAME" \
      acrName="$ACR_NAME" \
      vpnPublicIp="$VPN_PUBLIC_IP"
