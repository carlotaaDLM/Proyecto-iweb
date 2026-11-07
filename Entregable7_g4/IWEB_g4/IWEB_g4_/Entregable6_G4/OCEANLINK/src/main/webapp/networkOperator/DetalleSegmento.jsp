<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Servicio" %>
<%@ page import="beans.Incidencia" %>
<%@ include file="badges.jspf" %>
<%
    Segmento seg = (Segmento) request.getAttribute("segmento");

    List<Servicio> servicios = (List<Servicio>) request.getAttribute("servicios");
    if (servicios == null) servicios = new ArrayList<>();

    List<String> rutas = (List<String>) request.getAttribute("rutas");
    if (rutas == null) rutas = new ArrayList<>();

    List<Incidencia> incidencias = (List<Incidencia>) request.getAttribute("incidencias");
    if (incidencias == null) incidencias = new ArrayList<>();

    String servlet = request.getContextPath() + "/NetworkOperatorServlet";
    String tramo = seg.getTramo();
    double total = seg.getCapacidadTotal();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Detalle del segmento | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/networkOperator/networkOperator.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="estadoSegmentos"/>
</jsp:include>

    <main class="content">
        <a href="<%= servlet %>?action=estadoSegmentos" class="back-link">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
            Volver a estado de segmentos
        </a>

        <div class="topbar">
            <div>
                <h1>Detalle del segmento</h1>
                <p class="small">Capacidad, servicios que lo usan e incidencias relacionadas.</p>
            </div>
            <a href="<%= servlet %>?action=formRegistrar&segmento=<%= url(seg.getCodigoSegmento()) %>" class="primary">Registrar incidencia</a>
        </div>

        <section class="card">
            <div class="record-head">
                <div>
                    <span class="stat-label">Segmento</span>
                    <span class="big"><%= seg.getCodigoSegmento() %></span>
                    <span class="small"><%= tramo %></span>
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

        <section class="stats">
            <div class="stat">
                <span class="stat-label">Capacidad total</span>
                <span class="stat-value"><%= numero(total) %> <small>Gbps</small></span>
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
                <span class="small"><%= decimal(total > 0 ? seg.getCapacidadDisponible() * 100 / total : 0) %>% del total</span>
            </div>
        </section>

        <% if ("Fuera de servicio".equals(seg.getEstado())) { %>
        <div class="alert error">
            <strong>Segmento fuera de servicio</strong>
            Los servicios que usan este segmento están interrumpidos y no pueden activarse servicios nuevos hasta su reparación.
        </div>
        <% } else if ("Degradado".equals(seg.getEstado())) { %>
        <div class="alert warn">
            <strong>Segmento degradado</strong>
            El rendimiento de los servicios que usan este segmento puede verse afectado.
        </div>
        <% } else if ("En mantenimiento".equals(seg.getEstado())) { %>
        <div class="alert info">
            <strong>Segmento en mantenimiento</strong>
            Hay una intervención programada sobre este segmento.
        </div>
        <% } %>

        <div class="split">
            <section class="card">
                <div class="card-header">
                    <h2>Servicios que usan el segmento</h2>
                    <span class="small"><%= servicios.size() %> servicios</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Servicio</th>
                            <th>Cliente</th>
                            <th>Ruta</th>
                            <th class="num">Gbps</th>
                            <th>Situación</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (servicios.isEmpty()) { %>
                        <tr><td colspan="5" class="small">Ningún servicio usa este segmento.</td></tr>
                        <% } %>
                        <% for (Servicio s : servicios) {
                            String situacion = s.getEstado();
                            String clase = "Activo".equals(situacion) ? "green" : "blue";
                            if ("Activo".equals(s.getEstado()) && "Fuera de servicio".equals(seg.getEstado())) {
                                situacion = "Interrumpido";
                                clase = "red";
                            } else if ("Activo".equals(s.getEstado()) && "Degradado".equals(seg.getEstado())) {
                                situacion = "Degradado";
                                clase = "yellow";
                            }
                        %>
                        <tr>
                            <td class="cell-main"><%= String.format("SRV-%03d", s.getIdServicio()) %></td>
                            <td><%= s.getRazonSocialCliente() %></td>
                            <td><%= s.getCodigoRuta() %></td>
                            <td class="num"><%= numero(s.getCapacidadContratada()) %></td>
                            <td><span class="badge <%= clase %>"><%= situacion %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Rutas que lo incluyen</h2>
                </div>
                <div class="chips">
                    <% for (String ruta : rutas) { %>
                    <span class="chip"><%= ruta %></span>
                    <% } %>
                    <% if (rutas.isEmpty()) { %>
                    <span class="small">Ninguna ruta incluye este segmento.</span>
                    <% } %>
                </div>
                <p class="small form-note">Si el segmento falla, todos los servicios de estas rutas se ven afectados.</p>
            </section>
        </div>

        <section class="card">
            <div class="card-header">
                <h2>Incidencias relacionadas</h2>
                <span class="small"><%= incidencias.size() %> incidencias</span>
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
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (incidencias.isEmpty()) { %>
                    <tr><td colspan="6" class="small">Este segmento no tiene incidencias registradas.</td></tr>
                    <% } %>
                    <% for (Incidencia inc : incidencias) {
                        String detalle = servlet + "?action=detalleIncidencia&codigo=" + url(inc.getCodigoIncidencia());
                    %>
                    <tr>
                        <td class="cell-main"><a href="<%= detalle %>" class="cell-link"><%= inc.getCodigoIncidencia() %></a></td>
                        <td>
                            <%= texto(inc.getTitulo()) %>
                            <span class="cell-sub"><%= seg.getCodigoSegmento() %> · <%= tramo %></span>
                        </td>
                        <td><span class="badge <%= claseSeveridad(inc.getSeveridad()) %>"><%= inc.getSeveridad() %></span></td>
                        <td><span class="badge <%= claseEstadoIncidencia(inc.getEstado()) %>"><%= inc.getEstado() %></span></td>
                        <td class="date"><%= inc.getFechaDeteccion() %></td>
                        <td><a href="<%= detalle %>" class="ghost btn-sm">Ver detalle</a></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </section>
    </main>
</div>

</body>
</html>
