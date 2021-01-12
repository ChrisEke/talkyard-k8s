#!/usr/bin/env bash
talkyard_version_url="https://raw.githubusercontent.com/debiki/talkyard-versions/master/version-tags.log"
talkyard_version_output="lib/talkyard/talkyard-version.libsonnet"
manifest_dir="manifests"
kustomize_base="kustomization.yaml"
kustomize_manifests="$manifest_dir/$kustomize_base"

# Get latest Talkyard version
latest_version=$(curl -S --silent $talkyard_version_url | grep -v -e "WIP\|^$" | tail -1)
echo "{ _version+:: { talkyard+:: { version: '"$latest_version"' } } }" > $talkyard_version_output

## Start clean by removing old manifests
rm -r $manifest_dir/

## Leverage tanka export function to generate yaml manifests
tk export environments/default $manifest_dir --format='{{.metadata.name}}-{{.kind}}'

## Generate Kustomization manifests
echo "apiVersion: kustomize.config.k8s.io/v1beta1" | tee $kustomize_base $kustomize_manifests > /dev/null
echo "kind: Kustomization" | tee -a $kustomize_base $kustomize_manifests > /dev/null
echo "resources:" | tee -a $kustomize_base $kustomize_manifests > /dev/null

shopt -s nullglob
manifest_files=($manifest_dir/*)

for f in "${manifest_files[@]}"; do
    f=$(basename $f)
    if [ ! $f == "kustomization.yaml" ]; then
        echo "- $f" | tee -a $kustomize_manifests > /dev/null
    fi
done

echo "- $manifest_dir" | tee -a $kustomize_base > /dev/null
