-- =============================================================================
-- DisasterLink — Seed Data
-- File: supabase/migrations/002_seed_data.sql
-- =============================================================================

-- Disaster Types
INSERT INTO disaster_type (type_name, description) VALUES
    ('Flood', 'Riverine and flash flooding caused by heavy monsoon rains'),
    ('Earthquake', 'Seismic events causing structural damage and casualties'),
    ('Drought', 'Prolonged water shortage affecting agriculture and livelihoods');

-- Disasters
INSERT INTO disaster (disaster_id, disaster_type_id, disaster_name, severity_level, declaration_date, projected_end_date, status, description) VALUES
    (1, 1, '2022 Pakistan Monsoon Floods', 'Critical', '2022-08-15', '2022-12-31', 'Closed', 'Catastrophic flooding across Sindh and Balochistan affecting 33 million people'),
    (2, 2, '2023 Balochistan Earthquake', 'High', '2023-08-17', NULL, 'Active', '6.3 magnitude earthquake in Jaffarabad district');

-- Reset sequence
SELECT setval('disaster_disaster_id_seq', 2);

-- Disaster Locations
INSERT INTO disaster_location (location_id, disaster_id, province, district, tehsil, affected_population, gps_latitude, gps_longitude, location_status) VALUES
    (1, 1, 'Sindh', 'Larkana', 'Larkana City', 450000, 27.5600, 68.2100, 'Cleared'),
    (2, 1, 'Sindh', 'Jacobabad', 'Jacobabad', 380000, 28.2800, 68.4400, 'Cleared'),
    (3, 1, 'Punjab', 'Rajanpur', 'Rajanpur', 220000, 29.1000, 70.3300, 'Cleared'),
    (4, 2, 'Balochistan', 'Jaffarabad', 'Usta Muhammad', 150000, 28.4200, 67.9500, 'Active');

SELECT setval('disaster_location_location_id_seq', 4);

-- Relief Camps
INSERT INTO relief_camp (camp_id, location_id, camp_name, capacity, is_active) VALUES
    (1, 1, 'Larkana Central Camp', 5000, false),
    (2, 4, 'Jaffarabad Emergency Camp', 3000, true);

SELECT setval('relief_camp_camp_id_seq', 2);

-- Organizations
INSERT INTO org_category (org_category_id, category_name, description) VALUES
    (1, 'National NGO', 'Pakistani non-governmental organization'),
    (2, 'International NGO', 'International non-governmental organization'),
    (3, 'Government Unit', 'Government agency or department'),
    (4, 'Welfare Trust', 'Community welfare organization');

SELECT setval('org_category_org_category_id_seq', 4);

INSERT INTO organization (org_id, org_category_id, org_name, registration_number, contact_email, contact_phone, approval_status, approval_date, government_tier, international_flag, registration_authority) VALUES
    (1, 1, 'Edhi Foundation', 'EDHI-001', 'contact@edhi.org', '+92-21-3456789', 'Approved', '2022-01-15', NULL, false, 'SECP'),
    (2, 2, 'Aga Khan Foundation', 'AKF-002', 'info@akdn.org', '+92-21-3567890', 'Approved', '2022-02-01', NULL, true, 'SECP'),
    (3, 3, 'NDMA', 'NDMA-GOV', 'info@ndma.gov.pk', '+92-51-9100123', 'Approved', '2020-01-01', 'Federal', NULL, NULL),
    (4, 1, 'Al-Khidmat Foundation', 'AKF-004', 'info@alkhidmat.org', '+92-42-3567891', 'Approved', '2022-03-10', NULL, false, 'SECP'),
    (5, 4, 'Saylani Welfare Trust', 'SWT-005', 'info@saylani.org', '+92-21-3456790', 'Approved', '2022-04-01', NULL, false, 'SECP');

SELECT setval('organization_org_id_seq', 5);

-- Relief Programs
INSERT INTO relief_program (program_id, disaster_id, program_name, objectives, start_date, end_date, status, created_by_admin_id) VALUES
    (1, 1, 'Sindh Flood Relief 2022', 'Coordinate flood relief operations across Sindh province', '2022-08-20', '2022-12-31', 'Closed', 3),
    (2, 2, 'Balochistan Earthquake Response', 'Emergency response and rehabilitation for earthquake-affected areas', '2023-08-18', NULL, 'Active', 3);

SELECT setval('relief_program_program_id_seq', 2);

-- Products
INSERT INTO product (product_id, product_name, category, unit_of_measure, description) VALUES
    (1, 'Food Pack', 'Food', 'units', 'Family-sized food pack for 7 days'),
    (2, 'ORS Kit', 'Medicine', 'units', 'Oral rehydration solution kit for 10 patients'),
    (3, 'Tarpaulin', 'Shelter', 'units', 'Heavy-duty waterproof tarpaulin 20x30ft'),
    (4, 'Water Purification Tablet', 'Water', 'units', 'Pack of 100 tablets, treats 1000 litres'),
    (5, 'Blanket', 'Shelter', 'units', 'Thermal blanket'),
    (6, 'Medical Kit', 'Medicine', 'units', 'Basic first aid and trauma kit'),
    (7, 'Rice Bag', 'Food', 'kg', '25kg rice bag'),
    (8, 'Cooking Oil', 'Food', 'litres', '5-litre cooking oil tin');

SELECT setval('product_product_id_seq', 8);

-- Resource Requirements
INSERT INTO resource_requirement (requirement_id, program_id, location_id, product_id, quantity_required, quantity_committed, quantity_fulfilled, fulfillment_status, priority) VALUES
    (1, 1, 1, 1, 5000, 5000, 5000, 'Fulfilled', 'Critical'),
    (2, 1, 1, 3, 3000, 3000, 2800, 'Partial', 'Critical'),
    (3, 1, 2, 2, 1000, 800, 600, 'Partial', 'Critical'),
    (4, 1, 2, 4, 2000, 1500, 1500, 'Partial', 'High'),
    (5, 1, 3, 7, 10000, 8000, 8000, 'Partial', 'High'),
    (6, 2, 4, 1, 2000, 1200, 800, 'Partial', 'Critical'),
    (7, 2, 4, 5, 3000, 2000, 1500, 'Partial', 'High'),
    (8, 2, 4, 6, 500, 300, 100, 'Partial', 'Critical');

SELECT setval('resource_requirement_requirement_id_seq', 8);

-- Program Enrollments
INSERT INTO program_enrollment (program_id, org_id, enrolled_date, enrollment_status) VALUES
    (1, 1, '2022-08-21', 'Active'),
    (1, 2, '2022-08-22', 'Active'),
    (1, 4, '2022-08-25', 'Active'),
    (1, 5, '2022-09-01', 'Active'),
    (2, 1, '2023-08-19', 'Active'),
    (2, 3, '2023-08-19', 'Active'),
    (2, 4, '2023-08-20', 'Active');

-- Field Teams
INSERT INTO field_team (team_id, org_id, location_id, team_name, team_leader_name, headcount, deployment_date, status) VALUES
    (1, 1, 1, 'Edhi Larkana Alpha', 'Ahmed Khan', 25, '2022-08-22', 'Active'),
    (2, 2, 2, 'AKF Jacobabad Team', 'Dr. Fatima Ali', 18, '2022-08-25', 'Active'),
    (3, 4, 3, 'Rajanpur Relief Team', 'Hassan Raza', 30, '2022-09-01', 'Active'),
    (4, 3, 4, 'Jaffarabad Ops', 'Brig. Mahmood (R)', 40, '2023-08-18', 'Active');

SELECT setval('field_team_team_id_seq', 4);

-- Incident Reports
INSERT INTO incident_report (report_id, team_id, location_id, report_title, report_body, report_date, severity_flag, submitted_by) VALUES
    (1, 1, 1, 'Critical shelter shortage in Larkana', 'Over 12,000 families sleeping in open fields. No tarpaulins available. Children and elderly at high risk. Urgent shelter deployment needed in northern sectors.', '2022-09-08', 'Critical', 'Ahmed Khan'),
    (2, 2, 2, 'Medical emergency Jacobabad camp', 'Acute watery diarrhea outbreak detected. 340 cases in 48 hours. Medical team overwhelmed. Requesting ORS and IV fluids immediately. Cholera risk is high.', '2022-09-10', 'Critical', 'Dr. Fatima Ali'),
    (3, 2, 2, 'Water contamination Sukkur', 'Standing floodwater contaminating drinking sources. No purification tablets distributed yet to Rohri tehsil. Cholera risk elevated. Need water purification tablets urgently.', '2022-09-12', 'Warning', 'Dr. Fatima Ali'),
    (4, 1, 1, 'Food distribution progress Larkana', '1800 food packs distributed today. 3200 families remain unserved in camp perimeter. Coordination with PRCS improved. Need more rice and cooking oil supplies.', '2022-09-15', 'Info', 'Ahmed Khan'),
    (5, 3, 3, 'Road access restored Rajanpur', 'Highway N-55 now accessible to trucks. Can reach eastern villages. Requesting logistics coordination for aid convoy tomorrow morning. Fuel supplies needed.', '2022-09-18', 'Info', 'Hassan Raza'),
    (6, 2, 2, 'Malnutrition screening Jacobabad', 'MUAC screening of 500 children under 5 completed. 47 cases of acute malnutrition identified. Therapeutic food required urgently. Families unaware of nutrition programs.', '2022-09-25', 'Warning', 'Dr. Fatima Ali'),
    (7, 4, 4, 'Balochistan flash flood update', 'Rapidly rising water levels in Usta Muhammad. 6 villages unreachable by road. Helicopter deployment requested for rescue operations. 200 families stranded.', '2023-08-17', 'Critical', 'Brig. Mahmood'),
    (8, 3, 3, 'DG Khan situation update', 'Food distribution complete for all registered families. 400 new arrivals from Taunsa requiring registration. Medical supplies running low. Blankets needed for night temperatures.', '2022-09-20', 'Info', 'Hassan Raza');

SELECT setval('incident_report_report_id_seq', 8);

-- Beneficiaries
INSERT INTO beneficiary (beneficiary_id, location_id, cnic_or_id, full_name, contact_number, family_size, address_province, address_district, address_street, registration_date, displacement_status) VALUES
    (1, 1, '42101-1234567-1', 'Ghulam Rasool', '+92-300-1234567', 8, 'Sindh', 'Larkana', 'Village Dero Jamali', '2022-09-01', 'Displaced'),
    (2, 2, '42201-2345678-2', 'Shabana Bibi', '+92-301-2345678', 6, 'Sindh', 'Jacobabad', 'Camp Block C, Tent 42', '2022-09-05', 'Displaced'),
    (3, 3, '31101-3456789-3', 'Muhammad Bux', '+92-302-3456789', 10, 'Punjab', 'Rajanpur', 'Mohalla Darbar Sharif', '2022-09-10', 'In-Place'),
    (4, 4, '61101-4567890-4', 'Zarina Baloch', '+92-303-4567890', 5, 'Balochistan', 'Jaffarabad', 'Village Usta Muhammad', '2023-08-18', 'Displaced');

SELECT setval('beneficiary_beneficiary_id_seq', 4);

-- Aid Distribution
INSERT INTO aid_distribution (distribution_id, beneficiary_id, product_id, program_id, org_id, team_id, quantity_distributed, distribution_date, notes) VALUES
    (1, 1, 1, 1, 1, 1, 2, '2022-09-10', 'Two food packs for family of 8'),
    (2, 1, 3, 1, 1, 1, 1, '2022-09-12', 'One tarpaulin for temporary shelter'),
    (3, 2, 2, 1, 2, 2, 3, '2022-09-15', 'ORS kits for family with diarrhea cases'),
    (4, 4, 1, 2, 3, 4, 1, '2023-08-20', 'Emergency food pack post-earthquake');

SELECT setval('aid_distribution_distribution_id_seq', 4);

-- Commitments
INSERT INTO commitment (commitment_id, requirement_id, org_id, quantity_committed, commitment_date, commitment_status, notes) VALUES
    (1, 6, 1, 1200, '2023-08-19', 'Active', 'Edhi committing food packs for Jaffarabad'),
    (2, 7, 4, 2000, '2023-08-20', 'Active', 'Al-Khidmat committing blankets');

SELECT setval('commitment_commitment_id_seq', 2);

-- Fulfillments (these fire Trigger T1)
INSERT INTO fulfillment (fulfillment_id, commitment_id, quantity_fulfilled, fulfillment_date, delivery_method, verified_by_admin_id) VALUES
    (1, 1, 800, '2023-08-22', 'Camp', 3),
    (2, 2, 1500, '2023-08-25', 'Direct', 3);

SELECT setval('fulfillment_fulfillment_id_seq', 2);

-- =============================================================================
-- SEED COMPLETE
-- =============================================================================
