---
title: Informe Dinámico
sidebar_position: 7
---

Construye una tabla agregada por **una o dos dimensiones** en la ventana de período
elegida y **expórtala** (botón de descarga de la tabla → CSV).

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

<Dropdown name=dim1 title="Campo 1 (filas)" defaultValue="manufacturer">
    <DropdownOption valueLabel="Compañía"        value="manufacturer" />
    <DropdownOption valueLabel="Categoría"       value="category" />
    <DropdownOption valueLabel="SubCategoría"    value="sub_category" />
    <DropdownOption valueLabel="Área de Negocio" value="business_area" />
    <DropdownOption valueLabel="Marca"           value="brand" />
    <DropdownOption valueLabel="Producto"        value="product" />
    <DropdownOption valueLabel="Canal"           value="channel" />
    <DropdownOption valueLabel="Market"          value="market" />
</Dropdown>

<Dropdown name=dim2 title="Campo 2 (columnas/filas)" defaultValue="category">
    <DropdownOption valueLabel="(ninguno)"       value="metric" />
    <DropdownOption valueLabel="Compañía"        value="manufacturer" />
    <DropdownOption valueLabel="Categoría"       value="category" />
    <DropdownOption valueLabel="SubCategoría"    value="sub_category" />
    <DropdownOption valueLabel="Área de Negocio" value="business_area" />
    <DropdownOption valueLabel="Marca"           value="brand" />
    <DropdownOption valueLabel="Canal"           value="channel" />
    <DropdownOption valueLabel="Market"          value="market" />
</Dropdown>

<ButtonGroup name=win title="Ventana de período">
    <ButtonGroupItem valueLabel="MES" value="MES" />
    <ButtonGroupItem valueLabel="L4M" value="L4M" defaultValue="L4M" />
    <ButtonGroupItem valueLabel="YTD" value="YTD" />
    <ButtonGroupItem valueLabel="TAM" value="TAM" />
</ButtonGroup>

```sql dinamico
with a as (
    select cast('${inputs.anio}' as integer) as ayear,
           cast('${inputs.anio}' as integer) * 12
             + cast('${inputs.mes}' as integer) as aidx
),
agg as (
    select
        ${inputs.dim1.value} as dimension_1,
        ${inputs.dim2.value} as dimension_2,
        sum(f.value) as ventas
    from marketshare.fact_full f
    cross join a
    where f.metric = '${inputs.metrica.value}'
      and (
           ('${inputs.win}' = 'MES' and f.pidx = a.aidx)
        or ('${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx)
        or ('${inputs.win}' = 'TAM' and f.pidx between a.aidx - 11 and a.aidx)
        or ('${inputs.win}' = 'YTD' and f.year = a.ayear and f.pidx <= a.aidx)
      )
    group by 1, 2
)
select
    dimension_1, dimension_2, ventas,
    replace(printf('%,d', cast(round(ventas) as bigint)), ',', '.') as ventas_fmt
from agg
order by ventas desc
```

## Resultado — {inputs.metrica.value}

<DataTable data={dinamico} rows=25 search=true totalRow=true downloadable=true>
    <Column id=dimension_1 title="Campo 1" />
    <Column id=dimension_2 title="Campo 2" />
    <Column id=ventas_fmt  title="Ventas" />
</DataTable>
