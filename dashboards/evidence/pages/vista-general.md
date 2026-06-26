---
title: Vista General
sidebar_position: 2
---

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

```sql companias
select distinct manufacturer from marketshare.fact_full
where manufacturer is not null order by 1
```

<Dropdown data={metricas}  name=metrica  value=metric        title="Métrica"  defaultValue="Valor €" />
<Dropdown data={companias} name=compania value=manufacturer  title="Compañía" defaultValue="Compañía SN" />

<ButtonGroup name=anio title="Año">
    <ButtonGroupItem valueLabel="2022" value="2022" />
    <ButtonGroupItem valueLabel="2023" value="2023" />
    <ButtonGroupItem valueLabel="2024" value="2024" defaultValue="2024" />
</ButtonGroup>

<ButtonGroup name=mes title="Mes">
    <ButtonGroupItem valueLabel="Ene" value="1" />
    <ButtonGroupItem valueLabel="Feb" value="2" />
    <ButtonGroupItem valueLabel="Mar" value="3" />
    <ButtonGroupItem valueLabel="Abr" value="4" />
    <ButtonGroupItem valueLabel="May" value="5" />
    <ButtonGroupItem valueLabel="Jun" value="6" />
    <ButtonGroupItem valueLabel="Jul" value="7" />
    <ButtonGroupItem valueLabel="Ago" value="8" />
    <ButtonGroupItem valueLabel="Sep" value="9" />
    <ButtonGroupItem valueLabel="Oct" value="10" />
    <ButtonGroupItem valueLabel="Nov" value="11" />
    <ButtonGroupItem valueLabel="Dic" value="12" defaultValue="12" />
</ButtonGroup>

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
        select cast('${inputs.anio}' as integer) as ayear,
               cast('${inputs.anio}' as integer) * 12
                 + cast('${inputs.mes}' as integer) as aidx
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
    -- BPS es una diferencia entre dos períodos: sin período anterior devolvemos 0 (no un
    -- valor irreal de restar contra una cuota inexistente).
    case when mkt_cur is null or mkt_cur = 0       then null
         when mkt_prev is null or mkt_prev = 0     then 0
         else (comp_cur / mkt_cur - coalesce(comp_prev, 0) / mkt_prev) * 10000 end as bps
from m
```

<BigValue data={vg_kpis} value=comp_cur title="Ventas compañía (actual)" fmt="#,##0" />
<BigValue data={vg_kpis} value=ms_cur   title="Market Share"            fmt="0.0%" />
<BigValue data={vg_kpis} value=pct_var  title="%Crecimiento mercado"    fmt="0.0%" />
<BigValue data={vg_kpis} value=bps      title="BPS"                     fmt="#,##0" />

## Incremento vs período anterior — evolución mensual

```sql vg_evol
select
    month_number,
    month_long as mes,
    sum(value) filter (where year = cast('${inputs.anio}' as integer))     as "Año actual",
    sum(value) filter (where year = cast('${inputs.anio}' as integer) - 1) as "Año anterior"
from marketshare.fact_full
where metric = '${inputs.metrica.value}' and manufacturer = '${inputs.compania.value}'
  and year in (cast('${inputs.anio}' as integer), cast('${inputs.anio}' as integer) - 1)
group by 1, 2
order by 1
```

<BarChart
    data={vg_evol}
    x=mes
    y={['Año actual', 'Año anterior']}
    type=grouped
    sort=false
    colorPalette={['#002060', '#00ACED']}
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
        select cast('${inputs.anio}' as integer) as ayear,
               cast('${inputs.anio}' as integer) * 12
                 + cast('${inputs.mes}' as integer) as aidx
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
        select cast('${inputs.anio}' as integer) as ayear,
               cast('${inputs.anio}' as integer) * 12
                 + cast('${inputs.mes}' as integer) as aidx
    ) a
    where f.metric = '${inputs.metrica.value}'
),
agg as (
    select
        manufacturer as compania,
        sum(value) filter (where bucket = 'cur')  as ventas,
        sum(value) filter (where bucket = 'prev') as ventas_prev
    from base
    where bucket is not null
    group by 1
    having sum(value) filter (where bucket = 'cur') > 0
)
select
    compania,
    ventas,
    -- Color según comparación con el período anterior. ventas_prev es NULL cuando no hay
    -- período anterior con el que comparar (p. ej. 2022-01) -> gris.
    case when ventas_prev is not null and ventas - ventas_prev > 0 then ventas end as "Sube",
    case when ventas_prev is not null and ventas - ventas_prev < 0 then ventas end as "Baja",
    case when ventas_prev is not null and ventas - ventas_prev = 0 then ventas end as "Sin cambio",
    case when ventas_prev is null then ventas end                                  as "Sin comparativa"
from agg
order by ventas desc
limit 7
```

<BarChart
    data={vg_top7}
    x=compania
    y={['Sube', 'Baja', 'Sin cambio', 'Sin comparativa']}
    swapXY=true
    type=stacked
    colorPalette={['#2E9E5B', '#D23B3B', '#E8941A', '#888888']}
    yAxisTitle="Ventas"
/>

<DataTable data={vg_rank} rows=10>
    <Column id=compania     title="Compañía" />
    <Column id=ventas       title="Ventas"        fmt="#,##0" />
    <Column id=market_share title="Market Share"  fmt="0.0%" />
    <Column id=crecimiento  title="Crecimiento"   fmt="#,##0" contentType=delta />
    <Column id=pct_crec     title="%Crecimiento"  fmt="0.0%"  contentType=delta />
</DataTable>
