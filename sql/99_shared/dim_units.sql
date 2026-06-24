/* =============================================================================
   Layer  : Shared dimension (conformed)
   Object : GOLD_DMT.DIM_UNITS
   Purpose: Measure catalogue used by the Power BI model.
            The fact tables carry KPI_FLG_COD; this dimension gives it a label
            and a unit of measure.
   Engine : Snowflake
   ============================================================================= */

SELECT KPI_FLG_COD, KPI_FLG_DSC, UNT_LBL
FROM VALUES
    (1, 'Volume', 'Kg'),
    (2, 'Value',  'EUR'),
    (3, 'Units',  'Uds'),
    (4, 'Volume', 'L'),     -- liters feed (e.g. liquid formats)
    (99,'Not Assigned', 'NA')
AS DIM_UNITS (KPI_FLG_COD, KPI_FLG_DSC, UNT_LBL);
