# Evidence.dev dashboard

BI-as-code version of the report: SQL queries + Markdown render an interactive site.
Git-native and deployable free (Netlify/Vercel/Evidence Cloud).

> Scaffolded but **not run here** (Evidence needs Node.js, unavailable in this environment).
> The Streamlit version was end-to-end tested; this one you run locally to finalize.

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

## How it's wired

- `sources/marketshare/connection.yaml` — in-memory DuckDB connection.
- `sources/marketshare/*.sql` — `fact_full` (star schema joined via `read_csv_auto` on the
  shared `../data/*.csv`) and `birth_rate`.
- `pages/index.md` — the dashboard: a metric `Dropdown`, KPI `BigValue`s, `LineChart`,
  `BarChart` with market share, and the birth-rate context series.

> If `read_csv_auto('../data/...')` doesn't resolve in your Evidence version, copy the CSVs
> from `dashboards/data/` into `sources/marketshare/` and change the paths to local
> filenames (Evidence also auto-loads CSVs placed inside a source folder).

## Deploy

Push to GitHub → connect the repo on **Evidence Cloud** (or Netlify) with build dir
`dashboards/evidence` → public URL for the root README.
