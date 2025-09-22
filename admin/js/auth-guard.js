// Admin Authentication Guard
// This script ensures only authenticated admin users can access admin pages

class AdminAuthGuard {
    constructor() {
        this.init();
    }

    async init() {
        try {
            console.log('🛡️ Checking admin authentication...');

            // Check if we're on the auth page - if so, don't redirect
            if (window.location.pathname.includes('auth.html')) {
                return;
            }

            // Get current session
            const { data: { session }, error } = await supabaseClient.auth.getSession();

            if (!session) {
                console.log('❌ No session found - redirecting to login');
                this.redirectToLogin();
                return;
            }

            // Check if user has admin privileges
            const isAdmin = await this.checkAdminPrivileges(session.user);

            if (!isAdmin) {
                console.log('❌ User lacks admin privileges - redirecting to login');
                await supabaseClient.auth.signOut();
                this.redirectToLogin();
                return;
            }

            console.log('✅ Admin authentication verified');

            // Setup logout functionality if not already set
            this.setupLogoutButton();

            // Listen for auth state changes
            supabaseClient.auth.onAuthStateChange((event, session) => {
                if (event === 'SIGNED_OUT' || !session) {
                    this.redirectToLogin();
                }
            });

        } catch (error) {
            console.error('❌ Auth guard error:', error);
            this.redirectToLogin();
        }
    }

    async checkAdminPrivileges(user) {
        try {
            const { data, error } = await supabaseClient
                .from('user_profiles')
                .select('role, full_name')
                .eq('user_id', user.id)
                .single();

            if (error) {
                console.error('Error checking user role:', error);
                return false;
            }

            // Store user info for display
            if (data) {
                sessionStorage.setItem('adminUser', JSON.stringify({
                    email: user.email,
                    name: data.full_name || user.email,
                    role: data.role
                }));
            }

            return data && ['admin', 'staff'].includes(data.role);

        } catch (error) {
            console.error('Error checking admin privileges:', error);
            return false;
        }
    }

    redirectToLogin() {
        // Clear any stored admin data
        sessionStorage.removeItem('adminUser');

        // Redirect to login page
        window.location.href = 'auth.html';
    }

    setupLogoutButton() {
        // Add logout button to admin pages if it doesn't exist
        const existingLogout = document.getElementById('adminLogout');
        if (existingLogout) return;

        // Find the admin nav and add logout button
        const adminNav = document.querySelector('.admin-nav ul');
        if (adminNav) {
            const logoutItem = document.createElement('li');
            logoutItem.innerHTML = `
                <a href="#" id="adminLogout" style="color: #dc3545;">
                    🚪 Logout
                </a>
            `;
            adminNav.appendChild(logoutItem);

            // Add logout functionality
            document.getElementById('adminLogout').addEventListener('click', async (e) => {
                e.preventDefault();
                await this.logout();
            });
        }

        // Also add user info display
        this.displayUserInfo();
    }

    displayUserInfo() {
        const adminUser = JSON.parse(sessionStorage.getItem('adminUser') || '{}');

        if (adminUser.name) {
            // Add user info to header if not already present
            const adminHeader = document.querySelector('.admin-header .container');
            const existingUserInfo = document.getElementById('adminUserInfo');

            if (adminHeader && !existingUserInfo) {
                const userInfoDiv = document.createElement('div');
                userInfoDiv.id = 'adminUserInfo';
                userInfoDiv.style.cssText = 'margin-top: 0.5rem; opacity: 0.9; font-size: 0.9rem;';
                userInfoDiv.innerHTML = `
                    Welcome back, <strong>${adminUser.name}</strong>
                    <span style="opacity: 0.7;">(${adminUser.role})</span>
                `;
                adminHeader.appendChild(userInfoDiv);
            }
        }
    }

    async logout() {
        try {
            console.log('🚪 Logging out admin user...');

            const { error } = await supabaseClient.auth.signOut();

            if (error) {
                console.error('Logout error:', error);
            }

            // Clear stored data
            sessionStorage.removeItem('adminUser');

            // Redirect to login page
            this.redirectToLogin();

        } catch (error) {
            console.error('Logout error:', error);
            // Force redirect even if logout fails
            this.redirectToLogin();
        }
    }
}

// Auto-initialize auth guard when supabase client is available
document.addEventListener('DOMContentLoaded', function() {
    // Wait for supabaseClient to be available
    const checkForSupabase = () => {
        if (typeof supabaseClient !== 'undefined') {
            new AdminAuthGuard();
        } else {
            // Try again in 100ms if supabase isn't loaded yet
            setTimeout(checkForSupabase, 100);
        }
    };

    checkForSupabase();
});

// Export for use in other scripts
window.AdminAuthGuard = AdminAuthGuard;