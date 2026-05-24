#!/bin/bash
# test-secret-apply.sh
# Run this locally. Never commit it.
# Fill in YOUR_TOKEN_HERE before running.

set -e

# Git credentials — used for API calls and clone
# Token needs: public_repo (poll) + admin:repo_hook (webhook auto-reg)
kubectl create secret generic kube-gitops-testing-secret \
  -n kube-deploy \
  --from-literal=username=centerionware \
  --from-literal=password=YOUR_TOKEN_HERE \
  --dry-run=client -o yaml | kubectl apply -f -

# Webhook HMAC secret — generate once, keep it, enter the same value
# in the GitHub webhook config if registering manually
kubectl create secret generic kube-gitops-testing-webhook-secret \
  -n kube-deploy \
  --from-literal=secret=$(openssl rand -hex 32) \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets applied."
echo ""
echo "If using webhook mode with auto-registration, EXTERNAL_URL must be"
echo "set in deploy.yaml and your token needs admin:repo_hook scope."
echo ""
echo "If registering the webhook manually, get the URL with:"
echo "  kubectl get gr kube-gitops-testing-webhook -n kube-deploy"
