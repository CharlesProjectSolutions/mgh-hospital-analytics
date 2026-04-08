
CREATE DATABASE HospitalDW

USE HospitalDW;   -- Switch to the target database
GO

/* ============================================================
   CREATE DIMENSION: dim_patients
   One row per patient.
   ============================================================
   */
DROP TABLE IF EXISTS dbo.dim_patients;
GO
CREATE TABLE dbo.dim_patients (
    patient_id       NVARCHAR(50)   NOT NULL PRIMARY KEY,
    first_name       NVARCHAR(100)  NULL,
    last_name        NVARCHAR(100)  NULL,
    prefix           NVARCHAR(20)   NULL,
    suffix           NVARCHAR(20)   NULL,
    maiden           NVARCHAR(100)  NULL,
    birthdate        DATE           NOT NULL,
    deathdate        DATE           NULL,           -- NULL = still alive
    gender           CHAR(1)        NOT NULL,       -- 'M' or 'F'
    race             NVARCHAR(50)   NOT NULL,
    ethnicity        NVARCHAR(50)   NOT NULL,
    marital          CHAR(1)        NOT NULL,       -- M=Married, S=Single, U=Unknown
    birthplace       NVARCHAR(200)  NULL,
    address          NVARCHAR(200)  NULL,
    city             NVARCHAR(100)  NULL,
    state            NVARCHAR(50)   NULL,
    county           NVARCHAR(100)  NULL,
    zip              CHAR(5)        NULL,
    lat              FLOAT          NULL,
    lon              FLOAT          NULL,
    is_deceased      TINYINT        NOT NULL DEFAULT 0,   -- 1 = deceased
    age_at_ref_date  INT            NULL,                 -- age as of 2022-02-05
    age_at_death     INT            NULL                  -- NULL if still alive
);
GO

/* ============================================================
   DIMENSION: dim_payers
   One row per insurance payer (9 insurers + NO_INSURANCE).
   ============================================================ */
DROP TABLE IF EXISTS dbo.dim_payers;
GO
CREATE TABLE dbo.dim_payers (
    payer_id    NVARCHAR(50)   NOT NULL PRIMARY KEY,
    payer_name  NVARCHAR(100)  NOT NULL,
    address     NVARCHAR(200)  NULL,
    city        NVARCHAR(100)  NULL,
    state       CHAR(2)        NULL,
    zip         NVARCHAR(10)   NULL,
    phone       NVARCHAR(30)   NULL
);
GO

/* ============================================================
   DIMENSION: dim_encounter_class
   6 encounter types (ambulatory, emergency, etc.)
   Tiny lookup table — avoids storing the string 27k times.
   ============================================================ */
DROP TABLE IF EXISTS dbo.dim_encounter_class;
GO
CREATE TABLE dbo.dim_encounter_class (
    encounter_class_id  TINYINT        NOT NULL PRIMARY KEY,
    encounter_class     NVARCHAR(50)   NOT NULL UNIQUE
);
GO

/* ============================================================
   DIMENSION: dim_date
   One row per calendar day, 2011-01-02 through 2022-02-05.
   Pre-computed calendar attributes speed up time-series analysis.
   ============================================================ */
DROP TABLE IF EXISTS dbo.dim_date;
GO
CREATE TABLE dbo.dim_date (
    date_key      INT         NOT NULL PRIMARY KEY,   -- YYYYMMDD integer
    date          DATE        NOT NULL UNIQUE,
    year          SMALLINT    NOT NULL,
    quarter       TINYINT     NOT NULL,               -- 1-4
    month         TINYINT     NOT NULL,               -- 1-12
    month_name    NVARCHAR(10) NOT NULL,
    week          TINYINT     NOT NULL,               -- ISO week 1-53
    day_of_month  TINYINT     NOT NULL,               -- 1-31
    day_of_week   TINYINT     NOT NULL,               -- 0=Monday, 6=Sunday
    day_name      NVARCHAR(10) NOT NULL,
    is_weekend    TINYINT     NOT NULL DEFAULT 0      -- 1 = Sat/Sun
);
GO

/* ============================================================
   FACT: fact_encounters
   One row per patient visit.
   Grain: one hospital encounter.
   Foreign keys resolve to all four dimensions above.
   ============================================================ */
DROP TABLE IF EXISTS dbo.fact_encounters;
GO
CREATE TABLE dbo.fact_encounters (
    encounter_id              NVARCHAR(50)    NOT NULL PRIMARY KEY,
    date_key                  INT             NOT NULL REFERENCES dbo.dim_date(date_key),
    patient_id                NVARCHAR(50)    NOT NULL REFERENCES dbo.dim_patients(patient_id),
    payer_id                  NVARCHAR(50)    NOT NULL REFERENCES dbo.dim_payers(payer_id),
    encounter_class_id        TINYINT         NOT NULL REFERENCES dbo.dim_encounter_class(encounter_class_id),
    organization_id           NVARCHAR(50)    NULL,
    encounter_start           DATETIMEOFFSET  NOT NULL,
    encounter_stop            DATETIMEOFFSET  NOT NULL,
    encounter_duration_min    FLOAT           NOT NULL,   -- length of visit in minutes
    encounter_code            BIGINT          NOT NULL,   -- SNOMED-CT code
    encounter_description     NVARCHAR(300)   NULL,
    base_encounter_cost       MONEY           NOT NULL,   -- facility base rate
    total_claim_cost          MONEY           NOT NULL,   -- total billed
    payer_coverage            MONEY           NOT NULL,   -- amount payer paid
    patient_out_of_pocket     MONEY           NOT NULL,   -- total - coverage
    reason_code               BIGINT          NULL,       -- SNOMED diagnosis code
    reason_description        NVARCHAR(300)   NOT NULL,   -- 'No reason recorded' if none
    patient_age_at_encounter  INT             NULL,
    encounter_year            SMALLINT        NOT NULL,
    encounter_month           TINYINT         NOT NULL,
    encounter_dow             NVARCHAR(10)    NOT NULL    -- 'Monday', 'Tuesday', etc.
);
GO

/* ============================================================
   FACT: fact_procedures
   One row per procedure performed.
   Grain: one procedure session (recurring daily procedures each get their own row, distinguished by procedure_start)
   ============================================================ */
DROP TABLE IF EXISTS dbo.fact_procedures;
GO
CREATE TABLE dbo.fact_procedures (
    procedure_key              INT             NOT NULL PRIMARY KEY,   -- surrogate
    encounter_id               NVARCHAR(50)    NOT NULL REFERENCES dbo.fact_encounters(encounter_id),
    patient_id                 NVARCHAR(50)    NOT NULL REFERENCES dbo.dim_patients(patient_id),
    date_key                   INT             NOT NULL REFERENCES dbo.dim_date(date_key),
    procedure_start            DATETIMEOFFSET  NOT NULL,
    procedure_stop             DATETIMEOFFSET  NOT NULL,
    procedure_duration_min     FLOAT           NOT NULL,
    procedure_code             BIGINT          NOT NULL,   -- SNOMED-CT code
    procedure_description      NVARCHAR(300)   NULL,
    base_cost                  MONEY           NOT NULL,
    reason_code                BIGINT          NULL,
    reason_description         NVARCHAR(300)   NOT NULL,
    patient_age_at_procedure   INT             NULL
);
GO

/* ============================================================
   BULK INSERT 
   ============================================================ 
*/

BULK INSERT dbo.dim_patients
FROM 'C:\Users\Charles\OneDrive\Desktop\Hospital Data\output\dimpatients.csv'
WITH (FORMAT='CSV');

BULK INSERT dbo.dim_payers
FROM 'C:\Users\Charles\OneDrive\Desktop\Hospital Data\output\dimpayers.csv'
WITH (FORMAT='CSV');

BULK INSERT dbo.dim_encounter_class
FROM 'C:\Users\Charles\OneDrive\Desktop\Hospital Data\output\dimencounter_class.csv'
WITH (FORMAT='CSV');

BULK INSERT dbo.dim_date
FROM 'C:\Users\Charles\OneDrive\Desktop\Hospital Data\output\dimdate.csv'
WITH (FORMAT='CSV');

BULK INSERT dbo.fact_encounters
FROM 'C:\Users\Charles\OneDrive\Desktop\Hospital Data\output\factencounters.csv'
WITH (FORMAT='CSV');

-- Error Message encountered loading the data & resolved:
-- Msg 4864, Level 16, State 1, Line 211 Bulk load data conversion error (type mismatch or invalid character for the specified codepage) for row 63, column 16 (reason_code)

BULK INSERT dbo.fact_procedures
FROM 'C:\Users\Charles\OneDrive\Desktop\Hospital Data\output\factprocedures.csv'
WITH (FORMAT='CSV');


/* ============================================================
   INDEXES  (add after bulk load for faster inserts)
   ============================================================ */
CREATE NONCLUSTERED INDEX IX_fact_encounters_patient
    ON dbo.fact_encounters (patient_id) INCLUDE (total_claim_cost, encounter_year);
GO
CREATE NONCLUSTERED INDEX IX_fact_encounters_payer
    ON dbo.fact_encounters (payer_id)   INCLUDE (total_claim_cost, payer_coverage);
GO
CREATE NONCLUSTERED INDEX IX_fact_encounters_date
    ON dbo.fact_encounters (date_key)   INCLUDE (encounter_class_id, total_claim_cost);
GO
CREATE NONCLUSTERED INDEX IX_fact_procedures_encounter
    ON dbo.fact_procedures (encounter_id);
GO
CREATE NONCLUSTERED INDEX IX_fact_procedures_patient
    ON dbo.fact_procedures (patient_id) INCLUDE (base_cost);
GO
   

/* ============================================================
   QUICK SANITY TABLES QUERY CHECKS
   ============================================================ */

SELECT 'dim_patients', COUNT(*) AS row_cnt FROM dbo.dim_patients
UNION ALL
SELECT 'dim_payers',  COUNT(*) FROM dbo.dim_payers
UNION ALL
SELECT 'dim_encounter_class', COUNT(*) FROM dbo.dim_encounter_class
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dbo.dim_date
UNION ALL
SELECT 'fact_encounters', COUNT(*) FROM dbo.fact_encounters
UNION ALL
SELECT 'fact_procedures', COUNT(*) FROM dbo.fact_procedures;
GO

