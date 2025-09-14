# GUIDAL Supabase Integration Setup Guide

This guide will walk you through setting up the complete GUIDAL system with Supabase integration, including authentication, database, file storage, and all new features.

## 📋 What's New

We've implemented a comprehensive upgrade to GUIDAL with the following new features:

### ✅ Enhanced Features Implemented:

1. **🔐 Proper Supabase Authentication**
   - User registration with email verification
   - Secure login/logout with session management
   - Password reset functionality
   - Profile-based authentication

2. **👤 User Profile Management**
   - Complete profile editing interface
   - Avatar upload functionality
   - School association management
   - Personal information management

3. **📝 Activity Registration System**
   - Real-time activity registration
   - Credit-based system integration
   - Registration status tracking
   - User registration history

4. **📁 File Upload System**
   - Avatar uploads for users
   - Activity image management
   - Document storage with proper permissions
   - Secure file access controls

5. **🛠️ Admin Dashboard**
   - User management interface
   - Activity management tools
   - School administration
   - System statistics and analytics

6. **🔔 Notification System**
   - In-app notifications for users
   - Admin broadcast capabilities
   - Activity registration confirmations
   - System updates and alerts

7. **⚡ Improved Error Handling**
   - User-friendly error messages
   - Comprehensive form validation
   - Network error recovery
   - Loading states and feedback

## 🚀 Setup Instructions

### Step 1: Supabase Project Setup

1. **Create a Supabase Project**
   ```
   1. Go to https://supabase.com
   2. Sign up/login and create a new project
   3. Choose project name: "GUIDAL"
   4. Set a strong database password
   5. Select your preferred region
   ```

2. **Get Your Project Credentials**
   ```
   1. Go to Settings > API in your Supabase dashboard
   2. Copy your Project URL and Anon public key
   3. Update js/supabase-client.js with your credentials:

   const SUPABASE_URL = 'your-project-url'
   const SUPABASE_ANON_KEY = 'your-anon-key'
   ```

### Step 2: Database Schema Setup

Run these SQL scripts in your Supabase SQL editor in order:

1. **Main Schema** (Required)
   ```sql
   -- Run: database/database-schema.sql
   -- This creates all core tables and relationships
   ```

2. **Notifications System** (Required)
   ```sql
   -- Run: database/notifications-schema.sql
   -- This adds the notification system tables and functions
   ```

3. **Storage Setup** (Required)
   ```sql
   -- Run: database/storage-setup.sql
   -- This creates storage buckets and policies for file uploads
   ```

4. **Sample Data** (Optional)
   ```sql
   -- Run: database/sample-data.sql
   -- This adds sample schools and activities for testing
   ```

### Step 3: Authentication Configuration

1. **Enable Email Authentication**
   ```
   1. Go to Authentication > Settings in Supabase
   2. Ensure Email/Password is enabled
   3. Set Site URL to your domain (e.g., https://your-domain.com)
   4. Add redirect URLs for development and production:
      - http://localhost:5500 (for development)
      - https://your-domain.com (for production)
   ```

2. **Email Templates** (Optional)
   ```
   1. Go to Authentication > Email Templates
   2. Customize confirmation and password reset emails
   3. Update links to point to your domain
   ```

### Step 4: Row Level Security (RLS)

The schema includes comprehensive RLS policies, but you may want to review and customize:

```sql
-- Example: Allow users to read their own data
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Example: Admin-only access to certain tables
CREATE POLICY "Admin only" ON activities
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND user_type = 'admin'
    )
  );
```

### Step 5: File Storage Configuration

Storage buckets are automatically created by the setup script:

- **`avatars`** - Public bucket for user profile pictures
- **`activity-images`** - Public bucket for activity photos
- **`documents`** - Private bucket for user documents

### Step 6: Test Your Setup

1. **Test Database Connection**
   ```javascript
   // Open browser console on your site and run:
   GuidalDB.testConnection()
   ```

2. **Test User Registration**
   ```
   1. Go to pages/auth/register.html
   2. Create a test account
   3. Check your email for verification
   4. Try logging in at pages/auth/login.html
   ```

3. **Test Admin Functions**
   ```
   1. Manually set a user's user_type to 'admin' in Supabase
   2. Visit pages/admin/dashboard.html
   3. Verify admin functionality works
   ```

## 🎯 Key Features Guide

### User Registration & Authentication

**Registration Process:**
1. Users fill out comprehensive registration form
2. System creates Supabase auth user + profile entry
3. Email verification sent automatically
4. Users can login after email verification

**Login Options:**
- Regular login with email/password
- School visit login (for temporary access)
- Password reset via email

### Activity Registration

**How it Works:**
1. Users browse activities on main page
2. Registration buttons show different states:
   - "Register" - Available for registration
   - "Login to Register" - Must login first
   - "✓ Registered" - Already registered
   - "Fully Booked" - No spots available
   - "Past Event" - Event already occurred

2. Registration process:
   - Checks user authentication
   - Validates credit requirements
   - Creates registration record
   - Updates participant count
   - Sends confirmation notification

### Profile Management

**Features:**
- Edit personal information
- Upload/change profile picture
- View registration history
- Check notifications
- Update school association

### Admin Dashboard

**Capabilities:**
- View system statistics
- Manage all users
- Create/edit activities
- Manage schools
- Send system notifications
- View registration reports

### File Upload System

**Supported Operations:**
- Avatar uploads (auto-resize recommended)
- Activity image management
- Document storage
- Secure access controls

## 🔧 Customization Options

### Adding New User Types

1. Update the database schema:
```sql
-- Add new user type to check constraint
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_type_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_user_type_check
  CHECK (user_type IN ('student', 'teacher', 'admin', 'staff', 'guest', 'your_new_type'));
```

2. Update the registration form and admin interface

### Creating Custom Activity Types

1. Add to activity types in database:
```sql
INSERT INTO activity_types (name, slug, description, color, icon) VALUES
('Custom Type', 'custom-type', 'Description here', '#color', '🎯');
```

2. Update the frontend activity type handling

### Customizing Notifications

The notification system supports different types:
- `info` - General information
- `success` - Positive confirmations
- `warning` - Important notices
- `error` - Error messages

## 🐛 Troubleshooting

### Common Issues:

1. **"Invalid login credentials" error**
   - Check if email is verified
   - Ensure correct email/password combination
   - Check Supabase auth logs

2. **File upload failures**
   - Verify storage buckets exist
   - Check file size limits (default 50MB)
   - Ensure proper RLS policies

3. **Registration not working**
   - Check if user already exists
   - Verify email domain restrictions
   - Check database connection

4. **Admin dashboard access denied**
   - Ensure user_type is set to 'admin'
   - Check RLS policies for admin access
   - Verify authentication status

### Debug Mode:

Enable detailed logging by opening browser console - all errors are logged with context.

## 📚 API Reference

### GuidalDB Methods

**Authentication:**
- `signUp(email, password, userData)` - Create new user
- `signIn(email, password)` - Login user
- `signOut()` - Logout user
- `resetPassword(email)` - Send password reset
- `getCurrentUser()` - Get current user info

**Profile Management:**
- `getProfile(userId)` - Get user profile
- `updateProfile(userId, data)` - Update profile
- `uploadFile(bucket, path, file)` - Upload file

**Activities:**
- `getActivities(filters)` - Get activities list
- `registerForActivity(activityId, userId)` - Register for activity
- `getMyRegistrations(userId)` - Get user's registrations

**Admin Functions:**
- `getAllUsers(filters)` - Get all users (admin only)
- `updateActivity(activityId, data)` - Update activity
- `createNotification(userId, title, message)` - Send notification

## 🔮 Next Steps

Recommended enhancements for future development:

1. **Payment Integration** - Add Stripe/PayPal for paid activities
2. **Calendar Integration** - Sync with Google Calendar
3. **Mobile App** - React Native companion app
4. **Advanced Analytics** - User behavior tracking
5. **Multilingual Support** - i18n implementation
6. **Social Features** - User interactions and community
7. **Advanced Notifications** - Push notifications and email campaigns

## 📞 Support

If you need help with setup or have questions:

1. Check the browser console for detailed error messages
2. Review Supabase logs in your dashboard
3. Verify all SQL scripts ran successfully
4. Test individual components step by step

The system is designed to be robust and user-friendly, with comprehensive error handling and helpful feedback messages throughout the user experience.

---

**🎉 Congratulations!** You now have a fully-featured GUIDAL system with modern authentication, user management, activity registration, file uploads, and admin capabilities!