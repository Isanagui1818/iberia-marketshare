> [!NOTE]
> _Built, run and verified locally — every page renders with data and no errors in the
> Evidence dev server. Publication pending (Evidence Cloud / Netlify)._

# Evidence.dev dashboard

BI-as-code version of the report: SQL queries + Markdown render an interactive site.
Git-native and deployable free (Netlify/Vercel/Evidence Cloud). It mirrors the
**8-page structure of the Streamlit build**, on the same synthetic star schema.

## Setup

The Evidence / SvelteKit scaffolding (`package.json`, `evidence.config.yaml`, …) is
committed, so a fresh clone runs with no extra steps:

```bash
cd dashboards/evidence
npm install          # needs Node 18+
npm run sources      # builds the DuckDB tables from ../data/*.csv
npm run dev          # open http://localhost:3000
```

`node_modules/` and the `.evidence/` build dir are gitignored.

## Pages (mirror of the Streamlit report)

| Page | File | What it shows |
|------|------|---------------|
| Portada | `pages/index.md` | Description, last loaded period, navigation. |
| Glosario | `pages/glosario.md` | Definitions of the measures and period windows. |
| Vista General | `pages/vista-general.md` | Company KPIs (Ventas, Market Share, %Crec., BPS), monthly evolution vs last year, market Top 7. |
| Performance | `pages/performance.md` | Full metric table by the selected dimension (field selector). |
| Evolución | `pages/evolucion.md` | Time series of the top-6 members of a dimension (Ventas / Market Share). |
| Segmento de Mercado | `pages/segmento.md` | Category comparison L4M / L3M with growth and BPS. |
| Birth Rate | `pages/birth-rate.md` | Context series (birth rate) + annual average. |
| Informe Dinámico | `pages/informe-dinamico.md` | Pivot builder by 1–2 dimensions, exportable to CSV. |

## How it's wired

- `sources/marketshare/connection.yaml` — in-memory DuckDB connection.
- `sources/marketshare/fact_full.sql` — star schema joined via `read_csv_auto` on the
  shared `../data/*.csv`; exposes a wide fact plus `pidx` (a continuous month index used by
  the period windows).
- `sources/marketshare/birth_rate.sql` — the context series with readable labels.
- The **period** is chosen with two `ButtonGroup`s (Año + Mes); the window type
  (MES / L4M / YTD / TAM) is a third `ButtonGroup`, defaulting to the most recent period.
- The **measures** (Market Share = company / market sales in the window, BPS = Δ share ×
  10 000, %Peso) are computed **in the page queries**, since Evidence inputs only resolve at
  query time (not in sources). The period windows use a continuous month index `pidx`.
- **Comparison colors**: green = up vs prior period · red = down · orange = no change ·
  gray = no prior period to compare. **BPS returns 0** when there is no prior period
  (instead of an unreal value).
- **European/Spanish number format** (`1.234.567`, `19,6 %`) is produced **in SQL** with
  `printf` + `replace` (DuckDB has no locale-aware `format`): integers via
  `replace(printf('%,d', x), ',', '.')`, percentages via
  `replace(printf('%.1f', x*100), '.', ',') || ' %'`. The adaptive scale (`mill.`/`mil`/
  units, `es_escala`) and the adaptive-decimals BPS (`es_sig`) are computed the same way.
- **Colored delta columns** in the tables: each `pct_crec` / `crecimiento` / `bps` ships a
  sibling `_html` column built in SQL (`'<span style="color:#2E9E5B">▲ …</span>'`) and is
  rendered with `<Column contentType=html />` — this gives the arrow + value + color of the
  Streamlit/Power BI convention, which Evidence's built-in `contentType=delta` can't fully
  reproduce.
- **Typed tooltip on the Top 7 chart** (Vista General): the stacked horizontal `BarChart`
  passes a custom `echartsOptions={{ tooltip: { formatter } }}`. The formatter finds the
  active (non-zero) stack series, shows the absolute total colored by the legend state and,
  below it, the arrow + signed difference vs the prior period. The per-row `crecimiento` is
  looked up from the query rows inside the formatter (ECharts only receives the x/y columns
  in `params.data`).

> A `periods.sql` source is also included (distinct loaded periods) in case you prefer a
> period dropdown over the Año/Mes button groups.

> If `read_csv_auto('../data/...')` doesn't resolve in your Evidence version, copy the CSVs
> from `dashboards/data/` into `sources/marketshare/` and change the paths to local
> filenames (Evidence also auto-loads CSVs placed inside a source folder).

## Gotchas (worth knowing before editing the pages)

- **No query chaining off a reactive query.** Evidence won't expose an input-driven query
  as a table to another query (`from other_query` → `Catalog Error: Table … does not
  exist`). So the formatting columns (`*_fmt`, `*_html`) are **inlined into the same query**
  via an `agg` CTE — never a separate `select … from <reactive_query>`. The period CTE is
  inlined into every query for the same reason.
- **Custom ECharts config goes through `echartsOptions`, not `options`.** `<BarChart
  options={…}>` is overwritten by Evidence's own config build; `echartsOptions={…}` is
  applied last via `chart.setOption()` and survives. The Top 7 tooltip relies on this.
- **`ButtonGroup` vs `Dropdown` value.** A `ButtonGroup` value is read as `${inputs.name}`;
  a `Dropdown` value as `${inputs.name.value}`. Año/Mes/Ventana are single-select
  `ButtonGroup`s (the Streamlit multi-select is not ported here). A numeric dropdown default
  needs `defaultValue={2024}` (number, not a string).
- **Cloud-synced working copy.** This repo lives under a synced `Documents/` folder. The
  sync tool can drop `+page (# Edit conflict … #).md` files into the generated
  `.evidence/template/`, which crashes the dev server (`Files prefixed with + are
  reserved`). If the whole site 500s, delete any `*Edit conflict*` files under
  `dashboards/evidence/.evidence/` and restart `npm run dev`.

## Deploy

Push to GitHub → connect the repo on **Evidence Cloud** (or Netlify) with build dir
`dashboards/evidence` → public URL for the root README.
