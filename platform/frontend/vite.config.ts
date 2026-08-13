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
  server: {
    port: 3000,
    // Proxy API + WebSocket calls to the local backend during development
    proxy: {
      "/api": {
        target: "http://localhost:52135",
        changeOrigin: true,
      },
      "/ws": {
        target: "ws://localhost:52135",
        ws: true,
      },
      "/code-server": {
        target: "http://localhost:8081",
        changeOrigin: true,
        ws: true,
        rewrite: (path) => path.replace(/^\/code-server/, ""),
      },
      "/_static": {
        target: "http://localhost:8081",
        changeOrigin: true,
      },
    },
  },
});
