/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string
  readonly VITE_APP_NAME: string
  readonly VITE_APP_DESCRIPTION: string
  readonly VITE_ENABLE_ANALYTICS: string
  readonly VITE_ENABLE_REGISTRATION: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
