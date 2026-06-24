/* =============================================================================
   Layer  : Gold / consumption star schema  (GOLD_STAR.*)
   Purpose: The dimensional model the BI tools consume — this is what
            `dashboards/data/*.csv` is exported from. Kept 1:1 with that data so
            the SQL "generates" the dataset used by Power BI / Streamlit / Evidence.
   Source : conformed dims (99_shared) + the Gold marts (03_gold_dmt) + the
            product/company master. Engine: Snowflake.
   Markets: ES + PT folded into one anonymized model (focal company = 'Compañía SN').
   ============================================================================= */

-- ----------------------------------------------------------------------------
-- Conformed dimensions
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE GOLD_STAR.DIM_CALENDAR AS
SELECT
    "Date", "Year", "Quarter", "Month Number", "Month Short", "Month Long",
    "Period ID",                        -- YYYYMM (grain of the model)
    "Period Name", "Year Quarter",
    "Year LY", "Date LY",               -- last-year shifts for time-intel
    "Current Year", "Current Month"
FROM SILVER_DWH.DIM_CALENDAR;           -- 99_shared/dim_calendar.sql

CREATE OR REPLACE TABLE GOLD_STAR.DIM_SOURCE (
    "Source ID"   INTEGER,
    "Source Name" STRING                -- Panel A / Panel B / Internal ...
);

CREATE OR REPLACE TABLE GOLD_STAR.DIM_CATEGORY (
    "Category ID"   INTEGER,
    "Category Name" STRING,
    "Source ID"     INTEGER             -- snowflake -> DIM_SOURCE
);

CREATE OR REPLACE TABLE GOLD_STAR.DIM_SALES_TYPE (
    "Sales Type ID"   INTEGER,
    "Sales Type Name" STRING            -- Sell-In / Sell-Out / Transfer
);

-- Channel hierarchy (added with the dataset extension)
CREATE OR REPLACE TABLE GOLD_STAR.DIM_CHANNEL (
    "Channel ID"   INTEGER,
    "Channel Name" STRING,
    "Channel"      STRING,              -- = Channel Name (breakdown field)
    "SubChannel"   STRING,
    "Type Channel" STRING               -- Entorno: Online / Offline
);

-- 4 measures used by the report (KPI Flag is the "Métrica" breakdown label)
CREATE OR REPLACE TABLE GOLD_STAR.DIM_UNITS AS
SELECT * FROM VALUES
    (1, 'Volume', 'Kg',  'Volumen Kg'),
    (2, 'Value',  'EUR', 'Valor €'),
    (3, 'Units',  'Uds', 'Unidades'),
    (4, 'Volume', 'L',   'Volumen L')
AS DIM_UNITS ("KPI Flag ID", "KPI Flag Name", "Unit Label", "KPI Flag");

-- Product master (extended with Manufacturer / Sub Category / Sub Brand / Market / Product)
CREATE OR REPLACE TABLE GOLD_STAR.DIM_PROD (
    "Product ID"        INTEGER,
    "Product Name"      STRING,
    "Product"           STRING,         -- = Product Name (breakdown field)
    "Brand"             STRING,
    "Sub Brand"         STRING,
    "Manufacturer"      STRING,         -- the "Compañía" dimension (~19, focal 'Compañía SN')
    "Business Area"     STRING,
    "Business Sub Area" STRING,
    "Category"          STRING,
    "Category ID"       INTEGER,
    "Sub Category"      STRING,
    "Market"            STRING,
    "Format"            STRING,
    "Etapas"            STRING,
    "EP"                FLOAT,
    "CUnits"            INTEGER,         -- units per pack (to derive Units)
    "Conversor LKG"     FLOAT,          -- Kg -> L factor (to derive Volume L)
    "Product Pack"      STRING
);

-- ----------------------------------------------------------------------------
-- Fact: market-share grain, one row per measure (KPI Flag)
--   KPI Flag 1 = Volume (Kg)  -> base, from the Gold mart
--   KPI Flag 2 = Value (EUR)  -> base, from the Gold mart
--   KPI Flag 3 = Units        -> derived = Volume Kg / unit weight (from Format)
--   KPI Flag 4 = Volume (L)   -> derived = Volume Kg * Conversor LKG
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE GOLD_STAR.FACT_TABLE AS
WITH base AS (
    -- Volume (Kg) and Value (EUR) come straight from the consolidated Gold mart
    SELECT PER_DSC AS "Period ID", PDT_COD AS "Product ID", CHL_COD AS "Channel ID",
           SAL_TYP_COD AS "Sales Type ID", CTG_COD AS "Category ID", PDT_PCK AS "Product Pack",
           CASE WHEN KPI = 'VOL' THEN 1 ELSE 2 END AS "KPI Flag ID",
           SO_VALUE AS "KPI Value"
    FROM GOLD_DMT.FACT_MARKETSHARE_ALL          -- consolidated ES+PT gold mart
),
uw AS (   -- peso por unidad a partir del Format
    SELECT "Product ID",
           CASE LOWER("Format")
               WHEN '1kg' THEN 1.0 WHEN '500g' THEN 0.5 WHEN '200g' THEN 0.2
               WHEN '1l'  THEN 1.0 WHEN '250ml' THEN 0.25 WHEN '500ml' THEN 0.5
               WHEN 'single' THEN 0.3 WHEN 'multipack' THEN 1.2 ELSE 0.5 END AS unit_weight,
           "Conversor LKG"
    FROM GOLD_STAR.DIM_PROD
)
SELECT "Period ID","Product ID","Channel ID","Sales Type ID","KPI Flag ID","Category ID",
       "Product Pack","KPI Value"
FROM base
UNION ALL  -- KPI Flag 3 = Units (derivado del Volumen Kg)
SELECT b."Period ID", b."Product ID", b."Channel ID", b."Sales Type ID", 3, b."Category ID",
       b."Product Pack", ROUND(b."KPI Value" / NULLIF(u.unit_weight,0))
FROM base b JOIN uw u ON b."Product ID" = u."Product ID" WHERE b."KPI Flag ID" = 1
UNION ALL  -- KPI Flag 4 = Volumen L (Kg * Conversor LKG)
SELECT b."Period ID", b."Product ID", b."Channel ID", b."Sales Type ID", 4, b."Category ID",
       b."Product Pack", ROUND(b."KPI Value" * u."Conversor LKG", 2)
FROM base b JOIN uw u ON b."Product ID" = u."Product ID" WHERE b."KPI Flag ID" = 1;

-- ----------------------------------------------------------------------------
-- Context fact: monthly birth rate, joined to the model only via DIM_CALENDAR
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TABLE GOLD_STAR.FACT_BIRTH_RATE AS
SELECT
    YEAR(c."Date")                                   AS "Year",
    UPPER(LEFT(MONTHNAME(c."Date"), 3))              AS "Month Short",   -- JAN..DEZ
    b.BIRTH_RATE                                     AS "KPI Value",
    c."Period ID"                                    AS "Period ID"
FROM GOLD_DMT.FACT_BIRTH_RATE b
JOIN GOLD_STAR.DIM_CALENDAR c ON b.PER_DSC = c."Period ID";

/* Notes
   - Exported to dashboards/data/*.csv (synthetic, committed) for the BI builds.
   - FACT_TABLE has all 4 KPI flags populated; Volume(L)/Units are derived as above.
   - Market Share in the BI layer = value within DIM_PROD."Manufacturer"; BPS = share
     delta x 10000; %Peso = share within the selected breakdown field.
   - Keep this file in sync whenever the dataset columns change (see CLAUDE.md). */
