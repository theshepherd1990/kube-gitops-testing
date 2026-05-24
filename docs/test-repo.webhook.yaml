# ============================================================
# Test GitRepo â€” webhook mode
# Requires: kube-gitops-testing-secret (see test-secret-apply.sh)
#           kube-gitops-testing-webhook-secret (see below)
# Commit this file. It has no secrets in it.
# ============================================================
apiVersion: kube-gitops.centerionware.app/v1alpha1
kind: GitRepo
metadata:
  name: kube-gitops-testing-webhook
  namespace: kube-deploy
spec:
  platform: github
  repo: https://github.com/centerionware/kube-gitops-testing
  gitSecret: kube-gitops-testing-secret

  trigger:
    mode: webhook
    webhookSecret: kube-gitops-testing-webhook-secret

  prPolicy:
    allowedAuthorAssociations:
      - OWNER
      - MEMBER
      - COLLABORATOR
      - CONTRIBUTOR
      - FIRST_TIME_CONTRIBUTOR

  notify:
    onDeploy: true
    onError: true
    onClose: false
    deployTemplate: |
      ðŸš€ Preview deployed: {{.URL}}

      Branch: `{{.Branch}}`
      Commit: `{{.SHA}}`
    errorTemplate: |
      âŒ Preview deployment failed for `{{.Branch}}`: {{.Error}}

  prDeploy:
    namespace: kube-gitops-testing-previews
    baseDomain: centerionware.com
    ingressHostTemplate: "kube-gitops-testing-pr-{{.PRNumber}}.centerionware.com"
    injectPREnv: true

    ingress:
      enabled: true
      className: cloudflare-tunnel

    run:
      port: 3000
      replicas: 1
