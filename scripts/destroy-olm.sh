#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

echo "CLUSTER_TYPE: ${CLUSTER_TYPE}"
if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  echo "Cluster version already had OLM: ${CLUSTER_VERSION}"
  exit 0
fi

kubectl --kubeconfig ~/.kube/config delete deployment -n olm --all
kubectl --kubeconfig ~/.kube/config delete namespace olm --wait=false
"${SCRIPT_DIR}/kill-kube-ns" olm
kubectl --kubeconfig ~/.kube/config delete namespace olm
exit 0
