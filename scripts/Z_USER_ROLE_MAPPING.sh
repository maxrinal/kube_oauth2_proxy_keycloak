#!/bin/bash
# set +x 

# https://documenter.getpostman.com/view/7294517/SzmfZHnd
# https://documenter.getpostman.com/view/7294517/SzmfZHnd#4a27e8c7-3b1e-4031-8de8-3ec0e89bdb18

######################### CONFIG VARS
KEYCLOAK_URL='https://idp.k8s.example.test'
KEYCLOAK_REALM='master'
KEYCLOAK_ADMIN_USER='keycloak'
KEYCLOAK_ADMIN_PWD='keycloak'
KEYCLOAK_APP_NAME='cli-test-01'
KEYCLOAK_APP_NAME_ROLE_ADMIN='full_admin'

KEYCLOAK_TEST_USER='maxi'
KEYCLOAK_TEST_USER_PASS='maxi'

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
######################### CREACION USUARIO


# ${KEYCLOAK_CURL_COMMAND} -X GET "${KEYCLOAK_URL_ADMIN}/users" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" --data "$user_payload" | jq 
# Busco el usuario maxi, para obtener su id
KEYCLOAK_TEST_USER_ID=$(${KEYCLOAK_CURL_COMMAND} -X GET "${KEYCLOAK_URL_ADMIN}/users?username=${KEYCLOAK_TEST_USER}" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" | jq .[].id | tr -d '"')




######################### OBTENEMOS CLIENT ID

KEYCLOAK_CLIENT_ID=$(${KEYCLOAK_CURL_COMMAND} -X GET ${KEYCLOAK_URL_ADMIN}/clients?clientId=$KEYCLOAK_APP_NAME \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $KEYCLOAK_TOKEN" | jq .[0].id | tr -d '"')


# echo $KEYCLOAK_CLIENT_SECRET

######################### FIN-OBTENEMOS CLIENT ID
######################### Agregamos role-mapping al usuario


# Get client-level role mappings for the user, and the app
# GET /{realm}/groups/{id}/role-mappings/clients/{client}
# ${KEYCLOAK_CURL_COMMAND} -X GET "${KEYCLOAK_URL_ADMIN}/users/${KEYCLOAK_TEST_USER_ID}/groups" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json"

# Get client-level role mappings for the user, and the app
# GET /{realm}/users/{id}/role-mappings/clients/{client}

# ${KEYCLOAK_CURL_COMMAND} -X GET "${KEYCLOAK_URL_ADMIN}/users/${KEYCLOAK_TEST_USER_ID}/role-mappings/clients/${KEYCLOAK_CLIENT_ID}" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json"

# Get available client-level roles that can be mapped to the user
# GET /{realm}/users/{id}/role-mappings/clients/{client}/available

KEYCLOAK_ROLE_TO_ADD=$( ${KEYCLOAK_CURL_COMMAND} \
-X GET "${KEYCLOAK_URL_ADMIN}/users/${KEYCLOAK_TEST_USER_ID}/role-mappings/clients/${KEYCLOAK_CLIENT_ID}/available?name=${KEYCLOAK_APP_NAME_ROLE_ADMIN}" \
-H "Authorization: Bearer $KEYCLOAK_TOKEN" \
-H "Content-Type: application/json" )
# jq .[].id )

# echo $KEYCLOAK_ROLE_TO_ADD | jq 
${KEYCLOAK_CURL_COMMAND} \
-X POST "${KEYCLOAK_URL_ADMIN}/users/${KEYCLOAK_TEST_USER_ID}/role-mappings/clients/${KEYCLOAK_CLIENT_ID}" \
-H "Authorization: Bearer $KEYCLOAK_TOKEN" \
-H "Content-Type: application/json" --data $KEYCLOAK_ROLE_TO_ADD



######################### FIN-Agregamos role-mapping al usuario

echo KEYCLOAK_CLIENT_ID: $KEYCLOAK_CLIENT_ID
echo KEYCLOAK_ROLE_ID: $KEYCLOAK_ROLE_ID


echo KEYCLOAK_TEST_USER: $KEYCLOAK_TEST_USER
echo KEYCLOAK_TEST_USER_ID: $KEYCLOAK_TEST_USER_ID

echo KEYCLOAK_URL_ADMIN: $KEYCLOAK_URL_ADMIN
echo KEYCLOAK_ISSUER_URL: $KEYCLOAK_ISSUER_URL
echo KEYCLOAK_TOKEN_ENDPOINT: $KEYCLOAK_TOKEN_ENDPOINT
# echo $curr_mapper_payload | jq


# Add client-level roles to the user role mapping
# POST /{realm}/users/{id}/role-mappings/clients/{client}


# You have to pass client UUID to the role-mappings REST method, not the ID that you specify when creating a client in admin UI. Use GET /admin/realms/{realm}/clients?clientId=realm-management REST method to find out the client UUID.

# UPDATE

# In Keycloak 6.0.1 to add a role it is required to pass role name and id.

# Example:

# POST /auth/admin/realms/{realm}/users/{user}/role-mappings/clients/{client}

# [
#   {
#     "id": "0830ff39-43ea-48bb-af8f-696bc420c1ce",
#     "name": "create-client"
#   }
# ]



# Add client-level roles to the user role mapping
# POST /{realm}/users/{id}/role-mappings/clients/{client}

# Get client-level role mappings for the user, and the app
# GET /{realm}/users/{id}/role-mappings/clients/{client}