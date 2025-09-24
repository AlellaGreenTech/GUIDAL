// Visit Planning Form JavaScript
// Simplified version matching the Google Form structure

class VisitPlanningForm {
    constructor() {
        console.log('🏗️ Constructing VisitPlanningForm...');

        this.form = document.getElementById('visitPlanningForm');
        this.workshopGrid = document.getElementById('workshopGrid');
        this.selectedWorkshops = new Set();
        this.availableWorkshops = [];

        console.log('🔍 Form element found:', !!this.form);
        console.log('🔍 WorkshopGrid element found:', !!this.workshopGrid);
        console.log('🔍 WorkshopGrid element:', this.workshopGrid);

        if (!this.form) {
            console.error('❌ visitPlanningForm element not found');
        }

        if (!this.workshopGrid) {
            console.error('❌ workshopGrid element not found');
            console.log('🔍 All elements with class workshop-grid:', document.querySelectorAll('.workshop-grid'));
            console.log('🔍 All elements with id containing "workshop":', document.querySelectorAll('[id*="workshop"]'));

            // Try to find it manually and set a test message
            const manualGrid = document.querySelector('#workshopGrid');
            if (manualGrid) {
                console.log('✅ Found workshopGrid manually, setting test content');
                manualGrid.innerHTML = '<p style="color: red; padding: 1rem; border: 2px solid red;">MANUAL TEST: WorkshopGrid element found and accessible</p>';
                this.workshopGrid = manualGrid;
            } else {
                console.log('❌ Could not find workshopGrid even manually');
            }
        } else {
            // Test if we can write to it
            console.log('✅ Testing write access to workshopGrid');
            this.workshopGrid.innerHTML = '<p style="color: green; padding: 1rem; border: 2px solid green;">TEST: WorkshopGrid is accessible and writable</p>';

        }

        this.init();
    }

    async init() {
        try {
            console.log('🎓 Initializing Visit Planning Form...');

            // Test database connection first
            await this.testDatabaseConnection();

            // Load available workshops and activities
            console.log('🔄 About to call loadWorkshops()');
            await this.loadWorkshops();
            console.log('✅ loadWorkshops() completed, workshops loaded:', this.availableWorkshops.length);

            // Set up form event listeners
            this.setupEventListeners();

            console.log('✅ Visit Planning Form initialized successfully');
        } catch (error) {
            console.error('❌ Error initializing Visit Planning Form:', error);
            this.showError('Failed to load form. Please refresh the page.');
        }
    }

    async testDatabaseConnection() {
        try {
            // Use GuidalDB's built-in test function
            if (typeof GuidalDB !== 'undefined' && GuidalDB.testConnection) {
                const result = await GuidalDB.testConnection();
                if (result) {
                    console.log('✅ Database connection successful');
                    return;
                }
            }

            // Fallback test using supabaseClient if available
            if (typeof supabaseClient !== 'undefined') {
                const { data, error } = await supabaseClient
                    .from('activities')
                    .select('id')
                    .limit(1);

                if (error) {
                    throw error;
                }
                console.log('✅ Database connection successful (fallback)');
                return;
            }

            throw new Error('No database client available');
        } catch (error) {
            console.error('❌ Database connection failed:', error);
            throw new Error('Database connection failed: ' + error.message);
        }
    }

    async loadWorkshops() {
        try {
            console.log('🔍 Loading available workshops...');

            // Use the working GuidalDB approach that we know works
            if (typeof GuidalDB !== 'undefined') {
                console.log('✅ Using GuidalDB approach');
                const activities = await GuidalDB.getActivities();

                // Debug: let's see what we have
                console.log('🔍 All activities before filtering:', activities?.map(a => ({
                    title: a.title,
                    type: a.activity_type?.name,
                    type_name: a.type_name,
                    status: a.status
                })));

                // Skip all database activities - we only want our static science-in-action stations
                this.availableWorkshops = [];
                console.log('🚫 Skipping all database activities, using only static science-in-action stations');
            } else {
                console.log('⚠️ GuidalDB not available, using direct supabaseClient');

                // Fallback to direct supabase client
                let { data: activities, error } = await supabaseClient
                    .from('activities')
                    .select(`
                        *,
                        activity_type:activity_types(*)
                    `)
                    .eq('status', 'published')
                    .order('title');

                // If complex query fails, try simple
                if (error) {
                    console.warn('Complex query failed, trying simple:', error);
                    const { data: simpleActivities, error: simpleError } = await supabaseClient
                        .from('activities')
                        .select('*')
                        .eq('status', 'published')
                        .order('title');

                    if (simpleError) {
                        throw simpleError;
                    }
                    activities = simpleActivities;
                }

                // Skip all database activities - we only want our static science-in-action stations
                this.availableWorkshops = [];
                console.log('🚫 Skipping all database activities, using only static science-in-action stations');
            }

            console.log(`📋 Loaded ${this.availableWorkshops.length} available workshops`);
            console.log('🔍 Workshop details:', this.availableWorkshops.map(w => ({
                title: w.title,
                slug: w.slug,
                type: w.activity_type?.name,
                status: w.status,
                image: w.featured_image
            })));

            console.log('🎨 About to call renderWorkshops()');
            this.renderWorkshops();
            console.log('✅ renderWorkshops() completed');

        } catch (error) {
            console.error('❌ Error loading workshops:', error);
            this.workshopGrid.innerHTML = '<p>Error loading workshops. Please try refreshing the page.</p>';
        }
    }

    renderWorkshops() {
        console.log('🎨 Starting renderWorkshops()');
        console.log('📊 Available workshops count:', this.availableWorkshops.length);
        console.log('🎯 Workshop grid element:', this.workshopGrid);

        // Science-in-Action stations will be added, so always continue
        if (false) {
            console.log('⚠️ No workshops to render');
            this.workshopGrid.innerHTML = `
                <div style="grid-column: 1 / -1; text-align: center; padding: 2rem;">
                    <h4>No Science-in-Action Stations Available</h4>
                    <p>Please contact us directly to discuss available activities.</p>
                </div>
            `;
            return;
        }

        if (!this.workshopGrid) {
            console.error('❌ Workshop grid element not found!');
            return;
        }

        // Group workshops by activity type
        const workshopsByType = this.availableWorkshops.reduce((acc, workshop) => {
            const type = workshop.activity_type?.name || 'Science-in-Action Stations';
            if (!acc[type]) acc[type] = [];
            acc[type].push(workshop);
            return acc;
        }, {});

        console.log('📂 Workshops grouped by type:', Object.keys(workshopsByType));
        console.log('📊 Group counts:', Object.fromEntries(Object.entries(workshopsByType).map(([k,v]) => [k, v.length])));

        // Render ALL science-in-action activities with complete details
        console.log('🎨 Rendering all science-in-action activities...');

        let html = ``;

        // Using simple image paths instead of complex thumbnail mapping
        /*const thumbnailMapping = {
            'ram pump': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAB4AKADASIAAhEBAxEB/8QAHAAAAgMBAQEBAAAAAAAAAAAAAAUEBgcDCAIB/8QAQxAAAgECBAMGAgcGBAUFAAAAAQIDBAUABhIhMUFRBxMiYXGBkaGxFCMyQlLB0fAkM2Jy4fEVJYKSohajs8LiFyVDRGL/xAAaAQACAwEBAAAAAAAAAAAAAAAAAQIDBAUG/8QAJxEAAgICAgICAgIDAQAAAAAAAAECAxEEIRIxQVEFEyJhFDJxkf/aAAwDAQACEQMRAD8A3GlqqevpYqmknjqKapjWSGWJgyOjDYgg7g4wYMGEMGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgPJfaZFVUfbbmWlpoTNPJUWyVIUyUhKkQVRJuBj2ph5fTU9d2k2e3R/aNa+4yxUNRJqjKzM7BZBrsP3h/jW2GDBgwYMGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgwgGDBgw';
            'composting': 'data:image/jpeg;base64,...', // Composting image
            'erosion': 'data:image/jpeg;base64,...', // Erosion image
            'planting': 'data:image/jpeg;base64,...', // Planting image
            'hydro': 'data:image/jpeg;base64,...', // Hydro electric image
            'wattle': 'data:image/jpeg;base64,...' // Wattle and daub image
        };*/

        // Science-in-Action stations matching the cards on the science-in-action page
        const additionalActivities = [
            {
                id: 'robotic-gardening',
                title: '🤖 Robotic Gardening',
                description: 'Tend your garden from 1,000km away - or let the bot do it! Explore automated agriculture and precision farming with real robotic systems.',
                duration_minutes: 90,
                max_participants: 25,
                activity_type: { name: 'Science-in-Action' },
                slug: 'robotic-gardening',
                featured_image: '../images/thumbnails/robotic-gardening-system.png',
                status: 'published',
                category: 'Technology & Innovation',
                skills: ['Programming and coding', 'Sensor technology and IoT', 'Agricultural science', 'Problem-solving and robotics']
            },
            {
                id: 'agricultural-drones',
                title: '🚁 Agricultural Drones & Vineyard',
                description: 'Discover how drones monitor crop health, detect diseases early, and optimize vineyard management through aerial technology.',
                duration_minutes: 75,
                max_participants: 20,
                activity_type: { name: 'Science-in-Action' },
                slug: 'robotic-gardening',
                featured_image: '../images/thumbnails/agricultural-drone-vineyard.png',
                status: 'published',
                category: 'Technology & Innovation',
                skills: ['Drone operation and control', 'Data collection and analysis', 'Remote sensing technology', 'Agricultural monitoring']
            },
            {
                id: 'smart-irrigation',
                title: '💦 Smart Irrigation Demo',
                description: 'Visit the smartest automatic irrigation plant in the Maresme - see precision water management and automated watering systems in action.',
                duration_minutes: 60,
                max_participants: 30,
                activity_type: { name: 'Science-in-Action' },
                slug: 'robotic-gardening',
                featured_image: '../images/thumbnails/smart-irrigation-demo.png',
                status: 'published',
                category: 'Technology & Innovation',
                skills: ['Water conservation principles', 'Sensor networks and automation', 'Environmental monitoring', 'Resource optimization']
            },
            {
                id: 'erosion-challenge',
                title: '⛰️ Erosion Challenge',
                description: 'Stop erosion, retain water and create a fertile hillside through natural engineering solutions and permaculture techniques.',
                duration_minutes: 120,
                max_participants: 25,
                activity_type: { name: 'Science-in-Action' },
                slug: 'erosion-challenge',
                featured_image: '../images/thumbnails/erosion-control.png',
                status: 'published',
                category: 'Environmental & Engineering',
                skills: ['Soil science and conservation', 'Water management systems', 'Environmental engineering', 'Landscape design principles']
            },
            {
                id: 'ram-pumps',
                title: '💧 Hydraulic Ram Pumps',
                description: 'Moving water up high without electricity! Discover genius inventions of the past that use water pressure to pump water uphill.',
                duration_minutes: 90,
                max_participants: 20,
                activity_type: { name: 'Science-in-Action' },
                slug: 'ram-pumps',
                featured_image: '../images/thumbnails/hydraulic-ram-pump-system.png',
                status: 'published',
                category: 'Environmental & Engineering',
                skills: ['Fluid mechanics and physics', 'Mechanical engineering principles', 'Sustainable technology design', 'Energy efficiency concepts']
            },
            {
                id: 'wattle-daub',
                title: '🏠 Wattle & Daub Construction',
                description: 'Harvest clay, then build a home with mud, hay, and sticks - 6,000-year-old sustainable construction techniques that still work today!',
                duration_minutes: 150,
                max_participants: 20,
                activity_type: { name: 'Science-in-Action' },
                slug: 'wattle-daub',
                featured_image: '../images/thumbnails/wattle-daub-construction.png',
                status: 'published',
                category: 'Environmental & Engineering',
                skills: ['Materials science and properties', 'Sustainable building techniques', 'Historical technology analysis', 'Hands-on construction skills']
            },
            {
                id: 'composting',
                title: '🌱 Composting & Soil Science',
                description: 'Discover the science of decomposition, nutrient cycles, and soil health through hands-on composting and soil analysis.',
                duration_minutes: 90,
                max_participants: 25,
                activity_type: { name: 'Science-in-Action' },
                slug: 'composting',
                featured_image: '../images/thumbnails/composting-farm-scene.png',
                status: 'published',
                category: 'Agriculture & Life Sciences',
                skills: ['Biological processes and cycles', 'Chemistry of decomposition', 'Soil analysis and testing', 'Sustainable waste management']
            },
            {
                id: 'planting',
                title: '🌿 Planting & Growing',
                description: 'Plant seeds, track growth, and discover the science of plant biology through hands-on gardening and data collection.',
                duration_minutes: 75,
                max_participants: 30,
                activity_type: { name: 'Science-in-Action' },
                slug: 'planting',
                featured_image: '../images/thumbnails/school-visit-planting.png',
                status: 'published',
                category: 'Agriculture & Life Sciences',
                skills: ['Plant biology and botany', 'Scientific observation and data collection', 'Agricultural practices', 'Growth tracking and analysis']
            },
            {
                id: 'schoolair-iot',
                title: '📊 SchoolAIR IoT Sensors',
                description: 'Build and program IoT environmental monitoring stations that collect real-time air quality and weather data.',
                duration_minutes: 120,
                max_participants: 15,
                activity_type: { name: 'Science-in-Action' },
                slug: 'https://schoolair.org',
                featured_image: '../images/thumbnails/iot-sensors.png',
                status: 'published',
                category: 'Agriculture & Life Sciences',
                skills: ['IoT programming and sensors', 'Environmental data collection', 'Air quality monitoring', 'Data visualization and analysis']
            }
        ];

        // Combine database activities with additional activities
        const allActivities = [...this.availableWorkshops, ...additionalActivities];
        console.log('🔍 Database workshops count:', this.availableWorkshops.length);
        console.log('🔍 Additional activities count:', additionalActivities.length);
        console.log('🔍 Combined activities count:', allActivities.length);
        console.log('🔍 Combined activities titles:', allActivities.map(a => a.title));

        // Render ALL activities with thumbnails and links
        allActivities.forEach(activity => {
            const durationText = activity.duration_minutes ?
                `${Math.floor(activity.duration_minutes / 60)}h ${activity.duration_minutes % 60}m` :
                'Flexible duration';

            const capacityText = activity.max_participants ?
                `Max ${activity.max_participants} students` :
                'Flexible capacity';

            // Get thumbnail image from featured_image or image_url
            let imageUrl = activity.featured_image || activity.image_url;
            console.log(`🔍 Original image URL for ${activity.title}:`, imageUrl);

            // Only filter out database activities with problematic paths, keep our static activities
            if (imageUrl && imageUrl.includes('pages/images/')) {
                console.log(`❌ Filtering out problematic database path: ${imageUrl}`);
                imageUrl = null;
            }

            console.log(`🖼️ Final image URL for ${activity.title}:`, imageUrl);

            // Create thumbnail HTML if we have an image
            const thumbnailHtml = imageUrl ? `
                <div class="workshop-thumbnail" style="margin-bottom: 1rem; border-radius: 8px; overflow: hidden; max-height: 200px; display: block !important; visibility: visible !important; height: 160px; width: 100%; position: relative;">
                    <img src="${imageUrl}" alt="${activity.title}" class="workshop-image" style="width: 100% !important; height: 160px !important; object-fit: cover !important; border-radius: 6px; display: block !important; visibility: visible !important; opacity: 1 !important; position: absolute; top: 0; left: 0;" onerror="console.error('Image failed to load:', this.src);" onload="console.log('Image loaded successfully:', this.src); this.previousElementSibling && this.previousElementSibling.remove();" />
                </div>
            ` : `<div style="background: yellow; padding: 10px; margin: 10px 0;">NO IMAGE FOR THIS ACTIVITY</div>`;
            console.log(`🏷️ Thumbnail HTML for ${activity.title}:`, thumbnailHtml ? 'Generated' : 'Empty');

            // Create station detail link - link to science-in-action page for these stations
            const detailLink = activity.slug ? `
                <a href="${activity.slug.startsWith('http') ? activity.slug : '../pages/science-in-action-examples.html#' + activity.id}" target="_blank" class="station-detail-link" style="color: #2196f3; text-decoration: none; font-size: 0.9rem; font-weight: 500;">
                    📖 View in Science-in-Action →
                </a>
            ` : '';

            html += `
                <div class="activity-card" style="border: 1px solid #e0e0e0; border-radius: 8px; padding: 1rem; background: white; transition: all 0.3s ease; cursor: pointer;"
                     data-activity-id="${activity.id}">
                    <div class="activity-header" style="display: flex; align-items: flex-start; gap: 0.75rem; margin-bottom: 1rem;">
                        <input type="checkbox" name="selectedWorkshops" value="${activity.id}" class="activity-checkbox" style="width: 18px; height: 18px; margin-top: 2px; accent-color: #2196f3;">
                        <div class="activity-title" style="font-weight: 600; color: #333; font-size: 1.1rem; line-height: 1.3; flex: 1;">
                            ${activity.title}
                        </div>
                    </div>

                    ${thumbnailHtml}

                    <div class="activity-info">
                        <div class="activity-description" style="color: #666; font-size: 0.9rem; line-height: 1.4; margin-bottom: 0.75rem;">
                            ${activity.description ? activity.description.substring(0, 150) + (activity.description.length > 150 ? '...' : '') : 'Hands-on science learning experience'}
                        </div>
                        <div class="activity-details" style="display: flex; gap: 1rem; margin-bottom: 0.75rem; flex-wrap: wrap;">
                            <span class="detail-item" style="font-size: 0.85rem; color: #777; background: #f8f9fa; padding: 0.25rem 0.5rem; border-radius: 4px;">
                                ⏱️ ${durationText}
                            </span>
                            <span class="detail-item" style="font-size: 0.85rem; color: #777; background: #f8f9fa; padding: 0.25rem 0.5rem; border-radius: 4px;">
                                👥 ${capacityText}
                            </span>
                            <span class="detail-item" style="font-size: 0.85rem; color: #777; background: #f8f9fa; padding: 0.25rem 0.5rem; border-radius: 4px;">
                                🏷️ ${activity.activity_type?.name || 'Science Activity'}
                            </span>
                        </div>
                        ${detailLink}
                    </div>
                </div>
            `;
        });

        console.log('📝 Generated HTML length:', html.length);
        console.log('🔍 Generated HTML preview:', html.substring(0, 200) + '...');

        this.workshopGrid.innerHTML = html;

        console.log('✅ HTML set to workshopGrid');
        console.log('🎯 Final workshopGrid content length:', this.workshopGrid.innerHTML.length);

        // Add enhanced styling for activities
        this.addActivityStyles();

        // Add event handlers for the activities
        this.setupActivityEventHandlers();

        console.log('✅ All science-in-action activities rendered successfully');
    }

    addActivityStyles() {
        // Remove any existing styles
        const existingStyle = document.getElementById('activity-styles');
        if (existingStyle) {
            existingStyle.remove();
        }

        const style = document.createElement('style');
        style.id = 'activity-styles';
        style.textContent = `
            .workshop-grid {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
                gap: 1.5rem;
                margin-top: 1rem;
            }

            .activity-card:hover {
                border-color: #2196f3;
                box-shadow: 0 4px 12px rgba(33, 150, 243, 0.2);
                transform: translateY(-2px);
            }

            .activity-card.selected {
                border-color: #2196f3;
                background: #f8fffe;
                box-shadow: 0 4px 12px rgba(33, 150, 243, 0.2);
            }

            .station-detail-link:hover {
                color: #1976d2;
                text-decoration: underline;
            }

            @media (max-width: 768px) {
                .workshop-grid {
                    grid-template-columns: 1fr;
                    gap: 1rem;
                }

                .activity-details {
                    flex-direction: column;
                    gap: 0.5rem;
                }
            }
        `;
        document.head.appendChild(style);
    }

    setupActivityEventHandlers() {
        // Add change handlers for activity selection
        this.workshopGrid.addEventListener('change', (e) => {
            if (e.target.name === 'selectedWorkshops') {
                this.handleActivitySelection(e);
            }
        });

        // Add click handlers for the entire card (except links)
        this.workshopGrid.addEventListener('click', (e) => {
            // Don't trigger card selection if clicking on links
            if (e.target.closest('a')) {
                return;
            }

            const card = e.target.closest('.activity-card');
            if (card && !e.target.matches('input[type="checkbox"]')) {
                const checkbox = card.querySelector('input[type="checkbox"]');
                checkbox.checked = !checkbox.checked;
                this.handleActivitySelection({ target: checkbox });
            }
        });
    }

    handleActivitySelection(e) {
        const card = e.target.closest('.activity-card');
        if (e.target.checked) {
            card.classList.add('selected');
            this.selectedWorkshops.add(e.target.value);
        } else {
            card.classList.remove('selected');
            this.selectedWorkshops.delete(e.target.value);
        }

        console.log('Selected activities:', Array.from(this.selectedWorkshops));
    }

    // Remove the old workshop-related methods and continue with the rest
    setupWorkshopEventHandlers() {
        // This method is no longer needed - replaced by setupActivityEventHandlers
    }

    addWorkshopStyles() {
        // This method is no longer needed - replaced by addActivityStyles
    }

    handleWorkshopSelection(e) {
        // This method is no longer needed - replaced by handleActivitySelection
    }

    setupEventListeners() {
        // Form submission
        this.form.addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleFormSubmission();
        });

        // Radio button styling
        document.querySelectorAll('input[type="radio"]').forEach(radio => {
            radio.addEventListener('change', (e) => {
                const group = e.target.closest('.radio-group');
                if (group) {
                    // Remove selected class from all options in this group
                    group.querySelectorAll('.radio-option').forEach(opt => {
                        opt.classList.remove('selected');
                    });
                    // Add selected class to the checked option's container
                    const selectedOption = e.target.closest('.radio-option');
                    if (selectedOption) {
                        selectedOption.classList.add('selected');
                    }
                }
            });
        });
    }
    async handleFormSubmission() {
        // Add enhanced CSS for the workshop cards
        if (!document.getElementById('workshop-enhanced-styles')) {
            const style = document.createElement('style');
            style.id = 'workshop-enhanced-styles';
            style.textContent = `
                .workshop-card {
                    border: 2px solid #e0e0e0;
                    border-radius: 12px;
                    overflow: hidden;
                    transition: all 0.3s ease;
                    background: white;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.05);
                }

                .workshop-card:hover {
                    border-color: #2196f3;
                    box-shadow: 0 4px 12px rgba(33, 150, 243, 0.15);
                    transform: translateY(-2px);
                }

                .workshop-card.selected {
                    border-color: #2196f3;
                    background: #f8fffe;
                    box-shadow: 0 4px 12px rgba(33, 150, 243, 0.2);
                }

                .workshop-content {
                    padding: 1rem;
                    cursor: pointer;
                }

                .workshop-header {
                    display: flex;
                    align-items: flex-start;
                    gap: 0.75rem;
                    margin-bottom: 1rem;
                }

                .workshop-checkbox {
                    width: 18px;
                    height: 18px;
                    margin-top: 2px;
                    accent-color: #2196f3;
                }

                .workshop-title {
                    font-weight: 600;
                    color: #333;
                    font-size: 1.1rem;
                    line-height: 1.3;
                    flex: 1;
                }

                .workshop-thumbnail {
                    position: relative;
                    margin-bottom: 1rem;
                }

                .view-details-overlay {
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(33, 150, 243, 0.9);
                    color: white;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-weight: 600;
                    opacity: 0;
                    transition: opacity 0.3s ease;
                    border-radius: 6px;
                }

                .workshop-thumbnail:hover .view-details-overlay {
                    opacity: 1;
                }

                .workshop-description {
                    color: #666;
                    font-size: 0.9rem;
                    line-height: 1.4;
                    margin-bottom: 0.75rem;
                }

                .workshop-details {
                    display: flex;
                    gap: 1rem;
                    margin-bottom: 0.75rem;
                }

                .detail-item {
                    font-size: 0.85rem;
                    color: #777;
                    background: #f8f9fa;
                    padding: 0.25rem 0.5rem;
                    border-radius: 4px;
                }

                .learn-more-link {
                    color: #2196f3;
                    text-decoration: none;
                    font-size: 0.9rem;
                    font-weight: 500;
                    transition: color 0.3s ease;
                }

                .learn-more-link:hover {
                    color: #1976d2;
                    text-decoration: underline;
                }

                .view-details-link {
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    z-index: 2;
                }
            `;
            document.head.appendChild(style);
        }
    }

    setupWorkshopEventHandlers() {
        // Add change handlers for workshop selection
        this.workshopGrid.addEventListener('change', (e) => {
            if (e.target.name === 'selectedWorkshops') {
                this.handleWorkshopSelection(e);
            }
        });

        // Add click handlers for the entire card (except links)
        this.workshopGrid.addEventListener('click', (e) => {
            // Don't trigger card selection if clicking on links
            if (e.target.closest('a')) {
                return;
            }

            const card = e.target.closest('.workshop-card');
            if (card && !e.target.matches('input[type="checkbox"]')) {
                const checkbox = card.querySelector('input[type="checkbox"]');
                checkbox.checked = !checkbox.checked;
                this.handleWorkshopSelection({ target: checkbox });
            }
        });
    }

    handleWorkshopSelection(e) {
        const card = e.target.closest('.workshop-card');
        if (e.target.checked) {
            card.classList.add('selected');
            this.selectedWorkshops.add(e.target.value);
        } else {
            card.classList.remove('selected');
            this.selectedWorkshops.delete(e.target.value);
        }

        console.log('Selected workshops:', Array.from(this.selectedWorkshops));
    }

    setupEventListeners() {
        // Form submission
        this.form.addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleFormSubmission();
        });

        // Radio button styling
        document.querySelectorAll('input[type="radio"]').forEach(radio => {
            radio.addEventListener('change', (e) => {
                const group = e.target.closest('.radio-group');
                if (group) {
                    // Remove selected class from all options in this group
                    group.querySelectorAll('.radio-option').forEach(opt => {
                        opt.classList.remove('selected');
                    });
                    // Add selected class to the checked option's container
                    const selectedOption = e.target.closest('.radio-option');
                    if (selectedOption) {
                        selectedOption.classList.add('selected');
                    }
                }
            });
        });
    }

    async handleFormSubmission() {
        try {
            console.log('📤 Submitting visit planning form...');

            // Show loading state
            this.showLoading(true);

            // Collect form data
            const formData = this.collectFormData();

            // Validate required fields
            if (!this.validateFormData(formData)) {
                this.showLoading(false);
                return;
            }

            // Submit to database
            const result = await this.submitToDatabase(formData);

            if (result.success) {
                this.showSuccess();
                this.form.reset();
                this.selectedWorkshops.clear();
                this.renderWorkshops(); // Reset workshop selections
            } else {
                throw new Error(result.error);
            }

        } catch (error) {
            console.error('❌ Error submitting form:', error);
            this.showError(error.message || 'Failed to submit form. Please try again.');
        } finally {
            this.showLoading(false);
        }
    }

    collectFormData() {
        const formData = new FormData(this.form);
        const data = {};

        // Collect basic form fields
        for (let [key, value] of formData.entries()) {
            if (key === 'selectedWorkshops') {
                // Handle multiple workshop selections
                if (!data[key]) data[key] = [];
                data[key].push(value);
            } else {
                data[key] = value;
            }
        }

        // Structure organizer contact data
        data.organizerContact = {
            name: data.organizerName || null,
            email: data.organizerEmail || null,
            phone: data.organizerPhone || null,
            position: 'Trip Organizer',
            type: 'organizer'
        };

        // Structure lead teacher contact data
        data.leadTeacherContact = {
            name: data.leadTeacherName || null,
            email: data.leadTeacherEmail || null,
            phone: data.leadTeacherPhone || null,
            position: 'Lead Teacher',
            type: 'lead_teacher'
        };

        // Structure school data
        data.schoolData = {
            name: data.schoolName || null,
            city: data.city || null,
            country: data.country || null
        };

        // Handle language "other" option
        if (data.language === 'other' && data.languageOther) {
            data.preferredLanguage = data.languageOther;
        } else {
            data.preferredLanguage = data.language;
        }

        // Handle "other" options for radio buttons
        if (data.visitFormat === 'other' && data.visitFormatOther) {
            data.visitFormatOther = data.visitFormatOther;
        }

        if (data.educationalFocus === 'other' && data.educationalFocusOther) {
            data.educationalFocusOther = data.educationalFocusOther;
        }

        // Convert food preferences to array if it exists
        if (data.foodPreferences) {
            data.food_preferences = [data.foodPreferences];
        }

        // Add selected workshops array
        data.selectedWorkshops = Array.from(this.selectedWorkshops);

        // Handle overnight visit data
        if (data.visitType === 'school_overnight') {
            // Handle custom nights
            if (data.numberOfNights === 'other' && data.customNights) {
                data.numberOfNights = parseInt(data.customNights);
            } else if (data.numberOfNights) {
                data.numberOfNights = parseInt(data.numberOfNights);
            }

            // Format date-time fields for database
            if (data.arrivalDateTime) {
                data.arrivalDateTime = new Date(data.arrivalDateTime).toISOString();
            }
            if (data.departureDateTime) {
                data.departureDateTime = new Date(data.departureDateTime).toISOString();
            }
        } else {
            // Ensure overnight fields are null for non-overnight visits
            data.numberOfNights = null;
            data.arrivalDateTime = null;
            data.departureDateTime = null;
            data.accommodationNeeds = null;
            data.accommodationSelection = null;
        }

        // Add timestamp
        data.submittedAt = new Date().toISOString();

        console.log('📋 Collected form data:', data);
        return data;
    }

    validateFormData(data) {
        const errors = [];

        // Core required fields validation
        const coreFields = {
            'leadTeacherContact.email': 'Lead teacher email',
            'leadTeacherContact.name': 'Lead teacher name',
            'schoolData.name': 'School/Organization name',
            'schoolData.city': 'City',
            'schoolData.country': 'Country',
            'studentCount': 'Number of students',
            'gradeLevel': 'Grade level',
            'proposedVisitDate': 'Proposed visit date'
        };

        // Check core required fields
        for (const [fieldPath, displayName] of Object.entries(coreFields)) {
            const value = this.getNestedValue(data, fieldPath);
            if (!value || String(value).trim() === '') {
                errors.push(`${displayName} is required`);
            }
        }

        // Email validation
        const leadTeacherEmail = data.leadTeacherContact?.email;
        if (leadTeacherEmail) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(leadTeacherEmail)) {
                errors.push('Please enter a valid lead teacher email address');
            }
        }

        // Organizer email validation (if provided)
        const organizerEmail = data.organizerContact?.email;
        if (organizerEmail && organizerEmail.trim() !== '') {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(organizerEmail)) {
                errors.push('Please enter a valid organizer email address');
            }
            // If organizer email is provided, name should also be provided
            if (!data.organizerContact?.name || data.organizerContact.name.trim() === '') {
                errors.push('Organizer name is required when email is provided');
            }
        }

        // Student count validation
        const studentCount = parseInt(data.studentCount);
        if (isNaN(studentCount) || studentCount < 1 || studentCount > 100) {
            errors.push('Please enter a valid number of students (1-100)');
        }

        // Adult count validation (if provided)
        const adultCount = data.adultCount;
        if (adultCount && (parseInt(adultCount) < 0 || parseInt(adultCount) > 50)) {
            errors.push('Number of adults must be between 0 and 50');
        }

        // Overnight visit specific validation
        if (data.visitType === 'school_overnight') {
            // Number of nights validation
            if (!data.numberOfNights || data.numberOfNights === '') {
                errors.push('Number of nights is required for overnight visits');
            } else if (data.numberOfNights === 'other') {
                const customNights = parseInt(data.customNights);
                if (isNaN(customNights) || customNights < 1 || customNights > 30) {
                    errors.push('Please enter a valid number of nights (1-30)');
                }
            }

            // Date validation for overnight visits
            if (data.arrivalDateTime && data.departureDateTime) {
                const arrival = new Date(data.arrivalDateTime);
                const departure = new Date(data.departureDateTime);
                if (departure <= arrival) {
                    errors.push('Departure date/time must be after arrival date/time');
                }
            }
        }

        // Visit format validation
        if (data.visitFormat === 'other' && (!data.visitFormatOther || data.visitFormatOther.trim() === '')) {
            errors.push('Please specify your preferred visit format when selecting "Other"');
        }

        // Educational focus validation
        if (data.educationalFocus === 'other' && (!data.educationalFocusOther || data.educationalFocusOther.trim() === '')) {
            errors.push('Please specify your educational focus when selecting "Other"');
        }

        // Language validation
        if (data.language === 'other' && (!data.languageOther || data.languageOther.trim() === '')) {
            errors.push('Please specify your preferred language when selecting "Other"');
        }

        // Display errors if any
        if (errors.length > 0) {
            const errorMessage = 'Please fix the following issues:\n\n• ' + errors.join('\n• ');
            alert(errorMessage);
            return false;
        }

        return true;
    }

    // Helper method to get nested object values
    getNestedValue(obj, path) {
        return path.split('.').reduce((current, key) => {
            return current && current[key] !== undefined ? current[key] : null;
        }, obj);
    }

    async submitToDatabase(formData) {
        try {
            console.log('🔄 Starting database submission with normalized schema...');

            // Step 1: Create or find school record
            const { data: schoolData, error: schoolError } = await supabaseClient
                .rpc('find_or_create_school', {
                    school_name: formData.schoolData.name,
                    school_city: formData.schoolData.city,
                    school_country: formData.schoolData.country
                });

            if (schoolError) throw new Error(`School creation failed: ${schoolError.message}`);
            const schoolId = schoolData;
            console.log('✅ School ID:', schoolId);

            // Step 2: Create organizer contact (if provided)
            let organizerContactId = null;
            if (formData.organizerContact.email) {
                const { data: organizerData, error: organizerError } = await supabaseClient
                    .rpc('find_or_create_contact', {
                        contact_name: formData.organizerContact.name,
                        contact_email: formData.organizerContact.email,
                        contact_phone: formData.organizerContact.phone,
                        contact_position: formData.organizerContact.position,
                        contact_type: formData.organizerContact.type,
                        contact_school_id: schoolId
                    });

                if (organizerError) throw new Error(`Organizer contact creation failed: ${organizerError.message}`);
                organizerContactId = organizerData;
                console.log('✅ Organizer Contact ID:', organizerContactId);
            }

            // Step 3: Create lead teacher contact
            const { data: teacherData, error: teacherError } = await supabaseClient
                .rpc('find_or_create_contact', {
                    contact_name: formData.leadTeacherContact.name,
                    contact_email: formData.leadTeacherContact.email,
                    contact_phone: formData.leadTeacherContact.phone,
                    contact_position: formData.leadTeacherContact.position,
                    contact_type: formData.leadTeacherContact.type,
                    contact_school_id: schoolId
                });

            if (teacherError) throw new Error(`Lead teacher contact creation failed: ${teacherError.message}`);
            const teacherContactId = teacherData;
            console.log('✅ Lead Teacher Contact ID:', teacherContactId);

            // Step 4: Process overnight data
            let overnightData = {};
            if (formData.visitType === 'school_overnight') {
                // Handle custom nights
                let nights = 0;
                if (formData.numberOfNights === 'other' && formData.customNights) {
                    nights = parseInt(formData.customNights);
                } else if (formData.numberOfNights) {
                    nights = parseInt(formData.numberOfNights);
                }

                overnightData = {
                    number_of_nights: nights,
                    arrival_date_time: formData.arrivalDateTime ? new Date(formData.arrivalDateTime).toISOString() : null,
                    departure_date_time: formData.departureDateTime ? new Date(formData.departureDateTime).toISOString() : null,
                    accommodation_selection: formData.accommodationSelection || null,
                    accommodation_needs: formData.accommodationNeeds || null
                };
            }

            // Step 5: Create visit record with actual database schema
            const visitRecord = {
                // Basic visit info - use actual column names from your DB
                visit_type: formData.visitType || 'school_day_trip',

                // Contact information (using your existing schema)
                contact_name: formData.leadTeacherContact.name,
                contact_email: formData.leadTeacherContact.email,
                contact_phone: formData.leadTeacherContact.phone,
                school_name: formData.schoolData.name,
                country_of_origin: formData.schoolData.country,

                // Add new fields we just added
                city: formData.schoolData.city,
                proposed_visit_date: formData.proposedVisitDate || null,
                preferred_date: formData.proposedVisitDate || null, // Map proposed date to preferred_date
                organizer_name: formData.organizerContact.name || null,
                organizer_email: formData.organizerContact.email || null,
                organizer_phone: formData.organizerContact.phone || null,
                lead_teacher_phone: formData.leadTeacherContact.phone || null,

                // Visit planning
                potential_visit_dates: formData.visitDates || null,
                preferred_language: formData.preferredLanguage || null,
                student_count: parseInt(formData.studentCount),
                teacher_count: parseInt(formData.adultCount) || null,
                grade_level: formData.gradeLevel || 'Not specified',

                // Overnight specific fields
                ...overnightData,

                // Visit format and educational focus
                visit_format: formData.visitFormat || null,
                visit_format_other: formData.visitFormatOther || null,
                schedule_preferences: formData.schedulePreferences || null,
                educational_focus: formData.educationalFocus || null,
                educational_focus_other: formData.educationalFocusOther || null,

                // Workshop and additional info
                selected_workshops: formData.selectedWorkshops || [],
                food_preferences: formData.food_preferences || [],

                // Use the correct column name from your database
                additional_comments: [
                    formData.additionalComments,
                    formData.accommodationNeeds
                ].filter(Boolean).join('\n\nAccommodation needs: ') || null,

                // Status and metadata
                status: 'pending',
                submitted_at: formData.submittedAt
            };

            const { data: visitData, error: visitError } = await supabaseClient
                .from('visits')
                .insert([visitRecord])
                .select();

            if (visitError) throw new Error(`Visit creation failed: ${visitError.message}`);

            console.log('✅ Visit request saved with normalized schema:', visitData[0]);

            return {
                success: true,
                data: visitData[0],
                metadata: {
                    schoolId,
                    organizerContactId,
                    teacherContactId,
                    visitId: visitData[0].id
                }
            };

        } catch (error) {
            console.error('❌ Database submission error:', error);

            // Provide more helpful error messages
            let errorMessage = error.message;
            if (error.message.includes('find_or_create_school')) {
                errorMessage = 'Unable to create school record. Please check school information.';
            } else if (error.message.includes('find_or_create_contact')) {
                errorMessage = 'Unable to create contact record. Please check contact information.';
            } else if (error.message.includes('relation') && error.message.includes('does not exist')) {
                errorMessage = 'Database schema error. Please run the schema fix script first.';
            } else if (error.message.includes('row-level security')) {
                errorMessage = 'Database permission error. Please contact the administrator.';
            } else if (error.message.includes('duplicate key')) {
                errorMessage = 'A request with this information already exists.';
            } else if (error.message.includes('constraint')) {
                console.error('Database constraint error details:', error);
                errorMessage = `Database constraint error: ${error.message}`;
            }

            return { success: false, error: errorMessage };
        }
    }

    showLoading(show) {
        const loadingEl = document.getElementById('loadingMessage');
        const submitBtn = document.getElementById('submitBtn');

        if (show) {
            loadingEl.style.display = 'block';
            submitBtn.disabled = true;
            submitBtn.textContent = 'Submitting...';
        } else {
            loadingEl.style.display = 'none';
            submitBtn.disabled = false;
            submitBtn.textContent = 'Submit Visit Planning Request';
        }
    }

    showSuccess() {
        const successEl = document.getElementById('successMessage');
        const errorEl = document.getElementById('errorMessage');

        successEl.style.display = 'block';
        errorEl.style.display = 'none';

        // Scroll to success message
        successEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    showError(message) {
        const errorEl = document.getElementById('errorMessage');
        const successEl = document.getElementById('successMessage');

        errorEl.style.display = 'block';
        successEl.style.display = 'none';

        // Update error message if provided
        if (message) {
            const errorText = errorEl.querySelector('p');
            errorText.textContent = message;
        }

        // Scroll to error message
        errorEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
}

// Wait for dependencies and initialize
function initializeVisitPlanningForm() {
    console.log('🎓 Attempting to initialize Visit Planning Form...');

    // Check if we have the required dependencies
    if (typeof window.supabase === 'undefined') {
        console.log('⏳ Waiting for Supabase library...');
        return false;
    }

    if (typeof GuidalDB === 'undefined') {
        console.log('⏳ Waiting for GuidalDB...');
        return false;
    }

    // Optional: check for supabaseClient (we'll use GuidalDB as primary)
    if (typeof supabaseClient === 'undefined') {
        console.log('⚠️ supabaseClient not available, will use GuidalDB');
    }

    console.log('✅ All dependencies loaded, initializing form...');
    new VisitPlanningForm();
    return true;
}

// Initialize when DOM is ready (either immediately or when event fires)
function initWhenReady() {
    console.log('🎓 Checking if DOM is ready...');

    // Try to initialize immediately
    if (!initializeVisitPlanningForm()) {
        // If dependencies aren't ready, poll for them
        let attempts = 0;
        const maxAttempts = 50; // 5 seconds max

        const pollInterval = setInterval(() => {
            attempts++;
            console.log(`🔄 Initialization attempt ${attempts}/${maxAttempts}`);

            if (initializeVisitPlanningForm()) {
                clearInterval(pollInterval);
            } else if (attempts >= maxAttempts) {
                clearInterval(pollInterval);
                console.error('❌ Failed to initialize after maximum attempts');

                const container = document.querySelector('.form-container');
                if (container) {
                    container.innerHTML = `
                        <div class="error-message" style="display: block;">
                            <h4>❌ System Error</h4>
                            <p>Required dependencies failed to load. Please refresh the page or contact support.</p>
                            <p><small>Dependencies checked: Supabase library, GuidalDB</small></p>
                        </div>
                    `;
                }
            }
        }, 100); // Check every 100ms
    }
}

// Check if DOM is already loaded or wait for it
if (document.readyState === 'loading') {
    console.log('🎓 DOM still loading, adding DOMContentLoaded listener...');
    document.addEventListener('DOMContentLoaded', initWhenReady);
} else {
    console.log('🎓 DOM already loaded, initializing immediately...');
    initWhenReady();
}