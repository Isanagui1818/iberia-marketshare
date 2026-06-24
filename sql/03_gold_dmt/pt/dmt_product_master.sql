/* =============================================================================
   Layer  : Gold / DMT  (dimension)
   Market : Portugal
   Object : GOLD_DMT.DIM_PT_PRODUCT
   Purpose: Final product dimension. Cleans 'NA' tokens to NULL, derives a single
            PDT_COD by precedence across panel codes, and keeps the latest version
            per product via QUALIFY.
   Engine : Snowflake
   ============================================================================= */

INSERT INTO GOLD_DMT.DIM_PT_PRODUCT
WITH productos AS (
    SELECT
        NULLIF(UPPER(TRIM(PNL_D_COD)), 'NA') AS PNL_D_COD_CLE,
        NULLIF(UPPER(TRIM(PNL_B_COD)), 'NA') AS PNL_B_COD_CLE,
        NULLIF(UPPER(TRIM(EAN_COD)),   'NA') AS EAN_COD_CLE,
        NULLIF(UPPER(TRIM(PNL_C_COD)), 'NA') AS PNL_C_COD_CLE,
        NULLIF(UPPER(TRIM(PNL_A_COD)), 'NA') AS PNL_A_COD_CLE,
        STS_COD, PDT_DSC, PDT_PCK, GAM_DSC, NET_ARE, SUB_NET_ARE,
        CAT_DSC, SUB_CAT_DSC, CNY_DSC, BRD_DSC, SUB_BRD_DSC, ETP_COD,
        VOL_QTY, SAL_QTY, PMN_DSC, STG_DSC, UNT_PCK, FOR_WGH, UNT_DSC,
        INC_COD, GLB_REP, ORG_DSC, SRC_DSC_ORG, LOA_DAT
    FROM SILVER_TRA.M_PT_PRODUCT
)
SELECT
    COALESCE(PNL_C_COD_CLE, PNL_D_COD_CLE, PNL_B_COD_CLE) AS PDT_COD,
    PNL_D_COD_CLE AS PNL_D_COD,
    PNL_B_COD_CLE AS PNL_B_COD,
    EAN_COD_CLE   AS EAN_COD,
    PNL_C_COD_CLE AS PNL_C_COD,
    PNL_A_COD_CLE AS PNL_A_COD,
    STS_COD, NET_ARE, SUB_NET_ARE, CAT_DSC, SUB_CAT_DSC, CNY_DSC,
    BRD_DSC, SUB_BRD_DSC, PDT_DSC, PDT_PCK, GAM_DSC, ETP_COD,
    VOL_QTY, SAL_QTY, PMN_DSC, STG_DSC, UNT_PCK, FOR_WGH, UNT_DSC,
    INC_COD, GLB_REP, ORG_DSC, SRC_DSC_ORG, LOA_DAT
FROM productos
WHERE COALESCE(PNL_C_COD_CLE, PNL_D_COD_CLE, PNL_B_COD_CLE) IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY COALESCE(PNL_C_COD_CLE, PNL_D_COD_CLE, PNL_B_COD_CLE)
    ORDER BY LOA_DAT DESC
) = 1;
