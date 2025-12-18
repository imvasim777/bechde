import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  { path: '', renderMode: RenderMode.Prerender },
  { path: 'listings', renderMode: RenderMode.Prerender },
  // Dynamic -> handle via SSR
  { path: 'listings/:id', renderMode: RenderMode.Server },
  // Auth/workflow pages -> SSR
  { path: 'sell', renderMode: RenderMode.Server },
  // Fallback -> SSR
  { path: '**', renderMode: RenderMode.Server }
];
