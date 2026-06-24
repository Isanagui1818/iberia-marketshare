# Power BI — Model notes

Reproduces the dashboards on the **synthetic** dataset
(`data/synthetic/marketshare_synthetic.xlsx`). No real data involved. The model logic
(87 measures + 6 field parameters + `_AuxPeriod`) lives as DAX in [`dax/`](dax/).

## 1. Load

Power BI Desktop → **Get Data → Excel** → import the 8 data tables:
`FACT_TABLE`, `DIM_CALENDAR`, `DIM_PROD`, `DIM_CHANNEL`, `DIM_SALES_TYPE`, `DIM_UNITS`,
`DIM_CATEGORY`, `DIM_SOURCE`. The helper/parameter tables are **not** imported — they are
created as DAX (see [`dax/`](dax/)).

## 2. Relationships (star schema)

| From (FACT_TABLE) | To | Cardinality |
|---|---|---|
| `Period ID`      | `DIM_CALENDAR[Period ID]`     | many-to-one |
| `Product ID`     | `DIM_PROD[Product ID]`        | many-to-one |
| `Channel ID`     | `DIM_CHANNEL[Channel ID]`     | many-to-one |
| `Sales Type ID`  | `DIM_SALES_TYPE[Sales Type ID]` | many-to-one |
| `KPI Flag ID`    | `DIM_UNITS[KPI Flag ID]`      | many-to-one |
| `Category ID`    | `DIM_CATEGORY[Category ID]`   | many-to-one |
| `DIM_CATEGORY[Source ID]` | `DIM_SOURCE[Source ID]` | many-to-one (snowflake) |

> Do **not** also relate `DIM_PROD[Category ID] → DIM_CATEGORY`: it would create a
> second path FACT→DIM_CATEGORY and an ambiguous filter. Category is filtered directly
> from the fact. `_AuxPeriod` and the `Parameter*` tables stay **disconnected**.

## 3. Date table

Mark `DIM_CALENDAR` as date table (**Table tools → Mark as date table**, column `Date`).
Grain is monthly (each row = first day of month), so the month/year time-intelligence in
the measures works.

## 4. DAX (measures, field parameters, helper table)

Don't rewrite anything — paste from [`dax/`](dax/) in this order:

1. `dax/01_calculated_tables.dax` → `_AuxPeriod` (period-type selector).
2. Create an empty table `Measure`, then `dax/03_measures.dax` → the 87 measures.
3. `dax/02_field_parameters.dax` → the 6 field parameters (create via *New parameter →
   Fields*, then paste the block).

See [`dax/README.md`](dax/README.md) for the dependency order and a bulk-import shortcut.

## 5. The dynamic framework (how it fits together)

- **`_AuxPeriod`** slicer picks the period type (MES / L4M / YTD / TAM). Every
  `...Período Switch` measure reads `SUM(_AuxPeriod[Selected Period ID])` to return the
  matching variant — so one slicer reshapes every KPI from month to YTD to MAT.
- **`ParameterField`** (field parameter over *columns*) swaps the breakdown axis
  (Manufacturer, Category, Brand, Channel, Format…). The `Ventas Globales … Switch`
  measures `REMOVEFILTERS` the selected level to compute the "total" denominator for
  **%Peso**.
- **`ParameterKPIs` / `ParameterMarket Año|Período (+ -1)`** (field parameters over
  *measures*) let a single visual show Ventas / Market Share / BPS / Crecimiento and their
  current vs `-1` / `LY` comparisons.
- **Market Share** = share within `DIM_PROD[Manufacturer]`; **BPS** = share delta ×10 000.

## 6. Build the report

KPI cards and a trend over `DIM_CALENDAR`, a ranking bar on the `ParameterField` axis with
the `ParameterMarket Período` measure parameter, slicers for `_AuxPeriod`, the "Métrica"
field (Volumen Kg / Valor € / Unidades / Volumen L) and Channel. Export key views to
`powerbi/screenshots/` for the README.
