// Admin Booking Configuration System
class BookingConfigManager {
    constructor() {
        this.config = {
            general: {
                advanceBookingDays: 7,
                maxBookingDays: 365,
                defaultMinParticipants: 5,
                bookingConfirmationHours: 48
            },
            dateRestrictions: {
                blockedDaysOfWeek: [], // 0 = Sunday, 1 = Monday, etc.
                blockedDateRanges: []
            },
            timeSlots: {
                morning: [
                    { time: '09:00', label: '9:00 AM' },
                    { time: '10:00', label: '10:00 AM' },
                    { time: '11:00', label: '11:00 AM' }
                ],
                afternoon: [
                    { time: '14:00', label: '2:00 PM' },
                    { time: '15:00', label: '3:00 PM' },
                    { time: '16:00', label: '4:00 PM' }
                ]
            },
            activitySpecific: {}
        };

        this.loadConfiguration();
    }

    async loadConfiguration() {
        try {
            console.log('📋 Loading booking configuration...');

            // Load from database if exists, otherwise use defaults
            const { data, error } = await window.supabaseClient
                .from('booking_configuration')
                .select('*')
                .single();

            if (data && !error) {
                this.config = { ...this.config, ...data.config };
                console.log('✅ Loaded configuration from database');
            } else {
                console.log('ℹ️ Using default configuration');
            }

            this.renderConfiguration();
            await this.loadActivitySpecificSettings();

        } catch (error) {
            console.error('❌ Failed to load configuration:', error);
            this.showStatus('Failed to load configuration', 'error');
        }
    }

    renderConfiguration() {
        // Render general settings
        document.getElementById('advance-booking-days').value = this.config.general.advanceBookingDays;
        document.getElementById('max-booking-days').value = this.config.general.maxBookingDays;
        document.getElementById('default-min-participants').value = this.config.general.defaultMinParticipants;
        document.getElementById('booking-confirmation-hours').value = this.config.general.bookingConfirmationHours;

        // Render blocked days of week
        this.config.dateRestrictions.blockedDaysOfWeek.forEach(day => {
            const checkbox = document.querySelector(`input[value="${day}"]`);
            if (checkbox) checkbox.checked = true;
        });

        // Render blocked date ranges
        this.renderBlockedDateRanges();

        // Render time slots
        this.renderTimeSlots();
    }

    renderBlockedDateRanges() {
        const container = document.getElementById('blocked-date-ranges');
        container.innerHTML = '';

        this.config.dateRestrictions.blockedDateRanges.forEach((range, index) => {
            const rangeDiv = document.createElement('div');
            rangeDiv.className = 'blocked-date-range';
            rangeDiv.innerHTML = `
                <input type="date" value="${range.start}" onchange="updateBlockedDateRange(${index}, 'start', this.value)">
                <span>to</span>
                <input type="date" value="${range.end}" onchange="updateBlockedDateRange(${index}, 'end', this.value)">
                <input type="text" placeholder="Reason (optional)" value="${range.reason || ''}" onchange="updateBlockedDateRange(${index}, 'reason', this.value)">
                <button class="btn btn-danger" onclick="removeBlockedDateRange(${index})">🗑️</button>
            `;
            container.appendChild(rangeDiv);
        });
    }

    renderTimeSlots() {
        // Render morning slots
        const morningContainer = document.getElementById('morning-slots');
        morningContainer.innerHTML = '';
        this.config.timeSlots.morning.forEach((slot, index) => {
            this.addTimeSlotElement(morningContainer, 'morning', slot, index);
        });

        // Render afternoon slots
        const afternoonContainer = document.getElementById('afternoon-slots');
        afternoonContainer.innerHTML = '';
        this.config.timeSlots.afternoon.forEach((slot, index) => {
            this.addTimeSlotElement(afternoonContainer, 'afternoon', slot, index);
        });
    }

    addTimeSlotElement(container, period, slot, index) {
        const slotDiv = document.createElement('div');
        slotDiv.className = 'time-slot-item';
        slotDiv.innerHTML = `
            <input type="time" value="${slot.time}" onchange="updateTimeSlot('${period}', ${index}, 'time', this.value)">
            <input type="text" value="${slot.label}" placeholder="Display label" onchange="updateTimeSlot('${period}', ${index}, 'label', this.value)">
            <button class="btn btn-danger" onclick="removeTimeSlot('${period}', ${index})">🗑️</button>
        `;
        container.appendChild(slotDiv);
    }

    async loadActivitySpecificSettings() {
        try {
            // Get all science-in-action activities
            const { data: activities, error } = await window.supabaseClient
                .from('activities')
                .select(`
                    id, title, min_participants, max_participants,
                    duration_minutes, price_euros,
                    activity_type:activity_types!activity_type_id(slug)
                `)
                .eq('activity_types.slug', 'science-stations')
                .eq('status', 'published');

            if (error) throw error;

            const container = document.getElementById('activity-specific-config');
            container.innerHTML = '';

            activities.forEach(activity => {
                const activityConfig = this.config.activitySpecific[activity.id] || {};

                const configDiv = document.createElement('div');
                configDiv.className = 'activity-config-item';
                configDiv.innerHTML = `
                    <h5>${activity.title}</h5>
                    <div class="form-group">
                        <label>Minimum Participants:</label>
                        <input type="number" value="${activityConfig.minParticipants || activity.min_participants || 5}"
                               min="1" max="20" onchange="updateActivityConfig('${activity.id}', 'minParticipants', this.value)">
                    </div>
                    <div class="form-group">
                        <label>Maximum Participants:</label>
                        <input type="number" value="${activityConfig.maxParticipants || activity.max_participants || 15}"
                               min="1" max="50" onchange="updateActivityConfig('${activity.id}', 'maxParticipants', this.value)">
                    </div>
                    <div class="form-group">
                        <label>Price per Person (€):</label>
                        <input type="number" value="${activityConfig.priceEuros || activity.price_euros || 25}"
                               min="0" step="0.01" onchange="updateActivityConfig('${activity.id}', 'priceEuros', this.value)">
                    </div>
                    <div class="form-group">
                        <label>Duration (minutes):</label>
                        <input type="number" value="${activityConfig.durationMinutes || activity.duration_minutes || 120}"
                               min="30" step="15" onchange="updateActivityConfig('${activity.id}', 'durationMinutes', this.value)">
                    </div>
                    <div class="form-group">
                        <label>
                            <input type="checkbox" ${activityConfig.enabled !== false ? 'checked' : ''}
                                   onchange="updateActivityConfig('${activity.id}', 'enabled', this.checked)">
                            Enable for booking
                        </label>
                    </div>
                `;
                container.appendChild(configDiv);
            });

        } catch (error) {
            console.error('❌ Failed to load activity settings:', error);
            document.getElementById('activity-specific-config').innerHTML =
                '<p class="error">Failed to load activity settings</p>';
        }
    }

    async saveConfiguration() {
        try {
            this.showStatus('Saving configuration...', 'info');

            // Collect current form values
            this.collectFormValues();

            // Save to database
            const { error } = await window.supabaseClient
                .from('booking_configuration')
                .upsert({
                    id: 'default',
                    config: this.config,
                    updated_at: new Date().toISOString()
                });

            if (error) throw error;

            // Update the booking modal time options
            this.updateBookingModalTimeOptions();

            this.showStatus('Configuration saved successfully!', 'success');
            console.log('✅ Configuration saved:', this.config);

        } catch (error) {
            console.error('❌ Failed to save configuration:', error);
            this.showStatus('Failed to save configuration: ' + error.message, 'error');
        }
    }

    collectFormValues() {
        // General settings
        this.config.general = {
            advanceBookingDays: parseInt(document.getElementById('advance-booking-days').value),
            maxBookingDays: parseInt(document.getElementById('max-booking-days').value),
            defaultMinParticipants: parseInt(document.getElementById('default-min-participants').value),
            bookingConfirmationHours: parseInt(document.getElementById('booking-confirmation-hours').value)
        };

        // Blocked days of week
        this.config.dateRestrictions.blockedDaysOfWeek = [];
        document.querySelectorAll('input[type="checkbox"]:checked').forEach(checkbox => {
            const day = parseInt(checkbox.value);
            if (!isNaN(day)) {
                this.config.dateRestrictions.blockedDaysOfWeek.push(day);
            }
        });
    }

    updateBookingModalTimeOptions() {
        // Update the booking modal time select with current configuration
        const timeSelect = document.getElementById('booking-time');
        if (timeSelect) {
            timeSelect.innerHTML = '<option value="">Select time...</option>';

            // Add morning slots
            this.config.timeSlots.morning.forEach(slot => {
                const option = document.createElement('option');
                option.value = slot.time;
                option.textContent = slot.label;
                timeSelect.appendChild(option);
            });

            // Add afternoon slots
            this.config.timeSlots.afternoon.forEach(slot => {
                const option = document.createElement('option');
                option.value = slot.time;
                option.textContent = slot.label;
                timeSelect.appendChild(option);
            });
        }
    }

    getDateRestrictions() {
        // Return current date restrictions for use in booking modal
        return {
            minDate: this.getMinBookingDate(),
            maxDate: this.getMaxBookingDate(),
            blockedDays: this.config.dateRestrictions.blockedDaysOfWeek,
            blockedRanges: this.config.dateRestrictions.blockedDateRanges
        };
    }

    getMinBookingDate() {
        const minDate = new Date();
        minDate.setDate(minDate.getDate() + this.config.general.advanceBookingDays);
        return minDate.toISOString().split('T')[0];
    }

    getMaxBookingDate() {
        const maxDate = new Date();
        maxDate.setDate(maxDate.getDate() + this.config.general.maxBookingDays);
        return maxDate.toISOString().split('T')[0];
    }

    isDateBlocked(date) {
        const dateObj = new Date(date);
        const dayOfWeek = dateObj.getDay();

        // Check if day of week is blocked
        if (this.config.dateRestrictions.blockedDaysOfWeek.includes(dayOfWeek)) {
            return true;
        }

        // Check if date falls in any blocked range
        const dateStr = date;
        return this.config.dateRestrictions.blockedDateRanges.some(range => {
            return dateStr >= range.start && dateStr <= range.end;
        });
    }

    showStatus(message, type) {
        const statusDiv = document.getElementById('config-status');
        statusDiv.textContent = message;
        statusDiv.className = `status-message ${type}`;
        statusDiv.style.display = 'block';

        if (type === 'success') {
            setTimeout(() => {
                statusDiv.style.display = 'none';
            }, 3000);
        }
    }

    resetToDefaults() {
        if (confirm('Are you sure you want to reset all settings to defaults? This cannot be undone.')) {
            this.config = {
                general: {
                    advanceBookingDays: 7,
                    maxBookingDays: 365,
                    defaultMinParticipants: 5,
                    bookingConfirmationHours: 48
                },
                dateRestrictions: {
                    blockedDaysOfWeek: [],
                    blockedDateRanges: []
                },
                timeSlots: {
                    morning: [
                        { time: '09:00', label: '9:00 AM' },
                        { time: '10:00', label: '10:00 AM' },
                        { time: '11:00', label: '11:00 AM' }
                    ],
                    afternoon: [
                        { time: '14:00', label: '2:00 PM' },
                        { time: '15:00', label: '3:00 PM' },
                        { time: '16:00', label: '4:00 PM' }
                    ]
                },
                activitySpecific: {}
            };

            this.renderConfiguration();
            this.showStatus('Configuration reset to defaults', 'info');
        }
    }

    previewRestrictions() {
        // Show a preview of how the restrictions will appear to users
        const restrictions = this.getDateRestrictions();
        const preview = `
Date Restrictions Preview:
• Earliest booking date: ${restrictions.minDate}
• Latest booking date: ${restrictions.maxDate}
• Blocked days: ${restrictions.blockedDays.map(d => ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][d]).join(', ') || 'None'}
• Blocked date ranges: ${restrictions.blockedRanges.length} range(s)
• Available time slots: ${this.config.timeSlots.morning.length + this.config.timeSlots.afternoon.length} slots
        `;

        alert(preview);
    }
}

// Global functions for the HTML onclick handlers
function addBlockedDateRange() {
    const today = new Date();
    const nextWeek = new Date(today);
    nextWeek.setDate(today.getDate() + 7);

    window.bookingConfigManager.config.dateRestrictions.blockedDateRanges.push({
        start: today.toISOString().split('T')[0],
        end: nextWeek.toISOString().split('T')[0],
        reason: ''
    });

    window.bookingConfigManager.renderBlockedDateRanges();
}

function removeBlockedDateRange(index) {
    window.bookingConfigManager.config.dateRestrictions.blockedDateRanges.splice(index, 1);
    window.bookingConfigManager.renderBlockedDateRanges();
}

function updateBlockedDateRange(index, field, value) {
    if (window.bookingConfigManager.config.dateRestrictions.blockedDateRanges[index]) {
        window.bookingConfigManager.config.dateRestrictions.blockedDateRanges[index][field] = value;
    }
}

function addTimeSlot(period) {
    const defaultTime = period === 'morning' ? '09:00' : '14:00';
    const defaultLabel = period === 'morning' ? '9:00 AM' : '2:00 PM';

    window.bookingConfigManager.config.timeSlots[period].push({
        time: defaultTime,
        label: defaultLabel
    });

    window.bookingConfigManager.renderTimeSlots();
}

function removeTimeSlot(period, index) {
    window.bookingConfigManager.config.timeSlots[period].splice(index, 1);
    window.bookingConfigManager.renderTimeSlots();
}

function updateTimeSlot(period, index, field, value) {
    if (window.bookingConfigManager.config.timeSlots[period][index]) {
        window.bookingConfigManager.config.timeSlots[period][index][field] = value;
    }
}

function updateActivityConfig(activityId, field, value) {
    if (!window.bookingConfigManager.config.activitySpecific[activityId]) {
        window.bookingConfigManager.config.activitySpecific[activityId] = {};
    }

    // Convert string values to appropriate types
    if (field === 'enabled') {
        window.bookingConfigManager.config.activitySpecific[activityId][field] = value;
    } else if (['minParticipants', 'maxParticipants', 'durationMinutes'].includes(field)) {
        window.bookingConfigManager.config.activitySpecific[activityId][field] = parseInt(value);
    } else if (field === 'priceEuros') {
        window.bookingConfigManager.config.activitySpecific[activityId][field] = parseFloat(value);
    } else {
        window.bookingConfigManager.config.activitySpecific[activityId][field] = value;
    }
}

function saveBookingConfiguration() {
    window.bookingConfigManager.saveConfiguration();
}

function resetToDefaults() {
    window.bookingConfigManager.resetToDefaults();
}

function previewRestrictions() {
    window.bookingConfigManager.previewRestrictions();
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    if (window.supabaseClient && document.getElementById('admin-booking-config')) {
        window.bookingConfigManager = new BookingConfigManager();
    }
});

// Make the manager available globally for booking modal integration
window.getBookingRestrictions = function() {
    return window.bookingConfigManager ? window.bookingConfigManager.getDateRestrictions() : null;
};

window.isDateBlocked = function(date) {
    return window.bookingConfigManager ? window.bookingConfigManager.isDateBlocked(date) : false;
};