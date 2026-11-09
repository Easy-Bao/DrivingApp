import '@web/ui/styles/theme.css'
import './assets/main.css'

import { createPinia } from 'pinia'
import { createApp } from 'vue'
import App from './App.vue'

const application = createApp(App)

application.use(createPinia())

application.mount('#app')
