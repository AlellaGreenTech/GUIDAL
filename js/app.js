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
        console.log('🚀 Initializing GUIDAL app...');

        // Check authentication status
        await this.checkAuthStatus();

        // Load initial data
        await this.loadActivityTypes();
        await this.loadActivities({ time_filter: 'upcoming' });

        // Set up event listeners
        this.setupEventListeners();
        this.setupModalEventListeners();
        this.setupAuthListener();

        console.log('✅ GUIDAL app initialized successfully');
    }


    async checkAuthStatus() {
        try {
            // Add timeout to auth check
            const timeoutPromise = new Promise((_, reject) =>
                setTimeout(() => reject(new Error('Auth timeout')), 2000)
            );

            this.currentUser = await Promise.race([
                GuidalDB.getCurrentUser(),
                timeoutPromise
            ]);

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

            // Add timeout to database call
            const timeoutPromise = new Promise((_, reject) =>
                setTimeout(() => reject(new Error('Database timeout')), 3000)
            );

            // Use new schema methods based on filter type
            let activities = []

            if (filters.type === 'science-stations' || filters.show_templates) {
                // Get science-in-action activity templates
                activities = await Promise.race([
                    GuidalDB.getActivityTemplates(filters),
                    timeoutPromise
                ])
            } else if (filters.time_filter === 'past') {
                // Get past visits
                activities = await Promise.race([
                    GuidalDB.getPastVisits(filters),
                    timeoutPromise
                ])
                // Transform past visits to look like activities
                activities = activities.map(visit => ({
                    ...visit,
                    title: visit.school_name || visit.title,
                    date_time: visit.confirmed_date || visit.created_at,
                    activity_type: {
                        id: 'past-visit',
                        name: 'Past Visit',
                        slug: visit.visit_type || 'school-visits',
                        color: '#757575',
                        icon: '🏫'
                    },
                    status: 'completed'
                }))
            } else {
                // Get scheduled visits (upcoming activities)
                activities = await Promise.race([
                    GuidalDB.getScheduledVisits(filters),
                    timeoutPromise
                ])
                // Transform scheduled visits to look like activities
                activities = activities.map(visit => {
                    const primaryActivity = visit.visit_activities?.[0]?.activities
                    return {
                        ...visit,
                        title: visit.title,
                        description: visit.description,
                        date_time: visit.scheduled_date,
                        duration_minutes: visit.duration_minutes,
                        max_participants: visit.max_participants,
                        current_participants: visit.current_participants,
                        activity_type: primaryActivity?.activity_type || {
                            id: 'scheduled-visit',
                            name: visit.visit_type?.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase()) || 'Scheduled Visit',
                            slug: visit.visit_type || 'workshops',
                            color: '#2196f3',
                            icon: visit.visit_type === 'school_group' ? '🏫' : '📅'
                        },
                        status: visit.status
                    }
                })
            }

            this.activities = activities
            console.log('✅ Activities loaded:', this.activities.length, 'activities');
            console.log('📊 First activity sample:', this.activities[0]);
            this.renderActivities();
        } catch (error) {
            console.error('❌ Error loading activities:', error);
            console.log('🔄 Falling back to static demo data');
            this.activities = this.getFallbackActivities(filters);
            this.renderActivities();
        }
    }

    getFallbackActivities(filters = {}) {
        // Include science-in-action templates as fallback
        const scienceInActionTemplates = [
            {
                id: 'science-1',
                title: 'Robotic Gardening',
                description: 'Tend your garden from 1,000km away - or let the bot do it! Explore automated agriculture and precision farming with real robotic systems.',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null, // Templates have no scheduled date
                suggested_duration_minutes: 60,
                recommended_group_size: '8-12 students',
                status: 'published',
                featured_image: 'images/robotic-gardening-system.png'
            },
            {
                id: 'science-2',
                title: 'Erosion Challenge',
                description: 'Stop erosion, retain water and create a fertile hillside through natural engineering solutions and permaculture techniques.',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null,
                suggested_duration_minutes: 90,
                recommended_group_size: '10-15 students',
                status: 'published',
                featured_image: 'images/swales.jpg'
            },
            {
                id: 'science-3',
                title: 'Hydraulic Ram Pumps',
                description: 'Moving water up high without electricity! Discover genius inventions of the past that use water pressure to pump water uphill.',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null,
                suggested_duration_minutes: 75,
                recommended_group_size: '6-10 students',
                status: 'published',
                featured_image: 'images/hydraulic-ram-pump-system.png'
            }
        ]

        const staticActivities = [
            {
                id: 'demo-1',
                title: 'Composting Workshop',
                description: 'Learn the essential ingredients for good soil. Master different composting methods and create rich, fertile soil for sustainable gardening.',
                activity_type: {
                    id: 'workshops',
                    name: 'Workshops',
                    slug: 'workshops',
                    color: '#ff9800',
                    icon: '🔧'
                },
                date_time: '2025-10-15T14:00:00+02:00',
                duration_minutes: 180,
                location: 'Alella Green Tech Campus',
                max_participants: 15,
                current_participants: 10,
                credits_earned: 2,
                credits_required: 0,
                status: 'published',
                featured_image: 'images/composting-farm-scene.png'
            },
            {
                id: 'demo-2',
                title: 'Erosion Challenge Workshop',
                description: 'Stop erosion, retain water, create fertile hillsides. Learn natural engineering techniques and soil conservation.',
                activity_type: {
                    id: 'workshops',
                    name: 'Workshops',
                    slug: 'workshops',
                    color: '#ff9800',
                    icon: '🔧'
                },
                date_time: '2025-10-20T09:00:00+02:00',
                duration_minutes: 300,
                location: 'Alella Green Tech Campus',
                max_participants: 20,
                current_participants: 12,
                credits_earned: 4,
                credits_required: 0,
                status: 'published',
                featured_image: 'images/school-visit-bg.png'
            },
            {
                id: 'demo-3',
                title: 'Planting Workshop',
                description: 'Seeds being planted today! Learn optimal planting techniques for sustainable gardens and food production.',
                activity_type: {
                    id: 'workshops',
                    name: 'Workshops',
                    slug: 'workshops',
                    color: '#ff9800',
                    icon: '🔧'
                },
                date_time: '2025-10-25T10:30:00+02:00',
                duration_minutes: 240,
                location: 'Alella Green Tech Campus',
                max_participants: 18,
                current_participants: 15,
                credits_earned: 3,
                credits_required: 0,
                status: 'published',
                featured_image: 'images/school-visit-planting.png'
            }
        ];

        // Combine templates and scheduled activities
        let allActivities = [...scienceInActionTemplates, ...staticActivities]

        // Apply filters if any
        let filteredActivities = allActivities

        if (filters.type && filters.type !== 'all') {
            filteredActivities = filteredActivities.filter(activity =>
                activity.activity_type.slug === filters.type
            )
        }

        // Filter based on show_templates flag
        if (filters.show_templates) {
            filteredActivities = filteredActivities.filter(activity => !activity.date_time)
        } else if (filters.time_filter === 'upcoming') {
            filteredActivities = filteredActivities.filter(activity => activity.date_time)
        }

        if (filters.search) {
            const searchTerm = filters.search.toLowerCase();
            filteredActivities = filteredActivities.filter(activity =>
                activity.title.toLowerCase().includes(searchTerm) ||
                activity.description.toLowerCase().includes(searchTerm)
            );
        }

        return filteredActivities;
    }

    populateActivityTypeFilter() {
        const filterSelect = document.getElementById('activity-filter')
        if (!filterSelect || !this.activityTypes) return

        // Clear existing options except "All Activities"
        filterSelect.innerHTML = '<option value="all">All Activities</option>'

        // Add science-stations as a special option
        const scienceOption = document.createElement('option')
        scienceOption.value = 'science-stations'
        scienceOption.textContent = 'Science-in-Action'
        filterSelect.appendChild(scienceOption)

        this.activityTypes.forEach(type => {
            // Skip science-stations since we added it manually above
            if (type.slug === 'science-stations') return

            const option = document.createElement('option')
            option.value = type.slug
            option.textContent = type.name
            filterSelect.appendChild(option)
        })
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
        // Debug: Log BFIS activity details
        if (activity.title && activity.title.includes('Benjamin Franklin')) {
            console.log('🚨 DEBUG: BFIS Activity Details:', {
                title: activity.title,
                activity_type: activity.activity_type,
                status: activity.status,
                description: activity.description,
                full_activity: activity
            });
        }

        const card = document.createElement('div');
        card.className = 'activity-card';

        // Get activity type from database structure (now joined)
        const activityType = activity.activity_type;
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
            ? `Max ${activity.max_participants} ${activityTypeSlug === 'school-visits' ? 'students' : 'participants'}`
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
                <div class="activity-type">${activityType?.name || 'Activity'}</div>
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
                <div class="activity-actions">
                    ${greensInfo}
                    <div class="activity-button-wrapper">
                        ${this.getActivityButton(activity)}
                    </div>
                </div>
            </div>
        `;

        return card;
    }

    getActivityImage(activity) {
        // Use featured_image from database if available
        console.log(`🖼️ Activity "${activity.title}" - featured_image: ${JSON.stringify(activity.featured_image)}`);
        const imageSrc = activity.featured_image || this.getDefaultImageForActivity(activity);
        console.log(`🖼️ Using image: ${imageSrc}`);

        if (imageSrc) {
            return `<img src="${imageSrc}" alt="${activity.title}" class="activity-photo" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                    <div class="image-placeholder" style="display:none;">
                        <p>${this.getActivityIcon(activity.activity_type?.slug)} ${activity.activity_type?.name || 'Activity'}</p>
                    </div>`;
        } else {
            return `<div class="image-placeholder">
                        <p>${this.getActivityIcon(activity.activity_type?.slug)} ${activity.activity_type?.name || 'Activity'}</p>
                    </div>`;
        }
    }

    getDefaultImageForActivity(activity) {
        // Fallback images when database doesn't have featured_image
        const defaultImages = {
            'Benjamin Franklin International School': 'images/school-visit-planting.png',
            'International School of Prague': 'images/prague-alella-bridge-vineyard.png',
            'Brainstorming Lunch': 'images/brainstorming-lunch.png',
            'Build Your Own Ram Pump': 'images/hydraulic-ram-pump-system.png',
            'Hydraulic Ram Pumps': 'images/hydraulic-ram-pump-system.png',
            'Ram Pump Workshop': 'images/hydraulic-ram-pump-system.png',
            'Pumped Hydro': 'images/pumped-hydro-simulation.png',
            'Pumped Hydro Workshop': 'images/pumped-hydro-simulation.png',
            'Robotic Gardening': 'images/robotic-gardening-system.png',
            'Robotic Gardening Workshop': 'images/robotic-gardening-system.png',
            'Wattle & Daub': 'images/wattle-daub-construction.png',
            'Wattle and Daub': 'images/wattle-daub-construction.png',
            'Traditional Construction': 'images/wattle-daub-construction.png',
            'Agricultural Drones': 'images/agricultural-drone-vineyard.png',
            'Agricultural Drones & Vineyard': 'images/agricultural-drone-vineyard.png',
            'Drone Vineyard Management': 'images/agricultural-drone-vineyard.png',
            'Sustainability Fair': 'images/event-sports-field.png',
            '2022 Mayday 4 Ukraine': 'images/event-sports-field.png',
            'Marina to the rescue': 'images/Marina to the rescue.png',
            'Prague meets Alella': 'images/prague meets alella.png'
        };

        // If no specific image found, use generic images by activity type
        if (!defaultImages[activity.title] && activity.activity_type) {
            const typeDefaults = {
                'School Visits': 'images/school-visit-bg.png',
                'Workshops': 'images/workshop-ram-pump.png',
                'Events': 'images/event-sports-field.png',
                'Special Lunches': 'images/brainstorming-lunch.png',
                'school-visits': 'images/school-visit-vineyard.png',
                'workshops': 'images/workshop-ram-pump.png',
                'events': 'images/event-sports-field.png',
                'lunches': 'images/brainstorming-lunch.png'
            };

            // activity_type is the joined object from Supabase
            const typeName = activity.activity_type?.name;
            const typeSlug = activity.activity_type?.slug;

            return typeDefaults[typeName] ||
                   typeDefaults[typeSlug] ||
                   'images/welcome-hero-new.png'; // Ultimate fallback
        }

        return defaultImages[activity.title] || 'images/welcome-hero-new.png';
    }

    getGREENsInfo(activity) {
        // Calculate GREENs based on duration: 1 GREEN per 30 minutes (no fractions)
        const durationMinutes = activity.duration_minutes || 0;
        const calculatedCost = durationMinutes > 0 ? Math.ceil(durationMinutes / 30) : 0;

        // Use calculated cost or database values
        const greensReward = activity.credits_earned || 0;
        const greensCost = calculatedCost || activity.credits_required || 0;

        const rewardText = greensReward > 1 ? `+${greensReward} GREEN$` : greensReward === 1 ? '+1 GREEN$' : '';
        const costText = greensCost > 1 ? `${greensCost} GREEN$` : greensCost === 1 ? '1 GREEN$' : '';
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
        // Set activity completion cutoff to next day at midnight
        const nextDay = activityDate ? new Date(activityDate.getTime() + 24 * 60 * 60 * 1000) : null;
        const isCompleted = activity.status === 'completed' || (nextDay && currentDate >= nextDay);

        if (isCompleted) {
            return `<span class="completed-badge">✅ Completed</span>`;
        }
        return '';
    }

    getCompletedVisitButton(activity) {
        // Determine visit type and privacy mode
        let visitType = 'unknown';
        if (activity.title.includes('Benjamin Franklin')) {
            visitType = 'benjamin-franklin';
        } else if (activity.title.includes('International School of Prague')) {
            visitType = 'prague';
        }

        // Use PrivacyManager if available, otherwise fallback to manual check
        let isPrivacyMode = false;
        if (typeof PrivacyManager !== 'undefined') {
            isPrivacyMode = PrivacyManager.isPrivacyMode(visitType);
        } else {
            // Fallback: Prague is privacy mode
            isPrivacyMode = visitType === 'prague';
        }

        if (isPrivacyMode) {
            // Privacy visits: Anyone can access completed visits
            if (activity.title.includes('International School of Prague')) {
                return `<a href="visits/international-school-prague-sept-2025.html" class="btn btn-secondary">View Visit</a>`;
            } else {
                return `<button class="btn btn-secondary" onclick="openLoginModal('${activity.title}', '#')">View Visit</button>`;
            }
        } else {
            // Secure visits: Only registered users for that school can access
            if (activity.title.includes('Benjamin Franklin')) {
                if (this.currentUser && this.isUserRegisteredForSchool(this.currentUser, 'benjamin-franklin')) {
                    return `<button class="btn btn-secondary" onclick="openLoginModal('${activity.title}', 'visits/benjamin-franklin-sept-2025.html')">View Visit</button>`;
                } else if (this.currentUser) {
                    return `<button class="btn btn-disabled" disabled title="Only registered Benjamin Franklin students can access this completed visit">Access Restricted</button>`;
                } else {
                    return `<button class="btn" onclick="openLoginModal('${activity.title}', 'visits/benjamin-franklin-sept-2025.html')">Login to View</button>`;
                }
            } else {
                return `<button class="btn" onclick="openLoginModal('${activity.title}', '#')">Login to View</button>`;
            }
        }
    }

    isUserRegisteredForSchool(user, schoolType) {
        // Check if user is registered for activities from this school
        // This could be enhanced to check user profile or registration data
        if (!user || !user.registrations) return false;

        // For now, check if user has any registrations for activities from this school
        return user.registrations.some(reg => {
            const activity = this.activities.find(act => act.id === reg.activity_id);
            if (!activity) return false;

            // Check if activity title contains the school identifier
            if (schoolType === 'benjamin-franklin') {
                return activity.title.includes('Benjamin Franklin');
            }
            return false;
        });
    }

    getActivityButton(activity) {
        const currentDate = new Date()
        const activityDate = activity.date_time ? new Date(activity.date_time) : null
        const isUpcoming = activity.status === 'confirmed' && (!activityDate || activityDate > currentDate)
        const isCompleted = activity.status === 'completed' || (activityDate && currentDate >= activityDate)
        const isFullyBooked = activity.max_participants && activity.current_participants >= activity.max_participants

        // Check if user is already registered
        const isRegistered = this.currentUser && this.currentUser.registrations &&
                             this.currentUser.registrations.some(reg => reg.activity_id === activity.id)

        // Get activity type for special handling
        const activityType = activity.activity_type
        const activityTypeSlug = activityType?.slug || 'other'

        // Handle science-in-action templates (no dates)
        if (activityTypeSlug === 'science-stations' && !activity.date_time) {
            return `<button class="btn btn-primary" onclick="app.handleScienceStationBooking('${activity.id}', '${activity.title}')">Book Station</button>`
        }

        if (activityTypeSlug === 'school-visits' || activityTypeSlug === 'school_group') {
            console.log('🔍 School visit detected:', activity.title, 'Type:', activityTypeSlug, 'Completed:', isCompleted)

            // Handle completed visits based on security/privacy mode
            if (isCompleted) {
                return this.getCompletedVisitButton(activity)
            } else if (activity.title.includes('Benjamin Franklin')) {
                console.log('✅ Benjamin Franklin visit detected - generating Visit Details button')
                return `<button class="btn" onclick="openLoginModal('${activity.title}', 'visits/benjamin-franklin-sept-2025.html')">Visit Details</button>`
            } else if (activity.title.includes('International School of Prague')) {
                return `<a href="visits/international-school-prague-sept-2025.html" class="btn">Visit Details</a>`
            } else {
                return `<button class="btn" onclick="openLoginModal('${activity.title}', '#')">Visit Details</button>`
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
            return `<button class="btn btn-success" disabled>✓ Booked</button>`;
        }

        if (isCompleted) {
            return ''; // No button for completed activities - badge shows status
        }

        if (isFullyBooked) {
            return `<button class="btn btn-secondary" disabled>Fully Booked</button>`;
        }

        if (activity.requires_login && !this.currentUser) {
            return `<button class="btn" onclick="app.showAuthModal('${activity.id}', '${activity.title}')">Login to Book</button>`;
        }

        if (isUpcoming) {
            return `<button class="btn btn-primary" onclick="app.handleActivityRegistration('${activity.id}', '${activity.title}')">
                        ${activity.credits_required > 0 ? `Book (${activity.credits_required} Green$)` : 'Book'}
                    </button>`;
        }

        return `<a href="#" class="btn">More Info</a>`
    }

    async handleScienceStationBooking(activityId, activityTitle) {
        // Handle booking a science-in-action station
        // This would typically open a form to schedule the station as part of a visit
        console.log('Booking science station:', activityTitle)

        if (!this.currentUser) {
            this.showAuthModal(activityId, activityTitle)
            return
        }

        // For now, show a message - this could open a scheduling modal
        this.showNotification(`${activityTitle} can be included in school visits. Contact us to schedule!`, 'info')
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
                this.showNotification(`Insufficient Green$. You need ${activity.credits_required} Green$ but have ${userProfile.credits}.`, 'error');
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
        const filters = {}
        const searchInput = document.getElementById('activity-search')
        if (searchInput && searchInput.value) {
            filters.search = searchInput.value
        }

        // Handle different filter types
        if (filterType === 'coming') {
            filters.time_filter = 'upcoming'
        } else if (filterType === 'past') {
            filters.time_filter = 'past'
        } else if (filterType === 'science-stations') {
            filters.type = 'science-stations'
            filters.show_templates = true // Show activity templates
        } else if (filterType !== 'all') {
            filters.type = filterType
        }

        // Special handling for school visits to show counts
        if (filterType === 'school-visits') {
            this.showSchoolVisitCounts()
        } else {
            this.hideSchoolVisitCounts()
        }

        // Load activities with new filters
        await this.loadActivities(filters)
    }

    // Time-based filter function for the toggle buttons
    async filterActivitiesByTime(timeType) {
        console.log('🕒 Filtering activities by time:', timeType);

        const filters = {};

        if (timeType === 'future') {
            filters.time_filter = 'upcoming';
            filters.status = 'published';

            // Keep current type filter for future activities
            const filterSelect = document.getElementById('activity-filter');
            if (filterSelect && filterSelect.value !== 'all') {
                filters.type = filterSelect.value;
            }
        } else if (timeType === 'past') {
            filters.time_filter = 'past';

            // For past activities, include completed status to show finished school visits
            filters.include_completed = true;

            // Keep current type filter for past activities too
            const filterSelect = document.getElementById('activity-filter');
            if (filterSelect && filterSelect.value !== 'all') {
                filters.type = filterSelect.value;
                console.log('🎯 Past activities with type filter:', filters.type);
            } else {
                console.log('🎯 Past activities showing all types');
            }

            // Allow type filtering for past activities to work properly
        }

        // Keep current search term if set
        const searchInput = document.getElementById('activity-search');
        if (searchInput && searchInput.value.trim()) {
            filters.search = searchInput.value.trim();
        }

        await this.loadActivities(filters);
    }

    showSchoolVisitCounts() {
        // Count school visits from database data
        const schoolVisits = this.activities.filter(activity =>
            (activity.activity_type?.slug === 'school-visits')
        );

        const currentDate = new Date();
        const completedVisits = schoolVisits.filter(visit => {
            const visitDate = visit.date_time ? new Date(visit.date_time) : null;
            const nextDay = visitDate ? new Date(visitDate.getTime() + 24 * 60 * 60 * 1000) : null;
            return visit.status === 'completed' || (nextDay && currentDate >= nextDay);
        }).length;

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

        // Update auth link in About section
        const authLink = document.getElementById('auth-link');
        if (authLink) {
            authLink.textContent = 'VIEW ACTIVITIES';
            authLink.href = '#activities';
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

        // Update auth link in About section
        const authLink = document.getElementById('auth-link');
        if (authLink) {
            authLink.textContent = 'Register to get started!';
            authLink.href = 'pages/auth/login.html';
        }

        // Update activity buttons
        this.renderActivities();
    }

    showAuthModal(activityId = null, activityTitle = null) {
        // Check for Prague privacy mode
        const urlParams = new URLSearchParams(window.location.search);
        const isPrivacyMode = urlParams.get('privacy') === 'true';
        const visitType = urlParams.get('visit');

        if (isPrivacyMode && visitType === 'prague') {
            // Redirect to simplified Prague registration
            const currentUrl = encodeURIComponent(window.location.href);
            const pragueRegisterUrl = `pages/auth/register-prague.html?returnTo=${currentUrl}`;
            window.location.href = pragueRegisterUrl;
            return;
        }

        // Store pending registration for after login
        if (activityId && activityTitle) {
            this.pendingRegistration = { activityId, activityTitle };
        }

        // Use current URL for return after auth
        const currentUrl = encodeURIComponent(window.location.href);

        if (activityId) {
            // Ask user if they want to login or register
            const isNewUser = confirm(`To register for "${activityTitle}", you need an account.\n\nClick OK to create a new account, or Cancel to login with existing account.`);

            if (isNewUser) {
                // Redirect to registration with return URL
                const registerUrl = `pages/auth/register.html?returnTo=${currentUrl}`;
                window.location.href = registerUrl;
            } else {
                // Redirect to login with return URL
                const loginUrl = `pages/auth/login.html?return_url=${currentUrl}`;
                window.location.href = loginUrl;
            }
        } else {
            // Default to login
            const loginUrl = `pages/auth/login.html?return_url=${currentUrl}`;
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
    openLoginModal(schoolName, redirectUrl) {
        const modal = document.getElementById('loginModal');
        const modalSchoolInfo = document.getElementById('modalSchoolInfo');
        const modalUsername = document.getElementById('modalUsername');
        const modalPassword = document.getElementById('modalPassword');

        // Set school-specific content
        modalSchoolInfo.innerHTML = `
            <h4>${schoolName}</h4>
            <p>September 16, 2025</p>
        `;

        // Clear login fields - users must enter their own credentials
        modalUsername.value = '';
        modalPassword.value = '';
        modalUsername.removeAttribute('readonly');
        
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
            
            const email = document.getElementById('modalUsername').value;
            const password = document.getElementById('modalPassword').value;
            const redirectUrl = modal.dataset.redirectUrl;

            // Use proper Supabase authentication
            this.authenticateUser(email, password, redirectUrl);
        });
    }

    async authenticateUser(email, password, redirectUrl) {
        try {
            // Attempt to sign in with Supabase
            const { user, session } = await GuidalDB.signIn(email, password);

            if (user && session) {
                // Successfully authenticated
                this.closeLoginModal();

                // Redirect to visit page
                window.location.href = redirectUrl;
            }
        } catch (error) {
            console.error('Authentication error:', error);
            alert('Invalid credentials. Please check your email and password, or register for an account.');
        }
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

// Global function for onclick handlers (ensures it's available immediately)
function openLoginModal(schoolName, redirectUrl) {
    if (window.app && window.app.openLoginModal) {
        window.app.openLoginModal(schoolName, redirectUrl);
    } else {
        console.error('App not ready yet, trying again...');
        setTimeout(() => openLoginModal(schoolName, redirectUrl), 100);
    }
}

// Global time filter function for the activities toggle
function filterActivitiesByTime(timeType) {
    if (window.app && window.app.filterActivitiesByTime) {
        window.app.filterActivitiesByTime(timeType);
    } else {
        console.error('App not ready yet, trying again...');
        setTimeout(() => filterActivitiesByTime(timeType), 100);
    }
}

// Make it available on window for the HTML onclick handlers
window.filterActivitiesByTime = filterActivitiesByTime;

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