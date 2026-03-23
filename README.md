# 🏥 MGH Hospital Performance Analytics Dashboard

> **Maven Analytics Hospital Challenge** — End-to-end analytics project covering SQL, Python, Tableau, and an interactive HTML dashboard for Massachusetts General Hospital (synthetic dataset, 2011–2022).

---

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Project Objective](#2-project-objective)
3. [Business Questions & Core KPIs](#3-business-questions--core-kpis)
4. [Data Structure](#4-data-structure)
5. [Dashboard Suite](#5-dashboard-suite)
6. [Methodology](#6-methodology)
7. [Wireframes & Prototypes](#7-wireframes--prototypes)
8. [Insights Summary](#8-insights-summary)
9. [How to Navigate the Repo](#9-how-to-navigate-the-repo)
10. [Future Enhancements](#10-future-enhancements)

---

## 1. Project Overview

This project was completed as part of the **Maven Analytics Hospital Challenge**, where I acted as a **Healthcare Data Analyst** tasked with building a comprehensive performance analytics solution for Massachusetts General Hospital (MGH). The dataset is synthetic and covers **27,891 patient encounters** across **974 unique patients** from January 2011 through February 2022.

The challenge required me to move through the full analytics lifecycle; from raw CSV ingestion and dimensional modelling through SQL-driven KPI calculation, Python-based statistical analysis, HTML wireframe/prototype dashboard** built with Chart.js , and finally a **fully interactive, cross-filtered Tableau dashboard.

The deliverables were designed to serve multiple stakeholders: clinical operations teams interested in patient flow and readmissions, finance leaders tracking costs and revenue, and payer-relations teams monitoring insurance coverage and reimbursement trends.

---

## 2. Project Objective

> **Design and build a hospital performance KPI dashboard that enables leadership to monitor clinical, insurance, financial, and  operational metrics, with the ability to drill down by year, visit type, payer, and coverage status.**

Specifically, the project aimed to:

- **Centralize** disparate encounter and procedure data into a clean star schema
- **Quantify** the four core pillars of hospital performance: admissions, operations, finance, and insurance
- **Surface** actionable insights through automated, filter-responsive dashboard
- **Deliver** production-ready artefacts in four formats: T-SQL queries, a Python analytics script, HTML wireframe/prototype dashboard, and a live Tableau dashboard.

---

## 3. Business Questions & Core KPIs

The executive team wants clarity on the followings questions:

### 1. **Patient Volume Trends**
* How many patients are being **admitted or readmitted** over time?
* How has admission volume trended year-over-year, and which year saw peak throughput?

### 2. **Hospital Stay Efficiency**
* What is the **average length of stay** for patients?

### 3. **Cost of Care**
* What is the **average cost per visit**?

### 4. **Insurance Coverage**
* How many **procedures** are covered by insurance?

Targeted SQL queries regarding the various business questions can be found [here](https://github.com/CharlesProjectSolutions/mgh-hospital-analytics/blob/2f3398b68dee9dfa785e6be1036471e9ceaf205d/kpi_queries.sql)

---

## 4. Data Structure

The SQL data ingestion queries utilized to create tables + bulk load CSVs files and perform quality checks can be found [here](https://github.com/CharlesProjectSolutions/mgh-hospital-analytics/blob/5442131de37416e66ae74a4265f32ab026218eac/data_ingestion.sql)

The SQL queries utilized to build data Model Views feeding Tableau dashboards can be found [here](https://github.com/CharlesProjectSolutions/mgh-hospital-analytics/blob/5442131de37416e66ae74a4265f32ab026218eac/data_model_views)

Prior to beginning this analysis, a variety of checks were conducted for quality control and familiarization with the datasets. Source CSVs files were reviewed for structure, column types, completeness, and 
identified the need for a star schema to support multi-dimensional cross-filtering. Designed dimensional tables: dim_patients, dim_payers, dim_encounter_class, dim_date.
Designed fact tables: fact_encounters, fact_procedures, and mapped derived fields required for KPIs: is_readmission flag (30-day window), los_days, age_group, coverage_rate.

<img width="33000" height="2500" alt="converted_page_1" src="https://github.com/user-attachments/assets/db941141-c479-4587-948d-01e7cc7581d9" />

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

## 5. Dashboard Suite

A downloadable interactive wireframe and prototype are included here [here.html](https://github.com/user-attachments/files/26173509/mgh_WireframesDdashboard.html)<!DOCTYPE html>
to preview the dashboard experience. The Tableau implementation is in progress and will be published upon completion.
  
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


These KPIs help leadership understand capacity, financial performance, and care quality

| # | KPI Family | Core Metric | 11-Year Overall |
|---|-----------|-------------|-----------------|
| 1 | **Volume & Admissions** | Total Encounters | **27,891** |
| 2 | **Readmissions** | 30-Day Readmission Rate | **62.2%** (17,346 events) |
| 3 | **Length of Stay** | Avg LOS per Encounter | **0.30 days** (inpatient: 1.54 d) |
| 4 | **Cost & Revenue** | Avg Cost per Visit | **$3,640** · Total Revenue **$101.5M** |

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

## 8. Insights Summary

### 📊 Volume & Admissions
- **Hospital admissions grew 191% from 2011 to 2014** (1,336 → 3,885 encounters), the peak year, before stabilizing around 2,000–3,000 annually.
- Ambulatory encounters dominate the visit mix, while **inpatient accounts for only ~4% of volume but the longest LOS** (avg 1.54 days vs 0.06 days for emergency).
- The **65+ Senior age group** represents the majority of all encounters, consistent with MGH's role as a tertiary referral centre serving an older patient population.
- **Resources:**



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


## 10. Future Enhancements

The current dashboard is a strong analytical foundation. The following enhancements would move it toward a production-grade hospital intelligence platform:

| Priority | Enhancement | Value |
|----------|------------|-------|
| 🔴 High | **Predictive Readmission Model** — Logistic regression or XGBoost model to score individual patients' 30-day readmission risk at discharge | Actionable clinical intervention at the point of care |
| 🔴 High | **Live SQL Server / Azure SQL Connection** — Replace static JSON with a live ODBC/JDBC connection, enabling real-time data refresh | Eliminates manual `compute_data.py` reruns |
| 🟡 Medium | **Bed Occupancy & Capacity KPI** — Integrate hospital capacity data to calculate true bed utilisation rates and flag surge risk | Fills the current "N/A" gap in the Operations tab |
| 🟡 Medium | **Cost Forecasting Module** — Time-series forecasting (Prophet or ARIMA) to project revenue and cost trajectories 12–24 months forward | Supports annual budget planning |
| 🟡 Medium | **Full Tableau Cloud Deployment** — Migrate the HTML dashboard to Tableau Cloud, enabling enterprise sharing and row-level security | Stakeholder self-service access |
| 🟢 Low | **Equity & Disparities Dashboard** — A dedicated 5th tab breaking down KPIs by race/ethnicity and gender to surface health equity gaps | Supports DEI reporting and compliance |
| 🟢 Low | **Automated PDF/Email Reports** — Scheduled Python script that renders key KPI snapshots to PDF and emails to leadership monthly | Reduces manual reporting overhead |


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
