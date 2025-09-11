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
        // Check for existing session
        await this.checkAuthStatus();
        
        // Load initial data
        await this.loadActivityTypes();
        await this.loadActivities();
        
        // Set up event listeners
        this.setupEventListeners();
        
        // Set up auth state listener
        this.setupAuthListener();
    }

    async checkAuthStatus() {
        try {
            const user = await GuidalAuth.getCurrentUser();
            if (user) {
                this.currentUser = await GuidalDB.getProfile(user.id);
                this.updateUIForLoggedInUser();
            }
        } catch (error) {
            console.log('No active session');
        }
    }

    async loadActivityTypes() {
        try {
            this.activityTypes = await GuidalDB.getActivityTypes();
            this.populateActivityTypeFilter();
        } catch (error) {
            console.error('Error loading activity types:', error);
        }
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
        if (!activityGrid || !this.activities) return;

        // Clear existing static content
        activityGrid.innerHTML = '';

        this.activities.forEach(activity => {
            const card = this.createActivityCard(activity);
            activityGrid.appendChild(card);
        });
    }

    createActivityCard(activity) {
        const card = document.createElement('div');
        card.className = 'activity-card';
        card.setAttribute('data-type', activity.activity_type.slug);
        card.setAttribute('data-date', activity.date_time || 'TBD');

        const dateDisplay = activity.date_time 
            ? new Date(activity.date_time).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })
            : 'Date: TBD';

        const participantCount = activity.current_participants || 0;
        const maxParticipants = activity.max_participants || 'Unlimited';

        card.innerHTML = `
            <div class="activity-image">
                <div class="image-placeholder">
                    <p>${this.getActivityIcon(activity.activity_type.slug)} ${activity.activity_type.name}</p>
                </div>
            </div>
            <div class="activity-info">
                <div class="activity-type">${activity.activity_type.name}</div>
                <h3>${activity.title}</h3>
                <p class="activity-date">${dateDisplay}</p>
                <p class="activity-description">${activity.description}</p>
                <div class="activity-details">
                    <span class="participants">${participantCount}/${maxParticipants} participants</span>
                    <span class="duration">${this.formatDuration(activity.duration_minutes)}</span>
                </div>
                ${this.getActivityButton(activity)}
            </div>
        `;

        return card;
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
        if (activity.activity_type.slug === 'school-visits') {
            return `<a href="visits/${activity.slug}.html" class="btn">Login to Visit</a>`;
        }
        
        const buttonText = activity.requires_login && !this.currentUser 
            ? 'Login to Register' 
            : 'Register Now';
            
        return `<button class="btn" onclick="app.handleActivityRegistration('${activity.id}', '${activity.title}')">${buttonText}</button>`;
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

        // Login/Register button
        const loginBtn = document.querySelector('.login-btn');
        if (loginBtn) {
            loginBtn.addEventListener('click', (e) => {
                e.preventDefault();
                if (this.currentUser) {
                    this.showUserMenu();
                } else {
                    this.showAuthModal();
                }
            });
        }
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