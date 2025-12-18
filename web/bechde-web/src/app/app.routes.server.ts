import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  { path: '', renderMode: RenderMode.Prerender },
  { path: 'listings', renderMode: RenderMode.Prerender },
  { path: 'listings/:id', renderMode: RenderMode.Server }, # Dynamic -> SSR
  { path: 'sell', renderMode: RenderMode.Server },         # Auth required -> SSR
  { path: '**', renderMode: RenderMode.Server }            # Fallback -> SSR
];
