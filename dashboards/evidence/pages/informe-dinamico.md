---
title: Informe Dinámico
---

Construye una tabla agregada por **una o dos dimensiones** en la ventana de período
elegida y **expórtala** (botón de descarga de la tabla → CSV).

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

```sql periodos
select period_id, period_name from marketshare.periods order by period_id desc
```

<Dropdown data={metricas} name=metrica value=metric label=metric title="Métrica" defaultValue="Valor €" />
<Dropdown data={periodos} name=anchor  value=period_id label=period_name title="Período" defaultValue="202412" />

<Dropdown name=dim1 title="Campo 1 (filas)" defaultValue="manufacturer">
    <DropdownOption valueLabel="Compañía"     value="manufacturer" />
    <DropdownOption valueLabel="Categoría"    value="category" />
    <DropdownOption valueLabel="SubCategoría" value="sub_category" />
    <DropdownOption valueLabel="Área de Negocio" value="business_area" />
    <DropdownOption valueLabel="Marca"        value="brand" />
    <DropdownOption valueLabel="Producto"     value="product" />
    <DropdownOption valueLabel="Canal"        value="channel" />
    <DropdownOption valueLabel="Market"       value="market" />
</Dropdown>

<Dropdown name=dim2 title="Campo 2 (columnas/filas)" defaultValue="category">
    <DropdownOption valueLabel="(ninguno)"    value="metric" />
    <DropdownOption valueLabel="Compañía"     value="manufacturer" />
    <DropdownOption valueLabel="Categoría"    value="category" />
    <DropdownOption valueLabel="SubCategoría" value="sub_category" />
    <DropdownOption valueLabel="Área de Negocio" value="business_area" />
    <DropdownOption valueLabel="Marca"        value="brand" />
    <DropdownOption valueLabel="Canal"        value="channel" />
    <DropdownOption valueLabel="Market"       value="market" />
</Dropdown>

<ButtonGroup name=win title="Ventana de período" defaultValue="L4M">
    <ButtonGroupItem valueLabel="MES" value="MES" />
    <ButtonGroupItem valueLabel="L4M" value="L4M" />
    <ButtonGroupItem valueLabel="YTD" value="YTD" />
    <ButtonGroupItem valueLabel="TAM" value="TAM" />
</ButtonGroup>

```sql dinamico
with p as (
    select
        cast(substr('${inputs.anchor.value}', 1, 4) as integer)                     as ayear,
        cast(substr('${inputs.anchor.value}', 1, 4) as integer) * 12
          + cast(substr('${inputs.anchor.value}', 5, 2) as integer)                 as aidx
),
base as (
    select f.*
    from marketshare.fact_full f
    cross join p
    where f.metric = '${inputs.metrica.value}'
      and (
        ('${inputs.win.value}' = 'MES' and f.pidx = p.aidx)
        or ('${inputs.win.value}' = 'L4M' and f.pidx between p.aidx - 3  and p.aidx)
        or ('${inputs.win.value}' = 'TAM' and f.pidx between p.aidx - 11 and p.aidx)
        or ('${inputs.win.value}' = 'YTD' and f.year = p.ayear and f.pidx <= p.aidx)
      )
)
select
    ${inputs.dim1.value} as dimension_1,
    ${inputs.dim2.value} as dimension_2,
    sum(value)           as "Ventas ${inputs.win.value}"
from base
group by 1, 2
order by 3 desc
```

## Resultado — {inputs.win.value} · {inputs.metrica.value}

<DataTable data={dinamico} rows=25 search=true totalRow=true downloadable=true />
