# Dashboards

Three ways to surface the same synthetic market-share data — build them, compare, keep the
one you like. All read from [`data/`](data/) (the star schema exported to CSV, committed
because it's fully synthetic).

| | [`streamlit/`](streamlit/) | [`evidence/`](evidence/) | [`looker-studio/`](looker-studio/) |
|---|---|---|---|
| **Type** | Python app | BI-as-code (SQL + Markdown) | No-code cloud |
| **Lives in repo** | ✅ code | ✅ code | ❌ (recipe only) |
| **Free public link** | ✅ Streamlit Cloud | ✅ Evidence Cloud / Netlify | ✅ share link |
| **Account** | GitHub | GitHub | Gmail |
| **Shows off** | Python · pandas · viz | SQL · data modelling | speed · no-code |
| **Status here** | ✅ built & tested | ⚙️ scaffolded (needs Node) | 📋 data + build guide |
| **Period framework** | full (MES/L4M/YTD/TAM, growth, share) | core (metric, trend, share) | via native controls/comparisons |

## Quick start

- **Streamlit** — `cd streamlit && pip install -r requirements.txt && streamlit run app.py`
- **Evidence** — see [`evidence/README.md`](evidence/README.md) (needs Node 18+)
- **Looker Studio** — follow [`looker-studio/README.md`](looker-studio/README.md)

## Which to keep?

- Want to show **engineering + analytics** with code in the repo → **Streamlit**.
- Want to lead with **SQL** and a git-native BI site → **Evidence**.
- Want the **fastest live link**, no code → **Looker Studio**.

They're not exclusive — a repo can ship the Streamlit/Evidence app *and* link a Looker
Studio page.
