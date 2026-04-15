// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui',
    '@vueuse/nuxt'
  ],

  devtools: {
    enabled: true
  },

  css: ['~/assets/css/main.css'],

  routeRules: {
    '/api/**': {
      cors: true
    }
  },

  compatibilityDate: '2024-07-11',

  nitro: {
    externals: {
      // Keep @opentelemetry/api as an external so server routes that call
      // trace.getTracer() share the same global singleton registered by
      // instrumentation.mjs (loaded via node --import before the server boots).
      external: ['@opentelemetry/api']
    }
  },

  hooks: {
    'nitro:config'(nitroConfig) {
    nitroConfig.rollupConfig = nitroConfig.rollupConfig || {}
    }
  },

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})
