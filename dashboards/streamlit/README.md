> [!NOTE]
> _This is a preliminary version that will keep being improved. The structure is already complete, but aesthetic improvements are still pending._

# Streamlit dashboard — Market Data SN

Multi-page Python replica of the Power BI report, in Spanish, on the synthetic data.
A code-native version of the original 8-page report.

## Pages

`Menú` (landing + nav) · `Glosario` · `Vista General` (KPIs, increment vs prior period,
market performance + Top 7) · `Performance` (field/KPI selectors, full metrics table) ·
`Evolución` (line/bar over time) · `Segmento de Mercado` (product comparison, L4M/L3M) ·
`Birth Rate` · `Informe Dinámico` (build + export to CSV/Excel).

## Files

- `app.py` — navigation (tab-style top nav), shared filter bar, the 8 page renderers.
- `core.py` — data load, the period framework (MES/L4M/YTD/TAM + `-1`/LY), the measures
  (Ventas, Market Share, BPS, %Peso, growth), Top-N and Spanish number formatting.
- `.streamlit/config.toml` — navy/blue theme matching the report.

## Run locally

```bash
cd dashboards/streamlit
pip install -r requirements.txt
python -m streamlit run app.py        # opens http://localhost:8501
```

> Reads `../data/*.csv`. The dataset now has ~19 anonymized companies (`Compañía SN` is the
> focal one) so the "Top 7" makes sense — the source workbook was updated too, so a Power BI
> refresh stays consistent.

## Deploy (free public link)

[📊 Streamlit Dashboard](https://iberia-marketshare.streamlit.app/)


## Fidelity note

Structure, colors, the dynamic selectors and all the measures are replicated. Streamlit is
not pixel-perfect vs Power BI (different engine); a few native-visual details are
approximated, not cloned.
