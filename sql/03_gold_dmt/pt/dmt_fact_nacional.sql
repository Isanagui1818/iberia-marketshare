/* =============================================================================
   Layer  : Gold / DMT  (data mart)
   Market : Portugal
   Object : GOLD_DMT.FACT_PT_NACIONAL
   Purpose: National-level fact. Unions PANEL_C, PANEL_B and PANEL_D, resolving each
            to a single product key via the national product master.
   Engine : Snowflake
   ============================================================================= */

INSERT INTO GOLD_DMT.FACT_PT_NACIONAL
    (PDT_COD, CHL_COD, SAL_TYP_COD, SRC_DSC, PER_DSC,
     SAL_VAL, SAL_UNT, SAL_WGT, SRC_DSC_ORG, LOA_DAT)
WITH producto_dedup AS (
    SELECT PDT_COD, PNL_C_COD, PNL_D_COD, PNL_B_COD
    FROM GOLD_DMT.M_PT_PRODUCT_NACIONAL
),
fact_union AS (
    SELECT e.PDT_COD, e.CHL_COD, e.SAL_TYP_COD, e.SRC_DSC, e.PER_DSC,
           e.SAL_UNT, e.SAL_VAL, e.SAL_WGT, e.SRC_DSC_ORG, e.LOA_DAT
    FROM SILVER_TRA.D_PT_PANEL_C e
    LEFT JOIN producto_dedup p ON e.PDT_COD = p.PNL_C_COD

    UNION ALL

    SELECT n.PDT_COD, n.CHL_COD, n.SAL_TYP_COD, n.SRC_DSC, n.PER_DSC,
           n.SAL_UNT, n.SAL_VAL, n.SAL_WGT, n.SRC_DSC_ORG, n.LOA_DAT
    FROM SILVER_TRA.D_PT_PANEL_B n
    LEFT JOIN producto_dedup p ON n.PDT_COD = p.PNL_B_COD

    UNION ALL

    SELECT h.PDT_COD, h.CHL_COD, h.SAL_TYP_COD, h.SRC_DSC, h.PER_DSC,
           h.SAL_UNT, h.SAL_VAL, NULL AS SAL_WGT, h.SRC_DSC_ORG, h.LOA_DAT
    FROM SILVER_TRA.D_PT_PANEL_D_UNION h
    LEFT JOIN producto_dedup p ON h.PDT_COD = p.PNL_D_COD
),
mapeo AS (
    SELECT
        f.*,
        COALESCE(p.PNL_C_COD, p.PNL_D_COD, p.PNL_B_COD, f.PDT_COD) AS PDT_COD_MAPPED
    FROM fact_union f
    LEFT JOIN producto_dedup p ON f.PDT_COD = p.PDT_COD
)
SELECT
    PDT_COD_MAPPED          AS PDT_COD,
    CHL_COD,
    SAL_TYP_COD,
    SRC_DSC,
    CAST(PER_DSC AS NUMBER) AS PER_DSC,
    SAL_VAL,
    SAL_UNT,
    SAL_WGT,
    SRC_DSC_ORG,
    LOA_DAT
FROM mapeo;
