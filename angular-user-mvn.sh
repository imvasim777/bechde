#!/usr/bin/env bash

# Script: auto_push_web.sh
# Description: Scaffolds Angular SSR app, generates OpenAPI clients, wires core pages, commits and pushes.
# Requires: Node, @angular/cli, @openapitools/openapi-generator-cli, git, optional gh CLI

set -euo pipefail

# --- Configuration ---
REPO_ROOT="$(pwd)"
WEB_DIR="web/bechde-web"
BRANCH="feature/web-ssr-mvp-$(date +%s)"
API_BASE="http://localhost:8080"

echo "🚀 Building Angular SSR app..."

# --- 0) Ensure tools ---
echo "--- Checking tools ---"
if ! command -v ng >/dev/null 2>&1; then
    echo "Installing Angular CLI..."
    npm i -g @angular/cli
fi

if ! command -v openapi-generator-cli >/dev/null 2>&1; then
    echo "Installing OpenAPI Generator CLI..."
    npm i -g @openapitools/openapi-generator-cli
fi

# --- 1) Create web project with SSR ---
echo "--- Scaffolding Project ---"
mkdir -p web
cd web

if [ ! -d "bechde-web" ]; then
    ng new bechde-web \
        --ssr \
        --routing \
        --style=scss \
        --skip-git \
        --strict=false \
        --package-manager=npm
fi

cd bechde-web

# --- 2) Install dependencies ---
echo "--- Installing Dependencies ---"
npm install

# --- 3) Generate OpenAPI clients ---
echo "--- Generating API Clients ---"
mkdir -p src/app/api

# Helper function to generate client
gen_client() {
    local name=$1
    local input="$REPO_ROOT/openapi/$name.yaml"
    local output="src/app/api/$name"

    echo "Generating $name client..."
    openapi-generator-cli generate \
        -g typescript-angular \
        -i "$input" \
        -o "$output" \
        -p providedInRoot=true
}

gen_client "auth"
gen_client "users"
gen_client "listings"
gen_client "payments"

# --- 4) Env configuration ---
echo "--- Configuring Environments ---"
# Using unquoted EOF to allow variable expansion ($API_BASE)
cat > src/environments/environment.ts <<EOF
export const environment = {
  production: false,
  apiBaseUrl: '${API_BASE}'
};
EOF

cat > src/environments/environment.development.ts <<EOF
export const environment = {
  production: false,
  apiBaseUrl: '${API_BASE}'
};
EOF

cat > src/environments/environment.prod.ts <<EOF
export const environment = {
  production: true,
  apiBaseUrl: '${API_BASE}'
};
EOF

# --- 5) Auth Interceptor ---
echo "--- Creating Auth Interceptor ---"
mkdir -p src/app/core
# Using quoted 'EOF' to prevent Bash from expanding ${token}
cat > src/app/core/auth.interceptor.ts <<'EOF'
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler } from '@angular/common/http';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler) {
    const token = typeof localStorage !== 'undefined' ? localStorage.getItem('jwt') : null;
    return next.handle(token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req);
  }
}
EOF

# --- 6) App module wiring for clients + interceptor ---
echo "--- Wiring App Config ---"
cat > src/app/app.config.ts <<'EOF'
import { ApplicationConfig, importProvidersFrom } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { HTTP_INTERCEPTORS, HttpClientModule } from '@angular/common/http';
import { AuthInterceptor } from './core/auth.interceptor';
import { environment } from '../environments/environment';
import { Configuration as AuthCfg } from './api/auth';
import { Configuration as UsersCfg } from './api/users';
import { Configuration as ListingsCfg } from './api/listings';
import { Configuration as PaymentsCfg } from './api/payments';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    importProvidersFrom(HttpClientModule),
    { provide: AuthCfg, useFactory: () => new AuthCfg({ basePath: environment.apiBaseUrl }) },
    { provide: UsersCfg, useFactory: () => new UsersCfg({ basePath: environment.apiBaseUrl }) },
    { provide: ListingsCfg, useFactory: () => new ListingsCfg({ basePath: environment.apiBaseUrl }) },
    { provide: PaymentsCfg, useFactory: () => new PaymentsCfg({ basePath: environment.apiBaseUrl }) },
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
  ]
};
EOF

# --- 7) Routes and pages ---
echo "--- Creating Routes and Components ---"
cat > src/app/app.routes.ts <<'EOF'
import { Routes } from '@angular/router';
import { HomeComponent } from './home/home.component';
import { LoginComponent } from './auth/login.component';
import { RegisterComponent } from './auth/register.component';
import { ProfileComponent } from './profile/profile.component';
import { CreateListingComponent } from './listings/create-listing.component';
import { PayComponent } from './payments/pay.component';

export const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: 'profile', component: ProfileComponent },
  { path: 'create-listing', component: CreateListingComponent },
  { path: 'pay', component: PayComponent },
];
EOF

# Home Component
mkdir -p src/app/home
cat > src/app/home/home.component.ts <<'EOF'
import { Component } from '@angular/core';
import { Title, Meta, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [RouterModule, CommonModule],
  template: `
    <h1>Bechde — Local Marketplace</h1>
    <nav>
      <a routerLink="/login">Login</a> |
      <a routerLink="/register">Register</a> |
      <a routerLink="/profile">Profile</a> |
      <a routerLink="/create-listing">Create Listing</a> |
      <a routerLink="/pay">Payments</a>
    </nav>
    <p>Gateway: rendering via SSR. Choose an action above.</p>
  `
})
export class HomeComponent {
  constructor(t: Title, m: Meta) {
    t.setTitle('Bechde — Local Marketplace');
    m.updateTag({ name: 'description', content: 'Buy & sell locally with Bechde.' });
  }
}
EOF

# Auth: Login
mkdir -p src/app/auth
cat > src/app/auth/login.component.ts <<'EOF'
import { Component } from '@angular/core';
import { AuthService, LoginRequest } from '../api/auth';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <h2>Login</h2>
    <form (ngSubmit)="submit()">
      <input [(ngModel)]="email" name="email" type="email" required placeholder="Email"/>
      <input [(ngModel)]="password" name="password" type="password" required placeholder="Password"/>
      <button type="submit">Login</button>
      <p *ngIf="error" style="color:red">{{error}}</p>
    </form>
  `
})
export class LoginComponent {
  email='';
  password='';
  error='';
  constructor(private authApi: AuthService, private router: Router){}

  submit(){
    const body: LoginRequest = { email: this.email, password: this.password };
    this.authApi.login(body).subscribe({
      next: (res:any) => {
        if(typeof localStorage!=='undefined'){
          localStorage.setItem('jwt', res.accessToken);
        }
        this.router.navigateByUrl('/profile');
      },
      error: () => this.error='Invalid credentials'
    });
  }
}
EOF

# Auth: Register
cat > src/app/auth/register.component.ts <<'EOF'
import { Component } from '@angular/core';
import { AuthService, RegisterRequest } from '../api/auth';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <h2>Register</h2>
    <form (ngSubmit)="submit()">
      <input [(ngModel)]="email" name="email" type="email" required placeholder="Email"/>
      <input [(ngModel)]="password" name="password" type="password" required placeholder="Password (min 8)"/>
      <input [(ngModel)]="displayName" name="displayName" required placeholder="Name"/>
      <input [(ngModel)]="city" name="city" required placeholder="City"/>
      <button type="submit">Create account</button>
      <p *ngIf="msg">{{msg}}</p>
    </form>
  `
})
export class RegisterComponent {
  email=''; password=''; displayName=''; city=''; msg='';
  constructor(private auth: AuthService, private router: Router){}

  submit(){
    const body: RegisterRequest = {
      email: this.email,
      password: this.password,
      displayName: this.displayName,
      city: this.city
    };
    this.auth.register(body).subscribe({
      next: () => {
        this.msg = 'Registered! Please login.';
        this.router.navigateByUrl('/login');
      },
      error: () => this.msg='Registration failed'
    });
  }
}
EOF

# Profile
mkdir -p src/app/profile
cat > src/app/profile/profile.component.ts <<'EOF'
import { Component } from '@angular/core';
import { UsersService } from '../api/users';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <h2>My Profile</h2>
    <button (click)="load()">Load</button>
    <pre *ngIf="profile">{{ profile | json }}</pre>
    <div>
      <input [(ngModel)]="displayName" placeholder="Display Name"/>
      <input [(ngModel)]="city" placeholder="City"/>
      <input [(ngModel)]="phone" placeholder="Phone"/>
      <button (click)="save()">Save</button>
      <p *ngIf="msg">{{msg}}</p>
    </div>
  `
})
export class ProfileComponent {
  profile:any; displayName=''; city=''; phone=''; msg='';
  constructor(private users: UsersService){}

  load(){
    this.users.usersMeGet().subscribe(p=> this.profile=p);
  }

  save(){
    this.users.usersMePatch({displayName:this.displayName, city:this.city, phone:this.phone})
      .subscribe(p=>{
        this.profile=p;
        this.msg='Saved!';
      });
  }
}
EOF

# Create Listing
mkdir -p src/app/listings
cat > src/app/listings/create-listing.component.ts <<'EOF'
import { Component } from '@angular/core';
import { ListingsService, ListingCreate } from '../api/listings';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-create-listing',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <h2>Create Listing</h2>
    <form (ngSubmit)="submit()">
      <input [(ngModel)]="model.title" name="title" placeholder="Title" required minlength="10"/>
      <textarea [(ngModel)]="model.description" name="description" required minlength="20" placeholder="Description"></textarea>
      <input [(ngModel)]="amount" name="amount" type="number" min="0" placeholder="Amount"/>
      <select [(ngModel)]="model.price.currency" name="currency">
        <option>USD</option><option>INR</option><option>EUR</option>
      </select>
      <select [(ngModel)]="model.category" name="category">
        <option>electronics</option><option>furniture</option><option>vehicles</option><option>other</option>
      </select>
      <input [(ngModel)]="model.city" name="city" placeholder="City" required />
      <button type="submit">Create</button>
    </form>
    <p *ngIf="msg">{{msg}}</p>
  `
})
export class CreateListingComponent {
  amount=0;
  model: ListingCreate = {
    title:'',
    description:'',
    price:{amount:0,currency:'USD'},
    category:'electronics',
    city:''
  };
  msg='';

  constructor(private api: ListingsService){}

  submit(){
    this.model.price.amount=this.amount;
    this.api.createListing(this.model).subscribe({
      next: () => this.msg='Created!',
      error: () => this.msg='Failed'
    });
  }
}
EOF

# Payments test
mkdir -p src/app/payments
cat > src/app/payments/pay.component.ts <<'EOF'
import { Component } from '@angular/core';
import { PaymentsService } from '../api/payments';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-pay',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <h2>Payments Test</h2>
    <input [(ngModel)]="listingId" placeholder="Listing ID"/>
    <select [(ngModel)]="placementType">
      <option>featured</option><option>boosted</option>
    </select>
    <button (click)="checkout()">Create Checkout Session</button>
    <p *ngIf="msg">{{msg}}</p>
  `
})
export class PayComponent {
  listingId=''; placementType='featured'; msg='';
  constructor(private payments: PaymentsService){}

  checkout(){
    this.payments.paymentsCheckoutSessionPost({listingId:this.listingId, placementType:this.placementType as any})
      .subscribe({
        next: (res:any) => {
          if(res?.url) { window.location.href = res.url; }
          else { this.msg='No URL returned'; }
        },
        error: ()=> this.msg='Failed to create session'
      });
  }
}
EOF

# --- 8) Root bootstrap ---
echo "--- Bootstrapping App ---"
cat > src/app/app.component.ts <<'EOF'
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterModule],
  template: `<router-outlet></router-outlet>`
})
export class AppComponent {}
EOF

cat > src/main.ts <<'EOF'
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

bootstrapApplication(AppComponent, appConfig).catch(err => console.error(err));
EOF

# --- 9) Quick tests (smoke) ---
echo "--- Creating Smoke Tests ---"
mkdir -p src/app/auth
cat > src/app/auth/login.component.spec.ts <<'EOF'
import { LoginComponent } from './login.component';
describe('LoginComponent', () => {
  it('should create', () => {
    const comp = new LoginComponent({} as any, {} as any);
    expect(comp).toBeTruthy();
  });
});
EOF

# --- 10) Back to repo root; commit/PR ---
echo "--- Committing and Pushing ---"
cd "$REPO_ROOT"

# Create branch if it doesn't exist
git checkout -b "$BRANCH" || git checkout "$BRANCH"

git add web/bechde-web
git commit -m "feat(web): Angular SSR MVP (auth, profile, create listing, payments) with OpenAPI clients" || true

if command -v gh >/dev/null 2>&1; then
    echo "Creating PR via GitHub CLI..."
    git push -u origin "$BRANCH" || true
    gh pr create \
        -B main \
        -H "$BRANCH" \
        --title "feat(web): SSR MVP app" \
        --body "SSR Angular app with auth, profile, create listing, payments using generated OpenAPI clients." \
        --draft || true
else
    echo "ℹ️ gh CLI not found. Push manually: git push -u origin $BRANCH"
fi

echo "✅ Done. Start locally: cd web/bechde-web && npm run dev:ssr"
