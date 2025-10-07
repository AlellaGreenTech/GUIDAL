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

    // Helper to get correct auth path based on current location
    getAuthPath(page = 'login.html') {
        const path = window.location.pathname;
        // If we're already in /pages/ directory, use relative path
        if (path.includes('/pages/')) {
            return `auth/${page}`;
        }
        // If at root or other directories, use full path
        return `pages/auth/${page}`;
    }

    // Helper to get correct image path based on current location
    getImagePath(imagePath) {
        if (!imagePath) return null;

        // If already an absolute path or external URL, return as-is
        if (imagePath.startsWith('http') || imagePath.startsWith('/')) {
            return imagePath;
        }

        const path = window.location.pathname;
        // If we're in /pages/ directory, need to go up one level
        if (path.includes('/pages/')) {
            return `../${imagePath}`;
        }
        // If at root, use path as-is
        return imagePath;
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
                setTimeout(() => reject(new Error('Database timeout')), 10000)
            );

            // Use database with proper admin RLS policies
            this.activities = await Promise.race([
                GuidalDB.getActivities(filters),
                timeoutPromise
            ]);

            console.log('✅ Activities loaded from database:', this.activities.length, 'activities');
            this.renderActivities();
        } catch (error) {
            console.error('❌ Error loading activities:', error);
            console.log('🔄 Falling back to static demo data');
            this.activities = this.getFallbackActivities(filters);
            this.renderActivities();
        }
    }

    getFallbackActivities(filters = {}) {
        // Include science-in-action templates as fallback - Updated to match science-in-action-examples.html
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
                title: 'Agricultural Drones & Vineyard',
                description: 'Discover how drones monitor crop health, detect diseases early, and optimize vineyard management through aerial technology.',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null,
                suggested_duration_minutes: 60,
                recommended_group_size: '8-12 students',
                status: 'published',
                featured_image: 'images/agricultural-drone-vineyard.png'
            },
            {
                id: 'science-3',
                title: 'Smart Irrigation Demo',
                description: 'Visit the smartest automatic irrigation plant in the Maresme - see precision water management and automated watering systems in action.',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null,
                suggested_duration_minutes: 45,
                recommended_group_size: '10-15 students',
                status: 'published',
                featured_image: 'images/smart-irrigation-demo.png'
            },
            {
                id: 'science-4',
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
                id: 'science-5',
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
            },
            {
                id: 'science-6',
                title: 'Wattle & Daub Construction',
                description: 'Harvest clay, then build a home with mud, hay, and sticks - 6,000-year-old sustainable construction techniques that still work today!',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null,
                suggested_duration_minutes: 120,
                recommended_group_size: '8-15 students',
                status: 'published',
                featured_image: 'images/wattle-daub-construction.png'
            },
            {
                id: 'science-7',
                title: 'Composting & Soil Science',
                description: 'Discover the science of decomposition, nutrient cycles, and soil health through hands-on composting and soil analysis.',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null,
                suggested_duration_minutes: 60,
                recommended_group_size: '10-20 students',
                status: 'published',
                featured_image: 'images/composting-farm-scene.png'
            },
            {
                id: 'science-8',
                title: 'Planting & Growing',
                description: 'Plant seeds, track growth, and discover the science of plant biology through hands-on gardening and data collection.',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null,
                suggested_duration_minutes: 90,
                recommended_group_size: '12-25 students',
                status: 'published',
                featured_image: 'images/school-visit-planting.png'
            },
            {
                id: 'science-9',
                title: 'SchoolAIR IoT Sensors',
                description: 'Build and program IoT environmental monitoring stations that collect real-time air quality and weather data.',
                activity_type: {
                    id: 'science-stations',
                    name: 'Science Stations',
                    slug: 'science-stations',
                    color: '#e91e63',
                    icon: '🔬'
                },
                date_time: null,
                suggested_duration_minutes: 75,
                recommended_group_size: '6-12 students',
                status: 'published',
                featured_image: 'images/school-visit-pond-canoe.png'
            }
        ];

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
            // For future activities, show both scheduled activities AND science-in-action templates (bookable)
            filteredActivities = filteredActivities.filter(activity => {
                // Include activities with future dates
                if (activity.date_time) {
                    const activityDate = new Date(activity.date_time);
                    return activityDate >= new Date();
                }
                // Include science-in-action templates (no date_time but bookable)
                if (!activity.date_time && activity.activity_type?.slug === 'science-stations') {
                    return true;
                }
                return false;
            })
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

        this.activityTypes.forEach(type => {

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

        const card = document.createElement('div');
        card.className = 'activity-card';

        // Get activity type from database structure (now joined)
        const activityType = activity.activity_type;
        const activityTypeSlug = activityType ? activityType.slug : 'other';

        card.setAttribute('data-type', activityTypeSlug);
        card.setAttribute('data-date', activity.date_time || 'TBD');

        // Special date handling for Pumpkin Patch
        let dateDisplay;
        let whatsappButton = '';
        if (activity.title && activity.title.includes('SCARY PUMPKIN PATCH')) {
            dateDisplay = 'October 10-31, 2025. Any time. Boo! us on WhatsApp first';
            whatsappButton = '<a href="https://chat.whatsapp.com/HnWhcfwNLenGKXMFOR6JUG" target="_blank" class="btn" style="background: #25D366 !important; color: white !important; border-color: #25D366 !important;">💬 Request Visit</a>';
        } else if (activity.date_time) {
            dateDisplay = new Date(activity.date_time).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
        } else {
            dateDisplay = 'Available on Request';
        }

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
                <p class="activity-description">${this.formatDescription(activity.description)}</p>
                <div style="display: flex; gap: 0.5rem; align-items: center; margin: 0.5rem 0;">
                    ${whatsappButton}
                    ${this.getActivityButton(activity)}
                </div>
                <div class="activity-details">
                    <span class="participants">${participantInfo}</span>
                    <span class="duration">${this.formatActivityDuration(activity)}</span>
                </div>
                <div class="activity-actions">
                    ${greensInfo}
                </div>
            </div>
        `;

        return card;
    }

    formatDescription(description) {
        if (!description) return '';

        // Convert WhatsApp URLs to buttons
        const whatsappRegex = /(https:\/\/chat\.whatsapp\.com\/[a-zA-Z0-9]+)/g;

        return description.replace(whatsappRegex, (url) => {
            return `<br><a href="${url}" target="_blank" style="display: inline-block; background: #25D366; color: white; padding: 0.5rem 1rem; border-radius: 6px; text-decoration: none; font-size: 0.85rem; font-weight: bold; margin-top: 0.5rem;">💬 Join WhatsApp</a>`;
        });
    }

    getActivityImage(activity) {
        // Use featured_image from database if available
        console.log(`🖼️ Activity "${activity.title}" - featured_image: ${JSON.stringify(activity.featured_image)}`);
        const imageSrc = activity.featured_image || this.getDefaultImageForActivity(activity);
        const correctedImagePath = this.getImagePath(imageSrc);
        console.log(`🖼️ Using image: ${imageSrc} → ${correctedImagePath}`);

        if (correctedImagePath) {
            return `<img src="${correctedImagePath}" alt="${activity.title}" class="activity-photo" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
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
            // School visits
            'Benjamin Franklin International School': 'images/school-visit-planting.png',
            'International School of Prague': 'images/prague-alella-bridge-vineyard.png',
            'Brainstorming Lunch': 'images/brainstorming-lunch.png',

            // Science-in-Action stations (exact matches from database)
            'Robotic Gardening': 'images/robotic-gardening-system.png',
            'Agricultural Drones & Vineyard': 'images/agricultural-drone-vineyard.png',
            'Smart Irrigation Demo': 'images/smart-irrigation-demo.png',
            'Erosion Challenge': 'images/swales.jpg',
            'Hydraulic Ram Pumps': 'images/hydraulic-ram-pump-system.png',
            'Wattle & Daub Construction': 'images/wattle-daub-construction.png',
            'Wattle and Daub Construction': 'images/wattle-daub-construction.png',
            'Composting & Soil Science': 'images/composting-farm-scene.png',
            'Planting & Growing': 'images/school-visit-planting.png',
            'SchoolAIR IoT Sensors': 'images/school-visit-pond-canoe.png',

            // Workshop session titles (scheduled_visits table)
            'Composting Workshop Session': 'images/composting-farm-scene.png',
            'Planting Workshop Session': 'images/school-visit-planting.png',
            'Erosion Control Workshop': 'images/swales.jpg',
            'Ram Pumps Workshop Session': 'images/hydraulic-ram-pump-system.png',
            'Robotic Gardening Workshop Session': 'images/robotic-gardening-system.png',
            'Wattle & Daub Workshop Session': 'images/wattle-daub-construction.png',
            'Smart Irrigation Workshop Session': 'images/smart-irrigation-demo.png',

            // Legacy workshop names for backwards compatibility (maps database workshop titles to correct images)
            'Build Your Own Ram Pump': 'images/hydraulic-ram-pump-system.png',
            'Ram Pump Workshop': 'images/hydraulic-ram-pump-system.png',
            'Ram Pumps Workshop': 'images/hydraulic-ram-pump-system.png',
            'Pumped Hydro': 'images/swales.jpg', // Actually maps to Erosion Challenge
            'Pumped Hydro Workshop': 'images/swales.jpg', // Actually maps to Erosion Challenge
            'Pumped Hydro Storage': 'images/swales.jpg', // Actually maps to Erosion Challenge
            'Robotic Gardening Workshop': 'images/robotic-gardening-system.png',
            'Wattle & Daub': 'images/wattle-daub-construction.png',
            'Wattle and Daub': 'images/wattle-daub-construction.png',
            'Wattle and Daub Construction': 'images/wattle-daub-construction.png',
            'Traditional Construction': 'images/wattle-daub-construction.png',
            'Agricultural Drones': 'images/agricultural-drone-vineyard.png',
            'Drone Vineyard Management': 'images/agricultural-drone-vineyard.png',
            'Composting Workshop': 'images/composting-farm-scene.png',
            'Planting Workshop': 'images/school-visit-planting.png',
            'SchoolAir IoT Monitoring': 'images/school-visit-pond-canoe.png',

            // Events
            'Sustainability Fair': 'images/event-sports-field.png',
            '2022 Mayday 4 Ukraine': 'images/event-sports-field.png',
            'Marina to the rescue': 'images/Marina to the rescue.png',
            'Prague meets Alella': 'images/prague meets alella.png',

            // Halloween Events
            'SCARY PUMPKIN PATCH - Pick Your Own Pumpkin 👻🎃': 'images/pumpkin-patch.jpg',
            'Halloween Party 2025 🎃👻': 'images/halloween-party.png',
            'Halloween Mini-Party 2025 🎃👻': 'images/halloween-party.png'
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
        // Don't show GREENs for events or workshops (they use different pricing)
        const activityType = activity.activity_type;
        const activityTypeSlug = activityType?.slug || 'other';
        const visitType = activity.visit_type; // For scheduled_visits table

        if (activityTypeSlug === 'events' ||
            activityTypeSlug === 'annual-events' ||
            activityTypeSlug === 'workshops' ||
            visitType === 'individual_workshop') {
            return ''; // No GREENs display for events or workshops
        }

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

        // Handle workshops (both scheduled and on-request)
        if (activityTypeSlug === 'workshops') {
            const detailsUrl = activity.details_page_url || '#';
            return `
                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                    <a href="${detailsUrl}" class="btn">Learn More</a>
                    <button class="btn btn-primary" onclick="app.handleActivityRegistration('${activity.id}', '${activity.title}')">Book</button>
                </div>
            `;
        }

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

            // Special handling for Halloween events - direct to checkout without login
            if (activity.title && activity.title.includes('SCARY PUMPKIN PATCH')) {
                return `<a href="/events/pumpkin-patch-checkout.html" class="btn btn-primary" style="background: #ff6b35 !important; border-color: #ff6b35 !important;">Book</a>`;
            }

            if (activity.title && activity.title.includes('Halloween Party 2025')) {
                return `
                    <div style="display: flex; gap: 0.5rem; align-items: center;">
                        <a href="/events/pumpkin-patch-checkout.html" class="btn btn-primary" style="background: #ff6b35 !important; border-color: #ff6b35 !important;">Book</a>
                        <a href="https://chat.whatsapp.com/HnWhcfwNLenGKXMFOR6JUG" target="_blank" class="btn btn-success" style="background: #25D366 !important; border-color: #25D366 !important; display: flex; align-items: center; gap: 0.3rem;">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="white">
                                <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/>
                            </svg>
                            WhatsApp
                        </a>
                    </div>
                `;
            }

            if (activity.title && activity.title.includes('Halloween Mini-Party 2025')) {
                return `<a href="/events/pumpkin-patch-checkout.html" class="btn btn-primary" style="background: #ff6b35 !important; border-color: #ff6b35 !important;">Book</a>`;
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
            return `<button class="btn btn-primary" onclick="app.handleActivityRegistration('${activity.id}', '${activity.title}')">Book</button>`;
        }

        // Use details_page_url if available, otherwise generic Learn More
        const detailsUrl = activity.details_page_url || '#';
        return `<a href="${detailsUrl}" class="btn">Learn More</a>`
    }

    async handleScienceStationBooking(activityId, activityTitle) {
        console.log('Booking science station:', activityTitle, 'ID:', activityId)

        if (!this.currentUser) {
            this.showAuthModal(activityId, activityTitle)
            return
        }

        // Load and show the booking modal
        await this.loadBookingModal()
        this.openBookingModal(activityId, activityTitle)
    }

    async loadBookingModal() {
        // Load the booking modal component if not already loaded
        const container = document.getElementById('booking-modal-container')
        if (container && !container.innerHTML.trim()) {
            try {
                const response = await fetch('/components/booking-modal.html')
                const html = await response.text()
                container.innerHTML = html
                console.log('📋 Booking modal loaded successfully')
            } catch (error) {
                console.error('❌ Failed to load booking modal:', error)
                this.showNotification('Failed to load booking form', 'error')
            }
        }
    }

    openBookingModal(activityId, activityTitle) {
        const modal = document.getElementById('booking-modal')
        const modalTitle = document.getElementById('booking-modal-title')

        if (!modal) {
            console.error('❌ Booking modal not found')
            return
        }

        // Set the activity details
        window.currentBookingActivity = { id: activityId, title: activityTitle }

        // Update modal title
        if (modalTitle) {
            modalTitle.textContent = `Book: ${activityTitle}`
        }

        // Reset to first step
        this.showBookingStep(1)

        // Load activity details and existing visits
        this.loadActivityBookingData(activityId)

        // Apply date restrictions
        this.applyBookingRestrictions()

        // Show modal
        modal.style.display = 'flex'
        document.body.style.overflow = 'hidden'

        console.log('📋 Booking modal opened for:', activityTitle)
    }

    async loadActivityBookingData(activityId) {
        try {
            // Get activity details
            const { data: activity, error: activityError } = await window.supabaseClient
                .from('activities')
                .select(`
                    *,
                    activity_type:activity_types!activity_type_id(*)
                `)
                .eq('id', activityId)
                .single()

            if (activityError) throw activityError

            // Update activity info in modal
            document.getElementById('min-participants').textContent = activity.min_participants || 5
            document.getElementById('price-per-person').textContent = activity.price_euros || 25
            document.getElementById('activity-duration').textContent = activity.duration_minutes
                ? `${Math.round(activity.duration_minutes / 60)} hours`
                : '2 hours'

            // Load existing bookings for this activity
            const { data: existingBookings, error: bookingsError } = await window.supabaseClient
                .from('booking_requests')
                .select('*')
                .eq('activity_id', activityId)
                .eq('status', 'pending')
                .gte('requested_date', new Date().toISOString())

            if (bookingsError) throw bookingsError

            // Show existing visits section if there are any
            const existingVisitsSection = document.getElementById('existing-visits-section')
            const existingVisitsList = document.getElementById('existing-visits-list')

            if (existingBookings && existingBookings.length > 0) {
                existingVisitsSection.style.display = 'block'
                existingVisitsList.innerHTML = existingBookings.map(booking => `
                    <div class="existing-visit-card" onclick="selectExistingBooking('${booking.id}')">
                        <div class="visit-date">
                            <strong>${new Date(booking.requested_date).toLocaleDateString()}</strong>
                            at ${new Date(booking.requested_date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                        </div>
                        <div class="visit-participants">
                            ${booking.current_participants} / ${booking.min_participants_needed} participants
                        </div>
                        <div class="visit-status">
                            ${booking.current_participants >= booking.min_participants_needed
                                ? '✅ Ready to confirm'
                                : '⏳ Needs more participants'}
                        </div>
                    </div>
                `).join('')
            } else {
                existingVisitsSection.style.display = 'none'
            }

        } catch (error) {
            console.error('❌ Failed to load booking data:', error)
            this.showNotification('Failed to load booking information', 'error')
        }
    }

    showBookingStep(stepNumber) {
        // Hide all steps
        for (let i = 1; i <= 3; i++) {
            const step = document.getElementById(`booking-step-${i}`)
            if (step) step.style.display = 'none'
        }

        // Show requested step
        const targetStep = document.getElementById(`booking-step-${stepNumber}`)
        if (targetStep) targetStep.style.display = 'block'
    }

    async setPaymentDeadlineAndNotify(booking, activity) {
        try {
            // Update booking status and set payment deadline
            const { error: updateError } = await window.supabaseClient
                .from('booking_requests')
                .update({
                    status: 'minimum_reached',
                    payment_deadline: new Date(Date.now() + 48*60*60*1000).toISOString()
                })
                .eq('id', booking.id);

            if (updateError) throw updateError;

            // Send payment required email immediately
            await this.sendPaymentRequiredEmail(booking, activity);

            // Log email
            await this.logEmail(booking.id, null, 'payment_required', this.currentUser.email);

        } catch (error) {
            console.error('❌ Failed to set payment deadline:', error);
        }
    }

    async sendRecruitmentEmail(booking, activity) {
        try {
            if (!this.currentUser || !this.currentUser.email) {
                console.log('No user email available for recruitment email');
                return;
            }

            const shareUrl = `${window.location.origin}${window.location.pathname}?booking=${booking.id}`;
            const participantsNeeded = (activity.min_participants || 5) - booking.participants_requested;

            const emailData = {
                to: this.currentUser.email,
                subject: `Booking Created - Help us reach ${activity.min_participants || 5} participants: ${activity.title}`,
                html: `
                    <h2>📅 Your booking request has been created!</h2>
                    <p>Hi ${this.currentUser.name || 'there'},</p>

                    <p>You've successfully requested a session for <strong>${activity.title}</strong>.</p>

                    <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 15px 0;">
                        <h3>📅 Booking Details</h3>
                        <p><strong>Activity:</strong> ${activity.title}</p>
                        <p><strong>Requested Date:</strong> ${new Date(booking.requested_date).toLocaleDateString()}</p>
                        <p><strong>Time:</strong> ${new Date(booking.requested_date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</p>
                        <p><strong>Your participants:</strong> ${booking.participants_requested}</p>
                        <p><strong>Still needed:</strong> ${participantsNeeded} more participants</p>
                        <p><strong>Booking ID:</strong> ${booking.id.substring(0, 8)}</p>
                    </div>

                    <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #ffc107;">
                        <h3>🤝 Help Us Reach the Minimum!</h3>
                        <p>We need <strong>${participantsNeeded} more participants</strong> to make this session happen.</p>
                        <p><strong>Share this link</strong> with friends, family, and colleagues:</p>
                    </div>

                    <div style="background: #e7f3ff; padding: 15px; border-radius: 4px; margin: 15px 0; text-align: center;">
                        <p style="margin: 0 0 10px 0; font-weight: bold;">Invitation Link:</p>
                        <a href="${shareUrl}" style="color: #007bff; text-decoration: none; font-weight: bold; word-break: break-all;">
                            ${shareUrl}
                        </a>
                        <p style="margin: 10px 0 0 0; font-size: 14px; color: #666;">
                            Copy and paste this link to invite others!
                        </p>
                    </div>

                    <h3>📋 What happens next?</h3>
                    <ul>
                        <li><strong>Share the link</strong> - The more people you invite, the better!</li>
                        <li><strong>When we reach ${activity.min_participants || 5} participants</strong> - Everyone gets notified</li>
                        <li><strong>Payment time</strong> - You'll have 48 hours to complete payment</li>
                        <li><strong>Session confirmed</strong> - Once everyone pays, your activity is booked!</li>
                    </ul>

                    <div style="background: #d4edda; padding: 10px; border-radius: 4px; margin: 15px 0;">
                        <p style="margin: 0; font-size: 14px;">
                            💡 <strong>Tip:</strong> Share on WhatsApp, email to friends, or post in group chats to fill spots quickly!
                        </p>
                    </div>

                    <p>Questions? Reply to this email or contact us at info@alellagreentech.org</p>

                    <p>Thanks,<br>The GUIDAL Team</p>
                `
            };

            await this.sendEmail(emailData);

            // Log email
            await this.logEmail(booking.id, null, 'recruitment', this.currentUser.email);

            console.log('✅ Recruitment email sent');

        } catch (error) {
            console.error('❌ Failed to send recruitment email:', error);
        }
    }

    async sendPaymentRequiredEmail(booking, activity) {
        try {
            if (!this.currentUser || !this.currentUser.email) {
                console.log('No user email available for payment email');
                return;
            }

            const paymentDeadline = new Date(Date.now() + 48*60*60*1000);
            const pricePerPerson = activity.price_euros || 25;
            const totalAmount = pricePerPerson * booking.participants_requested;

            const emailData = {
                to: this.currentUser.email,
                subject: `🎉 Session Confirmed! Payment Required: ${activity.title}`,
                html: `
                    <h2>🎉 Congratulations! Your session is confirmed!</h2>
                    <p>Hi ${this.currentUser.name || 'there'},</p>

                    <p>Great news! We have enough participants for your <strong>${activity.title}</strong> session.</p>

                    <div style="background: #d4edda; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #28a745;">
                        <h3>📅 Confirmed Session Details</h3>
                        <p><strong>Activity:</strong> ${activity.title}</p>
                        <p><strong>Date:</strong> ${new Date(booking.requested_date).toLocaleDateString()}</p>
                        <p><strong>Time:</strong> ${new Date(booking.requested_date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</p>
                        <p><strong>Total participants:</strong> ${booking.current_participants || booking.participants_requested}</p>
                        <p><strong>Your participants:</strong> ${booking.participants_requested}</p>
                    </div>

                    <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #ffc107;">
                        <h3>💳 Payment Required</h3>
                        <p><strong>Amount due:</strong> €${totalAmount} (€${pricePerPerson} × ${booking.participants_requested} participants)</p>
                        <p><strong>Payment deadline:</strong> ${paymentDeadline.toLocaleDateString()} at ${paymentDeadline.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</p>
                        <p><strong>Time remaining:</strong> 48 hours</p>
                    </div>

                    <div style="background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 15px 0;">
                        <h3>💳 How to Pay</h3>
                        <p>Payment instructions and secure payment link will be sent in a separate email within the next few minutes.</p>
                        <p><strong>Or contact us directly:</strong></p>
                        <ul>
                            <li>Email: payments@alellagreentech.org</li>
                            <li>Phone: [Phone number]</li>
                            <li>Reference: Booking #${booking.id.substring(0, 8)}</li>
                        </ul>
                    </div>

                    <h3>⚠️ Important Notes</h3>
                    <ul>
                        <li><strong>48-hour deadline:</strong> Payment must be completed within 48 hours to secure your spots</li>
                        <li><strong>All participants must pay:</strong> The session is only confirmed once everyone has paid</li>
                        <li><strong>Automatic cancellation:</strong> If not all participants pay by the deadline, the session will be cancelled</li>
                    </ul>

                    <p>Questions about payment? Reply to this email or contact us at info@alellagreentech.org</p>

                    <p>Thanks,<br>The GUIDAL Team</p>
                `
            };

            await this.sendEmail(emailData);
            console.log('✅ Payment required email sent');

        } catch (error) {
            console.error('❌ Failed to send payment required email:', error);
        }
    }

    async sendMinimumReachedNotification(booking, activity) {
        try {
            // Get all participants for this booking
            const { data: participants, error } = await window.supabaseClient
                .from('booking_participants')
                .select(`
                    *,
                    user:profiles!user_id(email, name)
                `)
                .eq('booking_request_id', booking.id);

            if (error) throw error;

            // Send email to each unique participant
            const uniqueEmails = [...new Set(participants.map(p => p.user.email).filter(email => email))];

            for (const email of uniqueEmails) {
                const participant = participants.find(p => p.user.email === email);
                const pricePerPerson = activity.price_euros || 25;
                const totalAmount = pricePerPerson * participant.participants_count;

                const emailData = {
                    to: email,
                    subject: `🎉 Minimum Reached! Payment Required: ${activity.title}`,
                    html: `
                        <h2>🎉 Great news! Your session has reached minimum participants!</h2>
                        <p>Hi ${participant.user.name || 'there'},</p>

                        <p>Excellent! We now have enough participants for the <strong>${activity.title}</strong> session you joined.</p>

                        <div style="background: #d4edda; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #28a745;">
                            <h3>📅 Session Details</h3>
                            <p><strong>Activity:</strong> ${activity.title}</p>
                            <p><strong>Date:</strong> ${new Date(booking.requested_date).toLocaleDateString()}</p>
                            <p><strong>Time:</strong> ${new Date(booking.requested_date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</p>
                            <p><strong>Total participants:</strong> ${booking.current_participants}</p>
                            <p><strong>Your participants:</strong> ${participant.participants_count}</p>
                        </div>

                        <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #ffc107;">
                            <h3>💳 Payment Required</h3>
                            <p>You have <strong>48 hours</strong> to complete your payment to secure your spot.</p>
                            <p><strong>Amount due:</strong> €${totalAmount} (€${pricePerPerson} × ${participant.participants_count} participants)</p>
                            <p><strong>Payment deadline:</strong> ${new Date(Date.now() + 48*60*60*1000).toLocaleString()}</p>
                        </div>

                        <p><strong>Payment instructions will be sent in a separate email shortly.</strong></p>

                        <p>Once all participants complete payment, your session will be officially confirmed!</p>

                        <p>Thanks,<br>The GUIDAL Team</p>
                    `
                };

                await this.sendEmail(emailData);

                // Log email for this participant
                await this.logEmail(booking.id, participant.id, 'minimum_reached', email);
            }

            console.log('✅ Minimum reached emails sent to all participants');

        } catch (error) {
            console.error('❌ Failed to send minimum reached emails:', error);
        }
    }

    async logEmail(bookingId, participantId, emailType, recipientEmail, emailData = {}) {
        try {
            await window.supabaseClient
                .from('booking_email_log')
                .insert({
                    booking_request_id: bookingId,
                    participant_id: participantId,
                    email_type: emailType,
                    recipient_email: recipientEmail,
                    email_data: emailData
                });

            console.log(`📧 Email logged: ${emailType} to ${recipientEmail}`);
        } catch (error) {
            console.error('❌ Failed to log email:', error);
            // Don't throw - email logging failure shouldn't break the flow
        }
    }

    updateBookingStatusUI(booking, uiStatus, activity) {
        try {
            const statusBadge = document.getElementById('booking-status-badge');
            const paymentStatusItem = document.getElementById('payment-status-item');
            const paymentDeadlineItem = document.getElementById('payment-deadline-item');
            const paymentActionBtn = document.getElementById('payment-action-btn');
            const shareSection = document.querySelector('.share-section');

            if (!statusBadge) return;

            switch (uiStatus) {
                case 'recruiting':
                    statusBadge.textContent = 'Waiting for more participants';
                    statusBadge.className = 'status-badge status-pending';
                    paymentStatusItem.style.display = 'none';
                    paymentDeadlineItem.style.display = 'none';
                    paymentActionBtn.style.display = 'none';
                    if (shareSection) shareSection.style.display = 'block';
                    break;

                case 'payment_required':
                    statusBadge.textContent = 'Payment Required';
                    statusBadge.className = 'status-badge status-payment-required';

                    // Show payment status
                    paymentStatusItem.style.display = 'block';
                    document.getElementById('payment-status').textContent = 'Pending Payment';

                    // Show payment deadline
                    paymentDeadlineItem.style.display = 'block';
                    const deadline = new Date(Date.now() + 48*60*60*1000);
                    document.getElementById('payment-deadline').textContent =
                        deadline.toLocaleDateString() + ' at ' + deadline.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

                    // Show payment button
                    paymentActionBtn.style.display = 'inline-block';

                    // Hide share section since minimum is reached
                    if (shareSection) shareSection.style.display = 'none';

                    // Update the success message
                    const successMessage = document.querySelector('.success-message h3');
                    if (successMessage) {
                        successMessage.textContent = 'Session Ready! Payment Required';
                    }

                    // Update what happens next
                    const nextStepsList = document.querySelector('.next-steps ul');
                    if (nextStepsList) {
                        nextStepsList.innerHTML = `
                            <li>Complete your payment within <strong>48 hours</strong> to secure your spot</li>
                            <li>Once all participants pay, your session will be confirmed</li>
                            <li>You'll receive a final confirmation email with all details</li>
                        `;
                    }
                    break;

                case 'confirmed':
                    statusBadge.textContent = 'Session Confirmed';
                    statusBadge.className = 'status-badge status-confirmed';

                    paymentStatusItem.style.display = 'block';
                    document.getElementById('payment-status').textContent = 'Payment Complete';

                    paymentDeadlineItem.style.display = 'none';
                    paymentActionBtn.style.display = 'none';
                    if (shareSection) shareSection.style.display = 'none';
                    break;
            }

            console.log(`✅ UI updated for status: ${uiStatus}`);

        } catch (error) {
            console.error('❌ Failed to update booking status UI:', error);
        }
    }

    async sendEmail(emailData) {
        // Simple email service integration
        // In production, this would use a service like Resend, SendGrid, or EmailJS

        try {
            // For now, we'll use EmailJS for client-side email sending
            // You'll need to configure EmailJS with your service

            console.log('📧 Email would be sent:', {
                to: emailData.to,
                subject: emailData.subject,
                preview: emailData.html.substring(0, 100) + '...'
            });

            // Placeholder for actual email service integration
            // await emailjs.send('service_id', 'template_id', emailData);

            // For development, show notification instead
            this.showNotification(`Email sent: ${emailData.subject}`, 'success');

        } catch (error) {
            console.error('❌ Email service error:', error);
            throw error;
        }
    }

    applyBookingRestrictions() {
        // Apply date and time restrictions from admin configuration
        const dateInput = document.getElementById('booking-date')
        const timeSelect = document.getElementById('booking-time')
        const restrictionsDiv = document.getElementById('date-restrictions')

        if (!dateInput || !timeSelect) return

        // Get restrictions from admin config if available
        const restrictions = window.getBookingRestrictions ? window.getBookingRestrictions() : null

        if (restrictions) {
            // Set min and max dates
            dateInput.min = restrictions.minDate
            dateInput.max = restrictions.maxDate

            // Update time options from admin config
            if (window.bookingConfigManager) {
                window.bookingConfigManager.updateBookingModalTimeOptions()
            }

            // Add date validation
            dateInput.addEventListener('change', (e) => {
                const selectedDate = e.target.value
                if (window.isDateBlocked && window.isDateBlocked(selectedDate)) {
                    alert('This date is not available for booking. Please select another date.')
                    e.target.value = ''
                    return
                }

                // Check day of week restrictions
                const dateObj = new Date(selectedDate)
                const dayOfWeek = dateObj.getDay()
                if (restrictions.blockedDays.includes(dayOfWeek)) {
                    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
                    alert(`${dayNames[dayOfWeek]}s are not available for booking. Please select another date.`)
                    e.target.value = ''
                }
            })

            // Show restrictions info
            let restrictionsText = []
            if (restrictions.blockedDays.length > 0) {
                const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
                const blockedDayNames = restrictions.blockedDays.map(d => dayNames[d])
                restrictionsText.push(`Not available: ${blockedDayNames.join(', ')}`)
            }

            if (restrictions.blockedRanges.length > 0) {
                restrictionsText.push(`${restrictions.blockedRanges.length} blocked date range(s)`)
            }

            if (restrictionsText.length > 0) {
                restrictionsDiv.innerHTML = `<small>📅 ${restrictionsText.join(' • ')}</small>`
            }
        } else {
            // Default restrictions if no admin config
            const today = new Date()
            const minDate = new Date(today)
            minDate.setDate(today.getDate() + 7) // 7 days advance booking

            const maxDate = new Date(today)
            maxDate.setDate(today.getDate() + 365) // 1 year max

            dateInput.min = minDate.toISOString().split('T')[0]
            dateInput.max = maxDate.toISOString().split('T')[0]

            restrictionsDiv.innerHTML = '<small>📅 Minimum 7 days advance booking required</small>'
        }
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

                // If there was a pending booking from share link, handle it
                const pendingBookingId = sessionStorage.getItem('pendingBookingId');
                if (pendingBookingId) {
                    sessionStorage.removeItem('pendingBookingId');
                    setTimeout(() => {
                        handleShareLink(pendingBookingId);
                    }, 1000); // Small delay to ensure UI is ready
                }
            } else if (event === 'SIGNED_OUT') {
                this.currentUser = null;
                this.updateUIForLoggedOutUser();
            }
        });
    }

    updateUIForLoggedInUser() {
        console.log('🔧 updateUIForLoggedInUser called');
        console.log('👤 Current user:', this.currentUser);

        const loginBtn = document.querySelector('.login-btn');
        console.log('🔘 Login button found:', loginBtn);

        // Check if auth-nav.js has already created a user menu
        const userMenuContainer = document.querySelector('.user-menu-container');
        if (userMenuContainer) {
            console.log('✅ User menu already created by auth-nav.js, skipping app.js update');
            // Just update activity buttons
            this.renderActivities();
            return;
        }

        // If we reach here, auth-nav.js hasn't loaded yet (shouldn't happen normally)
        // Just skip - auth-nav.js will handle it when it loads
        console.log('⚠️ auth-nav.js has not created user menu yet, skipping app.js fallback');

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
            loginBtn.href = this.getAuthPath('login.html');
        }

        // Update auth link in About section
        const authLink = document.getElementById('auth-link');
        if (authLink) {
            authLink.textContent = 'Register to get started!';
            authLink.href = this.getAuthPath('login.html');
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
            const pragueRegisterUrl = `${this.getAuthPath('register-prague.html')}?returnTo=${currentUrl}`;
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
                const registerUrl = `${this.getAuthPath('register.html')}?returnTo=${currentUrl}`;
                window.location.href = registerUrl;
            } else {
                // Redirect to login with return URL
                const loginUrl = `${this.getAuthPath('login.html')}?return_url=${currentUrl}`;
                window.location.href = loginUrl;
            }
        } else {
            // Default to login
            const loginUrl = `${this.getAuthPath('login.html')}?return_url=${currentUrl}`;
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

    // Check for share link in URL
    const urlParams = new URLSearchParams(window.location.search);
    const bookingId = urlParams.get('booking');
    if (bookingId) {
        console.log('📋 Detected share link for booking:', bookingId);
        setTimeout(() => {
            handleShareLink(bookingId);
        }, 2000); // Wait for app to fully initialize
    }
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

// Global booking modal functions
function closeBookingModal() {
    const modal = document.getElementById('booking-modal');
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = 'auto';
    }
}

function showStep(stepNumber) {
    if (window.app && window.app.showBookingStep) {
        window.app.showBookingStep(stepNumber);
    }
}

async function createNewBooking() {
    const date = document.getElementById('booking-date').value;
    const time = document.getElementById('booking-time').value;
    const participants = document.getElementById('participants-count').value;

    if (!date || !time) {
        alert('Please select both date and time');
        return;
    }

    if (!window.currentBookingActivity) {
        console.error('No current booking activity');
        return;
    }

    try {
        // Create datetime string
        const requestedDate = new Date(`${date}T${time}:00`);

        // Create booking request
        const { data, error } = await window.supabaseClient
            .from('booking_requests')
            .insert({
                activity_id: window.currentBookingActivity.id,
                requested_date: requestedDate.toISOString(),
                participants_requested: parseInt(participants),
                current_participants: parseInt(participants),
                status: 'pending'
            })
            .select()
            .single();

        if (error) throw error;

        // Update modal with booking details
        document.getElementById('selected-date-display').textContent =
            requestedDate.toLocaleDateString() + ' at ' + requestedDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        document.getElementById('current-count').textContent = participants;
        document.getElementById('booking-reference').textContent = data.id.substring(0, 8);

        // Generate share link
        const shareUrl = `${window.location.origin}${window.location.pathname}?booking=${data.id}`;
        document.getElementById('share-link').value = shareUrl;

        // Determine if minimum participants reached immediately
        const meetsMinimum = participants >= (activity.min_participants || 5);

        if (meetsMinimum) {
            // Set payment deadline and send payment email
            await this.setPaymentDeadlineAndNotify(data, window.currentBookingActivity);

            // Update UI for payment required
            this.updateBookingStatusUI(data, 'payment_required', activity);
        } else {
            // Send recruitment email with share link
            await this.sendRecruitmentEmail(data, window.currentBookingActivity);

            // Update UI for recruitment phase
            this.updateBookingStatusUI(data, 'recruiting', activity);
        }

        // Show success step
        showStep(2);

    } catch (error) {
        console.error('❌ Failed to create booking:', error);
        alert('Failed to create booking: ' + error.message);
    }
}

function selectExistingBooking(bookingId) {
    window.selectedBookingId = bookingId;
    showStep(3);

    // Load booking details for step 3
    loadJoinBookingDetails(bookingId);
}

async function loadJoinBookingDetails(bookingId) {
    try {
        const { data: booking, error } = await window.supabaseClient
            .from('booking_requests')
            .select(`
                *,
                activity:activities(title, description)
            `)
            .eq('id', bookingId)
            .single();

        if (error) throw error;

        const detailsContainer = document.getElementById('join-booking-details');
        detailsContainer.innerHTML = `
            <div class="booking-details-card">
                <h4>${booking.activity.title}</h4>
                <p><strong>Date:</strong> ${new Date(booking.requested_date).toLocaleDateString()}</p>
                <p><strong>Time:</strong> ${new Date(booking.requested_date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</p>
                <p><strong>Current participants:</strong> ${booking.current_participants} / ${booking.min_participants_needed || 5}</p>
                <p><strong>Status:</strong> ${booking.current_participants >= (booking.min_participants_needed || 5)
                    ? '✅ Ready to confirm'
                    : '⏳ Needs more participants'}</p>
            </div>
        `;

    } catch (error) {
        console.error('❌ Failed to load booking details:', error);
        document.getElementById('join-booking-details').innerHTML = '<p>Failed to load booking details</p>';
    }
}

async function joinExistingBooking() {
    const participants = document.getElementById('join-participants-count').value;

    if (!window.selectedBookingId) {
        console.error('No booking selected');
        return;
    }

    try {
        // Add participant to existing booking
        const { data, error } = await window.supabaseClient
            .from('booking_participants')
            .insert({
                booking_request_id: window.selectedBookingId,
                user_id: window.app.currentUser.id,
                participants_count: parseInt(participants)
            });

        if (error) throw error;

        // Update booking participant count
        const { error: updateError } = await window.supabaseClient
            .rpc('increment_booking_participants', {
                booking_id: window.selectedBookingId,
                participant_count: parseInt(participants)
            });

        if (updateError) throw updateError;

        // Get updated booking info for email notifications
        const { data: updatedBooking, error: fetchError } = await window.supabaseClient
            .from('booking_requests')
            .select(`
                *,
                activity:activities(*)
            `)
            .eq('id', window.selectedBookingId)
            .single();

        if (!fetchError && updatedBooking) {
            // Check if minimum just reached with this join
            const minimumJustReached = await window.supabaseClient
                .rpc('check_minimum_participants', { p_booking_id: window.selectedBookingId });

            if (minimumJustReached.data) {
                // Minimum was just reached - send milestone emails to all participants
                await window.app.sendMinimumReachedNotification(updatedBooking, updatedBooking.activity);
            }
        }

        alert('Successfully joined the booking!');
        closeBookingModal();

    } catch (error) {
        console.error('❌ Failed to join booking:', error);
        alert('Failed to join booking: ' + error.message);
    }
}

function copyShareLink() {
    const shareLink = document.getElementById('share-link');
    shareLink.select();
    shareLink.setSelectionRange(0, 99999); // For mobile devices

    try {
        document.execCommand('copy');

        // Show temporary feedback
        const copyBtn = event.target;
        const originalText = copyBtn.textContent;
        copyBtn.textContent = 'Copied!';
        copyBtn.style.background = '#28a745';

        setTimeout(() => {
            copyBtn.textContent = originalText;
            copyBtn.style.background = '#007bff';
        }, 2000);

    } catch (err) {
        console.error('Failed to copy link:', err);
        alert('Failed to copy link. Please copy manually.');
    }
}

function shareViaEmail() {
    const shareUrl = document.getElementById('share-link').value;
    const subject = encodeURIComponent(`Join my activity booking - ${window.currentBookingActivity?.title || 'Activity'}`);
    const body = encodeURIComponent(`Hi! I've requested a booking for "${window.currentBookingActivity?.title || 'an activity'}" and we need more participants to make it happen. Join me using this link: ${shareUrl}`);

    window.open(`mailto:?subject=${subject}&body=${body}`);
}

function shareViaWhatsApp() {
    const shareUrl = document.getElementById('share-link').value;
    const message = encodeURIComponent(`Hi! I've requested a booking for "${window.currentBookingActivity?.title || 'an activity'}" and we need more participants to make it happen. Join me: ${shareUrl}`);

    window.open(`https://wa.me/?text=${message}`);
}

async function handleShareLink(bookingId) {
    try {
        // Get booking details
        const { data: booking, error } = await window.supabaseClient
            .from('booking_requests')
            .select(`
                *,
                activity:activities(*)
            `)
            .eq('id', bookingId)
            .single();

        if (error) throw error;

        console.log('📋 Share link booking found:', booking);

        // Check if user is logged in
        if (!window.app.currentUser) {
            // Store booking ID for after login
            sessionStorage.setItem('pendingBookingId', bookingId);
            window.app.showNotification('Please log in to join this booking', 'info');
            // Redirect to login or show login modal
            window.location.href = '/pages/auth/login.html';
            return;
        }

        // Load booking modal and pre-populate with this booking
        await window.app.loadBookingModal();

        // Set current activity
        window.currentBookingActivity = {
            id: booking.activity.id,
            title: booking.activity.title
        };

        // Set selected booking
        window.selectedBookingId = bookingId;

        // Open modal directly to join step
        const modal = document.getElementById('booking-modal');
        const modalTitle = document.getElementById('booking-modal-title');

        if (modalTitle) {
            modalTitle.textContent = `Join: ${booking.activity.title}`;
        }

        showStep(3);
        await loadJoinBookingDetails(bookingId);

        modal.style.display = 'flex';
        document.body.style.overflow = 'hidden';

        window.app.showNotification(`Ready to join "${booking.activity.title}"!`, 'success');

    } catch (error) {
        console.error('❌ Failed to handle share link:', error);
        window.app.showNotification('Invalid or expired booking link', 'error');
    }
}

function proceedToPayment() {
    // Placeholder for payment processing
    // In production, this would integrate with Stripe, PayPal, or other payment processor

    if (!window.currentBookingActivity) {
        alert('Booking information not found');
        return;
    }

    const bookingId = document.getElementById('booking-reference').textContent;
    const activity = window.currentBookingActivity;

    // For now, show payment information
    const paymentInfo = `
Payment Information:

Activity: ${activity.title}
Booking ID: ${bookingId}
Amount: €${activity.price_euros || 25} per person

Payment Methods:
- Bank Transfer
- Credit/Debit Card
- PayPal

You will receive payment instructions via email shortly.

Contact: payments@alellagreentech.org
Phone: [Phone number]
    `;

    alert(paymentInfo);

    // In production, this would:
    // 1. Open payment processor (Stripe checkout, PayPal, etc.)
    // 2. Handle payment success/failure
    // 3. Update participant payment status in database
    // 4. Send confirmation emails
    // 5. Update UI to show payment complete status

    console.log('🔄 Payment process initiated for booking:', bookingId);
}

// Make booking functions available globally
window.closeBookingModal = closeBookingModal;
window.showStep = showStep;
window.createNewBooking = createNewBooking;
window.selectExistingBooking = selectExistingBooking;
window.joinExistingBooking = joinExistingBooking;
window.copyShareLink = copyShareLink;
window.shareViaEmail = shareViaEmail;
window.shareViaWhatsApp = shareViaWhatsApp;
window.proceedToPayment = proceedToPayment;

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