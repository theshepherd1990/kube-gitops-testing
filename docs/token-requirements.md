# Token Requirements by Platform and Method

This document covers exactly which permissions your personal access token needs
depending on your platform and trigger mode. Nothing more than what is listed
is required.

**Important:** Comments posted to PRs and commit statuses are authenticated API
calls — they are not open. The platform requires a valid token with write
access to accept them. Without it the API returns 403. The same token you use
for reading PRs covers this as long as it has write scope on the repository.

---

## GitHub

### Poll mode

| Scope | Why |
|---|---|
| `public_repo` (public repos) or `repo` (private repos) | List open pull requests via REST API |

No write access needed for poll mode alone.

### Webhook auto-registration

| Scope | Why |
|---|---|
| `public_repo` or `repo` | Read pull request data |
| `admin:repo_hook` | Create and delete webhooks on the repository via API |

Without `admin:repo_hook` the operator cannot register the webhook
automatically. You can omit it and register the webhook manually — the operator
will still validate and handle incoming payloads. See the webhook quickstart
for manual registration steps.

### PR comments and commit statuses

| Scope | Why |
|---|---|
| `repo` | Write comments to issues/PRs and post commit statuses |

`public_repo` does **not** include write access. Even for a public repository,
posting comments and commit statuses requires the full `repo` scope. GitHub
enforces this — a `public_repo` token will receive 403 on write endpoints.

### Recommended scope combinations

| Use case | Scopes |
|---|---|
| Poll, no notifications | `public_repo` or `repo` |
| Poll + notifications | `repo` |
| Webhook (manual reg) + notifications | `repo` |
| Webhook (auto-reg) + notifications | `repo` + `admin:repo_hook` |

### Creating a token

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Select the scopes for your use case from the table above
4. Copy the token immediately — GitHub will not show it again

---

## GitLab

### Poll mode

| Scope | Why |
|---|---|
| `read_api` | List open merge requests |

### Webhook auto-registration

| Scope | Why |
|---|---|
| `api` | Create and delete project webhooks |

GitLab does not offer a narrower scope for webhook management. `api` grants
full API access. If you register the webhook manually, `read_api` is enough
for poll mode — but see notifications below.

### PR comments and commit statuses

| Scope | Why |
|---|---|
| `api` | Post notes (comments) on merge requests and set commit statuses |

`read_api` is read-only and will 403 on any write operation. If you want
notifications you need `api` regardless of trigger mode.

### Recommended scope combinations

| Use case | Scopes |
|---|---|
| Poll, no notifications | `read_api` |
| Poll + notifications | `api` |
| Webhook (manual reg) + notifications | `api` |
| Webhook (auto-reg) + notifications | `api` |

For GitLab, `api` covers everything. Use `read_api` only if you explicitly do
not want the operator posting comments or statuses.

### Creating a token

1. GitLab → User Settings → Access Tokens
2. Add a new token
3. Select the scopes above
4. Set an expiry (GitLab requires one — set it as far out as your policy allows)
5. Copy the token

---

## Gitea / Forgejo

Gitea and Forgejo use the same API and token model. Permission names may vary
slightly across versions but the concepts are identical.

### Poll mode

| Permission | Level |
|---|---|
| Repository | Read |

### Webhook auto-registration

| Permission | Level |
|---|---|
| Repository | Read |
| Webhooks | Read and Write |

Without Webhooks write permission the operator cannot create or delete webhooks
via the API. Register manually if you want to avoid granting this.

### PR comments and commit statuses

| Permission | Level |
|---|---|
| Repository | Read and Write |
| Issue | Read and Write |

Gitea separates repository and issue permissions. Comments on pull requests go
through the issue API — you need issue write access in addition to repository
write access. Without it the operator will receive 403 when posting comments.
Commit statuses require repository write access.

### Recommended permission combinations

| Use case | Permissions |
|---|---|
| Poll, no notifications | Repository: Read |
| Poll + notifications | Repository: R/W, Issue: R/W |
| Webhook (manual reg) + notifications | Repository: R/W, Issue: R/W |
| Webhook (auto-reg) + notifications | Repository: R/W, Issue: R/W, Webhooks: R/W |

### Creating a token

1. Gitea/Forgejo → User Settings → Applications → Manage Access Tokens
2. Give the token a name
3. Select the permissions from the table above
4. Generate and copy the token

---

## Summary table

| Platform | Poll only | + Notifications | + Webhook auto-reg |
|---|---|---|---|
| GitHub | `public_repo`/`repo` | `repo` | + `admin:repo_hook` |
| GitLab | `read_api` | `api` | `api` (already covers it) |
| Gitea/Forgejo | Repo: Read | + Repo: R/W, Issue: R/W | + Webhooks: R/W |

---

## Secret format

The git secret format is the same across all platforms and methods:

```bash
kubectl create secret generic <name> \
  -n <namespace> \
  --from-literal=username=<your-username> \
  --from-literal=password=<your-token>
```

`username` is used by kube-deploy when cloning the PR branch over HTTPS.
`password` is the token used for all API calls by kube-gitops.

The secret name goes in `spec.gitSecret` on the `GitRepo` CR.

SSH keys (`ssh-privatekey`) can be used for clone-only scenarios but cannot
authenticate API calls. Poll mode and webhook auto-registration both require
an HTTPS token. If you configure SSH-only and enable poll mode, the operator
will log a clear error and skip polling.

---

## Webhook HMAC secret

The webhook secret is separate from your git credentials. It is not a platform
token — it is a random string you generate and configure on both sides so that
the operator can verify incoming webhook payloads are genuine.

```bash
kubectl create secret generic <name>-webhook-secret \
  -n <namespace> \
  --from-literal=secret=$(openssl rand -hex 32)
```

The secret name goes in `spec.trigger.webhookSecret` on the `GitRepo` CR.

Configure the same value on the platform:

- **GitHub:** Repository → Settings → Webhooks → Secret
- **GitLab:** Repository → Settings → Webhooks → Secret token
- **Gitea/Forgejo:** Repository → Settings → Webhooks → Secret

If using auto-registration the operator reads this secret from Kubernetes and
passes it to the platform API — you do not need to enter it manually anywhere.

The HMAC secret has nothing to do with authentication to the platform. It only
proves that a payload arriving at your webhook endpoint was sent by your platform
and not by someone else. Without it any HTTP client could fake a PR event.
