---
title: Vista General
sidebar_position: 2
---

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

```sql periodos
select period_id, period_name from marketshare.periods order by period_id desc
```

```sql companias
select distinct manufacturer from marketshare.fact_full
where manufacturer is not null order by 1
```

<Dropdown data={metricas}  name=metrica  value=metric        title="Métrica"  defaultValue="Valor €" />
<Dropdown data={periodos}  name=anchor   value=period_id label=period_name title="Período" defaultValue={202412} />
<Dropdown data={companias} name=compania value=manufacturer  title="Compañía" defaultValue="Compañía SN" />

<ButtonGroup name=win title="Ventana de período">
    <ButtonGroupItem valueLabel="MES" value="MES" />
    <ButtonGroupItem valueLabel="L4M" value="L4M" defaultValue="L4M" />
    <ButtonGroupItem valueLabel="YTD" value="YTD" />
    <ButtonGroupItem valueLabel="TAM" value="TAM" />
</ButtonGroup>

## KPIs — {inputs.compania.value} · {inputs.win}

```sql vg_kpis
with base as (
    select f.value, f.manufacturer,
        case
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx                             then 'cur'
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx - 1                         then 'prev'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx        then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7  and a.aidx - 4    then 'prev'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 11 and a.aidx        then 'cur'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 23 and a.aidx - 12   then 'prev'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear     and f.pidx <= a.aidx       then 'cur'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear - 1 and f.pidx <= a.aidx - 12  then 'prev'
        end as bucket
    from marketshare.fact_full f
    cross join (
        select cast(substr('${inputs.anchor.value}', 1, 4) as integer) as ayear,
               cast(substr('${inputs.anchor.value}', 1, 4) as integer) * 12
                 + cast(substr('${inputs.anchor.value}', 5, 2) as integer) as aidx
    ) a
    where f.metric = '${inputs.metrica.value}'
),
m as (
    select
        sum(value) filter (where bucket = 'cur')                                          as mkt_cur,
        sum(value) filter (where bucket = 'prev')                                         as mkt_prev,
        sum(value) filter (where bucket = 'cur'  and manufacturer = '${inputs.compania.value}') as comp_cur,
        sum(value) filter (where bucket = 'prev' and manufacturer = '${inputs.compania.value}') as comp_prev
    from base
    where bucket is not null
)
select
    comp_cur,
    case when mkt_cur  = 0 then null else comp_cur  / mkt_cur  end as ms_cur,
    case when mkt_prev = 0 then null else comp_prev / mkt_prev end as ms_prev,
    case when mkt_prev = 0 then null else mkt_cur / mkt_prev - 1 end as pct_var,
    case when mkt_cur = 0 or mkt_prev = 0 then null
         else (comp_cur / mkt_cur - comp_prev / mkt_prev) * 10000 end as bps
from m
```

<BigValue data={vg_kpis} value=comp_cur title="Ventas compañía (actual)" fmt="#,##0" />
<BigValue data={vg_kpis} value=ms_cur   title="Market Share"            fmt="0.0%" />
<BigValue data={vg_kpis} value=pct_var  title="%Crecimiento mercado"    fmt="0.0%" />
<BigValue data={vg_kpis} value=bps      title="BPS"                     fmt="#,##0" />

## Incremento vs período anterior — evolución mensual

```sql vg_evol
select month_number, month_long as mes, 'Año actual' as serie, sum(value) as ventas
from marketshare.fact_full
where metric = '${inputs.metrica.value}' and manufacturer = '${inputs.compania.value}'
  and year = cast(substr('${inputs.anchor.value}', 1, 4) as integer)
group by 1, 2
union all
select month_number, month_long as mes, 'Año anterior' as serie, sum(value) as ventas
from marketshare.fact_full
where metric = '${inputs.metrica.value}' and manufacturer = '${inputs.compania.value}'
  and year = cast(substr('${inputs.anchor.value}', 1, 4) as integer) - 1
group by 1, 2
order by 1
```

<BarChart
    data={vg_evol}
    x=mes
    y=ventas
    series=serie
    type=grouped
    sort=false
    colorPalette={['#0A2A66', '#1467BC']}
    yAxisTitle="Ventas"
/>

## Performance del mercado — Top 7

```sql vg_rank
with base as (
    select f.value, f.manufacturer,
        case
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx                             then 'cur'
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx - 1                         then 'prev'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx        then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7  and a.aidx - 4    then 'prev'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 11 and a.aidx        then 'cur'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 23 and a.aidx - 12   then 'prev'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear     and f.pidx <= a.aidx       then 'cur'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear - 1 and f.pidx <= a.aidx - 12  then 'prev'
        end as bucket
    from marketshare.fact_full f
    cross join (
        select cast(substr('${inputs.anchor.value}', 1, 4) as integer) as ayear,
               cast(substr('${inputs.anchor.value}', 1, 4) as integer) * 12
                 + cast(substr('${inputs.anchor.value}', 5, 2) as integer) as aidx
    ) a
    where f.metric = '${inputs.metrica.value}'
),
tot as (select sum(value) filter (where bucket = 'cur') as mkt_cur from base)
select
    manufacturer as compania,
    sum(value) filter (where bucket = 'cur')  as ventas,
    sum(value) filter (where bucket = 'cur') - sum(value) filter (where bucket = 'prev') as crecimiento,
    case when sum(value) filter (where bucket = 'prev') = 0 then null
         else sum(value) filter (where bucket = 'cur') / sum(value) filter (where bucket = 'prev') - 1 end as pct_crec,
    sum(value) filter (where bucket = 'cur') / (select mkt_cur from tot) as market_share
from base
where bucket is not null
group by 1
having sum(value) filter (where bucket = 'cur') > 0
order by ventas desc
```

```sql vg_top7
with base as (
    select f.value, f.manufacturer, f.pidx, f.year,
        (select cast(substr('${inputs.anchor.value}', 1, 4) as integer) * 12
              + cast(substr('${inputs.anchor.value}', 5, 2) as integer)) as aidx
    from marketshare.fact_full f
    where f.metric = '${inputs.metrica.value}'
)
select manufacturer as compania, sum(value) as ventas
from base
where
    ('${inputs.win}' = 'MES' and pidx = aidx)
    or ('${inputs.win}' = 'L4M' and pidx between aidx - 3  and aidx)
    or ('${inputs.win}' = 'TAM' and pidx between aidx - 11 and aidx)
    or ('${inputs.win}' = 'YTD' and year = cast(substr('${inputs.anchor.value}', 1, 4) as integer) and pidx <= aidx)
group by 1
having sum(value) > 0
order by ventas desc
limit 7
```

<BarChart data={vg_top7} x=compania y=ventas swapXY=true colorPalette={['#0A2A66']} yAxisTitle="Ventas" />

<DataTable data={vg_rank} rows=10>
    <Column id=compania     title="Compañía" />
    <Column id=ventas       title="Ventas"        fmt="#,##0" />
    <Column id=market_share title="Market Share"  fmt="0.0%" />
    <Column id=crecimiento  title="Crecimiento"   fmt="#,##0" contentType=delta />
    <Column id=pct_crec     title="%Crecimiento"  fmt="0.0%"  contentType=delta />
</DataTable>
