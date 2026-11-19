-- ОТЧЁТ 1. Топ маркетинговых кампаний по ROI

SELECT
    campaign_id,
    campaign_name,
    MAX(campaign_budget) AS campaign_budget,
    SUM(orders_count) AS total_orders,
    SUM(new_customers) AS new_customers,
    SUM(revenue) AS total_revenue,
    SUM(spend) AS total_spend,
    ROUND(
        (SUM(revenue) - SUM(spend)) * 100
        / NULLIF(SUM(spend), 0),
        2
    ) AS total_roi
FROM cdm.dm_sales_performance
GROUP BY
    campaign_id,
    campaign_name
ORDER BY total_roi DESC NULLS LAST;

-- ОТЧЁТ 2. Сравнение расходов и бюджетов кампаний

SELECT
    campaign_id,
    campaign_name,
    MAX(campaign_budget) AS campaign_budget,

    ROUND(
        SUM(spend), 2
    ) AS total_spend,

    ROUND(
        MAX(campaign_budget) - SUM(spend),
        2
    ) AS remaining_budget,

    ROUND(
        SUM(spend) * 100
        / NULLIF(MAX(campaign_budget), 0),
        2
    ) AS budget_utilization_pct

FROM cdm.dm_sales_performance
GROUP BY
    campaign_id,
    campaign_name
ORDER BY campaign_id;

-- ОТЧЁТ 3. Анализ привлечения новых клиентов

SELECT
    campaign_id,
    campaign_name,
    SUM(orders_count) AS total_orders,
    SUM(new_customers) AS new_customers,

    ROUND(
        SUM(new_customers) * 100.0
        / NULLIF(SUM(orders_count), 0),
        2
    ) AS new_orders_pct,

    ROUND(
        SUM(spend)
        / NULLIF(SUM(new_customers), 0),
        2
    ) AS cost_per_new_customer

FROM cdm.dm_sales_performance
GROUP BY
    campaign_id,
    campaign_name
ORDER BY new_customers DESC, campaign_id;


-- ОТЧЁТ 4. Эффективность рекламных каналов

SELECT
    channel_id,
    channel_name,
    COUNT(DISTINCT campaign_id) AS campaigns_count,
    SUM(orders_count) AS total_orders,
    SUM(new_customers) AS new_customers,

    ROUND(
        SUM(revenue), 2
    ) AS total_revenue,

    ROUND(
        SUM(spend), 2
    ) AS total_spend,

    ROUND(
        (SUM(revenue) - SUM(spend)) * 100
        / NULLIF(SUM(spend), 0),
        2
    ) AS roi,

    ROUND(
        SUM(spend)
        / NULLIF(SUM(new_customers), 0),
        2
    ) AS cost_per_new_customer

FROM cdm.dm_sales_performance
GROUP BY
    channel_id,
    channel_name
ORDER BY roi DESC NULLS LAST;
