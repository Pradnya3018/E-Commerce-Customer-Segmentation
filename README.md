# E-Commerce Customer Segmentation — SQL & Power BI Project
 
A MySQL + Power BI analysis of a 50,000-customer e-commerce dataset, covering
RFM segmentation, churn risk, customer lifetime value (CLV), and
profitability. Built to practice end-to-end analytics: raw CSV → cleaned
relational schema → SQL analysis → validated RFM logic → Power BI dashboard.
 
## Dataset
 
[E-Commerce Customer Segmentation Dataset 2026](https://www.kaggle.com/) (Kaggle)
— 50,000 customers, 53 features covering demographics, purchase behavior,
RFM scores, churn risk, CLV, profitability, loyalty tiers, and engagement
metrics.
 
## Pipeline
 
1. **Python (pandas)** — loads the raw CSV, cleans column names, drops
   duplicates, trims whitespace, and pushes the result into a MySQL staging
   table. See `02_load_data.py`.
2. **MySQL schema** — the staging table is split into 6 normalized tables
   (`customers`, `purchase_behavior`, `shopping_preferences`,
   `customer_experience`, `digital_engagement`, `customer_value`), joined on
   `customer_id`. See `01_schema.sql` and `03_normalize.sql`.
3. **SQL analysis** — RFM recomputation, churn risk, and CLV/profitability
   queries, written directly against the normalized tables. See
   `04_analysis_queries.sql`.
4. **Views** — the analysis queries are wrapped as 10 SQL views, which
   Power BI connects to directly. One view (`vw_customer_value_detail`) is
   built at the customer grain specifically so dashboard slicers (country,
   age group, loyalty tier) can filter consistently across visuals. See
   `05_views.sql`.
5. **Power BI dashboard** — 4 pages: Overview, Churn & Retention, CLV &
   Profitability, and RFM Validation.
## Files
 
| File | Purpose |
|---|---|
| `01_schema.sql` | Creates the database and 6 normalized tables |
| `02_load_data.py` | Loads and cleans the raw CSV into a MySQL staging table |
| `03_normalize.sql` | Splits the staging table into the normalized tables |
| `04_analysis_queries.sql` | RFM recomputation, churn risk, and CLV/profitability queries |
| `05_views.sql` | 10 SQL views powering the Power BI dashboard |
 
Run order: `01` → `02` → `03` → `04` (optional, for exploration) → `05`.
 
## Why a separate RFM calculation?
 
The dataset ships with pre-computed RFM scores. Rather than just
visualizing those labels, `vw_rfm_comparison` recomputes Recency,
Frequency, and Monetary scores independently from raw purchase data using
`NTILE()` window functions, then compares the result against the dataset's
given segments. This validates both the dataset's labels and the SQL logic
behind them, rather than assuming the pre-built scores are correct.
 
## Key findings
 
- **Recency is the strongest churn predictor.** Customers inactive 0-90
  days average a churn risk score of ~22; customers inactive 91+ days
  average ~46. Engagement level and loyalty tier, by contrast, show almost
  no separation in churn risk (~26.8-26.9 across all groups) — churn risk
  in this dataset tracks recency, not tier or engagement.
- **Satisfaction level does separate churn risk.** Dissatisfied and Very
  Dissatisfied customers average churn scores in the low 40s, versus ~17
  for Neutral, Satisfied, and Very Satisfied customers.
- **Acquisition cost is negligible and flat.** It sits around $100-103
  across every CLV tier, meaning `customer_profitability_usd` in this
  dataset is effectively CLV minus a near-constant cost — customer value
  is driven almost entirely by lifetime value, not acquisition efficiency.
- **Classic Pareto concentration.** The top 20% of customers by CLV
  (quintile 1) generate ~50% of total customer lifetime value, dropping to
  under 2% for the bottom quintile.
- **RFM validation succeeded.** Independently calculated RFM scores rank
  the dataset's given segments in the expected order — Champions (11.41
  avg. calculated score) > Loyal (8.42) > Potential Loyalists (6.47) > At
  Risk (4.94) > Need Attention (3.17) — confirming the given labels are
  consistent with the underlying purchase data.
## Dashboard
 
**Page 1 — Overview:** total customers, avg. CLV, avg. churn risk, %
high-risk customers; CLV by category; churn risk heatmap by loyalty tier;
slicers for country, age group, and loyalty tier.

<img width="590" height="331" alt="image" src="https://github.com/user-attachments/assets/7f69dc60-cb82-4857-b21c-3563b6db1fc1" />

 
**Page 2 — Churn & Retention:** churn risk by satisfaction level and by
recency bucket; a retention priority table of high-CLV, high-churn-risk
customers.

<img width="590" height="332" alt="image" src="https://github.com/user-attachments/assets/0230ed4d-11e6-49a7-ace7-fc62246afecd" />

 
**Page 3 — CLV & Profitability:** CLV vs. profitability by category, an
acquisition cost callout, profitability by shopping channel/device, and
the CLV quintile (Pareto) chart.

<img width="592" height="333" alt="image" src="https://github.com/user-attachments/assets/07cc8a7c-85e3-4f83-a8d7-24accc7ef0ed" />

 
**Page 4 — RFM Validation:** calculated vs. given RFM scores by segment.

<img width="592" height="333" alt="image" src="https://github.com/user-attachments/assets/330cbf22-ec67-406e-8bd7-02f8fcb1b8eb" />

 
## Tools
 
MySQL 8, Python (pandas, SQLAlchemy, mysql-connector-python), Power BI
Desktop.
 
## Author
 
Pradnya — [LinkedIn/GitHub link here]
