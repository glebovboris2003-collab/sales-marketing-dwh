-- 1. Сбор статистики STG

ANALYZE stg.customers;
ANALYZE stg.channels;
ANALYZE stg.campaigns;
ANALYZE stg.orders;
ANALYZE stg.order_items;

-- 2. Сбор статистики DDS

ANALYZE dds.dim_customers;
ANALYZE dds.dim_channels;
ANALYZE dds.dim_campaigns;
ANALYZE dds.fact_orders;
ANALYZE dds.fact_order_items;

-- 3. Сбор статистики CDM

ANALYZE cdm.dm_sales_performance;

-- 4. Анализ партиционирования CDM за 2026 год

EXPLAIN ANALYZE
SELECT
    campaign_id,
    SUM(orders_count) AS total_orders,
    SUM(revenue) AS total_revenue
FROM cdm.dm_sales_performance
WHERE report_dt >= DATE '2026-01-01'
  AND report_dt < DATE '2027-01-01'
GROUP BY campaign_id
ORDER BY campaign_id;

-- 5. Сравнение: тот же запрос без фильтра по дате

EXPLAIN ANALYZE
SELECT
    campaign_id,
    SUM(orders_count) AS total_orders,
    SUM(revenue) AS total_revenue
FROM cdm.dm_sales_performance
GROUP BY campaign_id
ORDER BY campaign_id;

-- 6. Анализ соединения двух таблиц фактов

EXPLAIN ANALYZE
SELECT
    o.order_id,
    SUM(i.quantity * i.price) AS items_amount
FROM dds.fact_orders o
JOIN dds.fact_order_items i
    ON o.order_id = i.order_id
WHERE o.order_dt >= DATE '2026-01-01'
  AND o.order_dt < DATE '2027-01-01'
  AND o.order_status = 'completed'
GROUP BY o.order_id;

-- 7. Проверка распределения строк между сегментами

SELECT
    'fact_orders' AS table_name,
    gp_segment_id,
    COUNT(*) AS rows_count
FROM dds.fact_orders
GROUP BY gp_segment_id

UNION ALL

SELECT
    'fact_order_items',
    gp_segment_id,
    COUNT(*)
FROM dds.fact_order_items
GROUP BY gp_segment_id

UNION ALL

SELECT
    'dm_sales_performance',
    gp_segment_id,
    COUNT(*)
FROM cdm.dm_sales_performance
GROUP BY gp_segment_id

ORDER BY table_name, gp_segment_id;

-- 8. Распределение кампаний между сегментами

SELECT
    gp_segment_id,
    campaign_id,
    COUNT(*) AS rows_count
FROM cdm.dm_sales_performance
GROUP BY
    gp_segment_id,
    campaign_id
ORDER BY
    gp_segment_id,
    campaign_id;
