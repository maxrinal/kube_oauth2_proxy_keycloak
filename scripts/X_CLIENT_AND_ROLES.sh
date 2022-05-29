#!/bin/bash
# set +x 

# https://documenter.getpostman.com/view/7294517/SzmfZHnd

######################### CONFIG VARS
KEYCLOAK_URL='https://idp.k8s.example.test'
KEYCLOAK_REALM='master'
KEYCLOAK_ADMIN_USER='keycloak'
KEYCLOAK_ADMIN_PWD='keycloak'
KEYCLOAK_APP_NAME='cli-test-01'
######################### FIN-CONFIG VARS





######################### AUTO CONFIG VARS
KEYCLOAK_URL_ADMIN="${KEYCLOAK_URL}/admin/realms/${KEYCLOAK_REALM}"
KEYCLOAK_REALM_OIDC_CONF="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/.well-known/openid-configuration"

# KEYCLOAK_CURL_EXTRA_OPTIONS=""
KEYCLOAK_CURL_EXTRA_OPTIONS="--noproxy '*' -k --silent"
KEYCLOAK_CURL_COMMAND="curl ${KEYCLOAK_CURL_EXTRA_OPTIONS}"
######################### FIN-AUTO CONFIG VARS

# ${KEYCLOAK_CURL_COMMAND} ${KEYCLOAK_REALM_OIDC_CONF} | jq 
# Get token endpoint url
export KEYCLOAK_ISSUER_URL=$(${KEYCLOAK_CURL_COMMAND} ${KEYCLOAK_REALM_OIDC_CONF} | jq .issuer | tr -d '"')
export KEYCLOAK_TOKEN_ENDPOINT=$(${KEYCLOAK_CURL_COMMAND} ${KEYCLOAK_REALM_OIDC_CONF} | jq .token_endpoint | tr -d '"')

######################### GET AUTH TOKEN
# Get bearer token
export KEYCLOAK_TOKEN=$(${KEYCLOAK_CURL_COMMAND} -X POST "${KEYCLOAK_TOKEN_ENDPOINT}" \
 -H "Content-Type: application/x-www-form-urlencoded" \
 -d "username=${KEYCLOAK_ADMIN_USER}" \
 -d "password=${KEYCLOAK_ADMIN_PWD}" \
 -d 'grant_type=password' \
 -d 'client_id=admin-cli' | jq -r '.access_token')
 


######################### FIN-GET AUTH TOKEN
######################### CREACION CLIENT

### Creo un cliente keycloak con roles por default
client_payload=$(cat <<EOF
  {
    "clientId": "${KEYCLOAK_APP_NAME}",
    "rootUrl": "https://${KEYCLOAK_APP_NAME}.k8s.example.test",
    "adminUrl": "",
    "baseUrl": "https://${KEYCLOAK_APP_NAME}.k8s.example.test/",
    "enabled": true,
    "clientAuthenticatorType": "client-secret",
    "redirectUris": [
      "https://${KEYCLOAK_APP_NAME}.k8s.example.test/*"
    ],
    "publicClient": false,
    "serviceAccountsEnabled": false,
    "protocol": "openid-connect"
  }
EOF
)

# echo $client_payload

${KEYCLOAK_CURL_COMMAND} -X POST "${KEYCLOAK_URL_ADMIN}/clients" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" --data "$client_payload" | jq 


######################### FIN-CREACION CLIENT
######################### GET CLIENT ID

KEYCLOAK_CLIENT_ID=$(${KEYCLOAK_CURL_COMMAND} -X GET ${KEYCLOAK_URL_ADMIN}/clients?clientId=$KEYCLOAK_APP_NAME \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $KEYCLOAK_TOKEN" | jq .[0].id | tr -d '"')

# echo $KEYCLOAK_CLIENT_ID

######################### FIN-GET CLIENT ID
######################### CLIENT MAPPER
# Creo un client mapper( roles  a un atributo )

# Create client mappers
# POST /{realm}/clients/{id}/protocol-mappers/models


curr_mapper_payload=$(cat <<EOF
{
    "name": "extra_client_roles",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-usermodel-client-role-mapper",
    "consentRequired": false,
    "config": {
        "multivalued": "true",
        "userinfo.token.claim": "true",
        "id.token.claim": "true",
        "access.token.claim": "true",
        "claim.name": "${KEYCLOAK_APP_NAME}-roles",
        "jsonType.label": "String",
        "usermodel.clientRoleMapping.clientId": "${KEYCLOAK_APP_NAME}"
    }
}
EOF
)

# echo $curr_mapper_payload | jq

# Creamos el role mapper para el client
${KEYCLOAK_CURL_COMMAND} -X POST "${KEYCLOAK_URL_ADMIN}/clients/${KEYCLOAK_CLIENT_ID}/protocol-mappers/models" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" --data "$curr_mapper_payload" 


######################### FIN-CLIENT MAPPER
######################### CREAMOS ROLES 

curr_role_payload=$(cat <<EOF
{
    "name": "full_admin",
    "composite": false,
    "clientRole": true,
    "attributes": {}
}
EOF
)

# echo $curr_role_payload | jq

${KEYCLOAK_CURL_COMMAND} -X POST "${KEYCLOAK_URL_ADMIN}/clients/${KEYCLOAK_CLIENT_ID}/roles" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" --data "$curr_role_payload" 

######################### FIN-CREAMOS ROLES 
######################### OBTENEMOS CLIENT SECRET

KEYCLOAK_CLIENT_SECRET=$(${KEYCLOAK_CURL_COMMAND} -X GET "${KEYCLOAK_URL_ADMIN}/clients/${KEYCLOAK_CLIENT_ID}/client-secret" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $KEYCLOAK_TOKEN" | jq .value | tr -d '"' )
# echo $KEYCLOAK_CLIENT_SECRET

######################### FIN-OBTENEMOS CLIENT SECRET
######################### BORRAMOS CLIENT RECIEN GENERADO

# Borramos el cliente recien creado
# DELETE /{realm}/clients/{id}
# ${KEYCLOAK_CURL_COMMAND} -X DELETE "${KEYCLOAK_URL_ADMIN}/clients/${KEYCLOAK_CLIENT_ID}" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json"

######################### FIN-BORRAMOS CLIENT RECIEN GENERADO





# MOSTRARMOS TODOS LOS ATRIBUTOS CREADOS

# echo KEYCLOAK_TOKEN: $KEYCLOAK_TOKEN
echo KEYCLOAK_APP_NAME: $KEYCLOAK_APP_NAME
echo KEYCLOAK_CLIENT_ID: $KEYCLOAK_CLIENT_ID
echo KEYCLOAK_CLIENT_SECRET: $KEYCLOAK_CLIENT_SECRET
echo KEYCLOAK_ISSUER_URL: $KEYCLOAK_ISSUER_URL
# echo $curr_mapper_payload | jq

