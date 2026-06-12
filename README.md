# SQL Data Warehouse Project (Bronze → Silver → Gold)

This repository contains a simple end-to-end SQL data warehouse pipeline built with three layers:

- **Bronze**: raw ingestions from CSV sources (staging/landing)
- **Silver**: cleaned + conformed data (ETL + standardization)
- **Gold**: analytics-ready star-schema artifacts (dimensions + fact) implemented as **views**

The project is designed for Microsoft SQL Server (T-SQL).

---

## Repository Structure

- `datasets/`
  - `datasets/source_crm/` (CRM CSVs)
    - `cust_info.csv`, `prd_info.csv`, `sales_details.csv`
  - `datasets/source_erp/` (ERP CSVs)
    - `CUST_AZ12.csv`, `LOC_A101.csv`, `PX_CAT_G1V2.csv`
- `scripts/`
  - `init_database.sql` — creates database `DataWarehouse` and schemas `bronze`, `silver`, `gold`
  - `bronze/`
    - `ddl_bronze.sql` — creates Bronze tables
    - `proc_load_bronze.sql` — loads CSVs into Bronze via `BULK INSERT`
  - `silver/`
    - `ddl_silver.sql` — creates Silver tables
    - `proc_load_silver.sql` — transforms Bronze into Silver
  - `gold/`
    - `ddl_gold.sql` — creates Gold dimension/fact **views**
- `tests/`
  - `silver_dq_checks.sql` — data quality checks for Silver
  - `gold_dq_checks.sql` — data quality checks for Gold

---

## How to Run

### 1) Create the database & schemas

Run:

```sql
:r scripts/init_database.sql
```

> Note: the script drops and recreates the `DataWarehouse` database if it already exists.

---

### 2) Create Bronze tables

Run:

```sql
:r scripts/bronze/ddl_bronze.sql
```

### 3) Load Bronze from CSVs

Run:

```sql
EXEC bronze.load_bronze;
```

**What it does**

- Truncates each Bronze table
- Loads CSVs using `BULK INSERT` from `datasets/source_crm` and `datasets/source_erp`

> ⚠️ The stored procedure uses hard-coded Windows paths. If your repo is located elsewhere, update the file paths inside `scripts/bronze/proc_load_bronze.sql`.

---

### 4) Create Silver tables

Run:

```sql
:r scripts/silver/ddl_silver.sql
```

### 5) Load Silver (ETL: Bronze → Silver)

Run:

```sql
EXEC silver.load_silver;
```

**What it does (high level)**

- Truncates each Silver table
- Applies cleaning/standardization rules, including:
  - trimming names
  - normalizing gender/marital status values
  - normalizing product line codes to descriptive labels
  - converting/validating date formats
  - deriving product category id from product key
  - removing NAS prefix from ERP `cid`
  - normalizing country names

---

### 6) Create Gold views (dimensions + fact)

Run:

```sql
:r scripts/gold/ddl_gold.sql
```

Gold artifacts:

- `gold.dim_customers`
- `gold.dim_products`
- `gold.fact_sales`

---

## Data Quality Checks

### Silver layer checks

After loading Silver, run:

```sql
:r tests/silver_dq_checks.sql
```

### Gold layer checks

After creating/loading Gold, run:

```sql
:r tests/gold_dq_checks.sql
```

---

## Notes / Assumptions

- Gold is implemented as **views** over Silver data (no physical Gold tables).
- The pipeline is intended to be re-runnable: Bronze/Silver procedures truncate target tables before loading.
- Several transformations are based on expected value patterns in the source CSVs (e.g., CRM codes for gender/marital status and ERP country abbreviations).

---

## License

This project is licensed under the MIT License. See `LICENSE` for details.
