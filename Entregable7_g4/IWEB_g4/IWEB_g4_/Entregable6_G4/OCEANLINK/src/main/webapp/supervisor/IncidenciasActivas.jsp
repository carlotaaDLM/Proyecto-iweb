<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="beans.Incidencia" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<Incidencia> incidencias = (List<Incidencia>) request.getAttribute("incidencias");
    if (incidencias == null) incidencias = new ArrayList<>();
    List<Segmento> segmentosFiltro = (List<Segmento>) request.getAttribute("segmentosFiltro");
    if (segmentosFiltro == null) segmentosFiltro = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    Map<String, Integer> porSeveridad = (Map<String, Integer>) request.getAttribute("porSeveridad");
    int totalRegistradas = (Integer) request.getAttribute("totalRegistradas");

    String severidad = request.getAttribute("severidad") == null ? "" : (String) request.getAttribute("severidad");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    String segmento = request.getAttribute("segmento") == null ? "" : (String) request.getAttribute("segmento");

    String servlet = request.getContextPath() + "/SupervisorServlet";

    String[] severidades = {"Crítica", "Alta", "Media", "Baja"};
    String[] estadosAbiertos = {"Detectada", "En análisis", "Reparación programada", "En reparación"};
    int totalActivas = 0;
    for (String s : severidades) totalActivas += cantidad(porSeveridad, s);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Incidencias activas | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="incidencias"/>
</jsp:include>

        <main class="content">
            <div class="topbar">
                <div>
                    <h1>Incidencias activas</h1>
                    <p class="small">Incidencias abiertas en la red, ordenadas por severidad.</p>
                </div>
            </div>

            <section class="stats cols-5">
                <a href="<%= servlet %>?action=incidencias&severidad=<%= url("Crítica") %>" class="stat bad">
                    <span class="stat-label">Críticas</span>
                    <span class="stat-value"><%= cantidad(porSeveridad, "Crítica") %></span>
                    <span class="small">Corte o pérdida del servicio</span>
                </a>
                <a href="<%= servlet %>?action=incidencias&severidad=Alta" class="stat orange">
                    <span class="stat-label">Altas</span>
                    <span class="stat-value"><%= cantidad(porSeveridad, "Alta") %></span>
                    <span class="small">Afectan a varios servicios</span>
                </a>
                <a href="<%= servlet %>?action=incidencias&severidad=Media" class="stat warn">
                    <span class="stat-label">Medias</span>
                    <span class="stat-value"><%= cantidad(porSeveridad, "Media") %></span>
                    <span class="small">Degradan el rendimiento</span>
                </a>
                <a href="<%= servlet %>?action=incidencias&severidad=Baja" class="stat info">
                    <span class="stat-label">Bajas</span>
                    <span class="stat-value"><%= cantidad(porSeveridad, "Baja") %></span>
                    <span class="small">Sin impacto en el tráfico</span>
                </a>
                <a href="<%= servlet %>?action=incidencias" class="stat ">
                    <span class="stat-label">Total activas</span>
                    <span class="stat-value"><%= totalActivas %></span>
                    <span class="small">de <%= totalRegistradas %> registradas</span>
                </a>
            </section>

            <form class="card filters" method="get" action="<%= servlet %>">
                <input type="hidden" name="action" value="incidencias">
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
                        <option value="">Todos los abiertos</option>
                        <% for (String e : estadosAbiertos) { %>
                        <option<%= sel(e.equals(estado)) %>><%= e %></option>
                        <% } %>
                    </select>
                </div>
                <div class="col">
                    <label for="segmento">Segmento</label>
                    <select id="segmento" name="segmento">
                        <option value="">Todos</option>
                        <% for (Segmento s : segmentosFiltro) { %>
                        <option value="<%= s.getCodigoSegmento() %>"<%= sel(s.getCodigoSegmento().equals(segmento)) %>><%= s.getCodigoSegmento() %> · <%= s.getTramo() %></option>
                        <% } %>
                    </select>
                </div>
                <div class="col-action botones">
                    <a href="<%= servlet %>?action=incidencias" class="ghost">Limpiar</a>
                    <button type="submit" class="primary">Aplicar filtros</button>
                </div>
            </form>

            <section class="card">
                <div class="card-header">
                    <h2>Incidencias abiertas</h2>
                    <span class="small"><%= paginacion.getTotalRegistros() %> incidencias · de mayor a menor severidad</span>
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
                            <th class="num">Servicios afectados</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (incidencias.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay incidencias activas que cumplan los filtros.</td></tr>
                        <% } %>
                        <% for (Incidencia inc : incidencias) { %>
                        <tr>
                            <td class="cell-main"><%= inc.getCodigoIncidencia() %></td>
                            <td>
                                <%= texto(inc.getTitulo()) %>
                                <span class="cell-sub"><%= inc.getCodigoSegmento() %> · <%= inc.getTramo() %></span>
                            </td>
                            <td><span class="badge <%= claseSeveridad(inc.getSeveridad()) %>"><%= inc.getSeveridad() %></span></td>
                            <td><span class="badge <%= claseEstadoIncidencia(inc.getEstado()) %>"><%= inc.getEstado() %></span></td>
                            <td class="date"><%= fechaHora(inc.getFechaDeteccion()) %></td>
                            <td class="num">
                                <% if (inc.getServiciosAfectados() > 0) { %>
                                <a href="<%= servlet %>?action=afectados&incidencia=<%= url(inc.getCodigoIncidencia()) %>" class="cell-link"><%= inc.getServiciosAfectados() %></a>
                                <% } else { %>
                                0
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="incidencias"/>
                </jsp:include>
                <p class="small form-note">Se consideran activas las incidencias que aún no tienen el servicio restaurado ni están cerradas. Servicios afectados = servicios <strong>Activos</strong> cuya ruta pasa por algún segmento de la incidencia.</p>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Niveles de severidad</h2>
                </div>
                <div class="legend">
                    <div><span class="badge red">Crítica</span><p>Corte total o pérdida de servicio en uno o más segmentos.</p></div>
                    <div><span class="badge orange">Alta</span><p>Falla que afecta a varios servicios o a una estación.</p></div>
                    <div><span class="badge yellow">Media</span><p>Degradación del rendimiento sin corte del servicio.</p></div>
                    <div><span class="badge blue">Baja</span><p>Alarma o anomalía sin impacto en el tráfico.</p></div>
                </div>
            </section>
        </main>

    </div>

</body>
</html>
