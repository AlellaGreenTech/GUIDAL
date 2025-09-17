// Privacy Configuration System for School Visits
// Determines which schools require privacy mode (no login, anonymous data collection)

const PRIVACY_CONFIG = {
    // Schools that enforce privacy mode
    privacySchools: [
        'prague',
        'international-school-prague',
        // Add more schools here as needed
    ],

    // Schools that require standard login/registration
    standardSchools: [
        'bfis',
        'benjamin-franklin',
        'st-george',
        // Add more schools here as needed
    ],

    // Default settings
    defaultMode: 'standard' // 'privacy' or 'standard'
};

// Utility functions for privacy mode detection
const PrivacyManager = {

    // Check if current visit is in privacy mode
    isPrivacyMode: function(visitType = null) {
        // Auto-detect from URL if not provided
        if (!visitType) {
            visitType = this.getVisitTypeFromURL();
        }

        return PRIVACY_CONFIG.privacySchools.includes(visitType);
    },

    // Extract visit type from current URL
    getVisitTypeFromURL: function() {
        const path = window.location.pathname;

        // Check for Prague patterns
        if (path.includes('prague') || path.includes('international-school-prague')) {
            return 'prague';
        }

        // Check for BFIS patterns
        if (path.includes('benjamin-franklin') || path.includes('bfis')) {
            return 'bfis';
        }

        // Check for St. George patterns
        if (path.includes('st-george')) {
            return 'st-george';
        }

        // Check URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        const visitParam = urlParams.get('visit');
        if (visitParam) {
            return visitParam;
        }

        return 'unknown';
    },

    // Get privacy settings for a visit type
    getPrivacySettings: function(visitType) {
        const isPrivacy = this.isPrivacyMode(visitType);

        return {
            visitType: visitType,
            privacyMode: isPrivacy,
            requiresLogin: !isPrivacy,
            allowsAnonymousData: isPrivacy,
            showPrivacyNotice: isPrivacy,
            dataRetention: isPrivacy ? 'minimal' : 'standard'
        };
    },

    // Initialize privacy mode for current page
    initializePrivacyMode: function() {
        const visitType = this.getVisitTypeFromURL();
        const settings = this.getPrivacySettings(visitType);

        console.log('Privacy settings:', settings);

        // Store in global scope for other scripts
        window.PRIVACY_SETTINGS = settings;

        return settings;
    }
};

// Auto-initialize when script loads
if (typeof window !== 'undefined') {
    document.addEventListener('DOMContentLoaded', function() {
        PrivacyManager.initializePrivacyMode();
    });
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { PRIVACY_CONFIG, PrivacyManager };
}