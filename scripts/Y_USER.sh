#!/bin/bash
# set +x 

# https://documenter.getpostman.com/view/7294517/SzmfZHnd


######################### CONFIG VARS
KEYCLOAK_URL='https://idp.k8s.example.test'
KEYCLOAK_REALM='master'
KEYCLOAK_ADMIN_USER='keycloak'
KEYCLOAK_ADMIN_PWD='keycloak'
KEYCLOAK_APP_NAME='cli-test-01'

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

### Creo un usuario con password
user_payload=$(cat <<EOF
  {
      "username": "${KEYCLOAK_TEST_USER}",
      "firstName": "nombre",
      "lastName": "apellido",
      "email": "${KEYCLOAK_TEST_USER}@k8s.example.test",
      "enabled": "true",
      "emailVerified": "true",
      "credentials": [
          {
              "type": "password",
              "value": "${KEYCLOAK_TEST_USER_PASS}",
              "temporary": false
          }
      ]
  }
EOF
)


echo $user_payload | jq

# echo $user_payload | jq 

${KEYCLOAK_CURL_COMMAND} -X POST "${KEYCLOAK_URL_ADMIN}/users" -H "Authorization: Bearer $KEYCLOAK_TOKEN" -H "Content-Type: application/json" --data "$user_payload" | jq 


# Add client-level roles to the user role mapping
# POST /{realm}/users/{id}/role-mappings/clients/{client}

# Get client-level role mappings for the user, and the app
# GET /{realm}/users/{id}/role-mappings/clients/{client}


# Get available client-level roles that can be mapped to the user
# GET /{realm}/users/{id}/role-mappings/clients/{client}/available


# Delete the user
# DELETE /{realm}/users/{id}

# MOSTRARMOS TODOS LOS ATRIBUTOS CREADOS

# echo KEYCLOAK_TOKEN: $KEYCLOAK_TOKEN
# echo KEYCLOAK_APP_NAME: $KEYCLOAK_APP_NAME
# echo KEYCLOAK_CLIENT_ID: $KEYCLOAK_CLIENT_ID
# echo KEYCLOAK_CLIENT_SECRET: $KEYCLOAK_CLIENT_SECRET
echo KEYCLOAK_URL_ADMIN: $KEYCLOAK_URL_ADMIN
echo KEYCLOAK_ISSUER_URL: $KEYCLOAK_ISSUER_URL
echo KEYCLOAK_TOKEN_ENDPOINT: $KEYCLOAK_TOKEN_ENDPOINT
# echo $curr_mapper_payload | jq

