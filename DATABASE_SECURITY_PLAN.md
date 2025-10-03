# Database Security & Schema Restoration Plan

## 🎯 Objective
Properly fix database security (RLS policies) and schema consistency while maintaining the working science-in-action cards with correct images.

## 📊 Current State Analysis

### Issues Identified:
- ❌ RLS policies blocking admin updates on `activities` table
- ❌ Schema inconsistency: activities categorized as "Workshop" instead of "Science Stations"
- ❌ Missing `featured_image` values in database
- ⚠️ Temporary workaround: app using static fallback data instead of database

### What's Working:
- ✅ Science-in-action cards displaying correctly with unique images
- ✅ All 9 science stations defined in static fallback data
- ✅ Image mapping system functional
- ✅ User authentication working

## 🛠️ Implementation Plan

### Phase 1: RLS Policy Investigation
**Objective:** Understand current permission restrictions

**Actions:**
1. Connect to Supabase dashboard as admin
2. Check current RLS policies:
   ```sql
   SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
   FROM pg_policies
   WHERE tablename = 'activities';
   ```
3. Review user roles and permissions:
   ```sql
   SELECT * FROM information_schema.role_table_grants
   WHERE table_name = 'activities';
   ```
4. Check if admin users have special privileges in profiles table

### Phase 2: Fix RLS Policies
**Objective:** Allow admin users to manage activities while maintaining security

**Option A: Admin Bypass Policy**
```sql
-- Enable RLS if not already enabled
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Create policy allowing admins full access
CREATE POLICY "admin_activities_full_access" ON activities
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.user_type = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.user_type = 'admin'
  )
);

-- Policy for regular users (read-only published activities)
CREATE POLICY "public_activities_read" ON activities
FOR SELECT
TO authenticated, anon
USING (status = 'published');
```

**Option B: Service Role (If Option A fails)**
- Use Supabase service role key for admin operations
- Create server-side admin endpoints with elevated permissions
- Keep client-side operations read-only

### Phase 3: Schema Migration
**Objective:** Fix activity categorization and add missing images

**Migration Script:**
```sql
-- Step 1: Get activity type IDs
DO $$
DECLARE
    workshop_type_id UUID;
    science_stations_type_id UUID;
BEGIN
    SELECT id INTO workshop_type_id FROM activity_types WHERE slug = 'workshop';
    SELECT id INTO science_stations_type_id FROM activity_types WHERE slug = 'science-stations';

    -- Step 2: Update activity types (only templates, not scheduled activities)
    UPDATE activities
    SET activity_type_id = science_stations_type_id
    WHERE activity_type_id = workshop_type_id
    AND date_time IS NULL;

    -- Step 3: Update titles, descriptions, and images
    UPDATE activities SET
        title = 'Hydraulic Ram Pumps',
        description = 'Moving water up high without electricity! Discover genius inventions of the past that use water pressure to pump water uphill.',
        featured_image = 'images/hydraulic-ram-pump-system.png',
        slug = 'hydraulic-ram-pumps'
    WHERE title = 'Ram Pumps Workshop';

    UPDATE activities SET
        title = 'Wattle & Daub Construction',
        description = 'Harvest clay, then build a home with mud, hay, and sticks - 6,000-year-old sustainable construction techniques that still work today!',
        featured_image = 'images/wattle-daub-construction.png',
        slug = 'wattle-daub-construction'
    WHERE title = 'Wattle and Daub Construction';

    UPDATE activities SET
        title = 'SchoolAIR IoT Sensors',
        description = 'Build and program IoT environmental monitoring stations that collect real-time air quality and weather data.',
        featured_image = 'images/school-visit-pond-canoe.png',
        slug = 'schoolair-iot-sensors'
    WHERE title = 'SchoolAir IoT Monitoring';

    UPDATE activities SET
        title = 'Composting & Soil Science',
        description = 'Discover the science of decomposition, nutrient cycles, and soil health through hands-on composting and soil analysis.',
        featured_image = 'images/composting-farm-scene.png',
        slug = 'composting-soil-science'
    WHERE title = 'Composting Workshop';

    UPDATE activities SET
        title = 'Planting & Growing',
        description = 'Plant seeds, track growth, and discover the science of plant biology through hands-on gardening and data collection.',
        featured_image = 'images/school-visit-planting.png',
        slug = 'planting-growing'
    WHERE title = 'Planting Workshop';

    UPDATE activities SET
        title = 'Erosion Challenge',
        description = 'Stop erosion, retain water and create a fertile hillside through natural engineering solutions and permaculture techniques.',
        featured_image = 'images/swales.jpg',
        slug = 'erosion-challenge'
    WHERE title = 'Pumped Hydro Storage';

    UPDATE activities SET
        title = 'Robotic Gardening',
        description = 'Tend your garden from 1,000km away - or let the bot do it! Explore automated agriculture and precision farming with real robotic systems.',
        featured_image = 'images/robotic-gardening-system.png',
        slug = 'robotic-gardening'
    WHERE title = 'Robotic Gardening Workshop';

    -- Step 4: Insert missing science stations if they don't exist
    INSERT INTO activities (
        title, slug, description, featured_image, duration_minutes, location,
        status, activity_type_id, date_time, current_participants,
        credits_required, credits_earned, price, requires_login
    )
    SELECT
        'Agricultural Drones & Vineyard',
        'agricultural-drones-vineyard',
        'Discover how drones monitor crop health, detect diseases early, and optimize vineyard management through aerial technology.',
        'images/agricultural-drone-vineyard.png',
        60,
        'Alella Green Tech Center',
        'published',
        science_stations_type_id,
        NULL,
        0, 0, 0, 0,
        false
    WHERE NOT EXISTS (
        SELECT 1 FROM activities WHERE title = 'Agricultural Drones & Vineyard'
    );

    INSERT INTO activities (
        title, slug, description, featured_image, duration_minutes, location,
        status, activity_type_id, date_time, current_participants,
        credits_required, credits_earned, price, requires_login
    )
    SELECT
        'Smart Irrigation Demo',
        'smart-irrigation-demo',
        'Visit the smartest automatic irrigation plant in the Maresme - see precision water management and automated watering systems in action.',
        'images/smart-irrigation-demo.png',
        45,
        'Alella Green Tech Center',
        'published',
        science_stations_type_id,
        NULL,
        0, 0, 0, 0,
        false
    WHERE NOT EXISTS (
        SELECT 1 FROM activities WHERE title = 'Smart Irrigation Demo'
    );

END $$;
```

### Phase 4: Verification & Testing
**Objective:** Ensure everything works correctly

**Verification Steps:**
1. **Admin Access Test:**
   ```javascript
   // Test in browser console after admin login
   const testUpdate = await window.supabaseClient
     .from('activities')
     .update({ updated_at: new Date().toISOString() })
     .eq('id', 'some-test-id');
   console.log('Admin update test:', testUpdate);
   ```

2. **Schema Validation:**
   ```sql
   -- Verify all science stations properly categorized
   SELECT title, activity_type.name as type, featured_image
   FROM activities
   JOIN activity_types ON activities.activity_type_id = activity_types.id
   WHERE activity_types.slug = 'science-stations'
   AND date_time IS NULL;
   ```

3. **Public Access Test:**
   ```javascript
   // Test read access for non-admin users
   const activities = await window.supabaseClient
     .from('activities')
     .select('*')
     .eq('status', 'published');
   console.log('Public read test:', activities);
   ```

### Phase 5: App Code Restoration
**Objective:** Remove temporary workaround and restore database integration

**Code Changes in `js/app.js`:**
```javascript
async loadActivities(filters = {}) {
    try {
        console.log('🔍 Loading activities with filters:', filters);

        // Restore database loading (remove temporary fallback)
        const timeoutPromise = new Promise((_, reject) =>
            setTimeout(() => reject(new Error('Database timeout')), 3000)
        );

        this.activities = await Promise.race([
            GuidalDB.getActivities(filters),
            timeoutPromise
        ]);

        console.log('✅ Activities loaded from database:', this.activities.length, 'activities');
        this.renderActivities();
    } catch (error) {
        console.error('❌ Error loading activities:', error);
        console.log('🔄 Falling back to static data');
        // Keep fallback as emergency backup
        this.activities = this.getFallbackActivities(filters);
        this.renderActivities();
    }
}
```

### Phase 6: Future Improvements
**Objective:** Prevent similar issues and improve maintainability

**Enhancements:**
1. **Admin Panel:** Create proper UI for managing activities
2. **Data Validation:** Add database constraints and validation
3. **Backup Strategy:** Regular exports of activity templates
4. **Error Monitoring:** Better error handling and logging
5. **Documentation:** Document RLS policies and procedures

## 🚀 Execution Steps

### Immediate (Tomorrow):
1. Access Supabase dashboard as admin
2. Run Phase 1 investigation queries
3. Implement Phase 2 RLS policy fixes
4. Test admin permissions

### Next:
1. Run Phase 3 schema migration
2. Verify all 9 science stations in database
3. Test Phase 4 verification steps
4. Restore Phase 5 app code

### Future:
1. Implement Phase 6 improvements
2. Create admin management interface
3. Set up monitoring and alerts

## 📝 Notes
- Keep temporary fallback code as emergency backup
- Test thoroughly in development before production
- Consider creating a separate admin API for sensitive operations
- Document all changes for future maintenance

## 🔒 Security Considerations
- Ensure only verified admin users can modify activities
- Maintain public read access for published activities
- Consider rate limiting for admin operations
- Log all administrative changes for audit trail