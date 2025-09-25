// Supabase Client for GUIDAL
// Updated for production database schema

const SUPABASE_URL = 'https://lmsuyhzcmgdpjynosxvp.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtc3V5aHpjbWdkcGp5bm9zeHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NzM5NjksImV4cCI6MjA3MzI0OTk2OX0.rRpHs_0ZLW3erdFnm2SwFTAmyQJYRMpcSlNzMBlcq4U'

// Initialize Supabase client
let supabase = null;

// Wait for Supabase library to be available
function initializeSupabase() {
  if (window.supabase) {
    supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    console.log('🔗 Supabase client initialized');

    // Export immediately after creation
    if (typeof window !== 'undefined') {
      window.supabaseClient = supabase;
      console.log('📤 supabaseClient exported to window');
    }

    return true;
  }
  return false;
}

// Try to initialize immediately
if (!initializeSupabase()) {
  // If not available, wait and try again with more attempts
  console.log('⏳ Waiting for Supabase library...');
  let attempts = 0;
  const maxAttempts = 50; // Try for 5 seconds

  const tryInitialize = () => {
    attempts++;
    if (initializeSupabase()) {
      console.log('✅ Supabase client initialized after', attempts, 'attempts');
    } else if (attempts < maxAttempts) {
      setTimeout(tryInitialize, 100);
    } else {
      console.error('❌ Failed to initialize Supabase client after', maxAttempts, 'attempts');
    }
  };

  setTimeout(tryInitialize, 100);
}

// Database service functions
class GuidalDB {
  
  // Schools Management
  static async getSchools() {
    const { data, error } = await supabase
      .from('schools')
      .select('*')
      .order('name', { ascending: true })
    
    if (error) {
      console.error('Error fetching schools:', error)
      return []
    }
    return data || []
  }

  static async addSchool(schoolData) {
    const { data, error } = await supabase
      .from('schools')
      .insert([schoolData])
      .select()
    
    if (error) {
      console.error('Error adding school:', error)
      throw error
    }
    return data[0]
  }

  // Visits Management
  static async getVisits(filters = {}) {
    let query = supabase
      .from('visits')
      .select('*')
      .order('confirmed_date', { ascending: true })

    if (filters.upcoming) {
      query = query.gte('confirmed_date', new Date().toISOString().split('T')[0])
    }

    if (filters.status) {
      query = query.eq('status', filters.status)
    }

    const { data, error } = await query

    if (error) {
      console.error('Error fetching visits:', error)
      return []
    }
    return data || []
  }

  static async getVisitByAccessCode(accessCode) {
    const { data, error } = await supabase
      .from('visits')
      .select('*')
      .eq('internal_notes', `access_code:${accessCode}`)
      .single()

    if (error) {
      console.error('Error fetching visit by access code:', error)
      return null
    }
    return data
  }

  static async addVisit(visitData) {
    const { data, error } = await supabase
      .from('visits')
      .insert([visitData])
      .select()

    if (error) {
      console.error('Error adding visit:', error)
      throw error
    }
    return data[0]
  }

  // Guest Book Entries
  static async getGuestBookEntries(visitId = null) {
    try {
      let query = supabase
        .from('guest_book_entries')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(20)

      if (visitId) {
        query = query.eq('visit_id', visitId)
      }

      const { data, error } = await query

      if (error) {
        console.error('Error fetching guest book entries:', error)
        return []
      }
      return data || []
    } catch (error) {
      console.error('Error in getGuestBookEntries:', error)
      return []
    }
  }

  static async addGuestBookEntry(entryData) {
    try {
      const { data, error } = await supabase
        .from('guest_book_entries')
        .insert([entryData])
        .select()

      if (error) {
        console.error('Error adding guest book entry:', error)
        throw error
      }
      return data[0]
    } catch (error) {
      console.error('Error in addGuestBookEntry:', error)
      throw error
    }
  }


  // Activities (for dynamic content)
  static async getActivities(filters = {}) {
    // Query activities table
    let activitiesQuery = supabase
      .from('activities')
      .select(`
        *,
        activity_type:activity_types!activity_type_id(id, name, slug, color, icon)
      `)

    // Handle status filter for activities - if not specified, show published activities
    if (filters.status) {
      activitiesQuery = activitiesQuery.eq('status', filters.status)
    } else if (filters.include_completed) {
      // For past activities, include completed status to show finished school visits
      activitiesQuery = activitiesQuery.in('status', ['published', 'active', 'upcoming', 'completed'])
    } else {
      activitiesQuery = activitiesQuery.in('status', ['published', 'active', 'upcoming'])
    }

    // Also query visits table for school visits
    let visitsQuery = supabase
      .from('visits')
      .select(`
        id,
        school_name as title,
        additional_comments as description,
        preferred_date as date_time,
        status,
        contact_email,
        student_count,
        visit_type,
        invoice_status,
        created_at,
        updated_at
      `)

    // Handle status filter for visits
    if (filters.status) {
      visitsQuery = visitsQuery.eq('status', filters.status)
    } else if (filters.include_completed) {
      // Include various statuses for visits, especially 'completed'
      visitsQuery = visitsQuery.in('status', ['confirmed', 'completed', 'pending', 'published'])
    } else {
      // For upcoming, show confirmed and pending visits
      visitsQuery = visitsQuery.in('status', ['confirmed', 'pending', 'published'])
    }

    // Apply activity type filter to activities query only
    if (filters.type) {
      const { data: activityType } = await supabase
        .from('activity_types')
        .select('id')
        .eq('slug', filters.type)
        .single()

      if (activityType) {
        activitiesQuery = activitiesQuery.eq('activity_type_id', activityType.id)

        // If filtering by type, don't include visits (they don't have activity_type)
        if (filters.type !== 'school-visits') {
          // Only query activities, skip visits
          visitsQuery = null;
        }
      }
    }

    // Apply search filters
    if (filters.search) {
      activitiesQuery = activitiesQuery.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
      if (visitsQuery) {
        visitsQuery = visitsQuery.or(`school_name.ilike.%${filters.search}%,additional_comments.ilike.%${filters.search}%`)
      }
    }

    if (filters.limit) {
      activitiesQuery = activitiesQuery.limit(Math.floor(filters.limit / 2)) // Split limit between tables
      if (visitsQuery) {
        visitsQuery = visitsQuery.limit(Math.floor(filters.limit / 2))
      }
    }

    console.log('🔍 Executing queries with filters:', filters);
    console.log('📊 Activities query enabled:', !!activitiesQuery);
    console.log('📊 Visits query enabled:', !!visitsQuery);

    // Execute both queries
    const promises = [activitiesQuery];
    if (visitsQuery) {
      promises.push(visitsQuery);
    } else {
      promises.push(Promise.resolve({ data: [], error: null }));
    }

    const [activitiesResult, visitsResult] = await Promise.all(promises);

    if (activitiesResult.error) {
      console.error('❌ Error fetching activities:', activitiesResult.error)
    }

    if (visitsResult.error) {
      console.error('❌ Error fetching visits:', visitsResult.error)
    }

    // Combine results
    const activities = activitiesResult.data || [];
    const visits = visitsResult.data || [];

    console.log(`📈 Raw results - Activities: ${activities.length}, Visits: ${visits.length}`);

    // Transform visits to look like activities and add activity_type
    const transformedVisits = visits.map(visit => ({
      ...visit,
      activity_type: {
        id: 'school-visit',
        name: 'School Visit',
        slug: 'school-visits',
        color: '#28a745',
        icon: '🏫'
      }
    }));

    console.log(`🔄 Transformed visits: ${transformedVisits.length}`);

    // Combine all data
    let allData = [...activities, ...transformedVisits];
    console.log(`📋 Combined data before filtering: ${allData.length}`);

    // Apply time-based filtering after database query
    const currentDate = new Date();
    let filteredData = allData;

    if (filters.time_filter === 'upcoming') {
      console.log('🔮 Applying upcoming filter, current date:', currentDate);
      filteredData = filteredData.filter(activity => {
        const activityDate = activity.date_time ? new Date(activity.date_time) : null;
        const isUpcoming = !activityDate || activityDate >= currentDate;
        if (activityDate) console.log(`📅 Activity ${activity.title}: ${activityDate} >= ${currentDate} = ${isUpcoming}`);
        return isUpcoming;
      });
    } else if (filters.time_filter === 'past') {
      console.log('📚 Applying past filter, current date:', currentDate);
      filteredData = filteredData.filter(activity => {
        const activityDate = activity.date_time ? new Date(activity.date_time) : null;
        const isPast = activityDate && activityDate < currentDate;
        if (activityDate) console.log(`📅 Activity ${activity.title}: ${activityDate} < ${currentDate} = ${isPast}`);
        return isPast;
      });
    }

    console.log(`⏰ After time filtering (${filters.time_filter}): ${filteredData.length}`);

    // Custom sorting: upcoming activities first, then past activities
    const sortedData = filteredData.sort((a, b) => {
      const dateA = a.date_time ? new Date(a.date_time) : null;
      const dateB = b.date_time ? new Date(b.date_time) : null;

      // Handle null dates (put them at the end)
      if (!dateA && !dateB) return 0;
      if (!dateA) return 1;
      if (!dateB) return -1;

      const isUpcomingA = dateA >= currentDate;
      const isUpcomingB = dateB >= currentDate;

      // If one is upcoming and one is past, upcoming comes first
      if (isUpcomingA && !isUpcomingB) return -1;
      if (!isUpcomingA && isUpcomingB) return 1;

      // If both are upcoming, sort by date (earliest first)
      if (isUpcomingA && isUpcomingB) {
        return dateA - dateB;
      }

      // If both are past, sort by date (most recent first)
      return dateB - dateA;
    });

    console.log('✅ Raw database response:', sortedData.length, 'activities (sorted by upcoming/past)');
    return sortedData;
  }

  static async addActivity(activityData) {
    const { data, error } = await supabase
      .from('activities')
      .insert([activityData])
      .select()
    
    if (error) {
      console.error('Error adding activity:', error)
      throw error
    }
    return data[0]
  }

  // Station Visits Tracking
  static async trackStationVisit(visitData) {
    const { data, error } = await supabase
      .from('station_visits')
      .insert([visitData])
      .select()
    
    if (error) {
      console.error('Error tracking station visit:', error)
      throw error
    }
    return data[0]
  }

  static async getStationVisits(visitId) {
    const { data, error } = await supabase
      .from('station_visits')
      .select('*')
      .eq('visit_id', visitId)
      .order('completion_time', { ascending: false })
    
    if (error) {
      console.error('Error fetching station visits:', error)
      return []
    }
    return data || []
  }

  // Real-time subscriptions
  static subscribeToGuestBookEntries(callback, visitId = null) {
    try {
      let filter = 'guest_book_entries:*'
      if (visitId) {
        filter = `guest_book_entries:visit_id=eq.${visitId}`
      }

      const subscription = supabase
        .channel('guest-book-changes')
        .on('postgres_changes', {
          event: '*',
          schema: 'public',
          table: 'guest_book_entries',
          filter: visitId ? `visit_id=eq.${visitId}` : undefined
        }, callback)
        .subscribe()

      return subscription
    } catch (error) {
      console.error('Error setting up guest book subscription:', error)
      return null
    }
  }


  // Authentication Management
  static async signUp(email, password, userData = {}) {
    try {
      // 1. Create auth user
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: userData.fullName,
            user_type: userData.userType || 'student'
          }
        }
      })

      if (authError) throw authError

      // 2. Create profile entry
      if (authData.user) {
        const profileData = {
          id: authData.user.id,
          email,
          full_name: userData.fullName,
          user_type: userData.userType || 'student',
          school_id: userData.schoolId,
          phone: userData.phone,
          emergency_contact: userData.emergencyContact,
          dietary_restrictions: userData.dietaryRestrictions
        }

        const { error: profileError } = await supabase
          .from('profiles')
          .insert([profileData])

        if (profileError) {
          console.error('Profile creation error:', profileError)
          // Don't throw here as auth user was created successfully
        }
      }

      return { user: authData.user, session: authData.session }
    } catch (error) {
      console.error('Sign up error:', error)
      throw error
    }
  }

  static async signIn(email, password) {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      })

      if (error) throw error
      return { user: data.user, session: data.session }
    } catch (error) {
      console.error('Sign in error:', error)
      throw error
    }
  }

  static async signOut() {
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error

      // Clear local storage
      localStorage.removeItem('greens_user')
      localStorage.removeItem('greens_session')

      return true
    } catch (error) {
      console.error('Sign out error:', error)
      throw error
    }
  }

  static async resetPassword(email) {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/pages/auth/reset-password.html`
      })

      if (error) throw error
      return true
    } catch (error) {
      console.error('Password reset error:', error)
      throw error
    }
  }

  static async updatePassword(newPassword) {
    try {
      const { error } = await supabase.auth.updateUser({
        password: newPassword
      })

      if (error) throw error
      return true
    } catch (error) {
      console.error('Password update error:', error)
      throw error
    }
  }

  static async getCurrentUser() {
    try {
      const { data: { user }, error } = await supabase.auth.getUser()
      if (error) throw error

      if (user && user.id) {
        // Get full profile data
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single()

        if (profileError) {
          console.warn('Profile fetch error:', profileError)
          // Return user without profile if profile fetch fails
          return { ...user, profile: null }
        }

        return { ...user, profile }
      }
      return null
    } catch (error) {
      console.error('Get current user error:', error)
      return null
    }
  }

  static async getCurrentSession() {
    try {
      const { data: { session }, error } = await supabase.auth.getSession()
      if (error) throw error
      return session
    } catch (error) {
      console.error('Get session error:', error)
      return null
    }
  }

  static onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange(callback)
  }

  // Profile Management
  static async updateProfile(userId, profileData) {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .update(profileData)
        .eq('id', userId)
        .select()

      if (error) throw error
      return data[0]
    } catch (error) {
      console.error('Profile update error:', error)
      throw error
    }
  }

  static async getProfile(userId) {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select(`
          *,
          school:schools(name, country)
        `)
        .eq('id', userId)
        .single()

      if (error) throw error
      return data
    } catch (error) {
      console.error('Get profile error:', error)
      throw error
    }
  }

  // File Upload
  static async uploadFile(bucket, filePath, file) {
    try {
      const { data, error } = await supabase.storage
        .from(bucket)
        .upload(filePath, file)

      if (error) throw error
      return data
    } catch (error) {
      console.error('File upload error:', error)
      throw error
    }
  }

  static async getPublicUrl(bucket, filePath) {
    try {
      const { data } = supabase.storage
        .from(bucket)
        .getPublicUrl(filePath)

      return data.publicUrl
    } catch (error) {
      console.error('Get public URL error:', error)
      return null
    }
  }

  static async deleteFile(bucket, filePath) {
    try {
      const { error } = await supabase.storage
        .from(bucket)
        .remove([filePath])

      if (error) throw error
      return true
    } catch (error) {
      console.error('File delete error:', error)
      throw error
    }
  }

  // Activity Registration
  static async registerForActivity(activityId, userId, registrationData = {}) {
    try {
      // Check if already registered
      const { data: existing } = await supabase
        .from('activity_registrations')
        .select('id')
        .eq('activity_id', activityId)
        .eq('user_id', userId)
        .single()

      if (existing) {
        throw new Error('Already registered for this activity')
      }

      // Register for activity
      const { data, error } = await supabase
        .from('activity_registrations')
        .insert([{
          activity_id: activityId,
          user_id: userId,
          status: 'registered',
          ...registrationData
        }])
        .select()

      if (error) throw error

      // Update participant count
      const { error: updateError } = await supabase.rpc('increment_participants', {
        activity_id: activityId
      })

      if (updateError) {
        console.error('Failed to update participant count:', updateError)
      }

      return data[0]
    } catch (error) {
      console.error('Activity registration error:', error)
      throw error
    }
  }

  static async getMyRegistrations(userId) {
    try {
      const { data, error } = await supabase
        .from('activity_registrations')
        .select(`
          *,
          activity:activities(
            title,
            date_time,
            location,
            featured_image
          )
        `)
        .eq('user_id', userId)
        .order('registration_date', { ascending: false })

      if (error) throw error
      return data || []
    } catch (error) {
      console.error('Get registrations error:', error)
      return []
    }
  }

  static async cancelRegistration(registrationId, activityId) {
    try {
      const { error } = await supabase
        .from('activity_registrations')
        .update({ status: 'cancelled' })
        .eq('id', registrationId)

      if (error) throw error

      // Update participant count
      const { error: updateError } = await supabase.rpc('decrement_participants', {
        activity_id: activityId
      })

      if (updateError) {
        console.error('Failed to update participant count:', updateError)
      }

      return true
    } catch (error) {
      console.error('Cancel registration error:', error)
      throw error
    }
  }

  // Notifications
  static async createNotification(userId, title, message, type = 'info', actionUrl = null) {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .insert([{
          user_id: userId,
          title,
          message,
          type,
          action_url: actionUrl,
          is_read: false
        }])
        .select()

      if (error) throw error
      return data[0]
    } catch (error) {
      console.error('Create notification error:', error)
      throw error
    }
  }

  static async getNotifications(userId, unreadOnly = false) {
    try {
      let query = supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })

      if (unreadOnly) {
        query = query.eq('is_read', false)
      }

      const { data, error } = await query
      if (error) throw error
      return data || []
    } catch (error) {
      console.error('Get notifications error:', error)
      return []
    }
  }

  static async markNotificationRead(notificationId) {
    try {
      const { error } = await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', notificationId)

      if (error) throw error
      return true
    } catch (error) {
      console.error('Mark notification read error:', error)
      throw error
    }
  }

  // Admin Functions
  static async getAllUsers(filters = {}) {
    try {
      let query = supabase
        .from('profiles')
        .select(`
          *,
          school:schools(name, country)
        `)
        .order('created_at', { ascending: false })

      if (filters.userType) {
        query = query.eq('user_type', filters.userType)
      }

      if (filters.schoolId) {
        query = query.eq('school_id', filters.schoolId)
      }

      const { data, error } = await query
      if (error) throw error
      return data || []
    } catch (error) {
      console.error('Get all users error:', error)
      return []
    }
  }

  static async updateActivity(activityId, activityData) {
    try {
      const { data, error } = await supabase
        .from('activities')
        .update(activityData)
        .eq('id', activityId)
        .select()

      if (error) throw error
      return data[0]
    } catch (error) {
      console.error('Update activity error:', error)
      throw error
    }
  }

  static async deleteActivity(activityId) {
    try {
      const { error } = await supabase
        .from('activities')
        .delete()
        .eq('id', activityId)

      if (error) throw error
      return true
    } catch (error) {
      console.error('Delete activity error:', error)
      throw error
    }
  }

  // Utility functions
  static async testConnection() {
    try {
      const { data, error } = await supabase
        .from('schools')
        .select('id')
        .limit(1)

      if (error) throw error
      console.log('✅ Supabase connection successful')
      return true
    } catch (error) {
      console.error('❌ Supabase connection failed:', error)
      return false
    }
  }

  // Enhanced error handling
  static handleError(error, context = '') {
    let userMessage = 'An error occurred. Please try again.'

    if (error.message.includes('Invalid login credentials')) {
      userMessage = 'Invalid email or password.'
    } else if (error.message.includes('Email not confirmed')) {
      userMessage = 'Please check your email and confirm your account.'
    } else if (error.message.includes('User already registered')) {
      userMessage = 'An account with this email already exists.'
    } else if (error.message.includes('Password should be at least 6 characters')) {
      userMessage = 'Password must be at least 6 characters long.'
    }

    console.error(`${context} Error:`, error)
    return userMessage
  }
}

// Export for use in other files
if (typeof window !== 'undefined') {
  window.GuidalDB = GuidalDB
  // supabaseClient is exported in initializeSupabase() function above
  if (supabase && !window.supabaseClient) {
    window.supabaseClient = supabase;
  }
}