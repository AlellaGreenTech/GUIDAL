# 🔧 GUIDAL Visit Planning Schema Fix - Installation Guide

## Overview
This upgrade transforms the GUIDAL visit planning system from a flat, denormalized structure to a professional, scalable, normalized database design.

## 🎯 What This Fix Accomplishes

### **Before (Issues Fixed):**
- ❌ Contact data duplicated in every visit record
- ❌ No relationship tracking between schools and visits
- ❌ Missing form fields not captured in database
- ❌ No contact management or reuse
- ❌ Poor data quality and inconsistency

### **After (Professional System):**
- ✅ Normalized database with proper relationships
- ✅ Contact and school management
- ✅ All form fields captured and validated
- ✅ Professional data views for admin dashboard
- ✅ Scalable, maintainable, efficient design

---

## 📋 Installation Steps

### **Step 1: Backup Your Data**
```sql
-- Create backup of current visits table
CREATE TABLE visits_backup AS SELECT * FROM visits;
```

### **Step 2: Run Schema Fix (Required)**
```bash
# In Supabase SQL Editor, run this file:
database/fix-visit-planning-schema.sql
```

**What this does:**
- Creates `schools` and `contacts` tables
- Adds missing fields to `visits` table
- Sets up proper relationships and constraints
- Creates indexes for performance
- Sets up Row Level Security
- Creates utility functions

### **Step 3: Create Database Views (Required)**
```bash
# In Supabase SQL Editor, run this file:
database/create-visit-views.sql
```

**What this does:**
- Creates optimized views for admin dashboard
- Creates analytics and reporting views
- Creates contact and school management views

### **Step 4: Migrate Existing Data (If you have existing visits)**
```bash
# In Supabase SQL Editor, run this file:
database/migrate-existing-visit-data.sql
```

**What this does:**
- Extracts school data from existing visits
- Extracts contact data from existing visits
- Updates visits with proper relationships
- Validates data quality
- Provides migration report

### **Step 5: Test New Form**
1. Open `pages/visit-planning.html`
2. Submit a test visit request
3. Check browser console for success messages
4. Verify data appears in database with proper relationships

---

## 🗃️ New Database Structure

### **Core Tables:**

#### **schools**
```sql
- id (UUID, Primary Key)
- name (Text, Required)
- city, country (Text)
- address, website, phone, email (Text)
- type (public/private/international/etc.)
- student_count_range (Text)
- active (Boolean)
- created_at, updated_at (Timestamps)
```

#### **contacts**
```sql
- id (UUID, Primary Key)
- name, email (Text, Required)
- phone, position (Text)
- type (organizer/lead_teacher/teacher/etc.)
- school_id (Foreign Key → schools)
- preferred_language (Text)
- is_primary (Boolean)
- active (Boolean)
- created_at, updated_at (Timestamps)
```

#### **visits** (Enhanced)
```sql
-- New fields added:
- visit_type (school_day_trip/school_overnight/etc.)
- proposed_visit_date (Date)
- city (Text)
- number_of_nights (Integer)
- arrival_date_time, departure_date_time (Timestamps)
- accommodation_selection (Text)
- accommodation_needs (Text)
- organizer_contact_id (Foreign Key → contacts)
- lead_teacher_contact_id (Foreign Key → contacts)
- school_id (Foreign Key → schools)
- source (Text - tracks where request came from)
- priority_level (low/normal/high/urgent)
```

### **Database Views:**

- **`visits_complete_view`** - Full visit data with all relationships
- **`visits_dashboard_view`** - Optimized for admin dashboard
- **`pending_visits_enhanced`** - Prioritized pending visits
- **`visit_statistics_view`** - Analytics and reporting
- **`school_visit_history`** - School relationship management
- **`contact_visit_summary`** - Contact relationship management

---

## 🧪 Testing & Validation

### **Test Form Submission:**
1. Fill out visit planning form completely
2. Include organizer contact (optional)
3. Test both day trip and overnight options
4. Submit and check browser console for success

### **Expected Console Output:**
```
🔄 Starting database submission with normalized schema...
✅ School ID: [uuid]
✅ Organizer Contact ID: [uuid] (if provided)
✅ Lead Teacher Contact ID: [uuid]
✅ Visit request saved with normalized schema: [visit object]
```

### **Verify Database:**
```sql
-- Check that relationships were created properly
SELECT
    v.id as visit_id,
    s.name as school_name,
    tc.name as teacher_name,
    oc.name as organizer_name
FROM visits v
LEFT JOIN schools s ON s.id = v.school_id
LEFT JOIN contacts tc ON tc.id = v.lead_teacher_contact_id
LEFT JOIN contacts oc ON oc.id = v.organizer_contact_id
ORDER BY v.created_at DESC
LIMIT 5;
```

---

## 🚀 Admin Dashboard Integration

### **Use New Views in Admin:**
```javascript
// Instead of querying visits directly:
const { data } = await supabase.from('visits').select('*')

// Use the new complete view:
const { data } = await supabase.from('visits_dashboard_view').select('*')

// This gives you:
// - All visit data
// - Related school information
// - Contact details
// - Calculated fields (urgency, status indicators)
// - Workshop details
```

### **Available Dashboard Views:**
- **`visits_dashboard_view`** - Main admin view
- **`pending_visits_enhanced`** - Prioritized queue
- **`school_visit_history`** - School management
- **`visit_statistics_view`** - Analytics

---

## 🔍 Troubleshooting

### **Common Issues:**

#### **"Function find_or_create_school does not exist"**
- **Solution:** Run `fix-visit-planning-schema.sql` first

#### **"Relation contacts does not exist"**
- **Solution:** Run `fix-visit-planning-schema.sql` first

#### **Form submission fails with constraint errors**
- **Solution:** Check browser console for specific validation errors
- Ensure all required fields are filled
- Check email format validation

#### **Migration shows data quality issues**
- **Solution:** Review the migration report
- Check `migration_issues` temp table for details
- Clean up data manually if needed

### **Get Help:**
- Check browser console for error details
- Review Supabase logs for database errors
- Test with simple data first

---

## 📊 Benefits After Installation

### **For Users:**
- ✅ Better form validation and error messages
- ✅ All form fields properly captured
- ✅ Faster form submission
- ✅ Better accommodation selection for overnight visits

### **For Administrators:**
- ✅ Professional admin dashboard with rich data
- ✅ Contact and school relationship management
- ✅ Analytics and reporting capabilities
- ✅ Duplicate detection and prevention
- ✅ Better data quality and consistency

### **For Developers:**
- ✅ Normalized, maintainable database design
- ✅ Proper foreign key relationships
- ✅ Optimized queries and indexes
- ✅ Scalable architecture
- ✅ Professional error handling

---

## 🎉 Installation Complete!

Your GUIDAL visit planning system is now running on a professional-grade database schema that's:
- **Scalable** - Can handle thousands of visits efficiently
- **Maintainable** - Proper relationships and constraints
- **Flexible** - Easy to extend with new features
- **Reliable** - Data integrity and validation
- **Professional** - Industry-standard design patterns

The system now provides a solid foundation for future growth and feature development!