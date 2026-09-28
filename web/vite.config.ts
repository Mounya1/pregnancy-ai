// @lovable.dev/vite-tanstack-config already includes the following — do NOT add them manually
// or the app will break with duplicate plugins:
//   - TanStack devtools (dev-only, first), tanstackStart, viteReact, tailwindcss, tsConfigPaths,
//     nitro (build-only using cloudflare as a default target), VITE_* env injection, @ path alias,
//     React/TanStack dedupe, error logger plugins, and sandbox detection (port/host/strictPort).
// You can pass additional config via defineConfig({ vite: { ... }, etc... }) if needed.
import { defineConfig } from "@lovable.dev/vite-tanstack-config";

// Nitro defaults to cloudflare-module here. Vercel is detected automatically
// when building on Vercel, but a local `NITRO_PRESET=vercel npm run build`
// has to be honoured too - otherwise the only way to reproduce the deployed
// artefact is to push and see, which is a slow way to find a build error.
const preset = process.env["NITRO_PRESET"];

export default defineConfig({
  tanstackStart: {
    // Redirect TanStack Start's bundled server entry to src/server.ts (our SSR error wrapper).
    // nitro/vite builds from this
    server: { entry: "server" },
  },
  ...(preset ? { nitro: { preset } } : {}),
});
