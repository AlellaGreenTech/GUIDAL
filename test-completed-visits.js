// Test script to add some completed visits for testing
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://fexnuvybcjbzgaawvcgf.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZleG51dnliY2piemdhYXd2Y2dmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMTk0NzM5NSwiZXhwIjoyMDQ3NTIzMzk1fQ.WA_cRiLEi7VWvKJQGZXCj0i_xYQgHNaJ-AxLO0Qk0wE';

const supabase = createClient(supabaseUrl, supabaseKey);

async function addTestData() {
    try {
        console.log('🧪 Adding test completed visits...');

        const testVisits = [
            {
                school_name: 'Barcelona International School',
                contact_name: 'Maria Garcia',
                contact_email: 'maria@bis.edu',
                student_count: 25,
                grade_level: 'Grade 6-8',
                preferred_date: '2024-11-15',
                visit_duration: '6 hours',
                status: 'completed'
            },
            {
                school_name: 'Individual Visitor',
                contact_name: 'John Smith',
                contact_email: 'john.smith@gmail.com',
                student_count: 1,
                grade_level: 'Adult',
                preferred_date: '2024-11-10',
                visit_duration: '3 hours',
                status: 'completed'
            },
            {
                school_name: 'Green Tech Company',
                contact_name: 'Sarah Johnson',
                contact_email: 'sarah@greentech.com',
                student_count: 12,
                grade_level: 'Corporate Group',
                preferred_date: '2024-11-20',
                visit_duration: '4 hours',
                status: 'completed'
            }
        ];

        const { data, error } = await supabase
            .from('trip_requests')
            .insert(testVisits);

        if (error) {
            console.error('❌ Error adding test data:', error);
        } else {
            console.log('✅ Test completed visits added successfully');
        }

        // Test the filtering
        console.log('🔍 Testing completed status filter...');
        const { data: completedVisits, error: filterError } = await supabase
            .from('trip_requests')
            .select('*')
            .eq('status', 'completed');

        if (filterError) {
            console.error('❌ Error filtering completed visits:', filterError);
        } else {
            console.log('✅ Found', completedVisits.length, 'completed visits');
            completedVisits.forEach(visit => {
                console.log(`  - ${visit.school_name} (${visit.contact_name}) - ${visit.preferred_date}`);
            });
        }

    } catch (err) {
        console.error('❌ Script error:', err);
    }
}

addTestData();