select
    "Period ID" as period_id,
    "Year"      as year,
    "KPI Value" as birth_rate
from read_csv_auto('../data/FACT_BIRTH_RATE.csv')
order by 1;
