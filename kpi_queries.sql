

-- ----------------------------------------------------------------
-- 1.1  TOTAL ADMISSIONS
-- ----------------------------------------------------------------

DECLARE @Year INT = NULL;

-- KPI scalar
SELECT
    COUNT(DISTINCT encounter_id)       AS total_admissions,
    COUNT(DISTINCT patient_id)         AS unique_patients
FROM HospitalDW.dbo.fact_encounters
WHERE (@Year IS NULL OR encounter_year = @Year);



-- Admission Trend by year (for line chart)
SELECT
    encounter_year,
    COUNT(DISTINCT encounter_id)       AS total_admissions,
    COUNT(DISTINCT patient_id)         AS unique_patients
FROM HospitalDW.dbo.fact_encounters
GROUP BY ROLLUP(encounter_year)
ORDER BY encounter_year



-- Admission Year-over-Year change
WITH yearly AS (
    SELECT
        encounter_year,
        COUNT(DISTINCT encounter_id)   AS admissions
    FROM HospitalDW.dbo.fact_encounters
    GROUP BY encounter_year
)
SELECT
    curr.encounter_year,
    curr.admissions                                                AS current_admissions,
    prev.admissions                                                AS prior_year_admissions,
    curr.admissions - ISNULL(prev.admissions, 0)                   AS yoy_delta,
    ROUND(
        (curr.admissions - ISNULL(prev.admissions, 0)) * 100.0
        / NULLIF(prev.admissions, 0), 1)                           AS yoy_pct_change
FROM yearly curr
LEFT JOIN yearly prev ON prev.encounter_year = curr.encounter_year - 1
ORDER BY curr.encounter_year;



-- ----------------------------------------------------------------
-- 1.2  TOTAL READMISSIONS & READMISSION RATE (30-day window)
-- ----------------------------------------------------------------
DECLARE @Year INT = NULL;

SELECT
    SUM(IsReadmission) AS total_readmissions,
    COUNT(*) AS total_encounters,
    ROUND(SUM(IsReadmission) * 100.0 / NULLIF(COUNT(encounter_id), 0), 2) AS readmission_rate_pct,
    ROUND(AVG(CAST(DaysSincePreviousDischarge AS FLOAT)), 1) AS avg_days_to_readmit
FROM HospitalDW.dbo.HospitalEncounterDW
WHERE (@Year IS NULL OR encounter_year = @Year);


-- ----------------------------------------------------------------
-- 1.3  AVERAGE LENGTH OF STAY
-- ----------------------------------------------------------------
DECLARE @Year INT = NULL;

WITH CalculatedData AS (
    SELECT 
        encounter_duration_min,
        -- Calculate median as a window function first
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY encounter_duration_min / 1440.0) OVER () AS median_raw
    FROM HospitalDW.dbo.HospitalEncounterDW
    WHERE (@Year IS NULL OR encounter_year = @Year)
)
SELECT
    ROUND(AVG(encounter_duration_min / 1440.0), 2) AS avg_los_days,
    ROUND(AVG(encounter_duration_min / 60.0),   2) AS avg_los_hours,
    ROUND(MIN(encounter_duration_min / 1440.0), 2) AS min_los_days,
    ROUND(MAX(encounter_duration_min / 1440.0), 2) AS max_los_days,
    ROUND(MAX(median_raw), 2)                      AS median_los_days -- Use MAX to pick the single value
FROM CalculatedData;

/*
0.3 days Average LOS > data is heavily skewed/pulled up by the outlier
May try removing the 1,872-day stay noise.
*/

-- LOS trend by year (for bar chart)
DECLARE @Year INT = NULL;

SELECT
    encounter_year,
    ROUND(AVG(encounter_duration_min / 1440.0), 2)   AS avg_los_days,
    COUNT(DISTINCT encounter_id)                      AS encounter_count
FROM HospitalDW.dbo.fact_encounters
WHERE (@Year IS NULL OR encounter_year = @Year)
GROUP BY encounter_year
ORDER BY encounter_year;


/* 
We calculated an 'Adjusted Average' by removing the top 1% of extreme cases. This prevents 'data errors' or 'rare 5-year stays' from making it look like our typical 15-minute check-up takes 7 hours. 
It gives us a much clearer picture of our daily hospital efficiency.
*/

SELECT 
    encounter_id,
    patient_id,
    encounter_start,
    encounter_stop,
    encounter_duration_min,
    -- Calculate days to confirm the math
    (encounter_duration_min / 1440.0) AS los_days 
FROM HospitalDW.dbo.fact_encounters
WHERE (encounter_duration_min / 1440.0) > 365
ORDER BY encounter_duration_min DESC;



-- Finding the 1% longest stays and ignore them, no matter how long they are. Keeping the data clean even if our hospital starts taking longer-term patients
WITH PercentileData AS (
    SELECT 
        encounter_duration_min,
        -- Ranking every row from 0 to 1 based on duration
        PERCENT_RANK() OVER (ORDER BY encounter_duration_min) AS duration_rank
    FROM HospitalDW.dbo.fact_encounters
)
SELECT 
    AVG(encounter_duration_min / 1440.0) AS Clean_Avg_LOS_Days
FROM PercentileData
-- Keep only the bottom 99% of data
WHERE duration_rank < 0.99;


-- ----------------------------------------------------------------
-- 1.4  AVERAGE COST PER VISIT
-- ----------------------------------------------------------------
DECLARE @Year INT = NULL;

-- KPI scalar
SELECT
    ROUND(AVG(total_claim_cost), 2)         AS avg_cost_per_visit,
    ROUND(AVG(payer_coverage), 2)           AS avg_payer_coverage,
    ROUND(AVG(patient_out_of_pocket), 2)    AS avg_patient_oop,
    ROUND(SUM(total_claim_cost), 2)         AS total_revenue
FROM HospitalDW.dbo.fact_encounters
WHERE (@Year IS NULL OR encounter_year = @Year);




-- Cost trend by year
DECLARE @Year INT = NULL;

SELECT
    encounter_year,
    ROUND(AVG(total_claim_cost), 2)         AS avg_cost_per_visit,
    ROUND(SUM(total_claim_cost), 2)         AS total_revenue
FROM HospitalDW.dbo.fact_encounters
WHERE (@Year IS NULL OR encounter_year = @Year)
GROUP BY ROLLUP(encounter_year)
ORDER BY encounter_year;


-- Cost per day (total_claim_cost / LOS in days)
DECLARE @Year INT = NULL;

SELECT
    encounter_year,
    ROUND(AVG(total_claim_cost /
        NULLIF(encounter_duration_min / 1440.0, 0)), 2)  AS avg_cost_per_day
FROM HospitalDW.dbo.fact_encounters
WHERE (@Year IS NULL OR encounter_year = @Year)
GROUP BY encounter_year
ORDER BY encounter_year;



-- ----------------------------------------------------------------
-- 1.5  INSURANCE COVERAGE RATE
-- ----------------------------------------------------------------
DECLARE @Year INT = NULL;

-- KPI scalar
SELECT
    ROUND(SUM(payer_coverage) / NULLIF(SUM(total_claim_cost), 0) * 100, 2) AS coverage_rate_pct,
    ROUND(SUM(payer_coverage), 2)  AS total_covered,
    ROUND(SUM(patient_out_of_pocket), 2)  AS total_uncovered,
	ROUND(SUM(patient_out_of_pocket) / NULLIF(SUM(total_claim_cost), 0) * 100, 2) AS uncovered_rate_pct,
    ROUND(SUM(total_claim_cost), 2)  AS total_billed,
    COUNT(DISTINCT CASE WHEN payer_name <> 'NO_INSURANCE' THEN encounter_id END)  AS insured_encounters,
    COUNT(DISTINCT CASE WHEN payer_name  = 'NO_INSURANCE' THEN encounter_id END) AS uninsured_encounters
FROM HospitalDW.dbo.HospitalEncounterDW
WHERE (@Year IS NULL OR encounter_year = @Year);



-- Coverage rate by year (line chart)
DECLARE @Year INT = NULL;
SELECT
    encounter_year,
    ROUND(SUM(payer_coverage) / NULLIF(SUM(total_claim_cost), 0) * 100, 2)
                                                              AS coverage_rate_pct
FROM HospitalDW.dbo.HospitalEncounterDW
WHERE (@Year IS NULL OR encounter_year = @Year)
GROUP BY encounter_year
ORDER BY encounter_year;




-- Proxy metric using inpatient encounters only:
DECLARE @Year INT = NULL;

SELECT  encounter_year,
   
    COUNT(DISTINCT encounter_id) AS inpatient_encounters,
    ROUND(SUM(encounter_duration_min / 1440.0), 1) AS total_inpatient_days,
    ROUND(AVG(encounter_duration_min / 1440.0), 0) AS avg_los_days
FROM HospitalDW.dbo.HospitalEncounterDW
WHERE encounter_class = 'inpatient'
  AND (@Year IS NULL OR encounter_year = @Year)
GROUP BY encounter_year
ORDER BY encounter_year;





WITH yearly_summary AS (
    -- First, aggregate your data by year
    SELECT
        encounter_year,
        COUNT(DISTINCT encounter_id) AS current_admissions
    FROM HospitalDW.dbo.fact_encounters
    GROUP BY ROLLUP(encounter_year)
)
SELECT
    encounter_year,
    current_admissions,
    -- 1. Get the previous year's admissions using LAG
    LAG(current_admissions) OVER (ORDER BY encounter_year) AS prior_year_admissions,
    
    -- 2. Calculate the raw change (Delta)
    current_admissions - LAG(current_admissions) OVER (ORDER BY encounter_year) AS yoy_delta,
    
    -- 3. Calculate the Percentage Change (rounded to 1 decimal place)
    CAST(
        (current_admissions - LAG(current_admissions) OVER (ORDER BY encounter_year)) * 100.0 
        / NULLIF(LAG(current_admissions) OVER (ORDER BY encounter_year), 0) 
    AS DECIMAL(18, 1)) AS yoy_pct_change
FROM yearly_summary
ORDER BY encounter_year;



SELECT 
    YEAR(EncounterStart) AS Visit_Year,
    SUM(IsReadmission) AS IS_Readmission,
    -- Use MAX to get the pre-calculated value from the join
    MAX(current_admissions) AS CurrentAdmissions, 
    MAX(prior_year_admissions) AS PYTD_Admission, 
    MAX(yoy_delta) AS YOYDelta,
    MAX(yoy_pct_change) AS YOY_Pct_Change
FROM HospitalEncounterDW
GROUP BY ROLLUP (YEAR(EncounterStart))
ORDER BY YEAR(EncounterStart);
