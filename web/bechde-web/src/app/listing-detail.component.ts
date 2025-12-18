import { Component, inject, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { NgIf, CommonModule } from '@angular/common';
import { ListingsApi, Listing } from './api/listings/listings.api';

@Component({
  standalone: true,
  imports: [NgIf, CommonModule, RouterLink],
  template: `
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
  `
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
