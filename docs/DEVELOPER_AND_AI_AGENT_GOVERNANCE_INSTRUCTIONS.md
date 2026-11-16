# OENEXA Developer & AI Agent Operations Manual
**Target Audience:** DevOps Engineers, Full-Stack Developers, Autonomous AI Agents  
**Authority:** Master Ecosystem Operations Standard  

---

## 1. Quick Reference: CLI Tooling & Workflows

All operations across the 30 polyrepos are driven by the unified CLI located in `oenexa-devops/scripts/`:

```powershell
# Windows PowerShell
& ".\oenexa-devops\scripts\oenexa-cli.ps1" status       # Git status across all 30 repos
& ".\oenexa-devops\scripts\oenexa-cli.ps1" sync         # Push commits to origin & server
& ".\oenexa-devops\scripts\oenexa-cli.ps1" up ai        # Start AI stack (Core, Web, isolated Postgres & Redis)
& ".\oenexa-devops\scripts\oenexa-cli.ps1" deploy <svc> # Zero-downtime hot-swap of single container (--no-deps)
```

```bash
# Linux / macOS / VPS (/opt/oenexa)
./oenexa-devops/scripts/oenexa-cli.sh status
./oenexa-devops/scripts/oenexa-cli.sh sync
./oenexa-devops/scripts/oenexa-cli.sh deploy oenexa-ai-web
```

---

## 2. Inviolable Operational Directives for AI Agents

1. **Never create root files in `oenexarepo`:** All new scripts, compose templates, or documentation must be committed inside the appropriate repository (`oenexa-devops`, `oenexa-infra`, `oenexa-docs`, or domain repos).
2. **Never share databases between services:** Always define separate database containers, credentials, and volumes.
3. **Never introduce relative file dependencies:** When adding dependencies in `package.json`, never use `file:../`.
4. **Never bypass API boundaries:** Inter-service data retrieval must use HTTP REST or JSON-RPC.
5. **Always test with Zero-Mocks:** Verify tests against real business records before committing.
6. **Always verify dual remotes:** Check that `origin` and `server` are in sync before concluding a development cycle.
