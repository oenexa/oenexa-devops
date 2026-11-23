# OENEXA Multi-Container Ecosystem Architecture 🐳

> **Developer Architecture Note: Why & How We Run Separate Orchestrated Containers**

---

## 1. Visual Topology & Network Architecture

```
                             [ HOST / PUBLIC INTERNET ]
                                          │
            ┌─────────────────────────────┼─────────────────────────────┐
            │                             │                             │
    :8080 (REST / MCP)            :5173 (Web UI)                :8545 / :8765 (P2P)
            ▼                             ▼                             ▼
   ┌───────────────────┐         ┌───────────────────┐         ┌───────────────────┐
   │  oenexa-ai-core   │◄────────┤   oenexa-ai-web   │         │    oenexa-node    │
   │ (Temurin 25 JRE   │  /api   │  (React 18 / Nginx│         │   (Pure L1 Go     │
   │   ~140 MB)        │         │      ~25 MB)      │         │      ~35 MB)      │
   └─────────┬─────────┘         └───────────────────┘         └─────────▲─────────┘
             │                                                           │
             │ :5432 / :6379                                             │ :8545 (Internal RPC)
             ▼                                                           │
   ┌───────────────────┐         ┌───────────────────┐         ┌─────────┴─────────┐
   │ Postgres & Redis  │         │    oenexa-pay     │         │  oenexa-exchange  │
   │ (Persistence &    │         │ (ISO 20022 Engine │────────►│ (Institutional FIX│
   │  NVMe Context)    │         │     ~45 MB)       │  :8082  │     ~45 MB)       │
   └───────────────────┘         └───────────────────┘         └───────────────────┘
                                           │
                    ═══════════════════════════════════════════
                          INTERNAL NETWORK: oenexa-network
                              (Isolated Bridge DNS)
```

---

## 2. Why: Multi-Container vs. Single Monolithic Container

| Requirement | ❌ Single "Fat" Container (Anti-Pattern) | ✅ Multi-Container (Professional Standard) |
| :--- | :--- | :--- |
| **Security Blast Radius** | Compromised web app exposes AI keys, database credentials, & RAM. | **Complete Isolation**: Web UI has zero access to backend filesystem or database containers. |
| **Crash Resilience** | A memory leak or uncaught exception takes down the entire ecosystem. | **Self-Healing**: Docker restarts only the crashed service; consensus and AI engines remain online. |
| **Horizontal Scaling** | Cannot scale AI web UI without duplicating heavy backend JVM processes. | **Independent Scaling**: Scale `oenexa-ai-web` to 10 instances while running 1 backend cluster. |
| **Image Footprint** | Multi-gigabyte monolithic image (slow CI/CD & deployment). | **Lightweight Micro-Images** (Go: 35MB, Nginx: 25MB, Temurin 25: 140MB, Next.js: 120MB). |
| **Cloud Portability** | Incompatible with Kubernetes / microservices architectures. | **Cloud-Native**: Directly maps to Kubernetes Pods, Deployments, and Helm charts. |

---

## 3. How: Port Mapping & Internal Service Discovery

Inside the private `oenexa-network`, services communicate using **Docker automatic DNS** (Service Names):

```
┌───────────────────┬───────────────────┬───────────────────────────────┬───────────────────────┐
│ Service           │ Internal DNS      │ Internal Port                 │ Exposed Host Port     │
├───────────────────┼───────────────────┼───────────────────────────────┼───────────────────────┤
│ oenexa-ai-core    │ oenexa-ai-core    │ :8080 (REST / MCP / SSE)      │ 8080                  │
│ oenexa-ai-web     │ oenexa-ai-web     │ :80 (Nginx SPA + /api proxy)  │ 5173                  │
│ oenexa-node       │ oenexa-node       │ :8545 (RPC), :8765, :9090     │ 8545, 8765, 9090      │
│ oenexa-explorer   │ oenexa-explorer   │ :80                           │ 5174                  │
│ oenexa-pay        │ oenexa-pay        │ :8086                         │ 8086                  │
│ oenexa-exchange   │ oenexa-exchange   │ :8082                         │ 8082                  │
│ postgres          │ oenexa-postgres   │ :5432                         │ 5432                  │
│ redis             │ oenexa-redis      │ :6379                         │ 6379                  │
└───────────────────┴───────────────────┴───────────────────────────────┴───────────────────────┘
```

* **`oenexa-ai-web` ➡️ `oenexa-ai-core`**: Proxies `/api/*` to `http://oenexa-ai-core:8080`
* **`oenexa-pay` ➡️ `oenexa-node`**: Connects via `http://oenexa-node:8545`
* **`oenexa-exchange` ➡️ `oenexa-pay`**: Settles trades via `http://oenexa-pay:8086`
* **`oenexa-explorer` ➡️ `oenexa-node`**: Queries `http://oenexa-node:8545`

---

## 4. Single-Command Developer Operations

Run all commands from `C:\workspace\oenexarepo`:

### 🚀 Start AI Platform Containers
```bash
# In oenexa-ai-core
./docker-runner.sh up

# On Windows PowerShell
cd oenexa-ai-core
.\docker-runner.ps1 up
```

### 📊 Check Health & Status Across Ecosystem
```bash
docker compose ps
```

### 📜 Follow Live Logs
```bash
# Stream AI Core backend logs
docker compose logs -f oenexa-ai-core

# Stream AI Web frontend logs
docker compose logs -f oenexa-ai-web
```

### 🛑 Stop Everything
```bash
docker compose down
```
