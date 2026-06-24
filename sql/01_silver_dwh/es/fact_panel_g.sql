/* =============================================================================
   Layer  : Silver / DWH  (fact normalization)
   Market : Spain
   Source : PANEL_G
   Target : SILVER_DWH.FACT_ES_PANEL_G
   Notes  : Product key derived from product description (hashed).
   Engine : Snowflake
   ============================================================================= */

INSERT INTO SILVER_DWH.FACT_ES_PANEL_G
    (PDT_COD, PDT_PCK, CHL_COD, SAL_TYP_COD, KPI_FLG_COD, KPI_VAL,
     PER_DSC, SRC_COD, SRC_DSC_ORG, LOA_DAT)
WITH cte_base AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY MKT_DSC, GEO_DSC, PDT_DSC, PER_DSC, KPI_FLG
            ORDER BY s.LOA_DAT DESC
        ) AS rn
    FROM BRONZE_STG.STG_ES_PANEL_G s
    WHERE s.LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_ES_PANEL_G),
        DATE '1900-01-01')
),
cte_keys AS (
    SELECT
        b.*,
        UPPER(TRIM(PDT_DSC))            AS PDT_PCK_N,
        SHA2(UPPER(TRIM(PDT_DSC)), 256) AS PDT_COD_N,
        'PANEL_G'                       AS CHL_ORIGEN_N,
        'PANEL_G'                       AS SALTYPE_ORIGEN_N,
        UPPER(TRIM(KPI_FLG))            AS UNITS_ORIGEN_N,
        COALESCE(KPI_VAL, 0)            AS KPI_VAL_N
    FROM cte_base b
    WHERE b.rn = 1
),
cte_map_chl AS (
    SELECT UPPER(TRIM(CHL_SRC)) AS ORIGEN_N, CHL_COD
    FROM SILVER_DWH.MAP_ES_CHANNEL    WHERE SRC_DSC = 'PANEL_G'
),
cte_map_st AS (
    SELECT UPPER(TRIM(SAL_TYP_SRC)) AS ORIGEN_N, SAL_TYP_COD
    FROM SILVER_DWH.MAP_ES_SALES_TYPE WHERE SRC_DSC = 'PANEL_G'
),
cte_map_unt AS (
    SELECT UPPER(TRIM(KPI_FLG_SRC)) AS ORIGEN_N, KPI_FLG_COD
    FROM SILVER_DWH.MAP_ES_UNITS      WHERE SRC_DSC = 'PANEL_G'
)
SELECT
    k.PDT_COD_N                   AS PDT_COD,
    k.PDT_PCK_N                   AS PDT_PCK,
    COALESCE(chl.CHL_COD, 99)     AS CHL_COD,
    COALESCE(st.SAL_TYP_COD, 99)  AS SAL_TYP_COD,
    COALESCE(unt.KPI_FLG_COD, 99) AS KPI_FLG_COD,
    k.KPI_VAL_N                   AS KPI_VAL,
    k.PER_DSC,
    5                             AS SRC_COD,
    k.SRC_DSC_ORG,
    k.LOA_DAT
FROM cte_keys k
LEFT JOIN cte_map_chl chl ON chl.ORIGEN_N = k.CHL_ORIGEN_N
LEFT JOIN cte_map_st  st  ON st.ORIGEN_N  = k.SALTYPE_ORIGEN_N
LEFT JOIN cte_map_unt unt ON unt.ORIGEN_N = k.UNITS_ORIGEN_N;
