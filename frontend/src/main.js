import { createApp } from "vue";
import { createPinia } from "pinia";

import App from "./App.vue";
import router from "./router";

import i18n from "./lang";

import Notifications from '@kyvg/vue3-notification'

// Bootstrap (and theme)
//import "bootstrap/dist/css/bootstrap.min.css"
import "bootswatch/dist/lux/bootstrap.min.css";
import "bootstrap";
import "./assets/base.css";

// Fontawesome
import "@fortawesome/fontawesome-free/js/all.js"

// Flags
import "flag-icons/css/flag-icons.min.css"

// Syntax Highlighting
import 'prismjs'
import 'prismjs/themes/prism-okaidia.css'

const app = createApp(App);

app.use(i18n)
app.use(createPinia());
app.use(router);
app.use(Notifications);

app.config.globalProperties.$filters = {
  truncate(value, maxLength, suffix) {
    suffix = suffix || '...'
    if (value.length > maxLength) {
      return value.substring(0, maxLength) + suffix;
    } else {
      return value;
    }
  }
}

app.mount("#app");
