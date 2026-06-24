---
title: Iberia Market-Share
---

Cuota de mercado multi-país sobre **datos 100% sintéticos** — versión _BI-as-code_ (SQL +
Markdown) del informe Power BI. Todo lo que ves se genera desde consultas SQL.

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

<Dropdown data={metricas} name=metrica value=metric title="Métrica" defaultValue="Valor €"/>

```sql kpis
select
    sum(value)                                   as ventas_total,
    count(distinct product)                      as productos,
    count(distinct manufacturer)                 as fabricantes
from marketshare.fact_full
where metric = '${inputs.metrica.value}'
```

<BigValue data={kpis} value=ventas_total title="Ventas (total)" fmt="#,##0"/>
<BigValue data={kpis} value=productos title="Productos"/>
<BigValue data={kpis} value=fabricantes title="Fabricantes"/>

## Evolución mensual

```sql evolucion
select period_id::varchar as periodo, sum(value) as ventas
from marketshare.fact_full
where metric = '${inputs.metrica.value}'
group by 1 order by 1
```

<LineChart data={evolucion} x=periodo y=ventas yAxisTitle="Ventas" markers=true/>

## Ranking por fabricante (cuota %)

```sql ranking
select manufacturer,
       sum(value) as ventas,
       sum(value) / sum(sum(value)) over () as cuota
from marketshare.fact_full
where metric = '${inputs.metrica.value}'
group by 1 order by ventas desc
```

<BarChart data={ranking} x=manufacturer y=ventas swapXY=true/>
<DataTable data={ranking}>
  <Column id=manufacturer title="Fabricante"/>
  <Column id=ventas title="Ventas" fmt="#,##0"/>
  <Column id=cuota title="Cuota" fmt="0.0%"/>
</DataTable>

## Contexto — tasa de natalidad

```sql natalidad
select period_id::varchar as periodo, birth_rate from marketshare.birth_rate
```

<LineChart data={natalidad} x=periodo y=birth_rate yAxisTitle="Tasa (‰)"/>
