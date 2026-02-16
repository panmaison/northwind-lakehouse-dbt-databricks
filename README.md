# northwind-lakehouse-dbt-databricks

An end-to-end, production-style Lakehouse demo on Azure.

**ADF** lands Northwind extracts to **ADLS Gen2** as date-partitioned **Parquet**, **Databricks (Unity Catalog)** reads data via External Locations, and **dbt** builds incremental **Bronze (Delta)** models. CI/CD is implemented with **GitHub Actions** (PR checks + main deployments).

---

## What this project demonstrates

- **Cloud ingestion pattern**: ADF → ADLS landing zone (daily folders)
- **Secure access**: Unity Catalog External Location (no account keys in code)
- **Lakehouse modeling**: Parquet landing → Delta Bronze (incremental / merge)
- **Data observability basics**: dbt tests + reproducible builds
- **CI/CD**: GitHub Actions CI on PR, CD on merge to `main`

---

## Architecture

**Flow**
1. **ADF** writes daily snapshots to ADLS Gen2 (landing)
2. **Databricks + Unity Catalog** connects to ADLS using an External Location
3. **dbt** reads parquet from ADLS and writes **Delta** Bronze tables
4. **GitHub Actions** runs CI/CD pipelines for automated validation and deployment

**Data layout (landing)**
abfss://landing@panmaisonadls.dfs.core.windows.net/northwind/Orders/
2026-02-12/Orders/.parquet
2026-02-13/Orders/.parquet

```md
## Repository structure
```text
├─ dbt/
│  ├─ dbt_project.yml
│  ├─ profiles.yml            # template uses env vars (no secrets committed)
│  ├─ models/
│  │  ├─ bronze/
│  │  │  └─ bronze_orders.sql
│  │  ├─ silver/
│  │  └─ marts/
│  ├─ macros/
│  └─ tests/
│
├─ .github/workflows/
│  ├─ ci.yml
│  └─ cd.yml
│
└─ architecture/
   ├─ diagram.png
   └─ decisions.md
```

---

## Prerequisites

- Azure Databricks workspace with **Unity Catalog enabled**
- ADLS Gen2 Storage Account (landing container)
- Unity Catalog:
  - **Storage Credential**
  - **External Location** pointing to the landing container
- A Databricks **SQL Warehouse** (recommended: separate **dev** and **prod**)

---
```md
## Local setup (dbt-core)

Install dbt adapter:

```bash
pip install dbt-databricks
Run in /dbt:
dbt deps
dbt debug -t dev --profiles-dir .
dbt build -t dev --select bronze_orders --profiles-dir .
This repo ships a profiles.yml template that reads connection settings from environment variables.
Bronze model (example)

Bronze reads parquet from the date-partitioned landing folders and adds:

load_date parsed from the path
source_file for traceability

Example access path:
parquet.`abfss://landing@panmaisonadls.dfs.core.windows.net/northwind/Orders/*/Orders`

CI/CD (GitHub Actions)
CI: Pull Request

dbt deps
dbt compile
dbt build (changed models only; fallback to Bronze model on first run)

CD – Production deployment
Triggered on push to main:

Runs dbt build -t prod using the production SQL Warehouse

GitHub Secrets & Variables

Add Repository Secrets:

DATABRICKS_HOST (e.g., https://dbc-xxxx.cloud.databricks.com)

DATABRICKS_TOKEN (PAT)

DATABRICKS_HTTP_PATH_DEV (SQL Warehouse HTTP path)

DATABRICKS_HTTP_PATH_PROD (SQL Warehouse HTTP path)

Add Repository Variables (optional but recommended):

DBT_CATALOG (e.g., erp_northwind)

DBT_SCHEMA_DEV (e.g., hongwei)

DBT_SCHEMA_PROD (e.g., prod)

Notes on cost control

Prefer SQL Warehouse auto-stop (10–15 minutes)

Avoid always-on clusters for development

Use incremental models to prevent full historical scans

Roadmap

 Add Silver models (typed & cleaned)

 Add dbt tests (not_null, uniqueness, relationships)

 Add dbt docs generation + GitHub Pages publish

 Add incremental load strategy per table (snapshot vs delta)

 Add lineage diagram (dbt docs)
