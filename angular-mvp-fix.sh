#!/usr/bin/env bash

# Script: fix_angular_20_deps.sh
# Description: Resolves ERESOLVE dependency conflict by forcing zone.js 0.15.x
#              and applying the correct SSR configuration for Angular 20.

set -euo pipefail
WEB_DIR="web/bechde-web"

# --- Pre-flight Checks ---
if [ ! -d "$WEB_DIR" ]; then
    echo "❌ Web app not found at $WEB_DIR."
    exit 1
fi

cd "$WEB_DIR"
echo "🔧 Fixing Angular 20 Dependencies & SSR..."

# --- 1) Fix package.json Dependency Conflict ---
echo "--- Step 1: Aligning zone.js version ---"
# We must use ~0.15.0 to satisfy @angular/core@20.3.15
# We use a temp file to safely edit package.json on Linux & Mac
if [ -f "package.json" ]; then
    # explicit replace of zone.js version
    sed 's/"zone.js": ".*"/"zone.js": "~0.15.0"/' package.json > package.json.tmp && mv package.json.tmp package.json
    echo "✅ Updated package.json: zone.js -> ~0.15.0"
else
    echo "❌ package.json missing!"
    exit 1
fi

# --- 2) Nuke Node Modules (Essential for ERESOLVE errors) ---
echo "--- Step 2: Clean Install ---"
rm -rf node_modules package-lock.json .angular
# Install with legacy-peer-deps to be safe against bleeding edge conflicts,
# though the zone.js fix should resolve the main one.
npm install --legacy-peer-deps

# --- 3) Write Correct SSR Files (No zone.js/node imports) ---
echo "--- Step 3: Patching App Files ---"

# 3a. AppComponent (RouterOutlet Fix)
mkdir -p src/app
cat > src/app/app.component.ts <<'EOF'
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: `<router-outlet></router-outlet>`
})
export class AppComponent {}
EOF

# 3b. Browser Bootstrap
cat > src/main.ts <<'EOF'
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

bootstrapApplication(AppComponent, appConfig).catch(err => console.error(err));
EOF

# 3c. Server Bootstrap (Angular 20 Style)
# Using 'any' for context to avoid TS version mismatches
cat > src/main.server.ts <<'EOF'
import { bootstrapApplication } from '@angular/platform-browser';
import { provideServerRendering } from '@angular/platform-server';
import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

export default function bootstrap(context: any) {
  return bootstrapApplication(
    AppComponent,
    {
      ...appConfig,
      providers: [
        ...(appConfig.providers ?? []),
        provideServerRendering()
      ]
    },
    context
  );
}
EOF

# 3d. Server Entry (The Fix for "Cannot find module zone.js/node")
# WE DO NOT IMPORT zone.js/node HERE.
cat > src/server.ts <<'EOF'
import bootstrap from './main.server';
export default bootstrap;
EOF

# --- 4) Inject Modules (Forms & Hydration) ---
echo "--- Step 4: Injecting Forms & Hydration ---"

inject_forms() {
    local file="$1"
    [ -f "$file" ] || return 0
    if ! grep -q "FormsModule" "$file"; then
        cat <(echo 'import { FormsModule } from "@angular/forms";') "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        awk 'BEGIN{i=0;a=0} /@Component\(/ {i=1} i&&/standalone:\s*true/{print;next} i&&/imports:\s*\[/&&!a{sub(/\[/,"[ FormsModule, ");a=1} {print}' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
}
inject_forms "src/app/auth/login.component.ts"
inject_forms "src/app/auth/register.component.ts"
inject_forms "src/app/listings/create-listing.component.ts"
inject_forms "src/app/payments/pay.component.ts"
inject_forms "src/app/profile/profile.component.ts"

CONFIG_FILE="src/app/app.config.ts"
if [ -f "$CONFIG_FILE" ] && ! grep -q "provideClientHydration" "$CONFIG_FILE"; then
    cat <(echo 'import { provideClientHydration } from "@angular/platform-browser";') "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    awk 'BEGIN{d=0} /providers:\s*\[/&&!d{print;print "    provideClientHydration(),";d=1;next} {print}' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

# --- 5) Build & Run ---
echo "--- Step 5: Building ---"
npm run build:ssr

echo "✅ FIXED. Start the server:"
echo "npm run dev:ssr"
