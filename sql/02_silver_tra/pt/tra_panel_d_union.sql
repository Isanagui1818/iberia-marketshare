/* =============================================================================
   Layer  : Silver / TRA  (transformation, multi-feed union)
   Market : Portugal
   Source : PANEL_D  (mass market, pharmacy, metabolics pharmacy)
   Target : SILVER_TRA.TRA_PT_PANEL_D_UNION
   Notes  : Unions the 3 feeds, tags each, deduplicates on the business key, then
            resolves channel and sales-type codes from the TRA mapping tables.
   Engine : Snowflake
   ============================================================================= */

INSERT INTO SILVER_TRA.TRA_PT_PANEL_D_UNION
    (GEO_COD, PDT_COD, PER_DSC, SRC_DSC, SAL_TYP_COD, CHL_COD,
     SAL_VAL, SAL_UNT, SAL_CUN, SAL_PVA_VAL, SRC_DSC_ORG, LOA_DAT, SAL_ORG_COD)
WITH cte_base AS (
    SELECT GEO_COD, PDT_COD, PER_DSC, CHL_COD, SAL_VAL, SAL_UNT, SAL_CUN,
           SAL_PVA_VAL, SRC_DSC_ORG, LOA_DAT, SAL_ORG_COD,
           'PANEL_D_MASS'   AS SRC_DSC
    FROM SILVER_TRA.D_PT_PANEL_D_MASS
    UNION ALL
    SELECT GEO_COD, PDT_COD, PER_DSC, CHL_COD, SAL_VAL, SAL_UNT, SAL_CUN,
           SAL_PVA_VAL, SRC_DSC_ORG, LOA_DAT, SAL_ORG_COD,
           'PANEL_D_META'   AS SRC_DSC
    FROM SILVER_TRA.D_PT_PANEL_D_META
    UNION ALL
    SELECT GEO_COD, PDT_COD, PER_DSC, CHL_COD, SAL_VAL, SAL_UNT, SAL_CUN,
           SAL_PVA_VAL, SRC_DSC_ORG, LOA_DAT, SAL_ORG_COD,
           'PANEL_D_PHARMA' AS SRC_DSC
    FROM SILVER_TRA.D_PT_PANEL_D_PHARMA
),
cte_dedup AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (
            PARTITION BY GEO_COD, PDT_COD, CHL_COD, SRC_DSC, PER_DSC, SAL_VAL, SAL_UNT
            ORDER BY b.LOA_DAT DESC
        ) AS rn
    FROM cte_base b
),
cte_keys AS (
    SELECT
        d.*,
        SUBSTR(CAST(d.PER_DSC AS STRING), 1, 6) AS PER_DSC_NORMALIZADO,
        d.SRC_DSC AS ORIGEN_N
    FROM cte_dedup d
    WHERE rn = 1
),
cte_map_chl AS (
    SELECT UPPER(TRIM(SRC_DSC)) AS ORIGEN_N, CHL_SRC, CHL_COD
    FROM SILVER_TRA.MAP_PT_CHANNEL
    WHERE SRC_DSC IN ('PANEL_D_MASS','PANEL_D_PHARMA','PANEL_D_META')
),
cte_map_st AS (
    SELECT UPPER(TRIM(SRC_DSC)) AS ORIGEN_N, SAL_TYP_SRC, SAL_TYP_COD
    FROM SILVER_TRA.MAP_PT_SALES_TYPE
    WHERE SRC_DSC IN ('PANEL_D_MASS','PANEL_D_PHARMA','PANEL_D_META')
)
SELECT
    k.GEO_COD,
    k.PDT_COD,
    k.PER_DSC_NORMALIZADO AS PER_DSC,
    k.SRC_DSC,
    st.SAL_TYP_COD,
    ch.CHL_COD,
    k.SAL_VAL,
    k.SAL_UNT,
    k.SAL_CUN,
    k.SAL_PVA_VAL,
    k.SRC_DSC_ORG,
    k.LOA_DAT,
    k.SAL_ORG_COD
FROM cte_keys k
LEFT JOIN cte_map_st st ON st.ORIGEN_N = k.ORIGEN_N AND st.SAL_TYP_SRC = k.CHL_COD
LEFT JOIN cte_map_chl ch ON ch.ORIGEN_N = k.ORIGEN_N AND ch.CHL_SRC   = k.CHL_COD;
