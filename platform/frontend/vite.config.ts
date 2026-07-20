import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": resolve(__dirname, "./src"),
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        // vanilla-framework's own SCSS uses deprecated Sass APIs (map-get,
        // @import, etc.). Silence these so they don't flood stdout and slow
        // down the dev server. This does not affect our own SCSS.
        silenceDeprecations: ["global-builtin", "import", "color-functions"],
        quietDeps: true,
      },
    },
  },
  server: {
    port: 3000,
    // Proxy API + WebSocket calls to the local backend during development
    proxy: {
      "/api": {
        target: "http://localhost:8080",
        changeOrigin: true,
      },
      "/ws": {
        target: "ws://localhost:8080",
        ws: true,
      },
      // Proxy code-server (VS Code in the browser) — lab workspace editor
      "/code-server": {
        target: "http://localhost:8081",
        changeOrigin: true,
        ws: true,
        rewrite: (path) => path.replace(/^\/code-server/, ""),
      },
    },
  },
});
