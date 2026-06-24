/* =============================================================================
   Layer  : Silver / DWH  (fact normalization)
   Market : Portugal
   Source : PANEL_B
   Target : SILVER_DWH.FACT_PT_PANEL_B
   Notes  : Period arrives as localized month abbreviation + 2-digit year
            (e.g. 'jan24'); parsed into YYYYMM. Geography hashed (UPPER/TRIM)
            into a stable surrogate key.
   Engine : Snowflake
   ============================================================================= */

DELETE FROM SILVER_DWH.FACT_PT_PANEL_B
WHERE PER_DSC IN (
    SELECT DISTINCT PER_DSC
    FROM SILVER_DWH.FACT_PT_PANEL_B
    WHERE LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_PT_PANEL_B),
        DATE '1900-01-01')
);

INSERT INTO SILVER_DWH.FACT_PT_PANEL_B
    (GEO_COD, GEO_DSC, PDT_COD, CHL_COD, SAL_TYP_COD, SRC_DSC, PER_DSC,
     SO_VALUES, SO_UNITS, SO_KILOS, SOURCE_CODE, LOA_DAT)
WITH cte_base AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY GEO_DSC, PER_DSC, PDT_PCK, PDT_COD, UPC_COD, CNY_DSC,
                         BRD_DSC, SGM_DSC, SSG_DSC, SBR_DSC, STG_DSC, CPC_DSC,
                         SO_VALUES, SO_UNITS, SO_KILOS
            ORDER BY s.LOA_DAT DESC
        ) AS rn
    FROM BRONZE_STG.STG_PT_PANEL_B s
    WHERE s.LOA_DAT > COALESCE(
        (SELECT MAX(LOA_DAT) FROM SILVER_DWH.FACT_PT_PANEL_B),
        DATE '1900-01-01')
),
cte_keys AS (
    SELECT
        b.*,
        PDT_COD::STRING                  AS PDT_COD_N,
        SHA2(UPPER(TRIM(GEO_DSC)), 256)  AS GEO_COD_N,
        CAST(
            '20' || REGEXP_SUBSTR(PER_DSC, '\\b\\d{2}\\b') ||
            CASE
                WHEN LOWER(PER_DSC) LIKE 'jan%' THEN '01'
                WHEN LOWER(PER_DSC) LIKE 'fev%' THEN '02'
                WHEN LOWER(PER_DSC) LIKE 'mar%' THEN '03'
                WHEN LOWER(PER_DSC) LIKE 'abr%' THEN '04'
                WHEN LOWER(PER_DSC) LIKE 'mai%' THEN '05'
                WHEN LOWER(PER_DSC) LIKE 'jun%' THEN '06'
                WHEN LOWER(PER_DSC) LIKE 'jul%' THEN '07'
                WHEN LOWER(PER_DSC) LIKE 'ago%' THEN '08'
                WHEN LOWER(PER_DSC) LIKE 'set%' THEN '09'
                WHEN LOWER(PER_DSC) LIKE 'out%' THEN '10'
                WHEN LOWER(PER_DSC) LIKE 'nov%' THEN '11'
                WHEN LOWER(PER_DSC) LIKE 'dez%' THEN '12'
                ELSE '00'   -- guard: unmatched month -> detectable, never silent NULL
            END
        AS VARCHAR(6)) AS PER_DSC_NOR,
        'PANEL_B' AS CHL_ORIGEN_N,
        'PANEL_B' AS SALTYPE_ORIGEN_N
    FROM cte_base b
    WHERE rn = 1
),
cte_map_chl AS (
    SELECT UPPER(TRIM(CHL_SRC)) AS ORIGEN_N, CHL_COD
    FROM SILVER_DWH.MAP_PT_CHANNEL
    WHERE SRC_DSC = 'PANEL_B'
),
cte_map_st AS (
    SELECT UPPER(TRIM(SAL_TYP_SRC)) AS ORIGEN_N, SAL_TYP_COD
    FROM SILVER_DWH.MAP_PT_SALES_TYPE
    WHERE SRC_DSC = 'PANEL_B'
)
SELECT
    k.GEO_COD_N                  AS GEO_COD,
    k.GEO_DSC                    AS GEO_DSC,
    k.PDT_COD_N                  AS PDT_COD,
    COALESCE(chl.CHL_COD, 99)    AS CHL_COD,
    COALESCE(st.SAL_TYP_COD, 99) AS SAL_TYP_COD,
    'PANEL_B'                    AS SRC_DSC,
    k.PER_DSC_NOR                AS PER_DSC,
    k.SO_VALUES,
    k.SO_UNITS,
    k.SO_KILOS,
    k.SOURCE_CODE,
    k.LOA_DAT
FROM cte_keys k
LEFT JOIN cte_map_chl chl ON chl.ORIGEN_N = k.CHL_ORIGEN_N
LEFT JOIN cte_map_st  st  ON st.ORIGEN_N  = k.SALTYPE_ORIGEN_N;
