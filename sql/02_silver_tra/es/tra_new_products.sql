/* =============================================================================
   Layer  : Silver / TRA  (transformation)
   Market : Spain
   Object : SILVER_TRA.D_ES_NEW_PRODUCT
   Purpose: Detect products present in the sell-in fact that are NOT yet in the
            product master for that source -> candidate "new products" to be
            attributed downstream.
   Engine : Snowflake
   ============================================================================= */

INSERT INTO SILVER_TRA.D_ES_NEW_PRODUCT
    (PDT_COD, PDT_PCK, SRC_COD, SRC_DSC_ORG, LOA_DAT)
SELECT DISTINCT
    f.PDT_COD,
    f.PDT_PCK,
    f.SRC_COD,
    f.SRC_DSC_ORG,
    f.LOA_DAT
FROM SILVER_TRA.D_ES_PANEL_I_NP f
JOIN SILVER_TRA.M_ES_PRODUCT dp ON f.PDT_COD = dp.PDT_COD
JOIN SILVER_TRA.M_ES_CATEGORY dc
     ON f.SRC_COD = dc.SRC_COD AND dp.CAT_DSC = dc.CAT_DSC
WHERE f.PDT_COD NOT IN (
    SELECT PDT_COD
    FROM SILVER_TRA.M_ES_PRODUCT
    WHERE ORG_DSC = 'PANEL_I'   -- anonymized source label
);
