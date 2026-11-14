# OENEXA Deployment Governance & Operational Rules

## Rule 1: Declarative Pure GitOps
1. Every microservice, ingress route, horizontal pod autoscaler, network policy, and secret reference must be committed to this repository.
2. Direct execution of mutating commands (`kubectl create`, `kubectl delete`, `kubectl patch`, `helm upgrade`) against production clusters will be flagged as an **SEV-1 Security Incident**.

## Rule 2: Immutable Container Images
1. Tags like `latest`, `dev`, or `master` are strictly rejected by Gatekeeper admission controllers.
2. Every deployed image must reference a semantic version tag pinned to an immutable cryptographic digest (`sha256:...`).

## Rule 3: Zero-Trust Pod Security
1. All pods must run as non-root (`runAsNonRoot: true`).
2. Root filesystems must be mounted read-only (`readOnlyRootFilesystem: true`). Ephemeral storage must use emptyDir volumes.
3. Linux capabilities must drop `ALL` with no privileged containers permitted.
4. Default-deny NetworkPolicies must be present in every namespace.

## Rule 4: Mandatory Production Telemetry
Before any service can be promoted to staging or production, it must have:
1. Health Probes: `livenessProbe`, `readinessProbe`, and `startupProbe` configured.
2. Resource Requests and Limits: Memory and CPU must be explicitly declared; unbounded pods are forbidden.
3. Pod Disruption Budget: `minAvailable: 1` or `maxUnavailable: 25%`.
4. High Availability: Minimum 2 replicas across distinct availability zones via `topologySpreadConstraints`.
