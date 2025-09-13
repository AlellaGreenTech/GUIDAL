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
        // Load initial data
        await this.loadActivityTypes();
        await this.loadActivities();
        
        // Set up event listeners
        this.setupEventListeners();
        this.setupModalEventListeners();
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
            this.activities = await GuidalDB.getActivities(filters);
            this.renderActivities();
        } catch (error) {
            console.error('Error loading activities:', error);
            // Fallback to static content if database fails
            console.log('Using static content as fallback');
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

        // Only clear and re-render if we have activities from database
        if (this.activities && this.activities.length > 0) {
            // Clear existing static content
            activityGrid.innerHTML = '';

            this.activities.forEach(activity => {
                const card = this.createActivityCard(activity);
                activityGrid.appendChild(card);
            });
        } else {
            // Keep static HTML content when no database activities
            console.log('No database activities found, keeping static content');
        }
    }

    createActivityCard(activity) {
        const card = document.createElement('div');
        card.className = 'activity-card';
        card.setAttribute('data-type', activity.activity_type);
        card.setAttribute('data-date', activity.date_time || 'TBD');

        const dateDisplay = activity.date_time 
            ? new Date(activity.date_time).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })
            : 'Date: TBD';

        const activityType = this.activityTypes.find(type => type.slug === activity.activity_type);
        const participantInfo = activity.participant_count 
            ? `${activity.participant_count} ${activity.activity_type === 'school-visits' ? 'students' : 'participants'}`
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
                <p class="activity-date">${dateDisplay}</p>
                <p class="activity-description">${activity.description}</p>
                <div class="activity-details">
                    <span class="participants">${participantInfo}</span>
                    <span class="duration">${activity.duration}</span>
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
            'International School of Prague': 'images/school-visit-prague.png',
            'Brainstorming Lunch': 'images/lunch-event.png',
            'Build Your Own Ram Pump': 'images/workshop-construction.png',
            'Sustainability Fair': 'images/sustainability-fair.png'
        };
        
        return defaultImages[activity.title] || null;
    }

    getGREENsInfo(activity) {
        // Determine GREENs reward based on activity type and characteristics
        let greensReward = 1; // Default
        let greensCost = 0;   // Default free

        // Educational activities earn GREENs
        if (activity.activity_category === 'educational' || activity.activity_type === 'workshops' || activity.activity_type === 'school-visits') {
            if (activity.title.toLowerCase().includes('full day') || activity.title.toLowerCase().includes('workshop') || activity.title.toLowerCase().includes('ram pump')) {
                greensReward = 3; // Full day with manual work
            } else if (activity.title.toLowerCase().includes('planting') || activity.title.toLowerCase().includes('station') || activity.activity_type === 'school-visits') {
                greensReward = 2; // Activities with manual work
            } else {
                greensReward = 1; // Easy educational activities
            }
        }

        // Recreational activities cost GREENs
        if (activity.activity_category === 'recreational' || activity.title.toLowerCase().includes('football') || activity.title.toLowerCase().includes('recreation')) {
            greensReward = 0;
            greensCost = 1; // Cost GREENs to participate
        }

        // Special events
        if (activity.activity_type === 'events' && !activity.title.toLowerCase().includes('lunch')) {
            greensReward = 2;
        }

        const rewardText = greensReward > 1 ? `+${greensReward} GREENs` : greensReward === 1 ? '+1 GREEN' : '';
        const costText = greensCost > 0 ? `${greensCost} GREEN${greensCost > 1 ? 's' : ''}` : 'Free';
        const costClass = greensCost > 0 ? 'greens-cost has-cost' : 'greens-cost';

        if (greensReward > 0) {
            return `
                <div class="greens-info">
                    <span class="greens-reward">${rewardText}</span>
                    <span class="${costClass}">${costText}</span>
                </div>
            `;
        } else if (greensCost > 0) {
            return `
                <div class="greens-info">
                    <span class="${costClass}">Costs ${costText}</span>
                </div>
            `;
        }

        return '';
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

    getActivityButton(activity) {
        if (activity.activity_type === 'school-visits') {
            if (activity.title === 'Benjamin Franklin International School') {
                return `<button class="btn" onclick="app.openLoginModal('${activity.title}', 'visits/benjamin-franklin-sept-2025.html', 'bfis', 'alellagreentech')">Login to Visit</button>`;
            } else {
                return `<a href="${activity.page_url}" class="btn">Visit Details</a>`;
            }
        }
        
        return `<a href="${activity.page_url}" class="btn">${activity.activity_type === 'workshops' ? 'Workshop Details' : activity.activity_type === 'events' ? 'Event Details' : 'Details'}</a>`;
    }

    async handleActivityRegistration(activityId, activityTitle) {
        if (!this.currentUser) {
            this.showAuthModal();
            return;
        }

        try {
            await GuidalDB.registerForActivity(activityId, this.currentUser.id);
            this.showNotification(`Successfully registered for ${activityTitle}!`, 'success');
            await this.loadActivities(); // Refresh to show updated participant count
        } catch (error) {
            console.error('Registration error:', error);
            this.showNotification('Registration failed. Please try again.', 'error');
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
        await this.loadActivities(filters);
    }

    setupAuthListener() {
        GuidalAuth.onAuthStateChange(async (event, session) => {
            if (event === 'SIGNED_IN' && session) {
                this.currentUser = await GuidalDB.getProfile(session.user.id);
                this.updateUIForLoggedInUser();
                this.hideAuthModal();
            } else if (event === 'SIGNED_OUT') {
                this.currentUser = null;
                this.updateUIForLoggedOutUser();
            }
        });
    }

    updateUIForLoggedInUser() {
        const loginBtn = document.querySelector('.login-btn');
        if (loginBtn) {
            loginBtn.textContent = this.currentUser.full_name || 'My Account';
        }
        
        // Update activity buttons
        this.renderActivities();
    }

    updateUIForLoggedOutUser() {
        const loginBtn = document.querySelector('.login-btn');
        if (loginBtn) {
            loginBtn.textContent = 'Login/Register';
        }
        
        // Update activity buttons
        this.renderActivities();
    }

    showAuthModal() {
        // TODO: Implement authentication modal
        // For now, redirect to a simple auth page
        console.log('Show authentication modal');
        alert('Authentication system coming soon! For now, activities are open to all visitors.');
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