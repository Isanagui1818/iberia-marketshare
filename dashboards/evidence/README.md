# Evidence.dev dashboard

BI-as-code version of the report: SQL queries + Markdown render an interactive site.
Git-native and deployable free (Netlify/Vercel/Evidence Cloud). It mirrors the
**8-page structure of the Streamlit build**, on the same synthetic star schema.

> [!NOTE]
> _Built and SQL-validated, but **not run here** (Evidence needs Node.js, unavailable in
> this environment). Every page query was checked against the CSVs with DuckDB; run
> `npm run dev` locally to render and publish it._

## Setup

Evidence projects are best initialized from the official template, then these files
dropped in:

```bash
cd dashboards/evidence
npx degit evidence-dev/template . --force   # adds package.json, build config, components
# keep the sources/ and pages/ in this folder (they override the template samples)
npm install
npm run sources      # builds the DuckDB tables from ../data/*.csv
npm run dev          # open http://localhost:3000
```

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
- `sources/marketshare/periods.sql` — distinct loaded periods (feeds the period dropdowns).
- `sources/marketshare/birth_rate.sql` — the context series with readable labels.
- The **period framework** (MES / L4M / YTD / TAM with `-1` variants) and the measures
  (Market Share = company / market sales in the window, BPS = Δ share × 10 000, %Peso) are
  computed **in the page queries** from the selected anchor, since Evidence inputs only
  resolve at query time, not in sources.

> If `read_csv_auto('../data/...')` doesn't resolve in your Evidence version, copy the CSVs
> from `dashboards/data/` into `sources/marketshare/` and change the paths to local
> filenames (Evidence also auto-loads CSVs placed inside a source folder).

## Deploy

Push to GitHub → connect the repo on **Evidence Cloud** (or Netlify) with build dir
`dashboards/evidence` → public URL for the root README.
