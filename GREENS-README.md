# 🌱 GREENs Blockchain Reward System for GUIDAL

## Overview

The GREENs system is a comprehensive blockchain-based reward system integrated into the GUIDAL platform. Students earn GREENs by participating in educational activities and can spend them on recreational activities, creating a sustainable learning economy.

## 🎯 Core Concept

- **Earn GREENs**: Participate in educational activities to earn rewards
  - 1 GREEN: Easy educational activities (presentations, simple workshops)
  - 2 GREENs: Activities with manual work (planting, building, experiments)
  - 3 GREENs: Full-day activities with manual work and instruction
  
- **Spend GREENs**: Use earned GREENs for recreational activities
  - 1 GREEN: 30 minutes of recreational activities (football, games)
  - 2 GREENs: Special recreational events
  - 3 GREENs: Premium recreational experiences

## 🏗️ System Architecture

### Database Schema
The system uses PostgreSQL with the following key tables:
- **users**: Comprehensive user profiles with GREENs balances
- **activities**: Activities with GREENs rewards and costs
- **greens_transactions**: Blockchain-ready transaction records
- **activity_completions**: Records of completed activities
- **activity_registrations**: Activity sign-ups

### Files Structure
```
GUIDAL/
├── database/
│   └── greens/
│       ├── greens-schema-update.sql     # Database schema
│       ├── populate-greens-data.sql     # Sample data
│       └── update-activity-images.sql   # Image assignments
├── server/
│   ├── server.py                # Python development server (recommended)
│   ├── server.js               # Node.js development server
│   ├── package.json            # NPM configuration
│   └── README.md               # Server documentation
├── js/
│   ├── greens-client.js         # Main GREENs API client
│   └── supabase-client.js       # Database connection
├── dashboard.html               # User dashboard
├── register.html               # User registration
├── login-greens.html           # GREENs login system
├── test-greens.html            # System testing page
├── start-server.sh             # Quick server launcher
└── styles.css                  # Updated with GREENs styles
```

## 🚀 Setup Instructions

### 1. Database Setup
Run these SQL files in your Supabase dashboard (in order):
```sql
-- 1. First, run the main schema update
-- Copy and run: database/greens/greens-schema-update.sql

-- 2. Then populate with sample data
-- Copy and run: database/greens/populate-greens-data.sql

-- 3. Finally, set up activity images
-- Copy and run: database/greens/update-activity-images.sql
```

### 2. Configuration
Update `js/supabase-client.js` with your Supabase credentials:
```javascript
const SUPABASE_URL = 'your_supabase_url'
const SUPABASE_ANON_KEY = 'your_supabase_anon_key'
```

### 3. Testing
Visit `test-greens.html` to verify all systems are working correctly.

## 🌟 Key Features

### User Management
- Comprehensive user profiles with personal, educational, and social information
- Age, school affiliation, languages, social media handles
- Dietary restrictions and emergency contacts
- User type classification (student, teacher, admin)

### GREENs Economy
- **Earning System**: Automated GREENs rewards based on activity completion
- **Spending System**: GREENs deduction for recreational activities
- **Balance Tracking**: Real-time balance updates and transaction history
- **Leaderboards**: Community rankings based on GREENs earned

### Blockchain Integration
- **Transaction Hashing**: Each transaction gets a unique blockchain hash
- **Verification System**: Transactions are verified on the blockchain
- **Network Status**: Real-time blockchain network health monitoring
- **Transaction Proofs**: Cryptographic proofs for all transactions

### Activity System
- **Smart Categorization**: Automatic GREENs assignment based on activity type
- **Registration Management**: Users must register for activities
- **Completion Tracking**: Record activity completions with scores
- **Real-time Updates**: Live participant counts and availability

## 👥 User Experience

### Registration Flow
1. User visits `register.html`
2. Fills comprehensive profile form
3. Receives 5 GREENs welcome bonus
4. Account created and ready to use

### Activity Participation
1. Browse activities on main page (now shows GREENs info)
2. Register for educational activities (earn GREENs)
3. Complete activities and receive rewards
4. Use earned GREENs for recreational activities

### Dashboard Experience
1. View GREENs balance and statistics
2. See upcoming registered activities
3. Review transaction history with blockchain verification
4. Track activity completions and achievements
5. Check position on community leaderboard

## 🔧 API Reference

### Main Classes

#### GREENsDB
The main API client for all GREENs operations.

```javascript
// User Management
await GREENsDB.registerUser(userData)
await GREENsDB.loginUser(email, password)
await GREENsDB.getUserProfile(userId)

// Activity Management
await GREENsDB.getActivities(filters)
await GREENsDB.registerForActivity(userId, activityId)
await GREENsDB.getUserRegistrations(userId)

// GREENs Transactions
await GREENsDB.createGREENsTransaction(userId, type, amount, newBalance, description)
await GREENsDB.getUserGREENsTransactions(userId, limit)
await GREENsDB.awardGREENsForCompletion(userId, activityId)

// Blockchain Features
await GREENsDB.verifyTransaction(transactionId)
await GREENsDB.getTransactionProof(transactionId)
await GREENsDB.getBlockchainStatus()

// Utilities
await GREENsDB.getGREENsLeaderboard(limit)
await GREENsDB.searchUsers(query)
```

## 🎨 UI Components

### GREENs Display Elements
```html
<!-- Activity with GREENs info -->
<div class="greens-info">
    <span class="greens-reward">+3 GREENs</span>
    <span class="greens-cost">Free</span>
</div>

<!-- Recreational activity that costs GREENs -->
<div class="greens-info">
    <span class="greens-cost has-cost">Costs 2 GREENs</span>
</div>

<!-- Blockchain verification status -->
<span class="blockchain-status verified">✓ Verified</span>
<span class="blockchain-status pending">⏳ Pending</span>
```

## 📊 Demo Accounts

The system includes several demo accounts for testing:

### Students
- **alice@demo.com** (Alice Green) - 8 GREENs balance
- **bob@demo.com** (Bob Martinez) - 5 GREENs balance  
- **david@demo.com** (David Chen) - 12 GREENs balance

### Teachers
- **carol@demo.com** (Dr. Carol Johnson) - 20 GREENs balance

### General Demo
- **student@demo.com** / **teacher@demo.com** (password: any)

## 🔒 Security & Privacy

- Row Level Security (RLS) enabled on all tables
- User authentication with session management
- Blockchain verification for transaction integrity
- Personal data protection compliance
- Emergency contact and dietary restriction handling

## 🌍 Multilingual Support

The system supports multiple languages:
- English (default)
- Spanish
- French
- German
- Catalan
- Dutch
- Czech

## 📈 Analytics & Reporting

### Blockchain Analytics
- Network health monitoring
- Transaction verification rates
- 24-hour activity summaries
- User engagement metrics

### Educational Analytics
- Activity completion rates
- GREENs earning patterns
- User progression tracking
- Community leaderboards

## 🚦 Testing & Validation

Use `test-greens.html` to validate:
- Database connectivity
- User management system
- Activity system integration
- GREENs transaction processing
- Blockchain verification
- UI component rendering

## 🔄 Future Enhancements

### Phase 2 Features
- Real blockchain integration (Ethereum/Polygon)
- Mobile app development
- Advanced analytics dashboard
- Peer-to-peer GREENs transfers
- Achievement badges and certificates
- Integration with external educational platforms

### Technical Improvements
- API rate limiting
- Advanced caching strategies
- Real-time notifications
- Offline functionality
- Advanced search and filtering

## 📞 Support & Maintenance

### Monitoring
- Database performance tracking
- Transaction success rates
- User engagement metrics
- System error logging

### Backup & Recovery
- Automated database backups
- Transaction log preservation
- User data recovery procedures
- Blockchain data synchronization

## 🎯 Success Metrics

The system tracks several key metrics:
- **User Engagement**: Activity participation rates
- **Economic Activity**: GREENs earned vs. spent ratios
- **Educational Impact**: Completion rates and scores
- **System Reliability**: Blockchain verification success rates
- **Community Growth**: New user registration and retention

---

**Built with** ❤️ **for sustainable education by the GUIDAL team**

For technical support or questions, contact: support@allellagreentech.com