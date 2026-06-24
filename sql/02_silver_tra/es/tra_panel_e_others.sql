/* =============================================================================
   Layer  : Silver / TRA  (transformation)
   Market : Spain
   Source : PANEL_E  (others feed)
   Target : SILVER_TRA.TRA_ES_PANEL_E_OTHERS
   Notes  : Channel is derived from a (category x channel-description) decision table.
            Category/channel labels shown here are anonymized placeholders.
   Engine : Snowflake (uses $$src_db parameter for portability)
   ============================================================================= */

INSERT INTO SILVER_TRA.TRA_ES_PANEL_E_OTHERS
    (PDT_COD, PDT_PCK, CHL_DSC, CAT_DSC, CNY_DSC, SGM_DSC, BRD_DSC,
     VRY_DSC, SVR_DSC, SBR_DSC, CPC_N01, CPC_N02, UPC_COD, CHL_COD,
     PER_DSC, SRC_COD, SAL_TYP_COD, KPI_FLG_COD, KPI_VAL, LOA_DAT, SRC_DSC_ORG)
WITH cte_base AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY CHL_DSC, PDT_PCK, CAT_DSC, CNY_DSC, SGM_DSC, BRD_DSC,
                         VRY_DSC, SVR_DSC, SBR_DSC, CPC_N01, CPC_N02, UPC_COD,
                         KPI_FLG, PER_DSC
            ORDER BY s.LOA_DAT DESC
        ) AS rn
    FROM $$src_db.BRONZE_STG.STG_ES_PANEL_E_OTHERS s
    WHERE s.LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM $$src_db.SILVER_TRA.TRA_ES_PANEL_E_OTHERS),
        DATE '1900-01-01')
),
cte_keys AS (
    SELECT
        b.*,
        UPPER(TRIM(PDT_PCK))            AS PDT_PCK_N,
        SHA2(UPPER(TRIM(PDT_PCK)), 256) AS PDT_COD_N,
        CASE
            WHEN CAT_DSC = 'CATEGORY_A' AND CHL_DSC = 'CHANNEL_ONLINE'    THEN 2
            WHEN CAT_DSC = 'CATEGORY_A' AND CHL_DSC = 'CHANNEL_HYPER'     THEN 3
            WHEN CAT_DSC = 'CATEGORY_A' AND CHL_DSC = 'CHANNEL_SUPER'     THEN 4
            WHEN CAT_DSC = 'CATEGORY_A' AND CHL_DSC = 'CHANNEL_DISCOUNT'  THEN 5
            WHEN CAT_DSC = 'CATEGORY_B' AND CHL_DSC = 'CHANNEL_ONLINE'    THEN 6
            WHEN CAT_DSC = 'CATEGORY_B' AND CHL_DSC = 'CHANNEL_HYPER'     THEN 7
            WHEN CAT_DSC = 'CATEGORY_B' AND CHL_DSC = 'CHANNEL_SUPER'     THEN 8
            WHEN CAT_DSC = 'CATEGORY_B' AND CHL_DSC = 'CHANNEL_DISCOUNT'  THEN 9
            ELSE 99
        END AS CHL_COD,
        'PANEL_E'             AS SALTYPE_ORIGEN_N,
        UPPER(TRIM(KPI_FLG))  AS UNITS_ORIGEN_N,
        COALESCE(KPI_VAL, 0)  AS KPI_VAL_N
    FROM cte_base b
    WHERE CHL_DSC <> 'TOTAL_MARKET'   -- exclude pre-aggregated market totals
),
cte_map_st AS (
    SELECT UPPER(TRIM(SAL_TYP_SRC)) AS ORIGEN_N, SAL_TYP_COD
    FROM $$src_db.SILVER_TRA.MAP_ES_SALES_TYPE WHERE SRC_DSC = 'PANEL_E'
),
cte_map_unt AS (
    SELECT UPPER(TRIM(KPI_FLG_SRC)) AS ORIGEN_N, KPI_FLG_COD
    FROM $$src_db.SILVER_TRA.MAP_ES_UNITS      WHERE SRC_DSC = 'PANEL_E_OTHERS'
)
SELECT
    k.PDT_COD_N AS PDT_COD,
    k.PDT_PCK_N AS PDT_PCK,
    k.CHL_DSC, k.CAT_DSC, k.CNY_DSC, k.SGM_DSC, k.BRD_DSC,
    k.VRY_DSC, k.SVR_DSC, k.SBR_DSC, k.CPC_N01, k.CPC_N02, k.UPC_COD,
    k.CHL_COD,
    k.PER_DSC,
    3 AS SRC_COD,
    COALESCE(st.SAL_TYP_COD, 99)  AS SAL_TYP_COD,
    COALESCE(unt.KPI_FLG_COD, 99) AS KPI_FLG_COD,
    k.KPI_VAL_N AS KPI_VAL,
    k.LOA_DAT,
    k.SRC_DSC_ORG
FROM cte_keys k
LEFT JOIN cte_map_st  st  ON st.ORIGEN_N  = k.SALTYPE_ORIGEN_N
LEFT JOIN cte_map_unt unt ON unt.ORIGEN_N = k.UNITS_ORIGEN_N
WHERE k.rn = 1 AND k.UPC_COD <> 'Not Available';
