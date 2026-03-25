import { defineConfig } from 'vite'
import rails from 'vite-plugin-rails'

export default defineConfig({
  logLevel: 'error',
  build: {
    reportCompressedSize: false,
    chunkSizeWarningLimit: 2000,
  },
  plugins: [
    rails(),
  ]
})
