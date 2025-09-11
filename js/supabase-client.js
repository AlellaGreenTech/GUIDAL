// Supabase Client for GUIDAL
// Replace these with your actual Supabase project values

const SUPABASE_URL = 'https://your-project-id.supabase.co'
const SUPABASE_ANON_KEY = 'your-anon-key-here'

// Import Supabase (you'll need to include this in your HTML)
// <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Database service functions
class GuidalDB {
  
  // Activities
  static async getActivities(filters = {}) {
    let query = supabase
      .from('activities')
      .select(`
        *,
        activity_type:activity_types(name, slug, color, icon),
        registrations:activity_registrations(count)
      `)
      .eq('status', 'published')
      .order('date_time', { ascending: true })

    // Apply filters
    if (filters.type) {
      query = query.eq('activity_types.slug', filters.type)
    }
    
    if (filters.search) {
      query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
    }

    const { data, error } = await query
    if (error) throw error
    return data
  }

  static async getActivity(slug) {
    const { data, error } = await supabase
      .from('activities')
      .select(`
        *,
        activity_type:activity_types(name, slug, color, icon),
        school_visit:school_visits(*)
      `)
      .eq('slug', slug)
      .eq('status', 'published')
      .single()

    if (error) throw error
    return data
  }

  // Activity Types
  static async getActivityTypes() {
    const { data, error } = await supabase
      .from('activity_types')
      .select('*')
      .eq('active', true)
      .order('name')

    if (error) throw error
    return data
  }

  // Schools
  static async getSchools() {
    const { data, error } = await supabase
      .from('schools')
      .select('*')
      .eq('active', true)
      .order('name')

    if (error) throw error
    return data
  }

  // User Profile
  static async getProfile(userId) {
    const { data, error } = await supabase
      .from('profiles')
      .select(`
        *,
        school:schools(name)
      `)
      .eq('id', userId)
      .single()

    if (error) throw error
    return data
  }

  static async updateProfile(userId, updates) {
    const { data, error } = await supabase
      .from('profiles')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId)
      .select()
      .single()

    if (error) throw error
    return data
  }

  // Activity Registration
  static async registerForActivity(activityId, userId) {
    const { data, error } = await supabase
      .from('activity_registrations')
      .insert([
        {
          activity_id: activityId,
          user_id: userId,
          status: 'registered'
        }
      ])
      .select()
      .single()

    if (error) throw error
    return data
  }

  static async getUserRegistrations(userId) {
    const { data, error } = await supabase
      .from('activity_registrations')
      .select(`
        *,
        activity:activities(
          title,
          date_time,
          location,
          activity_type:activity_types(name, color)
        )
      `)
      .eq('user_id', userId)
      .order('registration_date', { ascending: false })

    if (error) throw error
    return data
  }

  // Credits
  static async getUserCredits(userId) {
    const { data, error } = await supabase
      .from('profiles')
      .select('credits')
      .eq('id', userId)
      .single()

    if (error) throw error
    return data.credits || 0
  }

  static async addCreditTransaction(userId, amount, type, description, activityId = null) {
    const { data, error } = await supabase
      .from('credit_transactions')
      .insert([
        {
          user_id: userId,
          activity_id: activityId,
          transaction_type: type,
          amount: amount,
          description: description
        }
      ])
      .select()
      .single()

    if (error) throw error

    // Update user's total credits
    const { error: updateError } = await supabase.rpc('update_user_credits', {
      user_id: userId,
      credit_change: type === 'earned' || type === 'awarded' ? amount : -amount
    })

    if (updateError) throw updateError
    return data
  }

  // Blog Posts
  static async getBlogPosts(limit = 10) {
    const { data, error } = await supabase
      .from('blog_posts')
      .select(`
        *,
        author:profiles(full_name)
      `)
      .eq('published', true)
      .order('published_at', { ascending: false })
      .limit(limit)

    if (error) throw error
    return data
  }

  // Products
  static async getProducts() {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('active', true)
      .order('name')

    if (error) throw error
    return data
  }

  // School Visits
  static async getSchoolVisit(accessCode) {
    const { data, error } = await supabase
      .from('school_visits')
      .select(`
        *,
        activity:activities(*),
        school:schools(*),
        stations:visit_stations(*)
      `)
      .eq('access_code', accessCode)
      .single()

    if (error) throw error
    return data
  }
}

// Authentication service
class GuidalAuth {
  
  // Sign up new user
  static async signUp(email, password, userData = {}) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: userData
      }
    })

    if (error) throw error

    // Create profile if sign up successful
    if (data.user) {
      await GuidalDB.updateProfile(data.user.id, {
        email: data.user.email,
        full_name: userData.full_name,
        user_type: userData.user_type || 'student'
      })
    }

    return data
  }

  // Sign in user
  static async signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })

    if (error) throw error
    return data
  }

  // Sign out user
  static async signOut() {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  }

  // Get current user
  static async getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser()
    return user
  }

  // Get current session
  static async getCurrentSession() {
    const { data: { session } } = await supabase.auth.getSession()
    return session
  }

  // Listen to auth changes
  static onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange((event, session) => {
      callback(event, session)
    })
  }

  // Password recovery
  static async resetPassword(email) {
    const { error } = await supabase.auth.resetPasswordForEmail(email)
    if (error) throw error
  }
}

// Real-time subscriptions service
class GuidalRealtime {
  
  // Subscribe to activity updates
  static subscribeToActivities(callback) {
    return supabase
      .channel('activities-changes')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'activities'
      }, callback)
      .subscribe()
  }

  // Subscribe to user's registrations
  static subscribeToUserRegistrations(userId, callback) {
    return supabase
      .channel('user-registrations')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'activity_registrations',
        filter: `user_id=eq.${userId}`
      }, callback)
      .subscribe()
  }
}

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { GuidalDB, GuidalAuth, GuidalRealtime, supabase }
}