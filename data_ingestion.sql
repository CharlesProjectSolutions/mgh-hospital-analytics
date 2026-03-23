
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
   Grain: one procedure session (recurring daily procedures each
          get their own row, distinguished by procedure_start).
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






SELECT * FROM dbo.fact_encounters

-- Query 1.1: Overall Hospital Performance Dashboard Metrics
-- Purpose: Calculate summary KPIs for executive dashboard
SELECT
    COUNT(DISTINCT encounter_id) AS total_encounters,
    COUNT(DISTINCT patient_id) AS total_patients,
    --ROUND(AVG(EXTRACT(EPOCH FROM (encounter_stop - encounter_start)) / 3600), 2) AS avg_los_hours,
    ROUND(SUM(total_claim_cost), 2) AS total_revenue,
    ROUND(AVG(total_claim_cost), 2) AS avg_cost_per_encounter,
    ROUND(SUM(payer_coverage), 2) AS total_payer_coverage,
    ROUND((SUM(payer_coverage) / NULLIF(SUM(total_claim_cost), 0)) * 100, 2) AS payer_coverage_rate
FROM fact_encounters
INNER JOIN dim_date ON fact_encounters.date_key = dim_date.date_key
WHERE dim_date.date >= '2011-01-01';



-- Query 1.2: Encounter Volume Trends by Month
-- Purpose: Track monthly encounter volumes to identify seasonality and trends
SELECT
    DATEFROMPARTS(YEAR(encounter_start), MONTH(encounter_start), 1) AS month, 
    COUNT(*) AS encounter_count,
    COUNT(DISTINCT patient_id) AS unique_patients,
    ROUND(AVG(total_claim_cost), 2) AS avg_encounter_cost
FROM dbo.fact_encounters
--WHERE encounter_start >= DATEADD(YEAR, -2, DATEFROMPARTS(YEAR(GETDATE()), 1, 1))
GROUP BY DATEFROMPARTS(YEAR(encounter_start), MONTH(encounter_start), 1)
ORDER BY month DESC;




WITH encounter_sequence AS (
    SELECT
        encounter_id, patient_id, encounter_class_id,
        encounter_start,
        encounter_stop,
        reason_description,
        LAG(encounter_stop) OVER (PARTITION BY patient_id ORDER BY encounter_start) AS previous_discharge_date,
        LAG(encounter_class_id) OVER (PARTITION BY patient_id ORDER BY encounter_start) AS previous_encounter_class,
        LAG(reason_description) OVER (PARTITION BY patient_id ORDER BY encounter_start) AS previous_reason
    FROM fact_encounters
    WHERE encounter_stop IS NOT NULL
),
readmissions AS (
    SELECT
        *,
        -- DATEDIFF(interval, start, end) calculates the difference in days
        DATEDIFF(day, previous_discharge_date, encounter_start) AS days_since_last_visit,
        CASE
            WHEN DATEDIFF(day, previous_discharge_date, encounter_start) <= 30
            THEN 1 ELSE 0
        END AS is_readmission_30day
    FROM encounter_sequence
    WHERE previous_discharge_date IS NOT NULL
)
SELECT
    encounter_class_id,
    COUNT(*) AS total_followup_encounters,
    SUM(is_readmission_30day) AS readmissions_30day,
   ROUND((CAST(SUM(is_readmission_30day) AS NUMERIC(18,2)) / COUNT(*)) * 100, 2) AS readmission_rate_pct,
    ROUND(AVG(CASE WHEN is_readmission_30day = 1 THEN days_since_last_visit END), 1) AS avg_days_to_readmit
FROM readmissions
GROUP BY ROLLUP(encounter_class_id)
ORDER BY readmission_rate_pct DESC;

