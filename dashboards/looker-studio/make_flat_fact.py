"""Genera ../data/flat_fact_for_looker.csv: el esquema en estrella desnormalizado en una
tabla ancha (Looker Studio prefiere una sola fuente).

El CSV resultante NO se versiona (pesa ~15 MB y cada re-export engordaría el historial de
git para siempre): se regenera aquí a partir de las tablas del modelo, que sí están
commiteadas. Ejecutar antes de subirlo a Google Sheets:

    python dashboards/looker-studio/make_flat_fact.py
"""
from pathlib import Path

import pandas as pd

DATA = Path(__file__).resolve().parent.parent / "data"
OUT = DATA / "flat_fact_for_looker.csv"

# columnas de la tabla ancha, en el orden que documenta el kit de Looker
COLS = ["Period ID", "Date", "Year", "Quarter", "Month Long", "Period Name",
        "Product", "Brand", "Sub Brand", "Manufacturer", "Business Area",
        "Category", "Sub Category", "Market", "Format", "Etapas",
        "Channel", "SubChannel", "Type Channel", "KPI Flag", "KPI Value"]


def build():
    read = lambda name: pd.read_csv(DATA / f"{name}.csv")
    flat = (read("FACT_TABLE")
            .merge(read("DIM_CALENDAR")[["Period ID", "Date", "Year", "Quarter",
                                         "Month Long", "Period Name"]],
                   on="Period ID", how="left")
            .merge(read("DIM_PROD")[["Product ID", "Product", "Brand", "Sub Brand",
                                     "Manufacturer", "Business Area", "Category",
                                     "Sub Category", "Market", "Format", "Etapas"]],
                   on="Product ID", how="left")
            .merge(read("DIM_CHANNEL")[["Channel ID", "Channel", "SubChannel", "Type Channel"]],
                   on="Channel ID", how="left")
            .merge(read("DIM_UNITS")[["KPI Flag ID", "KPI Flag"]],
                   on="KPI Flag ID", how="left"))
    return flat[COLS]


if __name__ == "__main__":
    df = build()
    df.to_csv(OUT, index=False)
    print(f"{OUT.name}: {len(df):,} filas x {len(df.columns)} columnas -> {OUT}")
