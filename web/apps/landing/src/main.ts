import '@web/ui/styles/theme.css'
import './assets/main.css'

import { createPinia } from 'pinia'
import { createApp } from 'vue'
import App from './App.vue'
import applicationRouter from './app/router/application-router'

const application = createApp(App)

application.use(createPinia())
application.use(applicationRouter)

application.mount('#app')
