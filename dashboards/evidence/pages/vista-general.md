---
title: Vista General
sidebar_position: 2
---

```sql metricas
select distinct metric from marketshare.fact_full order by 1
```

```sql companias
select distinct manufacturer from marketshare.fact_full
where manufacturer is not null order by 1
```

<Dropdown data={metricas}  name=metrica  value=metric       title="Métrica"  defaultValue="Valor €" />
<Dropdown data={companias} name=compania value=manufacturer title="Compañía" defaultValue="Compañía SN" />

<ButtonGroup name=anio title="Año">
    <ButtonGroupItem valueLabel="2022" value="2022" />
    <ButtonGroupItem valueLabel="2023" value="2023" />
    <ButtonGroupItem valueLabel="2024" value="2024" defaultValue="2024" />
</ButtonGroup>

<ButtonGroup name=mes title="Mes">
    <ButtonGroupItem valueLabel="Ene" value="1" />
    <ButtonGroupItem valueLabel="Feb" value="2" />
    <ButtonGroupItem valueLabel="Mar" value="3" />
    <ButtonGroupItem valueLabel="Abr" value="4" />
    <ButtonGroupItem valueLabel="May" value="5" />
    <ButtonGroupItem valueLabel="Jun" value="6" />
    <ButtonGroupItem valueLabel="Jul" value="7" />
    <ButtonGroupItem valueLabel="Ago" value="8" />
    <ButtonGroupItem valueLabel="Sep" value="9" />
    <ButtonGroupItem valueLabel="Oct" value="10" />
    <ButtonGroupItem valueLabel="Nov" value="11" />
    <ButtonGroupItem valueLabel="Dic" value="12" defaultValue="12" />
</ButtonGroup>

<ButtonGroup name=win title="Ventana de período">
    <ButtonGroupItem valueLabel="MES" value="MES" />
    <ButtonGroupItem valueLabel="L4M" value="L4M" defaultValue="L4M" />
    <ButtonGroupItem valueLabel="YTD" value="YTD" />
    <ButtonGroupItem valueLabel="TAM" value="TAM" />
</ButtonGroup>

## KPIs — {inputs.compania.value} · {inputs.win}

```sql vg_kpis
with base as (
    select f.value, f.manufacturer,
        case
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx                             then 'cur'
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx - 1                         then 'prev'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx        then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7  and a.aidx - 4    then 'prev'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 11 and a.aidx        then 'cur'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 23 and a.aidx - 12   then 'prev'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear     and f.pidx <= a.aidx       then 'cur'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear - 1 and f.pidx <= a.aidx - 12  then 'prev'
        end as bucket
    from marketshare.fact_full f
    cross join (
        select cast('${inputs.anio}' as integer) as ayear,
               cast('${inputs.anio}' as integer) * 12
                 + cast('${inputs.mes}' as integer) as aidx
    ) a
    where f.metric = '${inputs.metrica.value}'
),
m as (
    select
        sum(value) filter (where bucket = 'cur')                                          as mkt_cur,
        sum(value) filter (where bucket = 'prev')                                         as mkt_prev,
        sum(value) filter (where bucket = 'cur'  and manufacturer = '${inputs.compania.value}') as comp_cur,
        sum(value) filter (where bucket = 'prev' and manufacturer = '${inputs.compania.value}') as comp_prev
    from base
    where bucket is not null
),
r as (
    select
        coalesce(comp_cur, 0)                                                           as comp_cur,
        case when mkt_cur  = 0 then null else comp_cur  / mkt_cur  end                 as ms_cur,
        case when mkt_prev = 0 then null else comp_prev / mkt_prev end                 as ms_prev,
        case when mkt_prev = 0 then null else mkt_cur / mkt_prev - 1 end               as pct_var,
        case when mkt_cur  is null or mkt_cur  = 0 then null
             when mkt_prev is null or mkt_prev = 0 then 0
             else (comp_cur / mkt_cur - coalesce(comp_prev, 0) / mkt_prev) * 10000
        end as bps
    from m
)
select
    comp_cur,
    -- es_escala: formato adaptativo europeo (mill./mil/unidades)
    case when abs(comp_cur) >= 1e6 then replace(printf('%.1f', comp_cur / 1e6), '.', ',') || ' mill.'
         when abs(comp_cur) >= 1e3 then replace(printf('%.1f', comp_cur / 1e3), '.', ',') || ' mil'
         else cast(cast(round(comp_cur) as bigint) as varchar)
    end as ventas_escala,
    ms_cur, ms_prev, pct_var, bps,
    replace(printf('%.1f', ms_cur * 100), '.', ',') || ' %' as ms_fmt,
    replace(printf('%.1f', pct_var * 100), '.', ',') || ' %' as pct_var_fmt,
    -- es_sig: ≥2 cifras significativas para que un BPS pequeño no salga "0"
    case when bps is null then null
         when bps = 0     then '0'
         when abs(bps) >= 10  then cast(cast(round(bps) as bigint) as varchar)
         when abs(bps) >= 1   then replace(printf('%.1f', bps), '.', ',')
         when abs(bps) >= 0.1 then replace(printf('%.2f', bps), '.', ',')
         else replace(printf('%.4f', bps), '.', ',')
    end as bps_sig
from r
```

<BigValue data={vg_kpis} value=ventas_escala title="Ventas compañía (actual)" />
<BigValue data={vg_kpis} value=ms_fmt        title="Market Share" />
<BigValue data={vg_kpis} value=pct_var_fmt   title="%Crecimiento mercado" />
<BigValue data={vg_kpis} value=bps_sig       title="BPS" />

## Incremento vs período anterior — evolución mensual

```sql vg_evol
-- Depende solo del año seleccionado (no del mes)
with mkt as (
    select month_number, month_long as mes,
        sum(value) filter (where year = cast('${inputs.anio}' as integer))     as mkt_cur,
        sum(value) filter (where year = cast('${inputs.anio}' as integer) - 1) as mkt_prev
    from marketshare.fact_full
    where metric = '${inputs.metrica.value}'
    group by 1, 2
),
comp as (
    select month_number,
        sum(value) filter (where year = cast('${inputs.anio}' as integer))     as cur,
        sum(value) filter (where year = cast('${inputs.anio}' as integer) - 1) as prev
    from marketshare.fact_full
    where metric = '${inputs.metrica.value}'
      and manufacturer = '${inputs.compania.value}'
    group by 1
)
select m.month_number, m.mes,
    coalesce(c.cur,  0) as "Año actual",
    coalesce(c.prev, 0) as "Año anterior",
    case when m.mkt_cur  = 0 or m.mkt_cur  is null then null
         else coalesce(c.cur,  0) / m.mkt_cur  end as ms_cur,
    case when m.mkt_prev = 0 or m.mkt_prev is null then null
         else coalesce(c.prev, 0) / m.mkt_prev end as ms_prev,
    case when m.mkt_cur = 0 or m.mkt_prev is null or m.mkt_prev = 0 then 0
         else (coalesce(c.cur, 0) / m.mkt_cur - coalesce(c.prev, 0) / m.mkt_prev) * 10000
    end as bps
from mkt m
left join comp c on m.month_number = c.month_number
order by m.month_number
```

<ButtonGroup name=metr_chart title="Métrica del gráfico">
    <ButtonGroupItem valueLabel="Ventas"       value="ventas" defaultValue="ventas" />
    <ButtonGroupItem valueLabel="Market Share" value="ms" />
    <ButtonGroupItem valueLabel="BPS"          value="bps" />
</ButtonGroup>

{#if inputs.metr_chart === 'bps'}
<BarChart
    data={vg_evol}
    x=mes
    y=bps
    sort=false
    colorPalette={['#002060']}
    yAxisTitle="BPS (puntos básicos)"
/>
{:else if inputs.metr_chart === 'ms'}
<BarChart
    data={vg_evol}
    x=mes
    y={['ms_cur', 'ms_prev']}
    type=grouped
    sort=false
    colorPalette={['#002060', '#00ACED']}
    yFmt="0.0%"
    yAxisTitle="Market Share"
/>
{:else}
<BarChart
    data={vg_evol}
    x=mes
    y={['Año actual', 'Año anterior']}
    type=grouped
    sort=false
    colorPalette={['#002060', '#00ACED']}
    yAxisTitle="Ventas"
/>
{/if}

## Performance del mercado — Top 7

```sql vg_rank
with base as (
    select f.value, f.manufacturer,
        case
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx                             then 'cur'
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx - 1                         then 'prev'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx        then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7  and a.aidx - 4    then 'prev'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 11 and a.aidx        then 'cur'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 23 and a.aidx - 12   then 'prev'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear     and f.pidx <= a.aidx       then 'cur'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear - 1 and f.pidx <= a.aidx - 12  then 'prev'
        end as bucket
    from marketshare.fact_full f
    cross join (
        select cast('${inputs.anio}' as integer) as ayear,
               cast('${inputs.anio}' as integer) * 12
                 + cast('${inputs.mes}' as integer) as aidx
    ) a
    where f.metric = '${inputs.metrica.value}'
),
tot as (select sum(value) filter (where bucket = 'cur') as mkt_cur from base),
agg as (
    select
        manufacturer as compania,
        sum(value) filter (where bucket = 'cur')  as ventas,
        sum(value) filter (where bucket = 'cur') - sum(value) filter (where bucket = 'prev') as crecimiento,
        case when sum(value) filter (where bucket = 'prev') = 0 then null
             else sum(value) filter (where bucket = 'cur') / sum(value) filter (where bucket = 'prev') - 1 end as pct_crec,
        sum(value) filter (where bucket = 'cur') / (select mkt_cur from tot) as market_share
    from base
    where bucket is not null
    group by 1
    having sum(value) filter (where bucket = 'cur') > 0
)
select
    compania, ventas, crecimiento, pct_crec, market_share,
    replace(printf('%,d', cast(round(ventas) as bigint)), ',', '.') as ventas_fmt,
    replace(printf('%.1f', market_share * 100), '.', ',') || ' %' as ms_fmt,
    case when crecimiento is null then '–'
         when crecimiento > 0 then '<span style="color:#2E9E5B">▲ ' || replace(printf('%,d', cast(round(crecimiento) as bigint)), ',', '.') || '</span>'
         when crecimiento < 0 then '<span style="color:#D23B3B">▼ ' || replace(printf('%,d', cast(round(abs(crecimiento)) as bigint)), ',', '.') || '</span>'
         else '<span style="color:#E8941A">– 0</span>'
    end as crec_html,
    case when pct_crec is null then '–'
         when pct_crec > 0 then '<span style="color:#2E9E5B">▲ ' || replace(printf('%.1f', pct_crec * 100), '.', ',') || ' %</span>'
         when pct_crec < 0 then '<span style="color:#D23B3B">▼ ' || replace(printf('%.1f', abs(pct_crec) * 100), '.', ',') || ' %</span>'
         else '<span style="color:#E8941A">– 0,0 %</span>'
    end as pct_crec_html
from agg
order by ventas desc
```

```sql vg_top7
with base as (
    select f.value, f.manufacturer,
        case
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx                             then 'cur'
            when '${inputs.win}' = 'MES' and f.pidx = a.aidx - 1                         then 'prev'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 3  and a.aidx        then 'cur'
            when '${inputs.win}' = 'L4M' and f.pidx between a.aidx - 7  and a.aidx - 4    then 'prev'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 11 and a.aidx        then 'cur'
            when '${inputs.win}' = 'TAM' and f.pidx between a.aidx - 23 and a.aidx - 12   then 'prev'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear     and f.pidx <= a.aidx       then 'cur'
            when '${inputs.win}' = 'YTD' and f.year = a.ayear - 1 and f.pidx <= a.aidx - 12  then 'prev'
        end as bucket
    from marketshare.fact_full f
    cross join (
        select cast('${inputs.anio}' as integer) as ayear,
               cast('${inputs.anio}' as integer) * 12
                 + cast('${inputs.mes}' as integer) as aidx
    ) a
    where f.metric = '${inputs.metrica.value}'
),
agg as (
    select
        manufacturer as compania,
        sum(value) filter (where bucket = 'cur')  as ventas,
        sum(value) filter (where bucket = 'prev') as ventas_prev
    from base
    where bucket is not null
    group by 1
    having sum(value) filter (where bucket = 'cur') > 0
)
select
    compania,
    ventas,
    ventas - coalesce(ventas_prev, 0) as crecimiento,
    case when ventas_prev is not null and ventas - ventas_prev > 0 then ventas end as "Sube",
    case when ventas_prev is not null and ventas - ventas_prev < 0 then ventas end as "Baja",
    case when ventas_prev is not null and ventas - ventas_prev = 0 then ventas end as "Sin cambio",
    case when ventas_prev is null then ventas end                                  as "Sin comparativa"
from agg
order by ventas desc
limit 7
```

<BarChart
    data={vg_top7}
    x=compania
    y={['Sube', 'Baja', 'Sin cambio', 'Sin comparativa']}
    swapXY=true
    type=stacked
    colorPalette={['#2E9E5B', '#D23B3B', '#E8941A', '#888888']}
    yAxisTitle="Ventas"
    echartsOptions={{
      tooltip: (function() {
        var lookup = {};
        vg_top7.forEach(function(row) { lookup[row.compania] = row.crecimiento; });
        function fmt(n) {
          var sign = n < 0 ? '-' : '';
          return sign + Math.round(Math.abs(n)).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
        }
        return {
          formatter: function(params) {
            if (!Array.isArray(params) || params.length === 0) return '';
            var active = null;
            for (var i = 0; i < params.length; i++) {
              var pv = params[i].value;
              var v = Array.isArray(pv) ? pv[0] : pv;
              if (typeof v === 'number' && !isNaN(v) && v > 0) {
                active = { sn: params[i].seriesName, v: v, name: params[i].name };
                break;
              }
            }
            if (!active) return '';
            var sn = active.sn;
            var color = sn === 'Sube' ? '#2E9E5B' : sn === 'Baja' ? '#D23B3B' : sn === 'Sin cambio' ? '#E8941A' : '#888888';
            var arrow = sn === 'Sube' ? '▲' : sn === 'Baja' ? '▼' : sn === 'Sin cambio' ? '–' : '○';
            var line1 = '<span style="color:' + color + ';font-weight:bold">' + fmt(active.v) + '</span>';
            if (sn === 'Sin comparativa') {
              return line1 + '<br><span style="color:#888888">○ sin comparativa</span>';
            }
            var cr = lookup[active.name];
            var line2 = (typeof cr === 'number') ? arrow + ' ' + fmt(cr) : arrow + ' ' + sn.toLowerCase();
            return line1 + '<br><span style="color:' + color + ';font-weight:bold">' + line2 + '</span>';
          }
        };
      })()
    }}
/>

<DataTable data={vg_rank} rows=10>
    <Column id=compania     title="Compañía" />
    <Column id=ventas_fmt   title="Ventas" />
    <Column id=ms_fmt       title="Market Share" />
    <Column id=crec_html    title="Crecimiento"  contentType=html />
    <Column id=pct_crec_html title="%Crecimiento" contentType=html />
</DataTable>
