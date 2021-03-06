#export CONTAINER_IMAGE_TAG=*********
#export YOUR_ACR_NAME=***********
export YOUR_KEY_VAULT=*********
#export containerusername=`az acr credential show --name *********** | jq '.username' | sed 's/"//g' `
#export containerpassword=`az acr credential show --name *********** | jq '.passwords[0].value' | sed 's/"//g' `
export PROJECT_PREFIX=***********
export LOCATION="westeurope"

az keyvault secret set --vault-name $YOUR_KEY_VAULT --name 'sonarqube-sql-admin' --value sonarqube
az keyvault secret set --vault-name $YOUR_KEY_VAULT --name 'sonarqube-sql-admin-password' --value Wordgrass85Pattern
#az keyvault secret set --vault-name $YOUR_KEY_VAULT --name 'container-registry-admin' --value $containerusername
#az keyvault secret set --vault-name $YOUR_KEY_VAULT --name 'container-registry-admin-password' --value $containerpassword

# General
export RESOURCE_GROUP_NAME="$PROJECT_PREFIX-sonarqube-rg"

# SQL database related
export SQL_ADMIN_USER=`az keyvault secret show -n sonarqube-sql-admin --vault-name $YOUR_KEY_VAULT | jq -r '.value'`
export SQL_ADMIN_PASSWORD=`az keyvault secret show -n sonarqube-sql-admin-password --vault-name $YOUR_KEY_VAULT | jq -r '.value'`
export SQL_SERVER_NAME="$PROJECT_PREFIX-sql-server"
export DATABASE_NAME="$PROJECT_PREFIX-sonar-sql-db"
export DATABASE_SKU="S0"

# Webapp related 
export APP_SERVICE_NAME="$PROJECT_PREFIX-sonarqube-app-service"
export APP_SERVICE_SKU="P3v2"

# Container image related
#export CONTAINER_REGISTRY_NAME="$YOUR_ACR_NAME"
#export CONTAINER_REGISTRY_FQDN="$CONTAINER_REGISTRY_NAME.azurecr.io"
#export REG_ADMIN_USER=`az keyvault secret show -n container-registry-admin --vault-name $YOUR_KEY_VAULT | jq -r '.value'`
#export REG_ADMIN_PASSWORD=`az keyvault secret show -n container-registry-admin-password --vault-name $YOUR_KEY_VAULT | jq -r '.value'`
export WEBAPP_NAME="$PROJECT_PREFIX-sonarqube-webapp"
#export CONTAINER_IMAGE_NAME="$PROJECT_PREFIX-sonar"
#export CONTAINER_IMAGE_TAG=$CONTAINER_IMAGE_TAG

# Concatenated variable strings for better readability
export DB_CONNECTION_STRING="jdbc:sqlserver://$SQL_SERVER_NAME.database.windows.net:1433;database=$DATABASE_NAME;user=$SQL_ADMIN_USER@$SQL_SERVER_NAME;password=$SQL_ADMIN_PASSWORD;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
# Checkout the repository containing the Dockerfile and the config script
#git clone https://github.com/kuntal2318/sonarqube-azure-setup.git && cd sonarqube-azure-setup

# Log into your Azure Container Registry  
#sudo az acr login --name $CONTAINER_REGISTRY_NAME

# Build the image and push to the registry
#sudo docker build -t $CONTAINER_IMAGE_NAME:$CONTAINER_IMAGE_TAG .
#sudo docker tag $CONTAINER_IMAGE_NAME:$CONTAINER_IMAGE_TAG "$CONTAINER_REGISTRY_FQDN/$CONTAINER_IMAGE_NAME:$CONTAINER_IMAGE_TAG"
#sudo docker push "$CONTAINER_REGISTRY_FQDN/$CONTAINER_IMAGE_NAME:$CONTAINER_IMAGE_TAG"

# Add resource group; tag appropriately :-)
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --tag 'createdBy=Kuntal Mehta' 'createdFor=Resource group for SonarQube components'

# Create sql server and database
az sql server create \
    --name $SQL_SERVER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --admin-user $SQL_ADMIN_USER \
    --admin-password $SQL_ADMIN_PASSWORD
az sql db create \
    --resource-group $RESOURCE_GROUP_NAME \
    --server $SQL_SERVER_NAME \
    --name $DATABASE_NAME \
    --service-objective $DATABASE_SKU \
    --collation "SQL_Latin1_General_CP1_CS_AS"

# Set SQL server's firewall rules to accept requests from Azure services only (this is going to be our Azure Webapp)
az sql server firewall-rule create \
    --resource-group $RESOURCE_GROUP_NAME \
    --server $SQL_SERVER_NAME -n "AllowAllWindowsAzureIps" \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0
	
# Create an Azure App Service Plan with Linux as Host OS
az appservice plan create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $APP_SERVICE_NAME \
    --sku $APP_SERVICE_SKU \
    --is-linux

# Create the WebApp hosting the Sonarqube container
az webapp create \
    --resource-group $RESOURCE_GROUP_NAME \
    --plan $APP_SERVICE_NAME \
    --name $WEBAPP_NAME \
    --deployment-container-image-name sonarqube:developer
	
# Configure the WebApp
az webapp config connection-string set \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $WEBAPP_NAME -t SQLAzure \
    --settings SONARQUBE_JDBC_URL=$DB_CONNECTION_STRING \
    --connection-string-type SQLAzure
az webapp config set \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $WEBAPP_NAME \
    --always-on true
az webapp log config \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $WEBAPP_NAME \
    --docker-container-logging filesystem
	
# Restart app to ensure all environment variables are considered correctly; wait 5 minutes.
az webapp restart \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $WEBAPP_NAME
	
az webapp log download \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $WEBAPP_NAME
