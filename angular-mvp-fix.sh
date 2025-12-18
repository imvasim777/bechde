#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
REPO_ROOT="$(pwd)"
WEB_DIR="web/bechde-web"
BACKEND_DIR="services/listings-service"
PACKAGE_DIR="src/main/java/com/bechde/listings"

# --- Pre-flight Checks ---
if [ ! -d "$WEB_DIR" ] || [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Error: Project directories not found."
    echo "   Run this from the repo root containing 'web/' and 'services/'."
    exit 1
fi

echo "🚀 Implementing Listings E2E (Web + Backend)..."

# ==============================================================================
# PART 1: BACKEND (Spring Boot)
# ==============================================================================
echo "--- ☕ Backend: Configuring Listings Service ---"
cd "$REPO_ROOT/$BACKEND_DIR"

# 1. Update application.yml (Port 8081 & Jackson config)
mkdir -p src/main/resources
cat > src/main/resources/application.yml <<EOF
server:
  port: 8081

spring:
  application:
    name: listings-service
  jackson:
    serialization:
      WRITE_DATES_AS_TIMESTAMPS: false
  # Assuming H2 for dev based on previous context, or Postgres if configured
  datasource:
    url: jdbc:h2:mem:listingsdb
    driverClassName: org.h2.Driver
    username: sa
    password: password
  jpa:
    database-platform: org.hibernate.dialect.H2Dialect
    hibernate:
      ddl-auto: update
EOF

# 2. Ensure DTOs exist (Fixes compilation errors due to missing classes)
# Creating ListingResponse Record
mkdir -p "$PACKAGE_DIR/web"
cat > "$PACKAGE_DIR/ListingResponse.java" <<EOF
package com.bechde.listings;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record ListingResponse(
    UUID id,
    String title,
    String description,
    BigDecimal priceAmount,
    String currency,
    String category,
    String city,
    Double lat,
    Double lon,
    String status,
    String slug,
    OffsetDateTime publishedAt
) {}
EOF

# Creating ListingCreateDto Record (if not already present)
mkdir -p "$PACKAGE_DIR/dto"
cat > "$PACKAGE_DIR/dto/ListingCreateDto.java" <<EOF
package com.bechde.listings.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record ListingCreateDto(
    @NotBlank @Size(min=10, max=120) String title,
    @NotBlank @Size(min=20, max=5000) String description,
    @NotNull @DecimalMin("0.0") BigDecimal priceAmount,
    @NotBlank String currency,
    @NotBlank String category,
    @NotBlank String city,
    Double lat,
    Double lon
) {}
EOF

# 3. Create ListingResponseMapper
cat > "$PACKAGE_DIR/web/ListingResponseMapper.java" <<EOF
package com.bechde.listings.web;

import com.bechde.listings.domain.Listing;
import com.bechde.listings.ListingResponse;

class ListingResponseMapper {
    static ListingResponse toDto(Listing l) {
        return new ListingResponse(
            l.getId(),
            l.getTitle(),
            l.getDescription(),
            l.getPriceAmount(),
            l.getCurrency(),
            l.getCategory(),
            l.getCity(),
            l.getLat(),
            l.getLon(),
            l.getStatus() != null ? l.getStatus().name() : "ACTIVE",
            l.getSlug(),
            l.getPublishedAt()
        );
    }
}
EOF

# 4. Create/Update ListingsController
# Note: Synthesizing full controller with dependency injection
cat > "$PACKAGE_DIR/web/ListingsController.java" <<EOF
package com.bechde.listings.web;

import com.bechde.listings.domain.Listing;
import com.bechde.listings.dto.ListingCreateDto;
import com.bechde.listings.repo.ListingRepository;
import com.bechde.listings.service.ListingService;
import com.bechde.listings.ListingResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.net.URI;
import java.util.UUID;

@CrossOrigin(origins = "http://localhost:4200")
@RestController
@RequestMapping("/listings")
public class ListingsController {

    private final ListingService svc;
    private final ListingRepository repo;

    public ListingsController(ListingService svc, ListingRepository repo) {
        this.svc = svc;
        this.repo = repo;
    }

    @PostMapping
    public ResponseEntity<ListingResponse> create(@Valid @RequestBody ListingCreateDto dto) {
        Listing saved = svc.create(dto);
        return ResponseEntity
                .created(URI.create("/listings/" + saved.getId()))
                .body(ListingResponseMapper.toDto(saved));
    }

    @GetMapping
    public Page<ListingResponse> list(
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="10") int size) {

        Pageable pageable = PageRequest.of(
            Math.max(page, 0),
            Math.min(size, 50),
            Sort.by(Sort.Direction.DESC, "publishedAt")
        );

        return repo.findAll(pageable).map(ListingResponseMapper::toDto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ListingResponse> get(@PathVariable UUID id) {
        return repo.findById(id)
                .map(ListingResponseMapper::toDto)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
EOF

# ==============================================================================
# PART 2: FRONTEND (Angular)
# ==============================================================================
echo "--- 🅰️  Web: Configuring Angular App ---"
cd "$REPO_ROOT/$WEB_DIR"

# 1. Update app.config.ts (Add HttpClient with fetch)
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

# 2. Create API Service
mkdir -p src/app/api/listings
cat > src/app/api/listings/listings.api.ts <<EOF
import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';

export type Listing = {
  id: string;
  title: string;
  description: string;
  priceAmount: number;
  currency: 'USD'|'INR'|'EUR';
  category: string;
  city: string;
  lat?: number;
  lon?: number;
  status: string;
  slug: string;
  publishedAt: string;
};

export type Page<T> = {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
};

export type ListingCreate = {
  title: string;
  description: string;
  priceAmount: number;
  currency: 'USD'|'INR'|'EUR';
  category: string;
  city: string;
  lat?: number;
  lon?: number;
};

const API_BASE = 'http://localhost:8081';

@Injectable({ providedIn: 'root' })
export class ListingsApi {
  private http = inject(HttpClient);

  list(page=0, size=10) {
    const params = new HttpParams().set('page', page).set('size', size);
    return this.http.get<Page<Listing>>(\`\${API_BASE}/listings\`, { params });
  }

  get(id: string) {
    return this.http.get<Listing>(\`\${API_BASE}/listings/\${id}\`);
  }

  create(body: ListingCreate) {
    return this.http.post<Listing>(\`\${API_BASE}/listings\`, body);
  }
}
EOF

# 3. Create Components

# Listings List (Feed)
cat > src/app/listings-list.component.ts <<EOF
import { Component, inject, OnInit } from '@angular/core';
import { NgFor, NgIf, CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ListingsApi, Listing } from './api/listings/listings.api';

@Component({
  standalone: true,
  imports: [NgFor, NgIf, RouterLink, CommonModule],
  template: \`
    <div class="container">
      <h2>Listings</h2>
      <div *ngIf="loading">Loading...</div>
      <div *ngIf="error" class="error" style="color:red">{{ error }}</div>

      <ul style="list-style:none; padding:0;">
        <li *ngFor="let l of items" style="border-bottom:1px solid #ccc; padding: 1rem 0;">
          <h3><a [routerLink]="['/listings', l.id]">{{ l.title }}</a></h3>
          <p>{{ l.priceAmount | currency:l.currency }} — {{ l.city }}</p>
          <small>{{ l.publishedAt | date }}</small>
        </li>
      </ul>

      <div style="margin-top: 1rem;">
        <button (click)="prev()" [disabled]="page<=0">Prev</button>
        <span style="margin: 0 1rem;">Page {{page + 1}} of {{totalPages || 1}}</span>
        <button (click)="next()" [disabled]="page>=totalPages-1">Next</button>
      </div>
    </div>
  \`,
})
export class ListingsListComponent implements OnInit {
  private api = inject(ListingsApi);
  items: Listing[] = [];
  loading = false;
  error = '';
  page = 0;
  totalPages = 0;

  ngOnInit() {
    this.load();
  }

  load() {
    this.loading = true;
    this.error = '';
    this.api.list(this.page, 10).subscribe({
      next: (p) => {
        this.items = p.content;
        this.totalPages = p.totalPages;
        this.loading = false;
      },
      error: () => {
        this.error = 'Failed to load listings. Is backend running on port 8081?';
        this.loading = false;
      }
    });
  }

  next() { if(this.page < this.totalPages - 1) { this.page++; this.load(); } }
  prev() { if(this.page > 0) { this.page--; this.load(); } }
}
EOF

# Listing Detail
cat > src/app/listing-detail.component.ts <<EOF
import { Component, inject, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { NgIf, CommonModule } from '@angular/common';
import { ListingsApi, Listing } from './api/listings/listings.api';

@Component({
  standalone: true,
  imports: [NgIf, CommonModule, RouterLink],
  template: \`
    <div style="padding: 1rem;">
      <a routerLink="/listings">← Back to feed</a>
      <div *ngIf="!item && !error">Loading...</div>
      <div *ngIf="error" class="error" style="color:red">{{ error }}</div>

      <section *ngIf="item" style="margin-top:1rem; border:1px solid #ddd; padding:1rem;">
        <h2>{{ item.title }}</h2>
        <p style="font-size: 1.2rem; font-weight: bold;">
          {{ item.priceAmount | currency:item.currency }}
        </p>
        <p>{{ item.description }}</p>
        <p><strong>Location:</strong> {{ item.city }}</p>
        <small>Published: {{ item.publishedAt | date:'medium' }}</small>
        <br><br>
        <button disabled>Contact Seller (Coming Soon)</button>
      </section>
    </div>
  \`
})
export class ListingDetailComponent implements OnInit {
  private api = inject(ListingsApi);
  private route = inject(ActivatedRoute);
  item?: Listing;
  error = '';

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id')!;
    this.api.get(id).subscribe({
      next: (l) => this.item = l,
      error: () => this.error = 'Listing not found or API unavailable'
    });
  }
}
EOF

# Listing Create (Sell)
cat > src/app/listing-create.component.ts <<EOF
import { Component, inject } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { ListingsApi } from './api/listings/listings.api';
import { Router } from '@angular/router';
import { NgIf } from '@angular/common';

@Component({
  standalone: true,
  imports: [ReactiveFormsModule, NgIf],
  template: \`
    <div style="max-width: 600px; margin: 0 auto; padding: 1rem;">
      <h2>Sell an item</h2>
      <form [formGroup]="form" (ngSubmit)="submit()" style="display: flex; flex-direction: column; gap: 1rem;">

        <label>
          Title
          <input formControlName="title" style="display:block; width:100%; padding: 0.5rem;">
        </label>
        <div *ngIf="form.controls.title.invalid && form.controls.title.touched" style="color:red">
          Title must be at least 10 characters
        </div>

        <label>
          Description
          <textarea formControlName="description" rows="5" style="display:block; width:100%; padding: 0.5rem;"></textarea>
        </label>
        <div *ngIf="form.controls.description.invalid && form.controls.description.touched" style="color:red">
          Description must be at least 20 characters
        </div>

        <div style="display:flex; gap: 1rem;">
          <label style="flex:1">
            Price
            <input type="number" formControlName="amount" style="display:block; width:100%; padding: 0.5rem;">
          </label>
          <label style="width: 100px;">
            Currency
            <select formControlName="currency" style="display:block; width:100%; padding: 0.5rem;">
              <option value="USD">USD</option>
              <option value="INR">INR</option>
              <option value="EUR">EUR</option>
            </select>
          </label>
        </div>

        <label>
          Category
          <input formControlName="category" style="display:block; width:100%; padding: 0.5rem;">
        </label>

        <label>
          City
          <input formControlName="city" style="display:block; width:100%; padding: 0.5rem;">
        </label>

        <button type="submit" [disabled]="form.invalid || submitting"
                style="padding: 1rem; background: #007bff; color: white; border: none; cursor: pointer;">
          {{ submitting ? 'Creating...' : 'Create Listing' }}
        </button>

        <div *ngIf="error" style="color:red; margin-top: 1rem;">{{ error }}</div>
      </form>
    </div>
  \`,
})
export class ListingCreateComponent {
  private fb = inject(FormBuilder);
  private api = inject(ListingsApi);
  private router = inject(Router);

  submitting = false;
  error = '';

  form = this.fb.group({
    title: ['', [Validators.required, Validators.minLength(10)]],
    description: ['', [Validators.required, Validators.minLength(20)]],
    amount: [0, [Validators.required, Validators.min(0)]],
    currency: ['USD', [Validators.required]],
    category: ['', Validators.required],
    city: ['', [Validators.required, Validators.minLength(2)]],
  });

  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.submitting = true;
    this.error = '';

    // Map form values to API contract
    const body = {
      title: this.form.value.title!,
      description: this.form.value.description!,
      priceAmount: this.form.value.amount!,
      currency: this.form.value.currency! as 'USD'|'INR'|'EUR',
      category: this.form.value.category!,
      city: this.form.value.city!,
    };

    this.api.create(body).subscribe({
      next: (res) => this.router.navigate(['/listings', res.id]),
      error: () => {
        this.error = 'Failed to create listing. Ensure backend is running.';
        this.submitting = false;
      }
    });
  }
}
EOF

# 4. Update Routes (Lazy loading)
cat > src/app/app.routes.ts <<EOF
import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('./listings-list.component').then(m => m.ListingsListComponent)
  },
  {
    path: 'listings',
    loadComponent: () => import('./listings-list.component').then(m => m.ListingsListComponent)
  },
  {
    path: 'listings/:id',
    loadComponent: () => import('./listing-detail.component').then(m => m.ListingDetailComponent)
  },
  {
    path: 'sell',
    loadComponent: () => import('./listing-create.component').then(m => m.ListingCreateComponent)
  },
  {
    path: '**',
    redirectTo: ''
  },
];
EOF

echo "---------------------------------------------------"
echo "✅ Listings E2E Implementation Complete!"
echo "---------------------------------------------------"
echo "👉 To run the Backend:"
echo "   cd $BACKEND_DIR"
echo "   ./mvnw spring-boot:run -Dspring-boot.run.jvmArguments=\"-Dserver.port=8081\""
echo ""
echo "👉 To run the Frontend (in a separate terminal):"
echo "   cd $WEB_DIR"
echo "   ./scripts/dev-web-ssr.sh"
echo "---------------------------------------------------"
