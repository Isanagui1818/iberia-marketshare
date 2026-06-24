# Dashboard data

The synthetic star schema exported from `../../data/synthetic/marketshare_synthetic.xlsx`
to CSV, so the dashboards are self-contained and deployable. **All synthetic/anonymized** —
safe to commit (unlike the source workbook, these are tracked on purpose).

- `DIM_*.csv`, `FACT_TABLE.csv`, `FACT_BIRTH_RATE.csv` — the model tables (one per file).
- `flat_fact_for_looker.csv` — the fact denormalized into one wide table (for Looker Studio,
  which prefers a single source).

Regenerate by re-running the export step after changing the workbook.
