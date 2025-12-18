import 'zone.js/node';
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { config as serverConfig } from './app/app.config.server';

// Fix: Accept context (any) and pass it to bootstrapApplication
export default function bootstrap(context?: any) {
  return bootstrapApplication(AppComponent, serverConfig, context);
}
