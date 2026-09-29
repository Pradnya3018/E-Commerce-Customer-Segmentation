
USE ecommerce_segmentation;
 
INSERT INTO customers
    (customer_id, age, age_group, gender, country, city,
     income_bracket, education_level, employment_type, marital_status)
SELECT
    customer_id, age, age_group, gender, country, city,
    income_bracket, education_level, employment_type, marital_status
FROM staging_customers;
 
INSERT INTO purchase_behavior
    (customer_id, tenure_months, total_purchases, avg_order_value_usd,
     total_spent_usd, purchase_frequency, days_since_last_purchase)
SELECT
    customer_id, tenure_months, total_purchases, avg_order_value_usd,
    total_spent_usd, purchase_frequency, days_since_last_purchase
FROM staging_customers;
 
INSERT INTO shopping_preferences
    (customer_id, preferred_category_1, preferred_category_2, preferred_category_3,
     shopping_channel, device_used, payment_method)
SELECT
    customer_id, preferred_category_1, preferred_category_2, preferred_category_3,
    shopping_channel, device_used, payment_method
FROM staging_customers;
 
INSERT INTO customer_experience
    (customer_id, return_count, complaint_count, satisfaction_score,
     satisfaction_level, loyalty_tier)
SELECT
    customer_id, return_count, complaint_count, satisfaction_score,
    satisfaction_level, loyalty_tier
FROM staging_customers;
 
INSERT INTO digital_engagement
    (customer_id, email_open_rate, click_through_rate, conversion_rate, social_media_presence)
SELECT
    customer_id, email_open_rate, click_through_rate, conversion_rate, social_media_presence
FROM staging_customers;
 
INSERT INTO customer_value
    (customer_id, customer_lifetime_value_usd, customer_acquisition_cost_usd,
     customer_profitability_usd, recency_score, frequency_score, monetary_score,
     rfm_score, churn_risk_score, customer_health_score, customer_value_category,
     activity_status, health_status, churn_risk_category, rfm_category,
     profitability_category, engagement_level, behavior_segment,
     device_preference, clv_category, customer_segment, segment_category)
SELECT
    customer_id, customer_lifetime_value_usd, customer_acquisition_cost_usd,
    customer_profitability_usd, recency_score, frequency_score, monetary_score,
    rfm_score, churn_risk_score, customer_health_score, customer_value_category,
    activity_status, health_status, churn_risk_category, rfm_category,
    profitability_category, engagement_level, behavior_segment,
    device_preference, clv_category, customer_segment, segment_category
FROM staging_customers;
 
-- Verify row counts match across all tables
SELECT 'staging_customers' AS table_name, COUNT(*) AS row_count FROM staging_customers
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'purchase_behavior', COUNT(*) FROM purchase_behavior
UNION ALL
SELECT 'shopping_preferences', COUNT(*) FROM shopping_preferences
UNION ALL
SELECT 'customer_experience', COUNT(*) FROM customer_experience
UNION ALL
SELECT 'digital_engagement', COUNT(*) FROM digital_engagement
UNION ALL
SELECT 'customer_value', COUNT(*) FROM customer_value;
 
-- Once verified, you can drop the staging table:
-- DROP TABLE staging_customers;