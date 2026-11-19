CREATE TABLE cdm.dm_sales_performance (
    report_dt DATE NOT NULL,
    campaign_id INTEGER NOT NULL,
    campaign_name VARCHAR(100),
    channel_id INTEGER,
    channel_name VARCHAR(100),

    orders_count BIGINT,
    customers_count BIGINT,

    order_amount NUMERIC(18,2),
    avg_order_amount NUMERIC(18,2),

    new_customers BIGINT,

    campaign_budget NUMERIC(12,2),
    spend NUMERIC(18,2),
    revenue NUMERIC(18,2),
    roi NUMERIC(18,2)
)
DISTRIBUTED BY (campaign_id)
PARTITION BY RANGE (report_dt)
(
    START (DATE '2025-01-01') INCLUSIVE
    END (DATE '2027-01-01') EXCLUSIVE
    EVERY (INTERVAL '1 year')
);
