import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { serverRoutes } from './app.routes.server';
import { provideServerRendering } from '@angular/platform-server';
import { provideServerRouting } from '@angular/ssr';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideClientHydration(withEventReplay()),
    provideHttpClient(withFetch()),

    // Server Routing capabilities for Hybrid Mode
    provideServerRendering(),
    provideServerRouting(serverRoutes)
  ]
};
