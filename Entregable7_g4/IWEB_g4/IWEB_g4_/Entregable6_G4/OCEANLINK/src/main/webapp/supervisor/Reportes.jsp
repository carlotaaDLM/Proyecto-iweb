<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Incidencia" %>
<%@ page import="beans.Mantenimiento" %>
<%@ page import="beans.ServicioAfectado" %>
<%@ page import="beans.ClienteAfectado" %>
<%@ page import="beans.IndicadorMes" %>
<%@ page import="beans.UtilizacionSegmento" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%!
    // Leyenda de un gráfico circular: un <li> por cada valor
    String leyenda(String[] nombres, int[] cantidades, String[] colores) {
        String html = "";
        for (int i = 0; i < nombres.length; i++) {
            html += "<li><span class=\"dot\" style=\"background: " + colores[i] + "\"></span>"
                    + nombres[i] + "<strong>" + cantidades[i] + "</strong></li>";
        }
        return html;
    }

    int suma(int[] valores) {
        int total = 0;
        for (int v : valores) total += v;
        return total;
    }
%>
<%
    String tipo = (String) request.getAttribute("tipo");
    String desde = request.getAttribute("desde") == null ? "" : (String) request.getAttribute("desde");
    String hasta = request.getAttribute("hasta") == null ? "" : (String) request.getAttribute("hasta");
    String segmento = request.getAttribute("segmento") == null ? "" : (String) request.getAttribute("segmento");
    String landing = request.getAttribute("landing") == null ? "" : (String) request.getAttribute("landing");
    String severidad = request.getAttribute("severidad") == null ? "" : (String) request.getAttribute("severidad");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    String error = (String) request.getAttribute("error");
    String ahora = (String) request.getAttribute("ahora");

    List<Segmento> segmentosFiltro = (List<Segmento>) request.getAttribute("segmentosFiltro");
    if (segmentosFiltro == null) segmentosFiltro = new ArrayList<>();
    List<LandingStation> landingsFiltro = (List<LandingStation>) request.getAttribute("landingsFiltro");
    if (landingsFiltro == null) landingsFiltro = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");

    String servlet = request.getContextPath() + "/SupervisorServlet";

    // Texto de los filtros aplicados: "Del 01/09/2026 al 30/09/2026 · SEG-LUR-MAN · Todas las severidades"
    String periodo = "Del " + fecha(desde) + " al " + fecha(hasta);
    String elemento = !segmento.isEmpty() ? segmento : (!landing.isEmpty() ? landing : "Toda la red");
    String textoSeveridad = severidad.isEmpty() ? "Todas las severidades" : "Severidad " + severidad;
    String textoEstado = "abiertas".equals(estado) ? "Solo abiertos" : ("cerradas".equals(estado) ? "Solo cerrados" : "Todos los estados");

    String[] severidades = {"Crítica", "Alta", "Media", "Baja"};
    String[] coloresSeveridad = {"#d92d20", "#f07a12", "#e0a800", "#2e6be6"};

    // Enlaces para cambiar de tipo de reporte con los mismos filtros
    String filtros = "&desde=" + url(desde) + "&hasta=" + url(hasta) + "&segmento=" + url(segmento)
            + "&landing=" + url(landing) + "&severidad=" + url(severidad) + "&estado=" + url(estado);
    String[][] tipos = {
            {"incidencias", "Incidencias"}, {"red", "Estado general de la red"},
            {"utilizacion", "Utilización de capacidad"}, {"afectados", "Servicios y clientes afectados"},
            {"mantenimientos", "Mantenimientos"}};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Reportes | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="reporte"/>
</jsp:include>

        <main class="content">
            <div class="topbar">
                <div>
                    <h1>Reportes</h1>
                    <p class="small">Genera reportes de la red combinando tipo, periodo, elemento y estado.</p>
                </div>
            </div>

            <form class="card" method="get" action="<%= servlet %>">
                <input type="hidden" name="action" value="reporte">
                <div class="card-header">
                    <h2>Criterios del reporte</h2>
                </div>
                <div class="filters bare">
                    <div class="col">
                        <label for="tipo">Tipo de reporte <span class="req">*</span></label>
                        <select id="tipo" name="tipo" required>
                            <% for (String[] t : tipos) { %>
                            <option value="<%= t[0] %>"<%= sel(t[0].equals(tipo)) %>><%= t[1] %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="desde">Desde <span class="req">*</span></label>
                        <input type="date" id="desde" name="desde" value="<%= texto(desde) %>" required>
                    </div>
                    <div class="col">
                        <label for="hasta">Hasta <span class="req">*</span></label>
                        <input type="date" id="hasta" name="hasta" value="<%= texto(hasta) %>" required>
                    </div>
                    <div class="col">
                        <label for="segmento">Segmento</label>
                        <select id="segmento" name="segmento">
                            <option value="">Toda la red</option>
                            <% for (Segmento s : segmentosFiltro) { %>
                            <option value="<%= s.getCodigoSegmento() %>"<%= sel(s.getCodigoSegmento().equals(segmento)) %>><%= s.getCodigoSegmento() %> · <%= s.getTramo() %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="landing">Landing Station</label>
                        <select id="landing" name="landing">
                            <option value="">Todas</option>
                            <% for (LandingStation ls : landingsFiltro) { %>
                            <option value="<%= ls.getIdLanding() %>"<%= sel(ls.getIdLanding().equals(landing)) %>><%= ls.getIdLanding() %> · <%= ls.getNombre().replace("Estación ", "") %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="severidad">Severidad</label>
                        <select id="severidad" name="severidad">
                            <option value="">Todas</option>
                            <% for (String s : severidades) { %>
                            <option<%= sel(s.equals(severidad)) %>><%= s %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="estado">Estado</label>
                        <select id="estado" name="estado">
                            <option value="">Todos</option>
                            <option value="abiertas"<%= sel("abiertas".equals(estado)) %>>Abiertos o pendientes</option>
                            <option value="cerradas"<%= sel("cerradas".equals(estado)) %>>Cerrados o finalizados</option>
                        </select>
                    </div>
                    <div class="col-action">
                        <button type="submit" class="primary">Generar reporte</button>
                    </div>
                </div>
                <p class="small form-note">Severidad aplica a los reportes de incidencias y de afectados. Estado aplica a incidencias (activas / restauradas o cerradas) y mantenimientos (programados o en ejecución / finalizados o cancelados). Estado general de la red y afectados muestran la situación actual, sin depender de las fechas.</p>
            </form>

            <nav class="report-types" aria-label="Tipos de reporte">
                <span class="small">Otro tipo con los mismos filtros:</span>
                <% for (String[] t : tipos) { %>
                <a href="<%= servlet %>?action=reporte&tipo=<%= t[0] %><%= filtros %>" class="chip"<%= t[0].equals(tipo) ? " aria-current=\"page\"" : "" %>><%= t[1] %></a>
                <% } %>
            </nav>

            <% if (error != null) { %>
            <div class="alert warn"><strong>Revisa las fechas</strong> <%= error %></div>
            <% } else if ("red".equals(tipo)) {
                   // ===================== ESTADO GENERAL DE LA RED =====================
                   Map<String, Integer> segmentosPorEstado = (Map<String, Integer>) request.getAttribute("segmentosPorEstado");
                   Map<String, Integer> landingPorEstado = (Map<String, Integer>) request.getAttribute("landingPorEstado");
                   Map<String, Integer> incPorSeveridad = (Map<String, Integer>) request.getAttribute("incidenciasPorSeveridad");
                   double[] afectados = (double[]) request.getAttribute("afectados");
                   List<Segmento> detalle = (List<Segmento>) request.getAttribute("detalle");

                   String[] estadosSeg = {"Operativo", "Degradado", "En mantenimiento", "Fuera de servicio"};
                   String[] coloresSeg = {"#16a34a", "#e0a800", "#2e6be6", "#d92d20"};
                   int[] cantSeg = new int[4];
                   for (int i = 0; i < 4; i++) cantSeg[i] = cantidad(segmentosPorEstado, estadosSeg[i]);
                   int[] cantSev = new int[4];
                   for (int i = 0; i < 4; i++) cantSev[i] = cantidad(incPorSeveridad, severidades[i]);
                   int totalLs = 0;
                   for (int c : landingPorEstado.values()) totalLs += c;
            %>
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2>Reporte de estado general de la red</h2>
                        <span class="small">Situación al <%= ahora %> · <%= elemento %></span>
                    </div>
                    <span class="small">Generado el <%= ahora %></span>
                </div>

                <div class="stats inner">
                    <div class="stat ok">
                        <span class="stat-label">Segmentos operativos</span>
                        <span class="stat-value"><%= cantSeg[0] %> <small>de <%= suma(cantSeg) %></small></span>
                        <span class="small"><%= suma(cantSeg) - cantSeg[0] %> con problemas</span>
                    </div>
                    <div class="stat info">
                        <span class="stat-label">Landing Stations operativas</span>
                        <span class="stat-value"><%= cantidad(landingPorEstado, "Operativa") %> <small>de <%= totalLs %></small></span>
                        <span class="small"><%= cantidad(landingPorEstado, "Inactiva") %> inactiva(s)</span>
                    </div>
                    <div class="stat bad">
                        <span class="stat-label">Incidencias activas</span>
                        <span class="stat-value"><%= suma(cantSev) %></span>
                        <span class="small"><%= cantSev[0] %> críticas</span>
                    </div>
                    <div class="stat warn">
                        <span class="stat-label">Servicios afectados</span>
                        <span class="stat-value"><%= (int) afectados[0] %></span>
                        <span class="small"><%= (int) afectados[1] %> clientes</span>
                    </div>
                </div>

                <div class="charts">
                    <div class="donut-box">
                        <h3 class="donut-title">Segmentos por estado</h3>
                        <div class="donut" style="<%= dona(cantSeg, coloresSeg) %>">
                            <span><strong><%= suma(cantSeg) %></strong>segmentos</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(estadosSeg, cantSeg, coloresSeg) %></ul>
                    </div>
                    <div class="donut-box">
                        <h3 class="donut-title">Incidencias activas por severidad</h3>
                        <div class="donut" style="<%= dona(cantSev, coloresSeveridad) %>">
                            <span><strong><%= suma(cantSev) %></strong>activas</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(severidades, cantSev, coloresSeveridad) %></ul>
                    </div>
                </div>

                <div class="card-header report-detail">
                    <h3>Detalle por segmento</h3>
                    <span class="small"><%= paginacion.getTotalRegistros() %> segmentos</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Segmento</th>
                            <th>Tramo</th>
                            <th>Estado</th>
                            <th>Utilización</th>
                            <th class="num">Incidencias activas</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (detalle.isEmpty()) { %>
                        <tr><td colspan="5" class="small">No hay segmentos para los filtros elegidos.</td></tr>
                        <% } %>
                        <% for (Segmento s : detalle) { %>
                        <tr>
                            <td class="cell-main"><%= s.getCodigoSegmento() %></td>
                            <td class="tramo"><%= s.getTramo() %></td>
                            <td><span class="badge <%= claseEstadoSegmento(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                            <td><%= barraUso(s.getPorcentajeOcupacion()) %></td>
                            <td class="num">
                                <% if (s.getIncidenciasAbiertas() > 0) { %>
                                <span class="badge red"><%= s.getIncidenciasAbiertas() %></span>
                                <% } else { %>
                                <span class="small">0</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="segmentos"/>
                </jsp:include>
            </section>

            <% } else if ("utilizacion".equals(tipo)) {
                   // ===================== UTILIZACIÓN DE CAPACIDAD =====================
                   List<IndicadorMes> meses = (List<IndicadorMes>) request.getAttribute("meses");
                   List<UtilizacionSegmento> resumen = (List<UtilizacionSegmento>) request.getAttribute("resumenSegmentos");
                   List<UtilizacionSegmento> detalle = (List<UtilizacionSegmento>) request.getAttribute("detalle");

                   double sumaMeses = 0, pico = 0;
                   String mesPico = "—";
                   for (IndicadorMes im : meses) {
                       sumaMeses += im.getPorcentajeUso();
                       if (im.getPorcentajeUso() > pico) {
                           pico = im.getPorcentajeUso();
                           mesPico = mes(im.getMes());
                       }
                   }
                   double promedio = meses.isEmpty() ? 0 : sumaMeses / meses.size();

                   // nivel de cada segmento en el último mes del periodo y el de mayor crecimiento
                   String[] niveles = {"Normal", "Alta", "Crítica"};
                   String[] coloresNivel = {"#16a34a", "#f07a12", "#d92d20"};
                   int[] cantNivel = new int[3];
                   UtilizacionSegmento mayor = null;
                   for (UtilizacionSegmento us : resumen) {
                       if (us.getPorcentajeFinal() > 95) cantNivel[2]++;
                       else if (us.getPorcentajeFinal() >= 80) cantNivel[1]++;
                       else cantNivel[0]++;
                       if (mayor == null || us.getVariacion() > mayor.getVariacion()) mayor = us;
                   }
                   String mesFinal = meses.isEmpty() ? "—" : mes(meses.get(meses.size() - 1).getMes());
                   String mesInicial = meses.isEmpty() ? "—" : mes(meses.get(0).getMes());
            %>
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2>Reporte de utilización de capacidad</h2>
                        <span class="small"><%= periodo %> · <%= elemento %> · Registros mensuales de UTILIZACION_HIST</span>
                    </div>
                    <span class="small">Generado el <%= ahora %></span>
                </div>

                <div class="stats inner">
                    <div class="stat info">
                        <span class="stat-label">Promedio del periodo</span>
                        <span class="stat-value"><%= decimal(promedio) %>%</span>
                        <span class="small">de la capacidad total</span>
                    </div>
                    <div class="stat warn">
                        <span class="stat-label">Pico</span>
                        <span class="stat-value"><%= decimal(pico) %>%</span>
                        <span class="small">en <%= mesPico %></span>
                    </div>
                    <div class="stat bad">
                        <span class="stat-label">Segmentos ≥ 80%</span>
                        <span class="stat-value"><%= cantNivel[1] + cantNivel[2] %></span>
                        <span class="small">al cierre del periodo</span>
                    </div>
                    <div class="stat orange">
                        <span class="stat-label">Mayor crecimiento</span>
                        <span class="stat-value"><%= mayor == null ? "—" : mayor.getCodigoSegmento() %></span>
                        <span class="small"><%= mayor == null ? "sin registros" : (mayor.getVariacion() >= 0 ? "+" : "") + decimal(mayor.getVariacion()) + " puntos" %></span>
                    </div>
                </div>

                <div class="charts">
                    <div class="donut-box">
                        <h3 class="donut-title">Segmentos por nivel (<%= mesFinal %>)</h3>
                        <div class="donut" style="<%= dona(cantNivel, coloresNivel) %>">
                            <span><strong><%= resumen.size() %></strong>segmentos</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(niveles, cantNivel, coloresNivel) %></ul>
                    </div>
                    <div class="donut-box">
                        <h3 class="donut-title">Utilización mensual</h3>
                        <div class="vbars sm">
                            <% for (IndicadorMes im : meses) { %>
                            <div class="vbar">
                                <span class="vbar-value"><%= decimal(im.getPorcentajeUso()) %>%</span>
                                <span class="vbar-fill" style="height: <%= ancho(im.getPorcentajeUso(), pico) %>"></span>
                                <span class="vbar-label"><%= mes(im.getMes()).substring(0, 3) %></span>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="card-header report-detail">
                    <h3>Detalle por segmento</h3>
                    <span class="small">ordenado por utilización al cierre del periodo</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Segmento</th>
                            <th class="num">Capacidad (Gbps)</th>
                            <th class="num"><%= mesInicial %></th>
                            <th><%= mesFinal %></th>
                            <th class="num">Variación (pts)</th>
                            <th class="num">Máximo</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (detalle.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay registros de utilización en el periodo.</td></tr>
                        <% } %>
                        <% for (UtilizacionSegmento us : detalle) { %>
                        <tr>
                            <td class="cell-main"><%= us.getCodigoSegmento() %></td>
                            <td class="num"><%= numero(us.getCapacidadTotal()) %></td>
                            <td class="num"><%= decimal(us.getPorcentajeInicial()) %>%</td>
                            <td><%= barraUso(us.getPorcentajeFinal()) %></td>
                            <td class="num">
                                <% if (us.getVariacion() > 0.05) { %>
                                <span class="trend-up">↑ <%= decimal(us.getVariacion()) %></span>
                                <% } else if (us.getVariacion() < -0.05) { %>
                                <span class="trend-down">↓ <%= decimal(-us.getVariacion()) %></span>
                                <% } else { %>
                                <span class="trend-flat">→ 0</span>
                                <% } %>
                            </td>
                            <td class="num"><%= decimal(us.getPorcentajeMaximo()) %>%</td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="segmentos"/>
                </jsp:include>
            </section>

            <% } else if ("afectados".equals(tipo)) {
                   // ===================== SERVICIOS Y CLIENTES AFECTADOS =====================
                   List<ServicioAfectado> servicios = (List<ServicioAfectado>) request.getAttribute("serviciosAfectados");
                   List<ClienteAfectado> detalle = (List<ClienteAfectado>) request.getAttribute("detalle");
                   double[] afectados = (double[]) request.getAttribute("afectados");
                   int serviciosActivos = (Integer) request.getAttribute("serviciosActivos");
                   int clientes = (Integer) request.getAttribute("clientes");

                   String[] situaciones = {"Interrumpido", "Degradado"};
                   String[] coloresSit = {"#d92d20", "#e0a800"};
                   int[] cantSit = new int[2];
                   int[] cantSev = new int[4];
                   for (ServicioAfectado sa : servicios) {
                       if ("Interrumpido".equals(sa.getSituacion())) cantSit[0]++; else cantSit[1]++;
                       for (int i = 0; i < 4; i++) {
                           if (severidades[i].equals(sa.getSeveridadMaxima())) cantSev[i]++;
                       }
                   }
            %>
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2>Reporte de servicios y clientes afectados</h2>
                        <span class="small">Situación al <%= ahora %> · Incidencias activas · <%= elemento %> · <%= textoSeveridad %></span>
                    </div>
                    <span class="small">Generado el <%= ahora %></span>
                </div>

                <div class="stats inner">
                    <div class="stat warn">
                        <span class="stat-label">Servicios afectados</span>
                        <span class="stat-value"><%= (int) afectados[0] %></span>
                        <span class="small">de <%= serviciosActivos %> activos</span>
                    </div>
                    <div class="stat bad">
                        <span class="stat-label">Interrumpidos</span>
                        <span class="stat-value"><%= cantSit[0] %></span>
                        <span class="small">segmento fuera de servicio</span>
                    </div>
                    <div class="stat orange">
                        <span class="stat-label">Clientes afectados</span>
                        <span class="stat-value"><%= (int) afectados[1] %></span>
                        <span class="small">de <%= clientes %> clientes</span>
                    </div>
                    <div class="stat info">
                        <span class="stat-label">Capacidad afectada</span>
                        <span class="stat-value"><%= numero(afectados[2]) %> <small>Gbps</small></span>
                        <span class="small">suma de servicios</span>
                    </div>
                </div>

                <div class="charts">
                    <div class="donut-box">
                        <h3 class="donut-title">Servicios por situación</h3>
                        <div class="donut" style="<%= dona(cantSit, coloresSit) %>">
                            <span><strong><%= servicios.size() %></strong>servicios</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(situaciones, cantSit, coloresSit) %></ul>
                    </div>
                    <div class="donut-box">
                        <h3 class="donut-title">Servicios por severidad máxima</h3>
                        <div class="donut" style="<%= dona(cantSev, coloresSeveridad) %>">
                            <span><strong><%= servicios.size() %></strong>servicios</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(severidades, cantSev, coloresSeveridad) %></ul>
                    </div>
                </div>

                <div class="card-header report-detail">
                    <h3>Detalle por cliente</h3>
                    <span class="small"><%= paginacion.getTotalRegistros() %> clientes</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Cliente</th>
                            <th>Servicios</th>
                            <th class="num">Gbps</th>
                            <th>Incidencias</th>
                            <th>Peor situación</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (detalle.isEmpty()) { %>
                        <tr><td colspan="5" class="small">No hay clientes afectados para los filtros elegidos.</td></tr>
                        <% } %>
                        <% for (ClienteAfectado ca : detalle) { %>
                        <tr>
                            <td class="cell-main"><%= texto(ca.getRazonSocial()) %></td>
                            <td><%= ca.getServicios() %></td>
                            <td class="num"><%= numero(ca.getCapacidadAfectada()) %></td>
                            <td><%= ca.getIncidencias() %></td>
                            <td><span class="badge <%= claseSituacion(ca.getSituacion()) %>"><%= ca.getSituacion() %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="clientes"/>
                </jsp:include>
            </section>

            <% } else if ("mantenimientos".equals(tipo)) {
                   // ===================== MANTENIMIENTOS =====================
                   List<Mantenimiento> todos = (List<Mantenimiento>) request.getAttribute("todos");
                   List<Mantenimiento> detalle = (List<Mantenimiento>) request.getAttribute("detalle");

                   String[] estadosMnt = {"Programado", "En ejecución", "Finalizado", "Cancelado"};
                   String[] coloresMnt = {"#2e6be6", "#e0a800", "#16a34a", "#98a2b3"};
                   String[] tiposMnt = {"Preventivo", "Correctivo"};
                   String[] coloresTipo = {"#04b0c7", "#0f2a5c"};
                   int[] cantEstado = new int[4];
                   int[] cantTipo = new int[2];
                   int horasEstimadas = 0;
                   for (Mantenimiento m : todos) {
                       for (int i = 0; i < 4; i++) if (estadosMnt[i].equals(m.getEstado())) cantEstado[i]++;
                       for (int i = 0; i < 2; i++) if (tiposMnt[i].equals(m.getTipo())) cantTipo[i]++;
                       if (!"Cancelado".equals(m.getEstado())) horasEstimadas += m.getHorasEstimadas();
                   }
            %>
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2>Reporte de mantenimientos</h2>
                        <span class="small"><%= periodo %> · <%= elemento %> · <%= textoEstado %></span>
                    </div>
                    <span class="small">Generado el <%= ahora %></span>
                </div>

                <div class="stats inner">
                    <div class="stat ">
                        <span class="stat-label">Mantenimientos</span>
                        <span class="stat-value"><%= todos.size() %></span>
                        <span class="small">en el periodo</span>
                    </div>
                    <div class="stat info">
                        <span class="stat-label">Programados</span>
                        <span class="stat-value"><%= cantEstado[0] %></span>
                        <span class="small"><%= cantEstado[1] %> en ejecución</span>
                    </div>
                    <div class="stat ok">
                        <span class="stat-label">Finalizados</span>
                        <span class="stat-value"><%= cantEstado[2] %></span>
                        <span class="small"><%= cantEstado[3] %> cancelado(s)</span>
                    </div>
                    <div class="stat warn">
                        <span class="stat-label">Horas estimadas</span>
                        <span class="stat-value"><%= horasEstimadas %> <small>h</small></span>
                        <span class="small">sin contar cancelados</span>
                    </div>
                </div>

                <div class="charts">
                    <div class="donut-box">
                        <h3 class="donut-title">Por estado</h3>
                        <div class="donut" style="<%= dona(cantEstado, coloresMnt) %>">
                            <span><strong><%= todos.size() %></strong>mantenimientos</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(estadosMnt, cantEstado, coloresMnt) %></ul>
                    </div>
                    <div class="donut-box">
                        <h3 class="donut-title">Por tipo</h3>
                        <div class="donut" style="<%= dona(cantTipo, coloresTipo) %>">
                            <span><strong><%= todos.size() %></strong>mantenimientos</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(tiposMnt, cantTipo, coloresTipo) %></ul>
                    </div>
                </div>

                <div class="card-header report-detail">
                    <h3>Detalle</h3>
                    <span class="small"><%= paginacion.getTotalRegistros() %> mantenimientos · pendientes primero</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Código</th>
                            <th>Actividad</th>
                            <th>Elemento</th>
                            <th>Fecha programada</th>
                            <th class="num">Duración</th>
                            <th>Estado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (detalle.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay mantenimientos para los filtros elegidos.</td></tr>
                        <% } %>
                        <% for (Mantenimiento m : detalle) { %>
                        <%@ include file="filaMantenimiento.jspf" %>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="mantenimientos"/>
                </jsp:include>
            </section>

            <% } else {
                   // ===================== INCIDENCIAS (por defecto) =====================
                   int registradas = (Integer) request.getAttribute("registradas");
                   int activas = (Integer) request.getAttribute("activas");
                   Map<String, Integer> porSeveridad = (Map<String, Integer>) request.getAttribute("porSeveridad");
                   Map<String, Integer> porEstado = (Map<String, Integer>) request.getAttribute("porEstado");
                   String[] masAfectado = (String[]) request.getAttribute("masAfectado");
                   List<Incidencia> detalle = (List<Incidencia>) request.getAttribute("detalle");

                   int[] cantSev = new int[4];
                   for (int i = 0; i < 4; i++) cantSev[i] = cantidad(porSeveridad, severidades[i]);
                   String[] estadosInc = {"Detectada", "En análisis", "Reparación programada", "En reparación", "Servicio restaurado", "Cerrada"};
                   String[] coloresInc = new String[6];
                   int[] cantEst = new int[6];
                   for (int i = 0; i < 6; i++) {
                       cantEst[i] = cantidad(porEstado, estadosInc[i]);
                       coloresInc[i] = colorEstadoIncidencia(estadosInc[i]);
                   }
            %>
            <section class="card">
                <div class="card-header">
                    <div>
                        <h2>Reporte de incidencias</h2>
                        <span class="small"><%= periodo %> · <%= elemento %> · <%= textoSeveridad %> · <%= textoEstado %></span>
                    </div>
                    <span class="small">Generado el <%= ahora %></span>
                </div>

                <div class="stats inner">
                    <div class="stat ">
                        <span class="stat-label">Registradas</span>
                        <span class="stat-value"><%= registradas %></span>
                        <span class="small">en el periodo</span>
                    </div>
                    <div class="stat bad">
                        <span class="stat-label">Activas</span>
                        <span class="stat-value"><%= activas %></span>
                        <span class="small">aún sin restaurar</span>
                    </div>
                    <div class="stat ok">
                        <span class="stat-label">Restauradas o cerradas</span>
                        <span class="stat-value"><%= registradas - activas %></span>
                        <span class="small">resueltas</span>
                    </div>
                    <div class="stat warn">
                        <span class="stat-label">Segmento más afectado</span>
                        <span class="stat-value"><%= masAfectado == null ? "—" : masAfectado[0] %></span>
                        <span class="small"><%= masAfectado == null ? "sin incidencias" : masAfectado[1] + " incidencias" %></span>
                    </div>
                </div>

                <div class="charts">
                    <div class="donut-box">
                        <h3 class="donut-title">Por severidad</h3>
                        <div class="donut" style="<%= dona(cantSev, coloresSeveridad) %>">
                            <span><strong><%= registradas %></strong>incidencias</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(severidades, cantSev, coloresSeveridad) %></ul>
                    </div>
                    <div class="donut-box">
                        <h3 class="donut-title">Por estado</h3>
                        <div class="donut" style="<%= dona(cantEst, coloresInc) %>">
                            <span><strong><%= registradas %></strong>incidencias</span>
                        </div>
                        <ul class="donut-legend"><%= leyenda(estadosInc, cantEst, coloresInc) %></ul>
                    </div>
                </div>

                <div class="card-header report-detail">
                    <h3>Detalle</h3>
                    <span class="small"><%= paginacion.getTotalRegistros() %> incidencias · por fecha de detección</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Código</th>
                            <th>Incidencia</th>
                            <th>Severidad</th>
                            <th>Estado</th>
                            <th>Detección</th>
                            <th>Landing Station</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (detalle.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay incidencias para los filtros elegidos.</td></tr>
                        <% } %>
                        <% for (Incidencia inc : detalle) { %>
                        <tr>
                            <td class="cell-main"><%= inc.getCodigoIncidencia() %></td>
                            <td>
                                <%= texto(inc.getTitulo()) %>
                                <span class="cell-sub"><%= inc.getCodigoSegmento() %> · <%= inc.getTramo() %></span>
                            </td>
                            <td><span class="badge <%= claseSeveridad(inc.getSeveridad()) %>"><%= inc.getSeveridad() %></span></td>
                            <td><span class="badge <%= claseEstadoIncidencia(inc.getEstado()) %>"><%= inc.getEstado() %></span></td>
                            <td class="date"><%= fechaHora(inc.getFechaDeteccion()) %></td>
                            <td><%= inc.getIdLanding() %> · <%= inc.getNombreLanding() %></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="incidencias"/>
                </jsp:include>
            </section>
            <% } %>
        </main>

    </div>

</body>
</html>
