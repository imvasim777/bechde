#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
REPO_ROOT="$(pwd)"
WEB_DIR="web/bechde-web"
BRANCH_NAME="feature/web-ci-ssr"

# --- Pre-flight Checks ---
if [ ! -d "$WEB_DIR" ]; then
    echo "❌ Error: Directory $WEB_DIR not found."
    echo "   Please run this script from the root of the repository."
    exit 1
fi

echo "🔧 Applying Angular Route Fix (HomeComponent)..."

# --- 1. Ensure we are on the correct branch ---
echo "--- Step 1: Checking Branch ---"
current_branch=$(git branch --show-current)
if [ "$current_branch" != "$BRANCH_NAME" ]; then
    echo "   Switching to $BRANCH_NAME..."
    git checkout "$BRANCH_NAME" || git checkout -b "$BRANCH_NAME"
else
    echo "   Already on $BRANCH_NAME"
fi

cd "$WEB_DIR"

# --- 2. Create HomeComponent ---
echo "--- Step 2: Creating HomeComponent ---"
cat > src/app/home.component.ts <<'EOF'
import { Component } from '@angular/core';

@Component({
  selector: 'app-home',
  standalone: true,
  template: `
    <div style="text-align: center; margin-top: 50px; font-family: sans-serif;">
      <h1>🚀 Bechde SSR is working!</h1>
      <p>This content is rendered via Angular Universal (SSR).</p>
      <small>Edit src/app/home.component.ts to change this view.</small>
    </div>
  `,
})
export class HomeComponent {}
EOF

# --- 3. Update Routes ---
echo "--- Step 3: Updating app.routes.ts ---"
cat > src/app/app.routes.ts <<'EOF'
import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('./home.component').then(m => m.HomeComponent)
  },
  {
    path: '**',
    redirectTo: ''
  },
];
EOF

# --- 4. Git Commit ---
echo "--- Step 4: Committing Changes ---"
cd "$REPO_ROOT"
git add "$WEB_DIR/src/app/home.component.ts" "$WEB_DIR/src/app/app.routes.ts"
git commit -m "Web: add default home route to fix blank page in SSR" || echo "⚠️  Nothing to commit (files might be unchanged)"

echo "---------------------------------------------------"
echo "✅ Fix Applied!"
echo "---------------------------------------------------"
echo "👉 To verify locally:"
echo "   ./scripts/dev-web-ssr.sh"
echo ""
echo "👉 To finish and notify Release Manager:"
echo "   git push origin $BRANCH_NAME"
echo "---------------------------------------------------"
