CREATE DATABASE IF NOT EXISTS ecommerce_segmentation;
USE ecommerce_segmentation;

-- Customer Table
CREATE TABLE IF NOT EXISTS customers (
    customer_id      VARCHAR(20) PRIMARY KEY,
    age              INT,
    age_group        VARCHAR(20),
    gender           VARCHAR(20),
    country          VARCHAR(50),
    city             VARCHAR(50),
    income_bracket   VARCHAR(30),
    education_level  VARCHAR(30),
    employment_type  VARCHAR(30),
    marital_status   VARCHAR(20)
);

-- Purchase behavior
CREATE TABLE IF NOT EXISTS purchase_behavior (
    customer_id                VARCHAR(20) PRIMARY KEY,
    tenure_months               INT,
    total_purchases             INT,
    avg_order_value_usd         DECIMAL(10,2),
    total_spent_usd             DECIMAL(12,2),
    purchase_frequency          DECIMAL(6,2),
    days_since_last_purchase    INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
 
-- Shopping preferences
CREATE TABLE IF NOT EXISTS shopping_preferences (
    customer_id            VARCHAR(20) PRIMARY KEY,
    preferred_category_1     VARCHAR(50),
    preferred_category_2     VARCHAR(50),
    preferred_category_3     VARCHAR(50),
    shopping_channel         VARCHAR(30),
    device_used              VARCHAR(30),
    payment_method           VARCHAR(30),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
 
-- Customer experience
CREATE TABLE IF NOT EXISTS customer_experience (
    customer_id         VARCHAR(20) PRIMARY KEY,
    return_count          INT,
    complaint_count       INT,
    satisfaction_score    DECIMAL(4,2),
    satisfaction_level    VARCHAR(20),
    loyalty_tier          VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
 
-- Digital engagement
CREATE TABLE IF NOT EXISTS digital_engagement (
    customer_id            VARCHAR(20) PRIMARY KEY,
    email_open_rate          DECIMAL(5,2),
    click_through_rate       DECIMAL(5,2),
    conversion_rate          DECIMAL(5,2),
    social_media_presence    VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
 
-- Customer value, RFM & risk (kept from source dataset for comparison
-- against your own SQL-calculated RFM/churn logic)
CREATE TABLE IF NOT EXISTS customer_value (
    customer_id                     VARCHAR(20) PRIMARY KEY,
    customer_lifetime_value_usd       DECIMAL(12,2),
    customer_acquisition_cost_usd     DECIMAL(10,2),
    customer_profitability_usd        DECIMAL(12,2),
    recency_score                     INT,
    frequency_score                   INT,
    monetary_score                    INT,
    rfm_score                         VARCHAR(10),
    churn_risk_score                  DECIMAL(5,2),
    customer_health_score             DECIMAL(5,2),
    customer_value_category           VARCHAR(30),
    activity_status                   VARCHAR(20),
    health_status                     VARCHAR(20),
    churn_risk_category               VARCHAR(20),
    rfm_category                      VARCHAR(30),
    profitability_category            VARCHAR(30),
    engagement_level                  VARCHAR(20),
    behavior_segment                  VARCHAR(30),
    device_preference                 VARCHAR(30),
    clv_category                      VARCHAR(30),
    customer_segment                  VARCHAR(30),
    segment_category                  VARCHAR(30),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);