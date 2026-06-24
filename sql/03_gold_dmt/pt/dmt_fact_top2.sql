/* =============================================================================
   Layer  : Gold / DMT  (data mart)
   Market : Portugal
   Object : GOLD_DMT.FACT_PT_TOP2
   Purpose: Business-ready fact for the "Top-2 retailers" view. Unions the relevant
            panels and resolves every row to a single product key via the Top-2
            product master cross-reference.
   Engine : Snowflake
   ============================================================================= */

INSERT INTO GOLD_DMT.FACT_PT_TOP2
    (PDT_COD, CHL_COD, SAL_TYP_COD, SRC_DSC, PER_DSC,
     SAL_VAL, SAL_UNT, SAL_WGT, SRC_DSC_ORG, LOA_DAT)
WITH producto_top2 AS (
    SELECT PDT_COD, EAN_COD, PNL_C_COD, PNL_A_COD, PNL_D_COD
    FROM GOLD_DMT.M_PT_PRODUCT_TOP2
),
fact_union AS (
    -- PANEL_C (matches on its own code or the EAN barcode)
    SELECT e.PDT_COD, e.CHL_COD, e.SAL_TYP_COD, e.SRC_DSC, e.PER_DSC,
           e.SAL_VAL, e.SAL_UNT, e.SAL_WGT, e.SRC_DSC_ORG, e.LOA_DAT,
           p.EAN_COD, p.PNL_C_COD, p.PNL_A_COD, p.PNL_D_COD
    FROM SILVER_TRA.D_PT_PANEL_C e
    LEFT JOIN producto_top2 p ON e.PDT_COD = p.PNL_C_COD OR e.PDT_COD = p.EAN_COD

    UNION ALL

    -- PANEL_A (food feed)
    SELECT sf.PDT_COD, sf.CHL_COD, sf.SAL_TYP_COD, sf.SRC_DSC, sf.PER_DSC,
           sf.SAL_VAL, sf.SAL_UNT, sf.SAL_WGT, sf.SRC_DSC_ORG, sf.LOA_DAT,
           p.EAN_COD, p.PNL_C_COD, p.PNL_A_COD, p.PNL_D_COD
    FROM SILVER_TRA.D_PT_PANEL_A_FOOD sf
    LEFT JOIN producto_top2 p ON sf.PDT_COD = p.PNL_A_COD

    UNION ALL

    -- PANEL_A (milk feed)
    SELECT sm.PDT_COD, sm.CHL_COD, sm.SAL_TYP_COD, sm.SRC_DSC, sm.PER_DSC,
           sm.SAL_VAL, sm.SAL_UNT, sm.SAL_WGT, sm.SRC_DSC_ORG, sm.LOA_DAT,
           p.EAN_COD, p.PNL_C_COD, p.PNL_A_COD, p.PNL_D_COD
    FROM SILVER_TRA.D_PT_PANEL_A_MILK sm
    LEFT JOIN producto_top2 p ON sm.PDT_COD = p.PNL_A_COD
),
mapeo AS (
    SELECT
        f.*,
        COALESCE(f.EAN_COD, f.PNL_C_COD, f.PNL_A_COD, f.PNL_D_COD, f.PDT_COD)
            AS PDT_COD_MAPPED
    FROM fact_union f
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
