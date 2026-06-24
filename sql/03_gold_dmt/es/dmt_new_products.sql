/* =============================================================================
   Layer  : Gold / DMT  (data mart)
   Market : Spain
   Object : GOLD_DMT.DIM_ES_NEW_PRODUCT
   Purpose: Enrich the detected new products with their descriptive attributes,
            keeping the latest record per product pack.
   Engine : Snowflake
   ============================================================================= */

INSERT INTO GOLD_DMT.DIM_ES_NEW_PRODUCT
    (CNY_DSC, PDT_DSC, PDT_PCK, CAT_DSC,
     OTC_N01, OTC_N02, OTC_N03, OTC_N04, SRC_COD, SRC_DSC_ORG, LOA_DAT)
WITH attribute_np AS (
    SELECT *
    FROM (
        SELECT
            brz.*,
            np.SRC_COD,
            ROW_NUMBER() OVER (
                PARTITION BY brz.PDT_PCK ORDER BY brz.LOA_DAT DESC
            ) AS rn
        FROM BRONZE_STG.STG_ES_PANEL_I_NP brz
        INNER JOIN SILVER_TRA.D_ES_NEW_PRODUCT np
            ON UPPER(TRIM(brz.PDT_PCK)) = np.PDT_PCK
    )
    WHERE rn = 1
)
SELECT
    CNY_DSC, PDT_DSC, PDT_PCK, CAT_DSC,
    OTC_N01, OTC_N02, OTC_N03, OTC_N04,
    SRC_COD, SRC_DSC_ORG, LOA_DAT
FROM attribute_np;
