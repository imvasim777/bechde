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

echo "🔧 Applying Final Angular SSR Fixes (Zone.js + Server Routes)..."

cd "$WEB_DIR"

# --- 1. Fix server routes (Remove illegal comments, fix RenderModes) ---
echo "--- Step 1: Fixing app.routes.server.ts ---"
mkdir -p src/app
cat > src/app/app.routes.server.ts <<EOF
import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  { path: '', renderMode: RenderMode.Prerender },
  { path: 'listings', renderMode: RenderMode.Prerender },
  // Dynamic -> handle via SSR
  { path: 'listings/:id', renderMode: RenderMode.Server },
  // Auth/workflow pages -> SSR
  { path: 'sell', renderMode: RenderMode.Server },
  // Fallback -> SSR
  { path: '**', renderMode: RenderMode.Server }
];
EOF

# --- 2. Fix app.config.ts (Remove provideServerRouting, enable Zone) ---
echo "--- Step 2: Fixing app.config.ts ---"
cat > src/app/app.config.ts <<EOF
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';
import { provideHttpClient, withFetch } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideClientHydration(withEventReplay()),
    provideHttpClient(withFetch())
  ]
};
EOF

# --- 3. Fix main.ts (Import zone.js for Browser) ---
echo "--- Step 3: Patching main.ts ---"
# Check if zone.js is already imported; if not, prepend it
if ! grep -q "import 'zone.js';" src/main.ts; then
    cat <(echo "import 'zone.js';") src/main.ts > src/main.ts.tmp && mv src/main.ts.tmp src/main.ts
    echo "   Added import 'zone.js' to main.ts"
fi

# --- 4. Fix main.server.ts (Import zone.js/node & simplify bootstrap) ---
echo "--- Step 4: Patching main.server.ts ---"
cat > src/main.server.ts <<EOF
import 'zone.js/node';
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { config as serverConfig } from './app/app.config.server';

export default function bootstrap() {
  return bootstrapApplication(AppComponent, serverConfig);
}
EOF

# --- 5. Ensure app.config.server.ts exists (Dependency for main.server.ts) ---
# We ensure the server config merges the app config with server rendering providers
if [ ! -f "src/app/app.config.server.ts" ]; then
    echo "--- Step 5: Creating missing app.config.server.ts ---"
    cat > src/app/app.config.server.ts <<EOF
import { mergeApplicationConfig, ApplicationConfig } from '@angular/core';
import { provideServerRendering } from '@angular/platform-server';
import { appConfig } from './app.config';
import { serverRoutes } from './app.routes.server';
import { provideServerRouting } from '@angular/ssr';

const serverConfig: ApplicationConfig = {
  providers: [
    provideServerRendering(),
    provideServerRouting(serverRoutes)
  ]
};

export const config = mergeApplicationConfig(appConfig, serverConfig);
EOF
fi

# --- 6. Kill Stray Port 4200 (Mac/Linux) ---
echo "--- Step 6: Checking Port 4200 ---"
# Finds PID using port 4200 and kills it
PID=$(lsof -t -i :4200 || true)
if [ -n "$PID" ]; then
    echo "   Killing process $PID on port 4200..."
    kill -9 "$PID"
else
    echo "   Port 4200 is free."
fi

# --- 7. Clean & Rebuild ---
echo "--- Step 7: Clean & Rebuild ---"
echo "🧹 Cleaning cache..."
rm -rf .angular node_modules
# Re-installing deps to ensure everything is fresh
echo "📦 npm install..."
npm install

echo "---------------------------------------------------"
echo "✅ Configuration Fixed!"
echo "---------------------------------------------------"
echo "🚀 To run the server (SSR Dev Mode):"
echo "   cd $WEB_DIR"
echo "   npm run dev:ssr"
echo ""
echo "👉 Verify:"
echo "   1. Feed: http://localhost:4200/listings"
echo "   2. Detail: http://localhost:4200/listings/some-id"
echo "   3. Sell: http://localhost:4200/sell"
echo "---------------------------------------------------"
