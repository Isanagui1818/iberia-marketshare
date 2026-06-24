// =============================================================================
// Tabular Editor 2 (free) — bulk-create _AuxPeriod + the 87 measures in one run.
// HOW: Power BI Desktop -> External Tools -> Tabular Editor -> "C# Script" tab
//      -> paste this -> Run (F5) -> back in Tabular Editor press Ctrl+S to save
//      the changes into the Power BI model.
// Re-runnable: it skips objects that already exist.
// =============================================================================

// 1) Home table for the measures
Table mt = Model.Tables.Contains("Measure") ? Model.Tables["Measure"]
         : Model.AddCalculatedTable("Measure", "ROW(\"_\", BLANK())");

// 2) Period-type selector
if(!Model.Tables.Contains("_AuxPeriod"))
    Model.AddCalculatedTable("_AuxPeriod",
        @"DATATABLE(""Selected Period"", STRING, ""Selected Period ID"", INTEGER,
        {{""MES"",4},{""L4M"",3},{""YTD"",2},{""TAM"",1}})");

// 3) Measures
if(!mt.Measures.Contains("Fecha Último Período Cargado - Sell In")) mt.AddMeasure("Fecha Último Período Cargado - Sell In", @"
VAR UltimaFecha =
    CALCULATE(
        MAX(FACT_TABLE[Period ID]),
        DIM_CATEGORY[Source ID] = 1
    )
VAR Anio = INT(UltimaFecha / 100)
VAR Mes  = MOD(UltimaFecha, 100)
RETURN
""Último Período Cargado (Sell In): "" & FORMAT(Mes, ""00"") & ""/"" & Anio", "4. Variables Texto");
if(!mt.Measures.Contains("Fecha Último Período Cargado - Sell Out")) mt.AddMeasure("Fecha Último Período Cargado - Sell Out", @"
VAR UltimaFecha =
    CALCULATE(
        MAX(FACT_TABLE[Period ID]),
        DIM_CATEGORY[Source ID] <> 1
    )
VAR Anio = INT(UltimaFecha / 100)
VAR Mes  = MOD(UltimaFecha, 100)
RETURN
""Último Período Cargado (Sell Out): "" & FORMAT(Mes, ""00"") & ""/"" & Anio", "4. Variables Texto");
if(!mt.Measures.Contains("Ventas Globales Mes-1 Switch")) mt.AddMeasure("Ventas Globales Mes-1 Switch", @"
    SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas Mes-1],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("Market Share Período-1 Switch")) mt.AddMeasure("Market Share Período-1 Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Market Share Mes-1],
    3, [Market Share L4M-1],
    2, [Market Share YTD-1],
    1, [Market Share TAM-1]
)", "2. Market Share y %");
if(!mt.Measures.Contains("%Peso Mes")) mt.AddMeasure("%Peso Mes", @"DIVIDE([Ventas Mes], [Ventas Globales Mes Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("%Peso L4M-1")) mt.AddMeasure("%Peso L4M-1", @"DIVIDE([Ventas L4M-1], [Ventas Globales L4M-1 Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas Globales YTD-1 Switch")) mt.AddMeasure("Ventas Globales YTD-1 Switch", @"
    SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas YTD-1],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("BPS TAM")) mt.AddMeasure("BPS TAM", @"([Market Share TAM]-[Market Share TAM-1])*10000", "3. BPS");
if(!mt.Measures.Contains("Market Share L3M")) mt.AddMeasure("Market Share L3M", @"
DIVIDE(
    [Ventas L3M], CALCULATE([Ventas L3M], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas Globales L4M Switch")) mt.AddMeasure("Ventas Globales L4M Switch", @"
    SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas L4M],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("Control de Visibilidad")) mt.AddMeasure("Control de Visibilidad", @"
VAR PeriodoSeleccionado = SELECTEDVALUE('_AuxPeriod'[Selected Period])
RETURN
    IF(
        PeriodoSeleccionado = ""MES"",
        ""#1467BC"", -- Color del texto (Negro) cuando está seleccionado 'MES'
        ""#FFFFFF00"" -- Color Transparente cuando NO está seleccionado 'MES'
    )", "4. Variables Texto");
if(!mt.Measures.Contains("Ventas YTD-1")) mt.AddMeasure("Ventas YTD-1", @"
VAR UltimaFechaSeleccionada =
    MAX('dim_calendar'[date])
VAR UltimaFechaAnioAnterior =
    DATE(
        YEAR(UltimaFechaSeleccionada) - 1,
        MONTH(UltimaFechaSeleccionada),
        DAY(UltimaFechaSeleccionada)
    )
VAR InicioDeAnioAnterior =
    DATE(
        YEAR(UltimaFechaAnioAnterior),
        1,
        1
    )
VAR VentasAnioAnterior =
    CALCULATE(
        SUM(FACT_TABLE[KPI Value]),
        FILTER(
            ALL('dim_calendar'),
            'dim_calendar'[date] >= InicioDeAnioAnterior &&
            'dim_calendar'[date] <= UltimaFechaAnioAnterior
        )
    )
RETURN
    -- COALESCE devuelve el primer valor que no es BLANK. 
    -- Si VentasAnioAnterior es BLANK, devuelve 0.
    COALESCE(VentasAnioAnterior, 0)", "1. Ventas");
if(!mt.Measures.Contains("Market Share L4M-1")) mt.AddMeasure("Market Share L4M-1", @"
DIVIDE(
    [Ventas L4M-1], CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("BPS L3M LY")) mt.AddMeasure("BPS L3M LY", @"([Market Share L3M]-[Market Share L3M LY])*10000", "3. BPS");
if(!mt.Measures.Contains("BPS L4M")) mt.AddMeasure("BPS L4M", @"([Market Share L4M]-[Market Share L4M-1])*10000", "3. BPS");
if(!mt.Measures.Contains("Ventas TAM")) mt.AddMeasure("Ventas TAM", @"
VAR UltimaFechaSeleccionada =
    MAX('dim_calendar'[date])
VAR FechaDeInicio =
    EDATE(UltimaFechaSeleccionada, -12) + 1
RETURN
    CALCULATE(
        SUM(FACT_TABLE[KPI Value]),
        REMOVEFILTERS('dim_calendar'),
        'dim_calendar'[date] >= FechaDeInicio && 'dim_calendar'[date] <= UltimaFechaSeleccionada
    )", "1. Ventas");
if(!mt.Measures.Contains("%Peso TAM-1")) mt.AddMeasure("%Peso TAM-1", @"DIVIDE([Ventas TAM-1], [Ventas Globales TAM-1 Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("Crecimiento Ventas Períodos LY Switch")) mt.AddMeasure("Crecimiento Ventas Períodos LY Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Crecimiento Mes LY],
    3, [Crecimiento L4M],
    2, [Crecimiento YTD],
    1, [Crecimiento TAM]
)", "1. Ventas");
if(!mt.Measures.Contains("Ventas Globales TAM Switch")) mt.AddMeasure("Ventas Globales TAM Switch", @"
    SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas TAM],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("Market Share Y-1 Switch")) mt.AddMeasure("Market Share Y-1 Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Market Share Mes LY],
    3, [Market Share L4M-1],
    2, [Market Share YTD-1],
    1, [Market Share TAM-1]
)", "2. Market Share y %");
if(!mt.Measures.Contains("BPS Período LY Switch")) mt.AddMeasure("BPS Período LY Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [BPS Mes LY],
    3, [BPS L4M],
    2, [BPS YTD],
    1, [BPS TAM]
)", "3. BPS");
if(!mt.Measures.Contains("Selección Fecha")) mt.AddMeasure("Selección Fecha", @"
MAX('DIM_CALENDAR'[DATE])", "4. Variables Texto");
if(!mt.Measures.Contains("%Peso Mes-1")) mt.AddMeasure("%Peso Mes-1", @"DIVIDE([Ventas Mes-1], [Ventas Globales Mes-1 Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas L6M")) mt.AddMeasure("Ventas L6M", @"
VAR MesSeleccionado = 
    MAX('DIM_CALENDAR'[Date])
VAR FechaDeInicio = 
    DATE(
        YEAR(MesSeleccionado),
        MONTH(MesSeleccionado) - 5,
        1
    )
RETURN
    CALCULATE(
        sum('FACT_TABLE'[KPI Value]),
        REMOVEFILTERS('DIM_CALENDAR'),
        'DIM_CALENDAR'[Date] >= FechaDeInicio &&
        'DIM_CALENDAR'[Date] <= MesSeleccionado
    )", "1. Ventas");
if(!mt.Measures.Contains("Market Share Mes-1")) mt.AddMeasure("Market Share Mes-1", @"
DIVIDE(
    [Ventas Mes-1], CALCULATE([Ventas Mes-1], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("BPS Período L3M LY Switch")) mt.AddMeasure("BPS Período L3M LY Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [BPS Mes LY],
    3, [BPS L3M LY],
    2, [BPS YTD],
    1, [BPS TAM]
)", "3. BPS");
if(!mt.Measures.Contains("BPS YTD")) mt.AddMeasure("BPS YTD", @"([Market Share YTD]-[Market Share YTD-1])*10000", "3. BPS");
if(!mt.Measures.Contains("Ventas Globales TAM-1 Switch")) mt.AddMeasure("Ventas Globales TAM-1 Switch", @"
   SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas TAM-1],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("Ventas TAM-1")) mt.AddMeasure("Ventas TAM-1", @"
VAR MesSeleccionado = 
    MAX('DIM_CALENDAR'[Date])
VAR FechaDeInicioL4M = 
    DATE(
        YEAR(MesSeleccionado),
        MONTH(MesSeleccionado) - 11,
        1
    )
VAR FechaFinAnterior =
    DATE(
        YEAR(FechaDeInicioL4M),
        MONTH(FechaDeInicioL4M),
        DAY(FechaDeInicioL4M)
    ) - 1 // Restamos 1 día para obtener el día anterior al inicio de L4M
VAR FechaInicioAnterior =
    DATE(
        YEAR(FechaFinAnterior),
        MONTH(FechaFinAnterior) - 11,
        1
    )
RETURN
    CALCULATE(
        sum('FACT_TABLE'[KPI Value]),
        REMOVEFILTERS('DIM_CALENDAR'),
        'DIM_CALENDAR'[Date] >= FechaInicioAnterior &&
        'DIM_CALENDAR'[Date] <= FechaFinAnterior
    )", "1. Ventas");
if(!mt.Measures.Contains("%Crecimiento YTD")) mt.AddMeasure("%Crecimiento YTD", @"
IF(
    -- 1. Condición: Si las Ventas Acumuladas del Año Anterior son 0 o BLANK
    ISBLANK([Ventas YTD-1]) || [Ventas YTD-1] = 0,
    
    -- 2. Resultado si la condición se cumple: Devuelve 0%
    0, 
    
    -- 3. Resultado si la condición NO se cumple: Ejecuta la fórmula de crecimiento normal
    DIVIDE([Ventas YTD], [Ventas YTD-1]) - 1
)", "2. Market Share y %");
if(!mt.Measures.Contains("Market Share Mes LY")) mt.AddMeasure("Market Share Mes LY", @"DIVIDE([Ventas Mes LY], CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas L6M-1")) mt.AddMeasure("Ventas L6M-1", @"
VAR MesSeleccionado = 
    MAX('DIM_CALENDAR'[Date])
VAR FechaFinAnterior =
    DATE(
        YEAR(MesSeleccionado),
        MONTH(MesSeleccionado) - 6,
        DAY(MesSeleccionado)
    )
VAR FechaInicioAnterior =
    DATE(
        YEAR(FechaFinAnterior),
        MONTH(FechaFinAnterior) - 5,
        1
    )
VAR VentasCalculadas =
    CALCULATE(
        SUM('FACT_TABLE'[KPI Value]),
        REMOVEFILTERS('DIM_CALENDAR'),
        'DIM_CALENDAR'[Date] >= FechaInicioAnterior &&
        'DIM_CALENDAR'[Date] <= FechaFinAnterior
    )
RETURN
    -- Si el resultado es BLANK, devuelve 0; de lo contrario, devuelve el resultado.
    COALESCE(VentasCalculadas, 0)", "1. Ventas");
if(!mt.Measures.Contains("Ventas Globales YTD Switch")) mt.AddMeasure("Ventas Globales YTD Switch", @"
    SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas YTD],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("Ventas Mes-1")) mt.AddMeasure("Ventas Mes-1", @"
VAR UltimoDiaSeleccionado = 
    MAX('dim_calendar'[date])
VAR MesAnterior = 
    EDATE(UltimoDiaSeleccionado, -1)
VAR PrimerDiaMesAnterior = 
    EOMONTH(MesAnterior, -1) + 1
VAR UltimoDiaMesAnterior = 
    EOMONTH(MesAnterior, 0)
RETURN
    CALCULATE(
        [Ventas],
        -- Elimina todos los filtros de la tabla calendario para aplicar el nuevo rango.
        -- Esto es crucial cuando se usa MAX('dim_calendar'[date]) en las variables.
        REMOVEFILTERS('dim_calendar'), 
        'dim_calendar'[date] >= PrimerDiaMesAnterior,
        'dim_calendar'[date] <= UltimoDiaMesAnterior
    )", "1. Ventas");
if(!mt.Measures.Contains("%Crecimiento Período LY Switch")) mt.AddMeasure("%Crecimiento Período LY Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [%Crecimiento Mes LY],
    3, [%Crecimiento L4M],
    2, [%Crecimiento YTD],
    1, [%Crecimiento TAM]
)", "2. Market Share y %");
if(!mt.Measures.Contains("Fecha L6M-1")) mt.AddMeasure("Fecha L6M-1", @"
VAR FechaFin = [Selección Fecha]
VAR PeriodoAnteriorFechaFin = EOMONTH(FechaFin, -6)
VAR PeriodoAnteriorFechaInicio = EOMONTH(FechaFin, -12) + 1
RETURN
""Ventas: "" & FORMAT(PeriodoAnteriorFechaInicio, ""mm/yyyy"") & "" - "" & FORMAT(PeriodoAnteriorFechaFin, ""mm/yyyy"")", "4. Variables Texto");
if(!mt.Measures.Contains("%Peso YTD")) mt.AddMeasure("%Peso YTD", @"DIVIDE([Ventas YTD], [Ventas Globales YTD Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("BPS Mes LY")) mt.AddMeasure("BPS Mes LY", @"([Market Share Mes] - [Market Share Mes LY])*10000", "3. BPS");
if(!mt.Measures.Contains("Ventas Periodos-1 Switch")) mt.AddMeasure("Ventas Periodos-1 Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Ventas Mes-1],
    3, [Ventas L4M-1],
    2, [Ventas YTD-1],
    1, [Ventas TAM-1]
)", "1. Ventas");
if(!mt.Measures.Contains("BPS Mes")) mt.AddMeasure("BPS Mes", @"([Market Share Mes] - [Market Share Mes-1])*10000", "3. BPS");
if(!mt.Measures.Contains("Ventas L4M-1")) mt.AddMeasure("Ventas L4M-1", @"
VAR MesSeleccionado = 
    MAX('DIM_CALENDAR'[Date])
VAR FechaDeInicioL4M = 
    DATE(
        YEAR(MesSeleccionado),
        MONTH(MesSeleccionado) - 3,
        1
    )
VAR FechaFinAnterior =
    DATE(
        YEAR(FechaDeInicioL4M),
        MONTH(FechaDeInicioL4M),
        DAY(FechaDeInicioL4M)
    ) - 1
VAR FechaInicioAnterior =
    DATE(
        YEAR(FechaFinAnterior),
        MONTH(FechaFinAnterior) - 3,
        1
    )
VAR Resultado = 
    CALCULATE(
        SUM('FACT_TABLE'[KPI Value]),
        REMOVEFILTERS('DIM_CALENDAR'),
        'DIM_CALENDAR'[Date] >= FechaInicioAnterior &&
        'DIM_CALENDAR'[Date] <= FechaFinAnterior
    )
RETURN
    // COALESCE devuelve el primer valor que no sea BLANK. 
    // Si Resultado es BLANK, devuelve 0.
    COALESCE(Resultado, 0)", "1. Ventas");
if(!mt.Measures.Contains("Ventas")) mt.AddMeasure("Ventas", @"SUM('FACT_TABLE'[KPI Value])", "1. Ventas");
if(!mt.Measures.Contains("Ventas YTD")) mt.AddMeasure("Ventas YTD", @"
VAR UltimaFechaSeleccionada = MAX('dim_calendar'[date])
VAR InicioDeAnio = DATE(YEAR(UltimaFechaSeleccionada), 1, 1)
VAR CalculoVentas =
    CALCULATE(
        SUM(FACT_TABLE[KPI Value]),
        REMOVEFILTERS('dim_calendar'), 
        'dim_calendar'[date] >= InicioDeAnio && 'dim_calendar'[date] <= UltimaFechaSeleccionada
    )
RETURN
    -- Si el resultado de CalculoVentas es BLANK (no hay datos), COALESCE devuelve 0.
    COALESCE(CalculoVentas, 0)", "1. Ventas");
if(!mt.Measures.Contains("%Crecimiento L3M")) mt.AddMeasure("%Crecimiento L3M", @"
IF(
    -- 1. Condición: Si el denominador es 0 o BLANK (no hay ventas el año anterior)
    ISBLANK([Ventas L3M LY]) || [Ventas L3M LY] = 0, 
    0, 
    -- 2. Resultado si la condición NO se cumple: Aplica tu cálculo original
    DIVIDE([Ventas L3M], [Ventas L3M LY], 0) - 1 
)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas L4M")) mt.AddMeasure("Ventas L4M", @"
VAR MesSeleccionado = 
    MAX('DIM_CALENDAR'[Date])
VAR FechaDeInicio = 
    DATE(
        YEAR(MesSeleccionado),
        MONTH(MesSeleccionado) - 3,
        1
    )
VAR Resultado =
    CALCULATE(
        SUM('FACT_TABLE'[KPI Value]),
        // 💡 Ignora filtros de fecha externos para forzar el rango de 4 meses
        REMOVEFILTERS('DIM_CALENDAR'), 
        // Aplica el rango fijo de 4 meses
        'DIM_CALENDAR'[Date] >= FechaDeInicio &&
        'DIM_CALENDAR'[Date] <= MesSeleccionado
    )
RETURN
    // 💡 Devuelve 0 si el resultado es BLANK (por falta de datos)
    COALESCE(Resultado, 0)", "1. Ventas");
if(!mt.Measures.Contains("Market Share TAM")) mt.AddMeasure("Market Share TAM", @"DIVIDE([Ventas TAM], CALCULATE([Ventas TAM], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("Market Share YTD")) mt.AddMeasure("Market Share YTD", @"DIVIDE([Ventas YTD], CALCULATE([Ventas YTD], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas L3M LY")) mt.AddMeasure("Ventas L3M LY", @"
VAR MesSeleccionado =
    MAX('DIM_CALENDAR'[Date])

-- ⬅️ Retrocede 12 meses exactos desde la fecha seleccionada
VAR MesSeleccionadoLY =
    EDATE(MesSeleccionado, -12)

-- ⬅️ FECHA DE FIN del periodo LY (igual día que el seleccionado pero 12 meses atrás)
VAR FinPeriodoLY =
    MesSeleccionadoLY

-- ⬅️ FECHA DE INICIO del periodo LY = primer día del mes que está 2 meses antes que FinPeriodoLY
VAR InicioPeriodoLY =
    DATE(
        YEAR(FinPeriodoLY),
        MONTH(FinPeriodoLY) - 2,
        1
    )

RETURN
    CALCULATE(
        SUM('FACT_TABLE'[KPI Value]),
        -- Ignora cualquier filtro existente (igual que tu medida original)
        REMOVEFILTERS('DIM_CALENDAR'),
        -- Aplica el rango de los mismos 3 meses pero un año atrás
        'DIM_CALENDAR'[Date] >= InicioPeriodoLY,
        'DIM_CALENDAR'[Date] <= FinPeriodoLY
    )", "1. Ventas");
if(!mt.Measures.Contains("%Crecimiento Mes LY")) mt.AddMeasure("%Crecimiento Mes LY", @"
IF(
    -- 1. Condición: Si las ventas del Mes Anterior son 0 o BLANK (denominador cero)
    ISBLANK([Ventas Mes LY]) || [Ventas Mes LY] = 0,
    
    -- 2. Resultado si la condición se cumple: Devuelve 0%
    0, 
    
    -- 3. Resultado si la condición NO se cumple: Aplica el cálculo de crecimiento normal
    DIVIDE([Ventas Mes], [Ventas Mes LY]) - 1
)", "2. Market Share y %");
if(!mt.Measures.Contains("%Crecimiento Período L3M LY Switch")) mt.AddMeasure("%Crecimiento Período L3M LY Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [%Crecimiento Mes LY],
    3, [%Crecimiento L3M],
    2, [%Crecimiento YTD],
    1, [%Crecimiento TAM]
)", "2. Market Share y %");
if(!mt.Measures.Contains("Market Share Período L3M Switch")) mt.AddMeasure("Market Share Período L3M Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Market Share Mes],
    3, [Market Share L3M],
    2, [Market Share YTD],
    1, [Market Share TAM]
)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas Globales L4M-1 Switch")) mt.AddMeasure("Ventas Globales L4M-1 Switch", @"
    SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas L4M-1],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas L4M-1], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("Ventas Mes")) mt.AddMeasure("Ventas Mes", @"
CALCULATE(
    [Ventas],
    DIM_CALENDAR[Year] = YEAR(MAX(DIM_CALENDAR[Date])),
    DIM_CALENDAR[Month Number] = MONTH(MAX(DIM_CALENDAR[Date]))
)", "1. Ventas");
if(!mt.Measures.Contains("Ventas Y-1 Switch")) mt.AddMeasure("Ventas Y-1 Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Ventas Mes LY],
    3, [Ventas L4M-1],
    2, [Ventas YTD-1],
    1, [Ventas TAM-1]
)", "1. Ventas");
if(!mt.Measures.Contains("Período de Comparación")) mt.AddMeasure("Período de Comparación", @"
VAR PeriodoSeleccionado = SELECTEDVALUE('_AuxPeriod'[Selected Period])
RETURN
    IF(
        PeriodoSeleccionado = ""MES"",
        ""Período Mes vs Mes LY"",
        BLANK()
    )", "4. Variables Texto");
if(!mt.Measures.Contains("Market Share L4M")) mt.AddMeasure("Market Share L4M", @"
DIVIDE(
    [Ventas L4M], CALCULATE([Ventas L4M], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("Crecimiento Mes")) mt.AddMeasure("Crecimiento Mes", @"CALCULATE([Ventas Mes] - [Ventas Mes-1])", "1. Ventas");
if(!mt.Measures.Contains("%Peso YTD-1")) mt.AddMeasure("%Peso YTD-1", @"DIVIDE([Ventas YTD-1], [Ventas Globales YTD-1 Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("%Peso TAM")) mt.AddMeasure("%Peso TAM", @"DIVIDE([Ventas TAM], [Ventas Globales TAM Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("Market Share")) mt.AddMeasure("Market Share", @"
DIVIDE(
    [Ventas], CALCULATE([Ventas], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("%Peso L4M")) mt.AddMeasure("%Peso L4M", @"DIVIDE([Ventas L4M], [Ventas Globales L4M Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("Texto Segmento Categoría")) mt.AddMeasure("Texto Segmento Categoría", @"
VAR TEXTO = SELECTEDVALUE(DIM_PROD[Category])

RETURN
IF(ISBLANK(TEXTO), ""SELECCIÓN MULTIPLE"", TEXTO)", "4. Variables Texto");
if(!mt.Measures.Contains("BPS Período Switch")) mt.AddMeasure("BPS Período Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [BPS Mes],
    3, [BPS L4M],
    2, [BPS YTD],
    1, [BPS TAM]
)", "3. BPS");
if(!mt.Measures.Contains("Crecimiento Mes LY")) mt.AddMeasure("Crecimiento Mes LY", @"CALCULATE([Ventas Mes]-[Ventas Mes LY])", "1. Ventas");
if(!mt.Measures.Contains("Crecimiento TAM")) mt.AddMeasure("Crecimiento TAM", @"CALCULATE([Ventas TAM] - [Ventas TAM-1])", "1. Ventas");
if(!mt.Measures.Contains("%Peso Mes LY")) mt.AddMeasure("%Peso Mes LY", @"DIVIDE([Ventas Mes LY], [Ventas Globales Mes LY Switch],0)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas Globales Mes LY Switch")) mt.AddMeasure("Ventas Globales Mes LY Switch", @"
    SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas Mes LY],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas Mes LY], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("%Crecimiento L4M")) mt.AddMeasure("%Crecimiento L4M", @"
IF(
    -- 1. Condición: Si el denominador es 0 o BLANK (no hay ventas el año anterior)
    ISBLANK([Ventas L4M-1]) || [Ventas L4M-1] = 0, 
    0, 
    -- 2. Resultado si la condición NO se cumple: Aplica tu cálculo original
    DIVIDE([Ventas L4M], [Ventas L4M-1], 0) - 1 
)", "2. Market Share y %");
if(!mt.Measures.Contains("%Crecimiento Período Switch")) mt.AddMeasure("%Crecimiento Período Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [%Crecimiento Mes],
    3, [%Crecimiento L4M],
    2, [%Crecimiento YTD],
    1, [%Crecimiento TAM]
)", "2. Market Share y %");
if(!mt.Measures.Contains("Crecimiento L4M")) mt.AddMeasure("Crecimiento L4M", @"CALCULATE([Ventas L4M] - [Ventas L4M-1])", "1. Ventas");
if(!mt.Measures.Contains("Crecimiento YTD")) mt.AddMeasure("Crecimiento YTD", @"CALCULATE([Ventas YTD]-[Ventas YTD-1])", "1. Ventas");
if(!mt.Measures.Contains("Market Share L3M LY")) mt.AddMeasure("Market Share L3M LY", @"
DIVIDE(
    [Ventas L3M LY], CALCULATE([Ventas L3M LY], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("%Crecimiento Mes")) mt.AddMeasure("%Crecimiento Mes", @"
IF(
    -- 1. Condición: Si las ventas del Mes Anterior son 0 o BLANK (denominador cero)
    ISBLANK([Ventas Mes-1]) || [Ventas Mes-1] = 0,
    
    -- 2. Resultado si la condición se cumple: Devuelve 0%
    0, 
    
    -- 3. Resultado si la condición NO se cumple: Aplica el cálculo de crecimiento normal
    DIVIDE([Ventas Mes], [Ventas Mes-1]) - 1
)", "2. Market Share y %");
if(!mt.Measures.Contains("Market Share YTD-1")) mt.AddMeasure("Market Share YTD-1", @"
DIVIDE(
    [Ventas YTD-1], CALCULATE([Ventas YTD-1], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("Crecimiento L6M")) mt.AddMeasure("Crecimiento L6M", @"CALCULATE([Ventas L6M] - [Ventas L6M-1])", "1. Ventas");
if(!mt.Measures.Contains("Market Share Mes")) mt.AddMeasure("Market Share Mes", @"DIVIDE([Ventas Mes], CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("%Crecimiento L6M")) mt.AddMeasure("%Crecimiento L6M", @"
VAR VentasUltimos6Meses = COALESCE([Ventas L6M], 0)
VAR VentasPeriodoAnterior = COALESCE([Ventas L6M-1], 0)
VAR Crecimiento = 
    DIVIDE(
        VentasUltimos6Meses - VentasPeriodoAnterior,
        VentasPeriodoAnterior,
        -- Resultado alternativo si el denominador (VentasPeriodoAnterior) es 0 o BLANK.
        -- Si ambas ventas son 0, el resultado es 0. Si las ventas anteriores son 0 y las actuales son > 0, dará INF. Aquí devolvemos BLANK para que la lógica de COALESCE lo convierta a 0.
        BLANK()
    )
RETURN
    -- Asegura que el resultado final sea 0 si Crecimiento es BLANK (por ejemplo, si VentasUltimos6Meses y VentasPeriodoAnterior son 0)
    COALESCE(Crecimiento, 0)", "2. Market Share y %");
if(!mt.Measures.Contains("Fecha L6M")) mt.AddMeasure("Fecha L6M", @"
VAR FechaFin = [Selección Fecha]
VAR FechaInicio = EOMONTH(FechaFin, -6) + 1
RETURN
""Ventas: "" & FORMAT(FechaInicio, ""mm/yyyy"") & "" - "" & FORMAT(FechaFin, ""mm/yyyy"")", "4. Variables Texto");
if(!mt.Measures.Contains("Ventas Períodos Switch")) mt.AddMeasure("Ventas Períodos Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Ventas Mes],
    3, [Ventas L4M],
    2, [Ventas YTD],
    1, [Ventas TAM]
)", "1. Ventas");
if(!mt.Measures.Contains("Ventas L3M")) mt.AddMeasure("Ventas L3M", @"
VAR MesSeleccionado = 
    MAX('DIM_CALENDAR'[Date])
VAR FechaDeInicio = 
    DATE(
        YEAR(MesSeleccionado),
        MONTH(MesSeleccionado) - 2,
        1
    )
VAR Resultado =
    CALCULATE(
        SUM('FACT_TABLE'[KPI Value]),
        // 💡 Ignora filtros de fecha externos para forzar el rango de 4 meses
        REMOVEFILTERS('DIM_CALENDAR'), 
        // Aplica el rango fijo de 4 meses
        'DIM_CALENDAR'[Date] >= FechaDeInicio &&
        'DIM_CALENDAR'[Date] <= MesSeleccionado
    )
RETURN
    // 💡 Devuelve 0 si el resultado es BLANK (por falta de datos)
    COALESCE(Resultado, 0)", "1. Ventas");
if(!mt.Measures.Contains("Ventas Globales Mes Switch")) mt.AddMeasure("Ventas Globales Mes Switch", @"
    SWITCH(MAX(ParameterField[ParameterField]),
        ""Área de Negocio"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Business Area])),
        ""Compañía"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Manufacturer])),
        ""Categoría"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Category])),
        ""SubCategoría"", CALCULATE([Ventas Mes],REMOVEFILTERS(DIM_PROD[Sub Category])),
        ""Entorno"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_CHANNEL[Type Channel])),
        ""Canal"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_CHANNEL[Channel])),
        ""SubCanal"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_CHANNEL[SubChannel])),
        ""Marca"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Brand])),
        ""Sub Marca"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Sub Brand])),
        ""Producto"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Product])),
        ""Product Pack"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Product Pack])),
        ""Formato"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Format])),
        ""Market"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Market])),
        ""Etapa"", CALCULATE([Ventas Mes], REMOVEFILTERS(DIM_PROD[Etapas]))
          )", "1. Ventas");
if(!mt.Measures.Contains("%Crecimiento TAM")) mt.AddMeasure("%Crecimiento TAM", @"
IF(
    -- 1. Condición: Si las Ventas del Periodo Base (TAM-1) son 0 o BLANK
    ISBLANK([Ventas TAM-1]) || [Ventas TAM-1] = 0,
    
    -- 2. Resultado si la condición se cumple: Devuelve 0% (evita el -100%)
    0, 
    
    -- 3. Resultado si la condición NO se cumple: Ejecuta la fórmula de crecimiento normal
    DIVIDE([Ventas TAM], [Ventas TAM-1]) - 1
)", "2. Market Share y %");
if(!mt.Measures.Contains("Market Share TAM-1")) mt.AddMeasure("Market Share TAM-1", @"
DIVIDE(
    [Ventas TAM-1], CALCULATE([Ventas TAM-1], REMOVEFILTERS(DIM_PROD[Manufacturer])),0)", "2. Market Share y %");
if(!mt.Measures.Contains("Ventas Mes LY")) mt.AddMeasure("Ventas Mes LY", @"
VAR UltimoDiaSeleccionado = 
    MAX('dim_calendar'[date]) 
VAR MesMismoAnyoAnterior = 
    -- Retrocede 12 meses exactos a partir del último día seleccionado
    EDATE(UltimoDiaSeleccionado, -12)
VAR PrimerDiaMismoMesAnyoAnterior = 
    -- Encuentra el primer día del mes de 'MesMismoAñoAnterior'
    EOMONTH(MesMismoAnyoAnterior, -1) + 1
VAR UltimoDiaMismoMesAnyoAnterior = 
    -- Encuentra el último día del mes de 'MesMismoAñoAnterior'
    EOMONTH(MesMismoAnyoAnterior, 0)
RETURN
    CALCULATE(
        [Ventas],
        -- Crucial para ignorar el contexto de filtro actual y forzar el nuevo rango
        REMOVEFILTERS('dim_calendar'), 
        'dim_calendar'[date] >= PrimerDiaMismoMesAnyoAnterior,
        'dim_calendar'[date] <= UltimoDiaMismoMesAnyoAnterior
    )", "1. Ventas");
if(!mt.Measures.Contains("Fecha Último Período Cargado")) mt.AddMeasure("Fecha Último Período Cargado", @"
VAR UltimaFecha = MAX(DIM_CALENDAR[Date])
RETURN
""Último Período Cargado: "" & FORMAT(UltimaFecha, ""MM/YYYY"")", "4. Variables Texto");
if(!mt.Measures.Contains("Crecimiento Ventas Períodos Switch")) mt.AddMeasure("Crecimiento Ventas Períodos Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Crecimiento Mes],
    3, [Crecimiento L4M],
    2, [Crecimiento YTD],
    1, [Crecimiento TAM]
)", "1. Ventas");
if(!mt.Measures.Contains("Market Share Período Switch")) mt.AddMeasure("Market Share Período Switch", @"
SWITCH (
    SUM ( _AuxPeriod[Selected Period ID] ),
    4, [Market Share Mes],
    3, [Market Share L4M],
    2, [Market Share YTD],
    1, [Market Share TAM]
)", "2. Market Share y %");

Info("Hecho: _AuxPeriod + " + mt.Measures.Count + " medidas. Pulsa Ctrl+S para guardar en Power BI.");