-- 1. Клиенты
CREATE TABLE stg.customers (
    customer_id INTEGER,
    customer_name VARCHAR(100),
    signup_dt DATE,
    region VARCHAR(50),
    customer_segment VARCHAR(50)
)
DISTRIBUTED BY (customer_id);


-- 2. Рекламные каналы
CREATE TABLE stg.channels (
    channel_id INTEGER,
    channel_name VARCHAR(100),
    channel_type VARCHAR(50)
)
DISTRIBUTED REPLICATED;


-- 3. Маркетинговые кампании
CREATE TABLE stg.campaigns (
    campaign_id INTEGER,
    campaign_name VARCHAR(100),
    channel_id INTEGER,
    start_dt DATE,
    end_dt DATE,
    budget NUMERIC(12,2)
)
DISTRIBUTED REPLICATED;


-- 4. Заказы
CREATE TABLE stg.orders (
    order_id INTEGER,
    order_dt DATE,
    customer_id INTEGER,
    campaign_id INTEGER,
    order_amount NUMERIC(12,2),
    order_status VARCHAR(20)
)
DISTRIBUTED BY (order_id)
PARTITION BY RANGE (order_dt)
(
    START (DATE '2025-01-01') INCLUSIVE
    END (DATE '2027-01-01') EXCLUSIVE
    EVERY (INTERVAL '1 year')
);


-- 5. Товарные позиции заказов
CREATE TABLE stg.order_items (
    order_item_id INTEGER,
    order_id INTEGER,
    product_id INTEGER,
    product_name VARCHAR(100),
    quantity INTEGER,
    price NUMERIC(12,2)
)
DISTRIBUTED BY (order_id);
