<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Incidencia" %>
<%@ page import="beans.ServicioAfectado" %>
<%@ page import="beans.Mantenimiento" %>
<%@ page import="beans.UtilizacionHist" %>
<%@ include file="badges.jspf" %>
<%
    Segmento seg = (Segmento) request.getAttribute("segmento");

    List<Incidencia> incidencias = (List<Incidencia>) request.getAttribute("incidencias");
    if (incidencias == null) incidencias = new ArrayList<>();
    List<ServicioAfectado> servicios = (List<ServicioAfectado>) request.getAttribute("servicios");
    if (servicios == null) servicios = new ArrayList<>();
    List<String> rutas = (List<String>) request.getAttribute("rutas");
    if (rutas == null) rutas = new ArrayList<>();
    List<Mantenimiento> mantenimientos = (List<Mantenimiento>) request.getAttribute("mantenimientos");
    if (mantenimientos == null) mantenimientos = new ArrayList<>();
    List<UtilizacionHist> historial = (List<UtilizacionHist>) request.getAttribute("historial");
    if (historial == null) historial = new ArrayList<>();

    String servlet = request.getContextPath() + "/SupervisorServlet";

    int activas = seg.getIncidenciasAbiertas();

    List<Integer> clientesDistintos = new ArrayList<>();
    for (ServicioAfectado sa : servicios) {
        if (!clientesDistintos.contains(sa.getIdCliente())) clientesDistintos.add(sa.getIdCliente());
    }

    // Impacto del segmento sobre los servicios que lo usan
    String impacto = "Sin impacto";
    String claseImpacto = "green";
    if ("Fuera de servicio".equals(seg.getEstado())) {
        impacto = "Interrumpido";
        claseImpacto = "red";
    } else if ("Degradado".equals(seg.getEstado()) || activas > 0) {
        impacto = "Degradado";
        claseImpacto = "yellow";
    } else if ("En mantenimiento".equals(seg.getEstado())) {
        impacto = "En mantenimiento";
        claseImpacto = "blue";
    }

    double maxHist = 0;
    for (UtilizacionHist u : historial) maxHist = Math.max(maxHist, u.getCapacidadUtilizada());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Detalle del segmento | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="segmentos"/>
</jsp:include>

        <main class="content">
            <a href="<%= servlet %>?action=segmentos" class="back-link">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
                Volver a segmentos
            </a>

            <div class="topbar">
                <div>
                    <h1>Detalle del segmento</h1>
                    <p class="small">Capacidad, incidencias, servicios, clientes y mantenimientos del segmento.</p>
                </div>
            </div>

            <section class="card">
                <div class="record-head">
                    <div>
                        <span class="stat-label">Segmento</span>
                        <span class="big"><%= seg.getCodigoSegmento() %></span>
                        <span class="small"><%= seg.getTramo() %></span>
                    </div>
                    <div>
                        <span class="stat-label">Origen</span>
                        <%= seg.getNombreOrigen() %>
                        <span class="cell-sub"><%= seg.getIdOrigen() %> · <%= seg.getPaisOrigen() %></span>
                    </div>
                    <div>
                        <span class="stat-label">Destino</span>
                        <%= seg.getNombreDestino() %>
                        <span class="cell-sub"><%= seg.getIdDestino() %> · <%= seg.getPaisDestino() %></span>
                    </div>
                    <div>
                        <span class="stat-label">Estado actual</span>
                        <span class="badge <%= claseEstadoSegmento(seg.getEstado()) %>"><%= seg.getEstado() %></span>
                    </div>
                </div>
            </section>

            <nav class="subnav" aria-label="Secciones del segmento">
                <a href="#resumen">Resumen</a>
                <a href="#incidencias">Incidencias <span class="count"><%= incidencias.size() %></span></a>
                <a href="#servicios">Servicios y clientes <span class="count"><%= servicios.size() %></span></a>
                <a href="#mantenimiento">Mantenimiento <span class="count"><%= mantenimientos.size() %></span></a>
                <a href="#historico">Histórico</a>
            </nav>

            <section id="resumen" class="stats">
                <div class="stat ">
                    <span class="stat-label">Capacidad total</span>
                    <span class="stat-value"><%= numero(seg.getCapacidadTotal()) %> <small>Gbps</small></span>
                    <span class="small">Del segmento</span>
                </div>
                <div class="stat info">
                    <span class="stat-label">Utilizada</span>
                    <span class="stat-value"><%= numero(seg.getCapacidadUtilizada()) %> <small>Gbps</small></span>
                    <span class="small"><%= decimal(seg.getPorcentajeUso()) %>% del total</span>
                </div>
                <div class="stat warn">
                    <span class="stat-label">Reservada</span>
                    <span class="stat-value"><%= numero(seg.getCapacidadReservada()) %> <small>Gbps</small></span>
                    <span class="small">Para solicitudes aprobadas</span>
                </div>
                <div class="stat ok">
                    <span class="stat-label">Disponible</span>
                    <span class="stat-value"><%= numero(seg.getCapacidadDisponible()) %> <small>Gbps</small></span>
                    <span class="small">Ocupación <%= decimal(seg.getPorcentajeOcupacion()) %>% · nivel <%= seg.getNivelUso().toLowerCase() %></span>
                </div>
            </section>

            <% if (!"Operativo".equals(seg.getEstado()) || activas > 0) { %>
            <div class="alert warn">
                <strong>Segmento <%= seg.getEstado().toLowerCase() %></strong>
                Tiene <%= activas %> incidencia<%= activas == 1 ? "" : "s" %> activa<%= activas == 1 ? "" : "s" %>;
                los <%= servicios.size() %> servicios que lo usan pueden presentar afectación.
            </div>
            <% } %>

            <section id="incidencias" class="card">
                <div class="card-header">
                    <h2>Incidencias del segmento</h2>
                    <span class="small"><%= activas %> activas · <%= incidencias.size() %> en total</span>
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
                        </tr>
                        </thead>
                        <tbody>
                        <% if (incidencias.isEmpty()) { %>
                        <tr><td colspan="5" class="small">El segmento no tiene incidencias registradas.</td></tr>
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
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <section id="servicios" class="card">
                <div class="card-header">
                    <h2>Servicios y clientes que usan el segmento</h2>
                    <span class="small"><%= servicios.size() %> servicios · <%= clientesDistintos.size() %> clientes</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Servicio</th>
                            <th>Cliente</th>
                            <th>Ruta</th>
                            <th class="num">Gbps</th>
                            <th>Estado</th>
                            <th>Impacto</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (servicios.isEmpty()) { %>
                        <tr><td colspan="6" class="small">Ningún servicio usa este segmento.</td></tr>
                        <% } %>
                        <% for (ServicioAfectado sa : servicios) { %>
                        <tr>
                            <td class="cell-main"><%= codigo("SRV", sa.getIdServicio()) %></td>
                            <td>
                                <%= texto(sa.getRazonSocial()) %>
                                <span class="cell-sub">RUC <%= sa.getRuc() %></span>
                            </td>
                            <td><%= sa.getCodigoRuta() %></td>
                            <td class="num"><%= numero(sa.getCapacidadContratada()) %></td>
                            <td><span class="badge <%= "Activo".equals(sa.getEstado()) ? "green" : "blue" %>"><%= sa.getEstado() %></span></td>
                            <td><span class="badge <%= claseImpacto %>"><%= impacto %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <% if (!rutas.isEmpty()) { %>
                <p class="small form-note">Rutas que incluyen el segmento: <%= String.join(", ", rutas) %>.</p>
                <% } %>
            </section>

            <section id="mantenimiento" class="card">
                <div class="card-header">
                    <h2>Mantenimientos del segmento</h2>
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
                        <% if (mantenimientos.isEmpty()) { %>
                        <tr><td colspan="6" class="small">El segmento no tiene mantenimientos.</td></tr>
                        <% } %>
                        <% for (Mantenimiento m : mantenimientos) { %>
                        <%@ include file="filaMantenimiento.jspf" %>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <section id="historico" class="card">
                <div class="card-header">
                    <h2>Histórico de utilización</h2>
                    <span class="small"><%= historial.isEmpty() ? "Sin registros" : mes(historial.get(0).getFecha()) + " – " + mes(historial.get(historial.size() - 1).getFecha()) %> · Gbps utilizados</span>
                </div>
                <% if (historial.isEmpty()) { %>
                <p class="small">El segmento todavía no tiene registros mensuales en UTILIZACION_HIST.</p>
                <% } else { %>
                <div class="vbars">
                    <% for (UtilizacionHist u : historial) { %>
                    <div class="vbar ">
                        <span class="vbar-value"><%= numero(u.getCapacidadUtilizada()) %></span>
                        <span class="vbar-fill" style="height: <%= ancho(u.getCapacidadUtilizada(), maxHist) %>"></span>
                        <span class="vbar-label"><%= mes(u.getFecha()).substring(0, 3) %></span>
                    </div>
                    <% } %>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Mes</th>
                            <th class="num">Utilizada (Gbps)</th>
                            <th class="num">Libre (Gbps)</th>
                            <th>Uso</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% for (UtilizacionHist u : historial) { %>
                        <tr>
                            <td><%= mes(u.getFecha()) %></td>
                            <td class="num"><%= numero(u.getCapacidadUtilizada()) %></td>
                            <td class="num"><%= numero(u.getCapacidadDisponible()) %></td>
                            <td><%= barraUso(u.getPorcentajeUso()) %></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <% } %>
            </section>
        </main>

    </div>

</body>
</html>
