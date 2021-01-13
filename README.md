# talkyard-k8s

k8s manifests for deployment of [Talkyard](https://www.talkyard.io/) forum software. 

The manifests within this repository are fairly minimal and does not include persistent storage, resource requests/limits, HA-configuration etc. The idea is that custom configurations can be done with [Tanka](https://tanka.dev) or [Kustomize](https://github.com/kubernetes-sigs/kustomize/).

For docker-compose install see official repository: [github.com/debiki/talkyard-prod-one](https://github.com/debiki/talkyard-prod-one)

Talkyard source repository: [github.com/debiki/talkyard](https://github.com/debiki/talkyard)

## How to deploy/quickstart

Two alternatives: 

1. With [Tanka](https://tanka.dev) and leverage this repository as a jsonnet library.
2. With [Kustomize](https://github.com/kubernetes-sigs/kustomize/) as a remote resource.

### 1. Tanka

**Pre-requisites:**

- k8s cluster with amd64 nodes
- kubectl installed and $KUBECONFIG configured with the cluster
- Tanka and Jsonnet Bundler installed. See [tanka.dev/install](https://tanka.dev/install)

**Install:**

1. Initialize a new Tanka project and import this repository as a library.
    
    ```shell
    mkdir talkyard && cd talkyard
    tk init
    jb install github.com/ChrisEke/talkyard-k8s/lib/talkyard
    ```
2. Custom configuration of the Talkyard deployment should be done in directory `environments/default` (or whichever environment that is preferred).
   
   **REQUIRED:** 
   - Talkyard-app expects configuration file [play-framework.conf](https://github.com/debiki/talkyard-prod-one/blob/master/conf/play-framework.conf) for custom configurations such as hostname, SMTP, user authentications etc. Place `play-framework.conf` in `environments/default` directory and update desired parameters.  
   - Update `main.jsonnet` to include play-framework.conf as a ConfigMap.
   - Update `spec.json` with k8s cluster endpoint and namespace
   - By default namespace "talkyard" is created. This can be changed in `main.jsonnet`.

  Examples from [environments/tanka-example](https://github.com/ChrisEke/talkyard-k8s/tree/main/environments/tanka-example)
   
  **environments/tanka-example/main.jsonnet:**
  
  ```jsonnet
  (import 'talkyard/talkyard.libsonnet')

  {
    app+: {
      // Includes play-framework.conf as a ConfigMap which Talkyard-app will mount as a config volume.
      playFrameworkConfigMap: $.core.v1.configMap.new('app-play-framework-conf')
                              + $.core.v1.configMap.withData({
                                'app-prod-override.conf': importstr 'play-framework.conf',
                              }),
    },
    _config+:: {
      namespace: 'my-namespace',
      app+:: {
        // Settings for Java heap size as well as many of the parameters in play-framework-conf
        // can be specified as environment variables
        env+:: {
          PLAY_HEAP_MEMORY_MB: '256',
          BECOME_OWNER_EMAIL_ADDRESS: 'example@example.com',
          TALKYARD_HOSTNAME: 'example.com',
        },
      },
      search+:: {
        env+:: {
          ES_JAVA_OPTS: '-Xms192m -Xmx192m',
        },
      },
    },
  }
  ```

  **environments/tanka-example/spec.jsonnet:**

  ```json
  {
    "apiVersion": "tanka.dev/v1alpha1",
    "kind": "Environment",
    "metadata": {
      "name": "environments/tanka-example"
    },
    "spec": {
      "apiServer": "https://my-k8s-cluster:6443",
      "namespace": "my-namespace",
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

### 2. Kustomize

**Pre-requisites:**

- k8s cluster with amd64 nodes
- kubectl installed and $KUBECONFIG configured with the cluster
- kustomize installed. See [kubectl.docs.kubernetes.io/installation/kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)

**Install:**

1. Create a project area
    
    ```shell
    mkdir talkyard && cd talkyard
    ```

2. Setup `kustomization.yaml`-file. Example configMapGenerator and secretGenerator has been included for mandatory configuration and secrets.
   
    ```shell
    cat << EOF > kustomization.yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: talkyard
    
    configMapGenerator:
    - name: app-play-framework-conf
      files:
      - app-prod-override.conf=play-framework.conf

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
3. Include file [play-framework.conf](https://github.com/debiki/talkyard-prod-one/blob/master/conf/play-framework.conf) in the project directory and update parameters to desired values.  
4. Apply to k8s cluster.
   
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

Port-forward of Talkyard web service on localhost with an unpriviliged port might result in a blank page. This is due to the $port being stripped from the request URL-header for additional site assets, which consequently leads to failure of loading said assets. 

A temporary fix is to modify the web pod, example: 

```shell
kubectl exec web-546846b96d-f7vfq -- \
  sed -i 's/proxy_set_header Host \$host/proxy_set_header Host \$http_host/' \
  /etc/nginx/server-locations.conf

kubectl exec web-546846b96d-f7vfq -- nginx -s reload
```
Changing nginx parameter $host to $http_host has some security implications. A better and more permanent solution is to apply an ingress object infront of the web service and configure it with a proper URL.
