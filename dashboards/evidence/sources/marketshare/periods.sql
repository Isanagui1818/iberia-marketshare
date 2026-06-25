-- Distinct loaded periods, newest first — feeds the period (anchor) dropdowns.
select distinct
    c."Period ID"                       as period_id,
    c."Year"                            as year,
    c."Month Number"                    as month_number,
    c."Period Name"                     as period_name,
    (c."Year" * 12 + c."Month Number")  as pidx
from read_csv_auto('../data/DIM_CALENDAR.csv') c
where c."Period ID" in (select distinct "Period ID" from read_csv_auto('../data/FACT_TABLE.csv'))
order by period_id desc;
