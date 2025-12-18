#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../web/bechde-web"
if command -v nvm >/dev/null 2>&1; then
    nvm use 20 >/dev/null 2>&1 || { nvm install 20 && nvm use 20; }
fi
npm ci
npm run dev:ssr
