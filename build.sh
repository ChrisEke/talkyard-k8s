#!/usr/bin/env bash
#rm -r manifests/ 
#tk export environments/default ./manifests --format='{{.metadata.name}}-{{.kind}}'

file1="manifests/kustomization.yaml"
file2="kustomization.yaml"

echo "apiVersion: kustomize.config.k8s.io/v1beta1" | tee $file1 $file2 > /dev/null
echo "kind: Kustomization" | tee -a $file1 $file2 > /dev/null
echo "resources:" | tee -a $file1 $file2 > /dev/null

# use nullglob in case there are no matching files
shopt -s nullglob
# create an array with all the filer/dir inside ~/myDir
files=(manifests/*)

for f in "${files[@]}"; do
    f=$(basename $f)
    echo "- $f" | tee -a $file1 > /dev/null
done

echo "- manifests" | tee -a $file2 > /dev/null