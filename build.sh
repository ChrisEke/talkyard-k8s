#!/usr/bin/env bash
manifest_dir="manifests"
kustomize_base="kustomization.yaml"
kustomize_manifests="$manifest_dir/$kustomize_base"

rm -r $manifest_dir/ 
tk export environments/default $manifest_dir --format='{{.metadata.name}}-{{.kind}}'

echo "apiVersion: kustomize.config.k8s.io/v1beta1" | tee $kustomize_base $kustomize_manifests > /dev/null
echo "kind: Kustomization" | tee -a $kustomize_base $kustomize_manifests > /dev/null
echo "resources:" | tee -a $kustomize_base $kustomize_manifests > /dev/null

# use nullglob in case there are no matching files
shopt -s nullglob
# create an array with all the files inside dir ./manifests
manifest_files=($manifest_dir/*)

for f in "${manifest_files[@]}"; do
    f=$(basename $f)
    if [ ! $f == "kustomization.yaml" ]; then
        echo "- $f" | tee -a $kustomize_manifests > /dev/null
    fi
done

echo "- $manifest_dir" | tee -a $kustomize_base > /dev/null