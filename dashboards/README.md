> [!WARNING]
> _Only the Streamlit dashboard is currently operational. The Evidence and Looker Studio dashboards are still pending development._

Each dashboard reimplements the Power BI report on the synthetic dataset. Once a dashboard
is operational it is also **published online and can be consulted directly — no setup
required:**

- **Streamlit (live)** — **[📊iberia-marketshare.streamlit.app](https://iberia-marketshare.streamlit.app/)**
- **Evidence** — _pending publication_
- **Looker Studio** — _pending publication_

The **Quick start** below is only needed if you want to **download the repo and run a
dashboard locally** on your own machine.

## Quick start (run locally)

- **Streamlit** — `cd streamlit && pip install -r requirements.txt && python -m streamlit run app.py` · details in [`streamlit/README.md`](streamlit/README.md#run-locally)
- **Evidence** — see [`evidence/README.md`](evidence/README.md) (needs Node 18+)
- **Looker Studio** — follow [`looker-studio/README.md`](looker-studio/README.md)

## Which to keep?

- Want to show **engineering + analytics** with code in the repo → **Streamlit**.
- Want to lead with **SQL** and a git-native BI site → **Evidence**.
- Want the **fastest live link**, no code → **Looker Studio**.

They're not exclusive — a repo can ship the Streamlit/Evidence app *and* link a Looker
Studio page.
