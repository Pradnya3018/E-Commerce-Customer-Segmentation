USE ecommerce_segmentation;
 
-- ============================================================
-- SECTION 1: RFM — recompute from raw data, compare to dataset's given scores
-- ============================================================
 
-- 1a. Recompute Recency, Frequency, Monetary scores (1-5, 5 = best) using NTILE
--     Recency: fewer days_since_last_purchase = better = higher score
--     Frequency: more total_purchases = better = higher score
--     Monetary: more total_spent_usd = better = higher score
WITH rfm_raw AS (
    SELECT
        c.customer_id,
        pb.days_since_last_purchase,
        pb.total_purchases,
        pb.total_spent_usd
    FROM customers c
    JOIN purchase_behavior pb ON c.customer_id = pb.customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        -- lower days_since_last_purchase -> higher recency score
        6 - NTILE(5) OVER (ORDER BY days_since_last_purchase) AS recency_score_calc,
        NTILE(5) OVER (ORDER BY total_purchases)              AS frequency_score_calc,
        NTILE(5) OVER (ORDER BY total_spent_usd)               AS monetary_score_calc
    FROM rfm_raw
)
SELECT
    r.customer_id,
    r.recency_score_calc,
    r.frequency_score_calc,
    r.monetary_score_calc,
    (r.recency_score_calc + r.frequency_score_calc + r.monetary_score_calc) AS rfm_total_calc,
    cv.recency_score   AS recency_score_given,
    cv.frequency_score AS frequency_score_given,
    cv.monetary_score  AS monetary_score_given,
    cv.rfm_score        AS rfm_score_given
FROM rfm_scored r
JOIN customer_value cv ON r.customer_id = cv.customer_id
LIMIT 50;
 
-- 1b. Compare distributions: does your calculated RFM roughly agree with the given labels?
WITH rfm_raw AS (
    SELECT
        c.customer_id,
        pb.days_since_last_purchase,
        pb.total_purchases,
        pb.total_spent_usd
    FROM customers c
    JOIN purchase_behavior pb ON c.customer_id = pb.customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        (6 - NTILE(5) OVER (ORDER BY days_since_last_purchase))
        + NTILE(5) OVER (ORDER BY total_purchases)
        + NTILE(5) OVER (ORDER BY total_spent_usd) AS rfm_total_calc
    FROM rfm_raw
)
SELECT
    cv.rfm_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(r.rfm_total_calc), 2) AS avg_calculated_rfm_score
FROM rfm_scored r
JOIN customer_value cv ON r.customer_id = cv.customer_id
GROUP BY cv.rfm_category
ORDER BY avg_calculated_rfm_score DESC;
 
-- ============================================================
-- SECTION 2: Churn risk analysis
-- ============================================================
 
-- 2a. Churn risk by loyalty tier — are loyal customers actually lower risk?
SELECT
    ce.loyalty_tier,
    cv.churn_risk_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(cv.churn_risk_score), 2) AS avg_churn_risk_score
FROM customer_experience ce
JOIN customer_value cv ON ce.customer_id = cv.customer_id
GROUP BY ce.loyalty_tier, cv.churn_risk_category
ORDER BY ce.loyalty_tier, avg_churn_risk_score DESC;
 
-- 2b. Churn risk vs. engagement level — does low engagement predict churn risk?
SELECT
    cv.engagement_level,
    ROUND(AVG(cv.churn_risk_score), 2) AS avg_churn_risk_score,
    COUNT(*) AS customer_count
FROM customer_value cv
GROUP BY cv.engagement_level
ORDER BY avg_churn_risk_score DESC;
 
-- 2c. High-value customers at high churn risk — priority retention list
SELECT
    c.customer_id,
    cv.customer_lifetime_value_usd,
    cv.churn_risk_score,
    cv.churn_risk_category,
    ce.loyalty_tier,
    ce.satisfaction_level
FROM customers c
JOIN customer_value cv ON c.customer_id = cv.customer_id
JOIN customer_experience ce ON c.customer_id = ce.customer_id
WHERE cv.churn_risk_category IN ('High', 'Very High')
ORDER BY cv.customer_lifetime_value_usd DESC
LIMIT 20;
 
-- 2d. Churn risk by days since last purchase (recency) — data-driven threshold,
--     similar approach to your earlier 75th-percentile churn project
SELECT
    CASE
        WHEN pb.days_since_last_purchase <= 30 THEN '0-30 days'
        WHEN pb.days_since_last_purchase <= 90 THEN '31-90 days'
        WHEN pb.days_since_last_purchase <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END AS recency_bucket,
    COUNT(*) AS customer_count,
    ROUND(AVG(cv.churn_risk_score), 2) AS avg_churn_risk_score
FROM purchase_behavior pb
JOIN customer_value cv ON pb.customer_id = cv.customer_id
GROUP BY recency_bucket
ORDER BY MIN(pb.days_since_last_purchase);
 
-- ============================================================
-- SECTION 3: CLV & profitability
-- ============================================================
 
-- 3a. Top 20 customers by CLV
SELECT
    c.customer_id,
    cv.customer_lifetime_value_usd,
    cv.customer_profitability_usd,
    cv.clv_category,
    ce.loyalty_tier,
    sp.shopping_channel
FROM customers c
JOIN customer_value cv ON c.customer_id = cv.customer_id
JOIN customer_experience ce ON c.customer_id = ce.customer_id
JOIN shopping_preferences sp ON c.customer_id = sp.customer_id
ORDER BY cv.customer_lifetime_value_usd DESC
LIMIT 20;
 
-- 3b. CLV vs profitability by category — which CLV tiers are actually profitable?
SELECT
    cv.clv_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(cv.customer_lifetime_value_usd), 2)   AS avg_clv,
    ROUND(AVG(cv.customer_acquisition_cost_usd), 2)  AS avg_acquisition_cost,
    ROUND(AVG(cv.customer_profitability_usd), 2)     AS avg_profitability
FROM customer_value cv
GROUP BY cv.clv_category
ORDER BY avg_clv DESC;
 
-- 3c. Profitability by shopping channel and device — where's the profitable traffic coming from?
SELECT
    sp.shopping_channel,
    sp.device_used,
    COUNT(*) AS customer_count,
    ROUND(AVG(cv.customer_profitability_usd), 2) AS avg_profitability,
    ROUND(AVG(cv.customer_lifetime_value_usd), 2) AS avg_clv
FROM shopping_preferences sp
JOIN customer_value cv ON sp.customer_id = cv.customer_id
GROUP BY sp.shopping_channel, sp.device_used
ORDER BY avg_profitability DESC;
 
-- 3d. Revenue/value concentration — what % of total CLV comes from the top 20% of customers?
--     (classic Pareto / 80-20 check, good talking point for a value-segmentation project)
WITH ranked AS (
    SELECT
        customer_id,
        customer_lifetime_value_usd,
        NTILE(5) OVER (ORDER BY customer_lifetime_value_usd DESC) AS clv_quintile
    FROM customer_value
)
SELECT
    clv_quintile,
    COUNT(*) AS customer_count,
    ROUND(SUM(customer_lifetime_value_usd), 2) AS total_clv,
    ROUND(SUM(customer_lifetime_value_usd) * 100.0 /
        (SELECT SUM(customer_lifetime_value_usd) FROM customer_value), 2) AS pct_of_total_clv
FROM ranked
GROUP BY clv_quintile
ORDER BY clv_quintile;
 