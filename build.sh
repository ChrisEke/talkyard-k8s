#!/usr/bin/env bash
rm -r manifests/ 
tk export environments/default ./manifests --format='{{.metadata.name}}-{{.kind}}'

file="./kustomization.yaml"

echo "apiVersion: kustomize.config.k8s.io/v1beta1" > $file
echo "kind: Kustomization" >> $file
echo "resources:" >> $file

# use nullglob in case there are no matching files
shopt -s nullglob
# create an array with all the filer/dir inside ~/myDir
arr=(manifests/*)
# iterate through array using a counter
for ((i=0; i<${#arr[@]}; i++)); do
    #do something to each element of array
    echo "- ${arr[$i]}" >> $file
done