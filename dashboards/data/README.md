# Dashboard data

The synthetic star schema exported from `../../data/synthetic/marketshare_synthetic.xlsx`
to CSV, so the dashboards are self-contained and deployable. **All synthetic/anonymized** —
safe to commit (unlike the source workbook, these are tracked on purpose).

- `DIM_*.csv`, `FACT_TABLE.csv`, `FACT_BIRTH_RATE.csv` — the model tables (one per file).
- `flat_fact_for_looker.csv` — the fact denormalized into one wide table (for Looker Studio,
  which prefers a single source). **Not committed** (~15 MB of derived data): generate it
  locally with `python ../looker-studio/make_flat_fact.py` whenever you need it.

Regenerate the model tables by re-running the export step after changing the workbook,
then re-run `make_flat_fact.py`.
