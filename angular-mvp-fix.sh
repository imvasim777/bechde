#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
REPO_ROOT="$(pwd)"
WEB_DIR="web/bechde-web"

# --- Pre-flight Checks ---
if [ ! -d "$WEB_DIR" ]; then
    echo "❌ Error: Directory $WEB_DIR not found."
    echo "   Please run this script from the root of the repository."
    exit 1
fi

echo "🔧 applying Angular SSR Fixes: Hybrid Rendering + Zone.js..."

cd "$WEB_DIR"

# --- 1. Configure Hybrid Rendering (Server vs Prerender) ---
echo "--- Step 1: Configuring app.routes.server.ts ---"
# This tells Angular which routes to Prerender (static) vs Server (dynamic)
mkdir -p src/app
cat > src/app/app.routes.server.ts <<EOF
import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  { path: '', renderMode: RenderMode.Prerender },
  { path: 'listings', renderMode: RenderMode.Prerender },
  { path: 'listings/:id', renderMode: RenderMode.Server }, # Dynamic -> SSR
  { path: 'sell', renderMode: RenderMode.Server },         # Auth required -> SSR
  { path: '**', renderMode: RenderMode.Server }            # Fallback -> SSR
];
EOF

# --- 2. Install Zone.js (Required for stable hydration) ---
echo "--- Step 2: Installing Zone.js ---"
# Installing the specific version compatible with Angular 20
npm install zone.js@~0.15.0 --save

# --- 3. Update Entry Files to Import Zone.js ---
echo "--- Step 3: Importing Zone.js in entry files ---"

# Fix src/main.ts (Browser)
MAIN_TS="src/main.ts"
if ! grep -q "import 'zone.js';" "$MAIN_TS"; then
    # Create temp file with import at top, then append original content
    echo "import 'zone.js';" | cat - "$MAIN_TS" > "${MAIN_TS}.tmp" && mv "${MAIN_TS}.tmp" "$MAIN_TS"
    echo "   Added zone.js import to main.ts"
fi

# Fix src/main.server.ts (Server)
MAIN_SERVER_TS="src/main.server.ts"
if ! grep -q "import 'zone.js/node';" "$MAIN_SERVER_TS"; then
    echo "import 'zone.js/node';" | cat - "$MAIN_SERVER_TS" > "${MAIN_SERVER_TS}.tmp" && mv "${MAIN_SERVER_TS}.tmp" "$MAIN_SERVER_TS"
    echo "   Added zone.js/node import to main.server.ts"
fi

# --- 4. Update App Config (Remove Zoneless Provider) ---
echo "--- Step 4: Updating app.config.ts ---"
# Reverting to standard provider configuration
cat > src/app/app.config.ts <<EOF
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { serverRoutes } from './app.routes.server';
import { provideServerRendering } from '@angular/platform-server';
import { provideServerRouting } from '@angular/ssr';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideClientHydration(withEventReplay()),
    provideHttpClient(withFetch()),

    // Server Routing capabilities for Hybrid Mode
    provideServerRendering(),
    provideServerRouting(serverRoutes)
  ]
};
EOF

# --- 5. Clean & Rebuild ---
echo "--- Step 5: Clean Install & Build ---"
echo "🧹 Cleaning caches..."
rm -rf .angular node_modules package-lock.json

echo "📦 Installing dependencies..."
npm install

echo "🧪 Building SSR..."
npm run build:ssr

echo "---------------------------------------------------"
echo "✅ Fix Applied!"
echo "---------------------------------------------------"
echo "👉 To verify locally:"
echo "   ./scripts/dev-web-ssr.sh"
echo ""
echo "👉 To push changes:"
echo "   git add web/bechde-web/src/app/app.routes.server.ts web/bechde-web/src/app/app.config.ts web/bechde-web/src/main.ts web/bechde-web/src/main.server.ts web/bechde-web/package.json web/bechde-web/package-lock.json"
echo "   git commit -m 'Web SSR: fix prerender for dynamic routes; enable Zone.js'"
echo "   git push origin feature/web-ci-ssr"
echo "---------------------------------------------------"
