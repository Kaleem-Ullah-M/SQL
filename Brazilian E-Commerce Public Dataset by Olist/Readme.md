# Introduction of the Project: 
Project consists of two parts.

## 1 data cleaning, validation along with Data Model.
## 2 Statistical Summary and KPIs

### 1: Data cleaning, validation and Data Model
The dataset: Olist e-commerce — 100,000+ transactions, 9 raw tables, real messy data.

Here's exactly what the pipeline looked like:

𝟭. Extracted raw CSVs → SQL Server
Loaded everything into raw tables (R_ prefix) — untouched, safe.

𝟮. Built a staging layer (STG_ tables)
Never clean raw data directly. I copied everything into staging tables first — so I always had a fallback.

𝟯. Validated nulls and duplicates across all 9 tables
No blind trust. Every key column checked. Found what needed fixing before touching anything.

𝟰. Diagnosed a many-to-many problem in geolocation data
ZIP codes were duplicated across customers, sellers, and geolocation. I resolved it by building a normalized LOCATION table — turning an M:M mess into clean 1:M relationships.

𝟱. Pre-validated all 8 foreign key relationships before loading
Found 278 orphan customers, 7 orphan sellers, and 13 orphan products. Handled them deliberately — not silently dropped.

𝟲. Rebuilt the schema with proper data types and constraints
New tables. Correct types. Check constraints (e.g. review score must be 1–5). Composite primary keys where needed.

𝟳. Loaded clean data using CAST — then enforced foreign keys
Inserted from STG_ → final tables with explicit casting. Added all FK constraints only after data integrity was confirmed.

The result: a fully relational, constraint-enforced schema — ready for analysis in Power BI or Tableau.

What I'd do differently next time:
→ Log orphan records to an audit table instead of just reassigning them
→ Add row count reconciliation checks after every INSERT
→ Use DECIMAL instead of FLOAT for money columns

