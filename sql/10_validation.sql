-- 1. Проверка количества записей STG и DDS

WITH table_counts AS (
    SELECT
        'customers' AS table_name,
        (SELECT COUNT(*) FROM stg.customers) AS stg_count,
        (SELECT COUNT(*) FROM dds.dim_customers) AS dds_count,
        100 AS expected_count

    UNION ALL

    SELECT
        'channels',
        (SELECT COUNT(*) FROM stg.channels),
        (SELECT COUNT(*) FROM dds.dim_channels),
        4

    UNION ALL

    SELECT
        'campaigns',
        (SELECT COUNT(*) FROM stg.campaigns),
        (SELECT COUNT(*) FROM dds.dim_campaigns),
        10

    UNION ALL

    SELECT
        'orders',
        (SELECT COUNT(*) FROM stg.orders),
        (SELECT COUNT(*) FROM dds.fact_orders),
        600

    UNION ALL

    SELECT
        'order_items',
        (SELECT COUNT(*) FROM stg.order_items),
        (SELECT COUNT(*) FROM dds.fact_order_items),
        2000
)
SELECT
    table_name,
    stg_count,
    dds_count,
    expected_count,
    CASE
        WHEN stg_count = dds_count
         AND stg_count = expected_count
        THEN 'OK'
        ELSE 'ERROR'
    END AS check_result
FROM table_counts
ORDER BY table_name;

-- 2. Проверка дублирования идентификаторов в DDS

SELECT
    'dim_customers' AS table_name,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicates
FROM dds.dim_customers

UNION ALL

SELECT
    'dim_channels',
    COUNT(*) - COUNT(DISTINCT channel_id)
FROM dds.dim_channels

UNION ALL

SELECT
    'dim_campaigns',
    COUNT(*) - COUNT(DISTINCT campaign_id)
FROM dds.dim_campaigns

UNION ALL

SELECT
    'fact_orders',
    COUNT(*) - COUNT(DISTINCT order_id)
FROM dds.fact_orders

UNION ALL

SELECT
    'fact_order_items',
    COUNT(*) - COUNT(DISTINCT order_item_id)
FROM dds.fact_order_items;

-- 3. Проверка связей заказов с клиентами и кампаниями

SELECT
    COUNT(*) FILTER (
        WHERE c.customer_id IS NULL
    ) AS missing_customers,

    COUNT(*) FILTER (
        WHERE ca.campaign_id IS NULL
    ) AS missing_campaigns,

    COUNT(*) FILTER (
        WHERE o.order_dt < c.signup_dt
    ) AS orders_before_signup,

    COUNT(*) FILTER (
        WHERE o.order_dt < ca.start_dt
           OR o.order_dt > ca.end_dt
    ) AS orders_outside_campaign

FROM dds.fact_orders o

LEFT JOIN dds.dim_customers c
    ON o.customer_id = c.customer_id

LEFT JOIN dds.dim_campaigns ca
    ON o.campaign_id = ca.campaign_id;

-- 4. Проверка товарных позиций и сумм заказов

WITH item_totals AS (
    SELECT
        order_id,
        SUM(quantity * price) AS total_amount
    FROM dds.fact_order_items
    GROUP BY order_id
)
SELECT
    COUNT(*) FILTER (
        WHERE i.order_id IS NULL
    ) AS orders_without_items,

    COUNT(*) FILTER (
        WHERE i.total_amount IS NOT NULL
          AND o.order_amount IS DISTINCT FROM i.total_amount
    ) AS mismatched_amounts

FROM dds.fact_orders o

LEFT JOIN item_totals i
    ON o.order_id = i.order_id;


-- Проверка позиций без существующего заказа

SELECT
    COUNT(*) AS orphan_items
FROM dds.fact_order_items i
LEFT JOIN dds.fact_orders o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 5. Проверка дубликатов в CDM

SELECT
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        report_dt,
        campaign_id
    FROM cdm.dm_sales_performance
    GROUP BY report_dt, campaign_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- 6. Проверка согласованности DDS и CDM

WITH dds_totals AS (
    SELECT
        COUNT(*) AS completed_orders,
        SUM(order_amount) AS revenue,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM dds.fact_orders
    WHERE order_status = 'completed'
),

cdm_totals AS (
    SELECT
        SUM(orders_count) AS completed_orders,
        SUM(revenue) AS revenue,
        SUM(new_customers) AS new_customers
    FROM cdm.dm_sales_performance
)

SELECT
    d.completed_orders AS dds_orders,
    c.completed_orders AS cdm_orders,

    d.revenue AS dds_revenue,
    c.revenue AS cdm_revenue,

    d.unique_customers AS dds_customers,
    c.new_customers AS cdm_new_customers,

    CASE
        WHEN d.completed_orders = c.completed_orders
         AND d.revenue = c.revenue
         AND d.unique_customers = c.new_customers
        THEN 'OK'
        ELSE 'ERROR'
    END AS check_result

FROM dds_totals d
CROSS JOIN cdm_totals c;

-- 7. Проверка логических ограничений CDM

SELECT
    COUNT(*) FILTER (
        WHERE orders_count < 0
    ) AS negative_orders,

    COUNT(*) FILTER (
        WHERE customers_count > orders_count
    ) AS invalid_customer_counts,

    COUNT(*) FILTER (
        WHERE new_customers > customers_count
    ) AS invalid_new_customers,

    COUNT(*) FILTER (
        WHERE revenue < 0 OR spend < 0
    ) AS negative_financial_values

FROM cdm.dm_sales_performance;

-- 8. Итоговая статистика CDM

SELECT
    COUNT(*) AS total_rows,
    SUM(orders_count) AS completed_orders,
    SUM(new_customers) AS new_customers,
    SUM(revenue) AS total_revenue,
    SUM(spend) AS total_spend
FROM cdm.dm_sales_performance;

