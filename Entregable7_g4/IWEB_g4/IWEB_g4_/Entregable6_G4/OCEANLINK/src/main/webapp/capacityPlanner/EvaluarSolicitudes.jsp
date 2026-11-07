<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.SolicitudCapacidad" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<SolicitudCapacidad> solicitudes = (List<SolicitudCapacidad>) request.getAttribute("solicitudes");
    if (solicitudes == null) solicitudes = new ArrayList<>();

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    String msg = (String) request.getAttribute("msg");
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");

    String servlet = request.getContextPath() + "/CapacityPlannerServlet";

    String[] estados = {"Registrada", "En evaluación", "Aprobada", "Provisionada", "Activa",
            "Rechazada", "Pendiente por capacidad"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Evaluar solicitudes | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/capacityPlanner/capacityPlanner.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="listarSolicitudes"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Evaluar solicitudes</h1>
                <p class="small">Revisa la capacidad de la ruta de cada solicitud y decide si se aprueba, queda pendiente o se rechaza.</p>
            </div>
            <a href="<%= servlet %>?action=formRegistrar" class="primary">Nueva solicitud</a>
        </div>

        <% if ("borrada".equals(msg)) { %>
        <div class="alert ok"><strong>Solicitud eliminada</strong>Se eliminó la solicitud y su historial.</div>
        <% } else if ("noBorrada".equals(msg)) { %>
        <div class="alert error"><strong>No se pudo eliminar</strong>Solo se pueden eliminar solicitudes Registradas o Rechazadas.</div>
        <% } %>

        <section class="stats">
            <div class="stat info">
                <span class="stat-label">Por evaluar</span>
                <span class="stat-value"><%= request.getAttribute("porEvaluar") %></span>
                <span class="small">Registradas o en evaluación</span>
            </div>
            <a href="<%= servlet %>?action=listarSolicitudes&estado=<%= url("Pendiente por capacidad") %>" class="stat warn">
                <span class="stat-label">Pendientes por capacidad</span>
                <span class="stat-value"><%= request.getAttribute("pendientes") %></span>
                <span class="small">Esperan disponibilidad</span>
            </a>
            <a href="<%= servlet %>?action=listarSolicitudes&estado=Aprobada" class="stat ok">
                <span class="stat-label">Aprobadas</span>
                <span class="stat-value"><%= request.getAttribute("aprobadas") %></span>
                <span class="small"><%= request.getAttribute("porReservar") %> sin reserva de capacidad</span>
            </a>
            <a href="<%= servlet %>?action=listarSolicitudes&estado=Rechazada" class="stat bad">
                <span class="stat-label">Rechazadas</span>
                <span class="stat-value"><%= request.getAttribute("rechazadas") %></span>
                <span class="small">No continúan el flujo</span>
            </a>
        </section>

        <form class="card filters" method="get" action="<%= servlet %>">
            <input type="hidden" name="action" value="listarSolicitudes">
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input type="text" id="buscar" name="buscar" value="<%= texto(buscar) %>"
                       placeholder="Código, cliente, estación o ruta">
            </div>
            <div class="col">
                <label for="estado">Estado</label>
                <select id="estado" name="estado">
                    <option value="">Todos</option>
                    <% for (String e : estados) { %>
                    <option<%= sel(e.equals(estado)) %>><%= e %></option>
                    <% } %>
                </select>
            </div>
            <div class="col-action">
                <button type="submit" class="primary">Buscar</button>
            </div>
        </form>

        <section class="card">
            <div class="card-header">
                <h2>Solicitudes de capacidad</h2>
                <span class="small"><%= paginacion.getTotalRegistros() %> solicitudes</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Solicitud</th>
                        <th>Cliente</th>
                        <th>Origen → Destino</th>
                        <th class="num">Capacidad</th>
                        <th>Fecha requerida</th>
                        <th>Estado</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <% for (SolicitudCapacidad s : solicitudes) {
                        String est = s.getEstado();
                        String enlaceDetalle = servlet + "?action=detalleSolicitud&id=" + s.getIdSolicitud();
                    %>
                    <tr>
                        <td>
                            <span class="cell-main"><%= s.getCodigo() %></span>
                            <span class="cell-sub"><%= fecha(s.getFechaSolicitud()) %></span>
                        </td>
                        <td><%= texto(s.getRazonSocialCliente()) %></td>
                        <td>
                            <%= s.getTramo() %>
                            <span class="cell-sub"><%= s.getCodigoRuta() == null ? "Ruta por calcular" : s.getCodigoRuta() %></span>
                        </td>
                        <td class="num"><%= numero(s.getCapacidadRequerida()) %> Gbps</td>
                        <td><%= fecha(s.getFechaRequerida()) %></td>
                        <td><span class="badge <%= claseEstadoSolicitud(est) %>"><%= est %></span></td>
                        <td>
                            <% if ("Registrada".equals(est) || "En evaluación".equals(est) || "Pendiente por capacidad".equals(est)) { %>
                            <a href="<%= enlaceDetalle %>" class="primary btn-sm">Evaluar</a>
                            <% } else if ("Aprobada".equals(est) && !s.isReservada()) { %>
                            <a href="<%= servlet %>?action=formReservar&id=<%= s.getIdSolicitud() %>" class="secondary btn-sm">Reservar</a>
                            <% } else if ("Aprobada".equals(est)) { %>
                            <a href="<%= enlaceDetalle %>" class="secondary btn-sm">Provisionar</a>
                            <% } else { %>
                            <a href="<%= enlaceDetalle %>" class="ghost btn-sm">Ver</a>
                            <% } %>
                        </td>
                    </tr>
                    <% } %>
                    <% if (solicitudes.isEmpty()) { %>
                    <tr>
                        <td colspan="7" class="small">No hay solicitudes que coincidan con la búsqueda.</td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="solicitudes"/>
            </jsp:include>
            <p class="small table-note">
                Flujo: Registrada → En evaluación → Aprobada → Provisionada → Activa. También puede quedar Rechazada o Pendiente por capacidad.
            </p>
        </section>
    </main>
</div>

</body>
</html>
