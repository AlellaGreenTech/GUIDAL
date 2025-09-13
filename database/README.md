# 🗄️ GUIDAL Database Files

This directory contains all database-related files for the GUIDAL platform.

## 📁 Directory Structure

```
database/
├── README.md                 # This file
├── database-schema.sql       # Original GUIDAL database schema
├── sample-data.sql          # Original sample data
└── greens/                  # GREENs blockchain system
    ├── greens-schema-update.sql    # Complete GREENs database schema
    ├── populate-greens-data.sql    # Sample GREENs data and users
    └── update-activity-images.sql  # Image assignments for activities
```

## 🚀 Setup Instructions

### For GREENs System (Recommended)

Run these files **in order** in your Supabase SQL Editor:

1. **`greens/greens-schema-update.sql`**
   - Complete database schema with GREENs integration
   - Creates users, activities, transactions, completions tables
   - Sets up triggers and blockchain functionality

2. **`greens/populate-greens-data.sql`**
   - Sample activities with GREENs rewards
   - Demo user accounts
   - Sample transactions and completions

3. **`greens/update-activity-images.sql`**
   - Updates activities with image paths
   - Stores featured images in database

### For Basic GUIDAL (Legacy)

If you only need the basic system without GREENs:

1. **`database-schema.sql`** - Basic schema
2. **`sample-data.sql`** - Basic sample data

## 🌱 GREENs System Features

The GREENs subfolder contains the blockchain-based reward system:

- **User Management**: Comprehensive profiles with GREENs balances
- **Activity System**: Educational activities earn GREENs, recreational cost GREENs
- **Blockchain Integration**: Transaction hashing and verification
- **Image Management**: Featured images stored in database
- **Real-time Analytics**: Leaderboards and transaction tracking

## 🔧 Database Configuration

Update your `js/supabase-client.js` with your Supabase credentials before running:

```javascript
const SUPABASE_URL = 'your_supabase_url'
const SUPABASE_ANON_KEY = 'your_supabase_anon_key'
```

## 📊 Tables Overview

### Core Tables (GREENs System)
- **users** - User profiles and GREENs balances
- **activities** - Activities with rewards/costs and images
- **greens_transactions** - Blockchain transaction records
- **activity_completions** - Completed activities and earned GREENs
- **activity_registrations** - Activity sign-ups
- **schools** - Educational institutions
- **activity_types** - Categories of activities

### Legacy Tables (Basic System)
- **profiles** - Basic user profiles
- **school_visits** - School visit management
- **credits** - Basic credit system

---

**For support or questions about the database setup, see the main project README or contact the development team.**