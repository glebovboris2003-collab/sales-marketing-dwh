-- 1. Определение первого завершённого заказа клиента
WITH first_orders AS (
    SELECT
        order_id,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_dt, order_id
        ) AS purchase_num
    FROM dds.fact_orders
    WHERE order_status = 'completed'
),

-- 2. Агрегация завершённых заказов по датам и кампаниям
daily_orders AS (
    SELECT
        o.order_dt AS report_dt,
        o.campaign_id,

        COUNT(*) AS orders_count,

        COUNT(DISTINCT o.customer_id) AS customers_count,

        SUM(o.order_amount) AS order_amount,

        ROUND(AVG(o.order_amount), 2) AS avg_order_amount,

        SUM(
            CASE
                WHEN f.purchase_num = 1 THEN 1
                ELSE 0
            END
        ) AS new_customers

    FROM dds.fact_orders o

    JOIN first_orders f
        ON o.order_id = f.order_id

    WHERE o.order_status = 'completed'

    GROUP BY o.order_dt, o.campaign_id
),

-- 3. Расчёт ежедневных расходов рекламных кампаний
campaign_days AS (
    SELECT
        cal.report_dt::DATE AS report_dt,
        c.campaign_id,
        c.campaign_name,
        c.channel_id,
        ch.channel_name,
        c.budget AS campaign_budget,

        CASE
            WHEN cal.report_dt::DATE = c.end_dt THEN
                c.budget
                - ROUND(
                    c.budget / (c.end_dt - c.start_dt + 1),
                    2
                  ) * (c.end_dt - c.start_dt)

            ELSE ROUND(
                c.budget / (c.end_dt - c.start_dt + 1),
                2
            )
        END AS spend

    FROM dds.dim_campaigns c

    JOIN dds.dim_channels ch
        ON c.channel_id = ch.channel_id

    CROSS JOIN generate_series(
        TIMESTAMP '2025-01-01',
        TIMESTAMP '2026-11-19',
        INTERVAL '1 day'
    ) AS cal(report_dt)

    WHERE cal.report_dt::DATE
        BETWEEN c.start_dt AND c.end_dt
)

-- 4. Заполнение аналитической витрины
INSERT INTO cdm.dm_sales_performance (
    report_dt,
    campaign_id,
    campaign_name,
    channel_id,
    channel_name,
    orders_count,
    customers_count,
    order_amount,
    avg_order_amount,
    new_customers,
    campaign_budget,
    spend,
    revenue,
    roi
)

SELECT
    d.report_dt,
    d.campaign_id,
    d.campaign_name,
    d.channel_id,
    d.channel_name,

    COALESCE(o.orders_count, 0),
    COALESCE(o.customers_count, 0),
    COALESCE(o.order_amount, 0),
    COALESCE(o.avg_order_amount, 0),
    COALESCE(o.new_customers, 0),

    d.campaign_budget,
    d.spend,

    COALESCE(o.order_amount, 0) AS revenue,

    ROUND(
        (
            COALESCE(o.order_amount, 0) - d.spend
        ) * 100 / NULLIF(d.spend, 0),
        2
    ) AS roi

FROM campaign_days d

LEFT JOIN daily_orders o
    ON d.report_dt = o.report_dt
   AND d.campaign_id = o.campaign_id;
