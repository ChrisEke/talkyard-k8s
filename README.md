# talkyard-k8s

k8s manifests for deployment of [Talkyard](https://www.talkyard.io/) forum software. 

The manifests within this repository are fairly minimal and does not include persistent storage, resource requests/limits, HA-configuration etc. The idea is that custom configurations can be done with [Tanka](https://tanka.dev) or [Kustomize](https://github.com/kubernetes-sigs/kustomize/).


Talkyard source repo @ [github.com/debiki/talkyard](https://github.com/debiki/talkyard)

## How to deploy/quickstart

Two alternatives: 

1. With [Tanka](https://tanka.dev) and leverage this repository as a jsonnet library.
2. With [Kustomize](https://github.com/kubernetes-sigs/kustomize/).

### Tanka

**Pre-requisites:**

- k8s cluster with amd64 nodes
- kubectl installed and $KUBECONFIG configured with the cluster
- Tanka and Jsonnet Bundler installed. See [tanka.dev/install](https://tanka.dev/install)

**Install:**

1. Configure a tanka project and import this repository as a library.
    
    ```shell
    mkdir talkyard && cd talkyard
    tk init
    jb install github.com/ChrisEke/talkyard-k8s/lib/talkyard
    ```
2. In `environments/default` (or whichever environment that is preferred) update `main.jsonnet` and `spec.json`. Namespace **talkyard** is used by default.
   
   *example environments/default/main.jsonnet:*
  
    ```jsonnet
    (import 'talkyard/talkyard.libsonnet')

    {
      _config+:: {
        talkyard+:: {
          namespace+:: {
            name: 'talkyard',
          },
          app+:: {
            env+:: {
              PLAY_HEAP_MEMORY_MB: '256',
            },
          },
          search+:: {
            env+:: {
              ES_JAVA_OPTS: '-Xms192m -Xmx192m',
              'bootstrap.memory_lock': 'true',
            },
          },
        },
      },
    }
    ```
    *example environments/default/spec.jsonnet:*

    ```jsonnet
    {
      "apiVersion": "tanka.dev/v1alpha1",
      "kind": "Environment",
      "metadata": {
        "name": "environments/default"
      },
      "spec": {
        "apiServer": "https://my-k8s-cluster:6443",
        "namespace": "talkyard",
        "resourceDefaults": {},
        "expectVersions": {}
      }
    }
    ```

3. Apply to k8s cluster:
   
   ```shell
   tk apply environments/default
   ```

4. Add secrets `talkyard-app-secrets` and `talkyard-rdb-secrets`. Talkyard app and rdb will not be able to start without these being set. 
  
    ```shell
    kubectl create secret generic --namespace=talkyard talkyard-app-secrets --from-literal=play-secret-key='my-secret-key'
    kubectl create secret generic --namespace=talkyard talkyard-rdb-secrets --from-literal=postgres-password='my-postgres-password'
    ```

### Kustomize

**Pre-requisites:**

- k8s cluster with amd64 nodes
- kubectl installed and $KUBECONFIG configured with the cluster
- kustomize installed. See [kubectl.docs.kubernetes.io/installation/kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)

**Install:**

1. Create a project area
    
    ```shell
    mkdir talkyard && cd talkyard
    ```

2. Setup `kustomization.yaml`-file. secretGenerator for mandatory secrets has been included in example below.
   
    ```shell
    cat << EOF > kustomization.yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: talkyard

    secretGenerator:
      - name: talkyard-app-secrets
        literals:
          - play-secret-key='my-secret-key'

      - name: talkyard-rdb-secrets
        literals:
          - postgres-password='my-postgres-password'

    resources:
    - github.com/ChrisEke/talkyard-k8s
    EOF
    ```
3. Apply to k8s cluster.
   
    ```shell
    kustomize build . | kubectl apply -f -
    ```

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

## Verifying deployment on localhost

Port-forwarding Talkyard web service on localhost with an unpriviliged port might result in a blank page. This is due to the $port being stripped from the request URL-header when requesting additional site assets. To temporarily fix this a minor modification can be done to the web pod: 

```shell
kubectl exec web-546846b96d-f7vfq -- \
  sed -i 's/proxy_set_header Host \$host/proxy_set_header Host \$http_host/' \
  /etc/nginx/server-locations.conf

kubectl exec web-546846b96d-f7vfq -- nginx -s reload
```
Changing nginx parameter $host to $http_host has some security implications. A better and more permanent solution is to apply an ingress object infront of the web service configured with a proper URL.
