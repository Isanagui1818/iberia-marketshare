-- Birth-rate context series (joined to the calendar for readable labels).
select
    b."Period ID"   as period_id,
    b."Year"        as year,
    c."Month Long"  as month_long,
    c."Period Name" as period_name,
    b."KPI Value"   as birth_rate
from read_csv_auto('../data/FACT_BIRTH_RATE.csv') b
left join read_csv_auto('../data/DIM_CALENDAR.csv') c on b."Period ID" = c."Period ID"
order by period_id;
