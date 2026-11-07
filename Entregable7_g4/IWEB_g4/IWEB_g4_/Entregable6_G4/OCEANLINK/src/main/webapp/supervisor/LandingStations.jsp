<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<LandingStation> estaciones = (List<LandingStation>) request.getAttribute("estaciones");
    if (estaciones == null) estaciones = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    Map<String, Integer> porEstado = (Map<String, Integer>) request.getAttribute("landingPorEstado");
    int conIncidencias = (Integer) request.getAttribute("landingConIncidencias");

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    boolean soloIncidencias = "activas".equals(request.getAttribute("incidencias"));

    String servlet = request.getContextPath() + "/SupervisorServlet";

    int total = 0;
    for (int c : porEstado.values()) total += c;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Landing Stations | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="landing"/>
</jsp:include>

        <main class="content">
            <div class="topbar">
                <div>
                    <h1>Landing Stations</h1>
                    <p class="small">Estado de las estaciones de aterrizaje y su actividad.</p>
                </div>
            </div>

            <section class="stats cols-3">
                <a href="<%= servlet %>?action=landing&estado=Operativa" class="stat ok">
                    <span class="stat-label">Operativas</span>
                    <span class="stat-value"><%= cantidad(porEstado, "Operativa") %></span>
                    <span class="small">de <%= total %> estaciones</span>
                </a>
                <a href="<%= servlet %>?action=landing&estado=Inactiva" class="stat ">
                    <span class="stat-label">Inactivas</span>
                    <span class="stat-value"><%= cantidad(porEstado, "Inactiva") %></span>
                    <span class="small">Fuera de operación</span>
                </a>
                <a href="<%= servlet %>?action=landing&incidencias=activas" class="stat warn">
                    <span class="stat-label">Con incidencias activas</span>
                    <span class="stat-value"><%= conIncidencias %></span>
                    <span class="small">Requieren seguimiento</span>
                </a>
            </section>

            <form class="card filters" method="get" action="<%= servlet %>">
                <input type="hidden" name="action" value="landing">
                <% if (soloIncidencias) { %>
                <input type="hidden" name="incidencias" value="activas">
                <% } %>
                <div class="col col-wide">
                    <label for="buscar">Buscar</label>
                    <input type="text" id="buscar" name="buscar" value="<%= texto(buscar) %>" placeholder="Código, estación, ciudad o país">
                </div>
                <div class="col">
                    <label for="estado">Estado</label>
                    <select id="estado" name="estado">
                        <option value="">Todos</option>
                        <option<%= sel("Operativa".equals(estado)) %>>Operativa</option>
                        <option<%= sel("Inactiva".equals(estado)) %>>Inactiva</option>
                    </select>
                </div>
                <div class="col-action botones">
                    <a href="<%= servlet %>?action=landing" class="ghost">Limpiar</a>
                    <button type="submit" class="primary">Buscar</button>
                </div>
            </form>

            <section class="card">
                <div class="card-header">
                    <h2>Estaciones de aterrizaje</h2>
                    <span class="small"><%= paginacion.getTotalRegistros() %> estaciones</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Código</th>
                            <th>Estación</th>
                            <th>Estado</th>
                            <th class="num">Segmentos</th>
                            <th class="num">Incidencias activas</th>
                            <th>Mantenimiento</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (estaciones.isEmpty()) { %>
                        <tr><td colspan="7" class="small">No hay estaciones que cumplan los filtros.</td></tr>
                        <% } %>
                        <% for (LandingStation ls : estaciones) { %>
                        <tr>
                            <td class="cell-main"><%= ls.getIdLanding() %></td>
                            <td>
                                <%= ls.getNombre() %>
                                <span class="cell-sub"><%= ls.getCiudad() %>, <%= ls.getPais() %></span>
                            </td>
                            <td><span class="badge <%= "Operativa".equals(ls.getEstado()) ? "green" : "grey" %>"><%= ls.getEstado() %></span></td>
                            <td class="num"><%= ls.getCantidadSegmentos() %></td>
                            <td class="num">
                                <% if (ls.getIncidenciasActivas() > 0) { %>
                                <span class="badge red"><%= ls.getIncidenciasActivas() %></span>
                                <% } else { %>
                                <span class="small">0</span>
                                <% } %>
                            </td>
                            <td>
                                <% if (ls.getCodigoMantenimiento() != null) { %>
                                <%= ls.getCodigoMantenimiento() %> <span class="badge <%= claseEstadoMantenimiento(ls.getEstadoMantenimiento()) %>"><%= ls.getEstadoMantenimiento() %></span>
                                <span class="cell-sub"><%= fecha(ls.getFechaMantenimiento()) %></span>
                                <% } else { %>
                                <span class="small">—</span>
                                <% } %>
                            </td>
                            <td><a href="<%= servlet %>?action=segmentos&landing=<%= url(ls.getIdLanding()) %>" class="ghost btn-sm">Ver segmentos</a></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="estaciones"/>
                </jsp:include>
            </section>
        </main>

    </div>

</body>
</html>
