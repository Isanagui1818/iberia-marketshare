---
title: Evolución
sidebar_position: 4
---

Evolución temporal por **dimensión**: top 6 miembros a lo largo de todos los períodos
cargados, en **Ventas** o en **Market Share** (cuota = ventas del miembro / ventas del
mercado en cada período).

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

<Dropdown data={metricas} name=metrica value=metric label=metric title="Métrica" defaultValue="Valor €" />

<Dropdown name=campo title="Selector de Campo" defaultValue="manufacturer">
    <DropdownOption valueLabel="Área de Negocio" value="business_area" />
    <DropdownOption valueLabel="Compañía"        value="manufacturer" />
    <DropdownOption valueLabel="Categoría"       value="category" />
    <DropdownOption valueLabel="SubCategoría"    value="sub_category" />
    <DropdownOption valueLabel="Entorno"         value="type_channel" />
    <DropdownOption valueLabel="Canal"           value="channel" />
    <DropdownOption valueLabel="Marca"           value="brand" />
    <DropdownOption valueLabel="Producto"        value="product" />
    <DropdownOption valueLabel="Formato"         value="format" />
    <DropdownOption valueLabel="Market"          value="market" />
</Dropdown>

<ButtonGroup name=kpi title="KPI">
    <ButtonGroupItem valueLabel="Ventas"       value="ventas" defaultValue="ventas" />
    <ButtonGroupItem valueLabel="Market Share" value="cuota" />
</ButtonGroup>

```sql ev_series
with ev_top as (
    select ${inputs.campo.value} as dimension, sum(value) as tot
    from marketshare.fact_full
    where metric = '${inputs.metrica.value}' and ${inputs.campo.value} is not null
    group by 1
    order by tot desc
    limit 6
),
mkt as (
    select period_id, sum(value) as market
    from marketshare.fact_full
    where metric = '${inputs.metrica.value}'
    group by 1
)
select
    f.period_id,
    f.period_name,
    f.${inputs.campo.value} as dimension,
    sum(f.value)                  as ventas,
    sum(f.value) / max(m.market)  as cuota,
    replace(printf('%,d', cast(round(sum(f.value)) as bigint)), ',', '.') as ventas_fmt,
    replace(printf('%.1f', sum(f.value) / max(m.market) * 100), '.', ',') || ' %' as cuota_fmt
from marketshare.fact_full f
join mkt m on f.period_id = m.period_id
where f.metric = '${inputs.metrica.value}'
  and f.${inputs.campo.value} in (select dimension from ev_top)
group by 1, 2, 3
order by 1
```

## Evolución por {inputs.campo.value} — {inputs.kpi}

<LineChart
    data={ev_series}
    x=period_name
    y={inputs.kpi}
    series=dimension
    markers=true
    yAxisTitle={inputs.kpi}
    yFmt={inputs.kpi === 'cuota' ? '0.0%' : '#,##0'}
/>

<DataTable data={ev_series} rows=12 search=true>
    <Column id=period_name title="Período" />
    <Column id=dimension   title="Miembro" />
    <Column id=ventas_fmt  title="Ventas" />
    <Column id=cuota_fmt   title="Market Share" />
</DataTable>
