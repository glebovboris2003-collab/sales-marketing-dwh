-- 1. Измерение клиентов
CREATE TABLE dds.dim_customers (
    customer_id INTEGER NOT NULL,
    customer_name VARCHAR(100),
    signup_dt DATE,
    region VARCHAR(50),
    customer_segment VARCHAR(50),
    load_dt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_src VARCHAR(50) NOT NULL DEFAULT 'stg.customers'
)
DISTRIBUTED BY (customer_id);


-- 2. Измерение рекламных каналов
CREATE TABLE dds.dim_channels (
    channel_id INTEGER NOT NULL,
    channel_name VARCHAR(100),
    channel_type VARCHAR(50),
    load_dt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_src VARCHAR(50) NOT NULL DEFAULT 'stg.channels'
)
DISTRIBUTED REPLICATED;


-- 3. Измерение маркетинговых кампаний
CREATE TABLE dds.dim_campaigns (
    campaign_id INTEGER NOT NULL,
    campaign_name VARCHAR(100),
    channel_id INTEGER,
    start_dt DATE,
    end_dt DATE,
    budget NUMERIC(12,2),
    load_dt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_src VARCHAR(50) NOT NULL DEFAULT 'stg.campaigns'
)
DISTRIBUTED REPLICATED;


-- 4. Таблица фактов заказов
CREATE TABLE dds.fact_orders (
    order_id INTEGER NOT NULL,
    order_dt DATE NOT NULL,
    customer_id INTEGER,
    campaign_id INTEGER,
    order_amount NUMERIC(12,2),
    order_status VARCHAR(20),
    load_dt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_src VARCHAR(50) NOT NULL DEFAULT 'stg.orders'
)
DISTRIBUTED BY (order_id)
PARTITION BY RANGE (order_dt)
(
    START (DATE '2025-01-01') INCLUSIVE
    END (DATE '2027-01-01') EXCLUSIVE
    EVERY (INTERVAL '1 year')
);


-- 5. Таблица фактов товарных позиций
CREATE TABLE dds.fact_order_items (
    order_item_id INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    product_id INTEGER,
    product_name VARCHAR(100),
    quantity INTEGER,
    price NUMERIC(12,2),
    load_dt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_src VARCHAR(50) NOT NULL DEFAULT 'stg.order_items'
)
DISTRIBUTED BY (order_id);
