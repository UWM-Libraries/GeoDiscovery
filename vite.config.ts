import { defineConfig } from 'vite'
import rails from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    ruby(),
  ]
})