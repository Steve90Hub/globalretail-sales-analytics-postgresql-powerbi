Select "Quantity" as quant, count("Quantity")
from sales_transactions
group by quant
order by 2 desc

-- cHECK FOR NULL
select *
from sales_transactions
where transaction_no is null or transaction_date is null or product_no is null
or product_name is null or price is null or quantity is null or customer_no is null
or country is null

limit 20

Select "Price" 
from sales_transactions
limit 20;

-- Standardize to Lowercase (Best Long-term Solution)
-- Rename all columns to lowercase for consistency
ALTER TABLE sales_transactions RENAME COLUMN "TransactionNo" TO transaction_no;
ALTER TABLE sales_transactions RENAME COLUMN "Date" TO transaction_date;
ALTER TABLE sales_transactions RENAME COLUMN "ProductNo" TO product_no;
ALTER TABLE sales_transactions RENAME COLUMN "ProductName" TO product_name;
ALTER TABLE sales_transactions RENAME COLUMN "Price" TO price;
ALTER TABLE sales_transactions RENAME COLUMN "Quantity" TO quantity;
ALTER TABLE sales_transactions RENAME COLUMN "CustomerNo" TO customer_no;
ALTER TABLE sales_transactions RENAME COLUMN "Country" TO country;


-- Now you can use lowercase without quotes
SELECT price FROM sales_transactions LIMIT 5;

-- Basic overview (using proper column names)
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT transaction_no) as unique_transactions,
    COUNT(DISTINCT customer_no) as unique_customers,
    COUNT(DISTINCT product_no) as unique_products,
    MIN(transaction_date) as earliest_date,
    MAX(transaction_date) as latest_date
FROM sales_transactions;

-- Add revenue column
ALTER TABLE sales_transactions 
ADD COLUMN revenue DECIMAL(12,2);

-- Calculate revenue
UPDATE sales_transactions 
SET revenue = price * quantity;

-- 

-- Check for missing values in each column 
-- Zero missing values found

SELECT 
    'transaction_no' as column_name,
    COUNT(*) - COUNT(transaction_no) as missing_count,
    ROUND((COUNT(*) - COUNT(transaction_no)) * 100.0 / COUNT(*), 2) as missing_percentage
FROM sales_transactions
UNION ALL
SELECT 'transaction_date', COUNT(*) - COUNT(transaction_date), ROUND((COUNT(*) - COUNT(transaction_date)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'product_no', COUNT(*) - COUNT(product_no), ROUND((COUNT(*) - COUNT(product_no)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'product_name', COUNT(*) - COUNT(product_name), ROUND((COUNT(*) - COUNT(product_name)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'price', COUNT(*) - COUNT(price), ROUND((COUNT(*) - COUNT(price)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'quantity', COUNT(*) - COUNT(quantity), ROUND((COUNT(*) - COUNT(quantity)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'customer_no', COUNT(*) - COUNT(customer_no), ROUND((COUNT(*) - COUNT(customer_no)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'country', COUNT(*) - COUNT(country), ROUND((COUNT(*) - COUNT(country)) * 100.0 / COUNT(*), 2) FROM sales_transactions;

-- Check for duplicate transactions Phase 1 Step 2.3

SELECT 
    transaction_no,
    COUNT(*) as duplicate_count
FROM sales_transactions
GROUP BY transaction_no
HAVING COUNT(*) > 1
ORDER BY 2 ASC;

-- Check for potential duplicate transactions 
-- (same customer, product, date, quantity)
SELECT 
    customer_no,
    product_no,
	product_name,
	transaction_date,
    quantity,
	COUNT(*) as potential_duplicates
FROM sales_transactions
GROUP BY customer_no, product_no, product_name, transaction_date, quantity
HAVING COUNT(*) > 1;

-- Price outliers
SELECT 
    'Price Outliers' as metric,
    MIN(price) as min_value,
    MAX(price) as max_value,
    AVG(price) as avg_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) as q1,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) as q3
FROM sales_transactions;

-- Quantity outliers
SELECT 
    'Quantity Outliers' as metric,
    MIN(quantity) as min_value,
    MAX(quantity) as max_value,
    AVG(quantity) as avg_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantity) as q1,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantity) as q3
FROM sales_transactions;

-- Identify extreme outliers
SELECT *
FROM sales_transactions
WHERE price > (SELECT AVG(price) + 3 * STDDEV(price) FROM sales_transactions)
   OR quantity > (SELECT AVG(quantity) + 3 * STDDEV(quantity) FROM sales_transactions);


-- Check for negative prices or quantities
SELECT 
    COUNT(*) as negative_price_count
FROM sales_transactions
WHERE price < 0;

-- Check for zero quantity 
SELECT 
    COUNT(*) as zero_quantity_count
FROM sales_transactions
WHERE quantity = 0;

-- Check for negative quantity 
SELECT 
    COUNT(*) as negative_quantity_count
FROM sales_transactions
WHERE quantity < 0;

-- Check date range validity
SELECT 
    COUNT(*) as future_dates
FROM sales_transactions
WHERE transaction_date > CURRENT_DATE;

-- Check for unusual country names
SELECT 
    country,
    COUNT(*) as transaction_count
FROM sales_transactions
GROUP BY country
ORDER BY transaction_count DESC;

-- Create a view for customer transaction counts
CREATE VIEW customer_transaction_summary AS
SELECT 
    customer_no,
    COUNT(*) as transaction_count,
    SUM(revenue) as total_revenue,
    AVG(revenue) as avg_transaction_value,
    MIN(transaction_date) as first_transaction_date,
    MAX(transaction_date) as last_transaction_date
FROM sales_transactions
GROUP BY customer_no;

-- Add it directly to the main table
ALTER TABLE sales_transactions 
ADD COLUMN customer_transaction_count INTEGER;


-- Update the customer_transaction_count column to the sales_transaction table
WITH customer_counts AS (
    SELECT 
        transaction_no,
        COUNT(*) OVER (PARTITION BY customer_no) as txn_count
    FROM sales_transactions
)
UPDATE sales_transactions 
SET customer_transaction_count = customer_counts.txn_count
FROM customer_counts
WHERE sales_transactions.transaction_no = customer_counts.transaction_no;


-- Verify derived fields
SELECT 
    transaction_no,
    price,
    quantity,
    revenue,
    customer_no,
    customer_transaction_count
FROM sales_transactions
LIMIT 10;

-- Summary statistics for derived fields
SELECT 
    COUNT(*) as total_transactions,
    SUM(revenue) as total_revenue,
    AVG(revenue) as avg_revenue,
    MIN(revenue) as min_revenue,
    MAX(revenue) as max_revenue
FROM sales_transactions;


-- More on Data Validation Checks
-- Check for unrealistic price ranges (customize thresholds as needed) - None
SELECT 
    COUNT(*) as extremely_high_prices
FROM sales_transactions 
WHERE price > 10000;

-- Check for suspiciously large quantities - there are 106 suspiciously high quantities
SELECT 
    COUNT(*) as large_quantities
FROM sales_transactions 
WHERE quantity > 1000;

-- Verify revenue calculation is correct
SELECT 
    COUNT(*) as revenue_calculation_errors
FROM sales_transactions 
WHERE ABS(revenue - (price * quantity)) > 0.01;

-- Examine the high-quantity transactions in detail
SELECT 
    transaction_no,
    transaction_date,
    product_no,
    product_name,
    quantity,
    price,
    revenue,
    customer_no,
    country
FROM sales_transactions 
WHERE quantity > 1000
ORDER BY quantity DESC
LIMIT 20;

-- Distribution of high quantities
SELECT 
    CASE 
        WHEN quantity BETWEEN 1001 AND 2000 THEN '1001-2000'
        WHEN quantity BETWEEN 2001 AND 5000 THEN '2001-5000'
        WHEN quantity BETWEEN 5001 AND 10000 THEN '5001-10000'
        WHEN quantity > 10000 THEN '10000+'
    END as quantity_range,
    COUNT(*) as transaction_count,
    AVG(price) as avg_unit_price,
    SUM(revenue) as total_revenue
FROM sales_transactions 
WHERE quantity > 1000
GROUP BY 1
ORDER BY MIN(quantity);

-- Check if these are from specific customers (bulk buyers)
SELECT 
    customer_no,
    COUNT(*) as high_quantity_transactions,
    AVG(quantity) as avg_quantity,
    MAX(quantity) as max_quantity,
    SUM(revenue) as total_revenue
FROM sales_transactions 
WHERE quantity > 1000
GROUP BY customer_no
ORDER BY high_quantity_transactions DESC;


-- ===================================================================
-- PHASE 1: DATA QUALITY ASSESSMENT DOCUMENTATION QUERIES
-- ===================================================================

-- ===================================================================
-- (i) MISSING VALUES DETECTION
-- ===================================================================

-- Comprehensive missing values check across all columns
SELECT 
    'transaction_no' as column_name,
    COUNT(*) as total_records,
    COUNT(transaction_no) as non_null_records,
    COUNT(*) - COUNT(transaction_no) as missing_count,
    ROUND((COUNT(*) - COUNT(transaction_no)) * 100.0 / COUNT(*), 2) as missing_percentage
FROM sales_transactions
UNION ALL
SELECT 'transaction_date', COUNT(*), COUNT(transaction_date), COUNT(*) - COUNT(transaction_date), ROUND((COUNT(*) - COUNT(transaction_date)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'product_no', COUNT(*), COUNT(product_no), COUNT(*) - COUNT(product_no), ROUND((COUNT(*) - COUNT(product_no)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'product_name', COUNT(*), COUNT(product_name), COUNT(*) - COUNT(product_name), ROUND((COUNT(*) - COUNT(product_name)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'price', COUNT(*), COUNT(price), COUNT(*) - COUNT(price), ROUND((COUNT(*) - COUNT(price)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'quantity', COUNT(*), COUNT(quantity), COUNT(*) - COUNT(quantity), ROUND((COUNT(*) - COUNT(quantity)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'customer_no', COUNT(*), COUNT(customer_no), COUNT(*) - COUNT(customer_no), ROUND((COUNT(*) - COUNT(customer_no)) * 100.0 / COUNT(*), 2) FROM sales_transactions
UNION ALL
SELECT 'country', COUNT(*), COUNT(country), COUNT(*) - COUNT(country), ROUND((COUNT(*) - COUNT(country)) * 100.0 / COUNT(*), 2) FROM sales_transactions
ORDER BY missing_count DESC;


-- Summary of missing values
SELECT 
    CASE 
        WHEN (SELECT SUM(CASE WHEN transaction_no IS NULL THEN 1 ELSE 0 END + 
                         CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END +
                         CASE WHEN product_no IS NULL THEN 1 ELSE 0 END +
                         CASE WHEN product_name IS NULL THEN 1 ELSE 0 END +
                         CASE WHEN price IS NULL THEN 1 ELSE 0 END +
                         CASE WHEN quantity IS NULL THEN 1 ELSE 0 END +
                         CASE WHEN customer_no IS NULL THEN 1 ELSE 0 END +
                         CASE WHEN country IS NULL THEN 1 ELSE 0 END)
              FROM sales_transactions) = 0 
        THEN 'NO MISSING VALUES DETECTED'
        ELSE 'MISSING VALUES FOUND'
    END as missing_values_status;

-- ===================================================================
-- (ii) DUPLICATE TRANSACTIONS HANDLING
-- ===================================================================

-- Check for exact duplicate records (all columns identical)
WITH exact_duplicates AS (
    SELECT 
        transaction_no, transaction_date, product_no, product_name, 
        price, quantity, customer_no, country,
        COUNT(*) as duplicate_count,
        ROW_NUMBER() OVER (PARTITION BY transaction_no, transaction_date, product_no, product_name, 
                          price, quantity, customer_no, country ORDER BY transaction_no) as rn
    FROM sales_transactions
    GROUP BY transaction_no, transaction_date, product_no, product_name, 
             price, quantity, customer_no, country
    HAVING COUNT(*) > 1
)
SELECT 
    'Exact Duplicates' as duplicate_type,
    COUNT(*) as total_duplicate_records,
    COUNT(DISTINCT transaction_no) as unique_transaction_numbers_affected
FROM exact_duplicates;


-- Check for duplicate transaction numbers (same TransactionNo, different details)
SELECT 
    'Transaction Number Duplicates' as duplicate_type,
    COUNT(*) as transactions_with_duplicate_numbers,
    SUM(duplicate_count - 1) as extra_records_due_to_duplicates
FROM (
    SELECT 
        transaction_no,
        COUNT(*) as duplicate_count
    FROM sales_transactions
    GROUP BY transaction_no
    HAVING COUNT(*) > 1
) dup_txns;


-- Detailed view of transactions with duplicate numbers
SELECT 
    transaction_no,
    COUNT(*) as occurrence_count,
    COUNT(DISTINCT product_no) as unique_products,
    COUNT(DISTINCT customer_no) as unique_customers,
    MIN(transaction_date) as earliest_date,
    MAX(transaction_date) as latest_date
FROM sales_transactions
WHERE transaction_no IN (
    SELECT transaction_no
    FROM sales_transactions
    GROUP BY transaction_no
    HAVING COUNT(*) > 1
)
GROUP BY transaction_no
ORDER BY occurrence_count DESC
LIMIT 10;

-- Check for exact duplicate transactions (all fields identical)
SELECT 
    transaction_no,
    transaction_date,
    product_no,
    customer_no,
    price,
    quantity,
    COUNT(*) as duplicate_count
FROM sales_transactions
GROUP BY transaction_no, transaction_date, product_no, customer_no, price, quantity
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Check for duplicate transaction_no with different details
SELECT 
    transaction_no,
    COUNT(*) as occurrence_count,
    COUNT(DISTINCT product_no) as unique_products,
    COUNT(DISTINCT customer_no) as unique_customers,
    MIN(transaction_date) as earliest_date,
    MAX(transaction_date) as latest_date
FROM sales_transactions
GROUP BY transaction_no
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- View the actual duplicate records
SELECT *
FROM sales_transactions
WHERE transaction_no IN (
    SELECT transaction_no
    FROM sales_transactions
    GROUP BY transaction_no
    HAVING COUNT(*) > 1
)
ORDER BY transaction_no, product_no;

-- Clean Confirmed Duplicate Transactions
-- Create a clean table without duplicates
CREATE TABLE sales_transactions_clean AS
SELECT DISTINCT *
FROM sales_transactions;


-- Verify cleaning results
SELECT 
    'Original' as table_name,
    COUNT(*) as record_count
FROM sales_transactions
UNION ALL
SELECT 
    'Cleaned' as table_name,
    COUNT(*) as record_count
FROM sales_transactions_clean;

-- Find all transactions with negative quantities (returns)
SELECT 
    COUNT(*) as total_returns,
    COUNT(DISTINCT customer_no) as customers_with_returns,
    COUNT(DISTINCT product_no) as returned_products,
    SUM(quantity) as total_returned_quantity,
    SUM(revenue) as total_return_value,
    MIN(quantity) as largest_return_quantity,
    AVG(quantity) as avg_return_quantity
FROM sales_transactions
WHERE quantity < 0;

-- Detailed view of return transactions
SELECT 
    transaction_no,
    transaction_date,
    customer_no,
    product_no,
    product_name,
    quantity,
    price,
    revenue,
    country
FROM sales_transactions
WHERE quantity < 0
ORDER BY quantity ASC, transaction_date DESC;

-- Returns by customer
SELECT 
    customer_no,
    COUNT(*) as return_transactions,
    SUM(quantity) as total_returned_qty,
    SUM(revenue) as total_return_value
FROM sales_transactions
WHERE quantity < 0
GROUP BY customer_no
ORDER BY return_transactions DESC;

-- Handle Negative Quantities

-- Flag returns but keep them (recommended for business analysis)
ALTER TABLE sales_transactions_clean 
ADD COLUMN transaction_type VARCHAR(10) DEFAULT 'SALE';

UPDATE sales_transactions_clean 
SET transaction_type = 'RETURN'
WHERE quantity < 0;

-- Viewing my customer_transaction_count
select transaction_no, transaction_date, product_name, 
price, quantity, customer_no, country, revenue, customer_transaction_count
from sales_transactions_clean

-- ===============================================================
--PHASE 2
-- ===============================================================
/* Create comprehensive SQL scripts to answer these business questions: 
Customer Analytics 
○ Top 20 customers by total revenue 
○ Customer purchase frequency distribution
*/

-- ============================================================================
-- 1. CUSTOMER ANALYTICS
-- ============================================================================

-- 1.1: Top 20 Customers by Total Revenue
-- Purpose: Identify highest value customers for VIP programs and retention focus
SELECT 
    customer_no,
    COUNT(*) as total_transactions,
    SUM(quantity) as total_items_purchased,
    SUM(revenue) as total_revenue,
    AVG(revenue) as avg_transaction_value,
    MIN(transaction_date) as first_purchase_date,
    MAX(transaction_date) as last_purchase_date,
    MAX(transaction_date) - MIN(transaction_date) as customer_lifespan_days,
    COUNT(DISTINCT product_no) as unique_products_purchased
FROM sales_transactions_clean
GROUP BY customer_no
ORDER BY total_revenue DESC
LIMIT 20;

-- 1.2: Customer Purchase Frequency Distribution
-- Purpose: Understand customer behavior patterns and segment customers
SELECT 
    frequency_bucket,
    customer_count,
    percentage_of_customers,
    total_revenue_in_bucket,
    avg_revenue_per_customer
FROM (
    SELECT 
        CASE 
            WHEN transaction_count = 1 THEN '1 Transaction (One-time)'
            WHEN transaction_count BETWEEN 2 AND 5 THEN '2-5 Transactions (Occasional)'
            WHEN transaction_count BETWEEN 6 AND 15 THEN '6-15 Transactions (Regular)'
            WHEN transaction_count BETWEEN 16 AND 50 THEN '16-50 Transactions (Frequent)'
            WHEN transaction_count > 50 THEN '50+ Transactions (VIP)'
        END as frequency_bucket,
        COUNT(*) as customer_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage_of_customers,
        SUM(total_revenue) as total_revenue_in_bucket,
        ROUND(AVG(total_revenue), 2) as avg_revenue_per_customer
    FROM (
        SELECT 
            customer_no,
            COUNT(*) as transaction_count,
            SUM(revenue) as total_revenue
        FROM sales_transactions_clean
        GROUP BY customer_no
    ) customer_summary
    GROUP BY frequency_bucket
) freq_analysis
ORDER BY 
    CASE frequency_bucket
        WHEN '1 Transaction (One-time)' THEN 1
        WHEN '2-5 Transactions (Occasional)' THEN 2
        WHEN '6-15 Transactions (Regular)' THEN 3
        WHEN '16-50 Transactions (Frequent)' THEN 4
        WHEN '50+ Transactions (VIP)' THEN 5
    END;


-- 1.3: Customer Segmentation Analysis (RFM-style)
-- Purpose: Advanced customer segmentation for marketing strategies

WITH customer_metrics AS (
    SELECT 
        customer_no,
        MAX(transaction_date) as last_purchase_date,
        CURRENT_DATE - MAX(transaction_date) as recency_days,
        COUNT(*) as frequency,
        SUM(revenue) as monetary_value,
        AVG(revenue) as avg_order_value
    FROM sales_transactions_clean
    GROUP BY customer_no
),
customer_scores AS (
    SELECT 
        customer_no,
        recency_days,
        frequency,
        monetary_value,
        avg_order_value,
        NTILE(5) OVER (ORDER BY recency_days DESC) as recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC) as frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) as monetary_score
    FROM customer_metrics
)
SELECT 
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost Customers'
        ELSE 'Potential Loyalists'
    END as customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(monetary_value), 2) as avg_customer_value,
    ROUND(AVG(frequency), 1) as avg_purchase_frequency,
    ROUND(AVG(recency_days), 1) as avg_days_since_last_purchase
FROM customer_scores
GROUP BY customer_segment
ORDER BY customer_count DESC;


-- ============================================================================
-- 2. PRODUCT PERFORMANCE ANALYSIS
-- ============================================================================

-- 2.1: Best and Worst Performing Products by Revenue
-- Purpose: Identify star products and underperformers for inventory management
-- Top 20 Products by Revenue
SELECT 
    'TOP PERFORMERS' as category,
    product_no,
    product_name,
    COUNT(*) as total_transactions,
    SUM(quantity) as total_quantity_sold,
    SUM(revenue) as total_revenue,
    AVG(price) as avg_selling_price,
    AVG(revenue) as avg_transaction_value,
    COUNT(DISTINCT customer_no) as unique_customers
FROM sales_transactions_clean
GROUP BY product_no, product_name
ORDER BY total_revenue DESC
LIMIT 20;

-- Bottom 20 Products by Revenue (excluding products with very low transaction count)
SELECT 
    'BOTTOM PERFORMERS' as category,
    product_no,
    product_name,
    COUNT(*) as total_transactions,
    SUM(quantity) as total_quantity_sold,
    SUM(revenue) as total_revenue,
    AVG(price) as avg_selling_price,
    AVG(revenue) as avg_transaction_value,
    COUNT(DISTINCT customer_no) as unique_customers
FROM sales_transactions_sales
GROUP BY product_no, product_name
HAVING COUNT(*) >= 5  -- Only products with at least 5 transactions
ORDER BY total_revenue ASC
LIMIT 20;

-- 2.2: Best and Worst Performing Products by Quantity
-- Top Products by Quantity Sold
SELECT 
    'HIGH VOLUME' as category,
    product_no,
    product_name,
    SUM(quantity) as total_quantity_sold,
    SUM(revenue) as total_revenue,
    COUNT(*) as total_transactions,
    ROUND(SUM(revenue)/SUM(quantity), 2) as revenue_per_unit,
    COUNT(DISTINCT customer_no) as unique_customers
FROM sales_transactions_clean
WHERE quantity > 0  -- Exclude returns
GROUP BY product_no, product_name
ORDER BY total_quantity_sold DESC
LIMIT 20;

-- 2.3: Products with Highest/Lowest Average Transaction Values
-- Highest Average Transaction Value
SELECT 
    'HIGH VALUE' as category,
    product_no,
    product_name,
    COUNT(*) as total_transactions,
    ROUND(AVG(revenue), 2) as avg_transaction_value,
    SUM(revenue) as total_revenue,
    SUM(quantity) as total_quantity_sold,
    ROUND(AVG(price)::numeric, 2) as avg_unit_price
FROM sales_transactions_clean
GROUP BY product_no, product_name
HAVING COUNT(*) >= 10  -- At least 10 transactions for statistical significance
ORDER BY avg_transaction_value DESC
LIMIT 15;

-- Lowest Average Transaction Value
SELECT 
    'LOW VALUE' as category,
    product_no,
    product_name,
    COUNT(*) as total_transactions,
    ROUND(AVG(revenue), 2) as avg_transaction_value,
    SUM(revenue) as total_revenue,
    SUM(quantity) as total_quantity_sold,
    ROUND(AVG(price)::numeric, 2) as avg_unit_price
FROM sales_transactions
GROUP BY product_no, product_name
HAVING COUNT(*) >= 10  -- At least 10 transactions for statistical significance
ORDER BY avg_transaction_value ASC
LIMIT 15;

-- 2.4: Product Performance Trends Over Time
-- Monthly Product Performance Trends (Top 10 Products)
WITH top_products AS (
    SELECT product_no, product_name
    FROM sales_transactions
    GROUP BY product_no, product_name
    ORDER BY SUM(revenue) DESC
    LIMIT 5  -- Reduced to 5 for cleaner visualization
),
monthly_trends AS (
    SELECT 
        st.product_no,
        st.product_name,
        EXTRACT(YEAR FROM st.transaction_date) as year,
        EXTRACT(MONTH FROM st.transaction_date) as month_num,
        TO_CHAR(st.transaction_date, 'YYYY-MM') as month_label,
        TO_CHAR(st.transaction_date, 'Mon YYYY') as formatted_month,
        SUM(st.revenue) as monthly_revenue,
        SUM(st.quantity) as monthly_quantity,
        COUNT(*) as monthly_transactions
    FROM sales_transactions st
    INNER JOIN top_products tp ON st.product_no = tp.product_no
    GROUP BY st.product_no, st.product_name, 
             EXTRACT(YEAR FROM st.transaction_date), 
             EXTRACT(MONTH FROM st.transaction_date),
             TO_CHAR(st.transaction_date, 'YYYY-MM'),
             TO_CHAR(st.transaction_date, 'Mon YYYY')
)
SELECT 
    product_no,
    product_name,
    year,
    month_num,
    month_label,           -- Use this for X-axis: 2023-01, 2023-02, etc.
    formatted_month,       -- Or use this for X-axis: Jan 2023, Feb 2023, etc.
    monthly_revenue,
    monthly_quantity,
    monthly_transactions,
    LAG(monthly_revenue) OVER (PARTITION BY product_no ORDER BY year, month_num) as prev_month_revenue,
    CASE 
        WHEN LAG(monthly_revenue) OVER (PARTITION BY product_no ORDER BY year, month_num) IS NOT NULL 
        THEN ROUND(((monthly_revenue - LAG(monthly_revenue) OVER (PARTITION BY product_no ORDER BY year, month_num)) 
                   / LAG(monthly_revenue) OVER (PARTITION BY product_no ORDER BY year, month_num)) * 100, 2)
        ELSE NULL 
    END as revenue_growth_percentage
FROM monthly_trends
ORDER BY product_no, year, month_num;

-- ============================================================================
-- 3. SALES PERFORMANCE ANALYSIS
-- ============================================================================

-- 3.1: Yearly Sales Trends
-- Purpose: Understand business growth and seasonal patterns
SELECT 
    EXTRACT(YEAR FROM transaction_date) as year,
    COUNT(*) as total_transactions,
    SUM(quantity) as total_items_sold,
    SUM(revenue) as total_revenue,
    AVG(revenue) as avg_transaction_value,
    COUNT(DISTINCT customer_no) as unique_customers,
    COUNT(DISTINCT product_no) as unique_products_sold,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_no), 2) as revenue_per_customer
FROM sales_transactions
GROUP BY EXTRACT(YEAR FROM transaction_date)
ORDER BY year;

-- 3.2: Quarterly Sales Trends with Growth Analysis
WITH quarterly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM transaction_date) as year,
        EXTRACT(QUARTER FROM transaction_date) as quarter,
        COUNT(*) as total_trnx,
        SUM(revenue) as total_revenue,
        COUNT(DISTINCT customer_no) as unique_customers
    FROM sales_transactions_clean
    GROUP BY EXTRACT(YEAR FROM transaction_date), EXTRACT(QUARTER FROM transaction_date)
)
SELECT 
    year,
    quarter,
    CONCAT(year, '-Q', quarter) as period,
    total_trnx,
    total_revenue,
    unique_customers,
    LAG(total_revenue) OVER (ORDER BY year, quarter) as prev_quarter_revenue,
    CASE 
        WHEN LAG(total_revenue) OVER (ORDER BY year, quarter) IS NOT NULL 
        THEN ROUND(((total_revenue - LAG(total_revenue) OVER (ORDER BY year, quarter)) 
                   / LAG(total_revenue) OVER (ORDER BY year, quarter)) * 100, 2)
        ELSE NULL 
    END as quarter_over_quarter_growth_pct
FROM quarterly_sales
ORDER BY year, quarter;

-- 3.3: Running Totals and Moving Averages
-- Daily Sales with Running Totals and 7-day Moving Average
WITH daily_sales AS (
    SELECT 
        transaction_date,
        COUNT(*) as daily_trnx,
        SUM(revenue) as daily_revenue,
        COUNT(DISTINCT customer_no) as daily_unique_customers
    FROM sales_transactions_clean
    GROUP BY transaction_date
)
SELECT 
    transaction_date,
    daily_trnx,
    daily_revenue,
    daily_unique_customers,
    SUM(daily_revenue) OVER (ORDER BY transaction_date) as running_total_revenue,
    AVG(daily_revenue) OVER (
        ORDER BY transaction_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as seven_day_moving_avg_revenue,
    AVG(daily_trnx) OVER (
        ORDER BY transaction_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as seven_day_moving_avg_trnx
FROM daily_sales
ORDER BY transaction_date;

-- Monthly Running Totals and 3-Month Moving Average
WITH monthly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM transaction_date) as year,
        EXTRACT(MONTH FROM transaction_date) as month_num,
        TO_CHAR(transaction_date, 'YYYY-MM') as month_label,
        TO_CHAR(transaction_date, 'Mon YYYY') as formatted_month,
        SUM(revenue) as monthly_revenue,
        COUNT(*) as monthly_transactions,
        COUNT(DISTINCT customer_no) as monthly_customers
    FROM sales_transactions_clean
    GROUP BY EXTRACT(YEAR FROM transaction_date), 
             EXTRACT(MONTH FROM transaction_date),
             TO_CHAR(transaction_date, 'YYYY-MM'),
             TO_CHAR(transaction_date, 'Mon YYYY')
)
SELECT 
    year,
    month_num,
    month_label,
    formatted_month,
    ROUND(monthly_revenue, 2) as monthly_revenue,
    monthly_transactions,
    monthly_customers,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY year, month_num), 2) as running_total_revenue,
    ROUND(AVG(monthly_revenue) OVER (
        ORDER BY year, month_num 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) as three_month_moving_avg_revenue
FROM monthly_sales
ORDER BY year, month_num;


-- ============================================================================
-- 4. GEOGRAPHIC ANALYSIS
-- ============================================================================

-- 4.1: Country-wise Sales Performance Ranking
-- Purpose: Identify best and worst performing markets for expansion decisions
SELECT 
    country,
    COUNT(*) as total_trnx,
    SUM(quantity) as total_items_sold,
    SUM(revenue) as total_rev,
    COUNT(DISTINCT customer_no) as unique_customers,
    COUNT(DISTINCT product_no) as unique_products_sold,
    ROUND(AVG(revenue), 2) as avg_trnx_value,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_no), 2) as rev_per_customer,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT customer_no), 2) as trnx_per_customer,
    RANK() OVER (ORDER BY SUM(revenue) DESC) as revenue_rank,
    RANK() OVER (ORDER BY COUNT(DISTINCT customer_no) DESC) as cust_base_rank,
    RANK() OVER (ORDER BY AVG(revenue) DESC) as avg_trnx_value_rank
FROM sales_transactions_clean
GROUP BY country
ORDER BY total_rev DESC;


-- 4.2: Market Penetration Analysis by Country
-- Purpose: Understand market depth vs breadth for strategic planning
WITH country_metrics AS (
    SELECT 
        country,
        COUNT(*) as tot_trnx,
        SUM(revenue) as tot_rev,
        COUNT(DISTINCT customer_no) as unq_cust,
        COUNT(DISTINCT product_no) as unq_prod_sold,
        ROUND(AVG(revenue), 2) as avg_trnx_val
    FROM sales_transactions_clean
    GROUP BY country
),
market_totals AS (
    SELECT 
        COUNT(*) as global_trnx,  		                    -- Direct count from base table
        SUM(revenue) as global_rev,                         -- Direct sum from base table
        COUNT(DISTINCT customer_no) as global_cust,         -- Direct count from base table
        COUNT(DISTINCT product_no) as tot_unq_prod          -- Direct count from base table
    FROM sales_transactions_clean                           -- Query the base table, not CTEs
)
SELECT 
    cm.country,
    cm.tot_trnx,
    ROUND(cm.tot_rev, 2) as tot_rev,
    cm.unq_cust,
    cm.unq_prod_sold,
    cm.avg_trnx_val,
    -- Market Share Metrics
    ROUND((cm.tot_rev / mt.global_rev) * 100, 2) as rev_mkt_share_pct,
    ROUND((cm.unq_cust::DECIMAL / mt.global_cust) * 100, 2) as cust_mkt_share_pct,
    ROUND((cm.tot_trnx::DECIMAL / mt.global_trnx) * 100, 2) as trnx_mkt_share_pct,
    -- Market Penetration Metrics  
    ROUND((cm.unq_prod_sold::DECIMAL / mt.tot_unq_prod) * 100, 2) as prod_penetratn_pct,
    ROUND(cm.tot_rev / cm.unq_cust, 2) as rev_per_cust,
    ROUND(cm.tot_trnx::DECIMAL / cm.unq_cust, 2) as trnx_per_cust,
    -- Market Maturity Classification
    CASE 
        WHEN cm.tot_rev / mt.global_rev > 0.15 THEN 'Mature Market'
        WHEN cm.tot_rev / mt.global_rev BETWEEN 0.05 AND 0.15 THEN 'Growing Market'
        WHEN cm.tot_rev / mt.global_rev BETWEEN 0.01 AND 0.05 THEN 'Emerging Market'
        ELSE 'Developing Market'
    END as mkt_class
FROM country_metrics cm
CROSS JOIN market_totals mt
ORDER BY cm.tot_rev DESC;


-- 4.3: Geographic Growth Analysis (Time-based)
-- Country performance over time to identify growth trends
-- 4.3: Geographic Growth Analysis (Time-based)
-- Country performance over time to identify growth trends
WITH country_monthly AS (
    SELECT 
        country,
        EXTRACT(YEAR FROM transaction_date) as year,
        EXTRACT(MONTH FROM transaction_date) as month_num,
        TO_CHAR(transaction_date, 'YYYY-MM') as month_label,
        SUM(revenue) as monthly_revenue,
        COUNT(DISTINCT customer_no) as monthly_customers
    FROM sales_transactions_clean
    GROUP BY country, 
             EXTRACT(YEAR FROM transaction_date), 
             EXTRACT(MONTH FROM transaction_date),
             TO_CHAR(transaction_date, 'YYYY-MM')
),
country_growth AS (
    SELECT 
        country,
        year,
        month_num,
        month_label,
        monthly_revenue,
        monthly_customers,
        LAG(monthly_revenue) OVER (PARTITION BY country ORDER BY year, month_num) as prev_month_revenue,
        FIRST_VALUE(monthly_revenue) OVER (PARTITION BY country ORDER BY year, month_num) as first_month_revenue,
        MAX(monthly_revenue) OVER (PARTITION BY country) as max_monthly_revenue
    FROM country_monthly
)
SELECT 
    country,
    COUNT(*) as months_active,
    ROUND(SUM(monthly_revenue), 2) as total_revenue,
    ROUND(AVG(monthly_revenue), 2) as avg_monthly_revenue,
    ROUND(MAX(monthly_revenue), 2) as peak_monthly_revenue,
    ROUND(MIN(monthly_revenue), 2) as lowest_monthly_revenue,
    -- Growth metrics (using MAX to get the same value for each country group)
    CASE 
        WHEN MAX(first_month_revenue) > 0 
        THEN ROUND(((MAX(max_monthly_revenue) - MAX(first_month_revenue)) / MAX(first_month_revenue)) * 100, 2)
        ELSE NULL 
    END as total_growth_percentage,
    ROUND(STDDEV(monthly_revenue), 2) as revenue_volatility
FROM country_growth
GROUP BY country
HAVING COUNT(*) >= 3  -- At least 3 months of data
ORDER BY total_revenue DESC;









