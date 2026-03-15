**Enterprise Revenue Intelligence & Lifecycle Analytics**

**📈 Business Scenario**

The organization lacked a centralized "Single Source of Truth" for multi-channel sales data. With over 25,000 raw interaction logs siloed across various regions, leadership could not accurately track Revenue Velocity, identify High-Value (Whale) Customers, or quantify Marketing Channel Efficiency. The manual process of cleaning data led to a 48-hour lag in reporting, hindering real-time decision-making.

**🛠️ The Solution: Revenue Intelligence Pipeline**

I architected a robust analytics pipeline that transforms raw, messy interaction data into high-fidelity business insights.

1. Data Engineering & Modeling
Star Schema Architecture: Designed and implemented a relational warehouse with a central Fact_Sales table and three dimensions (Dim_Users, Dim_Products, Dim_Channels) to ensure data integrity and query performance.

ETL Logic: Engineered SQL scripts to handle the ingestion of 25K+ rows, applying constraints to maintain referential integrity.

2. Advanced Analytics (SQL Engine)
Revenue Velocity: Leveraged Window Functions (LAG) to calculate Month-over-Month (MoM) growth, providing a clear view of fiscal momentum.

Whale Discovery: Implemented DENSE_RANK() logic to identify and segment the top 1% of customers by Lifetime Value (LTV).

Retention Risk Modeling: Developed a recency-based churn model using DATEDIFF and conditional logic to categorize customers as "Active," "At Risk," or "Churned."

Marketing Attribution: Aggregated ROI across five major channels to determine the most cost-effective acquisition strategies.

3. Business Intelligence (Power BI)
Integrated the SQL warehouse with Power BI to create an executive dashboard.

Implemented DAX measures for real-time KPI tracking, allowing stakeholders to drill down by Region and Product Category.

**🚀 Business Impact**

Zero-Lag Reporting: Automated the data transformation process, reducing the time from raw data to insight from 48 hours to seconds.

Risk Mitigation: Identified the "At Risk" customer segment (80+ days since last purchase), enabling the marketing team to launch targeted re-engagement campaigns.

Strategic Growth: Uncovered that "SaaS Premium" was the primary driver for "Whale" customers in the APAC region, leading to a 15% shift in budget allocation toward high-LTV segments.

**🔗 Repository Structure**

SQL_Scripts/ : Production-ready DDL and Analytical queries.

Data/ : Enterprise-scale interaction logs (25K+ records).

BI_Dashboards/ : Power BI (.pbix) and visualization exports.

Documentation/ : Technical architecture and data dictionary.
