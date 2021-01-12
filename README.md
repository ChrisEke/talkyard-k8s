# talkyard-k8s
## How to deploy

Two alternatives: 

### Tanka
1. mkdir talkyard && cd talkyard
2. tk init
3. Update main.jsonett and spec.json in environments/default (or whichever environment that is preffered) 
4. Add secrets 
5. tk apply environment/default


## Running in mixed amd64/arm cluster
Add nodeSelector to deployments: 

**Kustomize**: 

Create a patch file: 

```shell
cat << EOF > patch-nodeSelector.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: Whatever
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
EOF
```
Reference it in kustomization.yaml: 

``` yaml
patches:
  - path: patch-nodeSelector.yaml
    target: 
      kind: Deployment
```

## Localhost

```shell
kubectl exec web-546846b96d-f7vfq -- sed -i 's/proxy_set_header Host \$host/proxy_set_header Host \$http_host/' /etc/nginx/server-locations.conf 

kubectl exec web-546846b96d-f7vfq -- nginx -s reload
```
## Todo

- add nodeselectors - **Done** - see example above
- fix statefulset pvc - **Done** changed to deployment 
- version script - **Done**
- Check if easy way to demo with localhost port-forward - **Done**
- Write up deployment with Tanka and kustomize - *In progress*