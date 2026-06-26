# Evidence — parity with the Streamlit build (handoff checklist)

Goal: bring the Evidence dashboard to feature parity with `dashboards/streamlit/`.
**Streamlit is the reference implementation** — read `dashboards/streamlit/app.py` and
`core.py` and translate the logic to Evidence SQL/Markdown. The Evidence-specific gotchas are
in the repo `CLAUDE.md` ("Evidence gotchas"). Verify each item locally with `npm run dev`.

## Already done in Evidence
- 8 pages render; period framework MES/L4M/YTD/TAM via `pidx`; measures in page queries.
- Año + Mes `ButtonGroup`s (single select), default to the latest period.
- Top 7 bars 4-colour split (green/red/orange/gray); **BPS = 0** when no prior (vg_kpis, seg_cat).
- Monthly chart split columns (#002060 / #00ACED); sidebar order via `sidebar_position`.

## Pending — port from Streamlit

1. **Multi-select Año/Mes + "Todos"** (the big one). Mirror `core.resolve()`:
   - Make Año and Mes **multi-select** (Evidence `<Dropdown multiple=true>` with a select-all,
     or keep ButtonGroups + a "Todos" item). The period CTE must accept *lists* of years/months
     (use `where year in ${inputs.anios.value}` / `month_number in ${inputs.meses.value}`).
   - **Single (1 year + 1 month)** → keep the window model (MES/L4M/YTD/TAM vs preceding block).
   - **Multiple** → sum the selected periods (current) and compare vs the **same months with each
     selected year shifted back by the number of selected years** (May+Jun 2023 → May+Jun 2022;
     2022+2023 → 2020+2021), `has_prior=false` (→ gray, BPS 0) when that prior block has no data.
   - Hide the MES/L4M/YTD/TAM `ButtonGroup` in multi mode (Svelte `{#if}` on the input).

2. **Comparison colours** (4 states) everywhere feasible: green up · red down · orange no-change
   · gray no-prior. Tables use `contentType=delta` (green/red only — orange/gray is an Evidence
   limitation; document it). BPS already returns 0 with no prior.

3. **Adaptive scale + European format**:
   - Port `es_escala` (mill./mil/units) — Evidence `BigValue` has no per-value logic, so compute
     the scaled value + suffix **in SQL** (CASE on magnitude) or accept a fixed `fmt`.
   - European separators (`.` thousands, `,` decimals): set in `evidence.config.yaml` (locale) or
     per-component `fmt`.
   - Port `es_sig` (adaptive decimals, ≥2 significant figures) for **BPS** so tiny values aren't 0.

4. **Increment charts** (Vista General): depend only on the **YEAR** (ignore the month
   multi-select). Monthly chart shows **real per-month YoY BPS** in BPS mode (single series),
   `(share_this_year_month − share_prior_year_month) × 10000`, not market share.

5. **Tooltips typed by metric**: % for Market Share, adaptive value for Ventas, es_sig for BPS.
   Evidence's default tooltip lists all stacked series — fully custom tooltips (only the relevant
   case + the difference) need a raw `<ECharts>` component (optional, more fragile).

6. **No clutter**: no static "x mill." bar labels; no redundant hover tooltips on KPI numbers.

## Verify
`cd dashboards/evidence && npm install && npm run sources && npm run dev` → check every page
loads with data and no Catalog errors; test 2022-01 (no prior → gray, BPS 0) and a multi-select.
