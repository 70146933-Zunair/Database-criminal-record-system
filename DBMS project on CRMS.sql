 -- ═══════════════════════════════════════════════════════════════════
-- CRIMINAL RECORD MANAGEMENT SYSTEM (CRMS)
-- PostgreSQL — pgAdmin Compatible
-- ═══════════════════════════════════════════════════════════════════
 

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 1: POLICE_OFFICER
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE police_officer (
    officer_id      SERIAL          NOT NULL,
    badge_number    VARCHAR(20)     NOT NULL,
    full_name       VARCHAR(100)    NOT NULL,
    officer_rank    VARCHAR(50)     NOT NULL,
    department      VARCHAR(100)    NOT NULL,
    station_name    VARCHAR(100)    NOT NULL,
    phone           VARCHAR(20)     NOT NULL,
    email           VARCHAR(100),
    date_joined     DATE            NOT NULL,
    status          VARCHAR(10)     NOT NULL DEFAULT 'active',
    PRIMARY KEY (officer_id),
    UNIQUE (badge_number),
    UNIQUE (email),
    CONSTRAINT chk_officer_status CHECK (status IN ('active','retired'))
);

-- ─── TABLE 2: COMPLAINANT ────────────────────────────────────────
CREATE TABLE complainant (
    complainant_id     SERIAL          NOT NULL,
    full_name          VARCHAR(100)    NOT NULL,
    cnic               CHAR(15)        NOT NULL,
    gender             VARCHAR(10)     NOT NULL,
    dob                DATE,
    phone              VARCHAR(20)     NOT NULL,
    email              VARCHAR(100),
    address            TEXT,
    relation_to_victim VARCHAR(100),
    statement          TEXT,
    date_reported      DATE            NOT NULL,
    PRIMARY KEY (complainant_id),
    UNIQUE (cnic),
    CONSTRAINT chk_complainant_gender CHECK (gender IN ('Male','Female','Other')),
    CONSTRAINT chk_cnic_format        CHECK (LENGTH(cnic) = 15)
);

-- ─── TABLE 3: FIR ────────────────────────────────────────────────
CREATE TABLE fir (
    fir_id               SERIAL          NOT NULL,
    fir_number           VARCHAR(30)     NOT NULL,
    date_filed           DATE            NOT NULL,
    time_filed           TIME            NOT NULL,
    location_of_incident VARCHAR(200)    NOT NULL,
    description          TEXT            NOT NULL,
    fir_status           VARCHAR(25)     NOT NULL DEFAULT 'open',
    police_officer_id    INT             NOT NULL,
    complainant_id       INT             NOT NULL,
    created_at           TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fir_id),
    UNIQUE (fir_number),
    CONSTRAINT chk_fir_status CHECK (fir_status IN ('open','closed','under_investigation')),
    CONSTRAINT fk_fir_officer
        FOREIGN KEY (police_officer_id) REFERENCES police_officer(officer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_fir_complainant
        FOREIGN KEY (complainant_id) REFERENCES complainant(complainant_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ─── TABLE 4: CRM_CASE (renamed from `case` — reserved word) ─────
CREATE TABLE crm_case (
    case_id                  SERIAL          NOT NULL,
    case_number              VARCHAR(30)     NOT NULL,
    case_title               VARCHAR(200)    NOT NULL,
    case_type                VARCHAR(20)     NOT NULL,
    date_opened              DATE            NOT NULL,
    date_closed              DATE,
    case_status              VARCHAR(15)     NOT NULL DEFAULT 'ongoing',
    court_name               VARCHAR(150)    NOT NULL,
    judge_name               VARCHAR(100),
    verdict                  VARCHAR(100),
    fir_id                   INT             NOT NULL,
    investigating_officer_id INT             NOT NULL,
    PRIMARY KEY (case_id),
    UNIQUE (case_number),
    UNIQUE (fir_id),
    CONSTRAINT chk_case_type   CHECK (case_type   IN ('criminal','civil','cyber','fraud','terrorism','drug','homicide','theft')),
    CONSTRAINT chk_case_status CHECK (case_status IN ('ongoing','closed','appealed','dismissed')),
    CONSTRAINT fk_case_fir
        FOREIGN KEY (fir_id) REFERENCES fir(fir_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_case_officer
        FOREIGN KEY (investigating_officer_id) REFERENCES police_officer(officer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ─── TABLE 5: CRIMINAL ───────────────────────────────────────────
CREATE TABLE criminal (
    criminal_id   SERIAL          NOT NULL,
    full_name     VARCHAR(100)    NOT NULL,
    dob           DATE            NOT NULL,
    gender        VARCHAR(10)     NOT NULL,
    nationality   VARCHAR(50)     NOT NULL DEFAULT 'Pakistani',
    cnic          CHAR(15)        NOT NULL,
    address       TEXT,
    phone         VARCHAR(20),
    criminal_type VARCHAR(100)    NOT NULL,
    status        VARCHAR(15)     NOT NULL DEFAULT 'active',
    photo_url     VARCHAR(255),
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (criminal_id),
    UNIQUE (cnic),
    CONSTRAINT chk_criminal_gender CHECK (gender IN ('Male','Female','Other')),
    CONSTRAINT chk_criminal_status CHECK (status IN ('active','imprisoned','released'))
);

-- ─── TABLE 6: CRIMINAL_FIR (Bridge Table) ────────────────────────
CREATE TABLE criminal_fir (
    criminal_fir_id SERIAL          NOT NULL,
    criminal_id     INT             NOT NULL,
    fir_id          INT             NOT NULL,
    role_in_crime   VARCHAR(15)     NOT NULL,
    date_linked     DATE            NOT NULL,
    remarks         TEXT,
    PRIMARY KEY (criminal_fir_id),
    UNIQUE (criminal_id, fir_id),
    CONSTRAINT chk_role_in_crime CHECK (role_in_crime IN ('suspect','accused','convicted','witness')),
    CONSTRAINT fk_cf_criminal
        FOREIGN KEY (criminal_id) REFERENCES criminal(criminal_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cf_fir
        FOREIGN KEY (fir_id) REFERENCES fir(fir_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ─── TABLE 7: EVIDENCE ───────────────────────────────────────────
CREATE TABLE evidence (
    evidence_id      SERIAL          NOT NULL,
    evidence_type    VARCHAR(15)     NOT NULL,
    description      TEXT            NOT NULL,
    collection_date  DATE            NOT NULL,
    collected_by     INT             NOT NULL,
    storage_location VARCHAR(200)    NOT NULL,
    status           VARCHAR(15)     NOT NULL DEFAULT 'collected',
    case_id          INT             NOT NULL,
    fir_id           INT,
    photo_url        VARCHAR(255),
    PRIMARY KEY (evidence_id),
    CONSTRAINT chk_evidence_type   CHECK (evidence_type IN ('weapon','document','digital','physical')),
    CONSTRAINT chk_evidence_status CHECK (status        IN ('collected','submitted','destroyed')),
    CONSTRAINT fk_ev_officer
        FOREIGN KEY (collected_by) REFERENCES police_officer(officer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ev_case
        FOREIGN KEY (case_id) REFERENCES crm_case(case_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ev_fir
        FOREIGN KEY (fir_id) REFERENCES fir(fir_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- ═══════════════════════════════════════════════════════════════════
-- EER SUBTYPE TABLES
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE repeat_offender (
    criminal_id          INT         NOT NULL,
    previous_cases_count INT         NOT NULL DEFAULT 0,
    threat_level         VARCHAR(10) NOT NULL DEFAULT 'medium',
    last_offense_date    DATE,
    PRIMARY KEY (criminal_id),
    CONSTRAINT chk_threat_level CHECK (threat_level IN ('low','medium','high','critical')),
    CONSTRAINT fk_ro_criminal
        FOREIGN KEY (criminal_id) REFERENCES criminal(criminal_id)
        ON DELETE CASCADE
);

CREATE TABLE first_time_offender (
    criminal_id             INT          NOT NULL,
    rehabilitation_eligible BOOLEAN      NOT NULL DEFAULT TRUE,
    counselor_assigned      VARCHAR(100),
    first_offense_date      DATE,
    PRIMARY KEY (criminal_id),
    CONSTRAINT fk_fto_criminal
        FOREIGN KEY (criminal_id) REFERENCES criminal(criminal_id)
        ON DELETE CASCADE
);

-- ═══════════════════════════════════════════════════════════════════
-- SAMPLE DATA
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO police_officer (badge_number, full_name, officer_rank, department, station_name, phone, email, date_joined, status) VALUES
('PNP-2201', 'Azhar Mahmood Khan',     'DSP',       'CID Lahore',         'Shadman Police Station', '0300-1234567', 'azhar.khan@punjabpolice.gov.pk',      '2010-03-15', 'active'),
('PNP-2202', 'Sikandar Ali Bhatti',    'Inspector', 'Investigation Wing', 'Model Town Station',     '0321-7654321', 'sikandar.bhatti@punjabpolice.gov.pk', '2014-08-01', 'active'),
('PNP-2203', 'Muhammad Tahir Raza',    'SI',        'Cyber Crime Unit',   'FIA Islamabad',          '0333-9988776', 'tahir.raza@fia.gov.pk',               '2018-01-10', 'active'),
('PNP-2204', 'Rukhsana Perveen',       'ASI',       'Women Police Unit',  'Garden Town Station',    '0311-4455667', 'rukhsana.perveen@punjabpolice.gov.pk','2016-06-20', 'active'),
('PNP-2205', 'Ghulam Mustafa Qureshi', 'Constable', 'Patrol Unit',        'Cantt Police Station',   '0345-3322110', 'mustafa.qureshi@punjabpolice.gov.pk', '2020-11-05', 'active');

INSERT INTO complainant (full_name, cnic, gender, dob, phone, email, address, relation_to_victim, statement, date_reported) VALUES
('Fatima Zahra Siddiqui', '35202-1234567-8', 'Female', '1985-04-12', '0300-9988123', 'fatima.siddiqui@gmail.com',  'House 22, Block C, Gulberg III, Lahore', 'Self',     'I was robbed at gunpoint outside my workplace on the evening of 5th March 2024.', '2024-03-06'),
('Tariq Mehmood Ansari',  '42201-9876543-2', 'Male',   '1970-11-23', '0321-7712345', 'tariq.ansari@yahoo.com',     'Flat 5, Clifton Block 4, Karachi',       'Brother',  'My brother was assaulted by three unknown individuals near Karachi University.',  '2024-04-10'),
('Nadia Iqbal Chaudhry',  '37405-6543210-9', 'Female', '1990-07-30', '0333-6611223', 'nadia.chaudhry@hotmail.com', 'Street 7, F-8/3, Islamabad',             'Self',     'I received repeated online threats and my personal data was leaked.',            '2024-05-15'),
('Zafar Ullah Mirza',     '35301-5566778-1', 'Male',   '1955-02-14', '0311-8877665', NULL,                         'Village Mirza, Gujranwala',              'Neighbor', 'My neighbor was found dead under suspicious circumstances.',                     '2024-06-01'),
('Hina Bashir Chishti',   '36302-4433221-5', 'Female', '2000-09-05', '0345-9900112', 'hina.chishti@gmail.com',     'Plot 44, DHA Phase 5, Lahore',           'Self',     'My car was stolen from outside DHA Lahore shopping center.',                    '2024-06-20');

INSERT INTO fir (fir_number, date_filed, time_filed, location_of_incident, description, fir_status, police_officer_id, complainant_id) VALUES
('FIR/LHR/2024/001', '2024-03-06', '09:30:00', 'Main Boulevard, Gulberg III, Lahore', 'Armed robbery at gunpoint. Victim robbed of mobile phone and cash Rs. 45,000 near office premises.', 'under_investigation', 1, 1),
('FIR/KHI/2024/002', '2024-04-10', '14:45:00', 'University Road, Karachi',             'Gang assault causing grievous bodily harm. Victim admitted to Jinnah Hospital with fractures.',       'open',               2, 2),
('FIR/ISB/2024/003', '2024-05-15', '11:00:00', 'Online - IP traced to Rawalpindi',     'Cyber harassment, data breach, and online threats via social media platforms.',                       'under_investigation', 3, 3),
('FIR/GUJ/2024/004', '2024-06-01', '07:15:00', 'Village Mirza, District Gujranwala',   'Suspected homicide. Body of Muhammad Arif found with blunt force trauma injuries.',                  'open',               1, 4),
('FIR/LHR/2024/005', '2024-06-20', '16:00:00', 'DHA Phase 5, Lahore',                  'Motor vehicle theft. Toyota Corolla (LEA-1234) stolen from commercial area parking.',                'open',               2, 5);

INSERT INTO crm_case (case_number, case_title, case_type, date_opened, date_closed, case_status, court_name, judge_name, verdict, fir_id, investigating_officer_id) VALUES
('CASE/LHR/2024/0301', 'State vs Imran Baig - Armed Robbery',    'criminal', '2024-03-10', NULL,         'ongoing', 'Sessions Court Lahore',              'Justice Arshad Noor Khan', NULL,        1, 1),
('CASE/KHI/2024/0402', 'State vs Unknown - Gang Assault KHI',    'criminal', '2024-04-15', NULL,         'ongoing', 'Anti-Terrorism Court Karachi',       'Justice Fareeda Hanif',    NULL,        2, 2),
('CASE/ISB/2024/0503', 'State vs Hassan Zafar - Cyber Crime',    'cyber',    '2024-05-20', '2024-11-30', 'closed',  'FIA Cyber Crime Court Islamabad',    'Justice Rana Bashir',      'Convicted', 3, 3),
('CASE/GUJ/2024/0601', 'State vs Accused - Homicide Gujranwala', 'homicide', '2024-06-05', NULL,         'ongoing', 'High Court Lahore Bench Gujranwala', 'Justice Ijaz Ahmad',       NULL,        4, 1),
('CASE/LHR/2024/0621', 'State vs Vehicle Theft Ring LHR',        'theft',    '2024-06-25', '2024-12-15', 'closed',  'Sessions Court Lahore',              'Justice Asim Iqbal',       'Convicted', 5, 2);

INSERT INTO criminal (full_name, dob, gender, nationality, cnic, address, phone, criminal_type, status, photo_url) VALUES
('Imran Baig Lodhi',     '1995-08-15', 'Male', 'Pakistani', '35202-9988776-3', 'Chah Miran, Lahore',     '0300-1122334', 'Robbery',       'imprisoned', '/photos/c001.jpg'),
('Adnan Khalil Butt',    '1988-03-22', 'Male', 'Pakistani', '42201-5544332-1', 'Orangi Town, Karachi',   '0321-5566778', 'Assault',       'active',     '/photos/c002.jpg'),
('Hassan Zafar Rana',    '1992-11-09', 'Male', 'Pakistani', '37405-7766554-9', 'I-10/2, Islamabad',      '0333-8899001', 'Cyber Crime',   'released',   '/photos/c003.jpg'),
('Shahrukh Akbar Malik', '1980-06-30', 'Male', 'Pakistani', '35301-2233445-6', 'GT Road, Gujranwala',    '0311-3344556', 'Homicide',      'active',     '/photos/c004.jpg'),
('Bilal Hussain Gondal', '1997-01-18', 'Male', 'Pakistani', '36302-6677889-2', 'Model Colony, Lahore',   '0345-7788990', 'Vehicle Theft', 'imprisoned', '/photos/c005.jpg');

INSERT INTO criminal_fir (criminal_id, fir_id, role_in_crime, date_linked, remarks) VALUES
(1, 1, 'accused',   '2024-03-08', 'Eyewitness identified suspect at scene. CCTV footage reviewed.'),
(2, 2, 'suspect',   '2024-04-12', 'Fingerprints matched. Currently at large.'),
(3, 3, 'convicted', '2024-05-22', 'Laptop seized, IP logs confirmed. Digital forensics report filed.'),
(4, 4, 'suspect',   '2024-06-05', 'Motive under investigation. Last seen near scene.'),
(5, 5, 'convicted', '2024-06-27', 'Vehicle found in possession. Accomplices under investigation.'),
(1, 5, 'suspect',   '2024-06-28', 'Linked to vehicle theft ring through phone records.');

INSERT INTO evidence (evidence_type, description, collection_date, collected_by, storage_location, status, case_id, fir_id, photo_url) VALUES
('weapon',   'Country-made pistol (.30 bore) recovered near crime scene, serial no. scratched off.',  '2024-03-07', 1, 'Shadman PS Evidence Room - Locker A12', 'submitted', 1, 1, '/ev/e001.jpg'),
('physical', 'Victim bloodied clothing and broken wristwatch collected from Jinnah Hospital.',        '2024-04-11', 2, 'Karachi CID Store - Room 3',            'collected', 2, 2, '/ev/e002.jpg'),
('digital',  'Dell laptop, 2x USB drives, SIM card seized from suspects flat in I-10.',              '2024-05-21', 3, 'FIA Cyber Forensics Lab - Server Room',  'submitted', 3, 3, '/ev/e003.jpg'),
('document', 'Autopsy report and post-mortem photographs from CMH Gujranwala.',                      '2024-06-03', 1, 'GUJ Sessions Court Document Room',       'submitted', 4, 4, '/ev/e004.jpg'),
('physical', 'Recovered stolen Toyota Corolla (LEA-1234) from Raiwind industrial area.',             '2024-06-26', 2, 'DHA PS Vehicle Pound',                   'collected', 5, 5, '/ev/e005.jpg');

INSERT INTO repeat_offender (criminal_id, previous_cases_count, threat_level, last_offense_date) VALUES
(1, 3, 'high',   '2024-03-06'),
(2, 2, 'medium', '2024-04-10');

INSERT INTO first_time_offender (criminal_id, rehabilitation_eligible, counselor_assigned, first_offense_date) VALUES
(3, TRUE,  'Dr. Samina Asif (Psychiatrist)', '2024-05-15'),
(4, FALSE, NULL,                             '2024-06-01'),
(5, TRUE,  'Mr. Bilal Tahir (Counselor)',    '2024-06-20');


-- ═══════════════════════════════════════════════════════════════════
-- QUERY 1: All criminals with their FIRs and roles
-- ═══════════════════════════════════════════════════════════════════
SELECT
    c.criminal_id,
    c.full_name          AS criminal_name,
    c.criminal_type,
    c.status             AS criminal_status,
    f.fir_number,
    f.date_filed,
    cf.role_in_crime,
    cf.remarks
FROM criminal c
JOIN criminal_fir cf ON c.criminal_id = cf.criminal_id
JOIN fir f           ON cf.fir_id     = f.fir_id
ORDER BY c.full_name;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 2: Ongoing cases with investigating officer
-- ═══════════════════════════════════════════════════════════════════
SELECT
    ca.case_number,
    ca.case_title,
    ca.case_type,
    ca.court_name,
    ca.date_opened,
    po.full_name         AS officer_name,
    po.badge_number,
    po.station_name
FROM crm_case ca
JOIN police_officer po ON ca.investigating_officer_id = po.officer_id
WHERE ca.case_status = 'ongoing'
ORDER BY ca.date_opened DESC;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 3: FIR count per officer
-- ═══════════════════════════════════════════════════════════════════
SELECT
    po.officer_id,
    po.full_name         AS officer_name,
    po.badge_number,
    po.officer_rank,
    po.station_name,
    COUNT(f.fir_id)      AS total_firs_filed
FROM police_officer po
LEFT JOIN fir f ON po.officer_id = f.police_officer_id
GROUP BY po.officer_id, po.full_name, po.badge_number,
         po.officer_rank, po.station_name
ORDER BY total_firs_filed DESC;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 4: Evidence for a specific case
-- ═══════════════════════════════════════════════════════════════════
SELECT
    e.evidence_id,
    e.evidence_type,
    e.description,
    e.collection_date,
    e.storage_location,
    e.status             AS evidence_status,
    po.full_name         AS collected_by,
    ca.case_number,
    ca.case_title
FROM evidence e
JOIN crm_case       ca ON e.case_id      = ca.case_id
JOIN police_officer po ON e.collected_by = po.officer_id
WHERE ca.case_number = 'CASE/ISB/2024/0503'
ORDER BY e.collection_date;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 5: Criminals linked to more than one FIR
-- NOTE: GROUP_CONCAT (MySQL) replaced with STRING_AGG (PostgreSQL)
-- ═══════════════════════════════════════════════════════════════════
SELECT
    c.criminal_id,
    c.full_name          AS criminal_name,
    c.criminal_type,
    c.status,
    COUNT(cf.fir_id)     AS fir_count,
    STRING_AGG(f.fir_number, ', ' ORDER BY f.date_filed) AS fir_numbers
FROM criminal c
JOIN criminal_fir cf ON c.criminal_id = cf.criminal_id
JOIN fir f           ON cf.fir_id     = f.fir_id
GROUP BY c.criminal_id, c.full_name, c.criminal_type, c.status
HAVING COUNT(cf.fir_id) > 1
ORDER BY fir_count DESC;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 6: FIRs filed in date range with complainant details
-- ═══════════════════════════════════════════════════════════════════
SELECT
    f.fir_number,
    f.date_filed,
    f.location_of_incident,
    f.fir_status,
    co.full_name          AS complainant_name,
    co.phone              AS complainant_phone,
    co.cnic               AS complainant_cnic,
    co.relation_to_victim
FROM fir f
JOIN complainant co ON f.complainant_id = co.complainant_id
WHERE f.date_filed BETWEEN '2024-03-01' AND '2024-06-30'
ORDER BY f.date_filed ASC;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 7: Convicted cases with criminal details
-- ═══════════════════════════════════════════════════════════════════
SELECT
    ca.case_number,
    ca.case_title,
    ca.case_type,
    ca.verdict,
    ca.court_name,
    ca.date_closed,
    c.full_name          AS criminal_name,
    c.cnic               AS criminal_cnic,
    cf.role_in_crime
FROM crm_case ca
JOIN fir f           ON ca.fir_id      = f.fir_id
JOIN criminal_fir cf ON f.fir_id       = cf.fir_id
JOIN criminal c      ON cf.criminal_id = c.criminal_id
WHERE ca.verdict = 'Convicted'
ORDER BY ca.date_closed DESC;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 8: Currently imprisoned criminals with their cases
-- ═══════════════════════════════════════════════════════════════════
SELECT
    c.full_name          AS criminal_name,
    c.cnic,
    c.criminal_type,
    c.status,
    f.fir_number,
    ca.case_number,
    ca.case_title,
    ca.case_status,
    ca.verdict
FROM criminal c
JOIN criminal_fir cf ON c.criminal_id = cf.criminal_id
JOIN fir f           ON cf.fir_id     = f.fir_id
JOIN crm_case     ca ON f.fir_id      = ca.fir_id
WHERE c.status = 'imprisoned'
ORDER BY c.full_name;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 9: Case distribution by type with percentage
-- ═══════════════════════════════════════════════════════════════════
SELECT
    ca.case_type,
    COUNT(*)             AS total_cases,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM crm_case), 2) AS percentage
FROM crm_case ca
GROUP BY ca.case_type
ORDER BY total_cases DESC;

-- ═══════════════════════════════════════════════════════════════════
-- QUERY 10: Full criminal profile
-- ═══════════════════════════════════════════════════════════════════
SELECT
    c.criminal_id,
    c.full_name          AS criminal_name,
    c.criminal_type,
    c.status             AS criminal_status,
    f.fir_number,
    f.date_filed,
    f.fir_status,
    ca.case_number,
    ca.case_title,
    ca.case_type,
    ca.case_status,
    ca.verdict,
    po.full_name         AS investigating_officer,
    COUNT(e.evidence_id) AS total_evidence_pieces
FROM criminal c
JOIN criminal_fir cf   ON c.criminal_id  = cf.criminal_id
JOIN fir f             ON cf.fir_id      = f.fir_id
JOIN crm_case       ca ON f.fir_id       = ca.fir_id
JOIN police_officer po ON ca.investigating_officer_id = po.officer_id
LEFT JOIN evidence e   ON ca.case_id     = e.case_id
GROUP BY c.criminal_id, c.full_name, c.criminal_type, c.status,
         f.fir_number, f.date_filed, f.fir_status,
         ca.case_number, ca.case_title, ca.case_type, ca.case_status,
         ca.verdict, po.full_name
ORDER BY c.full_name, f.date_filed;
