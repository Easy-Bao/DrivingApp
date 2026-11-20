import '@web/ui/styles/theme.css'
import '@/assets/styles/main.css'

import { createApp } from 'vue'
import App from '@/App.vue'
import router from '@/app/router'

const application = createApp(App)

application.use(router)

application.mount('#app')
