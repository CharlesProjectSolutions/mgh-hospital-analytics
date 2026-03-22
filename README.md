# 🏥 MGH Hospital Performance Analytics Dashboard

> **Maven Analytics Hospital Challenge** — End-to-end analytics project covering SQL, Python, Tableau, and an interactive HTML dashboard for Massachusetts General Hospital (synthetic dataset, 2011–2022).

---

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Project Objective](#2-project-objective)
3. [Business Questions & Core KPIs](#3-business-questions--core-kpis)
4. [Dashboard Suite](#4-dashboard-suite)
5. [Data Summary](#5-data-summary)
6. [Methodology](#6-methodology)
7. [Wireframes & Prototypes](#7-wireframes--prototypes)
8. [Insights Summary](#8-insights-summary)
9. [How to Navigate the Repo](#9-how-to-navigate-the-repo)
10. [Future Enhancements](#10-future-enhancements)

---

## 1. Project Overview

This project was completed as part of the **Maven Analytics Hospital Challenge**, where I acted as a **Healthcare Data Analyst** tasked with building a comprehensive performance analytics solution for Massachusetts General Hospital (MGH). The dataset is synthetic and covers **27,891 patient encounters** across **974 unique patients** from January 2011 through February 2022.

The challenge required me to move through the full analytics lifecycle — from raw CSV ingestion and dimensional modelling, through SQL-driven KPI calculation, Python-based statistical analysis, Tableau dashboard specification, and finally a **fully interactive, cross-filtered HTML dashboard** built with Chart.js.

The deliverables were designed to serve multiple stakeholders: clinical operations teams interested in patient flow and readmissions, finance leaders tracking costs and revenue, and payer-relations teams monitoring insurance coverage and reimbursement trends.

---

## 2. Project Objective

> **Design and build a multi-page hospital performance dashboard that enables leadership to monitor clinical, operational, financial, and insurance KPIs, with the ability to drill down by year, visit type, payer, and coverage status.**

Specifically, the project aimed to:

- **Centralize** disparate encounter and procedure data into a clean star schema
- **Quantify** the four core pillars of hospital performance: admissions, operations, finance, and insurance
- **Surface** actionable insights through automated, filter-responsive commentary panels on every dashboard page
- **Deliver** production-ready artefacts in four formats: T-SQL queries, a Python analytics script, a Tableau migration guide, and a live HTML dashboard

---

## 3. Business Questions & Core KPIs

The following four KPI families drove every analytical decision in this project:

| # | KPI Family | Core Metric | 11-Year Overall |
|---|-----------|-------------|-----------------|
| 1 | **Volume & Admissions** | Total Encounters | **27,891** |
| 2 | **Readmissions** | 30-Day Readmission Rate | **62.2%** (17,346 events) |
| 3 | **Length of Stay** | Avg LOS per Encounter | **0.30 days** (inpatient: 1.54 d) |
| 4 | **Cost & Revenue** | Avg Cost per Visit | **$3,640** · Total Revenue **$101.5M** |

**Supporting questions answered by the dashboard:**

- How has admission volume trended year-over-year, and which year saw peak throughput?
- Which encounter class carries the highest readmission burden?
- Where does payer coverage leave patients with the greatest out-of-pocket exposure?
- Which insurance payers deliver the best reimbursement rates relative to billed amounts?
- How does patient age and gender distribution shift across years and visit types?
- Which procedure category drives the highest share of total cost?

---

## 4. An interactive HTML Wireframe & Prototype 
dashboard**(`file:///C:/Users/Charles/OneDrive/Desktop/Maven%20Hospital%20Challenge/mgh_dashboard.html`) that loads instantly in the browser, no server required.

Insights and recommendations are provided on the following key areas:

### 📊 Executive Summary
**Audience:** Hospital leadership & board
**Purpose:** High-level snapshot of the full patient population across all years and visit types.
**Filters:** Year · Visit Type
**KPI Tiles:** Total Admissions · Total Readmissions · Avg LOS · Avg Cost/Visit · Insurance Coverage Rate · Top Age Group

---

### ⚙️ Operations
**Audience:** Clinical operations & nurse management
**Purpose:** Drill into throughput efficiency, readmission rates, and visit-type mix.
**Filters:** Year · Visit Type
**KPI Tiles:** Avg LOS · Median LOS · Readmission Rate · Procedures per Visit

---

### 💵 Finance
**Audience:** CFO, revenue cycle management
**Purpose:** Track cost per visit, total revenue, procedure costs, and payer-level reimbursement.
**Filters:** Year · Payer
**KPI Tiles:** Avg Cost/Visit · Total Revenue · Payer Coverage % · Top Procedure Category · High-Cost Patients

---

### 🛡️ Insurance
**Audience:** Payer relations, access & equity team
**Purpose:** Analyse insurance coverage rates, payer mix, and the financial burden on uninsured patients.
**Filters:** Year · Payer · Coverage Status
**KPI Tiles:** Coverage Rate · Covered Procedures · Uninsured Procedure Cost · Largest Payer · Insured Encounters

---

> **Dynamic Insights Panels:** Every tab includes a row of **4 auto-generated insight cards** that update in real time when filters change — surfacing observations such as peak volume years, readmission rate deviations from the 11-year average, dominant payer share, and uninsured cost burden estimates.

---

## 5. Data Summary

### Source Files

| File | Rows | Description |
|------|------|-------------|
| `master_encounter.csv` | 27,891 | One row per patient encounter (admission) |
| `master_procedure.csv` | 47,701 | One row per procedure performed during an encounter |

### Star Schema (dimensional model)

```
                    ┌─────────────────┐
                    │   fact_encounters│
                    │─────────────────│
          ┌─────────┤ encounter_id (PK)├──────────┐
          │         │ patient_id (FK)  │           │
          │         │ payer_id (FK)    │           │
          │         │ class_id (FK)    │           │
          │         │ date_id (FK)     │           │
          │         │ total_claim_cost │           │
          │         │ coverage_amount  │           │
          │         │ los_days         │           │
          │         └────────┬────────┘           │
          │                  │                     │
   ┌──────┴───────┐  ┌───────┴──────┐  ┌──────────┴──────┐
   │ dim_patients │  │  dim_payers  │  │ dim_encounter_   │
   │──────────────│  │──────────────│  │ class            │
   │ patient_id   │  │ payer_id     │  │──────────────────│
   │ age_group    │  │ payer_name   │  │ class_id         │
   │ gender       │  │ payer_type   │  │ encounter_class  │
   │ race         │  └──────────────┘  └──────────────────┘
   └──────────────┘
          │                  │
   ┌──────┴───────┐  ┌───────┴──────────┐
   │   dim_date   │  │ fact_procedures  │
   │──────────────│  │──────────────────│
   │ date_id      │  │ procedure_id (PK)│
   │ year         │  │ encounter_id (FK)│
   │ month        │  │ procedure_desc   │
   │ quarter      │  │ procedure_cost   │
   └──────────────┘  │ payer_coverage   │
                     └──────────────────┘
```

### Dataset Characteristics

| Attribute | Detail |
|-----------|--------|
| **Date Range** | January 2011 – February 2022 |
| **Unique Patients** | 974 |
| **Total Encounters** | 27,891 |
| **Total Procedures** | 47,701 |
| **Encounter Classes** | 6 : ambulatory, emergency, inpatient, outpatient, urgentcare, wellness |
| **Payers** | 10: Medicare, NO_INSURANCE, Medicaid, Humana, Aetna, Blue Cross Blue Shield, Dual Eligible, UnitedHealthcare, Cigna Health, Anthem |
| **Procedure Categories** | 8 : Other, Cardiac, Preventive, Cancer Tx, Imaging, Dialysis, Inj/Infusion, Surgery |

---

## 6. Methodology

This project followed the **5 Data Analytics Ask → Prepare → Process → Analyze → Visualize** framework.

---

### Ask
Defined the four KPI domains (admissions, operations, finance, insurance) in collaboration with the project brief. Mapped each stakeholder group to a dedicated dashboard tab to ensure relevance at every level of the organisation. Documented 12 specific business questions to be answered before any data was touched.

---

### Prepare
- Reviewed both source CSVs (`master_encounter.csv`, `master_procedure.csv`) for structure, column types, and completeness
- Identified the need for a **star schema** to support multi-dimensional cross-filtering
- Designed dimensional tables: `dim_patients`, `dim_payers`, `dim_encounter_class`, `dim_date`
- Designed fact tables: `fact_encounters`, `fact_procedures`
- Mapped derived fields required for KPIs: `is_readmission` flag (30-day window), `los_days`, `age_group`, `coverage_rate`

---

### Process
- **SQL (`mgh_queries.sql`):** Wrote T-SQL (Microsoft SQL Server syntax) DDL scripts to create the star schema and all ETL transformations. Included window functions (`LAG`) for readmission detection, `DATEDIFF` for LOS, and CTEs for payer-coverage aggregation.
- **Python (`mgh_analytics.py` + `compute_data.py`):** Used `pandas` to replicate all SQL KPIs in Python — enabling local reproducibility without a SQL Server instance. `compute_data.py` pre-computes **19 cross-dimensional data slices** (year × visit type × payer matrix) and serialises to `dashboard_data.json`, which is then embedded directly into the HTML dashboard.
- Handled column-collision edge cases during the procedure/encounter merge (`payer_name_x` / `payer_name_y` suffix resolution).

---

### Analyze
Key analytical outputs:

| Analysis | Finding |
|----------|---------|
| Readmission trend | Rate rose from 48.8% (2011) to a peak of 68.4% (2014), then fluctuated — suggesting systemic discharge quality issues after 2013 |
| LOS by class | Inpatient avg LOS (1.54 d) is **25×** longer than emergency (0.06 d), validating separate benchmarking by encounter class |
| Payer coverage gap | Average payer coverage of 30.6% leaves patients with **69.4% OOP burden** across the study period |
| Coverage rate erosion | Coverage peaked at 47.4% in 2011 and fell to a low of 23.0% in 2018 — a 24.4pp decline over 7 years |
| Payer concentration | Medicare alone accounts for 40.8% of all encounters (11,371 visits), making government payer dynamics central to revenue strategy |
| Uninsured burden | 8,807 encounters (31.6%) had NO_INSURANCE, representing an estimated **$32M+ in self-pay costs** |
| Revenue peak | 2014 generated the highest annual revenue at **$12.0M**, corresponding to the peak admission year |
| Cost volatility | Avg cost/visit peaked at **$4,301 in 2012** and has fluctuated since, driven largely by inpatient and emergency case mix |

---

### Visualize
- **Tableau Migration Reference (`MGH_Dashboard_Reference_Guide.md`):** Complete specification of all Calculated Fields, LOD Expressions (`{FIXED}`, `{INCLUDE}`, `{EXCLUDE}`), Table Calculations, Parameters, Dashboard Actions, and filter logic for a direct Tableau rebuild.
- **HTML Dashboard (`mgh_dashboard.html`):** Four-tab Chart.js 4.4 dashboard with fully functional cross-filters. Pre-computed JSON data is embedded as a JavaScript constant — zero dependencies, zero server, opens directly in a browser.
- **Dynamic Insight Cards:** Each tab surfaces 4 auto-generated observations (e.g., *"2014 had the highest volume with 3,885 encounters"*; *"Coverage has declined by 11.6pp from 47.4% in 2011 to 35.8% in 2021"*) that recalculate on every filter change.

---

## 7. Wireframes & Prototypes

> **Note:** Figma wireframe exports should be placed in a `/wireframes` folder at the repo root. Reference them below by replacing the placeholder paths.

### Executive Summary Tab
```
┌─────────────────────────────────────────────────────────────────┐
│  🏥 MGH Hospital Performance Dashboard  │  2011–2022            │
├─────────────────────────────────────────────────────────────────┤
│  [ Year ▼ ]  [ Visit Type ▼ ]          All Years • All Types    │
├──────────┬──────────┬──────────┬──────────┬──────────┬──────────┤
│ ADMISSIONS│READMISS. │  AVG LOS │ AVG COST │ INS. COV.│ TOP AGE  │
│  27,671  │  17,346  │  0.30 d  │  $3,640  │  30.6%   │  65+Sen  │
├────────────────────────┬────────────────────────────────────────┤
│  Insights (4 cards)    │ Peak Volume · RR vs Avg · Payer · Age  │
├────────────────────────┼────────────────────────────────────────┤
│  Adm & Readm Over Time │  Avg LOS by Year                       │
├────────────────────────┼────────────────────────────────────────┤
│  Payer Mix (donut)     │  Demographics — Age & Gender           │
└────────────────────────┴────────────────────────────────────────┘
```

### Operations Tab
```
┌─────────────────────────────────────────────────────────────────┐
│  [ Year ▼ ]  [ Visit Type ▼ ]                                   │
├──────────┬──────────┬──────────┬──────────┬────────────────────┤
│  AVG LOS │ MEDIAN   │   RR     │BED OCC.  │  PROC / VISIT      │
│   0.30d  │  0.01d   │ 62.2%    │   N/A    │     1.71           │
├──────────────────────────────────────────────────────────────────┤
│  Insights: High-RR Class · LOS Range · YoY Change · LOS Gap     │
├────────────────────────┬─────────────────────────────────────────┤
│  LOS by Visit Type     │  Readmission Rate Over Time             │
├────────────────────────┼─────────────────────────────────────────┤
│  Admissions Trend      │  Patient Journey — Type Distribution    │
└────────────────────────┴─────────────────────────────────────────┘
```

### Finance Tab
```
┌─────────────────────────────────────────────────────────────────┐
│  [ Year ▼ ]  [ Payer ▼ ]                                        │
├──────────┬──────────┬──────────┬──────────┬────────────────────┤
│AVG COST  │  TOTAL   │  PAYER   │ TOP PROC │  HIGH-COST         │
│ $3,640   │ $101.5M  │  COV 30% │  CATEG.  │  PATIENTS: 90      │
├──────────────────────────────────────────────────────────────────┤
│  Insights: Peak Rev · Coverage Gap · Top Proc Cat · Best Payer  │
├────────────────────────┬─────────────────────────────────────────┤
│  Avg Cost/Visit by Yr  │  Procedure Category Cost (donut)        │
├────────────────────────┼─────────────────────────────────────────┤
│  Revenue vs Coverage   │  Cost & Coverage by Payer               │
└────────────────────────┴─────────────────────────────────────────┘
```

### Insurance Tab
```
┌─────────────────────────────────────────────────────────────────┐
│  [ Year ▼ ]  [ Payer ▼ ]  [ Coverage ▼ ]                       │
├──────────┬──────────┬──────────┬──────────┬────────────────────┤
│  COV.    │ COVERED  │ UNINSR.  │  LARGEST │  INSURED           │
│  RATE    │  PROC    │ COST     │  PAYER   │  ENCOUNTERS        │
│  30.6%   │  32,599  │  $50.2M  │ Medicare │   19,084           │
├──────────────────────────────────────────────────────────────────┤
│  Insights: Cov Trend · Medicare · Uninsured Burden · Proc Split │
├────────────────────────┬─────────────────────────────────────────┤
│  Payer Mix (donut)     │  Covered vs Uncovered Proc by Year      │
├────────────────────────┼─────────────────────────────────────────┤
│  Coverage Rate Trend   │  Payer: Billed vs Coverage Amount       │
└────────────────────────┴─────────────────────────────────────────┘
```

> 📁 Replace the ASCII wireframes above with actual Figma PNG exports once available:
> ```markdown
> ![Executive Summary Wireframe](wireframes/exec_summary_wireframe.png)
> ![Operations Wireframe](wireframes/operations_wireframe.png)
> ![Finance Wireframe](wireframes/finance_wireframe.png)
> ![Insurance Wireframe](wireframes/insurance_wireframe.png)
> ```

---

## 8. Insights Summary

### 📊 Volume & Admissions
- **Hospital admissions grew 191% from 2011 to 2014** (1,336 → 3,885 encounters), the peak year, before stabilizing around 2,000–3,000 annually.
- Ambulatory encounters dominate the visit mix, while **inpatient accounts for only ~4% of volume but the longest LOS** (avg 1.54 days vs 0.06 days for emergency).
- The **65+ Senior age group** represents the majority of all encounters, consistent with MGH's role as a tertiary referral centre serving an older patient population.

### ⚙️ Operations
- **The 30-day readmission rate peaked at 68.4% in 2014** — the same year admissions peaked — suggesting capacity pressure may have contributed to premature discharges.
- The lowest readmission rate recorded was **48.8% in 2011**, when volume was at its lowest, indicating a possible inverse relationship between throughput and readmission risk.
- **Inpatient readmission rate (77.0%)** is the highest of any visit class and nearly 12pp above the overall average, signalling inpatient discharge protocols as the highest-priority intervention target.
- Procedures per visit average 1.71 across the study period, with 47,701 total procedures logged against 27,891 encounters.

### 💵 Finance
- **Total 11-year revenue was $101.5M**, with 2014 representing the single highest revenue year ($12.0M) — directly tracking the admission volume peak.
- Average cost per visit peaked at **$4,301 in 2012**, driven by higher-acuity inpatient and emergency case mix in the early study period.
- Despite $101.5M in total billed costs, **payer coverage averaged only 30.6%** — meaning patients bore approximately **$70M in out-of-pocket costs** over 11 years.
- The **"Other" procedure category** accounts for the largest share of total procedure cost, followed by Cardiac and Imaging, which together represent significant high-cost procedure clusters.
- Medicare provides the best reimbursement ratio among insured payers, though its 40.8% share of encounters creates significant concentration risk around CMS policy changes.

### 🛡️ Insurance
- **Coverage rates declined from a high of 47.4% in 2011 to a low of 23.0% in 2018** — a 24.4pp erosion that substantially increased patient financial burden during that period.
- **Medicare is the single dominant payer at 40.8% of all encounters** (11,371 visits), with Medicaid and NO_INSURANCE the next largest groups — indicating a predominantly government-insured or uninsured patient base.
- **8,807 encounters (31.6%) were entirely uninsured**, representing an estimated $32M+ in self-pay cost exposure based on the average cost per visit — a significant uncompensated care risk.
- Of 47,701 total procedures, **32,599 (68.3%) had payer coverage** and 15,102 (31.7%) were self-pay, consistent with the ~31.6% uninsured encounter share.

---

## 9. How to Navigate the Repo

```
Maven Hospital Challenge/
│
├── README.md                         ← You are here
│
├── mgh_dashboard.html                ← 🌐 LIVE DASHBOARD — open in any browser
├── mgh_queries.sql                   ← 🗄️ T-SQL / MS SQL Server queries (all KPIs)
├── mgh_analytics.py                  ← 🐍 Python analytics script (pandas, all KPIs)
├── MGH_Dashboard_Reference_Guide.md  ← 📐 Tableau migration reference (full spec)
│
└── Hospital Data/
    │
    ├── master_encounter.csv          ← Source: 27,891 encounter rows
    ├── master_procedure.csv          ← Source: 47,701 procedure rows
    │
    ├── dim_patients.csv              ← Dimension: patient demographics
    ├── dim_payers.csv                ← Dimension: insurance payers
    ├── dim_encounter_class.csv       ← Dimension: visit type codes
    ├── dim_date.csv                  ← Dimension: calendar table
    ├── fact_encounters.csv           ← Fact: one row per encounter
    ├── fact_procedures.csv           ← Fact: one row per procedure
    │
    ├── create_schema.sql             ← DDL to create star schema tables in SQL Server
    ├── master_join.sql               ← SQL joins to rebuild master tables from star schema
    ├── compute_data.py               ← Python: pre-computes all dashboard data slices
    ├── dashboard_data.json           ← JSON: 19 pre-computed KPI data keys (embedded in HTML)
    └── build_dashboard_v2.py         ← Python: generates mgh_dashboard.html from JSON
```

### Quick Start

**To view the dashboard (no installation needed):**
```
Open mgh_dashboard.html in Chrome, Edge, or Firefox
```

**To regenerate the dashboard after data changes:**
```bash
cd "Hospital Data"
py compute_data.py        # Step 1: recompute dashboard_data.json
py build_dashboard_v2.py  # Step 2: rebuild mgh_dashboard.html
```

**To run the Python analytics script:**
```bash
py mgh_analytics.py
```

**To run SQL queries:** Open `mgh_queries.sql` in SSMS (SQL Server Management Studio) after running `create_schema.sql` to set up the schema.

---

## 10. Future Enhancements

The current dashboard is a strong analytical foundation. The following enhancements would move it toward a production-grade hospital intelligence platform:

| Priority | Enhancement | Value |
|----------|------------|-------|
| 🔴 High | **Predictive Readmission Model** — Logistic regression or XGBoost model to score individual patients' 30-day readmission risk at discharge | Actionable clinical intervention at the point of care |
| 🔴 High | **Live SQL Server / Azure SQL Connection** — Replace static JSON with a live ODBC/JDBC connection, enabling real-time data refresh | Eliminates manual `compute_data.py` reruns |
| 🟡 Medium | **Bed Occupancy & Capacity KPI** — Integrate hospital capacity data to calculate true bed utilisation rates and flag surge risk | Fills the current "N/A" gap in the Operations tab |
| 🟡 Medium | **Cost Forecasting Module** — Time-series forecasting (Prophet or ARIMA) to project revenue and cost trajectories 12–24 months forward | Supports annual budget planning |
| 🟡 Medium | **Full Tableau Cloud Deployment** — Migrate the HTML dashboard to Tableau Cloud using the `MGH_Dashboard_Reference_Guide.md` specification, enabling enterprise sharing and row-level security | Stakeholder self-service access |
| 🟢 Low | **Geospatial Patient Origin Map** — If patient ZIP codes are available, a Mapbox choropleth of encounter density by catchment area | Identifies underserved communities and expansion opportunities |
| 🟢 Low | **Equity & Disparities Dashboard** — A dedicated 5th tab breaking down KPIs by race/ethnicity and gender to surface health equity gaps | Supports DEI reporting and compliance |
| 🟢 Low | **Automated PDF/Email Reports** — Scheduled Python script that renders key KPI snapshots to PDF and emails to leadership monthly | Reduces manual reporting overhead |
| 🟢 Low | **Mobile-Responsive Redesign** — Refactor CSS grid layouts and chart sizes for tablets and phones using media queries | Extends access to clinical staff on mobile devices |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Data Storage | CSV flat files → Star Schema |
| SQL | Microsoft SQL Server (T-SQL) |
| Python | pandas · json · pathlib |
| Visualisation | Chart.js 4.4 (CDN) |
| Dashboard | Vanilla HTML5 / CSS3 / ES6+ JavaScript |
| BI Reference | Tableau Desktop (specification only) |
| IDE | VS Code |

---

## 📄 License

This project uses **synthetic data** provided by [Maven Analytics](https://www.mavenanalytics.io/) for educational purposes. All analysis, code, and dashboards are original work and are shared for portfolio and learning purposes.

---

<div align="center">

**Massachusetts General Hospital · Synthetic Data 2011–2022 · Maven Analytics Hospital Challenge**

*Built with SQL · Python · Chart.js · HTML/CSS/JS*

</div>
