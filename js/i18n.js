// GUIDAL i18n (Internationalization) System
// Supports English, Spanish (Español), and Catalan (Català)

(function() {
    'use strict';

    class I18n {
        constructor() {
            this.currentLang = this.getStoredLanguage() || this.detectBrowserLanguage() || 'en';
            this.translations = {};
            this.fallbackLang = 'en';
            this.loadedLanguages = new Set();
        }

        // Detect browser language
        detectBrowserLanguage() {
            const browserLang = navigator.language || navigator.userLanguage;
            const langCode = browserLang.split('-')[0].toLowerCase();

            // Map browser language to supported languages
            const supportedLangs = ['en', 'es', 'ca'];
            return supportedLangs.includes(langCode) ? langCode : 'en';
        }

        // Get stored language from localStorage
        getStoredLanguage() {
            return localStorage.getItem('guidal_language');
        }

        // Set and store language
        setLanguage(langCode) {
            this.currentLang = langCode;
            localStorage.setItem('guidal_language', langCode);
            document.documentElement.setAttribute('lang', langCode);

            // Dispatch event for listeners
            window.dispatchEvent(new CustomEvent('languageChanged', { detail: { lang: langCode } }));
        }

        // Load translation file
        async loadLanguage(langCode) {
            if (this.loadedLanguages.has(langCode)) {
                return this.translations[langCode];
            }

            try {
                const response = await fetch(`/js/i18n/${langCode}.json`);
                if (!response.ok) {
                    throw new Error(`Failed to load language: ${langCode}`);
                }

                this.translations[langCode] = await response.json();
                this.loadedLanguages.add(langCode);
                return this.translations[langCode];
            } catch (error) {
                console.error(`Error loading language ${langCode}:`, error);

                // Load fallback if current language fails
                if (langCode !== this.fallbackLang && !this.loadedLanguages.has(this.fallbackLang)) {
                    return this.loadLanguage(this.fallbackLang);
                }

                return null;
            }
        }

        // Get translation by key path (e.g., "pumpkinPatch.checkout.title")
        t(keyPath, params = {}) {
            const keys = keyPath.split('.');
            let translation = this.translations[this.currentLang];

            // Try current language
            for (const key of keys) {
                if (translation && typeof translation === 'object') {
                    translation = translation[key];
                } else {
                    translation = undefined;
                    break;
                }
            }

            // Fallback to English if translation not found
            if (translation === undefined && this.currentLang !== this.fallbackLang) {
                translation = this.translations[this.fallbackLang];
                for (const key of keys) {
                    if (translation && typeof translation === 'object') {
                        translation = translation[key];
                    } else {
                        translation = keyPath; // Return key if not found
                        break;
                    }
                }
            }

            // Return key if still not found
            if (translation === undefined) {
                console.warn(`Translation not found: ${keyPath}`);
                return keyPath;
            }

            // Replace parameters in translation
            if (typeof translation === 'string' && Object.keys(params).length > 0) {
                return translation.replace(/\{\{(\w+)\}\}/g, (match, param) => {
                    return params[param] !== undefined ? params[param] : match;
                });
            }

            return translation;
        }

        // Initialize i18n system
        async init() {
            // Load current language
            await this.loadLanguage(this.currentLang);

            // Load fallback if different
            if (this.currentLang !== this.fallbackLang) {
                await this.loadLanguage(this.fallbackLang);
            }

            // Set document language
            document.documentElement.setAttribute('lang', this.currentLang);

            // Apply translations to page
            this.applyTranslations();

            return this;
        }

        // Apply translations to elements with data-i18n attribute
        applyTranslations() {
            const elements = document.querySelectorAll('[data-i18n]');

            elements.forEach(element => {
                const key = element.getAttribute('data-i18n');
                const translation = this.t(key);

                // Apply to appropriate attribute
                if (element.hasAttribute('data-i18n-placeholder')) {
                    element.setAttribute('placeholder', translation);
                } else if (element.hasAttribute('data-i18n-title')) {
                    element.setAttribute('title', translation);
                } else if (element.tagName === 'INPUT' && element.type === 'button') {
                    element.value = translation;
                } else {
                    element.textContent = translation;
                }
            });
        }

        // Get current language
        getCurrentLanguage() {
            return this.currentLang;
        }

        // Get available languages
        getAvailableLanguages() {
            return [
                { code: 'en', name: 'English', flag: '🇬🇧' },
                { code: 'es', name: 'Español', flag: '🇪🇸' },
                { code: 'ca', name: 'Català', flag: '🏴' }
            ];
        }

        // Change language and reload page translations
        async changeLanguage(langCode) {
            if (langCode === this.currentLang) {
                return;
            }

            await this.loadLanguage(langCode);
            this.setLanguage(langCode);
            this.applyTranslations();
        }
    }

    // Create global instance
    window.i18n = new I18n();

    // Auto-initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            window.i18n.init();
        });
    } else {
        window.i18n.init();
    }

})();
