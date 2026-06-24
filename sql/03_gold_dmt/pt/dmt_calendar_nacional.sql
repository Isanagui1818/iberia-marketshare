/* =============================================================================
   Layer  : Gold / DMT  (dimension)
   Market : Portugal
   Object : GOLD_DMT.DIM_PT_CALENDAR_NACIONAL
   Purpose: Monthly calendar bounded by the min/max period actually present in the
            national fact, with localized (PT) month labels and last-year shifts and
            "current month / current year" flags used by the Power BI slicers.
   Engine : Snowflake
   ============================================================================= */

INSERT INTO GOLD_DMT.DIM_PT_CALENDAR_NACIONAL
WITH limits AS (
    SELECT
        TO_DATE(CASE
            WHEN LENGTH(CAST(PER_DSC AS STRING)) = 6 THEN CAST(PER_DSC AS STRING) || '01'
            WHEN LENGTH(CAST(PER_DSC AS STRING)) = 8 THEN CAST(PER_DSC AS STRING)
        END, 'YYYYMMDD') AS min_date,
        TO_DATE(CASE
            WHEN LENGTH(CAST(PER_DSC AS STRING)) = 6 THEN CAST(PER_DSC AS STRING) || '01'
            WHEN LENGTH(CAST(PER_DSC AS STRING)) = 8 THEN CAST(PER_DSC AS STRING)
        END, 'YYYYMMDD') AS max_date
    FROM GOLD_DMT.FACT_PT_NACIONAL
),
base AS (
    SELECT DATE_TRUNC(month, s.DAT_COD) AS DATE_M
    FROM SILVER_TRA.D_PT_CALENDAR s
    JOIN limits l ON s.DAT_COD BETWEEN l.min_date AND l.max_date
    GROUP BY DATE_TRUNC(month, s.DAT_COD)
),
calendar AS (
    SELECT
        DATE_M                                            AS DAT_COD,
        DATEADD(month, -12, DATE_M)                       AS DAT_LSY,
        TO_NUMBER(TO_CHAR(DATE_M,'YYYYMM'))               AS PER_DSC,
        YEAR(DATE_M)                                      AS YEA_DSC,
        YEAR(DATE_M) - 1                                  AS YEA_LSY,
        MONTH(DATE_M)                                     AS MON_NUM,
        CAST(CASE MONTH(DATE_M)
            WHEN 1 THEN 'JAN' WHEN 2 THEN 'FEV' WHEN 3 THEN 'MAR'
            WHEN 4 THEN 'ABR' WHEN 5 THEN 'MAI' WHEN 6 THEN 'JUN'
            WHEN 7 THEN 'JUL' WHEN 8 THEN 'AGO' WHEN 9 THEN 'SET'
            WHEN 10 THEN 'OUT' WHEN 11 THEN 'NOV' WHEN 12 THEN 'DEZ'
        END AS VARCHAR(10))                               AS MON_SHR,
        CAST(CASE MONTH(DATE_M)
            WHEN 1 THEN 'JANEIRO' WHEN 2 THEN 'FEVEREIRO' WHEN 3 THEN 'MARÇO'
            WHEN 4 THEN 'ABRIL' WHEN 5 THEN 'MAIO' WHEN 6 THEN 'JUNHO'
            WHEN 7 THEN 'JULHO' WHEN 8 THEN 'AGOSTO' WHEN 9 THEN 'SETEMBRO'
            WHEN 10 THEN 'OUTUBRO' WHEN 11 THEN 'NOVEMBRO' WHEN 12 THEN 'DEZEMBRO'
        END AS VARCHAR(20))                               AS MON_LNG,
        QUARTER(DATE_M)                                   AS QUA_DSC,
        CAST(TO_CHAR(DATE_M,'YYYY') || '-Q' || QUARTER(DATE_M) AS VARCHAR(20)) AS YEA_QUA,
        CAST(TO_CHAR(DATE_M,'YYYY') || ' ' ||
            CASE MONTH(DATE_M)
                WHEN 1 THEN 'JAN' WHEN 2 THEN 'FEV' WHEN 3 THEN 'MAR'
                WHEN 4 THEN 'ABR' WHEN 5 THEN 'MAI' WHEN 6 THEN 'JUN'
                WHEN 7 THEN 'JUL' WHEN 8 THEN 'AGO' WHEN 9 THEN 'SET'
                WHEN 10 THEN 'OUT' WHEN 11 THEN 'NOV' WHEN 12 THEN 'DEZ'
            END AS VARCHAR(20))                           AS PER_NAM,
        CASE WHEN DATE_TRUNC(month, DATE_M) = DATE_TRUNC(month, CURRENT_DATE)
             THEN 1 ELSE 0 END                            AS CUR_MON,
        'GOLD_CALENDAR'                                   AS SRC_DSC_ORG,
        CURRENT_TIMESTAMP()                               AS LOA_DAT
    FROM base
)
SELECT
    DAT_COD, DAT_LSY, PER_DSC, YEA_DSC, YEA_LSY, MON_NUM, MON_SHR, MON_LNG,
    QUA_DSC, YEA_QUA, PER_NAM, CUR_MON,
    CASE WHEN MON_NUM = (SELECT MONTH(MAX(DATE_M)) FROM base)
         THEN 'Mes Actual' ELSE 'Otros Meses' END AS MAX_MON,
    CASE WHEN YEA_DSC = (SELECT YEAR(MAX(DATE_M)) FROM base)
         THEN 'Año Actual' ELSE 'Otros Años' END  AS MAX_YEA,
    SRC_DSC_ORG, LOA_DAT
FROM calendar;
