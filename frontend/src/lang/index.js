// src/lang/index.js
import de from './translations/de.json';
import en from './translations/en.json';
import {createI18n} from "vue-i18n";

function getStoredLanguage() {
  let initialLang = localStorage.getItem('wgLang');
  if (!initialLang) {
    initialLang = "en"
  }
  return initialLang
}

// Create i18n instance with options
const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  allowComposition: true,
  locale: getStoredLanguage(), // set locale
  fallbackLocale: "en", // set fallback locale
  messages: {
    "de": de,
    "en": en
  }
});

export default i18n