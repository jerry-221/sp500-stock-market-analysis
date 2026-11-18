# S&P 500 Stock Market Performance & Trend Analysis (2014–2017)

## Project Overview
This project is an end-to-end data analytics and business intelligence solution analyzing historical daily stock data for S&P 500 companies from January 2014 to December 2017. The objective is to transform raw market data into structured, actionable insights regarding market trends, individual stock performance, volatility, and trading activity. 

**Technology Stack:** Python (JupyterLab), MySQL, Power BI.

## Repository Contents
- `S&P 500 Stock Prices 2014-2017.csv`: The raw source dataset.
- `S&P_500_Stock_Prices_clean.csv`: The cleaned, feature-engineered dataset ready for analysis.
- `S&P_500_Stock_Prices .ipynb`: Jupyter Notebook containing data cleaning, EDA, and feature engineering.
- `data_quality_report.csv`: A summary of the data anomalies found and handled during the cleaning phase.
- `sp500_analysis_queries.sql`: MySQL scripts containing foundational and advanced analytical queries.
- `SP500_Dashboard.pbix`: The interactive Power BI dashboard.
- `Dashboard_Screenshots/`: PNG images of the three dashboard pages.

---

## Methodology: Problems, Solutions, and Rationale

During the data preparation phase, several anomalies were detected. The following approach was taken to ensure the analytical dataset was robust and accurate.

### 1. Data Cleaning & Quality Assurance
**The Problem:** The raw dataset contained missing values, duplicate records, and logical inconsistencies (e.g., the `high` price being lower than the `low` price). Additionally, there was a single-row anomaly for the stock `GOOG`.
**The Solution:** 
- Records with missing OHLC (Open, High, Low, Close) values were dropped rather than imputed. 
- Duplicates were removed using the `(symbol, date)` combination. 
- The single-row `GOOG` anomaly was removed because `GOOGL` represents the same company and the single row would distort time-series aggregations (like volatility and moving averages).
**The Rationale:** Imputing stock prices using averages or forward-filling distorts historical reality and creates artificial zero-volatility days. It is analytically safer to drop the small fraction of invalid records (documented in `data_quality_report.csv`) to maintain data integrity.

### 2. Feature Engineering
To answer complex business questions, 25+ new features were engineered from the base columns. 
- **Returns:** `daily_return_pct` and `intraday_change_pct` were created. A critical step here was passing `fill_method=None` to pandas `pct_change()` to prevent silent forward-filling.
- **Trends:** Moving averages (`ma_7`, `ma_30`, `ma_50`) were calculated using `.groupby('symbol').transform()`. This ensures that rolling windows do not bleed data from one stock into another.
- **Risk:** `volatility_30d` (rolling standard deviation) and `drawdown_pct` (running peak to current price) were added to quantify risk.
- **Volume:** `relative_volume` was calculated by dividing daily volume by the 30-day moving average of volume, allowing for the identification of unusual trading activity.
**The Rationale:** Raw OHLC data is difficult to compare across different stocks. Percentage returns, moving averages, and volatility metrics normalize the data, enabling fair, relative comparisons across all 504 tickers.

### 3. SQL Analysis
The clean dataset was loaded into MySQL. Basic queries were used for aggregations (e.g., top stocks by volume). Advanced queries utilized **Common Table Expressions (CTEs)** and **Window Functions** (`ROW_NUMBER`, `DENSE_RANK`, `NTILE`).
**The Rationale:** Window functions are essential for time-series data. `ROW_NUMBER` was specifically used to isolate the first and last available closing prices for each stock to calculate cumulative returns accurately, regardless of missing dates.

---

## Power BI Dashboard

The Power BI report utilizes a Star Schema, connecting a central `StockData` fact table to `DimDate` and `DimStock` dimension tables for optimal performance and filtering.

### Page 1: Market Overview
Focuses on macro-level market trends over the four years, highlighting average closing prices and the ratio of positive to negative trading days.
![Market Overview](Dashboard_Screenshots/page1_market_overview.png)

### Page 2: Stock Performance (Winners & Losers)
Identifies the top and bottom cumulative performers. This page includes a drill-down chart to view an individual stock's price against its 30-day and 50-day moving averages.
![Stock Performance](Dashboard_Screenshots/page2_stock_performance.png)

### Page 3: Volatility & Activity
Analyzes risk. It highlights the most volatile stocks, maximum drawdowns, and plots the relationship between unusual trading volume and intraday price ranges.
![Volatility & Activity](Dashboard_Screenshots/page3_volatility_activity.png)

---

## Key Business Insights

1. **Extreme Outliers Drive Returns:** `NVDA` and `NFLX` were the undisputed winners of this era, yielding massive cumulative returns. Conversely, the energy sector collapse (2014–2016) dragged `CHK` and `RRC` down by over 80%.
2. **Volatility Cycles:** Market volatility was noticeably higher in 2015 and 2016 (driven by the August 2015 flash crash and early 2016 oil panic) compared to the historically calm baseline of 2017.
3. **Volume as a Signal:** As demonstrated on Page 3, high relative-volume trading days (>=3x the 30-day average) correlate with significantly wider intraday price ranges, confirming that unusual volume often precedes or accompanies institutional activity or news events.

---

## Project Limitations
- **No Adjusted Closing Prices:** The dataset does not account for stock splits or dividends. Therefore, cumulative returns represent price appreciation, not total shareholder return.
- **Lack of Sector Data:** Without sector classifications, cross-sectional analysis is limited to individual tickers rather than broader industry trends.
- **Historical Scope:** Analysis is restricted to the 2014–2017 window and does not reflect current market conditions.

## How to Reproduce
1. Clone the repository.
2. Install dependencies: `pip install pandas numpy matplotlib seaborn sqlalchemy pymysql jupyterlab`.
3. Run the Jupyter Notebook (`S&P_500_Stock_Prices .ipynb`) to generate the cleaned CSV.
4. Execute the scripts in `sp500_analysis_queries.sql` using a MySQL environment.
5. Open `SP500_Dashboard.pbix` in Power BI Desktop to view the visualizations.

*Disclaimer: This project is for educational and portfolio purposes only and does not constitute financial advice.*
