-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    employee_id TEXT UNIQUE NOT NULL,
    hospital_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Settings table
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    push_notifications TEXT CHECK (push_notifications IN ('enabled', 'disabled')) DEFAULT 'enabled',
    in_app_reminders TEXT CHECK (in_app_reminders IN ('enabled', 'disabled')) DEFAULT 'enabled',
    resource_age_grp TEXT CHECK (resource_age_grp IN ('Infants', 'Toddlers', 'Adolescents')),
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Patient Records
CREATE TABLE patient_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID UNIQUE DEFAULT uuid_generate_v4(),
    doc_id UUID NOT NULL REFERENCES users(id),
    name TEXT NOT NULL,
    dob DATE NOT NULL,
    gender TEXT CHECK (gender IN ('M', 'F')),
    emergency_contact_number TEXT,
    guardian_name TEXT,
    guardian_num TEXT,
    last_time_immunized DATE,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Vaccines
CREATE TABLE vaccines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vaccine_name TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Immunizations
CREATE TABLE immunizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patient_records(id),
    vaccine_id UUID NOT NULL REFERENCES vaccines(id),
    date_due_taken DATE NOT NULL,
    num_doses INTEGER NOT NULL,
    immunization_status TEXT CHECK (immunization_status IN ('Immunized', 'Pending', 'Overdue')),
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Vaccine Information
CREATE TABLE vaccine_information (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vaccine_id UUID NOT NULL REFERENCES vaccines(id) ON DELETE CASCADE,
    diseases_tackled TEXT NOT NULL,
    dosage_schedule JSONB NOT NULL,
    side_effects TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    patient_id UUID NOT NULL REFERENCES patient_records(id),
    immunization_id UUID NOT NULL REFERENCES immunizations(id),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_patient_records_doc_id ON patient_records(doc_id);
CREATE INDEX idx_immunizations_patient_id ON immunizations(patient_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);

-- Update timestamps trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update timestamp triggers to all tables
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY users_policy ON users
    FOR ALL USING (auth.uid() = id);

-- Doctors can only see their patients
CREATE POLICY patient_records_policy ON patient_records
    FOR ALL USING (auth.uid() = doc_id);

-- Users can only see their own notifications
CREATE POLICY notifications_policy ON notifications
    FOR ALL USING (auth.uid() = user_id);
