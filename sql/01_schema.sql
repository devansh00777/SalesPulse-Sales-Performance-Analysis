-- Global Superstore star schema 

DROP TABLE IF EXISTS fact_order_lines;
DROP TABLE IF EXISTS bridge_returns;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_geography;
DROP TABLE IF EXISTS dim_manager;

CREATE TABLE dim_customer (
    customer_id     TEXT PRIMARY KEY,
    customer_name   TEXT,      -- display only, NOT a unique person identifier
    segment         TEXT
);

CREATE TABLE dim_product (
    product_id      TEXT PRIMARY KEY,
    product_name    TEXT,
    category        TEXT,
    sub_category    TEXT
);

CREATE TABLE dim_geography (
    geography_key   SERIAL PRIMARY KEY,
    city            TEXT,
    state           TEXT,
    country         TEXT,
    region          TEXT,
    market          TEXT,
    postal_code     TEXT
);

CREATE TABLE dim_manager (
    region          TEXT PRIMARY KEY,
    manager_name    TEXT
);

CREATE TABLE bridge_returns (
    order_id        TEXT PRIMARY KEY,
    returned        TEXT,
    region          TEXT
);

CREATE TABLE fact_order_lines (
    row_id          INTEGER PRIMARY KEY,
    order_id        TEXT,
    order_date      DATE,
    ship_date       DATE,
    ship_mode       TEXT,
    customer_id     TEXT REFERENCES dim_customer(customer_id),
    product_id      TEXT REFERENCES dim_product(product_id),
    geography_key   INTEGER REFERENCES dim_geography(geography_key),
    order_priority  TEXT,
    sales           NUMERIC,
    quantity        INTEGER,
    discount        NUMERIC,
    profit          NUMERIC,
    shipping_cost   NUMERIC,
    delivery_days   INTEGER,
    is_returned_line INTEGER
);
