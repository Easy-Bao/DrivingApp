import '@web/ui/styles/theme.css'
import '@/assets/styles/main.css'

import { createPinia } from 'pinia'
import { createApp } from 'vue'
import App from '@/App.vue'
import router from '@/app/router'

const application = createApp(App)

application.use(createPinia())
application.use(router)

application.mount('#app')
