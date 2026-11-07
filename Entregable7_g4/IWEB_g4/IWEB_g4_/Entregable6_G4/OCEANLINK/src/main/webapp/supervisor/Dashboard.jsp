<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Mantenimiento" %>
<%@ include file="badges.jspf" %>
<%
    Map<String, Integer> segmentosPorEstado = (Map<String, Integer>) request.getAttribute("segmentosPorEstado");
    Map<String, Integer> landingPorEstado = (Map<String, Integer>) request.getAttribute("landingPorEstado");
    Map<String, Integer> incidenciasPorSeveridad = (Map<String, Integer>) request.getAttribute("incidenciasPorSeveridad");
    int landingConIncidencias = (Integer) request.getAttribute("landingConIncidencias");
    double[] capacidad = (double[]) request.getAttribute("capacidadRed");
    double[] afectados = (double[]) request.getAttribute("afectados");
    int clientes = (Integer) request.getAttribute("clientes");

    List<Segmento> altaUtilizacion = (List<Segmento>) request.getAttribute("altaUtilizacion");
    if (altaUtilizacion == null) altaUtilizacion = new ArrayList<>();
    List<Mantenimiento> pendientes = (List<Mantenimiento>) request.getAttribute("mantenimientosPendientes");
    if (pendientes == null) pendientes = new ArrayList<>();

    String servlet = request.getContextPath() + "/SupervisorServlet";

    int totalSegmentos = 0;
    for (int c : segmentosPorEstado.values()) totalSegmentos += c;
    int totalLandings = 0;
    for (int c : landingPorEstado.values()) totalLandings += c;

    // Capacidad de la red: total - utilizada - reservada = disponible (igual que el Capacity Planner)
    double total = capacidad[0], utilizada = capacidad[1], reservada = capacidad[2];
    double disponible = total - utilizada - reservada;

    String[] severidades = {"Crítica", "Alta", "Media", "Baja"};
    int incidenciasActivas = 0, maxSeveridad = 0;
    for (String s : severidades) {
        incidenciasActivas += cantidad(incidenciasPorSeveridad, s);
        maxSeveridad = Math.max(maxSeveridad, cantidad(incidenciasPorSeveridad, s));
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="dashboard"/>
</jsp:include>

        <main class="content">
            <div class="topbar">
                <div>
                    <h1>Dashboard</h1>
                    <p class="small">Estado general de la red OceanLink.</p>
                </div>
                <span class="small">Actualizado al <%= request.getAttribute("ahora") %></span>
            </div>

            <section class="card">
                <div class="card-header">
                    <h2>Estado de segmentos</h2>
                    <a href="<%= servlet %>?action=segmentos" class="cell-link small">Ver segmentos</a>
                </div>
                <div class="stats cols-4 inner">
                    <a href="<%= servlet %>?action=segmentos&estado=Operativo" class="stat ok">
                        <span class="stat-label">Operativos</span>
                        <span class="stat-value"><%= cantidad(segmentosPorEstado, "Operativo") %> <small>de <%= totalSegmentos %></small></span>
                        <span class="small">Funcionan con normalidad</span>
                    </a>
                    <a href="<%= servlet %>?action=segmentos&estado=Degradado" class="stat warn">
                        <span class="stat-label">Degradados</span>
                        <span class="stat-value"><%= cantidad(segmentosPorEstado, "Degradado") %></span>
                        <span class="small">Rendimiento afectado</span>
                    </a>
                    <a href="<%= servlet %>?action=segmentos&estado=<%= url("En mantenimiento") %>" class="stat info">
                        <span class="stat-label">En mantenimiento</span>
                        <span class="stat-value"><%= cantidad(segmentosPorEstado, "En mantenimiento") %></span>
                        <span class="small">Intervención en curso</span>
                    </a>
                    <a href="<%= servlet %>?action=segmentos&estado=<%= url("Fuera de servicio") %>" class="stat bad">
                        <span class="stat-label">Fuera de servicio</span>
                        <span class="stat-value"><%= cantidad(segmentosPorEstado, "Fuera de servicio") %></span>
                        <span class="small">Sin tráfico</span>
                    </a>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Landing Stations</h2>
                    <a href="<%= servlet %>?action=landing" class="cell-link small">Ver estaciones</a>
                </div>
                <div class="stats cols-3 inner">
                    <a href="<%= servlet %>?action=landing&estado=Operativa" class="stat ok">
                        <span class="stat-label">Operativas</span>
                        <span class="stat-value"><%= cantidad(landingPorEstado, "Operativa") %></span>
                        <span class="small">de <%= totalLandings %></span>
                    </a>
                    <a href="<%= servlet %>?action=landing&estado=Inactiva" class="stat ">
                        <span class="stat-label">Inactivas</span>
                        <span class="stat-value"><%= cantidad(landingPorEstado, "Inactiva") %></span>
                        <span class="small">Fuera de operación</span>
                    </a>
                    <a href="<%= servlet %>?action=landing" class="stat warn">
                        <span class="stat-label">Con incidencias</span>
                        <span class="stat-value"><%= landingConIncidencias %></span>
                        <span class="small">activas en la estación</span>
                    </a>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Utilización de capacidad</h2>
                    <a href="<%= servlet %>?action=segmentos" class="cell-link small">Ver detalle</a>
                </div>
                <div class="stats cols-3 inner">
                    <div class="stat info">
                        <span class="stat-label">Promedio de la red</span>
                        <span class="stat-value"><%= decimal(total > 0 ? utilizada * 100 / total : 0) %>%</span>
                        <span class="small"><%= numero(utilizada) %> de <%= numero(total) %> Gbps</span>
                    </div>
                    <a href="<%= servlet %>?action=segmentos&nivel=minimo80" class="stat bad">
                        <span class="stat-label">Alta utilización</span>
                        <span class="stat-value"><%= altaUtilizacion.size() %></span>
                        <span class="small">segmentos ≥ 80%</span>
                    </a>
                    <div class="stat ok">
                        <span class="stat-label">Disponible</span>
                        <span class="stat-value"><%= numero(disponible) %> <small>Gbps</small></span>
                        <span class="small">en toda la red</span>
                    </div>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Resumen de operación</h2>
                </div>
                <div class="stats cols-4 inner">
                    <a href="<%= servlet %>?action=incidencias" class="stat bad">
                        <span class="stat-label">Incidencias activas</span>
                        <span class="stat-value"><%= incidenciasActivas %></span>
                        <span class="small"><%= cantidad(incidenciasPorSeveridad, "Crítica") %> críticas</span>
                    </a>
                    <a href="<%= servlet %>?action=afectados" class="stat warn">
                        <span class="stat-label">Servicios afectados</span>
                        <span class="stat-value"><%= (int) afectados[0] %></span>
                        <span class="small">por incidencias activas</span>
                    </a>
                    <a href="<%= servlet %>?action=afectados#clientes" class="stat orange">
                        <span class="stat-label">Clientes afectados</span>
                        <span class="stat-value"><%= (int) afectados[1] %></span>
                        <span class="small">de <%= clientes %> clientes</span>
                    </a>
                    <a href="<%= servlet %>?action=mantenimientos" class="stat info">
                        <span class="stat-label">Mantenimientos pendientes</span>
                        <span class="stat-value"><%= pendientes.size() %></span>
                        <span class="small">programados o en ejecución</span>
                    </a>
                </div>
            </section>

            <div class="split even">
                <section class="card">
                    <div class="card-header">
                        <h2>Segmentos con alta utilización</h2>
                        <a href="<%= servlet %>?action=segmentos&nivel=minimo80" class="cell-link small">80% o más</a>
                    </div>
                    <div class="table-wrap">
                        <table class="table">
                            <thead>
                            <tr>
                                <th>Segmento</th>
                                <th>Tramo</th>
                                <th>Uso</th>
                                <th class="num">Disponible (Gbps)</th>
                            </tr>
                            </thead>
                            <tbody>
                            <% if (altaUtilizacion.isEmpty()) { %>
                            <tr><td colspan="4" class="small">Ningún segmento llega al 80% de ocupación.</td></tr>
                            <% } %>
                            <% for (Segmento s : altaUtilizacion) { %>
                            <tr>
                                <td class="cell-main"><a href="<%= servlet %>?action=detalleSegmento&codigo=<%= url(s.getCodigoSegmento()) %>" class="cell-link"><%= s.getCodigoSegmento() %></a></td>
                                <td class="tramo"><%= s.getTramo() %></td>
                                <td><%= barraUso(s.getPorcentajeOcupacion()) %></td>
                                <td class="num"><%= numero(s.getCapacidadDisponible()) %></td>
                            </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </section>

                <section class="card">
                    <div class="card-header">
                        <h2>Incidencias activas por severidad</h2>
                        <a href="<%= servlet %>?action=incidencias" class="cell-link small">Ver todas</a>
                    </div>
                    <div class="sev-list">
                        <% for (String sev : severidades) { %>
                        <a href="<%= servlet %>?action=incidencias&severidad=<%= url(sev) %>" class="sev-row">
                            <span class="badge <%= claseSeveridad(sev) %>"><%= sev %></span>
                            <span class="sev-bar"><span style="width: <%= ancho(cantidad(incidenciasPorSeveridad, sev), maxSeveridad) %>; background: <%= colorSeveridad(sev) %>"></span></span>
                            <strong><%= cantidad(incidenciasPorSeveridad, sev) %></strong>
                        </a>
                        <% } %>
                    </div>
                </section>
            </div>

            <section class="card">
                <div class="card-header">
                    <h2>Mantenimientos pendientes</h2>
                    <a href="<%= servlet %>?action=mantenimientos" class="cell-link small">Ver todos</a>
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
                        <% if (pendientes.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay mantenimientos programados ni en ejecución.</td></tr>
                        <% } %>
                        <% for (Mantenimiento m : pendientes) { %>
                        <%@ include file="filaMantenimiento.jspf" %>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>
        </main>

    </div>

</body>
</html>
