/* =============================================================================
   Layer  : Silver / TRA  (transformation)
   Market : Spain
   Source : PANEL_E  (pharma feed)
   Target : SILVER_TRA.TRA_ES_PANEL_E_PHARMA
   Notes  : Channel is a fixed literal (1) for this feed. Output at fact grain.
            (Original re-projected CHL_COD twice via SELECT k.* -> duplicate column;
            fixed here with an explicit projection.)
   Engine : Snowflake
   ============================================================================= */

INSERT INTO SILVER_TRA.TRA_ES_PANEL_E_PHARMA
    (PDT_COD, PDT_PCK, CHL_COD, SAL_TYP_COD, KPI_FLG_COD, KPI_VAL,
     PER_DSC, SRC_COD, SRC_DSC_ORG, LOA_DAT)
WITH cte_base AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY MKT_DSC, GEO_DSC, TYP_MKT_DSC, SGM_DSC, SGM_SUB_DSC,
                         CNY_DSC, PDT_DSC, PDT_PCK, KPI_FLG, PER_DSC
            ORDER BY s.LOA_DAT DESC
        ) AS rn
    FROM BRONZE_STG.STG_ES_PANEL_E_PHARMA s
    WHERE s.LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_TRA.TRA_ES_PANEL_E_PHARMA),
        DATE '1900-01-01')
),
cte_keys AS (
    SELECT
        b.*,
        UPPER(TRIM(PDT_PCK))            AS PDT_PCK_N,
        SHA2(UPPER(TRIM(PDT_PCK)), 256) AS PDT_COD_N,
        1                              AS CHL_COD,          -- fixed channel for pharma
        'PANEL_E'                      AS SALTYPE_ORIGEN_N,
        UPPER(TRIM(KPI_FLG))           AS UNITS_ORIGEN_N,
        COALESCE(KPI_VAL, 0)           AS KPI_VAL_N
    FROM cte_base b
    WHERE b.rn = 1
),
cte_map_st AS (
    SELECT UPPER(TRIM(SAL_TYP_SRC)) AS ORIGEN_N, SAL_TYP_COD
    FROM SILVER_TRA.MAP_ES_SALES_TYPE WHERE SRC_DSC = 'PANEL_E'
),
cte_map_unt AS (
    SELECT UPPER(TRIM(KPI_FLG_SRC)) AS ORIGEN_N, KPI_FLG_COD
    FROM SILVER_TRA.MAP_ES_UNITS      WHERE SRC_DSC = 'PANEL_E_PHARMA'
)
SELECT
    k.PDT_COD_N                   AS PDT_COD,
    k.PDT_PCK_N                   AS PDT_PCK,
    k.CHL_COD,
    COALESCE(st.SAL_TYP_COD, 99)  AS SAL_TYP_COD,
    COALESCE(unt.KPI_FLG_COD, 99) AS KPI_FLG_COD,
    k.KPI_VAL_N                   AS KPI_VAL,
    k.PER_DSC,
    4                             AS SRC_COD,
    k.SRC_DSC_ORG,
    k.LOA_DAT
FROM cte_keys k
LEFT JOIN cte_map_st  st  ON st.ORIGEN_N  = k.SALTYPE_ORIGEN_N
LEFT JOIN cte_map_unt unt ON unt.ORIGEN_N = k.UNITS_ORIGEN_N;
