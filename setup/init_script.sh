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
vault kv put secrets/flux/fluxcloud slack_url="$SLACK_WEBHOOK_URL"
vault kv put secrets/kube-system/traefik-basic-auth-jeff auth="$JEFF_AUTH"
vault kv put secrets/kube-system/cloudflare-api-key api-key="$CF_API_KEY"

####################
# helm chart values
####################
NS=kube-system kseal "$REPO_ROOT/kube-system/traefik/traefik-helm-values.txt" > "$REPO_ROOT/kube-system/traefik/traefik-helm-values.yaml"
NS=kube-system kseal "$REPO_ROOT/kube-system/kured/kured-helm-values.txt" > "$REPO_ROOT/kube-system/kured/kured-helm-values.yaml"

NS=monitoring kseal "$REPO_ROOT/monitoring/chronograf/chronograf-helm-values.txt" > "$REPO_ROOT/monitoring/chronograf/chronograf-helm-values.yaml"
NS=monitoring kseal "$REPO_ROOT/monitoring/prometheus-operator/prometheus-operator-helm-values.txt" > "$REPO_ROOT/monitoring/prometheus-operator/prometheus-operator-helm-values.yaml"
NS=monitoring kseal "$REPO_ROOT/monitoring/comcast/comcast-helm-values.txt" > "$REPO_ROOT/monitoring/comcast/comcast-helm-values.yaml"
NS=monitoring kseal "$REPO_ROOT/monitoring/uptimerobot/uptimerobot-helm-values.txt" > "$REPO_ROOT/monitoring/uptimerobot/uptimerobot-helm-values.yaml"
