import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'
import { installFontAwesome } from './plugins/fontawesome'

const app = createApp(App)

app.use(createPinia())
app.use(router)
installFontAwesome(app)

app.mount('#app')
