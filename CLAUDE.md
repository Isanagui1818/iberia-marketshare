# CLAUDE.md — Iberia Market-Share DWH

Project context for AI assistants working in this repo. Everything here is **anonymized
and synthetic** — safe to read/share. Spanish is the working language of the dashboards.

## What this is
Portfolio project of a **Data Engineer / Data Analyst**: an end-to-end market-share
analytics stack (FMCG / specialized nutrition) for two markets — **Spain (ES)** and
**Portugal (PT)** — reconstructed as an **anonymized reference implementation** of real work.
No real company, client, provider or figure is included.

## Repository layout
```
sql/                     Snowflake medallion DWH (Bronze STG -> Silver DWH/TRA -> Gold DMT)
  01_silver_dwh/ pt|es   STG -> DWH fact normalization (per panel)
  02_silver_tra/ pt|es   transformations: unions, product master, mappings
  03_gold_dmt/   pt|es   data marts
  04_gold_star_schema/   build of the BI consumption star schema (matches dashboards/data)
  99_shared/             conformed dims (calendar, units)
powerbi/                 Power BI model as DAX (measures, field params) + notes
  dax/                   01 _AuxPeriod · 02 field parameters · 03 the 87 measures + bulk .csx
dashboards/              BI layer on the synthetic data — 3 comparable builds
  data/                  star schema exported to CSV (synthetic, committed)
  streamlit/             Python app (Market Data SN) — built & tested
  evidence/              BI-as-code (SQL + Markdown)
  looker-studio/         no-code build kit + flattened data
data/synthetic/          source workbook (gitignored) + README documenting it
```

## Sources / panels (anonymized)
PT: `PANEL_A` (milk+food), `PANEL_B`, `PANEL_C`, `PANEL_D` (mass/pharmacy/metabolics).
ES: `PANEL_E` (pharma+others), `PANEL_F`, `PANEL_G`, `PANEL_H`, `PANEL_I` (sell-in).
All are licensed market panels in reality → kept generic. Infra/schema names are generic
(`BRONZE_STG`, `SILVER_DWH`, `SILVER_TRA`, `GOLD_DMT`).

## Dashboard star schema (the data the dashboards consume)
The synthetic dataset (`dashboards/data/*.csv`, generated to mirror the Power BI model):
- **FACT_TABLE** (~81k rows): `Period ID, Product ID, Channel ID, Sales Type ID,
  KPI Flag ID, Category ID, Product Pack, KPI Value` — 4 KPI flags populated.
- **FACT_BIRTH_RATE**: `Year, Month Short, KPI Value, Period ID` — context series, joined
  only via `DIM_CALENDAR[Period ID]`.
- **DIM_PROD** (120, 19 companies, focal = `Compañía SN`): Product, Brand, Sub Brand,
  Manufacturer, Business Area/Sub Area, Category/Sub Category, Market, Format, Etapas,
  Conversor LKG, CUnits…
- **DIM_CHANNEL**: Channel, SubChannel, Type Channel. **DIM_UNITS**: 4 metrics
  (Volumen Kg, Valor €, Unidades, Volumen L) via `KPI Flag`. Plus DIM_CALENDAR,
  DIM_CATEGORY (→ DIM_SOURCE), DIM_SALES_TYPE.

## Power BI model (real DAX, anonymized)
Dynamic period framework: `_AuxPeriod` selector (MES/L4M/YTD/TAM) drives `...Período Switch`
measures with `-1`/`LY` variants. Market Share = share within `Manufacturer`; BPS = share
delta ×10 000; %Peso = weight vs the field-parameter total. 87 measures + 6 field parameters
in `powerbi/dax/` (bulk-create with `tabular_editor_bulk.csx`).

## Streamlit app (`dashboards/streamlit/`)
8 pages: Menú · Glosario · Vista General · Performance · Evolución · Segmento de Mercado ·
Birth Rate · Informe Dinámico. `app.py` = nav + pages; `core.py` = data load, the period
windows/measures and Spanish formatting. Theme navy `#002060` / accent `#1467BC`.
Run: `cd dashboards/streamlit && pip install -r requirements.txt && python -m streamlit run app.py`.
- **Period selection**: Año + Mes are **multi-select** (with a "Todos" option), defaulting to
  the latest period. `core.resolve(years, months, tipo)` returns `(cur, prev, has_prior, multi)`:
  a single (year, month) keeps the MES/L4M/YTD/TAM window model (compare vs the preceding
  block); multiple months/years sum the selection and compare vs the same months with the
  year(s) shifted back by the number of selected years (YoY). In multi mode the per-page
  MES/L4M/YTD/TAM selectors are hidden. `company_table`/`breakdown_table` take resolved
  `cur`/`prev` lists.
- **Vista General** increment charts depend only on the YEAR (not the month filter); the
  monthly chart plots market share (there is no per-month BPS), so its tooltip shows `%` in
  both Market Share and BPS modes. KPI cards have no hover tooltips (read by color + arrow).
- `core.window` returns an **empty** prev/ly window at the data boundary (no negative slicing).

## Evidence dashboard (`dashboards/evidence/`)
Same 8-page report in BI-as-code (SQL + Markdown). Built, run and verified locally; the
SvelteKit scaffolding (`package.json`, etc.) is committed (`npm install && npm run sources &&
npm run dev`). Period = Año + Mes `ButtonGroup`s; the window type is a third `ButtonGroup`;
measures + period windows are computed **in the page queries** (a `pidx` month index). The
year/month multi-select is **not yet ported** to Evidence (TODO).

## Comparison convention (both dashboards)
green ▲ up vs prior period · red ▼ down · orange – no change · gray ○ no prior period.
**BPS returns 0** when there is no prior period (instead of an unreal value). Streamlit bars
show a 2-line hover tooltip (absolute total + variation vs prior); Evidence's tooltip is
limited by the chart component.

## Conventions / gotchas
- Streamlit: launch with `streamlit run` (not `python`); after editing code, **restart** the
  server (a browser refresh keeps the old module in memory). KPI/menu styling lives in the CSS
  block at the top of `app.py`; menu buttons use `st-key-mb_*` classes.
- Number format is European/Spanish (`68,9 mill.`, `19,6 %`) via `core.es_*`; `es_escala`
  picks mill./mil/units. Plotly charts use `separators=",."`.
- **Evidence gotchas**: a `ButtonGroup` value is read as `${inputs.name}` (not `.value`, that's
  for Dropdowns) and its default goes on a `ButtonGroupItem` (`defaultValue=`). Evidence does
  **not** expose a reactive (input-driven) query as a table to other queries, so the period
  CTE is **inlined** into each query (no `from other_query`). A numeric dropdown default needs
  `defaultValue={202412}` (not a string).
- The synthetic workbook (`data/synthetic/*.xlsx`) is gitignored; the CSVs in
  `dashboards/data/` are committed (synthetic → safe) so the apps deploy self-contained.
- When the dataset changes, re-export the CSVs and keep `sql/04_gold_star_schema` in sync.
