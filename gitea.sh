#!/usr/bin/env bash

CLUSTER_ID=af-cdevents-dff43bc8701fcd5837d6de963718ad39-0000
DOMAIN=${CLUSTER_ID}.eu-gb.containers.appdomain.cloud

# Create values file
cat <<EOF > gitea-values.yaml
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 100m
  hosts:
    - host: git.${DOMAIN}
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
      - git.${DOMAIN}
      secretName: ${CLUSTER_ID}

gitea:
  config:
    webhook:
      ALLOWED_HOST_LIST: '*'
EOF

# Install Gitea
helm repo add gitea-charts https://dl.gitea.io/charts/
helm repo update
helm upgrade --install gitea gitea-charts/gitea -f gitea-values.yaml
