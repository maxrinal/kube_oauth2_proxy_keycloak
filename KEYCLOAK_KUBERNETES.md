# KEYCLOAK CHART

Asumiremos para el siguiente despliegue que tenemos una infra base desplegada con 
* kube_helmfile(cluster minikube+ metallb+nginx-lb + powerdns + externaldns)
* infra_cacert(Cacert + ca-middle + cert)

Se requieren por lo menos 4gb de ram para el nodo de kubernetes donde se desplegara keycloak

https://bitnami.com/stack/keycloak/helm

https://github.com/bitnami/charts/tree/master/bitnami/keycloak/#installing-the-chart



```yaml
helm repo add bitnami https://charts.bitnami.com/bitnami

helm search repo --max-col-width 400 -l bitnami/keycloak
# helm search repo --max-col-width 400 -l bitnami/keycloak | head -2


NAME            	CHART VERSION	APP VERSION	DESCRIPTION                                                                                                                                                                 
bitnami/keycloak	9.0.3        	18.0.0     	Keycloak is a high performance Java-based identity and access management solution. It lets developers add an authentication layer to their applications with minimum effort.


# helm pull --version 9.0.3 bitnami/keycloak -d /tmp
# tar xzvf /tmp/keycloak-9.0.3.tgz -C /tmp
helm show values bitnami/keycloak --version 9.0.3 > tmp/bitnami_keycloak_default.yaml

cat <<EOT | helm upgrade --install keycloak --namespace ns-keycloak --create-namespace --version 9.0.3 bitnami/keycloak \
--set auth.adminUser=keycloak \
--set auth.adminPassword=keycloak \
--set service.type=ClusterIP \
-f - 
ingress:
  enabled: true
  ingressClassName: nginx-lb
  annotations:
    externaldns: pdns
  hostname: idp.k8s.example.test
  tls: true
  extraTls:
  - hosts:
      - idp.k8s.example.test
    secretName: tls-k8sexample
EOT

# Creamos el tls certificate para el ingress
kubectl -n ns-keycloak apply -f tmp/tls-k8sexample.yaml


  # selfSigned: true
```




https://idp.k8s.example.test/realms/master/account/#/