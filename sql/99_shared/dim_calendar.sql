/* =============================================================================
   Layer  : Shared dimension (conformed)
   Object : SILVER_DWH.DIM_CALENDAR
   Purpose: Daily calendar generated programmatically, exposing day/week/month/
            quarter/year grains plus ISO week, period keys and boundary flags.
   Engine : Snowflake (GENERATOR, ISO calendar functions)
   ============================================================================= */

WITH limits AS (
    SELECT TO_DATE('1990-01-01') AS min_date,
           TO_DATE('2070-12-31') AS max_date
),
days AS (
    SELECT DATEADD(day, ROW_NUMBER() OVER (ORDER BY seq4()) - 1, min_date) AS d,
           max_date
    FROM limits, TABLE(GENERATOR(ROWCOUNT => 30000))
),
calendar AS (
    SELECT
        d                                                         AS DAT_COD,
        TO_NUMBER(TO_CHAR(d,'YYYYMMDD'))                          AS DAT_KEY,
        TO_NUMBER(TO_CHAR(d,'YYYYMM'))                            AS PER_KEY,
        YEAR(d)                                                   AS YEA_COD,
        CASE WHEN MONTH(d) <= 6 THEN 1 ELSE 2 END                 AS SEM_COD,
        CASE WHEN MONTH(d) BETWEEN 1 AND 4 THEN 1
             WHEN MONTH(d) BETWEEN 5 AND 8 THEN 2 ELSE 3 END      AS QUA_COD,
        QUARTER(d)                                                AS QUA_DSC,
        CAST(TO_VARCHAR(YEAR(d)) || '-Q' || QUARTER(d) AS VARCHAR(20))  AS YEA_QUA,
        MONTH(d)                                                  AS MON_NUM,
        INITCAP(SUBSTR(MONTHNAME(d),1,3))                         AS MON_SHR,   -- Jan, Feb...
        CAST(TO_CHAR(d,'MMMM') AS VARCHAR(20))                    AS MON_LNG,   -- January...
        DAY(d)                                                    AS DAY_NUM,
        DAYOFWEEKISO(d)                                           AS DAY_WEK_NUM, -- 1=Mon..7=Sun
        INITCAP(DAYNAME(d))                                       AS DAY_WEK_NAM,
        WEEKISO(d)                                                AS WEK_YEA,     -- ISO 1..53
        CAST(TO_VARCHAR(YEAROFWEEKISO(d)) || '-W' ||
             LPAD(TO_VARCHAR(WEEKISO(d)),2,'0') AS VARCHAR(20))   AS YEA_WEK_ISO,
        CAST(TO_CHAR(d,'YYYY-MM') AS VARCHAR(10))                 AS YEA_MON,
        CAST(TO_CHAR(d,'Mon-YYYY') AS VARCHAR(10))                AS PER_NAM,
        CASE WHEN DAYOFWEEKISO(d) IN (6,7) THEN 1 ELSE 0 END                  AS WEK_END,
        CASE WHEN DATE_TRUNC(month,d)   = d THEN 1 ELSE 0 END                 AS MON_BGN,
        CASE WHEN LAST_DAY(d)           = d THEN 1 ELSE 0 END                 AS MON_END,
        CASE WHEN DATE_TRUNC(quarter,d) = d THEN 1 ELSE 0 END                 AS QUA_BGN,
        CASE WHEN LAST_DAY(DATEADD(month,2,DATE_TRUNC(quarter,d))) = d
             THEN 1 ELSE 0 END                                               AS QUA_END,
        CASE WHEN DATE_TRUNC(year,d)    = d THEN 1 ELSE 0 END                 AS YEA_BGN,
        CASE WHEN TO_DATE(TO_CHAR(YEAR(d))||'-12-31') = d THEN 1 ELSE 0 END   AS YEA_END,
        'SHARED_CALENDAR'                                         AS SRC_DSC_ORG,
        CURRENT_TIMESTAMP()                                       AS LOA_DAT
    FROM days
    WHERE d <= max_date
)
SELECT * FROM calendar;
