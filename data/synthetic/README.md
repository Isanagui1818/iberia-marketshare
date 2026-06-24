# Synthetic dataset

The dashboards in `powerbi/` are reproduced on a **fully synthetic, anonymized** dataset.
The workbook itself (`marketshare_synthetic.xlsx`) is **kept locally only** — it is
`.gitignore`d so no binary/embedded data is committed. This file documents what it
contains so the model is understandable from the repo alone.

## Workbook contents

**Dimensions**
- `DIM_CALENDAR` — monthly grain, 36 periods (2022–2024); year/quarter/month, ISO week,
  last-year shifts, current-month/year flags.
- `DIM_PROD` — 120 products: `Product`, `Brand`, `Sub Brand`, `Manufacturer`,
  `Business Area`/`Business Sub Area`, `Category`/`Sub Category`, `Market`, `Format`,
  `Etapas`, `Product Pack` (+ `Conversor LKG`, `CUnits` used to derive volume/units).
- `DIM_CHANNEL` — `Channel`, `SubChannel`, `Type Channel` (Online/Offline).
- `DIM_UNITS` — 4 measures: `Volumen Kg`, `Valor €`, `Unidades`, `Volumen L` (`KPI Flag`).
- `DIM_SALES_TYPE`, `DIM_SOURCE`, `DIM_CATEGORY`.

**Facts**
- `FACT_TABLE` — ~81k rows at the grain
  `Period × Product × Channel × Sales Type × KPI Flag × Category` with `KPI Value`,
  populated for all 4 KPI flags. Volume (L) is derived as Volume (Kg) × `Conversor LKG`;
  Units as Volume (Kg) ÷ unit weight (parsed from `Format`).
- `FACT_BIRTH_RATE` — monthly context series (`Year`, `Month Short`, `KPI Value`,
  `Period ID`); one row per calendar month, synthetic birth-rate values (~6–8). Joins the
  model **only** through `DIM_CALENDAR[Period ID]` (no other dimension). Covers the same
  range as the calendar (202201–202412) so every row resolves.

> The dimensions were extended (Manufacturer, Sub Category/Brand, Market, channel
> hierarchy, KPI Flag label) so the original DAX in `../../powerbi/dax/` runs unchanged.

The workbook is **data only**. Selection/helper tables, field parameters and measures are
**not** here — they belong in the model as DAX and live in
[`../../powerbi/dax/`](../../powerbi/dax/). (Field parameters and calculated tables are DAX
artifacts, not ingested data, so keeping them out of the spreadsheet keeps the dataset clean.)

All values are generated; brands (`BrandA…E`, `Private Label`), products (`Product_001…`)
and sources (`Panel A/B/Internal`) are placeholders. No real data.

## Notes

- Referential integrity verified (every fact key resolves to its dimension; no orphans,
  nulls or negatives) after the extension.
