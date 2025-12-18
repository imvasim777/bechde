import { Component, inject } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { ListingsApi } from './api/listings/listings.api';
import { Router } from '@angular/router';
import { NgIf } from '@angular/common';

@Component({
  standalone: true,
  imports: [ReactiveFormsModule, NgIf],
  template: `
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
  `,
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
