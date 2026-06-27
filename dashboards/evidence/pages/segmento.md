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

## Categorías

```sql seg_cat
with base as (
    select f.category, f.value,
        case
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx       then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7  and a.aidx - 4   then 'prev'
            when '${inputs.win}' = 'L3M' and f.pidx between a.aidx - 2  and a.aidx       then 'cur'
            when '${inputs.win}' = 'L3M' and f.pidx between a.aidx - 5  and a.aidx - 3   then 'prev'
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
),
agg as (
    select
        category, cur, prev,
        cur - coalesce(prev, 0) as crecimiento,
        case when prev is null or prev = 0 then null else cur / prev - 1 end as pct_crec,
        case when (select mkt_cur  from tot) is null or (select mkt_cur  from tot) = 0 then null
             when (select mkt_prev from tot) is null or (select mkt_prev from tot) = 0 then 0
             else (cur / (select mkt_cur from tot) - coalesce(prev,0) / (select mkt_prev from tot)) * 10000
        end as bps
    from t
    where cur > 0
)
select
    category, cur, prev, crecimiento, pct_crec, bps,
    replace(printf('%,d', cast(round(cur) as bigint)), ',', '.') as cur_fmt,
    replace(printf('%,d', cast(round(coalesce(prev,0)) as bigint)), ',', '.') as prev_fmt,
    case when pct_crec is null then '–'
         when pct_crec > 0 then '<span style="color:#2E9E5B">▲ ' || replace(printf('%.1f', pct_crec * 100), '.', ',') || ' %</span>'
         when pct_crec < 0 then '<span style="color:#D23B3B">▼ ' || replace(printf('%.1f', abs(pct_crec) * 100), '.', ',') || ' %</span>'
         else '<span style="color:#E8941A">– 0,0 %</span>'
    end as pct_crec_html,
    case when bps is null then '–'
         when bps > 0 then '<span style="color:#2E9E5B">▲ ' || replace(printf('%.1f', bps), '.', ',') || '</span>'
         when bps < 0 then '<span style="color:#D23B3B">▼ ' || replace(printf('%.1f', abs(bps)), '.', ',') || '</span>'
         else '<span style="color:#E8941A">– 0</span>'
    end as bps_html
from agg
order by cur desc
```

```sql seg_long
with base as (
    select f.category, f.value,
        case
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx       then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7  and a.aidx - 4   then 'prev'
            when '${inputs.win}' = 'L3M' and f.pidx between a.aidx - 2  and a.aidx       then 'cur'
            when '${inputs.win}' = 'L3M' and f.pidx between a.aidx - 5  and a.aidx - 3   then 'prev'
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
select category, '${inputs.win}' as periodo, cur as ventas from t
union all
select category, '${inputs.win}' || '-1' as periodo, prev as ventas from t
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
    <Column id=category      title="Categoría" />
    <Column id=cur_fmt       title="Ventas" />
    <Column id=prev_fmt      title="Ventas -1" />
    <Column id=pct_crec_html title="%Crecimiento" contentType=html />
    <Column id=bps_html      title="BPS"          contentType=html />
</DataTable>
