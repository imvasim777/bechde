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
