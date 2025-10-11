// Analytics Tracker for GUIDAL
// Tracks button clicks, page views, and other user interactions

(function() {
    'use strict';

    // Configuration
    const SUPABASE_URL = 'https://lmsuyhzcmgdpjynosxvp.supabase.co';
    const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtc3V5aHpjbWdkcGp5bm9zeHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NzM5NjksImV4cCI6MjA3MzI0OTk2OX0.rRpHs_0ZLW3erdFnm2SwFTAmyQJYRMpcSlNzMBlcq4U';

    // Session and visitor tracking
    let pageLoadTime = Date.now();
    let lastActivityTime = Date.now();

    // Generate or retrieve session ID
    function getSessionId() {
        let sessionId = sessionStorage.getItem('guidal_session_id');
        if (!sessionId) {
            sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            sessionStorage.setItem('guidal_session_id', sessionId);
        }
        return sessionId;
    }

    // Generate or retrieve visitor ID (persistent across sessions)
    function getVisitorId() {
        let visitorId = localStorage.getItem('guidal_visitor_id');
        if (!visitorId) {
            visitorId = 'vis_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            localStorage.setItem('guidal_visitor_id', visitorId);
        }
        return visitorId;
    }

    // Check if returning visitor
    function isReturningVisitor() {
        return localStorage.getItem('guidal_has_visited') === 'true';
    }

    // Mark as visited
    function markAsVisited() {
        localStorage.setItem('guidal_has_visited', 'true');
    }

    // Detect device type
    function getDeviceType() {
        const width = window.innerWidth;
        if (width < 768) return 'mobile';
        if (width < 1024) return 'tablet';
        return 'desktop';
    }

    // Detect browser
    function getBrowser() {
        const ua = navigator.userAgent;
        if (ua.indexOf('Chrome') > -1) return 'Chrome';
        if (ua.indexOf('Safari') > -1) return 'Safari';
        if (ua.indexOf('Firefox') > -1) return 'Firefox';
        if (ua.indexOf('Edge') > -1) return 'Edge';
        return 'Other';
    }

    // Detect OS
    function getOS() {
        const ua = navigator.userAgent;
        if (ua.indexOf('Win') > -1) return 'Windows';
        if (ua.indexOf('Mac') > -1) return 'macOS';
        if (ua.indexOf('Linux') > -1) return 'Linux';
        if (ua.indexOf('Android') > -1) return 'Android';
        if (ua.indexOf('iOS') > -1 || ua.indexOf('iPhone') > -1) return 'iOS';
        return 'Other';
    }

    // Track an event
    async function trackEvent(eventType, eventCategory, eventName, eventValue = null, metadata = {}) {
        try {
            lastActivityTime = Date.now();

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
                    event_name: eventName,
                    event_value: eventValue,
                    page_url: window.location.href,
                    page_title: document.title,
                    referrer_url: document.referrer || null,
                    session_id: getSessionId(),
                    visitor_id: getVisitorId(),
                    is_returning_visitor: isReturningVisitor(),
                    user_agent: navigator.userAgent,
                    device_type: getDeviceType(),
                    browser: getBrowser(),
                    os: getOS(),
                    screen_resolution: `${window.screen.width}x${window.screen.height}`,
                    metadata: Object.keys(metadata).length > 0 ? metadata : null
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
        markAsVisited();
        trackEvent('page_view', 'navigation', document.title, null, {
            path: window.location.pathname,
            query: window.location.search
        });
    }

    // Track time on page when leaving
    function trackPageExit() {
        const timeOnPage = Math.round((Date.now() - pageLoadTime) / 1000); // seconds
        const timeSinceActivity = Math.round((Date.now() - lastActivityTime) / 1000);

        // Only track if user was actually engaged (activity in last 5 minutes)
        if (timeSinceActivity < 300) {
            trackEvent('time_on_page', 'engagement', document.title, timeOnPage, {
                time_since_last_activity: timeSinceActivity
            });
        } else {
            // User was idle - might be a bounce
            trackEvent('bounce', 'engagement', document.title, timeOnPage, {
                idle_time: timeSinceActivity
            });
        }
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

        // Track page exit
        window.addEventListener('beforeunload', trackPageExit);
        window.addEventListener('pagehide', trackPageExit);

        // Track user activity to update lastActivityTime
        ['mousemove', 'keydown', 'scroll', 'touchstart'].forEach(eventType => {
            document.addEventListener(eventType, () => {
                lastActivityTime = Date.now();
            }, { passive: true });
        });

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
                trackEvent('button_click', 'booking', `BOOK: ${activityName}`, null, { activity: activityName });
            });
        });

        // PayPal payment button
        const paypalButtons = document.querySelectorAll('[data-analytics-track="payment"]');
        paypalButtons.forEach(button => {
            button.addEventListener('click', function() {
                trackEvent('button_click', 'checkout', 'PayPal Payment Button', null, { method: 'paypal' });
            });
        });
    }

    // Expose public API
    window.GuidalAnalytics = {
        // Core tracking
        track: trackEvent,
        trackPageView: trackPageView,

        // Convenience methods
        trackButtonClick: function(buttonText, category = 'button') {
            trackEvent('button_click', category, buttonText);
        },
        trackBooking: function(activityName) {
            trackEvent('button_click', 'booking', `BOOK: ${activityName}`, null, { activity: activityName });
        },
        trackCheckout: function(step) {
            trackEvent('checkout_step', 'checkout', step);
        },
        trackPayment: function(method) {
            trackEvent('payment_initiated', 'checkout', method);
        },

        // Email tracking
        trackEmailEntered: function() {
            trackEvent('email_entered', 'conversion', 'Email captured');
        },
        trackAbandonedCart: function(cartTotal, items) {
            trackEvent('abandoned_cart', 'conversion', 'Cart abandoned', cartTotal, { items });
        },

        // Booking lifecycle
        trackBookingComplete: function(orderId, orderTotal) {
            trackEvent('booking_complete', 'conversion', 'Booking completed', orderTotal, { order_id: orderId });
        },
        trackPaymentComplete: function(orderId, orderTotal, method) {
            trackEvent('payment_completed', 'conversion', 'Payment successful', orderTotal, {
                order_id: orderId,
                payment_method: method
            });
        },

        // Error tracking
        trackError: function(errorType, errorMessage) {
            trackEvent('error', 'error', errorType, null, { message: errorMessage });
        },

        // Get session info
        getSessionId: getSessionId,
        getVisitorId: getVisitorId
    };

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAnalytics);
    } else {
        initAnalytics();
    }

})();
