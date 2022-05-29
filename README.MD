# TEST OAUTH2-PROXY


Prueba de integracion de oauth2-proxy con keycloak, puede ser configurado utilizando config files o variables de entorno, en este caso utilizaremos variables de entorno referenciadas desde un secret.



# OAUTH PROXY

El despliegue requiere 
* Un cluster de kubernetes con dns  [Example](https://github.com/maxrinal/kube_helmfile)
* Un keycloak desplegado [Example](KEYCLOAK_KUBERNETES.md)


Extra info 
* [Oauth external auth](https://kubernetes.github.io/ingress-nginx/examples/auth/oauth-external-auth/)
* [Oauth external auth](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
* [Oauth config file](https://github.com/oauth2-proxy/oauth2-proxy/blob/master/contrib/oauth2-proxy.cfg.example)


# Create httpdump with sidecar and configmap


```bash

# Creamos el client y obtenemos su secret
bash scripts/X_CLIENT_AND_ROLES.sh
...
KEYCLOAK_CLIENT_SECRET: 0nkUxyhJsTMNNRghIGFTZEXbqNqru5fc
...
# Actualizamos  oauth.env con el nuevo secret 
sed -i 's/^OAUTH2_PROXY_CLIENT_SECRET.*/OAUTH2_PROXY_CLIENT_SECRET=0nkUxyhJsTMNNRghIGFTZEXbqNqru5fc/' manifest/oauth.env

# Creamos el usuario
bash scripts/Y_USER.sh

# Mapeamos el rol al usuariobash
bash scripts/Z_USER_ROLE_MAPPING.sh


# cp oauth.env.example oauth.env
# vim oauth.env

kubectl create namespace ns-sidecar
kubectl -n ns-sidecar apply -f manifest/01_app_deployment_and_service.yml

# Using Config map
# kubectl -n ns-sidecar delete configmaps cm-oauth
# kubectl -n ns-sidecar create configmap cm-oauth --from-env-file=manifest/oauth.env

# Using Secrets
# kubectl -n ns-sidecar delete secret cm-oauth
kubectl -n ns-sidecar create secret generic cm-oauth --from-env-file=manifest/oauth.env

kubectl -n ns-sidecar apply -f manifest/02_oauth_deployment_and_service.yml
kubectl -n ns-sidecar apply -f manifest/03_ingress_combined.yml
kubectl -n ns-sidecar apply -f tmp/tls-k8sexample.yaml


# Validamos estado de los resources
kubectl -n ns-sidecar get all
kubectl -n ns-sidecar get configmap
kubectl -n ns-sidecar get ingress

# kubectl delete namespace ns-sidecar
```



