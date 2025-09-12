// Supabase Client for GUIDAL
// Updated for production database schema

const SUPABASE_URL = 'https://lmsuyhzcmgdpjynosxvp.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtc3V5aHpjbWdkcGp5bm9zeHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NzM5NjksImV4cCI6MjA3MzI0OTk2OX0.rRpHs_0ZLW3erdFnm2SwFTAmyQJYRMpcSlNzMBlcq4U'

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

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
      .select(`
        *,
        school:schools(name, country)
      `)
      .order('visit_date', { ascending: true })
    
    if (filters.upcoming) {
      query = query.gte('visit_date', new Date().toISOString().split('T')[0])
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
      .select(`
        *,
        school:schools(name, country)
      `)
      .eq('access_code', accessCode)
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
    let query = supabase
      .from('guest_book_entries')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (visitId) {
      query = query.eq('visit_id', visitId)
    }
    
    const { data, error } = await query
    
    if (error) {
      console.error('Error fetching guest book entries:', error)
      return []
    }
    return data || []
  }

  static async addGuestBookEntry(entryData) {
    const { data, error } = await supabase
      .from('guest_book_entries')
      .insert([entryData])
      .select()
    
    if (error) {
      console.error('Error adding guest book entry:', error)
      throw error
    }
    return data[0]
  }

  // Soil Mixtures (Station 1 - Planting)
  static async getSoilMixtures() {
    const { data, error } = await supabase
      .from('soil_mixtures')
      .select('*')
      .order('group_number', { ascending: true })
    
    if (error) {
      console.error('Error fetching soil mixtures:', error)
      return []
    }
    return data || []
  }

  static async addSoilMixture(mixtureData) {
    const { data, error } = await supabase
      .from('soil_mixtures')
      .insert([mixtureData])
      .select()
    
    if (error) {
      console.error('Error adding soil mixture:', error)
      throw error
    }
    return data[0]
  }

  static async updateSoilMixture(groupNumber, mixtureData) {
    const { data, error } = await supabase
      .from('soil_mixtures')
      .update(mixtureData)
      .eq('group_number', groupNumber)
      .select()
    
    if (error) {
      console.error('Error updating soil mixture:', error)
      throw error
    }
    return data[0]
  }

  // Activities (for dynamic content)
  static async getActivities(filters = {}) {
    let query = supabase
      .from('activities')
      .select('*')
      .eq('status', 'published')
      .order('date_time', { ascending: true })
    
    if (filters.type) {
      query = query.eq('activity_type', filters.type)
    }
    
    if (filters.search) {
      query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
    }
    
    if (filters.limit) {
      query = query.limit(filters.limit)
    }
    
    const { data, error } = await query
    
    if (error) {
      console.error('Error fetching activities:', error)
      return []
    }
    return data || []
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
    let channel = supabase
      .channel('guest_book_changes')
      .on('postgres_changes', { 
        event: '*', 
        schema: 'public', 
        table: 'guest_book_entries',
        filter: visitId ? `visit_id=eq.${visitId}` : undefined
      }, callback)
      .subscribe((status) => {
        console.log('Guest book subscription status:', status)
      })
    
    return channel
  }

  static subscribeToSoilMixtures(callback) {
    let channel = supabase
      .channel('soil_mixture_changes')
      .on('postgres_changes', { 
        event: '*', 
        schema: 'public', 
        table: 'soil_mixtures'
      }, callback)
      .subscribe((status) => {
        console.log('Soil mixtures subscription status:', status)
      })
    
    return channel
  }

  // Utility functions
  static async testConnection() {
    try {
      const { data, error } = await supabase
        .from('schools')
        .select('count(*)')
        .limit(1)
      
      if (error) throw error
      console.log('✅ Supabase connection successful')
      return true
    } catch (error) {
      console.error('❌ Supabase connection failed:', error)
      return false
    }
  }
}

// Export for use in other files
if (typeof window !== 'undefined') {
  window.GuidalDB = GuidalDB
}