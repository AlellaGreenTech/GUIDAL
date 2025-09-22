const { createClient } = require('@supabase/supabase-js');

// Supabase configuration
const supabaseUrl = 'https://fexnuvybcjbzgaawvcgf.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZleG51dnliY2piemdhYXd2Y2dmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMTk0NzM5NSwiZXhwIjoyMDQ3NTIzMzk1fQ.WA_cRiLEi7VWvKJQGZXCj0i_xYQgHNaJ-AxLO0Qk0wE';

const supabase = createClient(supabaseUrl, supabaseKey);

async function setupTripRequestsTable() {
    try {
        console.log('🔧 Creating trip_requests table...');

        // Create basic table
        const createTableSQL = `
            CREATE TABLE IF NOT EXISTS trip_requests (
                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                school_name TEXT NOT NULL,
                contact_name TEXT NOT NULL,
                contact_email TEXT NOT NULL,
                contact_phone TEXT,
                student_count INTEGER NOT NULL CHECK (student_count > 0),
                teacher_count INTEGER DEFAULT 2,
                grade_level TEXT NOT NULL,
                preferred_date DATE NOT NULL,
                visit_duration TEXT NOT NULL,
                status TEXT DEFAULT 'pending',
                submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        `;

        const { error: createError } = await supabase.rpc('exec_sql', { sql: createTableSQL });

        if (createError) {
            console.error('❌ Error creating table:', createError);
            return;
        }

        console.log('✅ trip_requests table created');

        // Add some sample data
        console.log('📝 Adding sample school data...');

        const sampleSchools = [
            {
                school_name: 'Barcelona International School',
                contact_name: 'Maria Garcia',
                contact_email: 'maria.garcia@bis.edu',
                student_count: 25,
                grade_level: 'Grade 6-8',
                preferred_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                visit_duration: '6 hours'
            },
            {
                school_name: 'International School of Catalunya',
                contact_name: 'David Smith',
                contact_email: 'david.smith@isc.es',
                student_count: 18,
                grade_level: 'Grade 9-12',
                preferred_date: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                visit_duration: '4 hours'
            },
            {
                school_name: 'American School of Barcelona',
                contact_name: 'Jennifer Rodriguez',
                contact_email: 'j.rodriguez@asb.es',
                student_count: 22,
                grade_level: 'Grade 4-5',
                preferred_date: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                visit_duration: '3 hours'
            }
        ];

        const { data: insertData, error: insertError } = await supabase
            .from('trip_requests')
            .insert(sampleSchools);

        if (insertError) {
            console.error('❌ Error inserting sample data:', insertError);
        } else {
            console.log('✅ Sample data inserted');
        }

        // Test the table
        const { data: testData, error: testError } = await supabase
            .from('trip_requests')
            .select('school_name')
            .order('school_name');

        if (testError) {
            console.error('❌ Error testing table:', testError);
        } else {
            console.log('✅ Table test successful, schools found:');
            testData.forEach(row => console.log('  -', row.school_name));
        }

    } catch (err) {
        console.error('❌ Setup error:', err);
    }
}

setupTripRequestsTable();