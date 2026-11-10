export const env = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || '/api',
  appEnv: import.meta.env.MODE || 'development',
}
