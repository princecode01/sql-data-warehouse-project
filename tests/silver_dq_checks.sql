-- ============================================================
-- Data Quality Checks: Silver Layer
-- Run AFTER executing silver.load_silver to validate results
-- ============================================================

-- ============================================================
-- 1. silver.crm_cust_info
-- ============================================================

-- Check for duplicate customer IDs (should return 0 rows)
SELECT 'DQ-01' AS check_id, 'Duplicate cst_id' AS check_name, COUNT(*) AS failed_rows
FROM (
    SELECT cst_id, COUNT(*) AS cnt
    FROM silver.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(*) > 1
) t;

-- Check for NULL customer IDs (should return 0 rows)
SELECT 'DQ-02' AS check_id, 'NULL cst_id' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_cust_info
WHERE cst_id IS NULL;

-- Check marital status only contains expected values
SELECT 'DQ-03' AS check_id, 'Invalid cst_marital_status' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a');

-- Check gender only contains expected values
SELECT 'DQ-04' AS check_id, 'Invalid cst_gndr' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Male', 'Female', 'n/a');

-- Check for leading/trailing whitespace in names
SELECT 'DQ-05' AS check_id, 'Untrimmed cst_firstname or cst_lastname' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
   OR cst_lastname  != TRIM(cst_lastname);


-- ============================================================
-- 2. silver.crm_prd_info
-- ============================================================

-- Check for NULL product cost (should be 0 not NULL after ISNULL fix)
SELECT 'DQ-06' AS check_id, 'NULL prd_cost' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_prd_info
WHERE prd_cost IS NULL;

-- Check for negative product cost
SELECT 'DQ-07' AS check_id, 'Negative prd_cost' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_prd_info
WHERE prd_cost < 0;

-- Check product line only contains expected values
SELECT 'DQ-08' AS check_id, 'Invalid prd_line' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_prd_info
WHERE prd_line NOT IN ('Mountain', 'Road', 'Other Sales', 'Touring', 'n/a');

-- Check end date is never BEFORE start date
SELECT 'DQ-09' AS check_id, 'prd_end_dt before prd_start_dt' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_prd_info
WHERE prd_end_dt IS NOT NULL
  AND prd_end_dt < prd_start_dt;


-- ============================================================
-- 3. silver.crm_sales_details
-- ============================================================

-- Check order date is not after ship date
SELECT 'DQ-10' AS check_id, 'sls_order_dt after sls_ship_dt' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_sales_details
WHERE sls_order_dt IS NOT NULL
  AND sls_ship_dt  IS NOT NULL
  AND sls_order_dt > sls_ship_dt;

-- Check order date is not after due date
SELECT 'DQ-11' AS check_id, 'sls_order_dt after sls_due_dt' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_sales_details
WHERE sls_order_dt IS NOT NULL
  AND sls_due_dt   IS NOT NULL
  AND sls_order_dt > sls_due_dt;

-- Check sales = quantity * price
SELECT 'DQ-12' AS check_id, 'sls_sales != sls_quantity * sls_price' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price;

-- Check for zero or negative quantity
SELECT 'DQ-13' AS check_id, 'Non-positive sls_quantity' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_sales_details
WHERE sls_quantity <= 0 OR sls_quantity IS NULL;

-- Check for zero or negative price
SELECT 'DQ-14' AS check_id, 'Non-positive sls_price' AS check_name, COUNT(*) AS failed_rows
FROM silver.crm_sales_details
WHERE sls_price <= 0 OR sls_price IS NULL;


-- ============================================================
-- 4. silver.erp_cust_az12
-- ============================================================

-- Check no cid still starts with 'NAS' prefix
SELECT 'DQ-15' AS check_id, 'NAS prefix not removed from cid' AS check_name, COUNT(*) AS failed_rows
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';

-- Check no future birthdates remain
SELECT 'DQ-16' AS check_id, 'Future bdate not nulled' AS check_name, COUNT(*) AS failed_rows
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- Check gender only contains expected values
SELECT 'DQ-17' AS check_id, 'Invalid gen' AS check_name, COUNT(*) AS failed_rows
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male', 'Female', 'n/a');


-- ============================================================
-- 5. silver.erp_loc_a101
-- ============================================================

-- Check no hyphenated cid values remain
SELECT 'DQ-18' AS check_id, 'Hyphen not removed from cid' AS check_name, COUNT(*) AS failed_rows
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- Check no raw abbreviations remain (DE, US, USA should be expanded)
SELECT 'DQ-19' AS check_id, 'Unexpanded country code' AS check_name, COUNT(*) AS failed_rows
FROM silver.erp_loc_a101
WHERE cntry IN ('DE', 'US', 'USA');

-- Check no NULL or blank country values remain
SELECT 'DQ-20' AS check_id, 'NULL or blank cntry' AS check_name, COUNT(*) AS failed_rows
FROM silver.erp_loc_a101
WHERE cntry IS NULL OR TRIM(cntry) = '';


-- ============================================================
-- Summary: all checks in one result set
-- ============================================================
-- Re-run all checks above as a UNION to get a single pass/fail table.
-- Rows with failed_rows = 0 are PASS; anything > 0 is FAIL.
