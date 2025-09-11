# Supabase Setup Guide for GUIDAL

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up/login and create a new project
3. Choose a project name: "GUIDAL"
4. Set a strong database password
5. Select your preferred region (Europe for Spain)

## 2. Get Your Project Keys

Once your project is ready:
1. Go to Settings > API
2. Copy these values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon public key**: `eyJ...` (long string)

## 3. Run Database Schema

1. Go to SQL Editor in your Supabase dashboard
2. Copy and paste the entire contents of `database-schema.sql`
3. Click "Run" to create all tables and relationships

## 4. Configure Authentication

1. Go to Authentication > Settings
2. Enable these providers:
   - Email/Password (already enabled)
   - Google (optional, for easy login)
3. Set Site URL to your domain (e.g., `https://your-domain.com`)
4. Add redirect URLs:
   - `http://localhost:5500` (for development)
   - `https://your-domain.com` (for production)

## 5. Set Up Row Level Security Policies

The schema includes basic RLS policies, but you may want to customize:
1. Go to Authentication > Policies
2. Review and adjust policies as needed

## 6. Environment Configuration

Create a `.env` file (never commit this to git):
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 7. Initial Data Setup

After running the schema, you can:
1. Add your school data through the Supabase dashboard
2. Create admin user accounts
3. Import your existing activities

## Next Steps

Once Supabase is set up:
1. Install the Supabase JavaScript client
2. Update the GUIDAL frontend to use database queries
3. Implement authentication flows
4. Test all functionality

## Security Notes

- Never expose your `service_role` key in frontend code
- Always use the `anon` key for client-side operations
- RLS policies protect your data automatically
- Keep your database password secure