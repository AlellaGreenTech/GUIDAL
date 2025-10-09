// Analytics Tracker for GUIDAL
// Tracks button clicks, page views, and other user interactions

(function() {
    'use strict';

    // Configuration
    const SUPABASE_URL = 'https://lmsuyhzcmgdpjynosxvp.supabase.co';
    const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtc3V5aHpjbWdkcGp5bm9zeHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NzM5NjksImV4cCI6MjA3MzI0OTk2OX0.rRpHs_0ZLW3erdFnm2SwFTAmyQJYRMpcSlNzMBlcq4U';

    // Generate or retrieve session ID
    function getSessionId() {
        let sessionId = sessionStorage.getItem('guidal_session_id');
        if (!sessionId) {
            sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            sessionStorage.setItem('guidal_session_id', sessionId);
        }
        return sessionId;
    }

    // Track an event
    async function trackEvent(eventType, eventCategory, eventLabel, eventValue = null) {
        try {
            const response = await fetch(`${SUPABASE_URL}/rest/v1/analytics_events`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'apikey': SUPABASE_ANON_KEY,
                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                    'Prefer': 'return=minimal'
                },
                body: JSON.stringify({
                    event_type: eventType,
                    event_category: eventCategory,
                    event_label: eventLabel,
                    event_value: eventValue,
                    page_url: window.location.pathname,
                    user_session_id: getSessionId(),
                    user_agent: navigator.userAgent,
                    created_at: new Date().toISOString()
                })
            });

            if (!response.ok) {
                console.error('Analytics tracking failed:', response.statusText);
            }
        } catch (error) {
            console.error('Error tracking event:', error);
        }
    }

    // Track page view on load
    function trackPageView() {
        trackEvent('page_view', 'navigation', document.title, window.location.pathname);
    }

    // Track button clicks
    function trackButtonClick(button) {
        const buttonText = button.textContent.trim() || button.getAttribute('aria-label') || 'Unknown Button';
        const buttonId = button.id || button.className || 'unknown';
        const category = button.getAttribute('data-analytics-category') || 'button';
        const label = button.getAttribute('data-analytics-label') || buttonText;

        trackEvent('button_click', category, label, buttonId);
    }

    // Track link clicks
    function trackLinkClick(link) {
        const linkText = link.textContent.trim() || link.getAttribute('aria-label') || 'Unknown Link';
        const href = link.getAttribute('href') || '';
        const category = link.getAttribute('data-analytics-category') || 'link';
        const label = link.getAttribute('data-analytics-label') || linkText;

        trackEvent('link_click', category, label, href);
    }

    // Track form submissions
    function trackFormSubmit(form) {
        const formName = form.getAttribute('name') || form.id || 'Unknown Form';
        const category = form.getAttribute('data-analytics-category') || 'form';
        const label = form.getAttribute('data-analytics-label') || formName;

        trackEvent('form_submit', category, label, formName);
    }

    // Initialize tracking
    function initAnalytics() {
        // Track initial page view
        trackPageView();

        // Track all button clicks
        document.addEventListener('click', function(e) {
            const target = e.target;

            // Check if clicked element is a button or inside a button
            const button = target.closest('button');
            if (button) {
                trackButtonClick(button);
                return;
            }

            // Check if clicked element is a link or inside a link
            const link = target.closest('a');
            if (link) {
                trackLinkClick(link);
                return;
            }
        });

        // Track form submissions
        document.addEventListener('submit', function(e) {
            const form = e.target;
            if (form && form.tagName === 'FORM') {
                trackFormSubmit(form);
            }
        });

        // Track specific important actions
        // BOOK buttons on activities page
        const bookButtons = document.querySelectorAll('[data-analytics-track="booking"]');
        bookButtons.forEach(button => {
            button.addEventListener('click', function() {
                const activityName = button.getAttribute('data-activity-name') || 'Unknown Activity';
                trackEvent('button_click', 'booking', `BOOK: ${activityName}`, activityName);
            });
        });

        // PayPal payment button
        const paypalButtons = document.querySelectorAll('[data-analytics-track="payment"]');
        paypalButtons.forEach(button => {
            button.addEventListener('click', function() {
                trackEvent('button_click', 'checkout', 'PayPal Payment Button', 'paypal');
            });
        });
    }

    // Expose public API
    window.GuidalAnalytics = {
        track: trackEvent,
        trackPageView: trackPageView,
        trackButtonClick: function(buttonText, category = 'button') {
            trackEvent('button_click', category, buttonText);
        },
        trackBooking: function(activityName) {
            trackEvent('button_click', 'booking', `BOOK: ${activityName}`, activityName);
        },
        trackCheckout: function(step) {
            trackEvent('checkout_step', 'checkout', step);
        },
        trackPayment: function(method) {
            trackEvent('payment_initiated', 'checkout', method);
        }
    };

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAnalytics);
    } else {
        initAnalytics();
    }

})();
