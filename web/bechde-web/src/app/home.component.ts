import { Component } from '@angular/core';

@Component({
  selector: 'app-home',
  standalone: true,
  template: `
    <div style="text-align: center; margin-top: 50px; font-family: sans-serif;">
      <h1>🚀 Bechde SSR is working!</h1>
      <p>This content is rendered via Angular Universal (SSR).</p>
      <small>Edit src/app/home.component.ts to change this view.</small>
    </div>
  `,
})
export class HomeComponent {}
