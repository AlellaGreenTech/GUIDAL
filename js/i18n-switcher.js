// GUIDAL Language Switcher Component
// Provides a dropdown UI for switching between languages

(function() {
    'use strict';

    class LanguageSwitcher {
        constructor() {
            this.currentLang = window.i18n ? window.i18n.getCurrentLanguage() : 'en';
            this.languages = [
                { code: 'en', name: 'English', flag: '🇬🇧' },
                { code: 'es', name: 'Español', flag: '🇪🇸' },
                { code: 'ca', name: 'Català', flag: '🏴' }
            ];
        }

        // Create the switcher HTML element
        createSwitcher() {
            const container = document.createElement('div');
            container.className = 'language-switcher';
            container.innerHTML = this.getSwitcherHTML();

            // Add event listeners
            container.querySelector('.lang-dropdown-btn').addEventListener('click', () => {
                this.toggleDropdown();
            });

            // Close dropdown when clicking outside
            document.addEventListener('click', (e) => {
                if (!container.contains(e.target)) {
                    this.closeDropdown();
                }
            });

            return container;
        }

        // Generate the switcher HTML
        getSwitcherHTML() {
            const currentLangData = this.languages.find(l => l.code === this.currentLang) || this.languages[0];

            return `
                <button class="lang-dropdown-btn" aria-label="Select language">
                    <span class="lang-flag">${currentLangData.flag}</span>
                    <span class="lang-name">${currentLangData.name}</span>
                    <span class="lang-arrow">▼</span>
                </button>
                <div class="lang-dropdown-menu" id="lang-dropdown-menu">
                    ${this.languages.map(lang => `
                        <button
                            class="lang-option ${lang.code === this.currentLang ? 'active' : ''}"
                            onclick="window.languageSwitcher.selectLanguage('${lang.code}')"
                            data-lang="${lang.code}">
                            <span class="lang-flag">${lang.flag}</span>
                            <span class="lang-name">${lang.name}</span>
                            ${lang.code === this.currentLang ? '<span class="lang-check">✓</span>' : ''}
                        </button>
                    `).join('')}
                </div>
            `;
        }

        // Toggle dropdown visibility
        toggleDropdown() {
            const menu = document.getElementById('lang-dropdown-menu');
            if (menu) {
                menu.classList.toggle('show');
            }
        }

        // Close dropdown
        closeDropdown() {
            const menu = document.getElementById('lang-dropdown-menu');
            if (menu) {
                menu.classList.remove('show');
            }
        }

        // Handle language selection
        async selectLanguage(langCode) {
            if (langCode === this.currentLang) {
                this.closeDropdown();
                return;
            }

            // Change language using i18n system
            if (window.i18n) {
                await window.i18n.changeLanguage(langCode);
                this.currentLang = langCode;

                // Update the switcher UI
                this.updateSwitcherUI();

                // Close the dropdown
                this.closeDropdown();
            }
        }

        // Update the switcher UI after language change
        updateSwitcherUI() {
            const switcher = document.querySelector('.language-switcher');
            if (switcher) {
                const newHTML = this.getSwitcherHTML();
                switcher.innerHTML = newHTML;

                // Re-attach event listener to new button
                switcher.querySelector('.lang-dropdown-btn').addEventListener('click', () => {
                    this.toggleDropdown();
                });
            }
        }

        // Initialize the switcher in a container
        init(containerId = 'language-switcher-container') {
            // Try multiple container IDs (header first, then nav)
            const containerIds = ['header-language-switcher', containerId];
            let container = null;

            for (const id of containerIds) {
                container = document.getElementById(id);
                if (container) break;
            }

            if (container) {
                const switcher = this.createSwitcher();
                container.appendChild(switcher);
            } else {
                console.warn(`Language switcher container not found. Tried: ${containerIds.join(', ')}`);
            }

            // Listen for language change events
            window.addEventListener('languageChanged', (e) => {
                this.currentLang = e.detail.lang;
                this.updateSwitcherUI();
            });
        }

        // Auto-inject into header if it exists
        autoInject() {
            // Try to find common header locations
            const headerSelectors = [
                'header nav',
                '.header-nav',
                '.main-nav',
                'header',
                '.navbar'
            ];

            for (const selector of headerSelectors) {
                const header = document.querySelector(selector);
                if (header) {
                    const switcher = this.createSwitcher();
                    switcher.style.marginLeft = 'auto'; // Push to right side
                    header.appendChild(switcher);

                    // Listen for language change events
                    window.addEventListener('languageChanged', (e) => {
                        this.currentLang = e.detail.lang;
                        this.updateSwitcherUI();
                    });

                    return true;
                }
            }

            console.warn('Could not find suitable header to inject language switcher');
            return false;
        }
    }

    // Create global instance
    window.languageSwitcher = new LanguageSwitcher();

    // Auto-initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            // Try auto-inject, or look for container
            if (!window.languageSwitcher.autoInject()) {
                window.languageSwitcher.init();
            }
        });
    } else {
        if (!window.languageSwitcher.autoInject()) {
            window.languageSwitcher.init();
        }
    }

})();
