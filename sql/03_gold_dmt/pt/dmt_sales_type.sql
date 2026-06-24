/* =============================================================================
   Layer  : Gold / DMT  (dimension)
   Market : Portugal
   Object : GOLD_DMT.DIM_PT_SALES_TYPE
   Purpose: Sales-type dimension exposed to Power BI. Derives the parent channel
            code from the first digit of the sales-type code (hierarchical encoding).
   Engine : Snowflake
   ============================================================================= */

INSERT INTO GOLD_DMT.DIM_PT_SALES_TYPE
SELECT
    CAST(LEFT(TO_VARCHAR(SAL_TYP_COD), 1) AS INTEGER) AS CHL_COD,
    SAL_TYP_COD,
    SAL_TYP_DSC,
    SOURCE_CODE,
    LOA_DAT
FROM SILVER_DWH.DIM_PT_SALES_TYPE;
