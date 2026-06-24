/* =============================================================================
   Layer  : Silver / DWH  (fact normalization)
   Market : Portugal
   Source : PANEL_A  (food feed)
   Target : SILVER_DWH.FACT_PT_PANEL_A_FOOD
   Engine : Snowflake
   ============================================================================= */

DELETE FROM SILVER_DWH.FACT_PT_PANEL_A_FOOD
WHERE PER_DSC IN (
    SELECT DISTINCT TO_NUMBER(TO_CHAR(TO_DATE(PER_INI,'YYYY-MM-DD'),'YYYYMMDD'))
    FROM BRONZE_STG.STG_PT_PANEL_A_FOOD
    WHERE LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_PT_PANEL_A_FOOD),
        DATE '1900-01-01')
);

INSERT INTO SILVER_DWH.FACT_PT_PANEL_A_FOOD
    (PDT_COD, CHL_COD, SAL_TYP_COD, SRC_DSC, PER_DSC,
     SO_VALUES, SO_UNITS, SO_KILOS, SOURCE_CODE, LOA_DAT)
WITH cte_base AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY PDT_DSC, PDT_COD, PER_ALL, PER_INI, PER_FIN,
                         SO_UNITS, SO_VALUES, SO_KILOS
            ORDER BY s.LOA_DAT DESC
        ) AS rn
    FROM BRONZE_STG.STG_PT_PANEL_A_FOOD s
    WHERE PDT_DSC <> 'TOTAL'
      AND s.LOA_DAT > COALESCE(
          (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_PT_PANEL_A_FOOD),
          DATE '1900-01-01')
),
cte_keys AS (
    SELECT
        b.*,
        TO_NUMBER(TO_CHAR(TO_DATE(PER_INI,'YYYY-MM-DD'),'YYYYMMDD')) AS PER_DSC_NOR,
        'PANEL_A_FOOD' AS CHL_ORIGEN_N,
        'PANEL_A_FOOD' AS SALTYPE_ORIGEN_N
    FROM cte_base b
    WHERE rn = 1
),
cte_map_chl AS (
    SELECT UPPER(TRIM(CHL_SRC)) AS ORIGEN_N, CHL_COD
    FROM SILVER_DWH.MAP_PT_CHANNEL
    WHERE SRC_DSC = 'PANEL_A_FOOD'
),
cte_map_st AS (
    SELECT UPPER(TRIM(SAL_TYP_SRC)) AS ORIGEN_N, SAL_TYP_COD
    FROM SILVER_DWH.MAP_PT_SALES_TYPE
    WHERE SRC_DSC = 'PANEL_A_FOOD'
)
SELECT
    k.PDT_COD,
    COALESCE(chl.CHL_COD, 99)    AS CHL_COD,
    COALESCE(st.SAL_TYP_COD, 99) AS SAL_TYP_COD,
    'PANEL_A_FOOD'               AS SRC_DSC,
    k.PER_DSC_NOR                AS PER_DSC,
    k.SO_VALUES,
    k.SO_UNITS,
    k.SO_KILOS,
    k.SOURCE_CODE,
    k.LOA_DAT
FROM cte_keys k
LEFT JOIN cte_map_chl chl ON chl.ORIGEN_N = k.CHL_ORIGEN_N
LEFT JOIN cte_map_st  st  ON st.ORIGEN_N  = k.SALTYPE_ORIGEN_N;
