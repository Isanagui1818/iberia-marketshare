-- Joined star schema -> wide fact, read straight from the shared CSVs.
-- Paths are relative to the Evidence project root (dashboards/evidence).
-- `pidx` is a continuous month index (year*12 + month) used by the period
-- windows (MES/L4M/YTD/TAM) that the page queries compute from the selected anchor.
select
    f."Period ID"                       as period_id,
    c."Year"                            as year,
    c."Month Number"                    as month_number,
    c."Month Long"                      as month_long,
    c."Period Name"                     as period_name,
    c."Date"                            as date,
    (c."Year" * 12 + c."Month Number")  as pidx,
    p."Product"                         as product,
    p."Brand"                           as brand,
    p."Sub Brand"                       as sub_brand,
    p."Manufacturer"                    as manufacturer,
    p."Business Area"                   as business_area,
    p."Category"                        as category,
    p."Sub Category"                    as sub_category,
    p."Format"                          as format,
    p."Etapas"                          as etapas,
    p."Market"                          as market,
    ch."Channel"                        as channel,
    ch."SubChannel"                     as sub_channel,
    ch."Type Channel"                   as type_channel,
    st."Sales Type Name"                as sales_type,
    u."KPI Flag"                        as metric,
    f."KPI Value"                       as value
from read_csv_auto('../data/FACT_TABLE.csv')        f
left join read_csv_auto('../data/DIM_PROD.csv')       p  on f."Product ID"    = p."Product ID"
left join read_csv_auto('../data/DIM_CHANNEL.csv')    ch on f."Channel ID"    = ch."Channel ID"
left join read_csv_auto('../data/DIM_SALES_TYPE.csv') st on f."Sales Type ID" = st."Sales Type ID"
left join read_csv_auto('../data/DIM_UNITS.csv')      u  on f."KPI Flag ID"   = u."KPI Flag ID"
left join read_csv_auto('../data/DIM_CALENDAR.csv')   c  on f."Period ID"     = c."Period ID";
