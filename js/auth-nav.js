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
            // Get current user
            const { data: { user } } = await window.supabaseClient.auth.getUser();

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

                // Check if user is admin
                const isAdmin = profile && (profile.user_type === 'admin' || profile.user_type === 'staff');

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
                            position: absolute;
                            top: 100%;
                            right: 0;
                            background: white;
                            border-radius: 8px;
                            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
                            min-width: 180px;
                            margin-top: 0.5rem;
                            z-index: 1000;
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
                        <a href="#" class="user-menu" onclick="toggleUserDropdown(event); return false;">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" style="margin-right: 8px;">
                                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/>
                            </svg>
                            <span>${displayName}</span>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="margin-left: 4px;">
                                <path d="M7 10l5 5 5-5z"/>
                            </svg>
                        </a>
                        <div class="user-dropdown" id="userDropdown" style="display: none;">
                            <a href="${getProfilePath()}">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                                </svg>
                                Profile
                            </a>
                            ${isAdmin ? `
                            <a href="${getAdminPath()}">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8z"/>
                                </svg>
                                Admin
                            </a>` : ''}
                            <a href="#" onclick="logoutUser(event)">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z"/>
                                </svg>
                                Logout
                            </a>
                        </div>
                    </div>
                `;
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
        // If already in /pages/auth/, just go to profile.html
        if (path.includes('/pages/auth/')) {
            return 'profile.html';
        }
        // If in /pages/, go to auth/profile.html
        if (path.includes('/pages/')) {
            return 'auth/profile.html';
        }
        // If at root or in /admin/ or /events/, go to pages/auth/profile.html
        return 'pages/auth/profile.html';
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

    // Toggle user dropdown
    window.toggleUserDropdown = function(event) {
        event.preventDefault();
        event.stopPropagation();
        const dropdown = document.getElementById('userDropdown');
        if (dropdown) {
            dropdown.style.display = dropdown.style.display === 'none' ? 'block' : 'none';
        }
    };

    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
        const dropdown = document.getElementById('userDropdown');
        if (dropdown && dropdown.style.display === 'block') {
            if (!e.target.closest('.user-menu-container')) {
                dropdown.style.display = 'none';
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
