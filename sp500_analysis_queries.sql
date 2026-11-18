-- ============================================================
-- S&P 500 Stock Prices 2014–2017 — SQL Analysis
-- Author: <PRANAV PATIL>
-- Date:   2026-11-14
-- Tools:  MySQL Workbench 8.x
-- Database: sp500_analysis
-- Table:    stock_daily
-- Source:   S&P_500_Stock_Prices_clean.csv (496,500 rows, 32 cols)
-- ============================================================

-- (setup used only once — keep commented for reference)
--  SHOW databases;
--  USE sp500_analysis;
--  SHOW tables;
--  DESCRIBE stock_daily;
--  SELECT COUNT(*) FROM stock_daily;



-- ============================================================
-- SECTION A — Essential Queries (11 questions)
-- ============================================================

-- ═══════════════════════════════════════════════════════════════
-- QUESTION_1: Did all my data actually load?
-- ═══════════════════════════════════════════════════════════════
SELECT
    COUNT(*)                 AS total_rows,
    COUNT(DISTINCT symbol)   AS unique_stocks,
    MIN(date)                AS first_date,
    MAX(date)                AS last_date,
    MIN(year)                AS first_year,
    MAX(year)                AS last_year
FROM stock_daily;


-- ═══════════════════════════════════════════════════════════════
-- QUESTION_2: Top 10 stocks by average daily volume
-- ═══════════════════════════════════════════════════════════════
SELECT
    symbol,
    ROUND(AVG(volume), 0)  AS avg_daily_volume,
    SUM(volume)            AS total_volume
FROM stock_daily
GROUP BY symbol
ORDER BY avg_daily_volume DESC
LIMIT 10;

-- ═══════════════════════════════════════════════════════════════
-- QUESTION_3: Top 10 stocks by average closing price
-- ═══════════════════════════════════════════════════════════════
SELECT
    symbol,
    ROUND(AVG(close), 2)  AS avg_close,
    ROUND(MAX(close), 2)  AS max_close
FROM stock_daily
GROUP BY symbol
ORDER BY avg_close DESC
LIMIT 10;


-- ═══════════════════════════════════════════════════════════════
-- QUESTION_4: Bottom 10 stocks by average closing price
-- ═══════════════════════════════════════════════════════════════
SELECT
    symbol,
    ROUND(AVG(close), 2)  AS avg_close,
    ROUND(MIN(close), 2)  AS min_close
FROM stock_daily
GROUP BY symbol
ORDER BY avg_close ASC
LIMIT 10;

-- ═══════════════════════════════════════════════════════════════
-- QUESTION_5: Positive vs negative days, ranked by % positive
-- ═══════════════════════════════════════════════════════════════
SELECT
    symbol,
    SUM(CASE WHEN daily_return_pct > 0 THEN 1 ELSE 0 END) AS positive_days,
    SUM(CASE WHEN daily_return_pct < 0 THEN 1 ELSE 0 END) AS negative_days,
    ROUND(
      100.0 * SUM(CASE WHEN daily_return_pct > 0 THEN 1 ELSE 0 END)
            / COUNT(daily_return_pct),
      2
    ) AS pct_positive
FROM stock_daily
WHERE daily_return_pct IS NOT NULL
GROUP BY symbol
ORDER BY pct_positive DESC
LIMIT 20;

-- ═══════════════════════════════════════════════════════════════
-- QUESTION_6: Which year had the strongest average daily return?
-- ═══════════════════════════════════════════════════════════════
SELECT
    year,
    ROUND(AVG(daily_return_pct), 4)          AS avg_daily_return_pct,
    ROUND(STDDEV_SAMP(daily_return_pct), 4)  AS volatility,
    COUNT(*)                                  AS trading_rows
FROM stock_daily
WHERE daily_return_pct IS NOT NULL
GROUP BY year
ORDER BY year;

-- ═══════════════════════════════════════════════════════════════
-- QUESTION_7: Which month (across all years) had the strongest return?
-- ═══════════════════════════════════════════════════════════════
SELECT
    month,
    month_name,
    ROUND(AVG(daily_return_pct), 4) AS avg_return,
    COUNT(*)                         AS trading_rows
FROM stock_daily
WHERE daily_return_pct IS NOT NULL
GROUP BY month, month_name
ORDER BY avg_return DESC;

-- ═══════════════════════════════════════════════════════════════
-- QUESTION_8: Top 10 single-day gains
-- ═══════════════════════════════════════════════════════════════
SELECT
    symbol, date, daily_return_pct, close
FROM stock_daily
WHERE daily_return_pct IS NOT NULL
ORDER BY daily_return_pct DESC
LIMIT 10;


-- ═══════════════════════════════════════════════════════════════
-- QUESTION_9: Top 10 single-day losses
-- ═══════════════════════════════════════════════════════════════
SELECT
    symbol, date, daily_return_pct, close
FROM stock_daily
WHERE daily_return_pct IS NOT NULL
ORDER BY daily_return_pct ASC
LIMIT 10;

-- ═══════════════════════════════════════════════════════════════
-- QUESTION_10: Top 10 highest-volatility stocks (min 100 obs)
-- ═══════════════════════════════════════════════════════════════
SELECT
    symbol,
    ROUND(STDDEV_SAMP(daily_return_pct), 4) AS volatility,
    COUNT(*)                                 AS observations
FROM stock_daily
WHERE daily_return_pct IS NOT NULL
GROUP BY symbol
HAVING COUNT(*) >= 100
ORDER BY volatility DESC
LIMIT 10;

-- ═══════════════════════════════════════════════════════════════
-- QUESTION_11: Average monthly trading volume (all stocks)
-- ═══════════════════════════════════════════════════════════════
SELECT
    year, month, month_name,
    ROUND(AVG(volume), 0) AS avg_volume
FROM stock_daily
GROUP BY year, month, month_name
ORDER BY year, month;



-- ============================================================
-- SECTION B — Advanced Analysis (9 questions)
-- ============================================================

-- ------------------------------------------------------------
-- QUESTION_12: Top 10 stocks by cumulative return over the whole 4-year window
-- Uses ROW_NUMBER to pick first and last observation per stock.
-- ------------------------------------------------------------
SELECT
    symbol,
    first_close, last_close,
    ROUND((last_close - first_close) / first_close * 100, 2) AS cumulative_return_pct
FROM (
    SELECT
        symbol,
        MAX(CASE WHEN rn_first = 1 THEN close END) AS first_close,
        MAX(CASE WHEN rn_last  = 1 THEN close END) AS last_close
    FROM (
        SELECT
            symbol, date, close,
            ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date)       AS rn_first,
            ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC)  AS rn_last
        FROM stock_daily
    ) ranked
    GROUP BY symbol
) sub
ORDER BY cumulative_return_pct DESC
LIMIT 10;


-- ------------------------------------------------------------
-- QUESTION_13: Bottom 10 — biggest cumulative losers
-- ------------------------------------------------------------
SELECT
    symbol,
    first_close, last_close,
    ROUND((last_close - first_close) / first_close * 100, 2) AS cumulative_return_pct
FROM (
    SELECT
        symbol,
        MAX(CASE WHEN rn_first = 1 THEN close END) AS first_close,
        MAX(CASE WHEN rn_last  = 1 THEN close END) AS last_close
    FROM (
        SELECT
            symbol, date, close,
            ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date)       AS rn_first,
            ROW_NUMBER() OVER (PARTITION BY symbol ORDER BY date DESC)  AS rn_last
        FROM stock_daily
    ) ranked
    GROUP BY symbol
) sub
ORDER BY cumulative_return_pct ASC
LIMIT 10;


-- ------------------------------------------------------------
-- QUESTION_14: Rank stocks by annual return, per year (DENSE_RANK over partition)
-- (Answers "How did individual stock performance differ across the four years?")
-- ------------------------------------------------------------
WITH yearly AS (
    SELECT
        symbol, year,
        MAX(CASE WHEN rn_first = 1 THEN close END) AS first_close,
        MAX(CASE WHEN rn_last  = 1 THEN close END) AS last_close
    FROM (
        SELECT
            symbol, year, close,
            ROW_NUMBER() OVER (PARTITION BY symbol, year ORDER BY date)       AS rn_first,
            ROW_NUMBER() OVER (PARTITION BY symbol, year ORDER BY date DESC)  AS rn_last
        FROM stock_daily
    ) r
    GROUP BY symbol, year
)
SELECT
    year, symbol,
    ROUND((last_close - first_close) / first_close * 100, 2) AS annual_return_pct,
    DENSE_RANK() OVER (
        PARTITION BY year
        ORDER BY (last_close - first_close) / first_close DESC
    ) AS rnk
FROM yearly
WHERE first_close IS NOT NULL
ORDER BY year, rnk
LIMIT 40;


-- ------------------------------------------------------------
-- QUESTION_15: Only the #1 stock in each year
-- ------------------------------------------------------------
WITH yearly AS (
    SELECT
        symbol, year,
        MAX(CASE WHEN rn_first = 1 THEN close END) AS first_close,
        MAX(CASE WHEN rn_last  = 1 THEN close END) AS last_close
    FROM (
        SELECT
            symbol, year, close,
            ROW_NUMBER() OVER (PARTITION BY symbol, year ORDER BY date)       AS rn_first,
            ROW_NUMBER() OVER (PARTITION BY symbol, year ORDER BY date DESC)  AS rn_last
        FROM stock_daily
    ) r
    GROUP BY symbol, year
),
ranked AS (
    SELECT
        year, symbol,
        ROUND((last_close - first_close) / first_close * 100, 2) AS annual_return_pct,
        DENSE_RANK() OVER (
            PARTITION BY year
            ORDER BY (last_close - first_close) / first_close DESC
        ) AS rnk
    FROM yearly
)
SELECT year, symbol, annual_return_pct
FROM ranked
WHERE rnk = 1
ORDER BY year;


-- ------------------------------------------------------------
-- QUESTION_16: Stocks that traded above their 30-day MA most consistently
-- (Answers BRD "Which stocks consistently traded above their 30-day MA?")
-- Uses trend_status — no need for a derived flag column.
-- ------------------------------------------------------------
SELECT
    symbol,
    ROUND(
        100.0 * SUM(CASE WHEN trend_status = 'Above 30-Day MA' THEN 1 ELSE 0 END)
              / SUM(CASE WHEN trend_status IN ('Above 30-Day MA','Below 30-Day MA') THEN 1 ELSE 0 END),
        2
    ) AS pct_days_above_ma30
FROM stock_daily
WHERE ma_30 IS NOT NULL
GROUP BY symbol
ORDER BY pct_days_above_ma30 DESC
LIMIT 10;


-- ------------------------------------------------------------
-- QUESTION_17: Unusual-volume sessions that coincided with big intraday moves
-- (Answers "Is high trading volume associated with large price movements?")
-- ------------------------------------------------------------
SELECT
    symbol, date, volume,
    ROUND(relative_volume, 2)     AS rel_vol,
    ROUND(intraday_range_pct, 2)  AS intraday_range_pct
FROM stock_daily
WHERE relative_volume >= 3
ORDER BY intraday_range_pct DESC
LIMIT 20;


-- ------------------------------------------------------------
-- QUESTION_18: Compare average intraday range on high-volume vs low-volume days
-- (Splits every trade into quintiles by relative_volume, reports mean range)
-- ------------------------------------------------------------
WITH buckets AS (
    SELECT
        relative_volume,
        intraday_range_pct,
        NTILE(5) OVER (ORDER BY relative_volume) AS vol_bucket
    FROM stock_daily
    WHERE relative_volume IS NOT NULL
      AND intraday_range_pct IS NOT NULL
)
SELECT
    CASE vol_bucket
        WHEN 1 THEN '1 — Very Low Volume'
        WHEN 2 THEN '2 — Low Volume'
        WHEN 3 THEN '3 — Medium Volume'
        WHEN 4 THEN '4 — High Volume'
        WHEN 5 THEN '5 — Very High Volume'
    END AS volume_bucket,
    COUNT(*)                          AS n_trades,
    ROUND(AVG(intraday_range_pct), 3) AS avg_intraday_range_pct
FROM buckets
GROUP BY vol_bucket
ORDER BY vol_bucket;


-- ------------------------------------------------------------
-- QUESTION_19: Worst max-drawdown stocks
-- (Answers "Which stocks experienced the largest price decline?")
-- ------------------------------------------------------------
SELECT
    symbol,
    ROUND(MIN(drawdown_pct), 2) AS max_drawdown_pct,
    COUNT(*)                    AS observations
FROM stock_daily
WHERE drawdown_pct IS NOT NULL
GROUP BY symbol
ORDER BY max_drawdown_pct ASC
LIMIT 10;


-- ------------------------------------------------------------
-- QUESTION_20: Which month had the highest average return by year (2D view)
-- (Answers "How did individual stock performance differ across the four years?")
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT
        year, month, month_name,
        ROUND(AVG(daily_return_pct), 4) AS avg_return
    FROM stock_daily
    WHERE daily_return_pct IS NOT NULL
    GROUP BY year, month, month_name
)
SELECT *
FROM monthly
ORDER BY avg_return DESC
LIMIT 15;









