---
title: Segmento de Mercado
sidebar_position: 5
---

Comparación de **categorías** en la ventana corta seleccionada (**L4M** o **L3M**) frente
a su período equivalente anterior, con crecimiento y BPS.

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

<Dropdown data={metricas} name=metrica value=metric label=metric title="Métrica" defaultValue="Valor €" />

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

<ButtonGroup name=win title="Ventana de comparación">
    <ButtonGroupItem valueLabel="L4M" value="L4M" defaultValue="L4M" />
    <ButtonGroupItem valueLabel="L3M" value="L3M" />
</ButtonGroup>

## Categorías — {inputs.win} vs {inputs.win}-1

<!-- CTE base reutilizada (incrustada en cada consulta: Evidence no encadena consultas reactivas). -->

```sql seg_cat
with base as (
    select f.category, f.value,
        case
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3 and a.aidx     then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7 and a.aidx - 4 then 'prev'
            when '${inputs.win}' = 'L3M' and f.pidx between a.aidx - 2 and a.aidx     then 'cur'
            when '${inputs.win}' = 'L3M' and f.pidx between a.aidx - 5 and a.aidx - 3 then 'prev'
        end as bucket
    from marketshare.fact_full f
    cross join (
        select cast('${inputs.anio}' as integer) * 12
                 + cast('${inputs.mes}' as integer) as aidx
    ) a
    where f.metric = '${inputs.metrica.value}' and f.category is not null
),
tot as (
    select sum(value) filter (where bucket = 'cur')  as mkt_cur,
           sum(value) filter (where bucket = 'prev') as mkt_prev
    from base
),
t as (
    select category,
        sum(value) filter (where bucket = 'cur')  as cur,
        sum(value) filter (where bucket = 'prev') as prev
    from base where bucket is not null group by 1
)
select
    category, cur, prev,
    cur - coalesce(prev, 0) as crecimiento,
    case when prev is null or prev = 0 then null else cur / prev - 1 end as pct_crec,
    -- BPS = 0 cuando no hay período anterior con el que comparar (en vez de un valor irreal).
    case when (select mkt_cur from tot) is null or (select mkt_cur from tot) = 0   then null
         when (select mkt_prev from tot) is null or (select mkt_prev from tot) = 0 then 0
         else (cur / (select mkt_cur from tot) - coalesce(prev, 0) / (select mkt_prev from tot)) * 10000 end as bps
from t
where cur > 0
order by cur desc
```

```sql seg_long
with base as (
    select f.category, f.value,
        case
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3 and a.aidx     then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7 and a.aidx - 4 then 'prev'
            when '${inputs.win}' = 'L3M' and f.pidx between a.aidx - 2 and a.aidx     then 'cur'
            when '${inputs.win}' = 'L3M' and f.pidx between a.aidx - 5 and a.aidx - 3 then 'prev'
        end as bucket
    from marketshare.fact_full f
    cross join (
        select cast('${inputs.anio}' as integer) * 12
                 + cast('${inputs.mes}' as integer) as aidx
    ) a
    where f.metric = '${inputs.metrica.value}' and f.category is not null
),
t as (
    select category,
        sum(value) filter (where bucket = 'cur')  as cur,
        sum(value) filter (where bucket = 'prev') as prev
    from base where bucket is not null group by 1
    having sum(value) filter (where bucket = 'cur') > 0
)
select category, '${inputs.win}'   as periodo, cur  as ventas from t
union all
select category, '${inputs.win}-1' as periodo, prev as ventas from t
```

<BarChart
    data={seg_long}
    x=category
    y=ventas
    series=periodo
    type=grouped
    colorPalette={['#1467BC', '#0A2A66']}
    yAxisTitle="Ventas"
/>

<DataTable data={seg_cat} rows=12>
    <Column id=category    title="Categoría" />
    <Column id=cur         title="Ventas {inputs.win}"   fmt="#,##0" />
    <Column id=prev        title="Ventas {inputs.win}-1" fmt="#,##0" />
    <Column id=pct_crec    title="%Crecimiento" fmt="0.0%"  contentType=delta />
    <Column id=bps         title="BPS"          fmt="#,##0" contentType=delta />
</DataTable>
