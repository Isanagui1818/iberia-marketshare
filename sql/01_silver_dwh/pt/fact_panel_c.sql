/* =============================================================================
   Layer  : Silver / DWH  (fact normalization)
   Market : Portugal
   Source : PANEL_C
   Target : SILVER_DWH.FACT_PT_PANEL_C
   Notes  : Period arrives as 'MM/DD/YYYY'; normalized to YYYYMMDD.
   Engine : Snowflake
   ============================================================================= */

-- Delete-reload: drop the periods present in the new staging load (staging PER_DSC
-- normalized with the same expression the INSERT uses) before re-inserting them.
DELETE FROM SILVER_DWH.FACT_PT_PANEL_C
WHERE PER_DSC IN (
    SELECT DISTINCT TO_NUMBER(TO_CHAR(TO_DATE(PER_DSC,'MM/DD/YYYY'),'YYYYMMDD'))
    FROM BRONZE_STG.STG_PT_PANEL_C
    WHERE LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_PT_PANEL_C),
        DATE '1900-01-01')
);

INSERT INTO SILVER_DWH.FACT_PT_PANEL_C
    (PDT_COD, CHL_COD, SAL_TYP_COD, SRC_DSC, PER_DSC,
     SO_VALUES, SO_UNITS, SO_KILOS, SOURCE_CODE, LOA_DAT)
WITH cte_base AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY PDT_COD, PDT_PCK, CTG_DSC,
                         SO_VALUES, SO_UNITS, SO_KILOS, PER_DSC
            ORDER BY s.LOA_DAT DESC
        ) AS rn
    FROM BRONZE_STG.STG_PT_PANEL_C s
    WHERE s.LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_PT_PANEL_C),
        DATE '1900-01-01')
),
cte_keys AS (
    SELECT
        b.*,
        PDT_COD::STRING AS PDT_COD_N,
        TO_NUMBER(TO_CHAR(TO_DATE(PER_DSC,'MM/DD/YYYY'),'YYYYMMDD')) AS PER_DSC_NOR,
        'PANEL_C' AS CHL_ORIGEN_N,
        'PANEL_C' AS SALTYPE_ORIGEN_N
    FROM cte_base b
    WHERE rn = 1
),
cte_map_chl AS (
    SELECT UPPER(TRIM(CHL_SRC)) AS ORIGEN_N, CHL_COD
    FROM SILVER_DWH.MAP_PT_CHANNEL
    WHERE SRC_DSC = 'PANEL_C'
),
cte_map_st AS (
    SELECT UPPER(TRIM(SAL_TYP_SRC)) AS ORIGEN_N, SAL_TYP_COD
    FROM SILVER_DWH.MAP_PT_SALES_TYPE
    WHERE SRC_DSC = 'PANEL_C'
)
SELECT
    k.PDT_COD_N                  AS PDT_COD,
    COALESCE(chl.CHL_COD, 99)    AS CHL_COD,
    COALESCE(st.SAL_TYP_COD, 99) AS SAL_TYP_COD,
    'PANEL_C'                    AS SRC_DSC,
    k.PER_DSC_NOR                AS PER_DSC,
    k.SO_VALUES,
    k.SO_UNITS,
    k.SO_KILOS,
    k.SOURCE_CODE,
    k.LOA_DAT
FROM cte_keys k
LEFT JOIN cte_map_chl chl ON chl.ORIGEN_N = k.CHL_ORIGEN_N
LEFT JOIN cte_map_st  st  ON st.ORIGEN_N  = k.SALTYPE_ORIGEN_N;
