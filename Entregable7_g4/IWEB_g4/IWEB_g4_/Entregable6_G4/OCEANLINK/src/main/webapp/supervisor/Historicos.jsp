<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.EventoHistorico" %>
<%@ page import="beans.IndicadorMes" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<EventoHistorico> eventos = (List<EventoHistorico>) request.getAttribute("eventos");
    if (eventos == null) eventos = new ArrayList<>();
    List<IndicadorMes> meses = (List<IndicadorMes>) request.getAttribute("meses");
    if (meses == null) meses = new ArrayList<>();
    List<Segmento> segmentosFiltro = (List<Segmento>) request.getAttribute("segmentosFiltro");
    if (segmentosFiltro == null) segmentosFiltro = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");

    int incidenciasPeriodo = (Integer) request.getAttribute("incidenciasPeriodo");
    int resueltasPeriodo = (Integer) request.getAttribute("resueltasPeriodo");
    int finalizados = (Integer) request.getAttribute("finalizadosPeriodo");
    int enEjecucion = (Integer) request.getAttribute("enEjecucionPeriodo");

    String desde = request.getAttribute("desde") == null ? "" : (String) request.getAttribute("desde");
    String hasta = request.getAttribute("hasta") == null ? "" : (String) request.getAttribute("hasta");
    String segmento = request.getAttribute("segmento") == null ? "" : (String) request.getAttribute("segmento");
    String tipo = request.getAttribute("tipo") == null ? "" : (String) request.getAttribute("tipo");

    String servlet = request.getContextPath() + "/SupervisorServlet";

    // Promedio y pico de la utilización mensual en el periodo
    double suma = 0, pico = 0;
    String mesPico = "—";
    for (IndicadorMes im : meses) {
        suma += im.getPorcentajeUso();
        if (im.getPorcentajeUso() > pico) {
            pico = im.getPorcentajeUso();
            mesPico = mes(im.getMes());
        }
    }
    double promedio = meses.isEmpty() ? 0 : suma / meses.size();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Históricos | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="historicos"/>
</jsp:include>

        <main class="content">
            <div class="topbar">
                <div>
                    <h1>Históricos</h1>
                    <p class="small">Indicadores de operación de meses anteriores y registro de eventos.</p>
                </div>
            </div>

            <form class="card filters" method="get" action="<%= servlet %>">
                <input type="hidden" name="action" value="historicos">
                <div class="col">
                    <label for="desde">Desde</label>
                    <input type="date" id="desde" name="desde" value="<%= texto(desde) %>">
                </div>
                <div class="col">
                    <label for="hasta">Hasta</label>
                    <input type="date" id="hasta" name="hasta" value="<%= texto(hasta) %>">
                </div>
                <div class="col">
                    <label for="segmento">Elemento</label>
                    <select id="segmento" name="segmento">
                        <option value="">Toda la red</option>
                        <% for (Segmento s : segmentosFiltro) { %>
                        <option value="<%= s.getCodigoSegmento() %>"<%= sel(s.getCodigoSegmento().equals(segmento)) %>><%= s.getCodigoSegmento() %> · <%= s.getTramo() %></option>
                        <% } %>
                    </select>
                </div>
                <div class="col">
                    <label for="tipo">Tipo de evento</label>
                    <select id="tipo" name="tipo">
                        <option value="">Todos</option>
                        <option<%= sel("Incidencia".equals(tipo)) %>>Incidencia</option>
                        <option<%= sel("Mantenimiento".equals(tipo)) %>>Mantenimiento</option>
                    </select>
                </div>
                <div class="col-action botones">
                    <a href="<%= servlet %>?action=historicos" class="ghost">Limpiar</a>
                    <button type="submit" class="primary">Buscar</button>
                </div>
            </form>

            <section class="stats">
                <div class="stat info">
                    <span class="stat-label">Utilización promedio</span>
                    <span class="stat-value"><%= decimal(promedio) %>%</span>
                    <span class="small"><%= segmento.isEmpty() ? "de la red" : "de " + segmento %> en el periodo</span>
                </div>
                <div class="stat bad">
                    <span class="stat-label">Incidencias registradas</span>
                    <span class="stat-value"><%= incidenciasPeriodo %></span>
                    <span class="small"><%= resueltasPeriodo %> resueltas · <%= incidenciasPeriodo - resueltasPeriodo %> en proceso</span>
                </div>
                <div class="stat ok">
                    <span class="stat-label">Mantenimientos iniciados</span>
                    <span class="stat-value"><%= finalizados + enEjecucion %></span>
                    <span class="small"><%= finalizados %> finalizados · <%= enEjecucion %> en ejecución</span>
                </div>
                <div class="stat warn">
                    <span class="stat-label">Pico de utilización</span>
                    <span class="stat-value"><%= decimal(pico) %>%</span>
                    <span class="small">en <%= mesPico %></span>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Utilización mensual <%= segmento.isEmpty() ? "de la red" : "de " + segmento %></h2>
                    <span class="small">% de la capacidad total utilizada (UTILIZACION_HIST)</span>
                </div>
                <% if (meses.isEmpty()) { %>
                <p class="small">No hay registros mensuales en el periodo elegido.</p>
                <% } else { %>
                <div class="vbars">
                    <% for (IndicadorMes im : meses) { %>
                    <div class="vbar">
                        <span class="vbar-value"><%= decimal(im.getPorcentajeUso()) %>%</span>
                        <span class="vbar-fill" style="height: <%= ancho(im.getPorcentajeUso(), pico) %>"></span>
                        <span class="vbar-label"><%= mes(im.getMes()).substring(0, 3) %></span>
                    </div>
                    <% } %>
                </div>
                <% } %>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Indicadores por mes</h2>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Mes</th>
                            <th>Utilización</th>
                            <th class="num">Segmentos ≥ 80%</th>
                            <th class="num">Incidencias</th>
                            <th class="num">Mantenimientos</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (meses.isEmpty()) { %>
                        <tr><td colspan="5" class="small">Sin registros en el periodo.</td></tr>
                        <% } %>
                        <% for (IndicadorMes im : meses) { %>
                        <tr>
                            <td><%= mes(im.getMes()) %></td>
                            <td><%= barraUso(im.getPorcentajeUso()) %></td>
                            <td class="num"><%= im.getSegmentosAlta() %></td>
                            <td class="num"><%= im.getIncidencias() %></td>
                            <td class="num"><%= im.getMantenimientos() %></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Historial de eventos</h2>
                    <span class="small">Más recientes primero</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Fecha y hora</th>
                            <th>Elemento</th>
                            <th>Tipo</th>
                            <th>Código</th>
                            <th>Descripción</th>
                            <th>Estado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (eventos.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay eventos en el periodo elegido.</td></tr>
                        <% } %>
                        <% for (EventoHistorico ev : eventos) {
                               boolean esIncidencia = "Incidencia".equals(ev.getTipo()); %>
                        <tr>
                            <td class="date"><%= fechaHora(ev.getFecha(), ev.getHora()) %></td>
                            <td class="cell-main"><%= ev.getElemento() == null ? "—" : ev.getElemento() %></td>
                            <td><span class="badge <%= esIncidencia ? "red" : "green" %>"><%= ev.getTipo() %></span></td>
                            <td><%= ev.getCodigo() %></td>
                            <td><%= texto(ev.getDescripcion()) %></td>
                            <td><span class="badge <%= esIncidencia ? claseEstadoIncidencia(ev.getEstado()) : claseEstadoMantenimiento(ev.getEstado()) %>"><%= ev.getEstado() %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="eventos"/>
                </jsp:include>
            </section>
        </main>

    </div>

</body>
</html>
