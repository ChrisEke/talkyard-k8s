# talkyard-k8s

1. tk init
2. rm -r manifests/; tk export environments/default ./manifests --format='{{.metadata.name}}-{{.kind}}'


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

## Todo

- add nodeselectors - Done - see example above
- fix statefulset pvc - Done changed to deployment 
- version script - Done
- Check if easy way to demo with localhost port-forward