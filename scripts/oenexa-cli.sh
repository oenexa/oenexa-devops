#!/usr/bin/env bash
# ==============================================================================
# OENEXA Master Unified Developer CLI & Orchestrator Tool (Linux / macOS)
# ==============================================================================

set -e
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(cd "$ROOT_DIR/../compose" && pwd)"
COMMAND="${1:-help}"
TARGET="${2:-all}"

echo -e "\033[0;36m=================================================================\033[0m"
echo -e "\033[0;32m       OENEXA UNIFIED ECOSYSTEM MASTER ORCHESTRATOR CLI          \033[0m"
echo -e "\033[0;36m=================================================================\033[0m"

case "$COMMAND" in
    up)
        PROFILE="${TARGET:-all}"
        echo -e "\033[0;33mStarting ecosystem containers with profile: [$PROFILE]...\033[0m"
        docker compose -f "$COMPOSE_DIR/docker-compose.yml" --profile "$PROFILE" up -d --build
        echo -e "\033[0;32m✓ Services launched successfully! Run './oenexa-cli.sh routes' to view endpoints.\033[0m"
        ;;
    down)
        echo -e "\033[0;33mStopping all ecosystem containers cleanly...\033[0m"
        docker compose -f "$COMPOSE_DIR/docker-compose.yml" down
        echo -e "\033[0;32m✓ All containers stopped.\033[0m"
        ;;
    ps)
        docker compose -f "$COMPOSE_DIR/docker-compose.yml" ps
        ;;
    routes)
        cat << "EOF"
🌐 OENEXA Unified Single-Domain Routing Table (http://localhost or https://oenexa.com):
-----------------------------------------------------------------
  🏠 Main Portal, Markets & Trading UI : http://localhost/           (oenexa-ui:80)
  ⚡ AI Operating System Studio Cockpit : http://localhost/ai/       (oenexa-ai-web:80)
  🧠 AI Core Central Intelligence API  : http://localhost/api/v4/    (oenexa-ai-core:8080)
  🔍 L1 Post-Quantum Block Explorer    : http://localhost/explorer/  (oenexa-explorer:80)
  ⛓️ Layer-1 Blockchain Node JSON-RPC   : http://localhost/rpc        (oenexa-node:8545)
  🍔 D-Commerce Food Storefront        : http://localhost/food/      (oengo-web:3000)
  💳 Escrow Relayer & Banking API      : http://localhost/oengo-api/ (oengo-api:3001)
-----------------------------------------------------------------
EOF
        ;;
    logs)
        if [ "$TARGET" != "all" ]; then
            docker compose logs -f "$TARGET"
        else
            docker compose logs -f --tail=50
        fi
        ;;
    deploy)
        if [ -z "$TARGET" ] || [ "$TARGET" == "all" ]; then
            echo -e "\033[0;31mError: You must specify an exact service to deploy independently!\033[0m"
            echo -e "\033[0;33mExample: ./oenexa-cli.sh deploy oenexa-ai-web\033[0m"
            echo -e "\033[0;36mServices: oenexa-ai-web, oenexa-ai-core, oenexa-node, oenexa-explorer, oenexa-ui, oengo-api, oengo-web, caddy\033[0m"
            exit 1
        fi
        ENV_MODE="${3:-prod}"
        COMPOSE_FILE="$COMPOSE_DIR/docker-compose.prod.yml"
        if [ "$ENV_MODE" == "dev" ]; then
            COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
        fi
        echo -e "\033[0;33mIndependent Zero-Downtime Deployment for [$TARGET] ($ENV_MODE)...\033[0m"
        echo -e "\033[0;36mStep 1: Rebuilding image for [$TARGET]...\033[0m"
        docker compose -f "$COMPOSE_FILE" build "$TARGET"
        echo -e "\033[0;36mStep 2: Performing hot-swap with --no-deps (zero disruption to other services)...\033[0m"
        docker compose -f "$COMPOSE_FILE" up -d --no-deps "$TARGET"
        echo -e "\033[0;32m✓ [$TARGET] successfully updated and redeployed!\033[0m"
        docker compose -f "$COMPOSE_FILE" ps "$TARGET"
        ;;
    audit)
        echo -e "\033[0;33mRunning ecosystem architectural & governance audit...\033[0m"
        bash "$SCRIPT_DIR/verify-governance.sh"
        ;;
    *)
        cat << "EOF"
Available Commands:
  ./oenexa-cli.sh up [profile]           Launch containers (profiles: ai, blockchain, portal, commerce, all)
  ./oenexa-cli.sh down                   Stop all containers
  ./oenexa-cli.sh ps                     View running container status and ports
  ./oenexa-cli.sh deploy <service> [env] Independently build and hot-swap a single service (--no-deps)
  ./oenexa-cli.sh routes                 Display single-domain path routing map
  ./oenexa-cli.sh audit                  Verify compliance with the 8 Inviolable Architectural Laws
  ./oenexa-cli.sh logs [service]         Follow container logs in real time
EOF
        ;;
esac
