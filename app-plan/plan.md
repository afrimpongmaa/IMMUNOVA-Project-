# Rough DB plan

The app is offline-first, which will require an offline noSQL database. Since it will be updated online, we need to use a relational schema that represents the online db (preferrably Postgres with Supabase)

## Tables

### Users

id references auth.users.id ON CASCADE DELETE

id UUID
full_name 
phone_number
employee_id 
hospital_name




### User settings

user_id REFERENCES users.id ON CASCADE DELETE
push_notifications CHECK IN ("enabled","disabled")
in_app_reminders CHECK IN ("enabled","disabled")
resource_age_grp CHECK IN ("Infants", "Toddlers", "Adoscelents")








### Patient Records

patient_id UUID PK
doc_id references users.id -- Keep track of the what doctor attends to this patient
name - Patient name
dob - Date of Birth
Gender - check in ("M", "F")
Emergency contact number NULL
guardian_name 
guardian_num 
last_time_immunized 


### Vaccines
id UUID
vaccine_name 

### Immunization

id UUID PK
patient_id  REFERENCES patient_records.patient_id
vaccine_id REFERENCES vaccines.id
date_due_taken 
num_doses INT4
immunization_status CHECK IN ("Immunized", "Pending", "Overdue")




# Vaccine Information

vaccine_id REFERENCES vaccines.id ON CASCADE DELETE
diseases_tackled TEXT NOT NULL
dosage_schedule TEXT (/JSONB) NOT NULL
side_effects TEXT NOT NULL





## NOTIFICATIONS

id references users.id -- for a particular doctor
patient_id references patient_records.id
immunization_id REFERENCES immunization.id




