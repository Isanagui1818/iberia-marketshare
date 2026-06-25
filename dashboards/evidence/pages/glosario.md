---
title: Glosario
---

Definiciones de las medidas y los horizontes temporales del informe. Replican el modelo
Power BI (medidas DAX `...Período Switch` sobre el selector `_AuxPeriod`).

## Períodos

- **MES** — el mes seleccionado.
- **L4M / L4M-1** — _ventas acumuladas de los últimos 4 meses_ desde la fecha
  seleccionada; **L4M-1** son los 4 meses inmediatamente anteriores.
- **L3M** — variante de 3 meses (usada en _Segmento de Mercado_).
- **YTD / YTD-1** — _acumulado desde el 1 de enero_ hasta la fecha seleccionada, y el
  mismo período del año anterior.
- **TAM / TAM-1** — _Total Año Móvil_: los últimos 12 meses, y los 12 meses previos.

## Medidas

- **Ventas** — `SUM(KPI Value)` sobre la ventana de período y la métrica seleccionadas.
- **Crecimiento (absoluto)** — `[Ventas período] − [Ventas período-1]`.
- **%Crecimiento** — crecimiento porcentual entre el período actual y su equivalente anterior.
- **Market Share** — _participación de mercado_ = `[Ventas compañía] / [Ventas mercado]`
  dentro de la ventana de período. El "mercado" es el universo tras aplicar los filtros.
- **BPS** — _puntos básicos_ (1 bps = 0,01 %): `(Market Share − Market Share período
  anterior) × 10 000`.
- **%Peso / %Distribución** — cuota del segmento sobre el total, por dimensión (Área de
  Negocio, Compañía, Categoría, SubCategoría, Tipo de Canal, Canal, SubCanal, Marca, Sub
  Marca, Producto, Formato, Market, Etapa).

## Dimensiones y métricas

**Categorías (anónimas):** Beverages · Snacks · Dairy · Bakery · Frozen · Condiments ·
Personal Care · Household.

**Métricas:** Volumen Kg · Valor € · Unidades · Volumen L.

**Compañía focal:** `Compañía SN` (el resto, `Compañía 01…19`, son fabricantes
competidores anonimizados).
