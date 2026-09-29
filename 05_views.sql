USE ecommerce_segmentation;
 
-- ------------------------------------------------------------
-- View 1: RFM comparison — your calculated scores vs. dataset's given scores
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_rfm_comparison AS
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
    cv.rfm_score        AS rfm_score_given,
    cv.rfm_category      AS rfm_category_given
FROM rfm_scored r
JOIN customer_value cv ON r.customer_id = cv.customer_id;
 
-- ------------------------------------------------------------
-- View 2: Churn risk by loyalty tier
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_churn_by_loyalty_tier AS
SELECT
    ce.loyalty_tier,
    cv.churn_risk_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(cv.churn_risk_score), 2) AS avg_churn_risk_score
FROM customer_experience ce
JOIN customer_value cv ON ce.customer_id = cv.customer_id
GROUP BY ce.loyalty_tier, cv.churn_risk_category;
 
-- ------------------------------------------------------------
-- View 3: Churn risk by engagement level
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_churn_by_engagement AS
SELECT
    cv.engagement_level,
    ROUND(AVG(cv.churn_risk_score), 2) AS avg_churn_risk_score,
    COUNT(*) AS customer_count
FROM customer_value cv
GROUP BY cv.engagement_level;
 
-- ------------------------------------------------------------
-- View 4: High-value customers at high churn risk (retention priority list)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_retention_priority AS
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
WHERE cv.churn_risk_category IN ('High', 'Very High');
 
-- ------------------------------------------------------------
-- View 5: Churn risk by recency bucket
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_churn_by_recency AS
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
GROUP BY recency_bucket;
 
-- ------------------------------------------------------------
-- View 6: Full customer value detail (top CLV customers, drillable in Power BI)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_value_detail AS
SELECT
    c.customer_id,
    c.age_group,
    c.gender,
    c.country,
    c.city,
    cv.customer_lifetime_value_usd,
    cv.customer_profitability_usd,
    cv.clv_category,
    ce.loyalty_tier,
    sp.shopping_channel,
    sp.device_used
FROM customers c
JOIN customer_value cv ON c.customer_id = cv.customer_id
JOIN customer_experience ce ON c.customer_id = ce.customer_id
JOIN shopping_preferences sp ON c.customer_id = sp.customer_id;
 
-- ------------------------------------------------------------
-- View 7: CLV vs profitability by CLV category
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_clv_profitability_by_category AS
SELECT
    cv.clv_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(cv.customer_lifetime_value_usd), 2)   AS avg_clv,
    ROUND(AVG(cv.customer_acquisition_cost_usd), 2)  AS avg_acquisition_cost,
    ROUND(AVG(cv.customer_profitability_usd), 2)     AS avg_profitability
FROM customer_value cv
GROUP BY cv.clv_category;
 
-- ------------------------------------------------------------
-- View 8: Profitability by shopping channel and device
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_profitability_by_channel_device AS
SELECT
    sp.shopping_channel,
    sp.device_used,
    COUNT(*) AS customer_count,
    ROUND(AVG(cv.customer_profitability_usd), 2) AS avg_profitability,
    ROUND(AVG(cv.customer_lifetime_value_usd), 2) AS avg_clv
FROM shopping_preferences sp
JOIN customer_value cv ON sp.customer_id = cv.customer_id
GROUP BY sp.shopping_channel, sp.device_used;
 
-- ------------------------------------------------------------
-- View 9: CLV quintile / Pareto concentration
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_clv_quintile_concentration AS
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
GROUP BY clv_quintile;

CREATE OR REPLACE VIEW vw_churn_by_recency AS
SELECT
    CASE
        WHEN pb.days_since_last_purchase <= 30 THEN '0-30 days'
        WHEN pb.days_since_last_purchase <= 90 THEN '31-90 days'
        WHEN pb.days_since_last_purchase <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END AS recency_bucket,
    CASE
        WHEN pb.days_since_last_purchase <= 30 THEN 1
        WHEN pb.days_since_last_purchase <= 90 THEN 2
        WHEN pb.days_since_last_purchase <= 180 THEN 3
        ELSE 4
    END AS recency_sort,
    COUNT(*) AS customer_count,
    ROUND(AVG(cv.churn_risk_score), 2) AS avg_churn_risk_score
FROM purchase_behavior pb
JOIN customer_value cv ON pb.customer_id = cv.customer_id
GROUP BY recency_bucket, recency_sort;
 
 CREATE OR REPLACE VIEW vw_churn_by_satisfaction AS
SELECT
    sat.satisfaction_level,
    sat.satisfaction_sort,
    COUNT(*) AS customer_count,
    ROUND(AVG(sat.churn_risk_score), 2) AS avg_churn_risk_score
FROM (
    SELECT
        COALESCE(NULLIF(ce.satisfaction_level, ''), 'Unknown') AS satisfaction_level,
        CASE ce.satisfaction_level
            WHEN 'Very Dissatisfied' THEN 1
            WHEN 'Dissatisfied'      THEN 2
            WHEN 'Neutral'           THEN 3
            WHEN 'Satisfied'         THEN 4
            WHEN 'Very Satisfied'    THEN 5
            ELSE 6
        END AS satisfaction_sort,
        cv.churn_risk_score
    FROM customer_experience ce
    JOIN customer_value cv ON ce.customer_id = cv.customer_id
) sat
GROUP BY sat.satisfaction_level, sat.satisfaction_sort;
    
    
SELECT * FROM vw_churn_by_satisfaction ORDER BY satisfaction_sort;

CREATE OR REPLACE VIEW vw_customer_value_detail AS
SELECT
    c.customer_id,
    c.age_group,
    c.gender,
    c.country,
    c.city,
    cv.customer_lifetime_value_usd,
    cv.customer_acquisition_cost_usd,
    cv.customer_profitability_usd,
    cv.clv_category,
    cv.churn_risk_score,
    cv.churn_risk_category,
    cv.engagement_level,
    COALESCE(NULLIF(ce.loyalty_tier, ''), 'Unknown') AS loyalty_tier,
    ce.satisfaction_level,
    sp.shopping_channel,
    sp.device_used,
    pb.days_since_last_purchase
FROM customers c
JOIN customer_value cv ON c.customer_id = cv.customer_id
JOIN customer_experience ce ON c.customer_id = ce.customer_id
JOIN shopping_preferences sp ON c.customer_id = sp.customer_id
JOIN purchase_behavior pb ON c.customer_id = pb.customer_id;
-- ------------------------------------------------------------
-- Quick check: list all views created
-- ------------------------------------------------------------
SHOW FULL TABLES IN ecommerce_segmentation WHERE TABLE_TYPE = 'VIEW';