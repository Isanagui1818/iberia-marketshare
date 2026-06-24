-- Joined fact at query time (star schema -> wide), read straight from the shared CSVs.
-- Paths are relative to the Evidence project root (dashboards/evidence).
select
    f."Period ID"      as period_id,
    c."Date"           as date,
    c."Year"           as year,
    c."Month Long"     as month_long,
    p."Product"        as product,
    p."Brand"          as brand,
    p."Manufacturer"   as manufacturer,
    p."Business Area"  as business_area,
    p."Category"       as category,
    p."Sub Category"   as sub_category,
    p."Market"         as market,
    ch."Channel"       as channel,
    ch."Type Channel"  as type_channel,
    u."KPI Flag"       as metric,
    f."KPI Value"      as value
from read_csv_auto('../data/FACT_TABLE.csv')      f
left join read_csv_auto('../data/DIM_PROD.csv')     p  on f."Product ID"   = p."Product ID"
left join read_csv_auto('../data/DIM_CHANNEL.csv')  ch on f."Channel ID"   = ch."Channel ID"
left join read_csv_auto('../data/DIM_UNITS.csv')    u  on f."KPI Flag ID"  = u."KPI Flag ID"
left join read_csv_auto('../data/DIM_CALENDAR.csv') c  on f."Period ID"    = c."Period ID";
