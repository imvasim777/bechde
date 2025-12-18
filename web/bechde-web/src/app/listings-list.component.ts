import { Component, inject, OnInit } from '@angular/core';
import { NgFor, NgIf, CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ListingsApi, Listing } from './api/listings/listings.api';

@Component({
  standalone: true,
  imports: [NgFor, NgIf, RouterLink, CommonModule],
  template: `
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
  `,
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
