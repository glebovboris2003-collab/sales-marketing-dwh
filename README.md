
# Sales & Marketing Data Warehouse

## 1. Описание проекта

Учебный проект по разработке распределённого аналитического хранилища данных (DWH) на базе Greenplum 7.

Цель — создать хранилище для анализа продаж, клиентов, маркетинговых кампаний и эффективности рекламных каналов.

Архитектура хранилища:

STG → DDS → CDM

- STG — исходные данные.
- DDS — измерения и таблицы фактов.
- CDM — аналитическая витрина для бизнес-отчётности.

## 2. Используемые технологии

- Greenplum 7
- PostgreSQL-совместимый SQL
- Docker
- Visual Studio Code

## 3. Структура проекта

```text
sales-marketing-dwh/
├── sql/
│   ├── 00_create_database.sql
│   ├── 01_create_schemas.sql
│   ├── 02_create_stg.sql
│   ├── 03_generate_data.sql
│   ├── 04_create_dds.sql
│   ├── 05_load_dds.sql
│   ├── 06_create_cdm.sql
│   ├── 07_load_cdm.sql
│   ├── 08_business_reports.sql
│   ├── 09_optimization.sql
│   └── 10_validation.sql
├── README.md
└── architecture_report.md
```

Файл architecture_report.md содержит архитектурное обоснование и создаётся отдельно.

## 4. Модель данных

### STG

Исходный слой содержит пять таблиц:

- stg.customers — клиенты.
- stg.channels — рекламные каналы.
- stg.campaigns — маркетинговые кампании.
- stg.orders — заказы.
- stg.order_items — товарные позиции.

Данные генерируются средствами SQL с использованием generate_series(), random() и CASE.

### DDS

Слой детализированных данных включает:

Измерения:
- dds.dim_customers
- dds.dim_channels
- dds.dim_campaigns

Факты:
- dds.fact_orders
- dds.fact_order_items

В DDS используются служебные поля load_dt и load_src.

### CDM

Аналитическая витрина:

cdm.dm_sales_performance

Гранулярность: один день и одна маркетинговая кампания.

Основные показатели:
- Количество завершённых заказов.
- Количество уникальных покупателей.
- Средняя сумма заказа.
- Количество новых клиентов.
- Выручка.
- Расчётные расходы.
- ROI.

## 5. Запуск проекта

Команды приведены для Windows PowerShell.

### 5.1. Подготовка Greenplum

Скачать образ:

```powershell
docker pull andruche/greenplum:7
```

Создать контейнер, если он ещё не существует:

```powershell
docker run --name greenplum-container -p 5432:5432 -d andruche/greenplum:7
```

Если контейнер уже создан и остановлен:

```powershell
docker start greenplum-container
```

Проверить состояние:

```powershell
docker ps
```

### 5.2. Копирование SQL-файлов

Открыть PowerShell в корневой папке проекта:

```powershell
cd "$HOME\sales-marketing-dwh"
```

Скопировать папку SQL внутрь контейнера:

```powershell
docker cp .\sql greenplum-container:/tmp/sales-marketing-sql
```

### 5.3. Создание базы данных

Для чистого развёртывания, когда базы sales_marketing ещё нет:

```powershell
docker exec -u gpadmin greenplum-container psql -d postgres -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/00_create_database.sql
```

### 5.4. Создание и загрузка хранилища

Выполнять скрипты строго последовательно.

```powershell
docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/01_create_schemas.sql

docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/02_create_stg.sql

docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/03_generate_data.sql

docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/04_create_dds.sql

docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/05_load_dds.sql

docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/06_create_cdm.sql

docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/07_load_cdm.sql
```

Эти команды предназначены для пустой базы.

Не выполнять создание и загрузку повторно поверх уже заполненных таблиц.

### 5.5. Отчёты и оптимизация

После загрузки данных запустить:

```powershell
docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/08_business_reports.sql

docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/09_optimization.sql

docker exec -u gpadmin greenplum-container psql -d sales_marketing -v ON_ERROR_STOP=1 -f /tmp/sales-marketing-sql/10_validation.sql
```

Если файлы изменились на Windows, повторно скопировать обновлённую папку в контейнер перед запуском.

## 6. Контрольные показатели

Ожидаемый объём исходных данных:

| Таблица | Количество записей |
|---|---:|
| customers | 100 |
| channels | 4 |
| campaigns | 10 |
| orders | 600 |
| order_items | 2000 |

В слое DDS должно находиться столько же записей в соответствующих измерениях и фактах.

В витрине ожидается:
- 4146 строк.
- 420 завершённых заказов.
- 100 новых клиентов.

Денежные значения могут отличаться при каждом запуске, поскольку исходные данные генерируются случайным образом.

## 7. Бизнес-отчёты

Проект содержит четыре обязательных отчёта:

1. Рейтинг маркетинговых кампаний по ROI.
2. Сравнение расходов с бюджетами.
3. Анализ новых клиентов и стоимости привлечения.
4. Анализ эффективности рекламных каналов.

Все отчёты используют cdm.dm_sales_performance.

## 8. Бизнес-правила

- В расчёте выручки учитываются только completed-заказы.
- Новым клиентом считается покупатель, совершивший первый завершённый заказ.
- Расходы моделируются равномерным распределением бюджета кампании по дням.
- ROI = (revenue - spend) / spend * 100%.
- Сумма заказа равна сумме quantity * price всех его товарных позиций.

Расходы являются расчётными, а не фактическими.

Данные синтетические и предназначены для проверки архитектуры и SQL-логики.

Отчётный период заканчивается 19 ноября 2026 года.

## 9. Оптимизация

Используются:
- DISTRIBUTED BY для распределённых таблиц.
- DISTRIBUTED REPLICATED для небольших справочников.
- Годовое партиционирование заказов и аналитической витрины.
- ANALYZE для сбора статистики.
- EXPLAIN ANALYZE для исследования планов выполнения.

Выявлен перекос распределения CDM между двумя сегментами. Текущее распределение по campaign_id сохранено с учётом небольшого объёма данных и характера аналитических запросов.

## 10. Проверка качества данных

Файл 10_validation.sql содержит проверки:

- Количества записей.
- Дублирующихся идентификаторов.
- Ссылочной целостности.
- Корректности дат заказов.
- Согласованности денежных сумм.
- Отсутствия дублирующихся групп CDM.
- Соответствия показателей DDS и CDM.

Успешное выполнение запросов и корректные контрольные результаты подтверждают согласованность данных.

## 11. Ограничения

Проект предназначен для учебного использования.

При повторном запуске скриптов наполнения без очистки таблиц могут возникнуть дубликаты.

Показатели производительности получены на небольшом объёме тестовых данных и не являются оценкой промышленной нагрузки.

Данные Docker-контейнера необходимо сохранять отдельно, если требуется их восстановление после удаления контейнера.
