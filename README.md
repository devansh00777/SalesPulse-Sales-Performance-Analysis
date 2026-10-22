# SalesPulse: Sales Performance Analysis

Analysis of the Global Superstore sample dataset: raw Excel data is cleaned in Python, loaded into a PostgreSQL star schema, analysed in SQL, and shown in a four-page Power BI dashboard.

The question: sales grew every year, so where is that growth not turning into profit?

| | |
|---|---|
| Data | 51,290 order lines, 25,728 orders, 5 markets, 23 regions |
| Period | January 2012 to December 2015 |
| Totals | $12.64M sales, $1.47M profit, 11.61% margin, 4.19% order return rate |
| Stack | Python (pandas, SQLAlchemy), PostgreSQL, SQL, Power BI (DAX) |

## Dashboard

### Executive Overview
![Executive Overview](images/01_executive_overview.png)

### Product and Category
![Product and Category](images/02_product_category.png)

### Regional and Customer
![Regional and Customer](images/03_regional_customer.png)

### Returns and Profitability
![Returns and Profitability](images/04_returns_profitability.png)

## Project Workflow

| Step | File | What it does | Output |
|---|---|---|---|
| 1 | `notebooks/01_data_cleaning.ipynb` | Reads the Orders, Returns and People sheets. Checks keys, duplicates, business rules and that every returned order exists in Orders. Fixes the Canada region mismatch and extra spaces in product names. Adds the return flag and delivery days. | 3 cleaned CSVs in `outputs/` |
| 2 | `notebooks/02_load_to_postgres.ipynb` | Builds the star schema from `sql/01_schema.sql`, splits the data into a fact table and dimensions, checks row counts and keys, and loads everything. | 6 tables in PostgreSQL |
| 3 | `notebooks/03_analysis.ipynb` | SQL for yearly growth, profit by sub-category, discount bands, market growth and customer concentration. Customer scoring (RFM) in pandas. Results written back to PostgreSQL. | `rfm_customers`, `rfm_segment_summary` |
| 4 | `powerbi/sales_dashboard.pbix` | Four report pages connected to PostgreSQL. | Dashboard |

Data model: `fact_order_lines` (one row per order line, 51,290) with `dim_customer` (17,415), `dim_product` (3,788), `dim_geography` (3,856) and `dim_manager` (23). `bridge_returns` (1,079) holds the returned orders.

## Key Findings

**Growth.** Sales grew from $2.26M (2012) to $4.30M (2015) and profit from $249K to $504K. Profit grew faster than sales in 2013 and 2014 and slightly slower in 2015 (23.9% vs 26.3%). Margin by year: 11.0%, 11.5%, 11.9%, 11.7%.

**Furniture margin.** Furniture earns 6.94%, against 13.99% for Technology and 13.69% for Office Supplies. Tables is the only sub-category with a net loss: $757K in sales, a $64K loss (-8.5% margin), and 57.6% of its order lines lose money (next highest is Chairs at 32.0%). Without Tables, Furniture margin would be about 10.4%. Return rates are 4.1% to 4.3% in every category, so returns do not explain the gap.

**Discounts.** Margin by discount band for the three sub-categories analysed:

| Sub-category | 0% | 0-20% | 20-40% | 40-60% | 60%+ |
|---|---|---|---|---|---|
| Bookcases | 24.4% | 13.1% | -23.7% | -65.4% | -152.0% |
| Chairs | 23.9% | 10.6% | -10.3% | -72.8% | -134.2% |
| Tables | 23.1% | 5.0% | -18.1% | -51.8% | -163.1% |

In Tables, 467 of 861 order lines (54%) have a discount above 20%. This fits with discounting driving the loss, but the analysis does not separate discount from product cost or mix.

**Markets (2012 vs 2015).** Every market grew. Margin fell in Europe and Asia Pacific and rose in the other three.

| Market | Sales growth | Margin 2012 to 2015 |
|---|---|---|
| Africa | +122.5% | 8.6% to 13.9% |
| Europe | +118.3% | 14.2% to 13.3% |
| Asia Pacific | +92.4% | 10.3% to 9.8% |
| LATAM | +83.5% | 9.5% to 10.4% |
| USCA | +53.6% | 10.4% to 13.1% |

**Customer concentration.** The top 5 customers hold 12.4% of profit in Africa and 10.1% in USCA, and 3.0% to 3.6% in the other markets.

**Customer segments (RFM).** Rule-based groups from recency (R), frequency (F) and monetary value (M) scores:

| Segment | Rule | Customers | Share of profit |
|---|---|---|---|
| Recent, Low Frequency | R 4-5, F 1-2 | 5,575 (32.0%) | 26.9% |
| Lapsed High-Value | R 1-2, M 4-5, F 1-2 | 2,132 (12.2%) | 25.7% |
| Champions | R 4-5, F 3-4 | 1,396 (8.0%) | 24.2% |
| Regular | R 3 | 3,483 (20.0%) | 20.1% |
| At Risk | R 1-2, F 3-4 | 192 (1.1%) | 2.3% |
| Lost / Low Value | R 1-2, F 1-2, M 1-3 | 4,637 (26.6%) | 0.7% |

Lapsed High-Value is 12% of customers and about a quarter of profit, so it is the first group to look at for win-back work. Whether reactivation would work has not been tested.

**What to look at next**
- Check at product level whether specific Tables products drive the loss.
- Recalculate margins for Tables, Bookcases and Chairs with discounts capped at 20%.
- Look at what changed in Africa, where sales more than doubled and margin rose.

## Method

- Margin is `SUM(profit) / SUM(sales)` per group, not an average of line-level margins.
- Return rate uses distinct orders (1,079 of 25,728), because the Returns sheet lists orders, not lines.
- RFM snapshot date is the last order date plus one day. Recency and monetary value use five equal groups. Frequency uses four fixed tiers (1, 2, 3, 4+ orders) because most customers have one or two orders.

## Limitations

- There are 17,415 customer IDs but only 796 distinct customer names, and one name appears under IDs in up to 32 countries. Customer counts, concentration and RFM are at the customer ID level.
- Discount findings show an association in three sub-categories, not proof of cause. The other 14 sub-categories were not analysed by discount band.
- The market comparison uses 2012 and 2015 only.
- RFM segments are rule-based labels, not validated behaviour groups.
- Regional return rates (about 4.3% to 5.4%) come from roughly 1,000 returned orders across 23 regions, so small differences should not be over-read.
- `Delivery Days` is order date to ship date, not delivery to the customer.
- This is a sample dataset, so the findings show the method rather than a real business.

## How to Run

1. Create a PostgreSQL database and a `.env` file in the project root with `DB_USER`, `DB_PASS`, `DB_HOST`, `DB_PORT` and `DB_NAME`. `.env` is in `.gitignore`.
2. Put `global_superstore_2016.xlsx` in `data/`.
3. Run notebooks 01, 02 and 03 in order, each from top to bottom.
4. Open `powerbi/sales_dashboard.pbix`, point the PostgreSQL connection at your database, and refresh.
