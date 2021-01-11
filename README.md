# talkyard-k8s

1. tk init
2. rm -r manifests/; tk export environments/default ./manifests --format='{{.metadata.name}}-{{.kind}}'

## Todo

- add nodeselectors
- fix statefulset pvc 
- version script