---
title: Performance
---

Análisis profundo del rendimiento: todas las métricas del período por la **dimensión**
elegida (equivalente al "Selector de Campo" / field parameter de Power BI).

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

```sql periodos
select period_id, period_name from marketshare.periods order by period_id desc
```

<Dropdown data={metricas} name=metrica value=metric label=metric title="Métrica" defaultValue="Valor €" />
<Dropdown data={periodos} name=anchor  value=period_id label=period_name title="Período" defaultValue="202412" />

<Dropdown name=campo title="Selector de Campo" defaultValue="manufacturer">
    <DropdownOption valueLabel="Área de Negocio" value="business_area" />
    <DropdownOption valueLabel="Compañía"        value="manufacturer" />
    <DropdownOption valueLabel="Categoría"       value="category" />
    <DropdownOption valueLabel="SubCategoría"    value="sub_category" />
    <DropdownOption valueLabel="Entorno"         value="type_channel" />
    <DropdownOption valueLabel="Canal"           value="channel" />
    <DropdownOption valueLabel="SubCanal"        value="sub_channel" />
    <DropdownOption valueLabel="Marca"           value="brand" />
    <DropdownOption valueLabel="Sub Marca"       value="sub_brand" />
    <DropdownOption valueLabel="Producto"        value="product" />
    <DropdownOption valueLabel="Formato"         value="format" />
    <DropdownOption valueLabel="Market"          value="market" />
    <DropdownOption valueLabel="Etapa"           value="etapas" />
</Dropdown>

<ButtonGroup name=win title="Ventana de período" defaultValue="L4M">
    <ButtonGroupItem valueLabel="MES" value="MES" />
    <ButtonGroupItem valueLabel="L4M" value="L4M" />
    <ButtonGroupItem valueLabel="YTD" value="YTD" />
    <ButtonGroupItem valueLabel="TAM" value="TAM" />
</ButtonGroup>

```sql perf_base
with p as (
    select
        cast(substr('${inputs.anchor.value}', 1, 4) as integer)                     as ayear,
        cast(substr('${inputs.anchor.value}', 1, 4) as integer) * 12
          + cast(substr('${inputs.anchor.value}', 5, 2) as integer)                 as aidx
)
select
    f.*,
    case
        when '${inputs.win.value}' = 'MES' and f.pidx = p.aidx                            then 'cur'
        when '${inputs.win.value}' = 'MES' and f.pidx = p.aidx - 1                        then 'prev'
        when '${inputs.win.value}' = 'L4M' and f.pidx between p.aidx - 3  and p.aidx      then 'cur'
        when '${inputs.win.value}' = 'L4M' and f.pidx between p.aidx - 7  and p.aidx - 4  then 'prev'
        when '${inputs.win.value}' = 'TAM' and f.pidx between p.aidx - 11 and p.aidx      then 'cur'
        when '${inputs.win.value}' = 'TAM' and f.pidx between p.aidx - 23 and p.aidx - 12 then 'prev'
        when '${inputs.win.value}' = 'YTD' and f.year = p.ayear     and f.pidx <= p.aidx       then 'cur'
        when '${inputs.win.value}' = 'YTD' and f.year = p.ayear - 1 and f.pidx <= p.aidx - 12  then 'prev'
    end as bucket
from marketshare.fact_full f
cross join p
where f.metric = '${inputs.metrica.value}'
```

## {inputs.win.value} · {inputs.metrica.value}

```sql perf
select
    ${inputs.campo.value} as dimension,
    sum(value) filter (where bucket = 'cur')  as ventas,
    sum(value) filter (where bucket = 'prev') as ventas_prev,
    sum(value) filter (where bucket = 'cur') - sum(value) filter (where bucket = 'prev') as crecimiento,
    case when sum(value) filter (where bucket = 'prev') = 0 then null
         else sum(value) filter (where bucket = 'cur') / sum(value) filter (where bucket = 'prev') - 1 end as pct_crec,
    sum(value) filter (where bucket = 'cur')
        / (select sum(value) filter (where bucket = 'cur') from perf_base where bucket is not null) as peso
from perf_base
where bucket is not null
group by 1
having sum(value) filter (where bucket = 'cur') > 0
order by ventas desc
```

<DataTable data={perf} rows=20 search=true totalRow=true>
    <Column id=dimension   title="Dimensión" />
    <Column id=ventas      title="Ventas {inputs.win.value}"   fmt="#,##0" />
    <Column id=ventas_prev title="Ventas {inputs.win.value}-1" fmt="#,##0" />
    <Column id=crecimiento title="Crecimiento" fmt="#,##0" contentType=delta />
    <Column id=pct_crec    title="%Crecimiento" fmt="0.0%"  contentType=delta />
    <Column id=peso        title="%Peso"        fmt="0.0%"  contentType=colorscale />
</DataTable>
