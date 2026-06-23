const path = "C:/node/node_modules/docx";
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        Header, Footer, AlignmentType, LevelFormat, TableOfContents, HeadingLevel,
        BorderStyle, WidthType, ShadingType, VerticalAlign, PageNumber, PageBreak } = require(path);
const fs = require("fs");

// ---------- helpers ----------
const NAVY = "1F3864", BLUE = "2E75B6", LIGHT = "D9E2F3", GREEN = "C6EFCE",
      RED = "FFC7CE", YELLOW = "FFEB9C", GREY = "F2F2F2", WHITE = "FFFFFF";
const CW = 9360; // content width letter, 1" margins

const border = { style: BorderStyle.SINGLE, size: 1, color: "BFBFBF" };
const borders = { top: border, bottom: border, left: border, right: border,
                  insideHorizontal: border, insideVertical: border };
const cellMargins = { top: 60, bottom: 60, left: 110, right: 110 };

function cell(text, { w, fill, bold, color, align, size } = {}) {
  return new TableCell({
    borders, width: { size: w, type: WidthType.DXA },
    shading: fill ? { fill, type: ShadingType.CLEAR } : undefined,
    margins: cellMargins, verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: align || AlignmentType.LEFT,
      children: [new TextRun({ text: String(text), bold: !!bold,
        color: color || "000000", size: size || 19, font: "Arial" })]
    })]
  });
}
function headRow(cells, widths) {
  return new TableRow({ tableHeader: true, children:
    cells.map((c, i) => cell(c, { w: widths[i], fill: NAVY, bold: true, color: WHITE, align: AlignmentType.CENTER })) });
}
function row(cells, widths, opts = []) {
  return new TableRow({ children:
    cells.map((c, i) => cell(c, { w: widths[i], align: opts[i]?.align, fill: opts[i]?.fill, bold: opts[i]?.bold })) });
}
function table(widths, header, rows) {
  return new Table({ width: { size: CW, type: WidthType.DXA }, columnWidths: widths,
    rows: [headRow(header, widths), ...rows] });
}
const P = (text, opts = {}) => new Paragraph({
  spacing: { after: opts.after ?? 120, before: opts.before ?? 0 },
  alignment: opts.align, children: [new TextRun({ text, bold: opts.bold, italics: opts.italics,
    color: opts.color || "000000", size: opts.size || 22, font: "Arial" })] });
const H1 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(t)] });
const H2 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(t)] });
const bullet = (t, lvl = 0) => new Paragraph({ numbering: { reference: "b", level: lvl },
  spacing: { after: 60 }, children: parseRuns(t) });
const numItem = (t) => new Paragraph({ numbering: { reference: "n", level: 0 },
  spacing: { after: 80 }, children: parseRuns(t) });
// parse **bold** markers
function parseRuns(t) {
  const parts = String(t).split(/(\*\*[^*]+\*\*)/g).filter(Boolean);
  return parts.map(p => p.startsWith("**")
    ? new TextRun({ text: p.slice(2, -2), bold: true, size: 22, font: "Arial" })
    : new TextRun({ text: p, size: 22, font: "Arial" }));
}

// ---------- document ----------
const doc = new Document({
  creator: "Equipo Automatización QA - Konecta",
  title: "Informe de Ejecución de Pruebas Automatizadas SARA",
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 30, bold: true, color: NAVY, font: "Arial" },
        paragraph: { spacing: { before: 320, after: 160 }, outlineLevel: 0,
          border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE, space: 4 } } } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 25, bold: true, color: BLUE, font: "Arial" },
        paragraph: { spacing: { before: 220, after: 120 }, outlineLevel: 1 } },
    ]
  },
  numbering: { config: [
    { reference: "b", levels: [
      { level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 540, hanging: 280 } } } },
      { level: 1, format: LevelFormat.BULLET, text: "◦", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 1080, hanging: 280 } } } } ] },
    { reference: "n", levels: [
      { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 540, hanging: 280 } } } } ] },
  ] },
  sections: [{
    properties: { page: { size: { width: 12240, height: 15840 },
      margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    headers: { default: new Header({ children: [ new Paragraph({
      alignment: AlignmentType.RIGHT, spacing: { after: 0 },
      border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: BLUE, space: 2 } },
      children: [ new TextRun({ text: "Konecta  |  Automatización QA – Proyecto SARA",
        color: "808080", size: 16, font: "Arial" }) ] }) ] }) },
    footers: { default: new Footer({ children: [ new Paragraph({
      alignment: AlignmentType.CENTER,
      border: { top: { style: BorderStyle.SINGLE, size: 4, color: BLUE, space: 2 } },
      children: [
        new TextRun({ text: "Informe confidencial – Uso interno   |   Página ", color: "808080", size: 16, font: "Arial" }),
        new TextRun({ children: [PageNumber.CURRENT], color: "808080", size: 16, font: "Arial" }),
        new TextRun({ text: " de ", color: "808080", size: 16, font: "Arial" }),
        new TextRun({ children: [PageNumber.TOTAL_PAGES], color: "808080", size: 16, font: "Arial" }) ] }) ] }) },
    children: buildBody()
  }]
});

function buildBody() {
  const c = [];
  // ===== PORTADA =====
  c.push(new Paragraph({ spacing: { before: 2200, after: 0 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "INFORME DE EJECUCIÓN", bold: true, size: 56, color: NAVY, font: "Arial" })] }));
  c.push(new Paragraph({ spacing: { after: 120 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Pruebas Automatizadas – Plataforma SARA", bold: true, size: 40, color: BLUE, font: "Arial" })] }));
  c.push(new Paragraph({ spacing: { after: 600 }, alignment: AlignmentType.CENTER,
    border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: BLUE, space: 8 } }, children: [] }));
  c.push(new Paragraph({ spacing: { after: 80 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Ejecución paralela multi-máquina", size: 26, color: "595959", font: "Arial" })] }));
  c.push(new Paragraph({ spacing: { after: 80 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Fecha de consolidación: 19 de junio de 2026, 16:18", size: 24, color: "595959", font: "Arial" })] }));
  c.push(new Paragraph({ spacing: { after: 600 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Equipo de Automatización QA – Konecta", size: 24, color: "595959", font: "Arial" })] }));
  // tarjeta KPI portada
  c.push(new Table({ width: { size: 7000, type: WidthType.DXA }, alignment: AlignmentType.CENTER,
    columnWidths: [3500, 3500],
    rows: [
      new TableRow({ children: [
        cell("Tasa de Éxito Global", { w: 3500, fill: NAVY, bold: true, color: WHITE, align: AlignmentType.CENTER }),
        cell("Tests Ejecutados", { w: 3500, fill: NAVY, bold: true, color: WHITE, align: AlignmentType.CENTER }) ] }),
      new TableRow({ children: [
        new TableCell({ borders, width: { size: 3500, type: WidthType.DXA }, margins: cellMargins, shading: { fill: GREEN, type: ShadingType.CLEAR },
          children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "90.82 %", bold: true, size: 48, color: "1E7145", font: "Arial" })] })] }),
        new TableCell({ borders, width: { size: 3500, type: WidthType.DXA }, margins: cellMargins, shading: { fill: LIGHT, type: ShadingType.CLEAR },
          children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "1,176", bold: true, size: 48, color: NAVY, font: "Arial" })] })] }) ] }),
    ] }));
  c.push(new Paragraph({ children: [new PageBreak()] }));

  // ===== TOC =====
  c.push(new Paragraph({ spacing: { after: 160 }, children: [new TextRun({ text: "Tabla de Contenido", bold: true, size: 30, color: NAVY, font: "Arial" })] }));
  c.push(new TableOfContents("Tabla de Contenido", { hyperlink: true, headingStyleRange: "1-2" }));
  c.push(new Paragraph({ children: [new PageBreak()] }));

  // ===== 1. RESUMEN EJECUTIVO =====
  c.push(H1("1. Resumen Ejecutivo"));
  c.push(P("El presente informe consolida los resultados de la ejecución masiva de pruebas automatizadas sobre la plataforma SARA, realizada el 19 de junio de 2026. La suite fue ejecutada en paralelo sobre 23 máquinas simultáneas, lo que permitió validar 1,176 escenarios de negocio en un único ciclo de pruebas.", { after: 160 }));
  c.push(P("El resultado global fue una tasa de éxito del 90.82 %, con 1,068 pruebas superadas y 108 fallidas. Esto representa una mejora sustancial frente a la línea base del 5 de junio de 2026, que alcanzó un 70.08 %. La estabilidad del framework de automatización y de la aplicación bajo prueba ha mejorado de forma significativa.", { after: 160 }));
  c.push(P("Los hallazgos principales se concentran en dos frentes: (1) un grupo reducido de máquinas/usuarios concentra la mayoría de los fallos —dos usuarios suman el 57 % de todos los fallos— y (2) un problema sistémico de rendimiento, donde el 41.8 % de los pasos superan los 5 segundos y los flujos de “caso express” y “login” dominan el tiempo total de ejecución.", { after: 200 }));

  c.push(H2("1.1 Indicadores Clave (KPI)"));
  const w1 = [3900, 2200, 3260];
  c.push(table(w1, ["Indicador", "Valor", "Lectura"], [
    row(["Tasa de éxito global", "90.82 %", "Saludable / mejora +20.7 pp"], w1, [{}, { align: AlignmentType.CENTER, fill: GREEN, bold: true }, {}]),
    row(["Tests ejecutados", "1,176", "Cobertura amplia"], w1, [{}, { align: AlignmentType.CENTER, bold: true }, {}]),
    row(["Tests exitosos", "1,068", "—"], w1, [{}, { align: AlignmentType.CENTER, fill: GREEN }, {}]),
    row(["Tests fallidos", "108", "Concentrados en 2 máquinas"], w1, [{}, { align: AlignmentType.CENTER, fill: RED }, {}]),
    row(["Máquinas en paralelo", "23", "Ejecución distribuida"], w1, [{}, { align: AlignmentType.CENTER, bold: true }, {}]),
    row(["Archivos procesados", "26", "Reportes consolidados"], w1, [{}, { align: AlignmentType.CENTER }, {}]),
    row(["Pasos ejecutados", "43,668", "—"], w1, [{}, { align: AlignmentType.CENTER }, {}]),
    row(["Pasos lentos (> 5 s)", "18,234 (41.8 %)", "Riesgo de rendimiento"], w1, [{}, { align: AlignmentType.CENTER, fill: YELLOW }, {}]),
    row(["Tiempo total acumulado", "≈ 233 h (13,977 min)", "≈ 10 h reloj en paralelo"], w1, [{}, { align: AlignmentType.CENTER }, {}]),
    row(["Error más frecuente", "Iframe OneScript (38)", "Causa raíz técnica"], w1, [{}, { align: AlignmentType.CENTER, fill: RED }, {}]),
  ]));

  c.push(H2("1.2 Comparativa con la Ejecución Anterior"));
  const w2 = [3400, 2480, 2480, 1000];
  c.push(table(w2, ["Métrica", "05-jun-2026", "19-jun-2026", "Δ"], [
    row(["Tests ejecutados", "1,327", "1,176", "−151"], w2, [{}, { align: AlignmentType.CENTER }, { align: AlignmentType.CENTER }, { align: AlignmentType.CENTER }]),
    row(["Tasa de éxito", "70.08 %", "90.82 %", "▲ +20.7"], w2, [{}, { align: AlignmentType.CENTER, fill: RED }, { align: AlignmentType.CENTER, fill: GREEN }, { align: AlignmentType.CENTER, bold: true, fill: GREEN }]),
    row(["Tests fallidos", "397", "108", "▼ −289"], w2, [{}, { align: AlignmentType.CENTER, fill: RED }, { align: AlignmentType.CENTER, fill: GREEN }, { align: AlignmentType.CENTER, bold: true, fill: GREEN }]),
    row(["Máquinas", "26", "23", "−3"], w2, [{}, { align: AlignmentType.CENTER }, { align: AlignmentType.CENTER }, { align: AlignmentType.CENTER }]),
  ]));
  c.push(P("La reducción de fallos de 397 a 108 (−73 %) confirma que las correcciones aplicadas tras la ejecución del 5 de junio (ajuste de driver, manejo de falsos positivos y selección de combos) tuvieron un impacto directo y medible sobre la estabilidad.", { before: 120, after: 120, italics: true }));

  // ===== 2. METODOLOGÍA =====
  c.push(H1("2. Alcance y Metodología"));
  c.push(P("La ejecución se realizó bajo un esquema de paralelización por máquina, donde cada equipo ejecutó un subconjunto de escenarios (batches) de forma independiente y simultánea. Los reportes individuales fueron posteriormente consolidados en un único dataset.", { after: 120 }));
  c.push(bullet("**Aplicación bajo prueba:** Plataforma SARA (gestión de casos de asistencia – líneas AUTOS y HOGARES)."));
  c.push(bullet("**Framework:** Serenity BDD + Selenium WebDriver sobre Chrome, escenarios Gherkin/Cucumber."));
  c.push(bullet("**Modelo de ejecución:** 23 máquinas en paralelo, ~50 tests por máquina."));
  c.push(bullet("**Cobertura funcional:** Login (Cognito), apertura y diligenciamiento de Caso Express, gestión de proveedor, y transiciones de estado del caso (Programado, Aceptado, Finalizado)."));
  c.push(bullet("**Cobertura geográfica:** Escenarios distribuidos en múltiples departamentos y municipios de Colombia."));
  c.push(P("El tiempo total acumulado de cómputo fue de aproximadamente 233 horas; gracias a la ejecución paralela en 23 máquinas, el tiempo de reloj efectivo se estima en torno a 10 horas.", { before: 120 }));

  // ===== 3. RESULTADOS POR MÁQUINA =====
  c.push(H1("3. Comportamiento por Máquina"));
  c.push(P("La siguiente tabla presenta el desempeño de cada máquina ejecutora, ordenada de menor a mayor tasa de éxito para resaltar primero los casos que requieren atención.", { after: 140 }));
  const wm = [2600, 2760, 1000, 900, 1100, 1000];
  const mrows = [
    ["COMEKSF006", "jose.perez.fl", "50", "17", "33", "34"],
    ["COMEKSF043", "katian.vallejo", "50", "21", "29", "42"],
    ["COMEPORTKSF30", "giraldo.cuastumal", "50", "43", "7", "86"],
    ["COMEPORTKSF14", "juan.vargas", "77", "68", "9", "88.31"],
    ["COMEPORTKSF56", "david.villabona", "50", "46", "4", "92"],
    ["COMEPORTKSF15", "santiago.hernandez.c", "50", "47", "3", "94"],
    ["COMZADMPT020", "jorge.caicedo", "50", "47", "3", "94"],
    ["COMEKSF014", "fabian.silva", "50", "47", "3", "94"],
    ["COMEPORTKSF42", "hernando.hernandez", "50", "47", "3", "94"],
    ["PORTFLEX23M", "andres.puerta", "50", "47", "3", "94"],
    ["PORTFLEX05M", "yessica.pabon", "50", "48", "2", "96"],
    ["COMEKSF032", "joel.rodriguez", "50", "48", "2", "96"],
    ["PORTFLEX27M", "jonathan.valencia.f", "50", "49", "1", "98"],
    ["COMEPORTKSF46", "danilo.cortes", "50", "49", "1", "98"],
    ["MAURICIO", "mauro", "50", "49", "1", "98"],
    ["PORTFLEX25M", "angela.perez.z", "50", "49", "1", "98"],
    ["COMEPORTKSF39", "esneider.hernandez", "50", "49", "1", "98"],
    ["COMZADMPT001", "jairo.giraldo", "50", "49", "1", "98"],
    ["COMEKSF001", "mauricio.castano", "50", "49", "1", "98"],
    ["COMEPORTKSF08", "melanie.agualimpia", "50", "50", "0", "100"],
    ["ANKCRM38M", "sergio.anaya", "49", "49", "0", "100"],
    ["COMEPORTKSF19", "maycol.sanchez", "50", "50", "0", "100"],
    ["COMEKSF031", "Leider.Ardila", "50", "50", "0", "100"],
  ].map(r => {
    const tasa = parseFloat(r[5]);
    const fill = tasa < 50 ? RED : tasa < 90 ? YELLOW : GREEN;
    return row([r[0], r[1], r[2], r[3], r[4], r[5] + " %"], wm,
      [{}, {}, { align: AlignmentType.CENTER }, { align: AlignmentType.CENTER }, { align: AlignmentType.CENTER }, { align: AlignmentType.CENTER, fill, bold: true }]);
  });
  c.push(table(wm, ["Máquina", "Usuario", "Tests", "OK", "Fallo", "Tasa"], mrows));
  c.push(P("Lectura: 4 máquinas alcanzaron el 100 % de éxito y 13 superaron el 94 %. El problema se concentra en COMEKSF006 (34 %) y COMEKSF043 (42 %), responsables conjuntamente de 62 de los 108 fallos.", { before: 140, italics: true }));

  // ===== 4. ANÁLISIS DE ERRORES =====
  c.push(H1("4. Análisis de Errores"));
  c.push(P("Se registraron 108 tests fallidos. A diferencia de la ejecución anterior —dominada por timeouts genéricos— en esta ocasión los errores están claramente categorizados y trazados hasta el componente de código de origen, lo que facilita su corrección.", { after: 140 }));

  c.push(H2("4.1 Distribución por Tipo de Error"));
  const we = [2400, 1500, 5460];
  c.push(table(we, ["Tipo", "Fallos", "Naturaleza"], [
    row(["Data", "38", "No se encuentra el iframe OneScript para continuar el formulario"], we, [{ bold: true }, { align: AlignmentType.CENTER, fill: RED }, {}]),
    row(["UI", "26", "Elemento no visible / transición de estado fallida"], we, [{ bold: true }, { align: AlignmentType.CENTER, fill: YELLOW }, {}]),
    row(["Otros", "23", "RuntimeException: no fue posible esperar el siguiente estado"], we, [{ bold: true }, { align: AlignmentType.CENTER, fill: YELLOW }, {}]),
    row(["Validación", "17", "AssertionError: elemento esperado no presente / login"], we, [{ bold: true }, { align: AlignmentType.CENTER, fill: YELLOW }, {}]),
    row(["Selenium", "4", "DriverConfigurationError / UnreachableBrowser"], we, [{ bold: true }, { align: AlignmentType.CENTER }, {}]),
  ]));

  c.push(H2("4.2 Causas Raíz Principales (trazadas al código)"));
  c.push(P("El cruce de los mensajes de error con la columna “Origen Error” permite identificar los componentes exactos que fallan:", { after: 120 }));
  const wc = [3700, 1100, 4560];
  c.push(table(wc, ["Componente origen", "Veces", "Descripción del fallo"], [
    row(["SwitchToOneScriptIframe.java:63", "38", "No se encuentra el iframe OneScript — bloquea el diligenciamiento del formulario"], wc, [{ bold: true }, { align: AlignmentType.CENTER, fill: RED }, {}]),
    row(["ClickEstadoProgramado.java:129", "18", "Falla la transición del caso a estado 'Programado' por timeout"], wc, [{ bold: true }, { align: AlignmentType.CENTER, fill: RED }, {}]),
    row(["GoToAgentPage.java:121", "8", "No navega correctamente a la página de agente"], wc, [{ bold: true }, { align: AlignmentType.CENTER }, {}]),
    row(["LoginWithCognito.java:48/55/104", "9", "Login no completado / la app no queda autenticada"], wc, [{ bold: true }, { align: AlignmentType.CENTER }, {}]),
    row(["ClickCasoExpress.java:80/128", "5", "No se pudo seleccionar el formulario de creación de casos"], wc, [{ bold: true }, { align: AlignmentType.CENTER }, {}]),
    row(["FillCasoExpressFormInOrder.java", "8", "Error seleccionando combo/servicio (ej. AMAZONAS, CONDUCTOR ELEGIDO)"], wc, [{ bold: true }, { align: AlignmentType.CENTER }, {}]),
  ]));
  c.push(P("Conclusión técnica: el 35 % de los fallos (38 de 108) proviene de un único punto —la localización del iframe OneScript—. Resolver de forma robusta el cambio de contexto a ese iframe (espera explícita por presencia + reintento) eliminaría la mayor fuente de fallos de toda la suite.", { before: 140, bold: false, italics: true }));

  c.push(H2("4.3 Concentración de Fallos por Usuario/Máquina"));
  const wu = [3000, 1400, 4960];
  c.push(table(wu, ["Usuario", "Fallos", "Patrón de error dominante"], [
    row(["jose.perez.fl", "33", "27× iframe OneScript no encontrado — fallo sistemático del entorno"], wu, [{ bold: true }, { align: AlignmentType.CENTER, fill: RED }, {}]),
    row(["katian.vallejo", "29", "10× elemento no visible + 9× iframe + 3× driver config"], wu, [{ bold: true }, { align: AlignmentType.CENTER, fill: RED }, {}]),
    row(["juan.vargas", "9", "Volumen mayor (77 tests); fallos dispersos"], wu, [{ bold: true }, { align: AlignmentType.CENTER, fill: YELLOW }, {}]),
    row(["giraldo.cuastumal", "7", "Fallos dispersos"], wu, [{ bold: true }, { align: AlignmentType.CENTER, fill: YELLOW }, {}]),
    row(["Resto (15 usuarios)", "30", "1–4 fallos cada uno — ruido estadístico normal"], wu, [{ bold: true }, { align: AlignmentType.CENTER }, {}]),
  ]));
  c.push(P("Los dos primeros usuarios (jose.perez.fl y katian.vallejo) concentran 62 fallos = 57 % del total. Dado que en ambos el iframe OneScript es protagonista, es altamente probable que se trate de un problema de entorno/sincronización específico de esas dos máquinas, no de la lógica de las pruebas.", { before: 140, italics: true }));

  // ===== 5. RENDIMIENTO =====
  c.push(H1("5. Análisis de Rendimiento"));
  c.push(P("Se registraron 18,234 pasos lentos (> 5 s) sobre 43,668 totales, es decir el 41.8 %. Estos pasos lentos acumulan ≈ 225 horas, lo que representa prácticamente la totalidad del tiempo de cómputo de la suite. El rendimiento es, por tanto, el principal vector de optimización.", { after: 140 }));

  c.push(H2("5.1 Distribución de los Pasos Lentos"));
  const wp = [3400, 2000, 3960];
  c.push(table(wp, ["Rango de duración", "Cantidad", "Observación"], [
    row(["5 – 10 s", "3,486", "Tolerable"], wp, [{}, { align: AlignmentType.CENTER }, {}]),
    row(["10 – 30 s", "6,957", "Elevado"], wp, [{}, { align: AlignmentType.CENTER, fill: YELLOW }, {}]),
    row(["30 – 60 s", "1,682", "Crítico"], wp, [{}, { align: AlignmentType.CENTER, fill: RED }, {}]),
    row(["> 60 s", "6,109", "Muy crítico (33 % de los pasos lentos)"], wp, [{}, { align: AlignmentType.CENTER, fill: RED, bold: true }, {}]),
  ]));
  c.push(P("Alerta: 6,109 pasos superan el minuto de duración, con un máximo observado de 12 minutos en un solo paso (“diligencia caso express”, máquina de katian.vallejo). Esto sugiere esperas excesivas o reintentos silenciosos en la interacción con la aplicación.", { before: 120, italics: true }));

  c.push(H2("5.2 Operaciones Más Costosas"));
  c.push(P("Agrupando los pasos lentos por tipo de operación, el costo se concentra en cuatro flujos:", { after: 120 }));
  const wo = [5400, 1980, 1980];
  c.push(table(wo, ["Operación", "Pasos lentos", "Pico"], [
    row(["Login con Cognito (autenticación)", "≈ 1,097", "—"], wo, [{}, { align: AlignmentType.CENTER }, { align: AlignmentType.CENTER }]),
    row(["Diligenciar Caso Express (formulario + iframe)", "≈ 1,040", "12.0 min"], wo, [{}, { align: AlignmentType.CENTER, fill: RED }, { align: AlignmentType.CENTER, fill: RED }]),
    row(["Diligenciar / gestionar proveedor", "≈ 970", "11.3 min"], wo, [{}, { align: AlignmentType.CENTER, fill: RED }, { align: AlignmentType.CENTER, fill: RED }]),
    row(["Navegar a página de agente + transición de estados", "≈ 960", "—"], wo, [{}, { align: AlignmentType.CENTER, fill: YELLOW }, { align: AlignmentType.CENTER }]),
  ]));
  c.push(P("El flujo de Caso Express (apertura, entrada al iframe y diligenciamiento) es simultáneamente la mayor fuente de fallos y la operación más lenta. Es el candidato número uno para optimización e instrumentación.", { before: 140, italics: true }));

  // ===== 6. HALLAZGOS =====
  c.push(H1("6. Hallazgos Clave"));
  c.push(numItem("**Mejora notable de estabilidad:** la tasa de éxito subió del 70.08 % al 90.82 % (+20.7 pp) y los fallos cayeron un 73 %, validando las correcciones recientes del framework."));
  c.push(numItem("**Fallos altamente concentrados:** 2 de 23 máquinas (jose.perez.fl y katian.vallejo) generan el 57 % de los fallos; aislarlas elevaría la tasa global por encima del 95 %."));
  c.push(numItem("**Causa raíz única dominante:** el iframe OneScript no localizado (SwitchToOneScriptIframe.java:63) explica el 35 % de todos los fallos."));
  c.push(numItem("**Transiciones de estado frágiles:** la transición a 'Programado' falla por timeout 18 veces, indicando que la app tarda en confirmar el cambio de estado."));
  c.push(numItem("**Rendimiento como riesgo principal:** el 41.8 % de pasos son lentos y 6,109 superan el minuto; el flujo de Caso Express y el login dominan el tiempo total."));
  c.push(numItem("**Excelencia replicable:** 4 máquinas lograron 100 % de éxito; su configuración debe documentarse como estándar de referencia."));

  // ===== 7. RECOMENDACIONES =====
  c.push(H1("7. Recomendaciones"));
  const wr = [900, 4500, 1900, 2060];
  c.push(table(wr, ["Prior.", "Acción recomendada", "Responsable", "Impacto esperado"], [
    row(["P1", "Robustecer SwitchToOneScriptIframe: espera explícita por presencia del iframe + reintento con backoff", "Automatización", "−35 % de fallos"], wr, [{ align: AlignmentType.CENTER, bold: true, fill: RED }, {}, {}, {}]),
    row(["P1", "Diagnosticar entorno de COMEKSF006 y COMEKSF043 (red, recursos, versión de app)", "Infraestructura", "+~4 pp tasa global"], wr, [{ align: AlignmentType.CENTER, bold: true, fill: RED }, {}, {}, {}]),
    row(["P1", "Estabilizar transición a 'Programado' con espera por condición de estado, no por tiempo fijo", "Automatización / Dev", "−18 fallos"], wr, [{ align: AlignmentType.CENTER, bold: true, fill: RED }, {}, {}, {}]),
    row(["P2", "Optimizar e instrumentar el flujo de Caso Express (medir dónde se pierde el tiempo)", "Dev / QA", "−tiempo total"], wr, [{ align: AlignmentType.CENTER, bold: true, fill: YELLOW }, {}, {}, {}]),
    row(["P2", "Revisar rendimiento del login con Cognito (≈1,097 pasos lentos)", "Dev / Plataforma", "−tiempo total"], wr, [{ align: AlignmentType.CENTER, bold: true, fill: YELLOW }, {}, {}, {}]),
    row(["P3", "Documentar configuración de las 4 máquinas con 100 % como línea base estándar", "QA Lead", "Reproducibilidad"], wr, [{ align: AlignmentType.CENTER, bold: true }, {}, {}, {}]),
    row(["P3", "Normalizar nombres de usuario/máquina para trazabilidad de reportes", "Coordinación QA", "Gobernanza"], wr, [{ align: AlignmentType.CENTER, bold: true }, {}, {}, {}]),
  ]));

  // ===== 8. CONCLUSIÓN =====
  c.push(H1("8. Conclusión"));
  c.push(P("La ejecución del 19 de junio de 2026 demuestra que la automatización de SARA ha alcanzado un nivel de madurez sólido, con una tasa de éxito del 90.82 % y una reducción del 73 % en los fallos respecto a la línea base. La aplicación se comportó de forma estable en la gran mayoría de máquinas, y los problemas remanentes están bien acotados y son técnicamente trazables.", { after: 140 }));
  c.push(P("El camino hacia un objetivo del 95–98 % es claro y de corto plazo: (1) corregir la localización del iframe OneScript, (2) sanear las dos máquinas problemáticas y (3) estabilizar las transiciones de estado. En paralelo, el rendimiento —no la funcionalidad— se perfila como el principal eje de mejora futura, dado el alto porcentaje de pasos lentos en los flujos de Caso Express y login.", { after: 140 }));
  c.push(P("Con estas acciones priorizadas, el equipo está en posición de consolidar la suite como un mecanismo confiable de validación continua de la plataforma SARA.", { after: 200 }));

  c.push(new Paragraph({ spacing: { before: 240 }, border: { top: { style: BorderStyle.SINGLE, size: 4, color: "BFBFBF", space: 6 } },
    children: [new TextRun({ text: "Documento generado a partir de los reportes consolidados del 19/06/2026 (consolidated_report_20260619_161452). Equipo de Automatización QA – Konecta.", italics: true, size: 16, color: "808080", font: "Arial" })] }));

  return c;
}

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync("C:/Users/sergio.anaya/Desktop/Sara3/reports_consolidation/Informe_Pruebas_SARA_20260619.docx", buf);
  console.log("OK - documento generado");
});
