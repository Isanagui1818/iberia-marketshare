# DAX reproduction kit

The full Power BI logic — **87 measures + 6 field parameters + 1 helper table** — lives
here as plain DAX, so the report can be rebuilt on the synthetic dataset by **pasting**,
not rewriting. The synthetic Excel (`data/synthetic/`) holds **only data**; everything
below is DAX, exactly as in the original model (already anonymized).

## What the model does

A dynamic **period framework**: a single `_AuxPeriod` selector (MES / L4M / YTD / TAM)
drives a family of `...Período Switch` measures, each with current, `-1` (previous) and
`LY` (last-year) variants. On top: **Ventas**, **Market Share** (share within
`DIM_PROD[Manufacturer]`), **BPS** (share delta ×10 000), **%Peso** (weight vs the global
switch), and **%Crecimiento**. Breakdowns are swapped live with `ParameterField`
(columns) and the `ParameterMarket*` / `ParameterKPIs` field parameters (measures).

## Files

| File | Creates | How to paste |
|------|---------|--------------|
| `01_calculated_tables.dax` | `_AuxPeriod` (period-type selector) | Modeling → **New table** |
| `03_measures.dax`          | 87 measures (home table `Measure`) | **New measure**, or bulk via Tabular Editor |
| `02_field_parameters.dax`  | `ParameterField`, `ParameterKPIs`, `ParameterMarket Año/Período` + their `-1` | New parameter → Fields, then replace DAX |

## Rebuild order (dependencies)

1. Load `data/synthetic/marketshare_synthetic.xlsx` (data only).
2. Relationships + mark `DIM_CALENDAR` as date table (see `../model-notes.md`).
3. Paste `01_calculated_tables.dax` → `_AuxPeriod`.
4. Create an empty table named **`Measure`** (Enter data → empty) to home the measures.
5. Paste `03_measures.dax` → the 87 measures. Creation order doesn't matter; they
   cross-reference each other and resolve automatically.
6. Create the field parameters from `02_field_parameters.dax` **last** (they reference
   the measures and `_AuxPeriod`).

## Notes

- **Field parameters**: create each via **Modeling → New parameter → Fields** so Power BI
  adds the metadata that lets it swap fields/measures, then paste the matching block as its
  definition. Table names with spaces/hyphens (e.g. `ParameterMarket Período-1`) are set in
  that dialog.
- **`Measure` home table**: the field parameters reference `NAMEOF('Measure'[…])`, so the
  measures must live in a table called `Measure` for those references to resolve.
- The synthetic dimensions were extended (`DIM_PROD`: Manufacturer, Sub Category, Sub Brand,
  Product, Market · `DIM_CHANNEL`: Channel, SubChannel, Type Channel · `DIM_UNITS`: KPI Flag)
  so this DAX runs **unchanged**. See `../../data/synthetic/README.md`.

## Fast path — create everything in one shot (recommended)

Don't paste 87 measures by hand. Use **Tabular Editor 2** (free):

1. Install Tabular Editor 2 → it appears in Power BI's **External Tools** ribbon.
2. Refresh the data first (the model must be loaded), then open **External Tools →
   Tabular Editor**.
3. Open the **`C# Script`** tab, paste the contents of
   [`tabular_editor_bulk.csx`](tabular_editor_bulk.csx), and **Run (F5)**. This creates
   `_AuxPeriod` + the 87 measures (in a `Measure` table) at once. It's re-runnable (skips
   what already exists).
4. Press **Ctrl+S** in Tabular Editor to write the changes back into Power BI.

Then create the **6 field parameters** in the Power BI UI (only these are left):

5. **Modeling → New parameter → Fields**. Create `ParameterField` **first** (it only uses
   columns, so it always resolves), then the measure-based ones (`ParameterKPIs`,
   `ParameterMarket Año/Período` + their `-1`). For each, replace the auto-generated DAX
   with the matching block in [`02_field_parameters.dax`](02_field_parameters.dax).

Order matters only to avoid temporary "unresolved" warnings: columns→measures→measure
parameters. Everything resolves once all objects exist.
