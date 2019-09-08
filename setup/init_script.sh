#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)

if [[ -z "$DOMAIN" ]]; then
  echo ".env does not appear to be sourced, sourcing now"
  . "$REPO_ROOT"/setup/.env
fi

kvault() {
  name="secrets/$(dirname "$@")/$(basename -s .txt "$@")"
  if output=$(envsubst < "$REPO_ROOT/$*"); then
    printf '%s' "$output" | vault kv put "$name" values.yaml=-
  fi
}

kapply() {
  if output=$(envsubst < "$@"); then
    printf '%s' "$output" | kubectl apply -f -
  fi
}

#########################
# manual subst and apply
#########################
kapply "$REPO_ROOT"/kube-system/cert-manager/cert-manager-letsencrypt.txt

##########
# secrets
##########
kubectl create secret generic vault --from-literal=vault-unwrap-token="$VAULT_UNSEAL_TOKEN" --namespace kube-system

vault kv put secrets/flux/fluxcloud slack_url="$SLACK_WEBHOOK_URL"
vault kv put secrets/kube-system/traefik-basic-auth-jeff auth="$JEFF_AUTH"
vault kv put secrets/kube-system/cloudflare-api-key api-key="$CF_API_KEY"

####################
# helm chart values
####################
kvault "kube-system/traefik/traefik-helm-values.txt"
kvault "kube-system/kured/kured-helm-values.txt"
kvault "monitoring/chronograf/chronograf-helm-values.txt"
kvault "monitoring/prometheus-operator/prometheus-operator-helm-values.txt"
kvault "monitoring/comcast/comcast-helm-values.txt"
kvault "monitoring/uptimerobot/uptimerobot-helm-values.txt"
kvault "default/rabbitmq/rabbitmq-helm-values.txt"
kvault "default/node-red/node-red-helm-values.txt"
kvault "default/home-assistant/home-assistant-helm-values.txt"
kvault "default/home-assistant/hass-postgresql-helm-values.txt"
kvault "default/plex/plex-helm-values.txt"
kvault "default/pihole/pihole-helm-values.txt"
