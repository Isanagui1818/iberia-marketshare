---
title: Birth Rate
sidebar_position: 6
---

Serie de **contexto** del informe: tasa de natalidad (‰) por período. No interviene en las
medidas de cuota; se muestra como variable explicativa del mercado de nutrición infantil.

```sql natalidad
select period_name, year, birth_rate
from marketshare.birth_rate
order by period_id
```

<LineChart
    data={natalidad}
    x=period_name
    y=birth_rate
    markers=true
    colorPalette={['#2E9E5B']}
    yAxisTitle="Tasa de natalidad (‰)"
/>

```sql natalidad_anual
select year, avg(birth_rate) as media_anual
from marketshare.birth_rate
group by 1
order by 1
```

## Media anual

<BarChart data={natalidad_anual} x=year y=media_anual colorPalette={['#2E9E5B']} yAxisTitle="Tasa media (‰)" />
