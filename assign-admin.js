#!/usr/bin/env node

// Script to assign admin privileges to mpwicard@gmail.com
// Run with: node assign-admin.js

console.log('🔧 GUIDAL Admin Privilege Assignment');
console.log('===================================');

const adminEmail = 'mpwicard@gmail.com';

console.log(`\n📧 Assigning admin privileges to: ${adminEmail}`);

console.log(`
📋 MANUAL STEPS REQUIRED:

1. 🌐 Go to your Supabase dashboard:
   https://supabase.com/dashboard/project/lmsuyhzcmgdpjynosxvp/sql

2. 📝 Copy and paste this SQL query:

   -- Check if user exists and assign admin role
   UPDATE user_profiles
   SET
       role = 'admin',
       status = 'active',
       organization = 'Alella Green Tech',
       job_title = 'Administrator',
       email_verified = true,
       updated_at = NOW()
   WHERE user_id IN (
       SELECT id FROM auth.users WHERE email = '${adminEmail}'
   );

   -- If no profile exists, create one
   INSERT INTO user_profiles (
       user_id,
       full_name,
       role,
       status,
       organization,
       job_title,
       email_verified
   )
   SELECT
       au.id,
       COALESCE(au.raw_user_meta_data->>'full_name', 'Martin Picard'),
       'admin',
       'active',
       'Alella Green Tech',
       'Administrator',
       true
   FROM auth.users au
   WHERE au.email = '${adminEmail}'
   AND NOT EXISTS (
       SELECT 1 FROM user_profiles up WHERE up.user_id = au.id
   );

   -- Verify the assignment
   SELECT
       au.email,
       up.full_name,
       up.role,
       up.status,
       up.organization
   FROM auth.users au
   JOIN user_profiles up ON up.user_id = au.id
   WHERE au.email = '${adminEmail}';

3. ✅ Run the query to assign admin privileges

4. 🔍 VERIFICATION:
   After running the query, you should see output showing:
   - email: ${adminEmail}
   - role: admin
   - status: active

5. 🚪 LOGIN PROCESS:
   - Go to: http://localhost:8080/admin/auth.html
   - Use email: ${adminEmail}
   - Use the password you set when creating the account

📝 IMPORTANT NOTES:
• If the user doesn't exist yet, they need to sign up first at:
  http://localhost:8080/pages/auth/login.html

• The email ${adminEmail} must be verified in Supabase auth system

• Once admin privileges are assigned, the user can access:
  - http://localhost:8080/admin/ (main dashboard)
  - http://localhost:8080/admin/visit-requests.html (visit management)
  - http://localhost:8080/admin/form-editor.html (form editing)

🎯 ALTERNATIVE: Use the complete SQL file at:
   database/assign-admin-privileges.sql
`);

console.log('\n✨ Admin setup instructions complete!');