<p align="center"><em>Actualmente solo está operativo el dashboard de Streamlit. Los dashboards de Evidence y Looker Studio están todavía pendientes de desarrollar.</em></p>

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
