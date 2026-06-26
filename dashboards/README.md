> [!WARNING]
> _Streamlit is operational and published. Evidence is built (SQL + Markdown, mirrors the
> same 8-page report), runs and has been verified locally — publication pending. Looker
> Studio is still pending development._

Each dashboard reimplements the Power BI report on the synthetic dataset. Once a dashboard
is operational it is also **published online and can be consulted directly — no setup
required:**

- **Streamlit (live)** — **[📊iberia-marketshare.streamlit.app](https://iberia-marketshare.streamlit.app/)**
- **Evidence** — _built & verified locally (`npm run dev`), publication pending_
- **Looker Studio** — _pending development_

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
