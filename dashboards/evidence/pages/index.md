---
title: Market Data SN
---

_Versión **BI-as-code** (SQL + Markdown) del informe Power BI, sobre **datos 100 %
sintéticos y anonimizados**. Cada cifra, tabla y gráfico de este sitio se genera desde
consultas SQL — la documentación **es** el código._

```sql ultimo_periodo
select max(period_name) as periodo, count(*) as periodos_cargados
from marketshare.periods
```

<BigValue data={ultimo_periodo} value=periodo title="Último período cargado"/>
<BigValue data={ultimo_periodo} value=periodos_cargados title="Períodos cargados"/>

## El informe

Análisis de **cuota de mercado** de la industria de nutrición especializada (FMCG) en
**España y Portugal**. Mide ventas, market share, crecimiento y participación (%Peso) por
compañía, categoría, canal, marca y producto, en distintos horizontes temporales —
**MES, L4M, YTD y TAM** — con comparativas frente al período anterior y al mismo período
del año anterior.

## Páginas

- **[Glosario](/glosario)** — definiciones de las medidas y los períodos.
- **[Vista General](/vista-general)** — KPIs de la compañía, incremento vs período anterior y performance del mercado (Top 7).
- **[Performance](/performance)** — tabla completa de métricas por dimensión (selector de campo).
- **[Evolución](/evolucion)** — series temporales por dimensión (Ventas / Market Share).
- **[Segmento de Mercado](/segmento)** — comparación de categorías L4M / L3M.
- **[Birth Rate](/birth-rate)** — serie de contexto (tasa de natalidad).
- **[Informe Dinámico](/informe-dinamico)** — construye una tabla por dimensiones y expórtala.

---

_Modelo replicado del informe Power BI: framework de período `_AuxPeriod`
(MES/L4M/YTD/TAM con variantes `-1`/`LY`), Market Share = cuota dentro del fabricante,
BPS = Δ cuota × 10 000, %Peso = peso del segmento sobre el total._
