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
    return this.http.get<Page<Listing>>(`${API_BASE}/listings`, { params });
  }

  get(id: string) {
    return this.http.get<Listing>(`${API_BASE}/listings/${id}`);
  }

  create(body: ListingCreate) {
    return this.http.post<Listing>(`${API_BASE}/listings`, body);
  }
}
