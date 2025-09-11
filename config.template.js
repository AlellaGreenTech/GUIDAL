// GUIDAL Configuration Template
// Copy this file to config.js and fill in your actual Supabase credentials

// Supabase Configuration
// Get these values from your Supabase project dashboard
const SUPABASE_CONFIG = {
    url: 'https://your-project-id.supabase.co',
    anonKey: 'your-anon-key-here'
};

// Application Configuration
const APP_CONFIG = {
    // Site settings
    siteName: 'GUIDAL',
    siteUrl: 'https://your-domain.com',
    
    // Features toggles
    features: {
        authentication: true,
        creditSystem: true,
        ecommerce: true,
        blog: true,
        realTimeUpdates: true
    },
    
    // Default settings
    defaults: {
        userType: 'student',
        creditsPerActivity: 5,
        maxParticipants: 25
    },
    
    // Email settings (for notifications)
    email: {
        supportEmail: 'support@allellagreentech.com',
        noreplyEmail: 'noreply@allellagreentech.com'
    }
};

// Export configuration
if (typeof window !== 'undefined') {
    window.SUPABASE_CONFIG = SUPABASE_CONFIG;
    window.APP_CONFIG = APP_CONFIG;
}