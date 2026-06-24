# Looker Studio — build kit

Looker Studio is a no-code cloud tool: there's no file to commit. This folder is the
**recipe** — a flattened dataset plus the steps and formulas to rebuild the report. It
works with a normal **Gmail** account (no work email), and gives a **public link**.

> Data source: [`../data/flat_fact_for_looker.csv`](../data/flat_fact_for_looker.csv)
> (the star schema denormalized into one wide table — Looker prefers a single source).

## 1. Load the data

- Open **Google Sheets** → File → Import → upload `flat_fact_for_looker.csv` → new sheet.
- In **lookerstudio.google.com** → *Create → Data source → Google Sheets* → pick that sheet.
- Fix field types: `Date` → Date, `KPI Value` → Number, IDs → Text.
- (Optional) add `FACT_BIRTH_RATE.csv` as a second data source for the context chart.

## 2. The Looker way (it's different from Power BI)

Power BI does period logic with DAX measures. **Looker Studio does most of it with
built-in chart features**, not formulas:

- **Métrica selector** → add a **Filter control** on `KPI Flag` (Volumen Kg / Valor € /
  Unidades / Volumen L). Set the chart metric to **SUM(`KPI Value`)** = "Ventas".
- **MoM / YoY growth** → on a scorecard/time-series, enable **Comparison date range →
  Previous period / Previous year**. Looker computes the Δ% for you (no measure needed).
- **YTD / period windows** → use the **Date range control** (preset: Year to date), or a
  calculated field (below).
- **Market Share / cuota** → in a table, on the metric pick **Comparison calculation →
  Percent of total**. That gives each Manufacturer's share without a formula.

## 3. Useful calculated fields (Looker syntax, not DAX)

```text
# Etiqueta de período
Periodo            =  CONCAT(Year, "-", Month Long)

# Volumen total normalizado a Kg (combina Kg + L*densidad si lo necesitas)
# (en este dataset Volumen L ya viene en la métrica; normalmente NO hace falta)

# YTD acumulado (si no usas el control de rango):
EsYTD              =  CASE WHEN Date <= CURRENT_DATE() AND YEAR(Date) = YEAR(CURRENT_DATE())
                          THEN "YTD" ELSE "Fuera" END

# Crecimiento manual (si no usas Comparison): se hace mejor con el comparativo nativo.
```

> Looker Studio **no** tiene el equivalente directo de field parameters ni del switch
> `_AuxPeriod` MES/L4M/YTD/TAM. Eso se aproxima con **controles de filtro + rango de fechas
> + comparativos nativos**. Es más simple a propósito.

## 4. Suggested layout

- Top: filter controls (KPI Flag, Market, Channel) + date range.
- KPI **scorecards** with *Previous year* comparison (Ventas, Δ%).
- **Time series** of SUM(KPI Value) by Date.
- **Bar/Table** by Manufacturer with *Percent of total* = market share.
- Second page/area: **birth rate** time series (from the second data source).

## 5. Share

*Share → Manage access → Anyone with the link → Viewer*, and paste the link in the root
README. That public link is the main reason to use Looker for a portfolio.
