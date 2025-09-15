// GUIDAL - Guide to All at Alella Green Tech
console.log('GUIDAL loaded successfully!');

// Smooth scrolling for anchor links
document.addEventListener('DOMContentLoaded', function() {
    // Smooth scrolling for internal links
    const links = document.querySelectorAll('a[href^="#"]');
    
    links.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add animation to station cards on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe all station cards and activity cards
    const cards = document.querySelectorAll('.station-card, .activity, .info-card');
    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });
});

// Future features placeholder functions
function initializeEventSystem() {
    // TODO: Implement event signup system
    console.log('Event system initialization planned');
}

function initializeCreditSystem() {
    // TODO: Implement credit earning/spending system
    console.log('Credit system initialization planned');
}

function initializeShopSystem() {
    // TODO: Implement online shop functionality
    console.log('Shop system initialization planned');
}

// GUIDAL Application - Database-Integrated Version
class GuidalApp {
    constructor() {
        this.currentUser = null;
        this.activities = [];
        this.activityTypes = [];
        this.init();
    }

    async init() {
        // Check authentication status
        await this.checkAuthStatus();

        // Load initial data
        await this.loadActivityTypes();
        await this.loadActivities();

        // Set up event listeners
        this.setupEventListeners();
        this.setupModalEventListeners();
        this.setupAuthListener();
    }

    async checkAuthStatus() {
        try {
            this.currentUser = await GuidalDB.getCurrentUser();
            if (this.currentUser) {
                this.updateUIForLoggedInUser();
            } else {
                this.updateUIForLoggedOutUser();
            }
        } catch (error) {
            console.error('Auth status check failed:', error);
            this.currentUser = null;
            this.updateUIForLoggedOutUser();
        }
    }

    async loadActivityTypes() {
        // Simple predefined activity types since we're not storing them separately
        this.activityTypes = [
            { slug: 'school-visits', name: 'School Visits' },
            { slug: 'workshops', name: 'Workshops' },
            { slug: 'events', name: 'Events' },
            { slug: 'lunches', name: 'Special Lunches' }
        ];
        this.populateActivityTypeFilter();
    }

    async loadActivities(filters = {}) {
        try {
            console.log('🔍 Loading activities with filters:', filters);
            this.activities = await GuidalDB.getActivities(filters);
            console.log('✅ Activities loaded:', this.activities.length, 'activities');
            console.log('📊 First activity sample:', this.activities[0]);
            this.renderActivities();
        } catch (error) {
            console.error('❌ Error loading activities:', error);
            this.activities = [];
            this.renderActivities();
        }
    }

    populateActivityTypeFilter() {
        const filterSelect = document.getElementById('activity-filter');
        if (!filterSelect || !this.activityTypes) return;

        // Clear existing options except "All Activities"
        filterSelect.innerHTML = '<option value="all">All Activities</option>';
        
        this.activityTypes.forEach(type => {
            const option = document.createElement('option');
            option.value = type.slug;
            option.textContent = type.name;
            filterSelect.appendChild(option);
        });
    }

    renderActivities() {
        const activityGrid = document.getElementById('activity-grid');
        if (!activityGrid) return;

        // Always clear existing content and use database data
        activityGrid.innerHTML = '';

        if (this.activities && this.activities.length > 0) {
            this.activities.forEach(activity => {
                const card = this.createActivityCard(activity);
                activityGrid.appendChild(card);
            });
        } else {
            // Show loading or no data message
            activityGrid.innerHTML = `
                <div class="no-activities-message">
                    <p>Loading activities...</p>
                    <p>If activities don't appear, please check your database connection.</p>
                </div>
            `;
        }
    }

    createActivityCard(activity) {
        const card = document.createElement('div');
        card.className = 'activity-card';

        // Get activity type from database structure (now joined)
        const activityType = activity.activity_type || (this.activityTypes.find(type =>
            type.id === activity.activity_type_id
        ));
        const activityTypeSlug = activityType ? activityType.slug : 'other';

        card.setAttribute('data-type', activityTypeSlug);
        card.setAttribute('data-date', activity.date_time || 'TBD');

        const dateDisplay = activity.date_time 
            ? new Date(activity.date_time).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })
            : 'Date: TBD';

        const participantInfo = activity.max_participants
            ? `${activity.max_participants} ${activityTypeSlug === 'school-visits' ? 'students' : 'participants'}`
            : 'Open to all';

        // Get GREENs info for activity
        const greensInfo = this.getGREENsInfo(activity);

        // Get activity image
        const activityImage = this.getActivityImage(activity);

        card.innerHTML = `
            <div class="activity-image">
                ${activityImage}
            </div>
            <div class="activity-info">
                <div class="activity-type">${activityType ? activityType.name : 'Activity'}</div>
                <h3>${activity.title}</h3>
                <p class="activity-date">
                    ${dateDisplay}
                    ${this.getCompletedBadge(activity)}
                </p>
                <p class="activity-description">${activity.description}</p>
                <div class="activity-details">
                    <span class="participants">${participantInfo}</span>
                    <span class="duration">${this.formatActivityDuration(activity)}</span>
                </div>
                ${greensInfo}
                ${this.getActivityButton(activity)}
            </div>
        `;

        return card;
    }

    getActivityImage(activity) {
        // Use featured_image from database if available
        const imageSrc = activity.featured_image || this.getDefaultImageForActivity(activity);
        
        if (imageSrc) {
            return `<img src="${imageSrc}" alt="${activity.title}" class="activity-photo" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                    <div class="image-placeholder" style="display:none;">
                        <p>${this.getActivityIcon(activity.activity_type)} ${activity.activity_type}</p>
                    </div>`;
        } else {
            return `<div class="image-placeholder">
                        <p>${this.getActivityIcon(activity.activity_type)} ${activity.activity_type}</p>
                    </div>`;
        }
    }

    getDefaultImageForActivity(activity) {
        // Fallback images when database doesn't have featured_image
        const defaultImages = {
            'Benjamin Franklin International School': 'images/school-visit-planting.png',
            'International School of Prague': 'images/prague-alella-bridge-vineyard.png',
            'Brainstorming Lunch': 'images/brainstorming-lunch.png',
            'Build Your Own Ram Pump': 'images/workshop-ram-pump.png',
            'Sustainability Fair': 'images/event-sports-field.png',
            '2022 Mayday 4 Ukraine': 'images/event-sports-field.png',
            'Marina to the rescue': 'images/Marina to the rescue.png',
            'Prague meets Alella': 'images/prague meets alella.png'
        };

        // If no specific image found, use generic images by activity type
        if (!defaultImages[activity.title] && activity.activity_type) {
            const typeDefaults = {
                'School Visits': 'images/school-visit-permaculture.png',
                'Workshops': 'images/workshop-ram-pump.png',
                'Events': 'images/event-sports-field.png',
                'Special Lunches': 'images/brainstorming-lunch.png',
                'school-visits': 'images/school-visit-vineyard.png',
                'workshops': 'images/workshop-ram-pump.png',
                'events': 'images/event-sports-field.png',
                'lunches': 'images/brainstorming-lunch.png'
            };

            return typeDefaults[activity.activity_type.name] ||
                   typeDefaults[activity.activity_type.slug] ||
                   'images/welcome-hero-new.png'; // Ultimate fallback
        }

        return defaultImages[activity.title] || 'images/welcome-hero-new.png';
    }

    getGREENsInfo(activity) {
        // Use database values for credits
        const greensReward = activity.credits_earned || 0;
        const greensCost = activity.credits_required || 0;

        const rewardText = greensReward > 1 ? `+${greensReward} GREENs` : greensReward === 1 ? '+1 GREEN' : '';
        const costText = greensCost > 0 ? `${greensCost} GREEN${greensCost > 1 ? 's' : ''}` : '';
        const costClass = greensCost > 0 ? 'greens-cost has-cost' : 'greens-cost';

        if (greensReward > 0 && greensCost > 0) {
            return `
                <div class="greens-info">
                    <span class="greens-reward">${rewardText}</span>
                    <span class="${costClass}">Costs ${costText}</span>
                </div>
            `;
        } else if (greensReward > 0) {
            return `
                <div class="greens-info">
                    <span class="greens-reward">${rewardText}</span>
                </div>
            `;
        } else if (greensCost > 0) {
            return `
                <div class="greens-info">
                    <span class="${costClass}">Costs ${costText}</span>
                </div>
            `;
        }

        return `
            <div class="greens-info">
                <span class="greens-free">Free Activity</span>
            </div>
        `;
    }

    getActivityIcon(type) {
        const icons = {
            'school-visits': '🏫',
            'workshops': '🔧',
            'events': '🌱',
            'lunches': '🍷',
            'camps': '🏕️'
        };
        return icons[type] || '📅';
    }

    formatDuration(minutes) {
        if (!minutes) return 'Duration TBD';
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;
        if (hours === 0) return `${mins} minutes`;
        if (mins === 0) return `${hours} hour${hours > 1 ? 's' : ''}`;
        return `${hours}h ${mins}m`;
    }

    formatActivityDuration(activity) {
        if (activity.duration_minutes) {
            return this.formatDuration(activity.duration_minutes);
        }
        // Fallback to parsed duration text
        return activity.duration || 'Duration TBD';
    }

    getCompletedBadge(activity) {
        const currentDate = new Date();
        const activityDate = activity.date_time ? new Date(activity.date_time) : null;
        const isCompleted = activity.status === 'completed' || (activityDate && activityDate < currentDate);

        if (isCompleted) {
            return `<span class="completed-badge">✅ Completed</span>`;
        }
        return '';
    }

    getActivityButton(activity) {
        const currentDate = new Date();
        const activityDate = activity.date_time ? new Date(activity.date_time) : null;
        const isUpcoming = activity.status === 'published' && (!activityDate || activityDate > currentDate);
        const isCompleted = activity.status === 'completed' || (activityDate && activityDate < currentDate);
        const isFullyBooked = activity.max_participants && activity.current_participants >= activity.max_participants;

        // Check if user is already registered
        const isRegistered = this.currentUser && this.currentUser.registrations &&
                             this.currentUser.registrations.some(reg => reg.activity_id === activity.id);

        // Get activity type for special handling (now from joined data)
        const activityType = activity.activity_type;
        const activityTypeSlug = activityType ? activityType.slug : 'other';

        if (activityTypeSlug === 'school-visits') {
            // Special handling for school visits
            if (activity.title.includes('Benjamin Franklin')) {
                return `<button class="btn" onclick="app.openLoginModal('${activity.title}', 'visits/benjamin-franklin-sept-2025.html', 'bfis', 'alellagreentech')">Login to Visit</button>`;
            } else if (activity.title.includes('International School of Prague')) {
                return `<a href="visits/international-school-prague-sept-2025.html" class="btn">Visit Details</a>`;
            } else if (isCompleted) {
                return ''; // No button for completed activities - badge shows status
            } else {
                return `<a href="#" class="btn">Visit Details</a>`;
            }
        }

        if (activityTypeSlug === 'annual-events' || activityTypeSlug === 'events') {
            if (isCompleted) {
                return ''; // No button for completed activities - badge shows status
            } else if (!activityDate) {
                return `<button class="btn btn-info" disabled>📅 Coming Soon</button>`;
            }
        }

        // Regular activities with registration
        if (isRegistered) {
            return `<button class="btn btn-success" disabled>✓ Registered</button>`;
        }

        if (isCompleted) {
            return ''; // No button for completed activities - badge shows status
        }

        if (isFullyBooked) {
            return `<button class="btn btn-secondary" disabled>Fully Booked</button>`;
        }

        if (activity.requires_login && !this.currentUser) {
            return `<button class="btn" onclick="app.showAuthModal('${activity.id}', '${activity.title}')">Login to Register</button>`;
        }

        if (isUpcoming) {
            return `<button class="btn btn-primary" onclick="app.handleActivityRegistration('${activity.id}', '${activity.title}')">
                        ${activity.credits_required > 0 ? `Register (${activity.credits_required} GREENs)` : 'Register'}
                    </button>`;
        }

        return `<a href="#" class="btn">More Info</a>`;
    }

    async handleActivityRegistration(activityId, activityTitle) {
        if (!this.currentUser) {
            this.showAuthModal(activityId, activityTitle);
            return;
        }

        // Check if user has enough credits for paid activities
        const activity = this.activities.find(a => a.id === activityId);
        if (activity && activity.credits_required > 0) {
            const userProfile = await GuidalDB.getProfile(this.currentUser.id);
            if (userProfile.credits < activity.credits_required) {
                this.showNotification(`Insufficient GREENs credits. You need ${activity.credits_required} GREENs but have ${userProfile.credits}.`, 'error');
                return;
            }
        }

        try {
            await GuidalDB.registerForActivity(activityId, this.currentUser.id, {
                credits_used: activity?.credits_required || 0
            });

            this.showNotification(`Successfully registered for ${activityTitle}!`, 'success');

            // Create notification for user
            if (this.currentUser) {
                await GuidalDB.createNotification(
                    this.currentUser.id,
                    'Registration Confirmed',
                    `You've been registered for ${activityTitle}. Check your email for details.`,
                    'success'
                );
            }

            // Refresh activities and user data
            await this.loadActivities();
            await this.checkAuthStatus();
        } catch (error) {
            console.error('Registration error:', error);
            const message = GuidalDB.handleError(error, 'Activity Registration');
            this.showNotification(message, 'error');
        }
    }

    setupEventListeners() {
        // Search and filter
        const searchInput = document.getElementById('activity-search');
        const filterSelect = document.getElementById('activity-filter');

        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.handleSearch(e.target.value);
            });
        }

        if (filterSelect) {
            filterSelect.addEventListener('change', (e) => {
                this.handleFilter(e.target.value);
            });
        }

        // Keep existing login button functionality (it redirects to login.html)
    }

    async handleSearch(searchTerm) {
        // Always use database search
        const filters = { search: searchTerm };
        const filterSelect = document.getElementById('activity-filter');
        if (filterSelect && filterSelect.value !== 'all') {
            filters.type = filterSelect.value;
        }

        await this.loadActivities(filters);
    }

    async handleFilter(filterType) {
        const filters = filterType !== 'all' ? { type: filterType } : {};
        const searchInput = document.getElementById('activity-search');
        if (searchInput && searchInput.value) {
            filters.search = searchInput.value;
        }

        // Special handling for school visits to show counts
        if (filterType === 'school-visits') {
            this.showSchoolVisitCounts();
        } else {
            this.hideSchoolVisitCounts();
        }

        // Always use database filter
        await this.loadActivities(filters);
    }

    showSchoolVisitCounts() {
        // Count school visits from database data
        const schoolVisits = this.activities.filter(activity =>
            (activity.activity_type && activity.activity_type.slug === 'school-visits')
        );

        const currentDate = new Date();
        const completedVisits = schoolVisits.filter(visit =>
            visit.status === 'completed' ||
            (visit.date_time && new Date(visit.date_time) < currentDate)
        ).length;

        const upcomingVisits = schoolVisits.filter(visit =>
            visit.status === 'published' &&
            (!visit.date_time || new Date(visit.date_time) >= currentDate)
        ).length;

        // Create or update the counts display
        let countsElement = document.getElementById('school-visit-counts');
        if (!countsElement) {
            countsElement = document.createElement('div');
            countsElement.id = 'school-visit-counts';
            countsElement.className = 'school-visit-counts';

            const activitiesSection = document.querySelector('.activities-section');
            const searchContainer = document.querySelector('.search-container');
            if (activitiesSection && searchContainer) {
                activitiesSection.insertBefore(countsElement, searchContainer.nextSibling);
            }
        }

        countsElement.innerHTML = `
            <div class="visit-stats">
                <span class="stat-item completed">
                    <span class="stat-number">${completedVisits}</span>
                    <span class="stat-label">Completed School Trips</span>
                </span>
                <span class="stat-item upcoming">
                    <span class="stat-number">${upcomingVisits}</span>
                    <span class="stat-label">Upcoming School Trips</span>
                </span>
            </div>
        `;

        countsElement.style.display = 'block';
    }

    hideSchoolVisitCounts() {
        const countsElement = document.getElementById('school-visit-counts');
        if (countsElement) {
            countsElement.style.display = 'none';
        }
    }


    setupAuthListener() {
        GuidalDB.onAuthStateChange(async (event, session) => {
            if (event === 'SIGNED_IN' && session) {
                this.currentUser = await GuidalDB.getCurrentUser();
                this.updateUIForLoggedInUser();
                this.hideAuthModal();

                // If there was a pending registration, handle it
                if (this.pendingRegistration) {
                    await this.handleActivityRegistration(
                        this.pendingRegistration.activityId,
                        this.pendingRegistration.activityTitle
                    );
                    this.pendingRegistration = null;
                }
            } else if (event === 'SIGNED_OUT') {
                this.currentUser = null;
                this.updateUIForLoggedOutUser();
            }
        });
    }

    updateUIForLoggedInUser() {
        const loginBtn = document.querySelector('.login-btn');
        if (loginBtn) {
            const userName = this.currentUser.profile?.full_name || this.currentUser.email || 'My Account';
            loginBtn.innerHTML = `
                <span>${userName}</span>
                <div class="user-dropdown">
                    <a href="pages/profile.html">My Profile</a>
                    <a href="#" onclick="app.logout()">Logout</a>
                </div>
            `;
            loginBtn.classList.add('user-menu');
            loginBtn.href = 'pages/profile.html';
        }

        // Update activity buttons
        this.renderActivities();
    }

    updateUIForLoggedOutUser() {
        const loginBtn = document.querySelector('.login-btn');
        if (loginBtn) {
            loginBtn.textContent = 'Login/Register';
            loginBtn.classList.remove('user-menu');
            loginBtn.innerHTML = 'Login/Register';
            loginBtn.href = 'pages/auth/login.html';
        }

        // Update activity buttons
        this.renderActivities();
    }

    showAuthModal(activityId = null, activityTitle = null) {
        // Store pending registration for after login
        if (activityId && activityTitle) {
            this.pendingRegistration = { activityId, activityTitle };
        }

        // Redirect to login page with return URL
        const currentUrl = encodeURIComponent(window.location.href);
        const loginUrl = `pages/auth/login.html?return_url=${currentUrl}`;

        if (activityId) {
            // Show a message about needing to login
            const confirmed = confirm(`Please login to register for "${activityTitle}". You'll be redirected to the login page.`);
            if (confirmed) {
                window.location.href = loginUrl;
            }
        } else {
            window.location.href = loginUrl;
        }
    }

    async logout() {
        try {
            await GuidalDB.signOut();
            this.showNotification('Successfully logged out', 'success');
            // Page will reload via auth state change
        } catch (error) {
            console.error('Logout error:', error);
            this.showNotification('Logout failed. Please try again.', 'error');
        }
    }

    showUserMenu() {
        // TODO: Implement user menu dropdown
        console.log('Show user menu');
    }

    showNotification(message, type = 'info') {
        // Simple notification system
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1rem 1.5rem;
            background-color: ${type === 'success' ? '#4caf50' : type === 'error' ? '#f44336' : '#2196f3'};
            color: white;
            border-radius: 8px;
            z-index: 1000;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        `;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
        }, 5000);
    }

    hideAuthModal() {
        // TODO: Hide authentication modal
        console.log('Hide authentication modal');
    }

    // Modal Login System
    openLoginModal(schoolName, redirectUrl, username, password) {
        const modal = document.getElementById('loginModal');
        const modalSchoolInfo = document.getElementById('modalSchoolInfo');
        const modalUsername = document.getElementById('modalUsername');
        const modalPassword = document.getElementById('modalPassword');
        const modalLoginHelp = document.getElementById('modalLoginHelp');
        
        // Set school-specific content
        modalSchoolInfo.innerHTML = `
            <h4>${schoolName}</h4>
            <p>September 16, 2025</p>
        `;
        
        // Pre-fill login credentials
        modalUsername.value = username;
        modalPassword.value = password;
        
        // Set login help content
        modalLoginHelp.innerHTML = `
            <p>For BFIS September 16, 2025 visit:</p>
            <ul>
                <li><strong>Username:</strong> ${username} (pre-filled)</li>
                <li><strong>Password:</strong> ${password} (pre-filled)</li>
            </ul>
            <p>Simply click "Login to Visit" to access your visit details.</p>
        `;
        
        // Store redirect URL for form submission
        modal.dataset.redirectUrl = redirectUrl;
        
        // Show modal with animation
        modal.style.display = 'flex';
        setTimeout(() => {
            modal.style.opacity = '1';
        }, 10);
        
        // Focus password field
        modalPassword.focus();
        modalPassword.select();
    }

    closeLoginModal() {
        const modal = document.getElementById('loginModal');
        modal.style.opacity = '0';
        setTimeout(() => {
            modal.style.display = 'none';
        }, 300);
    }

    setupModalEventListeners() {
        const modal = document.getElementById('loginModal');
        const modalClose = document.getElementById('modalClose');
        const modalCancel = document.getElementById('modalCancel');
        const modalBackdrop = modal.querySelector('.modal-backdrop');
        const modalLoginForm = document.getElementById('modalLoginForm');
        
        // Close modal events
        modalClose.addEventListener('click', () => this.closeLoginModal());
        modalCancel.addEventListener('click', () => this.closeLoginModal());
        modalBackdrop.addEventListener('click', () => this.closeLoginModal());
        
        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && modal.style.display === 'flex') {
                this.closeLoginModal();
            }
        });
        
        // Handle login form submission
        modalLoginForm.addEventListener('submit', (e) => {
            e.preventDefault();
            
            const username = document.getElementById('modalUsername').value;
            const password = document.getElementById('modalPassword').value;
            const redirectUrl = modal.dataset.redirectUrl;
            
            // Simple authentication for BFIS (same logic as original login page)
            if (username === 'bfis' && password === 'alellagreentech') {
                // Store login state
                localStorage.setItem('schoolLogin', 'bfis');
                localStorage.setItem('loginTime', new Date().getTime().toString());
                
                // Close modal
                this.closeLoginModal();
                
                // Redirect to visit page
                window.location.href = redirectUrl;
            } else {
                alert('Invalid credentials. Please check your username and password.');
            }
        });
    }
}

// Initialize application when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Add smooth scrolling for anchor links (keeping existing functionality)
    const links = document.querySelectorAll('a[href^="#"]');
    
    links.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add animation to cards on scroll (keeping existing functionality)
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe all cards for animation
    const cards = document.querySelectorAll('.station-card, .activity, .info-card, .activity-card');
    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });

    // Initialize the main application
    window.app = new GuidalApp();
});

// Legacy functions for backward compatibility
function initializeEventSystem() {
    console.log('Event system integrated with database');
}

function initializeCreditSystem() {
    console.log('Credit system integrated with database');
}

function initializeShopSystem() {
    console.log('Shop system integrated with database');
}