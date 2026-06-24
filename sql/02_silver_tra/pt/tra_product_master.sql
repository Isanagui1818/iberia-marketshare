/* =============================================================================
   Layer  : Silver / TRA  (product master)
   Market : Portugal
   Target : SILVER_TRA.M_PT_PRODUCT
   Purpose: Cleansed product master cross-referencing each panel's product code
            (PNL_A/B/C/D + EAN barcode). Appends a single "NOT_ASSIGNED" member so
            fact rows that fail to match still resolve to a valid product key.
   Engine : Snowflake
   ============================================================================= */

INSERT INTO SILVER_TRA.M_PT_PRODUCT
WITH aud AS (   -- carry the real audit values onto the fallback member
    SELECT MAX(SRC_DSC_ORG) AS SRC_DSC_ORG, MAX(LOA_DAT) AS LOA_DAT
    FROM BRONZE_STG.STG_PT_PRODUCT
)
SELECT
    UPPER(TRIM(PNL_D_COD)) AS PNL_D_COD,
    UPPER(TRIM(PNL_C_COD)) AS PNL_C_COD,
    UPPER(TRIM(PNL_A_COD)) AS PNL_A_COD,
    UPPER(TRIM(PNL_B_COD)) AS PNL_B_COD,
    UPPER(TRIM(EAN_COD))   AS EAN_COD,
    TRIM(STS_COD)          AS STS_COD,
    UPPER(TRIM(NET_ARE))      AS NET_ARE,
    UPPER(TRIM(SUB_NET_ARE))  AS SUB_NET_ARE,
    UPPER(TRIM(CAT_DSC))      AS CAT_DSC,
    UPPER(TRIM(SUB_CAT_DSC))  AS SUB_CAT_DSC,
    UPPER(TRIM(CNY_DSC))      AS CNY_DSC,
    UPPER(TRIM(BRD_DSC))      AS BRD_DSC,
    UPPER(TRIM(SUB_BRD_DSC))  AS SUB_BRD_DSC,
    UPPER(TRIM(PDT_DSC))      AS PDT_DSC,
    UPPER(TRIM(PDT_PCK))      AS PDT_PCK,
    UPPER(TRIM(GAM_DSC))      AS GAM_DSC,
    UPPER(TRIM(ETP_COD))      AS ETP_COD,
    UPPER(TRIM(VOL_QTY))      AS VOL_QTY,
    UPPER(TRIM(SAL_QTY))      AS SAL_QTY,
    UPPER(TRIM(PMN_DSC))      AS PMN_DSC,
    UPPER(TRIM(STG_DSC))      AS STG_DSC,
    UPPER(TRIM(UNT_PCK))      AS UNT_PCK,
    UPPER(TRIM(FOR_WGH))      AS FOR_WGH,
    UPPER(TRIM(UNT_DSC))      AS UNT_DSC,
    UPPER(TRIM(INC_COD))      AS INC_COD,
    UPPER(TRIM(GLB_REP))      AS GLB_REP,
    UPPER(TRIM(ORG_DSC))      AS ORG_DSC,
    SRC_DSC_ORG,
    LOA_DAT
FROM BRONZE_STG.STG_PT_PRODUCT

UNION ALL

-- Fallback "NOT_ASSIGNED" member (code 99) with real audit metadata.
SELECT
    '99','99','99','99','99','1',
    'NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED',
    'NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED',
    'NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED',
    'NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED','NOT_ASSIGNED',
    'NOT_ASSIGNED',
    aud.SRC_DSC_ORG, aud.LOA_DAT
FROM aud;
