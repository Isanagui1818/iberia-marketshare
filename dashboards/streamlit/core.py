"""Lógica del informe Market Data SN: carga, framework de período y medidas.
Replica el modelo Power BI (Ventas / Market Share / BPS / %Peso / crecimientos)
sobre los datos sintéticos. Todo en euros/unidades anonimizadas."""
from pathlib import Path
import pandas as pd
import streamlit as st

DATA = Path(__file__).resolve().parent.parent / "data"
NAVY, BLUE, ACCENT = "#0A2A66", "#1F4E9E", "#1467BC"
MENU = "#002060"   # tono del menú (botones izq. fondo / texto derecha)
GREEN, RED = "#2E9E5B", "#D23B3B"
MESES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]


@st.cache_data
def load():
    t = {f.stem: pd.read_csv(f) for f in DATA.glob("*.csv") if not f.stem.startswith("flat")}
    fact = (t["FACT_TABLE"]
            .merge(t["DIM_PROD"], on="Product ID", how="left")
            .merge(t["DIM_CHANNEL"], on="Channel ID", how="left")
            .merge(t["DIM_SALES_TYPE"], on="Sales Type ID", how="left")
            .merge(t["DIM_UNITS"], on="KPI Flag ID", how="left")
            .merge(t["DIM_CALENDAR"][["Period ID", "Year", "Month Number"]], on="Period ID", how="left"))
    return fact, t["DIM_CALENDAR"], t["FACT_BIRTH_RATE"]


FACT, CAL, BIRTH = load()
PERIODS = sorted(CAL["Period ID"].unique())
# Último período con datos reales (se recalcula solo si el dataset se actualiza)
LAST_PERIOD = int(FACT["Period ID"].max())
LAST_PERIOD_FMT = f"{LAST_PERIOD % 100:02d}/{LAST_PERIOD // 100}"
COMPANIES = sorted(FACT["Manufacturer"].dropna().unique())
METRICS = ["Valor €", "Volumen Kg", "Unidades", "Volumen L"]
# campos disponibles para "Selector de Campo" (field parameter)
FIELDS = {"Área de Negocio": "Business Area", "Compañía": "Manufacturer", "Categoría": "Category",
          "SubCategoría": "Sub Category", "Entorno": "Type Channel", "Canal": "Channel",
          "SubCanal": "SubChannel", "Marca": "Brand", "Sub Marca": "Sub Brand",
          "Producto": "Product", "Formato": "Format", "Market": "Market", "Etapa": "Etapas"}


# --------------------------------------------------------------------------- #
# Ventanas de período (equivalente a _AuxPeriod + time-intel DAX)
# --------------------------------------------------------------------------- #
def window(anchor, tipo, variant):
    i = PERIODS.index(anchor)
    yr = anchor // 100
    # Ventana de n períodos que termina en el índice e. Si e < 0 la ventana cae entera
    # antes del inicio de los datos (no hay período anterior) -> vacía, en vez de hacer
    # slicing con índice negativo (que devolvería una ventana errónea).
    last = lambda n, e: PERIODS[max(0, e - n + 1): e + 1] if e >= 0 else []
    ytd = lambda y, u: [p for p in PERIODS if p // 100 == y and p <= u]
    ly = anchor - 100
    lyi = PERIODS.index(ly) if ly in PERIODS else None
    n = {"MES": 1, "L3M": 3, "L4M": 4, "L6M": 6, "TAM": 12}.get(tipo)
    if tipo == "YTD":
        return {"current": ytd(yr, anchor), "prev": ytd(yr - 1, anchor - 100),
                "ly": ytd(yr - 1, anchor - 100)}[variant]
    if variant == "current":
        return last(n, i)
    if variant == "prev":
        return last(n, i - n)
    if variant == "ly":
        return last(n, lyi) if lyi is not None else []
    return []


# --------------------------------------------------------------------------- #
# Medidas
# --------------------------------------------------------------------------- #
def ventas(df, periods):
    if not periods:
        return 0.0
    return float(df.loc[df["Period ID"].isin(periods), "KPI Value"].sum())


def apply_filters(metric, area=None, cat=None, entorno=None, canal=None):
    """df de mercado (sin filtro de compañía)."""
    d = FACT[FACT["KPI Flag"] == metric]
    if area:    d = d[d["Business Area"].isin(area)]
    if cat:     d = d[d["Category"].isin(cat)]
    if entorno: d = d[d["Type Channel"].isin(entorno)]
    if canal:   d = d[d["Channel"].isin(canal)]
    return d


def market_share(comp_df, mkt_df, periods):
    tot = ventas(mkt_df, periods)
    return ventas(comp_df, periods) / tot if tot else 0.0


def bps(ms_cur, ms_prev):
    return (ms_cur - ms_prev) * 10000


def company_table(mkt_df, tipo, anchor):
    """Tabla por compañía: Ventas, MS, BPS, Crecimiento, %Crecimiento (período 'tipo')."""
    cur, prev = window(anchor, tipo, "current"), window(anchor, tipo, "prev")
    tot_cur, tot_prev = ventas(mkt_df, cur), ventas(mkt_df, prev)
    rows = []
    for c in mkt_df["Manufacturer"].dropna().unique():
        cd = mkt_df[mkt_df["Manufacturer"] == c]
        v, vp = ventas(cd, cur), ventas(cd, prev)
        ms = v / tot_cur if tot_cur else 0
        msp = vp / tot_prev if tot_prev else 0
        rows.append({"Compañía": c, "Ventas": v, "Market Share": ms, "BPS": bps(ms, msp),
                     "Crecimiento Ventas": v - vp,
                     "%Crecimiento Ventas": (v / vp - 1) if vp else 0})
    return pd.DataFrame(rows).sort_values("Ventas", ascending=False).reset_index(drop=True)


def breakdown_table(mkt_df, field_col, tipo, anchor):
    """Tabla por dimensión (Selector de Campo) con todas las métricas del período."""
    cur, prev = window(anchor, tipo, "current"), window(anchor, tipo, "prev")
    tot_cur, tot_prev = ventas(mkt_df, cur), ventas(mkt_df, prev)
    rows = []
    for m in mkt_df[field_col].dropna().unique():
        gd = mkt_df[mkt_df[field_col] == m]
        v, vp = ventas(gd, cur), ventas(gd, prev)
        # market share del segmento = ventas segmento / ventas mercado, dentro del propio segmento universe
        ms = v / tot_cur if tot_cur else 0
        msp = vp / tot_prev if tot_prev else 0
        rows.append({field_col: m, f"Ventas {tipo}": v, f"Ventas {tipo}-1": vp,
                     f"Crecimiento {tipo}": v - vp,
                     f"%Crecimiento {tipo}": (v / vp - 1) if vp else 0,
                     f"Market Share {tipo}": ms, f"Market Share {tipo}-1": msp,
                     f"BPS {tipo}": bps(ms, msp),
                     f"%Peso {tipo}": v / tot_cur if tot_cur else 0,
                     f"%Peso {tipo}-1": vp / tot_prev if tot_prev else 0})
    return pd.DataFrame(rows).sort_values(f"Ventas {tipo}", ascending=False).reset_index(drop=True)


# --------------------------------------------------------------------------- #
# Formato (español)
# --------------------------------------------------------------------------- #
def es_num(v, dec=0):
    s = f"{v:,.{dec}f}"
    return s.replace(",", "X").replace(".", ",").replace("X", ".")


def es_mill(v):
    return f"{es_num(v / 1e6, 1)} mill."


def es_pct(v, dec=1):
    return f"{es_num(v * 100, dec)} %"


def arrow(v):
    return "▲" if v > 0 else ("▼" if v < 0 else "—")


def color(v):
    return GREEN if v > 0 else (RED if v < 0 else "#888")
