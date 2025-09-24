// Import CSV visit data into Supabase visits table
// This script processes the CSV data and imports it with correct field mappings

const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

// Supabase configuration
const SUPABASE_URL = 'https://lmsuyhzcmgdpjynosxvp.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtc3V5aHpjbWdkcGp5bm9zeHZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2NzM5NjksImV4cCI6MjA3MzI0OTk2OX0.rRpHs_0ZLW3erdFnm2SwFTAmyQJYRMpcSlNzMBlcq4U';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Parse CSV data and convert to visit records
function parseCSVLine(line) {
    const values = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
        const char = line[i];

        if (char === '"') {
            inQuotes = !inQuotes;
        } else if (char === ',' && !inQuotes) {
            values.push(current.trim());
            current = '';
        } else {
            current += char;
        }
    }
    values.push(current.trim());
    return values;
}

function extractStudentCount(studentsText) {
    if (!studentsText) return null;

    // Extract number from strings like "22 (16-17 years old)", "32-38", "27+24", "Approximately 70 students"
    const match = studentsText.match(/(\d+)(?:\s*[\-\+]\s*(\d+))?/);
    if (match) {
        const firstNumber = parseInt(match[1]);
        const secondNumber = match[2] ? parseInt(match[2]) : 0;
        return firstNumber + secondNumber;
    }
    return null;
}

function extractAdultCount(adultsText) {
    if (!adultsText) return 2; // Default to 2 adults

    // Extract number from strings like "3", "4 + 4", "7 teachers"
    const match = adultsText.match(/(\d+)(?:\s*[\+]\s*(\d+))?/);
    if (match) {
        const firstNumber = parseInt(match[1]);
        const secondNumber = match[2] ? parseInt(match[2]) : 0;
        return firstNumber + secondNumber;
    }
    return 2;
}

function parseVisitDate(dateText) {
    if (!dateText || dateText === 'tbd') return null;

    try {
        // Handle various date formats from CSV
        const cleanDate = dateText.replace(/th|st|nd|rd/g, '').trim();

        // Try parsing different formats
        const formats = [
            // "3.8.2024"
            /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/,
            // "24.10.2024"
            /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/,
            // "12th of November , 2024"
            /(\d{1,2})\s*of\s*(\w+)\s*,?\s*(\d{4})/i,
            // "7th of November, 20204" (typo)
            /(\d{1,2})\s*of\s*(\w+)\s*,?\s*(\d{4})/i,
            // "4th December, 2024"
            /(\d{1,2})\s*(\w+)\s*,?\s*(\d{4})/i,
            // "29th April, 20205" (typo)
            /(\d{1,2})\s*(\w+)\s*,?\s*(\d{4})/i
        ];

        // Try MM.DD.YYYY format
        let match = cleanDate.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/);
        if (match) {
            return `${match[3]}-${match[2].padStart(2, '0')}-${match[1].padStart(2, '0')}`;
        }

        // Try "day of month, year" format
        const monthNames = {
            'january': '01', 'february': '02', 'march': '03', 'april': '04',
            'may': '05', 'june': '06', 'july': '07', 'august': '08',
            'september': '09', 'october': '10', 'november': '11', 'december': '12'
        };

        match = cleanDate.match(/(\d{1,2})\s*(?:of\s*)?(\w+)\s*,?\s*(\d{4})/i);
        if (match) {
            const day = match[1].padStart(2, '0');
            const monthName = match[2].toLowerCase();
            const year = match[3];
            const month = monthNames[monthName];

            if (month) {
                return `${year}-${month}-${day}`;
            }
        }

        return null;
    } catch (error) {
        console.log(`Could not parse date: "${dateText}"`);
        return null;
    }
}

function determineVisitFormat(formatText) {
    if (!formatText) return 'other';

    const text = formatText.toLowerCase();
    if (text.includes('full day') && text.includes('lunch')) {
        return 'full_day_pizza_lunch';
    } else if (text.includes('morning') && text.includes('lunch')) {
        return 'morning_with_lunch';
    } else if (text.includes('morning') && (text.includes('no lunch') || text.includes('ends 13'))) {
        return 'morning_no_lunch';
    }
    return 'other';
}

function determineStatus(dateText, timestamp) {
    const visitDate = parseVisitDate(dateText);
    const today = new Date();

    if (visitDate) {
        const vDate = new Date(visitDate);
        if (vDate < today) {
            return 'completed';
        } else if (vDate > today) {
            return 'scheduled';
        }
    }

    // If no visit date or other cases, check if it's an old submission
    const submittedDate = new Date(timestamp);
    const daysSinceSubmission = (today - submittedDate) / (1000 * 60 * 60 * 24);

    if (daysSinceSubmission > 30) {
        return 'completed'; // Old submissions are likely completed
    }

    return 'approved';
}

async function importVisitsData() {
    try {
        console.log('📖 Reading CSV file...');
        const csvContent = fs.readFileSync('/Users/martinpicard/Websites/GUIDAL/visits/2025 School Visits to Alella Green Tech - Trip Info and Builder (Responses) - Form responses 1.csv', 'utf-8');

        const lines = csvContent.split('\n');
        const headers = parseCSVLine(lines[0]);

        console.log('📊 Processing', lines.length - 1, 'visit records...');

        const visits = [];

        for (let i = 1; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line) continue;

            const values = parseCSVLine(line);
            if (values.length < 5) continue; // Skip incomplete rows

            const timestamp = values[0];
            const email = values[1];
            const schoolName = values[2];
            const country = values[3];
            const visitDates = values[4];
            const language = values[5];
            const studentCountText = values[6];
            const adultCountText = values[7];
            const contactDetails = values[8];
            const visitFormat = values[9];
            const topics = values[10];
            const approach = values[11];
            const interests = values[12];
            const comments = values[13];
            const food = values[14];
            const requests = values[15];

            if (!email || !schoolName) continue; // Skip rows without essential data

            const visit = {
                contact_email: email,
                lead_teacher_contact: contactDetails || email,
                school_name: schoolName,
                country_of_origin: country || 'Unknown',
                potential_visit_dates: visitDates,
                preferred_language: language || 'English',
                number_of_students: extractStudentCount(studentCountText),
                number_of_adults: extractAdultCount(adultCountText),
                visit_format: determineVisitFormat(visitFormat),
                visit_format_other: visitFormat && !['full_day_pizza_lunch', 'morning_with_lunch', 'morning_no_lunch'].includes(determineVisitFormat(visitFormat)) ? visitFormat : null,
                educational_focus: approach === 'We prefer seeing real world examples that relate to things learnt about at school/homeschooling such as erosion, water table, evaporation, etc' ? 'seeing_real_world_science' :
                                 approach === 'We prefer a very hands on visit where kids work with the land, water, plants, & soil following permaculture principles' ? 'hands_on_permaculture' :
                                 approach === 'We prefer a balanced mix of seeing things and doing things' ? 'balanced_mix' : 'other',
                educational_focus_other: approach && !['seeing_real_world_science', 'hands_on_permaculture', 'balanced_mix'].includes(approach) ? approach : null,
                additional_comments: [topics, comments, requests].filter(Boolean).join('\n\n'),
                status: determineStatus(visitDates, timestamp),
                submitted_at: new Date(timestamp).toISOString(),
                confirmed_date: parseVisitDate(visitDates),
                internal_notes: `Imported from CSV. Food preferences: ${food || 'Not specified'}`
            };

            // Clean up any undefined values
            Object.keys(visit).forEach(key => {
                if (visit[key] === undefined) {
                    visit[key] = null;
                }
            });

            visits.push(visit);
            console.log(`✅ Processed: ${schoolName} (${visit.number_of_students} students, ${visit.number_of_adults} adults, status: ${visit.status})`);
        }

        console.log(`\n📤 Importing ${visits.length} visits to database...`);

        // Clear existing data (optional - comment out if you want to keep existing records)
        console.log('🧹 Clearing existing visits...');
        await supabase.from('visits').delete().neq('id', '00000000-0000-0000-0000-000000000000');

        // Insert new data in batches
        const batchSize = 10;
        for (let i = 0; i < visits.length; i += batchSize) {
            const batch = visits.slice(i, i + batchSize);

            const { data, error } = await supabase
                .from('visits')
                .insert(batch)
                .select();

            if (error) {
                console.error('❌ Error inserting batch:', error);
                console.log('Problematic records:', batch);
            } else {
                console.log(`✅ Inserted batch ${Math.floor(i/batchSize) + 1}: ${data.length} records`);
            }
        }

        console.log('\n🎉 Import completed successfully!');

        // Verify import
        const { count } = await supabase
            .from('visits')
            .select('*', { count: 'exact', head: true });

        console.log(`📊 Total visits in database: ${count}`);

    } catch (error) {
        console.error('❌ Import failed:', error);
    }
}

// Run the import
importVisitsData();