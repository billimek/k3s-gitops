#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)

if [[ -z "$DOMAIN" ]]; then
  echo ".env does not appear to be sourced, sourcing now"
  . "$REPO_ROOT"/setup/.env
fi

kseal() {
    name=$(basename -s .txt "$@")
    if [[ -z "$NS" ]]; then
      NS=default
    fi
    envsubst < "$@" > values.yaml | kubectl -n "$NS" create secret generic "$name" --from-file=values.yaml --dry-run -o json | kubeseal --format=yaml --cert="$REPO_ROOT/pub-cert.pem" && rm -f values.yaml
}

kapply() {
  # if [[ -z "$NS" ]]; then
  #   NS=default
  # fi
  # envsubst < "$@" | kubectl -n "$NS" apply -f -
  envsubst < "$@" | kubectl apply -f -
}

#########################
# manual subst and apply
#########################
kapply "$REPO_ROOT"/kube-system/cert-manager/cert-manager-letsencrypt.txt

##########
# secrets
##########
kubectl create secret generic fluxcloud --from-literal=slack_url="$SLACK_WEBHOOK_URL" --namespace flux --dry-run -o json | kubeseal --format=yaml --cert="$REPO_ROOT/pub-cert.pem" > "$REPO_ROOT/kube-system/fluxcloud/fluxcloud-secret.yaml"
kubectl create secret generic traefik-basic-auth-jeff --from-literal=auth="$JEFF_AUTH" --namespace kube-system --dry-run -o json | kubeseal --format=yaml --cert="$REPO_ROOT/pub-cert.pem" > "$REPO_ROOT/kube-system/traefik/traefik-basic-auth-jeff-kube-system.yaml"
kubectl create secret generic traefik-basic-auth-jeff --from-literal=auth="$JEFF_AUTH" --dry-run -o json | kubeseal --format=yaml --cert="$REPO_ROOT/pub-cert.pem" > "$REPO_ROOT/kube-system/traefik/traefik-basic-auth-jeff.yaml"
kubectl create secret generic cloudflare-api-key --from-literal=api-key="$CF_API_KEY" --namespace kube-system --dry-run -o json | kubeseal --format=yaml --cert="$REPO_ROOT/pub-cert.pem" > "$REPO_ROOT/kube-system/cert-manager/cert-manager-cloudflare-api-key.yaml"

####################
# helm chart values
####################
NS=kube-system kseal "$REPO_ROOT/kube-system/traefik/traefik-unsealed-helm-values.txt" > "$REPO_ROOT/kube-system/traefik/traefik-sealed-helm-values.yaml"
NS=kube-system kseal "$REPO_ROOT/kube-system/kured/kured-unsealed-helm-values.txt" > "$REPO_ROOT/kube-system/kured/kured-sealed-helm-values.yaml"
