-- 1. Генерация 100 клиентов (было решено локализовать некоторые параметры для большей наглядности)
INSERT INTO stg.customers (
    customer_id,
    customer_name,
    signup_dt,
    region,
    customer_segment
)
SELECT
    id,
    'Customer_' || id,
    DATE '2025-01-01' + (random() * 364)::INTEGER,
    CASE (id % 10)
        WHEN 0 THEN 'Москва'
        WHEN 1 THEN 'Санкт-Петербург'
        WHEN 2 THEN 'Московская область'
        WHEN 3 THEN 'Краснодарский край'
        WHEN 4 THEN 'Республика Татарстан'
        WHEN 5 THEN 'Свердловская область'
        WHEN 6 THEN 'Новосибирская область'
        WHEN 7 THEN 'Ростовская область'
        WHEN 8 THEN 'Самарская область'
        ELSE 'Нижегородская область'
    END,
    CASE (id % 3)
        WHEN 0 THEN 'Premium'
        WHEN 1 THEN 'Standard'
        ELSE 'Basic'
    END
FROM generate_series(1, 100) AS id;


-- 2. Генерация рекламных каналов
INSERT INTO stg.channels (
    channel_id,
    channel_name,
    channel_type
)
VALUES
    (1, 'Яндекс Директ', 'Paid Search'),
    (2, 'VK Реклама', 'Social Media'),
    (3, 'Email-рассылка', 'Email'),
    (4, 'Органический поиск', 'Organic Search');


-- 3. Генерация 10 маркетинговых кампаний
INSERT INTO stg.campaigns (
    campaign_id,
    campaign_name,
    channel_id,
    start_dt,
    end_dt,
    budget
)
SELECT
    id,
    'Кампания ' || id,
    ((id - 1) % 4) + 1,
    DATE '2025-07-01' + ((id - 1) * 14),
    DATE '2026-12-31' - ((id - 1) * 14),
    (50000 + id * 10000)::NUMERIC(12,2)
FROM generate_series(1, 10) AS g(id);


----------------------------------------------------------------
-- 4. Генерация 600 заказов
-- По 60 заказов на каждую кампанию
-- Статусы: 70% completed, 20% cancelled, 10% returned

WITH generated_orders AS (
    SELECT
        g.id AS order_id,
        u.customer_id,
        c.campaign_id,
        GREATEST(u.signup_dt, c.start_dt) AS min_order_dt,
        LEAST(c.end_dt, DATE '2026-11-19') AS max_order_dt,
        ROW_NUMBER() OVER (
            PARTITION BY c.campaign_id
            ORDER BY MD5(g.id::TEXT)
        ) AS rn
    FROM generate_series(1, 600) AS g(id)

    JOIN stg.customers u
        ON u.customer_id = ((g.id - 1) % 100) + 1

    JOIN stg.campaigns c
        ON c.campaign_id =
            (((g.id - 1) % 10 + (g.id - 1) / 100) % 10) + 1
)

INSERT INTO stg.orders (
    order_id,
    order_dt,
    customer_id,
    campaign_id,
    order_amount,
    order_status
)
SELECT
    order_id,

    min_order_dt
        + FLOOR(
            random() * (max_order_dt - min_order_dt + 1)
        )::INTEGER,

    customer_id,
    campaign_id,

    ROUND(
        (2000 + random() * 18000)::NUMERIC,
        2
    ),

    CASE
        WHEN rn <= 42 THEN 'completed'
        WHEN rn <= 54 THEN 'cancelled'
        ELSE 'returned'
    END

FROM generated_orders;


-- 5. Генерация 2000 товарных позиций
INSERT INTO stg.order_items (
    order_item_id,
    order_id,
    product_id,
    product_name,
    quantity,
    price
)
SELECT
    t.order_item_id,
    t.order_id,
    t.product_id,
    'Товар ' || t.product_id,
    t.quantity,
    t.price
FROM (
    SELECT
        g.id AS order_item_id,

        ((g.id - 1) % 600) + 1 AS order_id,

        (
            ((g.id - 1) % 50
            + ((g.id - 1) / 600) * 11) % 50
        ) + 1 AS product_id,

        (FLOOR(random() * 5) + 1)::INTEGER
            AS quantity,

        ROUND(
            (200 + random() * 4800)::NUMERIC,
            2
        ) AS price

    FROM generate_series(1, 2000) AS g(id)
) AS t;


-- 6. Согласование сумм заказов
UPDATE stg.orders AS o
SET order_amount = items.total_amount
FROM (
    SELECT
        order_id,
        SUM(quantity * price) AS total_amount
    FROM stg.order_items
    GROUP BY order_id
) AS items
WHERE o.order_id = items.order_id;
