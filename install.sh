#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="nginx-vless-ws-proxy"
REPO_URL="https://github.com/you/nginx-vless-ws-proxy.git"
TARGET_DIR="${HOME}/${PROJECT_NAME}"

echo "==> Bootstrap install for ${PROJECT_NAME}"
echo

# Basic OS check
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script is intended for Linux only."
  exit 1
fi

# Check dependencies
need_install_docker=false
if ! command -v docker >/dev/null 2>&1; then
  need_install_docker=true
fi

if ! docker compose version >/dev/null 2>&1; then
  if ! command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose not found."
  fi
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Git is required. Please install git and rerun."
  exit 1
fi

# Optional Docker install
if [[ "$need_install_docker" == "true" ]]; then
  echo "Docker not found."
  read -r -p "Install Docker now? [y/N] " yn
  case "$yn" in
    [Yy]* )
      curl -fsSL https://get.docker.com | sh
      ;;
    * )
      echo "Skipping Docker install. Please install Docker and rerun."
      exit 1
      ;;
  esac
fi

# Clone repo
if [[ -d "$TARGET_DIR" ]]; then
  echo "Target directory already exists: $TARGET_DIR"
else
  git clone "$REPO_URL" "$TARGET_DIR"
fi

# Create .env from template
if [[ -f "$TARGET_DIR/.env.example" && ! -f "$TARGET_DIR/.env" ]]; then
  cp "$TARGET_DIR/.env.example" "$TARGET_DIR/.env"
  echo ".env created from template."
fi

echo
echo "✔ Environment check passed"
echo "✔ Project ready at: $TARGET_DIR"
echo "✔ .env created from template (if missing)"
echo
echo "Next steps:"
echo "  1. Edit .env and set DOMAIN, EMAIL, UUID"
echo "  2. Review docker-compose.yml"
echo "  3. Run: docker compose up -d"
