<p align="center"><em>Este repositorio aún está en proceso de desarrollo.</em></p>

# Iberia Market-Share Data Warehouse

End-to-end **data warehouse** for multi-country **market-share analytics** (FMCG /
nutrition) across two markets — **Spain (ES)** and **Portugal (PT)** — built on a
**medallion architecture** in **Snowflake**, feeding **Power BI** dashboards.

> **Note on data & naming** — This repository is an **anonymized reference
> implementation** based on a real project I designed and built. All source systems are
> presented as generic **panels** (`PANEL_A`, `PANEL_B`, …), database/schema names are
> generic, and every figure comes from a **synthetic dataset**. No real provider, client
> or business data is included.

## What this shows

- **Dimensional modelling**: star schema with conformed dimensions (calendar, product,
  channel, sales type, units) shared across markets and sources.
- **Multi-source integration**: ~11 heterogeneous market panels normalized into a single
  fact model, each with its own date format, key structure and channel taxonomy.
- **Incremental loading**: high-watermark pattern on `LOA_DAT` (load timestamp) with
  idempotent delete-by-period reload.
- **Deduplication**: `ROW_NUMBER()` over business keys to keep the latest version of each
  record.
- **Surrogate keys & fallbacks**: SHA-256 product hashing and a `99` "not-assigned"
  fallback so a fact row never loses its mapping.
- **Reusable pattern**: every source script follows the same 4-step shape, which makes the
  pipeline easy to template and onboard new panels.

## Architecture (medallion)

```
 Bronze (STG)        Silver (DWH + TRA)              Gold (DMT)
 raw ingestion  -->  normalized facts & mappings -->  business-ready data marts
 BRONZE_STG          SILVER_DWH / SILVER_TRA          GOLD_DMT
```

See [`docs/architecture.md`](docs/architecture.md) for the full flow, layer
responsibilities and the per-source processing pattern, and
[`docs/data-model.md`](docs/data-model.md) for the star schema, grain and ER diagram.

## Repository layout

```
sql/
├── 01_silver_dwh/        STG -> DWH : fact normalization (per source)
│   ├── pt/               Portugal panels
│   └── es/               Spain panels
├── 02_silver_tra/        transformations: unions, product master, mappings
│   ├── pt/
│   └── es/
├── 03_gold_dmt/          DWH/TRA -> DMT : data marts for Power BI
│   ├── pt/
│   └── es/
└── 99_shared/            conformed dimensions (calendar, units)

powerbi/                  Power BI model as DAX (measures, field params) + notes
dashboards/               BI layer on the synthetic data — 3 comparable builds
├── data/                 star schema exported to CSV (synthetic, committed)
├── streamlit/            Python app (built & tested)
├── evidence/             BI-as-code (SQL + Markdown)
└── looker-studio/        no-code build kit + flattened data
```

## Dashboards

The same synthetic data, surfaced three ways so you can compare —
see [`dashboards/`](dashboards/): a **Streamlit** Python app (full dynamic
period framework, tested), an **Evidence.dev** SQL/Markdown site, and a
**Looker Studio** build kit. All deploy to a free public link.

## Markets & sources

| Market | Sources (anonymized) |
|--------|----------------------|
| **PT** | `PANEL_A`, `PANEL_B`, `PANEL_C`, `PANEL_D` |
| **ES** | `PANEL_E`, `PANEL_F`, `PANEL_G`, `PANEL_H`, `PANEL_I` |

## Conventions

- **Column naming**: 3-letter domain codes — `PDT` product, `CHL` channel, `SAL`/`SO`
  sales, `PER` period, `GEO` geography, `SAL_TYP` sales type, `KPI` measure, `LOA_DAT`
  load timestamp.
- **Measures (units)**: Volume (Kg), Volume (Liters), Value (EUR), Units — see
  [`sql/99_shared/dim_units.sql`](sql/99_shared/dim_units.sql).
- **Engine**: Snowflake SQL (`QUALIFY`, `GENERATOR`, `SHA2`, `DATEADD`, ISO calendar fns).

## Stack

Snowflake · SQL · Power BI · Snowflake Schema · Incremental ELT · Streamlit · Data Engineering · Data Analytics

## Disclaimer

Anonymized portfolio project. Synthetic data only. Not affiliated with, and contains no
confidential information of, any former employer, client or data provider.
