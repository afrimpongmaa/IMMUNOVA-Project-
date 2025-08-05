PRAGMA foreign_keys = ON;

-- Users table
CREATE TABLE users (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE,
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    employee_id TEXT UNIQUE NOT NULL,
    hospital_name TEXT NOT NULL,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT CHECK (sync_status IN ('pending', 'synced', 'conflict')) DEFAULT 'pending'
);

CREATE INDEX idx_users_remote_id ON users(remote_id);

-- Settings table
CREATE TABLE user_settings (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE,
    user_id INTEGER NOT NULL,
    push_notifications TEXT CHECK (push_notifications IN ('enabled', 'disabled')) DEFAULT 'enabled',
    in_app_reminders TEXT CHECK (in_app_reminders IN ('enabled', 'disabled')) DEFAULT 'enabled',
    resource_age_grp TEXT CHECK (resource_age_grp IN ('Infants', 'Toddlers', 'Adolescents')),
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT CHECK (sync_status IN ('pending', 'synced', 'conflict')) DEFAULT 'pending',
    FOREIGN KEY (user_id) REFERENCES users(local_id) ON DELETE CASCADE
);

-- Patient Records
CREATE TABLE patient_records (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE,
    patient_id TEXT UNIQUE,
    doc_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    dob DATE NOT NULL,
    gender TEXT CHECK (gender IN ('M', 'F')),
    emergency_contact_number TEXT,
    guardian_name TEXT,
    guardian_num TEXT,
    last_time_immunized DATE,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT CHECK (sync_status IN ('pending', 'synced', 'conflict')) DEFAULT 'pending',
    FOREIGN KEY (doc_id) REFERENCES users(local_id)
);

-- Vaccines
CREATE TABLE vaccines (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE,
    vaccine_name TEXT NOT NULL,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT CHECK (sync_status IN ('pending', 'synced', 'conflict')) DEFAULT 'pending'
);

-- Immunizations
CREATE TABLE immunizations (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE,
    patient_id INTEGER NOT NULL,
    vaccine_id INTEGER NOT NULL,
    date_due_taken DATE NOT NULL,
    num_doses INTEGER NOT NULL,
    immunization_status TEXT CHECK (immunization_status IN ('Immunized', 'Pending', 'Overdue')),
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT CHECK (sync_status IN ('pending', 'synced', 'conflict')) DEFAULT 'pending',
    FOREIGN KEY (patient_id) REFERENCES patient_records(local_id),
    FOREIGN KEY (vaccine_id) REFERENCES vaccines(local_id)
);

-- Vaccine Information
CREATE TABLE vaccine_information (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE,
    vaccine_id INTEGER NOT NULL,
    diseases_tackled TEXT NOT NULL,
    dosage_schedule TEXT NOT NULL,
    side_effects TEXT NOT NULL,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT CHECK (sync_status IN ('pending', 'synced', 'conflict')) DEFAULT 'pending',
    FOREIGN KEY (vaccine_id) REFERENCES vaccines(local_id) ON DELETE CASCADE
);

-- Notifications
CREATE TABLE notifications (
    local_id INTEGER PRIMARY KEY AUTOINCREMENT,
    remote_id TEXT UNIQUE,
    user_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    immunization_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    is_read INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT CHECK (sync_status IN ('pending', 'synced', 'conflict')) DEFAULT 'pending',
    FOREIGN KEY (user_id) REFERENCES users(local_id),
    FOREIGN KEY (patient_id) REFERENCES patient_records(local_id),
    FOREIGN KEY (immunization_id) REFERENCES immunizations(local_id)
);

-- Sync Queue table for offline changes
CREATE TABLE sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    record_id INTEGER NOT NULL,
    operation TEXT CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed INTEGER DEFAULT 0
);
