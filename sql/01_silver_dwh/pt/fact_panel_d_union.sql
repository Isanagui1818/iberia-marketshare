/* =============================================================================
   Layer  : Silver / DWH  (fact normalization, multi-feed union)
   Market : Portugal
   Source : PANEL_D  (3 feeds: mass market, pharmacy, metabolics pharmacy)
   Target : SILVER_DWH.FACT_PT_PANEL_D_UNION
   Notes  : The 3 feeds are unioned, tagged with their feed name, deduplicated,
            then a single sales-type mapping is applied by (feed, sales-type code).
   Engine : Snowflake
   ============================================================================= */

-- Idempotent reload: drop the periods present across any feed's incoming batch.
DELETE FROM SILVER_DWH.FACT_PT_PANEL_D_UNION t
USING (
    SELECT DISTINCT PER_DSC
    FROM (
        SELECT PER_DSC, LOA_DAT FROM BRONZE_STG.STG_PT_PANEL_D_MASS
        UNION ALL
        SELECT PER_DSC, LOA_DAT FROM BRONZE_STG.STG_PT_PANEL_D_PHARMA
        UNION ALL
        SELECT PER_DSC, LOA_DAT FROM BRONZE_STG.STG_PT_PANEL_D_META
    ) s
    WHERE s.LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_PT_PANEL_D_UNION),
        DATE '1900-01-01')
) u
WHERE t.PER_DSC = u.PER_DSC;

INSERT INTO SILVER_DWH.FACT_PT_PANEL_D_UNION
    (GEO_COD, PDT_COD, PER_DSC, SRC_DSC, SO_VALUES, SO_UNITS,
     CHL_COD, SAL_TYP_COD, SOURCE_CODE, LOA_DAT)
WITH cte_base AS (
    SELECT s.*, 'PANEL_D_MASS'   AS SRC_DSC FROM SILVER_TRA.TRA_PT_PANEL_D_MASS s
    UNION ALL
    SELECT s.*, 'PANEL_D_META'   AS SRC_DSC FROM SILVER_TRA.TRA_PT_PANEL_D_META s
    UNION ALL
    SELECT s.*, 'PANEL_D_PHARMA' AS SRC_DSC FROM SILVER_TRA.TRA_PT_PANEL_D_PHARMA s
),
cte_dedup AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (
            PARTITION BY GEO_COD, PDT_COD, CHL_COD, SRC_DSC, PER_DSC,
                         SO_VALUES, SO_UNITS
            ORDER BY b.LOA_DAT DESC
        ) AS rn
    FROM cte_base b
    WHERE b.LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_PT_PANEL_D_UNION),
        DATE '1900-01-01')
),
cte_keys AS (
    SELECT
        d.*,
        SUBSTR(CAST(d.PER_DSC AS STRING), 1, 6) AS PER_DSC_YYYYMM,
        CASE
            WHEN d.SRC_DSC = 'PANEL_D_MASS'   THEN '2'
            WHEN d.SRC_DSC = 'PANEL_D_PHARMA' THEN '3'
            WHEN d.SRC_DSC = 'PANEL_D_META'   THEN '4'
        END AS SAL_TYP_SRC
    FROM cte_dedup d
    WHERE rn = 1
),
cte_map_st AS (
    SELECT
        UPPER(TRIM(SRC_DSC))     AS SRC_DSC,
        UPPER(TRIM(SAL_TYP_SRC)) AS SAL_TYP_SRC,
        SAL_TYP_COD
    FROM SILVER_DWH.MAP_PT_SALES_TYPE
    WHERE SRC_DSC IN ('PANEL_D_MASS','PANEL_D_PHARMA','PANEL_D_META')
      AND SAL_TYP_SRC IN ('2','3','4')
)
SELECT
    k.GEO_COD,
    k.PDT_COD,
    k.PER_DSC_YYYYMM AS PER_DSC,
    k.SRC_DSC,
    k.SO_VALUES,
    k.SO_UNITS,
    k.CHL_COD,
    st.SAL_TYP_COD,
    k.SOURCE_CODE,
    k.LOA_DAT
FROM cte_keys k
LEFT JOIN cte_map_st st
       ON st.SRC_DSC     = UPPER(TRIM(k.SRC_DSC))
      AND st.SAL_TYP_SRC = k.SAL_TYP_SRC;
