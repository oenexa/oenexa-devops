# OENEXA DevOps (`oenexa-devops`)

> **Enterprise GitOps, Kubernetes Platform Engineering & Deployment Governance Repository**  
> Governed by the OENEXA Platform Engineering & Site Reliability Engineering (SRE) Organizations.

## 1. Golden Engineering Rule: Pure GitOps
**All production and non-production Kubernetes states are declared here.**
- ❌ **Zero Manual Deployments**: `kubectl apply`, `helm install`, or manual SSH modifications on live clusters are **strictly prohibited** and blocked via admission controllers.
- ❌ **Zero Cloud Console Edits**: Any manual drift is automatically wiped and corrected by ArgoCD automated reconciliation.
- ✅ **The Git Commit is the Release**: All changes require a Pull Request, automated CI linting/testing, policy evaluation, peer review, and merge to `main`.

---

## 2. Environment Promotion Model

```text
Feature Branch -> Pull Request -> Automated Validation (OPA/Lint) -> Peer Review
  │
  ▼
dev (Continuous deployment upon merge to main)
  │
  ├──► Automated Integration & Smoke Tests Passed
  ▼
staging (Canary verification & compliance audit)
  │
  ├──► SRE & Security Sign-off (Git Tag / Release Branch)
  ▼
prod (ArgoCD automated sync with progressive rollouts & automated rollback)
```

---

## 3. Directory Layout

```text
oenexa-devops/
├── argocd/
│   ├── root-application.yaml         # App-of-Apps Master Controller
│   ├── project.yaml                  # AppProject governance (destinations, repos)
│   └── applications/                 # Individual microservice ArgoCD Applications
├── helm/
│   └── oenexa-service/               # Enterprise golden chart for all stateless services
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── environments/
│   ├── dev/values.yaml
│   ├── staging/values.yaml
│   └── prod/values.yaml
├── observability/
│   ├── prometheus-rules/slos.yaml    # SLO multi-window burn-rate alerts
│   └── grafana-dashboards/
└── policies/
    └── deployment-governance.md      # Mandated operational policies
```
