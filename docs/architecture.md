# Architecture

## Layers (medallion)

| Layer  | Schema        | Responsibility |
|--------|---------------|----------------|
| Bronze | `BRONZE_STG`  | Raw ingestion of each panel, as received. Read-only source for Silver. |
| Silver | `SILVER_DWH`  | Normalized, deduplicated **fact** tables with conformed surrogate keys. |
| Silver | `SILVER_TRA`  | **Transformations**: cross-source unions, product master, mapping tables. |
| Gold   | `GOLD_DMT`    | Business-ready **data marts** consumed by Power BI (Top-2, National, etc.). |

`SILVER_DWH` and `SILVER_TRA` are both Silver: `DWH` holds the normalized facts, `TRA`
holds the heavier reshaping (unions across feeds, mastering, remapping) that some marts
need before reaching Gold.

## Per-source processing pattern

Every fact-normalization script (`01_silver_dwh/**`) follows the same 4 steps. This
uniformity is deliberate: it makes onboarding a new panel a copy-and-parameterize job.

```sql
WITH cte_base AS (        -- 1. Dedup + incremental window
    -- ROW_NUMBER() over the business key, keep latest LOA_DAT
    -- WHERE LOA_DAT > high-watermark of the target table
),
cte_keys AS (             -- 2. Key & date normalization
    -- normalize product key (UPPER/TRIM + SHA2), parse the source-specific
    -- date format into a YYYYMMDD integer, set the source-name literals
),
cte_map_chl AS ( ... ),   -- 3. Lookups (channel / sales type / units)
cte_map_st  AS ( ... )    --    each filtered to this source, UPPER/TRIM keys
SELECT ...                -- 4. Final projection with COALESCE(code, 99) fallback
FROM cte_keys k
LEFT JOIN ...
WHERE rn = 1;
```

Each script is followed by an **idempotent reload**: a `DELETE` of the affected periods
in the target, scoped to the same incremental window, so re-running a load replaces a
period rather than duplicating it.

## Incremental load (high-watermark)

```sql
WHERE s.LOA_DAT > COALESCE(
    (SELECT MAX(LOA_DAT) FROM <target_table>),
    DATE '1900-01-01'        -- first load: take everything
)
```

`LOA_DAT` is the load timestamp stamped at ingestion. Only rows newer than what the
target already contains are processed.

## Keys & fallbacks

- **Product surrogate key**: `SHA2(UPPER(TRIM(<product_pack>)), 256)` — stable across
  loads and insensitive to casing/whitespace.
- **Mapping fallback**: every dimension lookup uses `COALESCE(<code>, 99)`. `99` is the
  reserved "not assigned" member, present in every dimension, so a fact row is never
  dropped because a mapping is missing.

## Date normalization

Each panel delivers periods in a different shape; all are converted to a single
`YYYYMMDD` / `YYYYMM` integer (`PER_DSC`) so the fact model and the conformed calendar
join cleanly. Examples handled: `DD/MM/YYYY`, `YYYY-MM-DD`, `MM/DD/YYYY`, and localized
month abbreviations (`jan`, `fev`, …).

## Conformed dimensions (`99_shared`)

- **Calendar**: generated with `GENERATOR` over a date range; exposes day/week/month/
  quarter/year grains plus ISO week, last-year shifts and period flags.
- **Units**: the 4 measures used by the dashboards — Volume (Kg), Volume (Liters),
  Value (EUR), Units.
