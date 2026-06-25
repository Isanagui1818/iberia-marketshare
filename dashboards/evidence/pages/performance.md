---
title: Performance
sidebar_position: 3
---

Análisis profundo del rendimiento: todas las métricas del período por la **dimensión**
elegida (equivalente al "Selector de Campo" / field parameter de Power BI).

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

<ButtonGroup name=win title="Ventana de período">
    <ButtonGroupItem valueLabel="MES" value="MES" />
    <ButtonGroupItem valueLabel="L4M" value="L4M" defaultValue="L4M" />
    <ButtonGroupItem valueLabel="YTD" value="YTD" />
    <ButtonGroupItem valueLabel="TAM" value="TAM" />
</ButtonGroup>

## {inputs.win} · {inputs.metrica.value}

```sql perf
with base as (
    select f.value, ${inputs.campo.value} as dimension,
        case
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx                            then 'cur'
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx - 1                        then 'prev'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx      then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7  and a.aidx - 4  then 'prev'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 11 and a.aidx      then 'cur'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 23 and a.aidx - 12 then 'prev'
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
    dimension,
    sum(value) filter (where bucket = 'cur')  as ventas,
    sum(value) filter (where bucket = 'prev') as ventas_prev,
    sum(value) filter (where bucket = 'cur') - sum(value) filter (where bucket = 'prev') as crecimiento,
    case when sum(value) filter (where bucket = 'prev') = 0 then null
         else sum(value) filter (where bucket = 'cur') / sum(value) filter (where bucket = 'prev') - 1 end as pct_crec,
    sum(value) filter (where bucket = 'cur') / (select mkt_cur from tot) as peso
from base
where bucket is not null
group by 1
having sum(value) filter (where bucket = 'cur') > 0
order by ventas desc
```

<DataTable data={perf} rows=20 search=true totalRow=true>
    <Column id=dimension   title="Dimensión" />
    <Column id=ventas      title="Ventas {inputs.win}"   fmt="#,##0" />
    <Column id=ventas_prev title="Ventas {inputs.win}-1" fmt="#,##0" />
    <Column id=crecimiento title="Crecimiento" fmt="#,##0" contentType=delta />
    <Column id=pct_crec    title="%Crecimiento" fmt="0.0%"  contentType=delta />
    <Column id=peso        title="%Peso"        fmt="0.0%"  contentType=colorscale />
</DataTable>
