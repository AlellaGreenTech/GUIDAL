// Auth Navigation - Dynamic Login/Logout Button Handler
// This script manages the login/register button and user menu display

(function() {
    'use strict';

    async function initAuthNav() {
        // Wait for Supabase client to be available
        if (typeof window.supabaseClient === 'undefined') {
            console.warn('⚠️ Supabase client not loaded, auth nav will not be dynamic');
            return;
        }

        try {
            // Wait for session to be ready
            await new Promise(resolve => setTimeout(resolve, 100));

            // Get current user session
            const { data: { session } } = await window.supabaseClient.auth.getSession();
            const user = session?.user;

            // Find the login button
            const loginBtn = document.querySelector('.login-btn');
            if (!loginBtn) {
                console.warn('⚠️ Login button not found in navigation');
                return;
            }

            const loginListItem = loginBtn.closest('li');

            if (user) {
                // User is logged in - replace login button with user menu
                console.log('✅ User logged in:', user.email);

                // Get user profile for display name
                let displayName = user.email.split('@')[0]; // Default to email username
                let profile = null;

                try {
                    const { data } = await window.supabaseClient
                        .from('profiles')
                        .select('full_name, user_type')
                        .eq('id', user.id)
                        .single();

                    profile = data;
                    if (profile && profile.full_name) {
                        displayName = profile.full_name;
                    }
                } catch (profileError) {
                    console.warn('Could not fetch profile:', profileError);
                }

                // Check if user is admin or cashier
                const isAdmin = profile && (profile.user_type === 'admin' || profile.user_type === 'staff');
                const isCashier = profile && profile.user_type === 'cashier';

                // Get paths based on current location
                const profilePath = getProfilePath();
                const adminPath = getAdminPath();
                const cashierPath = getCashierPath();

                // Create user menu HTML
                loginListItem.innerHTML = `
                    <style>
                        .user-menu-container {
                            position: relative;
                            display: flex;
                            align-items: center;
                        }
                        .user-menu {
                            display: flex;
                            align-items: center;
                            color: white;
                            text-decoration: none;
                            padding: 0.5rem 1rem;
                            cursor: pointer;
                        }
                        .user-menu:hover {
                            background: rgba(255,255,255,0.1);
                            border-radius: 4px;
                        }
                        .user-dropdown {
                            position: fixed !important;
                            top: 60px !important;
                            right: 20px !important;
                            background: white !important;
                            border-radius: 8px !important;
                            box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important;
                            min-width: 180px !important;
                            z-index: 99999 !important;
                            display: none !important;
                            visibility: hidden !important;
                            opacity: 0 !important;
                        }
                        .user-dropdown.show {
                            display: block !important;
                            visibility: visible !important;
                            opacity: 1 !important;
                        }
                        .user-dropdown a {
                            display: flex;
                            align-items: center;
                            gap: 0.75rem;
                            padding: 0.75rem 1rem;
                            color: #333;
                            text-decoration: none;
                            transition: background 0.2s;
                        }
                        .user-dropdown a:first-child {
                            border-radius: 8px 8px 0 0;
                        }
                        .user-dropdown a:last-child {
                            border-radius: 0 0 8px 8px;
                        }
                        .user-dropdown a:hover {
                            background: #f5f5f5;
                        }
                        .user-dropdown svg {
                            fill: #666;
                        }
                    </style>
                    <div class="user-menu-container">
                        <a href="#" class="user-menu" id="userMenuButton">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 8px;">
                                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/>
                            </svg>
                            <span>${displayName}</span>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-left: 4px;">
                                <path d="M7 10l5 5 5-5z"/>
                            </svg>
                        </a>
                        <div class="user-dropdown" id="userDropdown">
                            <a href="${profilePath}">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                                </svg>
                                Profile
                            </a>
                            ${isAdmin ? `
                            <a href="${adminPath}">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/>
                                </svg>
                                Admin
                            </a>` : ''}
                            ${isCashier ? `
                            <a href="${cashierPath}">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M21.41 11.58l-9-9C12.05 2.22 11.55 2 11 2H4c-1.1 0-2 .9-2 2v7c0 .55.22 1.05.59 1.42l9 9c.36.36.86.58 1.41.58.55 0 1.05-.22 1.41-.59l7-7c.37-.36.59-.86.59-1.41 0-.55-.23-1.06-.59-1.42zM5.5 7C4.67 7 4 6.33 4 5.5S4.67 4 5.5 4 7 4.67 7 5.5 6.33 7 5.5 7z"/>
                                </svg>
                                Cashier Payments
                            </a>` : ''}
                            <a href="#" class="logout-link">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z"/>
                                </svg>
                                Logout
                            </a>
                        </div>
                    </div>
                `;

                // Attach event listeners after DOM is updated
                setTimeout(() => {
                    const logoutLink = document.querySelector('.logout-link');
                    if (logoutLink) {
                        logoutLink.addEventListener('click', window.logoutUser);
                    }
                }, 0);
            } else {
                // User is not logged in - ensure login button is visible
                console.log('👤 No user logged in');
            }
        } catch (error) {
            console.error('❌ Error initializing auth nav:', error);
        }
    }

    // Helper to get base path (handles being in subdirectories)
    function getBasePath() {
        const path = window.location.pathname;
        // If we're in /pages/, /admin/, or /events/, go up one level
        if (path.includes('/pages/') || path.includes('/admin/') || path.includes('/events/')) {
            return '../';
        }
        // If we're at root
        return '';
    }

    // Helper to get profile path
    function getProfilePath() {
        const path = window.location.pathname;
        // If already in /pages/, just go to profile.html
        if (path.includes('/pages/')) {
            return 'profile.html';
        }
        // If in /admin/ or /events/, go up to pages
        if (path.includes('/admin/') || path.includes('/events/')) {
            return '../pages/profile.html';
        }
        // If at root, go to pages/profile.html
        return 'pages/profile.html';
    }

    // Helper to get admin path
    function getAdminPath() {
        const path = window.location.pathname;
        // If in /pages/auth/ or /pages/, go up to admin
        if (path.includes('/pages/')) {
            return '../admin/pumpkin-orders.html';
        }
        // If in /admin/, stay in admin
        if (path.includes('/admin/')) {
            return 'pumpkin-orders.html';
        }
        // If at root or in /events/, go to admin
        return 'admin/pumpkin-orders.html';
    }

    // Helper to get cashier path
    function getCashierPath() {
        const path = window.location.pathname;
        // If in /pages/, go up to cashier
        if (path.includes('/pages/')) {
            return '../cashier/payments.html';
        }
        // If in /admin/, go up to cashier
        if (path.includes('/admin/')) {
            return '../cashier/payments.html';
        }
        // If in /cashier/, stay in cashier
        if (path.includes('/cashier/')) {
            return 'payments.html';
        }
        // If at root or in /events/, go to cashier
        return 'cashier/payments.html';
    }

    // Handle all dropdown interactions with a single document click listener
    document.addEventListener('click', function(e) {
        const menuButton = document.getElementById('userMenuButton');
        const dropdown = document.getElementById('userDropdown');

        if (!menuButton || !dropdown) return;

        // Check if click was on the menu button or its children
        if (e.target === menuButton || menuButton.contains(e.target)) {
            e.preventDefault();
            // Toggle the dropdown
            const isCurrentlyShown = dropdown.classList.contains('show');
            if (isCurrentlyShown) {
                dropdown.classList.remove('show');
                console.log('❌ Dropdown closed');
            } else {
                dropdown.classList.add('show');
                console.log('✅ Dropdown opened');
            }
        } else {
            // Click was outside - close if open
            if (dropdown.classList.contains('show')) {
                dropdown.classList.remove('show');
                console.log('🚪 Closed dropdown (clicked outside)');
            }
        }
    });

    // Logout function
    window.logoutUser = async function(event) {
        event.preventDefault();

        if (!confirm('Are you sure you want to logout?')) {
            return;
        }

        try {
            const { error } = await window.supabaseClient.auth.signOut();
            if (error) throw error;

            console.log('✅ Logged out successfully');

            // Redirect to home page (activities is the main landing)
            const path = window.location.pathname;
            if (path.includes('/pages/')) {
                window.location.href = '../index.html';
            } else if (path.includes('/admin/') || path.includes('/events/')) {
                window.location.href = '../pages/activities.html';
            } else {
                window.location.href = 'index.html';
            }
        } catch (error) {
            console.error('❌ Logout error:', error);
            alert('Error logging out. Please try again.');
        }
    };

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAuthNav);
    } else {
        // DOM already loaded
        initAuthNav();
    }
})();
