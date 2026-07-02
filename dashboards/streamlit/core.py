"""Lógica del informe Market Data SN: carga, framework de período y medidas.
Replica el modelo Power BI (Ventas / Market Share / BPS / %Peso / crecimientos)
sobre los datos sintéticos. Todo en euros/unidades anonimizadas."""
from pathlib import Path
import math
import pandas as pd
import streamlit as st

DATA = Path(__file__).resolve().parent.parent / "data"
NAVY, BLUE, ACCENT = "#0A2A66", "#1F4E9E", "#1467BC"
MENU = "#002060"   # tono del menú (botones izq. fondo / texto derecha)
GREEN, RED = "#2E9E5B", "#D23B3B"
ORANGE, GRAY = "#E8941A", "#888888"   # naranja = sin variación · gris = sin comparativa
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


def resolve(years, months, tipo):
    """Resuelve (períodos_actual, períodos_anterior, has_prior, multi) según la selección.
    - Un único período (1 año, 1 mes) -> modo ventana: usa window(anchor, tipo) con
      MES/L4M/YTD/TAM y compara contra el bloque inmediatamente anterior.
    - Selección múltiple (varios meses y/o años) -> suma los períodos elegidos y compara
      contra los mismos meses con los años desplazados atrás tantos años como años
      seleccionados (p. ej. May+Jun 2023 -> May+Jun 2022; 2022+2023 -> 2020+2021),
      existan o no los datos del bloque anterior."""
    years, months = sorted(years), sorted(months)
    multi = len(years) > 1 or len(months) > 1
    if not multi:
        a = years[0] * 100 + months[0]
        if a not in PERIODS:
            a = max(p for p in PERIODS if p <= a)
        return window(a, tipo, "current"), window(a, tipo, "prev"), bool(window(a, tipo, "prev")), False
    n = len(years)
    cur = sorted(p for y in years for m in months if (p := y * 100 + m) in PERIODS)
    prev = sorted(p for y in years for m in months if (p := (y - n) * 100 + m) in PERIODS)
    return cur, prev, bool(prev), True


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


def bps(ms_cur, ms_prev, has_prior=True):
    # BPS es por definición una diferencia entre dos períodos. Si no hay período anterior
    # con el que comparar, la resta (ms_cur - 0) y su ×10000 darían un valor irreal, así
    # que devolvemos 0 (se mostrará en gris como "sin comparativa").
    return (ms_cur - ms_prev) * 10000 if has_prior else 0.0


def sales_by(mkt_df, key, periods):
    """Ventas por miembro de la dimensión `key` en `periods`, en una sola agregación.
    Devuelve una Series indexada por TODOS los miembros presentes en mkt_df (0 si el
    miembro no vende en la ventana o la ventana es vacía)."""
    members = pd.Index(mkt_df[key].dropna().unique(), name=key)
    if not periods:
        return pd.Series(0.0, index=members)
    s = mkt_df.loc[mkt_df["Period ID"].isin(periods)].groupby(key)["KPI Value"].sum()
    return s.reindex(members, fill_value=0.0).astype(float)


def company_table(mkt_df, cur, prev):
    """Tabla por compañía: Ventas, MS, BPS, Crecimiento, %Crecimiento sobre los períodos
    'cur' vs 'prev' (ya resueltos). Si no hay período anterior las medidas comparativas
    valen 0."""
    has_prior = bool(prev)
    tot_cur, tot_prev = ventas(mkt_df, cur), ventas(mkt_df, prev)
    v, vp = sales_by(mkt_df, "Manufacturer", cur), sales_by(mkt_df, "Manufacturer", prev)
    ms = v / tot_cur if tot_cur else v * 0.0
    msp = vp / tot_prev if tot_prev else vp * 0.0
    df = pd.DataFrame({
        "Compañía": v.index.to_numpy(), "Ventas": v.to_numpy(),
        "Market Share": ms.to_numpy(),
        "BPS": ((ms - msp) * 10000 if has_prior else v * 0.0).to_numpy(),
        "Crecimiento Ventas": ((v - vp) if has_prior else v * 0.0).to_numpy(),
        "%Crecimiento Ventas": (v / vp - 1).where(vp != 0, 0.0).to_numpy(),
    }).sort_values("Ventas", ascending=False).reset_index(drop=True)
    df.attrs["has_prior"] = has_prior
    return df


def breakdown_table(mkt_df, field_col, cur, prev, label):
    """Tabla por dimensión (Selector de Campo) con todas las métricas. 'label' nombra las
    columnas (la ventana en modo único, o 'Sel.' en multiselección)."""
    has_prior = bool(prev)
    tot_cur, tot_prev = ventas(mkt_df, cur), ventas(mkt_df, prev)
    v, vp = sales_by(mkt_df, field_col, cur), sales_by(mkt_df, field_col, prev)
    # cuota del segmento = ventas del segmento / ventas del mercado (= %Peso en este modelo)
    ms = v / tot_cur if tot_cur else v * 0.0
    msp = vp / tot_prev if tot_prev else vp * 0.0
    df = pd.DataFrame({
        field_col: v.index.to_numpy(),
        f"Ventas {label}": v.to_numpy(), f"Ventas {label}-1": vp.to_numpy(),
        f"Crecimiento {label}": ((v - vp) if has_prior else v * 0.0).to_numpy(),
        f"%Crecimiento {label}": (v / vp - 1).where(vp != 0, 0.0).to_numpy(),
        f"Market Share {label}": ms.to_numpy(), f"Market Share {label}-1": msp.to_numpy(),
        f"BPS {label}": ((ms - msp) * 10000 if has_prior else v * 0.0).to_numpy(),
        f"%Peso {label}": ms.to_numpy(), f"%Peso {label}-1": msp.to_numpy(),
    }).sort_values(f"Ventas {label}", ascending=False).reset_index(drop=True)
    df.attrs["has_prior"] = has_prior
    return df


# --------------------------------------------------------------------------- #
# Formato (español)
# --------------------------------------------------------------------------- #
def es_num(v, dec=0):
    s = f"{v:,.{dec}f}"
    return s.replace(",", "X").replace(".", ",").replace("X", ".")


def es_mill(v):
    return f"{es_num(v / 1e6, 1)} mill."


def es_escala(v):
    """Formato adaptativo a la magnitud (nomenclatura europea):
    >= 1 millón -> 'mill.' · >= 1.000 -> 'mil' · resto -> número completo.
    Evita perder detalle (p. ej. 32.857 se ve '32,9 mil', no '0,0 mill.')."""
    m = abs(v)
    if m >= 1e6:
        return f"{es_num(v / 1e6, 1)} mill."
    if m >= 1e3:
        return f"{es_num(v / 1e3, 1)} mil"
    return es_num(v, 0)


def es_pct(v, dec=1):
    return f"{es_num(v * 100, dec)} %"


def es_sig(v, sig=2, maxdec=8):
    """Decimales adaptativos: muestra al menos `sig` cifras significativas. Útil para valores
    pequeños (p. ej. un BPS de 0,005) que con pocos decimales saldrían como 0 pese a existir."""
    if v == 0:
        return "0"
    exp = math.floor(math.log10(abs(v)))
    dec = min(max(0, sig - 1 - exp), maxdec)
    return es_num(v, dec)


def arrow(v, has_prior=True):
    # ▲ sube · ▼ baja · – sin variación (naranja) · ○ sin comparativa (gris)
    if not has_prior:
        return "○"
    return "▲" if v > 0 else ("▼" if v < 0 else "–")


def color(v, has_prior=True):
    # verde sube · rojo baja · naranja sin variación · gris sin comparativa
    if not has_prior:
        return GRAY
    return GREEN if v > 0 else (RED if v < 0 else ORANGE)
