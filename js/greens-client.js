// GREENs Blockchain System Client for GUIDAL
// Enhanced Supabase client with user management and GREENs transactions

class GREENsDB {
    // User Management
    static async registerUser(userData) {
        const { data, error } = await supabase
            .from('users')
            .insert([{
                email: userData.email,
                full_name: userData.fullName,
                username: userData.username,
                age: userData.age,
                birthday: userData.birthday,
                city: userData.city,
                region: userData.region,
                country: userData.country,
                phone: userData.phone,
                school_id: userData.schoolId,
                grade_level: userData.gradeLevel,
                languages: userData.languages || ['English'],
                social_media: userData.socialMedia || {},
                dietary_restrictions: userData.dietaryRestrictions,
                emergency_contact: userData.emergencyContact
            }])
            .select()

        if (error) {
            console.error('Error registering user:', error)
            throw error
        }
        return data[0]
    }

    static async loginUser(email, password) {
        // Simple authentication - in production, use Supabase Auth
        const { data, error } = await supabase
            .from('users')
            .select('*')
            .eq('email', email)
            .single()

        if (error || !data) {
            throw new Error('Invalid email or password')
        }

        // Store session in localStorage (simplified)
        localStorage.setItem('greens_user', JSON.stringify(data))
        localStorage.setItem('greens_session', new Date().getTime().toString())
        
        return data
    }

    static getCurrentUser() {
        const user = localStorage.getItem('greens_user')
        const session = localStorage.getItem('greens_session')
        
        if (!user || !session) return null
        
        // Check if session is still valid (24 hours)
        const sessionTime = parseInt(session)
        const now = new Date().getTime()
        if (now - sessionTime > 24 * 60 * 60 * 1000) {
            this.logoutUser()
            return null
        }
        
        return JSON.parse(user)
    }

    static logoutUser() {
        localStorage.removeItem('greens_user')
        localStorage.removeItem('greens_session')
    }

    static async updateUserProfile(userId, updates) {
        const { data, error } = await supabase
            .from('users')
            .update({ ...updates, updated_at: new Date().toISOString() })
            .eq('id', userId)
            .select()

        if (error) {
            console.error('Error updating user profile:', error)
            throw error
        }
        
        // Update local storage
        if (data[0]) {
            localStorage.setItem('greens_user', JSON.stringify(data[0]))
        }
        
        return data[0]
    }

    static async getUserProfile(userId) {
        const { data, error } = await supabase
            .from('users')
            .select(`
                *,
                school:schools(name, country)
            `)
            .eq('id', userId)
            .single()

        if (error) {
            console.error('Error fetching user profile:', error)
            return null
        }
        return data
    }

    // Activity Management
    static async getActivities(filters = {}) {
        let query = supabase
            .from('activities')
            .select(`
                *,
                activity_type:activity_types(name, slug, icon, color)
            `)
            .eq('status', 'published')
            .order('date_time', { ascending: true })

        if (filters.category) {
            query = query.eq('activity_category', filters.category)
        }

        if (filters.type) {
            query = query.eq('activity_type_id', filters.type)
        }

        if (filters.search) {
            query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`)
        }

        const { data, error } = await query

        if (error) {
            console.error('Error fetching activities:', error)
            return []
        }
        return data || []
    }

    static async getActivityTypes() {
        const { data, error } = await supabase
            .from('activity_types')
            .select('*')
            .order('name', { ascending: true })

        if (error) {
            console.error('Error fetching activity types:', error)
            return []
        }
        return data || []
    }

    static async registerForActivity(userId, activityId, registrationData = {}) {
        // Check if user has enough GREENs
        const activity = await this.getActivityById(activityId)
        const user = await this.getUserProfile(userId)
        
        if (activity.greens_cost > 0 && user.greens_balance < activity.greens_cost) {
            throw new Error(`Insufficient GREENs. Required: ${activity.greens_cost}, Available: ${user.greens_balance}`)
        }

        const { data, error } = await supabase
            .from('activity_registrations')
            .insert([{
                user_id: userId,
                activity_id: activityId,
                greens_used: activity.greens_cost,
                notes: registrationData.notes,
                emergency_contact: registrationData.emergencyContact,
                dietary_requirements: registrationData.dietaryRequirements
            }])
            .select()

        if (error) {
            console.error('Error registering for activity:', error)
            throw error
        }

        // If activity costs GREENs, create transaction
        if (activity.greens_cost > 0) {
            await this.createGREENsTransaction(
                userId,
                'spent',
                activity.greens_cost,
                user.greens_balance - activity.greens_cost,
                activityId,
                data[0].id,
                `GREENs spent for ${activity.title}`
            )
        }

        return data[0]
    }

    static async getActivityById(activityId) {
        const { data, error } = await supabase
            .from('activities')
            .select(`
                *,
                activity_type:activity_types(name, slug, icon, color)
            `)
            .eq('id', activityId)
            .single()

        if (error) {
            console.error('Error fetching activity:', error)
            throw error
        }
        return data
    }

    static async getUserRegistrations(userId) {
        const { data, error } = await supabase
            .from('activity_registrations')
            .select(`
                *,
                activity:activities(title, date_time, location, greens_cost)
            `)
            .eq('user_id', userId)
            .order('registration_date', { ascending: false })

        if (error) {
            console.error('Error fetching user registrations:', error)
            return []
        }
        return data || []
    }

    // GREENs Transaction Management
    static async createGREENsTransaction(userId, type, amount, newBalance, activityId = null, registrationId = null, description) {
        const currentUser = await this.getUserProfile(userId)
        
        const { data, error } = await supabase
            .from('greens_transactions')
            .insert([{
                user_id: userId,
                transaction_type: type,
                greens_amount: amount,
                balance_before: currentUser.greens_balance,
                balance_after: newBalance,
                activity_id: activityId,
                registration_id: registrationId,
                description: description,
                blockchain_hash: this.generateBlockchainHash(),
                blockchain_verified: true // Simplified for demo
            }])
            .select()

        if (error) {
            console.error('Error creating GREENs transaction:', error)
            throw error
        }

        return data[0]
    }

    static async awardGREENsForCompletion(userId, activityId, completionNotes = null) {
        const activity = await this.getActivityById(activityId)
        const user = await this.getUserProfile(userId)
        
        // Create completion record and award GREENs
        const { data, error } = await supabase.rpc('award_greens_for_completion', {
            p_user_id: userId,
            p_activity_id: activityId,
            p_greens_amount: activity.greens_reward,
            p_completion_notes: completionNotes
        })

        if (error) {
            console.error('Error awarding GREENs:', error)
            throw error
        }

        return data
    }

    static async getUserGREENsTransactions(userId, limit = 50) {
        const { data, error } = await supabase
            .from('greens_transactions')
            .select(`
                *,
                activity:activities(title),
                processed_by_user:users!processed_by(full_name)
            `)
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(limit)

        if (error) {
            console.error('Error fetching GREENs transactions:', error)
            return []
        }
        return data || []
    }

    static async getUserCompletions(userId) {
        const { data, error } = await supabase
            .from('activity_completions')
            .select(`
                *,
                activity:activities(title, greens_reward),
                verified_by_user:users!verified_by(full_name)
            `)
            .eq('user_id', userId)
            .order('completion_date', { ascending: false })

        if (error) {
            console.error('Error fetching user completions:', error)
            return []
        }
        return data || []
    }

    // Utility Functions
    static generateBlockchainHash() {
        // Enhanced hash generation for demo - in production, use actual blockchain
        const timestamp = Date.now()
        const random = Math.random().toString(36).substring(2)
        const userAgent = navigator.userAgent.split(' ')[0] || 'WEB'
        return `GRN${timestamp}${random}${userAgent.substring(0,3)}`.toUpperCase()
    }

    // Blockchain Integration Functions
    static async verifyTransaction(transactionId) {
        // Simulate blockchain verification
        const { data, error } = await supabase
            .from('greens_transactions')
            .select('*')
            .eq('id', transactionId)
            .single()

        if (error) {
            console.error('Error verifying transaction:', error)
            return false
        }

        // Simulate verification delay
        await new Promise(resolve => setTimeout(resolve, 1000))

        // Update verification status
        const { error: updateError } = await supabase
            .from('greens_transactions')
            .update({ 
                blockchain_verified: true,
                blockchain_network: 'GUIDAL-Chain',
                updated_at: new Date().toISOString()
            })
            .eq('id', transactionId)

        return !updateError
    }

    static async getTransactionProof(transactionId) {
        // Generate transaction proof for blockchain verification
        const { data, error } = await supabase
            .from('greens_transactions')
            .select('*')
            .eq('id', transactionId)
            .single()

        if (error || !data) return null

        return {
            transactionId: data.id,
            blockchainHash: data.blockchain_hash,
            userId: data.user_id,
            amount: data.greens_amount,
            type: data.transaction_type,
            timestamp: data.created_at,
            verified: data.blockchain_verified,
            network: data.blockchain_network
        }
    }

    static async getBlockchainStatus() {
        // Get overall blockchain system status
        const { data: recentTransactions, error } = await supabase
            .from('greens_transactions')
            .select('blockchain_verified, created_at')
            .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
            .order('created_at', { ascending: false })
            .limit(100)

        if (error) return null

        const totalTransactions = recentTransactions.length
        const verifiedTransactions = recentTransactions.filter(tx => tx.blockchain_verified).length
        const verificationRate = totalTransactions > 0 ? (verifiedTransactions / totalTransactions) * 100 : 0

        return {
            totalTransactions24h: totalTransactions,
            verifiedTransactions24h: verifiedTransactions,
            verificationRate: Math.round(verificationRate),
            networkStatus: verificationRate > 95 ? 'healthy' : verificationRate > 80 ? 'warning' : 'degraded',
            lastTransaction: recentTransactions[0]?.created_at || null
        }
    }

    static async getGREENsLeaderboard(limit = 10) {
        const { data, error } = await supabase
            .from('users')
            .select('full_name, username, total_greens_earned, greens_balance, school:schools(name)')
            .eq('active', true)
            .order('total_greens_earned', { ascending: false })
            .limit(limit)

        if (error) {
            console.error('Error fetching leaderboard:', error)
            return []
        }
        return data || []
    }

    static async searchUsers(query, limit = 20) {
        const { data, error } = await supabase
            .from('users')
            .select('id, full_name, username, email, school:schools(name), greens_balance')
            .or(`full_name.ilike.%${query}%,username.ilike.%${query}%,email.ilike.%${query}%`)
            .eq('active', true)
            .limit(limit)

        if (error) {
            console.error('Error searching users:', error)
            return []
        }
        return data || []
    }

    // Real-time subscriptions
    static subscribeToGREENsTransactions(userId, callback) {
        return supabase
            .channel('greens_transactions')
            .on('postgres_changes', {
                event: '*',
                schema: 'public',
                table: 'greens_transactions',
                filter: `user_id=eq.${userId}`
            }, callback)
            .subscribe()
    }

    static subscribeToActivityRegistrations(callback) {
        return supabase
            .channel('activity_registrations')
            .on('postgres_changes', {
                event: '*',
                schema: 'public',
                table: 'activity_registrations'
            }, callback)
            .subscribe()
    }
}

// Export for use in other files
if (typeof window !== 'undefined') {
    window.GREENsDB = GREENsDB
}