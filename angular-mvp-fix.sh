#!/usr/bin/env bash
set -euo pipefail

WEB_DIR="web/bechde-web"

if [ ! -d "$WEB_DIR" ]; then
    echo "❌ Error: Run this from the repository root."
    exit 1
fi

echo "🔧 Fixing NG0401: Restoring BootstrapContext in main.server.ts..."
cd "$WEB_DIR"

# --- Fix main.server.ts ---
# We update the bootstrap function to accept 'context' and pass it as the 3rd argument
# to bootstrapApplication. This allows Angular to initialize the Server Platform correctly.

cat > src/main.server.ts <<EOF
import 'zone.js/node';
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { config as serverConfig } from './app/app.config.server';

// Fix: Accept context (any) and pass it to bootstrapApplication
export default function bootstrap(context?: any) {
  return bootstrapApplication(AppComponent, serverConfig, context);
}
EOF

# --- Clean & Rebuild ---
echo "🧹 Cleaning cache to force re-compilation..."
rm -rf .angular

echo "---------------------------------------------------"
echo "✅ Fix Applied!"
echo "---------------------------------------------------"
echo "🚀 Try running the server again:"
echo "   cd web/bechde-web"
echo "   npm run dev:ssr"
echo "---------------------------------------------------"
