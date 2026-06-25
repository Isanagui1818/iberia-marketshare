---
title: Segmento de Mercado
---

Comparación de **categorías** en la ventana corta seleccionada (**L4M** o **L3M**) frente
a su período equivalente anterior, con crecimiento y BPS.

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

```sql periodos
select period_id, period_name from marketshare.periods order by period_id desc
```

<Dropdown data={metricas} name=metrica value=metric label=metric title="Métrica" defaultValue="Valor €" />
<Dropdown data={periodos} name=anchor  value=period_id label=period_name title="Período" defaultValue="202412" />

<ButtonGroup name=win title="Ventana de comparación" defaultValue="L4M">
    <ButtonGroupItem valueLabel="L4M" value="L4M" />
    <ButtonGroupItem valueLabel="L3M" value="L3M" />
</ButtonGroup>

```sql seg_base
with p as (
    select cast(substr('${inputs.anchor.value}', 1, 4) as integer) * 12
             + cast(substr('${inputs.anchor.value}', 5, 2) as integer) as aidx
)
select
    f.category,
    f.value,
    case
        when '${inputs.win.value}' = 'L4M' and f.pidx between p.aidx - 3 and p.aidx     then 'cur'
        when '${inputs.win.value}' = 'L4M' and f.pidx between p.aidx - 7 and p.aidx - 4 then 'prev'
        when '${inputs.win.value}' = 'L3M' and f.pidx between p.aidx - 2 and p.aidx     then 'cur'
        when '${inputs.win.value}' = 'L3M' and f.pidx between p.aidx - 5 and p.aidx - 3 then 'prev'
    end as bucket
from marketshare.fact_full f
cross join p
where f.metric = '${inputs.metrica.value}' and f.category is not null
```

```sql seg_cat
with t as (
    select
        category,
        sum(value) filter (where bucket = 'cur')  as cur,
        sum(value) filter (where bucket = 'prev') as prev,
        (select sum(value) filter (where bucket = 'cur')  from seg_base) as mkt_cur,
        (select sum(value) filter (where bucket = 'prev') from seg_base) as mkt_prev
    from seg_base
    where bucket is not null
    group by 1
)
select
    category,
    cur, prev,
    cur - prev as crecimiento,
    case when prev = 0 then null else cur / prev - 1 end as pct_crec,
    case when mkt_cur = 0 or mkt_prev = 0 then null
         else (cur / mkt_cur - prev / mkt_prev) * 10000 end as bps
from t
where cur > 0
order by cur desc
```

## Categorías — {inputs.win.value} vs {inputs.win.value}-1

```sql seg_long
select category, '${inputs.win.value}'    as periodo, cur  as ventas from seg_cat
union all
select category, '${inputs.win.value}-1'  as periodo, prev as ventas from seg_cat
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
    <Column id=cur         title="Ventas {inputs.win.value}"   fmt="#,##0" />
    <Column id=prev        title="Ventas {inputs.win.value}-1" fmt="#,##0" />
    <Column id=pct_crec    title="%Crecimiento" fmt="0.0%"  contentType=delta />
    <Column id=bps         title="BPS"          fmt="#,##0" contentType=delta />
</DataTable>
