# Vantage — Retail Profitability & Customer Analytics

An end-to-end retail analytics project — 51,290 order lines across 25,728 orders, 165 countries, and 5 global markets, taken from a raw Excel export through a validated PostgreSQL star schema to a four-page Power BI dashboard. Cleaning and validation in Python, business analysis in SQL, customer segmentation in Python — each tool used where it's actually the right one.

**Dataset:** 51,290 order lines · 25,728 distinct orders · 17,415 customers · 165 countries · 5 markets
**Stack:** Python (pandas) · PostgreSQL · SQL · Power BI (DAX)
**Observation window:** January 2012 – December 2015

---

## What This Does

Sales grew every year in this dataset — but a quarter of all order lines lose money, one entire sub-category is unprofitable despite strong sales, and profit is heavily concentrated in a small slice of customers. This project answers the question that matters more than "are we growing": **where specifically is that growth leaking profit, and what should change?**

Every number below was pulled directly from the executed notebooks and the live Postgres database.

## Project Pipeline

1. **Clean & Validate** (`01_data_cleaning.ipynb`) — profiling, business-rule validation, referential-integrity checks.
2. **Load to PostgreSQL** (`02_load_to_postgres.ipynb`, `sql/01_schema.sql`) — cleaned data shaped into a star schema, loaded with self-verifying assertions on row counts, grain, and foreign-key coverage.
3. **Analyze** (`03_analysis.ipynb`) — SQL answers each business question first; Python is used only for RFM scoring, where quantile logic is more readable in pandas than SQL. Python output is written back into Postgres.
4. **Dashboard** (`powerbi/sales_dashboard.pbix`) — four report pages connected directly to PostgreSQL.

## Data Model

```
                    dim_customer
                         │
dim_product ─────  fact_order_lines  ───── dim_geography
                         │
                    dim_manager  (joined via dim_geography.region)
```

`bridge_returns` is loaded into Postgres as the raw source for the `is_returned_line` flag but excluded from the Power BI model — that flag is already denormalized onto `fact_order_lines`, so including the bridge table again would only invite a spurious relationship without adding anything new.

## Business Questions & Where They're Answered

| # | Question | Answered In |
|---|---|---|
| 1 | Is the business growing, and is profit keeping pace with sales? | `03_analysis.ipynb` — YoY Growth |
| 2 | Which sub-categories generate sales but destroy profit? | `03_analysis.ipynb` — Profit Leakage |
| 3 | At what discount level does profitability actually deteriorate? | `03_analysis.ipynb` — Discount vs. Profitability |
| 4 | Which markets grew, and did their profitability improve or worsen? | `03_analysis.ipynb` — Market Growth vs. Margin |
| 5 | How dependent is each market on a small number of customers? | `03_analysis.ipynb` — Customer Profit Concentration |
| 6 | Which customer groups are worth retaining or worth re-engaging? | `03_analysis.ipynb` — RFM Segmentation |

## Techniques Used

- Referential-integrity checks with hard `assert`s, not just printed warnings
- Weighted aggregate margin (`SUM(profit)/SUM(sales)`) instead of an average of line-level margins
- Window functions (`LAG`, `RANK() OVER (PARTITION BY ...)`) for YoY growth and per-market customer ranking
- RFM segmentation with quantile scoring, using an honest 4-tier frequency score rather than forcing a false 1–5 symmetry
- `.env`-based credential handling — no database password committed to the repository

## Key Insights

1. **Profit growth outpaced sales in 2014, then fell behind in 2015.** Sales grew every year ($2.26M → $4.30M), but 2015's profit growth (23.9%) trailed its sales growth (26.3%) for the first time — a reversal from 2014.
2. **Tables is the only sub-category losing money.** -$64,083 profit on $757K sales (-8.5% margin), with 57.6% of its lines unprofitable — more than double any other sub-category.
3. **Every sub-category turns unprofitable past a 20% discount.** Tables, Bookcases, and Chairs all show strong margins at 0% discount, then outright losses beyond 20% — down to -163% margin at 60%+ discount for Tables.
4. **Europe and Asia Pacific grew fastest but got less profitable.** Europe: +118% sales, margin down 14.2% → 13.3%. Asia Pacific: +92% sales, margin down 10.3% → 9.8%. Africa is the exception — +122% sales *and* margin up 8.6% → 13.9%.
5. **Africa and USCA are unusually dependent on a few accounts.** Their top 5 customers hold 12.4% and 10.1% of market profit respectively, versus 3.0–3.6% everywhere else.
6. **A quarter of customers are worth almost nothing; a different 12% are worth winning back.** "Lost / Low Value" is 26.6% of customers but only 0.7% of profit. "Lapsed High-Value" is 12.2% of customers but 25.7% of profit — high-value buyers who've gone quiet.

## Recommendations

- Investigate Tables' cost/pricing baseline directly — its loss looks structural, not just discount-driven.
- Cap standard discount approval at 15–20% for Tables, Bookcases, and Chairs; route higher discounts through manager sign-off.
- Slow sales-growth investment in Europe and Asia Pacific until margin is addressed.
- Study Africa's pricing/operating model — it's the only market improving margin while growing fast.
- Build dedicated account coverage for Africa's and USCA's top customers given their outsized profit concentration.
- Prioritize a reactivation campaign for the 2,132 Lapsed High-Value customers before spending on general acquisition.
- Don't allocate retention budget to the Lost / Low Value segment — the economics don't justify it.

## Dashboard

| Page | Visuals |
|---|---|
| 01 Executive Overview | KPI cards (Sales, Profit, Margin, Orders, Return Rate) · Sales & Profit trend · Sales by Category (donut) · Sales by Region (bar) · Category/Region/Segment slicers |
| 02 Product & Category | Sub-category profit breakdown · Category-level detail (pivot table) · Category/sub-category slicers |
| 03 Regional & Customer | Market-level performance · Customer profit concentration · Sales-vs-profit customer view (scatter) · Regional detail (pivot table) |
| 04 Returns & Profitability | Discount-band profitability · Returns detail (pivot table) · Market/segment slicers |

All four pages connect directly to PostgreSQL.

## Folder Structure

```
Vantage-Retail-Analytics/
│
├── data/
│       global_superstore_2016.xlsx
│
├── notebooks/
│       01_data_cleaning.ipynb
│       02_load_to_postgres.ipynb
│       03_analysis.ipynb
│
├── sql/
│       01_schema.sql
│
├── outputs/
│       orders_clean.csv
│       returns_clean.csv
│       people_clean.csv
│
├── powerbi/
│       sales_dashboard.pbix
│
├── .env
├── .gitignore
└── README.md
```

## Tech Stack

| Category | Tools |
|---|---|
| Data Cleaning & Validation | Python — pandas, numpy |
| Database | PostgreSQL |
| Analysis | SQL (CTEs, window functions) · Python (pandas, scipy) |
| Visualization | Power BI (DAX) |
| Version Control | Git, GitHub |

## How to Reproduce

1. Create a PostgreSQL database and a `.env` file in the project root with `DB_USER`, `DB_PASS`, `DB_HOST`, `DB_PORT`, `DB_NAME`.
2. Run `notebooks/01_data_cleaning.ipynb` top to bottom — produces the cleaned CSVs in `outputs/`.
3. Run `notebooks/02_load_to_postgres.ipynb` — builds the schema from `sql/01_schema.sql` and loads all six tables.
4. Run `notebooks/03_analysis.ipynb` — runs all six analyses and writes the RFM results back into Postgres.
5. Open `powerbi/sales_dashboard.pbix` in Power BI Desktop, point the PostgreSQL connector at your database, and refresh.
