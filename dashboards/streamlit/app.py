"""
Market Data SN — réplica en Streamlit del informe Power BI (datos sintéticos, español).
Informe multipágina: Menú · Glosario · Vista General · Performance · Evolución ·
Segmento de Mercado · Birth Rate · Informe Dinámico.
"""

# cd C:\Users\isana\Documents\Claude\iberia-marketshare-dwh\dashboards\streamli python -m streamlit run app.py

from io import BytesIO
import pandas as pd
import plotly.graph_objects as go
import streamlit as st
import core as C

st.set_page_config(page_title="Market Data SN", layout="wide", page_icon="📊")

# --------------------------------------------------------------------------- #
# Estilos
# --------------------------------------------------------------------------- #
st.markdown(f"""
<style>
footer {{display:none !important;}}
.block-container {{padding-top:4.3rem; padding-bottom:1rem;}}
h1,h2,h3,h4 {{color:{C.NAVY};}}
.kpi {{border:1px solid #dce3f0; border-radius:9px; padding:13px 14px; background:#fff;
       box-shadow:0 1px 3px rgba(10,42,102,.06); min-height:132px;
       display:flex; flex-direction:column; justify-content:flex-start; text-align:center;}}
.kpi .t {{color:{C.ACCENT}; font-weight:700; font-size:1rem; line-height:1.2; margin-bottom:6px;}}
.kpi .body {{flex:1; display:flex; flex-direction:column; justify-content:center;}}
.kpi .v {{font-size:2.35rem; font-weight:800; line-height:1.05;}}
.kpi .v:empty {{display:none;}}
.kpi .s {{font-size:.9rem; font-weight:700; line-height:1.55;}}
/* modo compacto: menos aire para reducir scroll */
hr {{margin:.45rem 0 !important;}}
h2 {{font-size:1.2rem !important; margin:.2rem 0 !important;}}
h3 {{font-size:1.05rem !important; margin:.2rem 0 !important;}}
[data-testid="stVerticalBlock"] {{gap:.55rem;}}
[data-testid="stElementToolbar"] {{display:none;}}
.descbox {{background:#f2f4f8; border-radius:8px; padding:18px; color:{C.MENU};
           box-sizing:border-box;}}
.descbox b {{color:{C.MENU};}}
/* Botones del menú: fondo #002060, texto blanco en negrita, grandes y juntos (estilo Power BI) */
[data-testid="stColumn"]:has([class*="st-key-mb_"]) [data-testid="stVerticalBlock"] {{gap:.3rem;}}
[class*="st-key-mb_"] button {{background:{C.MENU} !important; color:#fff !important;
        border:1px solid {C.MENU} !important; font-size:1.4rem !important; font-weight:800 !important;
        min-height:3.5rem; max-width:340px; margin:0 auto; display:block;}}
[class*="st-key-mb_"] button:hover {{background:#00143f !important; color:#fff !important;}}
/* Navegación superior (pestañas) legible */
.stButton button {{font-weight:700; font-size:.82rem; line-height:1.15;
                   white-space:normal; padding:.45rem .3rem; min-height:2.6rem;}}
.stButton button[kind="secondary"] {{background:#fff; color:{C.NAVY}; border:1px solid #c9d6ef;}}
.stButton button[kind="secondary"]:hover {{border-color:{C.ACCENT}; color:{C.ACCENT};}}
.stButton button[kind="primary"] {{background:{C.ACCENT}; color:#fff; border:1px solid {C.ACCENT};}}
</style>""", unsafe_allow_html=True)

if "page" not in st.session_state:
    st.session_state.page = "Menú"
NAV = ["Menú", "Glosario", "Vista General", "Performance", "Evolución",
       "Segmento de Mercado", "Birth Rate", "Informe Dinámico"]


def goto(p):
    st.session_state.page = p


def topnav():
    cols = st.columns(len(NAV))
    for c, name in zip(cols, NAV):
        c.button(name, key="nav_" + name, width="stretch",
                 type="primary" if st.session_state.page == name else "secondary",
                 on_click=goto, args=(name,))
    st.divider()


# --------------------------------------------------------------------------- #
# Barra de filtros compartida -> devuelve selección
# --------------------------------------------------------------------------- #
def filtros(solo_fecha=False):
    years = sorted(C.CAL["Year"].unique())
    c = st.columns(8)
    # Por defecto, el año más reciente con datos (índice al último de la lista)
    anio = c[0].selectbox("Año", ["Todas"] + years, index=len(years), key="f_anio")
    mes = c[1].selectbox("Mes", ["Mes Actual"] + C.MESES, key="f_mes")
    yr = max(years) if anio == "Todas" else anio
    months = sorted(C.CAL.loc[C.CAL["Year"] == yr, "Month Number"].unique())
    mo = max(months) if mes == "Mes Actual" else (C.MESES.index(mes) + 1)
    anchor = yr * 100 + mo
    anchor = anchor if anchor in C.PERIODS else max(p for p in C.PERIODS if p <= anchor)
    if solo_fecha:
        return dict(anchor=anchor, metric="Valor €", company=None, area=[], cat=[], ent=[], canal=[])
    metric = c[2].selectbox("Métrica", C.METRICS, key="f_metric")
    company = c[3].selectbox("Compañía", C.COMPANIES,
                             index=C.COMPANIES.index("Compañía SN") if "Compañía SN" in C.COMPANIES else 0,
                             key="f_comp")
    area = c[4].multiselect("Área de Negocio", sorted(C.FACT["Business Area"].dropna().unique()), key="f_area")
    cat = c[5].multiselect("Categoría", sorted(C.FACT["Category"].dropna().unique()), key="f_cat")
    ent = c[6].multiselect("Entorno", sorted(C.FACT["Type Channel"].dropna().unique()), key="f_ent")
    canal = c[7].multiselect("Canal", sorted(C.FACT["Channel"].dropna().unique()), key="f_canal")
    return dict(anchor=anchor, metric=metric, company=company, area=area, cat=cat, ent=ent, canal=canal)


def kpi(col, title, value, sub_html=""):
    col.markdown(f'<div class="kpi"><div class="t">{title}</div>'
                 f'<div class="body"><div class="v">{value}</div>'
                 f'<div class="s">{sub_html}</div></div></div>',
                 unsafe_allow_html=True)


def header(sub):
    a, b = st.columns([1, 5])
    a.markdown(f"**Datos de Mercado SN**")
    a.caption(sub)


# =========================================================================== #
# PÁGINAS
# =========================================================================== #
def page_menu():
    st.markdown(f"<h1 style='text-align:center;color:{C.MENU};margin:.4rem 0 0;'>"
                f"Market Data SN</h1>", unsafe_allow_html=True)
    st.markdown("<div style='height:5vh'></div>", unsafe_allow_html=True)   # baja el bloque
    _, izq, der, _ = st.columns([1, 2, 2, 1])   # espaciadores laterales -> centrado
    with izq:
        for i, p in enumerate(["Glosario", "Vista General", "Performance", "Evolución",
                               "Segmento de Mercado", "Birth Rate", "Informe Dinámico"]):
            st.button(p, key=f"mb_{i}", width="stretch", on_click=goto, args=(p,))
    with der:
        st.markdown(f"""<div class="descbox" style="min-height:26.3rem; display:flex;
             flex-direction:column; justify-content:space-between;">
        <div><b>Informe de cuota de mercado de la industria de nutrición especializada
        (datos sintéticos anonimizados).</b><br><br>
        Analiza ventas, market share, crecimiento y participación (%Peso) por compañía,
        categoría, canal, marca y producto, en distintos horizontes temporales — MES, L4M,
        YTD y TAM — con comparativas frente al período anterior y al mismo período del año
        anterior. Usa el menú de la izquierda para navegar por las páginas del informe.</div>
        <div style="text-align:center;font-size:.95rem;">
        Último Período Cargado: <b>{C.LAST_PERIOD_FMT}</b></div></div>""", unsafe_allow_html=True)


def page_glosario():
    topnav(); header("Glosario")
    st.markdown("""
- **Ventas L4M / L4M-1** — *Ventas acumuladas de los últimos 4 meses.* L4M es la suma de los
  últimos 4 meses desde la fecha seleccionada; L4M-1, los 4 meses anteriores.
- **Ventas TAM / TAM-1** — *Ventas acumuladas de los últimos 12 meses* (Total Año Móvil) y los
  12 meses previos.
- **Ventas YTD / YTD-1** — *Acumulado del 1 de enero* hasta la fecha seleccionada, y el mismo
  período del año anterior.
- **Crecimiento TAM (absoluto)** — `[Ventas TAM] − [Ventas TAM-1]`, en valores absolutos.
- **%Crecimiento** — Crecimiento porcentual entre el período actual y el equivalente anterior.
- **Market Share Mes** — *Participación de mercado mensual* = `[Ventas Mes] / [Ventas Mercado]`.
- **%Peso / %Distribución** — Cuota del segmento sobre el total, por dimensión (Área, Compañía,
  Categoría, SubCategoría, Tipo de Canal, Canal, SubCanal, Marca, Producto, Formato, Market, Etapa).
- **BPS Período** — *Puntos básicos* (1 bps = 0,01%): `(Market Share − Market Share período
  anterior) × 10000`.

**Categorías (anónimas):** Beverages, Snacks, Dairy, Bakery, Frozen, Condiments,
Personal Care, Household. **Métricas:** Volumen Kg · Valor € · Unidades · Volumen L.
""")


def page_vista():
    topnav(); header("Descripción General")
    f = filtros()
    mkt = C.apply_filters(f["metric"], f["area"], f["cat"], f["ent"], f["canal"])
    comp = mkt[mkt["Manufacturer"] == f["company"]]
    a = f["anchor"]

    # --- KPIs ---
    def rng(tipo, var):
        w = C.window(a, "L6M", var)
        return f"{min(w)%100:02d}/{min(w)//100} - {max(w)%100:02d}/{max(w)//100}" if w else ""
    v_prev = C.ventas(comp, C.window(a, "L6M", "prev"))
    v_cur = C.ventas(comp, C.window(a, "L6M", "current"))
    dif = v_cur - v_prev
    ms = C.market_share(comp, mkt, C.window(a, "MES", "current"))
    k = st.columns(5)
    has6 = bool(C.window(a, "L6M", "prev"))   # ¿hay 6 meses anteriores con los que comparar?
    kpi(k[0], f"Ventas {rng('L6M','prev')}", C.es_mill(v_prev))
    kpi(k[1], f"Ventas {rng('L6M','current')}", C.es_mill(v_cur))
    tip6 = f"Últimos 6 meses {C.es_mill(v_cur)} vs 6 meses anteriores {C.es_mill(v_prev)}" if has6 else "Sin 6 meses anteriores con los que comparar"
    kpi(k[2], "Variación Últimos 6 meses",
        f"<span style='color:{C.color(dif, has6)}' title='{tip6}'>{C.arrow(dif, has6)} {C.es_mill(dif)}</span>",
        f"<span style='color:{C.color(dif, has6)}'>{C.es_pct(dif/v_prev if v_prev else 0)}</span>")
    kpi(k[3], "Market Share Mes", C.es_pct(ms))
    bps_html = ""
    for tp in ["MES", "L4M", "YTD", "TAM"]:
        hasp = bool(C.window(a, tp, "prev"))
        msc = C.market_share(comp, mkt, C.window(a, tp, "current"))
        msp = C.market_share(comp, mkt, C.window(a, tp, "prev"))
        b = C.bps(msc, msp, hasp)
        tipb = (f"Cuota actual {C.es_pct(msc)} vs anterior {C.es_pct(msp)}" if hasp
                else "Sin período anterior con el que comparar")
        bps_html += (f"BPS {tp} <span style='color:{C.color(b, hasp)}' title='{tipb}'>"
                     f"{C.arrow(b, hasp)} {C.es_num(b)}</span><br>")
    kpi(k[4], "BPS", "", bps_html)

    st.write("")
    # --- Incremento vs Período Anterior ---
    st.subheader("Incremento vs Período Anterior")
    metr = st.radio("Métrica del gráfico", ["Market Share", "Ventas", "BPS"],
                    horizontal=True, label_visibility="collapsed", key="vg_metr")

    def val(tipo, var):
        if metr == "Ventas":
            return C.ventas(comp, C.window(a, tipo, var))
        msc = C.market_share(comp, mkt, C.window(a, tipo, "current"))
        if metr == "BPS":
            return C.bps(msc, C.market_share(comp, mkt, C.window(a, tipo, "prev")))
        return C.market_share(comp, mkt, C.window(a, tipo, var))

    g1, g2 = st.columns(2)
    tipos = ["MES", "L4M", "YTD", "TAM"]
    fig = go.Figure()
    if metr == "BPS":
        fig.add_bar(x=tipos, y=[val(t, "current") for t in tipos], marker_color=C.ACCENT)
    else:
        fig.add_bar(name="Período Actual", x=tipos, y=[val(t, "current") for t in tipos], marker_color=C.NAVY)
        fig.add_bar(name="Período Anterior", x=tipos, y=[val(t, "prev") for t in tipos], marker_color=C.ACCENT)
    fig.update_layout(height=235, barmode="group", margin=dict(l=10, r=10, t=10, b=10),
                      legend=dict(orientation="h", y=-.15))
    g1.plotly_chart(fig, width="stretch")

    # mensual actual vs año anterior
    yr = a // 100
    figm = go.Figure()
    def mval(m, y):
        per = y * 100 + m
        if per not in C.PERIODS:
            return 0
        return (C.ventas(comp, [per]) if metr == "Ventas"
                else C.market_share(comp, mkt, [per]))
    figm.add_bar(name="Período Actual", x=C.MESES, y=[mval(m, yr) for m in range(1, 13)], marker_color=C.NAVY)
    figm.add_bar(name="Período Anterior", x=C.MESES, y=[mval(m, yr - 1) for m in range(1, 13)], marker_color=C.ACCENT)
    figm.update_layout(height=235, barmode="group", margin=dict(l=10, r=10, t=10, b=10),
                       legend=dict(orientation="h", y=-.15))
    g2.plotly_chart(figm, width="stretch")

    st.write("")
    # --- Performance del Mercado ---
    h1, h2 = st.columns([2, 3])
    h1.subheader("Performance del Mercado")
    tipo2 = h2.radio("Período", tipos, horizontal=True, index=1, label_visibility="collapsed", key="vg_perf")
    ct = C.company_table(mkt, tipo2, a)
    has_prior = ct.attrs.get("has_prior", True)
    b1, b2 = st.columns([2, 3])
    top = ct.head(7).iloc[::-1]
    b1.markdown("**Top 7 en Ventas**")
    # Color según comparación con el período anterior: verde sube · rojo baja · naranja sin
    # variación · gris sin comparativa. Tooltip de 2 líneas: valor absoluto (arriba) y, debajo,
    # solo el caso pertinente con su símbolo y el valor de la diferencia vs período anterior.
    barcolors = [C.color(cr, has_prior) for cr in top["Crecimiento Ventas"]]
    def _var(cr):
        return f"{C.arrow(cr, has_prior)} {C.es_num(cr)}" if has_prior else "○ sin comparativa"
    cdata = [[C.es_num(v), _var(cr)] for v, cr in zip(top["Ventas"], top["Crecimiento Ventas"])]
    figb = go.Figure(go.Bar(x=top["Ventas"], y=top["Compañía"], orientation="h",
                            marker_color=barcolors,
                            text=[C.es_mill(v) for v in top["Ventas"]], textposition="outside",
                            cliponaxis=False, customdata=cdata,
                            hovertemplate="<b>%{customdata[0]}</b><br>%{customdata[1]}<extra></extra>",
                            hoverlabel=dict(bgcolor=barcolors, font=dict(color="white"), align="left")))
    figb.update_layout(height=250, margin=dict(l=10, r=70, t=10, b=10))
    b1.plotly_chart(figb, width="stretch")
    disp = ct.copy()
    sty = (disp.style
           .format({"Ventas": C.es_num, "Market Share": C.es_pct,
                    "BPS": lambda v: f"{C.arrow(v, has_prior)} {C.es_num(v)}",
                    "Crecimiento Ventas": lambda v: f"{C.arrow(v, has_prior)} {C.es_num(v)}",
                    "%Crecimiento Ventas": lambda v: f"{C.arrow(v, has_prior)} {C.es_pct(v)}"})
           .map(lambda v: f"color:{C.color(v, has_prior)}",
                subset=["Crecimiento Ventas", "%Crecimiento Ventas", "BPS"]))
    b2.dataframe(sty, width="stretch", height=300, hide_index=True)


def _selector_campo_kpi(kpi_opts):
    c1, c2 = st.columns(2)
    campo = c1.selectbox("Selector de Campo", list(C.FIELDS.keys()), key="sc_" + kpi_opts[0])
    kpisel = c2.radio("Selector KPIs", kpi_opts, horizontal=True, key="sk_" + kpi_opts[0])
    return C.FIELDS[campo], kpisel


def page_performance():
    topnav(); header("Análisis profundo del rendimiento")
    f = filtros()
    mkt = C.apply_filters(f["metric"], f["area"], f["cat"], f["ent"], f["canal"])
    col, tipo = _selector_campo_kpi(["MES", "L4M", "YTD", "TAM"])
    t = C.breakdown_table(mkt, col, tipo, f["anchor"])
    has_prior = t.attrs.get("has_prior", True)
    pct = [c for c in t.columns if c.startswith("%") or "Market Share" in c]
    comp_cols = [c for c in t.columns if "Crecimiento" in c or c.startswith("BPS")]
    fmt = {}
    for c in t.columns:
        if c == col:
            continue
        base = C.es_pct if c in pct else C.es_num
        fmt[c] = (lambda v, b=base: f"{C.arrow(v, has_prior)} {b(v)}") if c in comp_cols else base
    sty = (t.style.format(fmt)
           .map(lambda v: f"color:{C.color(v, has_prior)}", subset=comp_cols))
    st.dataframe(sty, width="stretch", height=480, hide_index=True)


def page_evolucion():
    topnav(); header("Evolución de la categoría")
    f = filtros()
    mkt = C.apply_filters(f["metric"], f["area"], f["cat"], f["ent"], f["canal"])
    col, kpisel = _selector_campo_kpi(["Ventas", "Market Share"])
    modo = st.radio("Tipo de gráfico", ["Líneas", "Barras"], horizontal=True, key="ev_modo")
    campo = [k for k, v in C.FIELDS.items() if v == col][0]
    labels = [f"{p//100}-{p%100:02d}" for p in C.PERIODS]
    market_pm = {p: C.ventas(mkt, [p]) for p in C.PERIODS}     # denominador = mercado total
    top = mkt.groupby(col)["KPI Value"].sum().nlargest(6).index.tolist()
    st.markdown(f"**Evolución por {campo}** — top {len(top)} · {kpisel}")
    palette = [C.NAVY, C.ACCENT, C.GREEN, "#E0A11B", "#8E44AD", "#16A0A0"]
    fig = go.Figure()
    data = {}
    for i, m in enumerate(top):
        md = mkt[mkt[col] == m]
        if kpisel == "Ventas":
            y = [C.ventas(md, [p]) for p in C.PERIODS]
        else:  # cuota = ventas del miembro / ventas del mercado en ese período
            y = [(C.ventas(md, [p]) / market_pm[p] if market_pm[p] else 0) for p in C.PERIODS]
        data[str(m)] = y
        cc = palette[i % len(palette)]
        if modo == "Líneas":
            fig.add_scatter(x=labels, y=y, mode="lines+markers", name=str(m), line_color=cc)
        else:
            fig.add_bar(x=labels, y=y, name=str(m), marker_color=cc)
    fig.update_layout(height=330, barmode="group", margin=dict(l=10, r=10, t=10, b=10),
                      yaxis_title=kpisel, legend=dict(orientation="h", y=-.18),
                      yaxis_tickformat=".0%" if kpisel == "Market Share" else None)
    st.plotly_chart(fig, width="stretch")
    tbl = pd.DataFrame(data, index=labels).T
    fmt = C.es_pct if kpisel == "Market Share" else C.es_num
    for cc in tbl.columns:
        tbl[cc] = tbl[cc].map(fmt)
    st.dataframe(tbl, width="stretch")


def page_segmento():
    topnav(); header("Segmento de Mercado — comparación de productos")
    f = filtros()
    tipo = st.radio("Ventana de comparación", ["L4M", "L3M"], horizontal=True, key="seg_t",
                    help="L4M = últimos 4 meses · L3M = últimos 3 meses. El crecimiento compara "
                         "el período con su equivalente anterior.")
    mkt = C.apply_filters(f["metric"], f["area"], f["cat"], f["ent"], f["canal"])
    prods = sorted(mkt["Category"].dropna().unique())
    defaults = prods[:4]
    sel = st.multiselect("Selecciona hasta 4 categorías/productos", prods, default=defaults,
                         max_selections=4, key="seg_sel")
    cols = st.columns(max(1, len(sel)))
    cur, prev = C.window(f["anchor"], tipo, "current"), C.window(f["anchor"], tipo, "prev")
    has_prior = bool(prev)
    tot_c, tot_p = C.ventas(mkt, cur), C.ventas(mkt, prev)
    for col, name in zip(cols, sel):
        gd = mkt[mkt["Category"] == name]
        vc, vp = C.ventas(gd, cur), C.ventas(gd, prev)
        msc = vc / tot_c if tot_c else 0
        msp = vp / tot_p if tot_p else 0
        b = C.bps(msc, msp, has_prior)
        g = (vc / vp - 1) if vp else 0
        dif = vc - vp
        var_txt = (f"{C.arrow(dif, has_prior)} {C.es_num(dif)}" if has_prior
                   else "○ sin comparativa")
        # barra del período actual en verde/rojo/naranja/gris según comparación con el anterior
        fig = go.Figure(go.Bar(x=[f"{tipo}-1", tipo], y=[vp, vc],
                               marker_color=[C.ACCENT, C.color(dif, has_prior)],
                               customdata=[[C.es_num(vp), "período anterior"],
                                           [C.es_num(vc), var_txt]],
                               hovertemplate="<b>%{customdata[0]}</b><br>%{customdata[1]}<extra></extra>",
                               hoverlabel=dict(bgcolor=[C.ACCENT, C.color(dif, has_prior)],
                                               font=dict(color="white"), align="left")))
        fig.update_layout(height=185, margin=dict(l=6, r=6, t=30, b=6), title=name,
                          showlegend=False)
        col.plotly_chart(fig, width="stretch")
        col.markdown(f"**BPS:** <span style='color:{C.color(b, has_prior)}'>{C.arrow(b, has_prior)} {C.es_num(b)}</span> · "
                     f"**%Crec.:** <span style='color:{C.color(g, has_prior)}'>{C.arrow(g, has_prior)} {C.es_pct(g)}</span>",
                     unsafe_allow_html=True)


def page_birth():
    topnav(); header("Birth Rate")
    filtros(solo_fecha=True)
    b = C.BIRTH.sort_values("Period ID")
    labels = [f"{p//100}-{p%100:02d}" for p in b["Period ID"]]
    fig = go.Figure(go.Scatter(x=labels, y=b["KPI Value"], mode="lines+markers",
                               line_color=C.GREEN, fill="tozeroy",
                               fillcolor="rgba(46,158,91,.15)"))
    fig.update_layout(height=330, margin=dict(l=10, r=10, t=10, b=10),
                      yaxis_title="Tasa de natalidad (‰)")
    st.plotly_chart(fig, width="stretch")


def page_dinamico():
    topnav(); header("Informe Dinámico — construye y exporta")
    f = filtros()
    mkt = C.apply_filters(f["metric"], f["area"], f["cat"], f["ent"], f["canal"])
    c1, c2 = st.columns(2)
    dims = c1.multiselect("Campos (filas)", list(C.FIELDS.keys()), default=["Compañía", "Categoría"])
    tipo = c2.radio("Período", ["MES", "L4M", "YTD", "TAM"], horizontal=True, key="dn_t")
    if not dims:
        st.info("Elige al menos un campo."); return
    cols = [C.FIELDS[d] for d in dims]
    per = C.window(f["anchor"], tipo, "current")
    g = (mkt[mkt["Period ID"].isin(per)].groupby(cols)["KPI Value"].sum()
         .reset_index().rename(columns={"KPI Value": f"Ventas {tipo}"})
         .sort_values(f"Ventas {tipo}", ascending=False))
    st.dataframe(g, width="stretch", height=330, hide_index=True)
    d1, d2 = st.columns(2)
    d1.download_button("⬇️ Descargar CSV", g.to_csv(index=False).encode("utf-8"),
                       "informe_dinamico.csv", "text/csv", width="stretch")
    buf = BytesIO()
    with pd.ExcelWriter(buf, engine="openpyxl") as w:
        g.to_excel(w, index=False, sheet_name="Informe")
    d2.download_button("⬇️ Descargar Excel", buf.getvalue(), "informe_dinamico.xlsx",
                       "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", width="stretch")


# =========================================================================== #
PAGES = {"Menú": page_menu, "Glosario": page_glosario, "Vista General": page_vista,
         "Performance": page_performance, "Evolución": page_evolucion,
         "Segmento de Mercado": page_segmento, "Birth Rate": page_birth,
         "Informe Dinámico": page_dinamico}
PAGES[st.session_state.page]()
