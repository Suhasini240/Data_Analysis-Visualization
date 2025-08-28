--SQL Project I 
-- Q1: Daily ridership vs 2019 baseline (for line chart + color bands)
 ALL SELECT ride_date, 'Metro-North',  metro_north_total,     metro_north_pct_2019    FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'Bridges_Tunnels', bridges_tunnels_total, bridges_tunnels_pct_2019 FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'Staten_Island_Railway', staten_island_total, staten_island_pct_2019 FROM mta_daily_ridership
)
SELECT
  dte,
  mode,
  total,
  (pct_2019 * 100.0)                    AS pct_of_2019,         -- 100 = equal to comparable 2019 day
  ((pct_2019 - WITH base AS (
  SELECT ride_date AS dte, 'Subway' AS mode, subways_total::bigint AS total, subways_pct_2019::numeric AS pct_2019 FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'Bus',          buses_total,           buses_pct_2019          FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'LIRR',         lirr_total,            lirr_pct_2019           FROM mta_daily_ridership
  UNION1.0) * 100.0)            AS pct_change_vs_2019,  -- -35 = 35% below 2019
  CASE
    WHEN EXTRACT(YEAR FROM dte) = 2020 THEN '2020 (drop)'
    WHEN EXTRACT(YEAR FROM dte) BETWEEN 2021 AND 2025 THEN '2021–2025 (recovery)'
    ELSE 'Other'
  END AS period_band
FROM base
ORDER BY dte, mode;

-- Q2: Indexed recovery by mode (baseline = avg of first available 10 days per mode)
WITH base AS (
  SELECT ride_date AS dte, 'Subway' AS mode, subways_total::bigint AS total FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'Bus',          buses_total           FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'LIRR',         lirr_total            FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'Metro-North',  metro_north_total     FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'Bridges_Tunnels', bridges_tunnels_total FROM mta_daily_ridership
  UNION ALL SELECT ride_date, 'Staten_Island_Railway', staten_island_total FROM mta_daily_ridership
),
-- Prefer earliest date in 2020 if present; else earliest date overall
first_2020 AS (
  SELECT mode, MIN(dte) AS first_dte_2020
  FROM base
  WHERE EXTRACT(YEAR FROM dte) = 2020
  GROUP BY mode
),
first_any AS (
  SELECT mode, MIN(dte) AS first_dte_any
  FROM base
  GROUP BY mode
),
anchor AS (
  SELECT
    fa.mode,
    COALESCE(f2.first_dte_2020, fa.first_dte_any) AS anchor_dte
  FROM first_any fa
  LEFT JOIN first_2020 f2 USING (mode)
),
baseline AS (
  -- average of the first 10 available days starting at the anchor date
  SELECT
    b.mode,
    AVG(b.total)::numeric AS base_total
  FROM base b
  JOIN anchor a ON a.mode = b.mode
  WHERE b.dte >= a.anchor_dte
    AND b.dte <  a.anchor_dte + INTERVAL '10 days'
    AND b.total IS NOT NULL
  GROUP BY b.mode
)
SELECT
  b.dte,
  b.mode,
  b.total,
  CASE WHEN bl.base_total > 0 THEN 100.0 * b.total / bl.base_total END AS index_baseline100
FROM base b
JOIN baseline bl USING (mode)
ORDER BY b.dte, b.mode;


--Q3.What are the seasonal and weekly patterns of ridership?: Seasonal & weekly patterns 
WITH base AS (
  SELECT mdr.ride_date AS dte, 'Subway' AS mode,
         mdr.subways_total::bigint AS total, mdr.subways_pct_2019::numeric AS pct_2019
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Bus',
         mdr.buses_total::bigint, mdr.buses_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'LIRR',
         mdr.lirr_total::bigint, mdr.lirr_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Metro-North',
         mdr.metro_north_total::bigint, mdr.metro_north_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Bridges_Tunnels',
         mdr.bridges_tunnels_total::bigint, mdr.bridges_tunnels_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Staten_Island_Railway',
         mdr.staten_island_total::bigint, mdr.staten_island_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
)
SELECT
  mode,
  EXTRACT(ISODOW FROM dte)::int  AS dow,    -- 1=Mon … 7=Sun
  EXTRACT(MONTH  FROM dte)::int  AS month,  -- 1..12
  AVG(total)::numeric            AS avg_riders,
  AVG(pct_2019)::numeric         AS avg_pct_of_2019
FROM base
GROUP BY mode, EXTRACT(ISODOW FROM dte), EXTRACT(MONTH FROM dte)
ORDER BY mode, month, dow;

-- Q4: Weekend vs Weekday recovery (avg % of 2019)-- Has weekend ridership recovered differently than weekday ridership?
--Just for EDA not included in tableau visual
WITH base AS (
  SELECT mdr.ride_date AS dte, 'Subway' AS mode,
         mdr.subways_total::bigint AS total, mdr.subways_pct_2019::numeric AS pct_2019
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Bus',
         mdr.buses_total::bigint, mdr.buses_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'LIRR',
         mdr.lirr_total::bigint, mdr.lirr_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Metro-North',
         mdr.metro_north_total::bigint, mdr.metro_north_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Bridges_Tunnels',
         mdr.bridges_tunnels_total::bigint, mdr.bridges_tunnels_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Staten_Island_Railway',
         mdr.staten_island_total::bigint, mdr.staten_island_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
)
SELECT
  mode,
  CASE WHEN EXTRACT(ISODOW FROM dte) IN (6,7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
  AVG(pct_2019 * 100.0)::numeric AS avg_pct_of_2019, -- 100 = equal to comparable 2019 day
  AVG(total)::numeric           AS avg_riders,       -- optional, for context labels
  COUNT(*)                      AS n_days            -- optional, to see sample size
FROM base
GROUP BY mode, CASE WHEN EXTRACT(ISODOW FROM dte) IN (6,7) THEN 'Weekend' ELSE 'Weekday' END
ORDER BY mode, day_type;

---- Q5: Detect anomalies vs 7-day moving average
-- Q5 UPDATED: Anomalies vs 7-day moving average (20% threshold)
WITH base AS (
  SELECT mdr.ride_date AS dte, 'Subway' AS mode, mdr.subways_total::bigint AS total
  FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'Bus', mdr.buses_total::bigint FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'LIRR', mdr.lirr_total::bigint FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'Metro-North', mdr.metro_north_total::bigint FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'Bridges_Tunnels', mdr.bridges_tunnels_total::bigint FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'Staten_Island_Railway', mdr.staten_island_total::bigint FROM public.mta_daily_ridership mdr
),
ma AS (
  SELECT
    dte,
    mode,
    total,
    AVG(total) OVER (
      PARTITION BY mode
      ORDER BY dte
      ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
    )::numeric AS ma7
  FROM base
),
final AS (
  SELECT
    dte,
    mode,
    total,
    ma7,
    (total - ma7)                          AS delta,
    CASE WHEN ma7 > 0 THEN (total - ma7)/ma7 END AS rel_dev,            -- +/- fraction vs MA7
    CASE WHEN ma7 > 0 THEN ((total - ma7)/ma7) * 100.0 END AS pct_delta, -- +/- %
    CASE WHEN ma7 > 0 AND ABS((total - ma7)/ma7) >= 0.2 THEN TRUE ELSE FALSE END AS is_anomaly
  FROM ma
)
SELECT
  dte, mode, total, ma7, delta,
  ROUND(pct_delta, 1) AS pct_delta,    -- nice for tooltips
  is_anomaly
FROM final
ORDER BY dte, mode;

 
-------------

WITH base AS (
  SELECT mdr.ride_date AS dte, 'Subway' AS mode, mdr.subways_total::bigint AS total
  FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'Bus', mdr.buses_total::bigint FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'LIRR', mdr.lirr_total::bigint FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'Metro-North', mdr.metro_north_total::bigint FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'Bridges_Tunnels', mdr.bridges_tunnels_total::bigint FROM public.mta_daily_ridership mdr
  UNION ALL SELECT mdr.ride_date, 'Staten_Island_Railway', mdr.staten_island_total::bigint FROM public.mta_daily_ridership mdr
),
ma AS (
  SELECT
    dte, mode, total,
    AVG(total) OVER (PARTITION BY mode ORDER BY dte ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING)::numeric AS ma7
  FROM base
),
final AS (
  SELECT dte, mode, total, ma7,
         CASE WHEN ma7 > 0 AND ABS((total - ma7)/ma7) >= 0.2 THEN TRUE ELSE FALSE END AS is_anomaly
  FROM ma
)
SELECT
  mode,
  SUM(CASE WHEN is_anomaly THEN 1 ELSE 0 END) AS anomaly_days,
  COUNT(*)                                     AS total_days,
  ROUND(100.0 * SUM(CASE WHEN is_anomaly THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_days_anomalous
FROM final
GROUP BY mode
ORDER BY anomaly_days DESC;








--Q6. What is the forecasted ridership for 2026 if current trends continue?
---- Monthly series for forecasting
WITH base AS (
  SELECT mdr.ride_date AS dte, 'Subway' AS mode,
         mdr.subways_total::bigint AS total, mdr.subways_pct_2019::numeric AS pct_2019
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Bus',
         mdr.buses_total::bigint, mdr.buses_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'LIRR',
         mdr.lirr_total::bigint, mdr.lirr_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Metro-North',
         mdr.metro_north_total::bigint, mdr.metro_north_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Bridges_Tunnels',
         mdr.bridges_tunnels_total::bigint, mdr.bridges_tunnels_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
  UNION ALL
  SELECT mdr.ride_date, 'Staten_Island_Railway',
         mdr.staten_island_total::bigint, mdr.staten_island_pct_2019::numeric
  FROM public.mta_daily_ridership mdr
)
SELECT
  DATE_TRUNC('month', dte)::date AS month,
  mode,
  SUM(total)::bigint            AS riders,
  AVG(pct_2019 * 100.0)::numeric AS avg_pct_of_2019
FROM base
WHERE dte IS NOT NULL
GROUP BY 1,2
ORDER BY month, mode;

--KPI 
--1
WITH latest AS (
  SELECT MAX(ride_date) AS d FROM mta_daily_ridership
),
long AS (
  SELECT 'Subway' AS mode, m.subways_pct_2019 * 100.0 AS recovery_pct
  FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Bus',           m.buses_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'LIRR',          m.lirr_pct_2019 * 100.0  FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Metro-North',   m.metro_north_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Bridges_Tunnels', m.bridges_tunnels_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Staten_Island_Railway', m.staten_island_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
)
SELECT ROUND(AVG(recovery_pct)::numeric, 2) AS avg_recovery_pct
FROM long;


--2
WITH latest AS (
  SELECT MAX(ride_date) AS d FROM mta_daily_ridership
),
long AS (
  SELECT 'Subway' AS mode, m.subways_pct_2019 * 100.0 AS recovery_pct
  FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Bus',           m.buses_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'LIRR',          m.lirr_pct_2019 * 100.0  FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Metro-North',   m.metro_north_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Bridges_Tunnels', m.bridges_tunnels_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Staten_Island_Railway', m.staten_island_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
)
SELECT mode, ROUND(recovery_pct::numeric, 2) AS highest_recovery_pct
FROM long
ORDER BY recovery_pct DESC, mode ASC
LIMIT 1;

--3
WITH latest AS (
  SELECT MAX(ride_date) AS d FROM mta_daily_ridership
),
long AS (
  SELECT 'Subway' AS mode, m.subways_pct_2019 * 100.0 AS recovery_pct
  FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Bus',           m.buses_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'LIRR',          m.lirr_pct_2019 * 100.0  FROM mta_daily_ridership m JOIN latest l ON m.ride_date= l.d
  UNION ALL SELECT 'Metro-North',   m.metro_north_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date= l.d
  UNION ALL SELECT 'Bridges_Tunnels', m.bridges_tunnels_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date = l.d
  UNION ALL SELECT 'Staten_Island_Railway', m.staten_island_pct_2019 * 100.0 FROM mta_daily_ridership m JOIN latest l ON m.ride_date= l.d
)
SELECT mode, ROUND(recovery_pct::numeric, 2) AS lowest_recovery_pct
FROM long
ORDER BY recovery_pct ASC, mode ASC
LIMIT 1;











