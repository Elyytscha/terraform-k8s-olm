#!/usr/bin/env bash

# This script is for installing OLM from a GitHub release

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi


set -e

if [[ ${#@} -ne 1 ]]; then
    echo "Usage: $0 version"
    echo "* version: the github release version"
    exit 1
fi

release=$1
url=https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${release}
namespace=olm

kubectl create --kubeconfig ~/.kube/config -f ${url}/crds.yaml || kubectl replace --kubeconfig ~/.kube/config -f ${url}/crds.yaml
kubectl create --kubeconfig ~/.kube/config -f ${url}/olm.yaml || kubectl replace --kubeconfig ~/.kube/config -f ${url}/olm.yaml


# wait for deployments to be ready
kubectl --kubeconfig ~/.kube/config rollout status -w deployment/olm-operator --namespace="${namespace}"
kubectl --kubeconfig ~/.kube/config rollout status -w deployment/catalog-operator --namespace="${namespace}"

retries=50
until [[ $retries == 0 || $new_csv_phase == "Succeeded" ]]; do
    new_csv_phase=$(kubectl --kubeconfig ~/.kube/config get csv -n "${namespace}" packageserver -o jsonpath='{.status.phase}' 2>/dev/null || echo "Waiting for CSV to appear")
    if [[ $new_csv_phase != "$csv_phase" ]]; then
        csv_phase=$new_csv_phase
        echo "Package server phase: $csv_phase"
    fi
    sleep 10
    retries=$((retries - 1))
done

if [ $retries == 0 ]; then
    echo "CSV \"packageserver\" failed to reach phase succeeded"
    exit 1
fi

kubectl --kubeconfig ~/.kube/config rollout status -w deployment/packageserver --namespace="${namespace}"
