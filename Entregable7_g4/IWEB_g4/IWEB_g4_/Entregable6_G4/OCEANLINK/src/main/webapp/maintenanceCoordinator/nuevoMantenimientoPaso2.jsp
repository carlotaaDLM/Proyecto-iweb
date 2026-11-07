<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Segmento" %>
<%@ page import="dao.MantenimientoDAO" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";
    int pasoActual = 2;

    String error = (String) request.getAttribute("error");

    List<LandingStation> landings = (List<LandingStation>) request.getAttribute("landingsDisponibles");
    if (landings == null) landings = new ArrayList<>();
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentosDisponibles");
    if (segmentos == null) segmentos = new ArrayList<>();

    // Lo que ya se eligió (si se vuelve desde el paso 3)
    String[] estacionesElegidas = (String[]) session.getAttribute("mantEstaciones");
    String[] segmentosElegidos = (String[]) session.getAttribute("mantSegmentos");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Nuevo mantenimiento | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/maintenanceCoordinator/mantenimiento.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="nuevo"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=paso1">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a los datos generales
        </a>

        <div class="topbar">
            <div>
                <h1>Nuevo mantenimiento</h1>
                <p class="small">Elige las Landing Stations y los segmentos donde se realizará el mantenimiento.</p>
            </div>
        </div>

        <%@ include file="pasos.jspf" %>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa la selección</strong> <%= texto(error) %></div>
        <% } %>

        <form action="<%= servlet %>" class="card" method="post">
            <input type="hidden" name="action" value="guardarPaso2">

            <fieldset>
                <legend>Segmentos de fibra submarina</legend>
                <span class="hint" style="margin: 0 0 8px">Marca uno o más segmentos. Los que ya tienen un mantenimiento
                    programado o en ejecución no se pueden elegir.</span>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th class="check"></th>
                            <th>Segmento</th>
                            <th>Tramo</th>
                            <th>Estado actual</th>
                            <th class="num">Servicios</th>
                            <th>Mantenimiento asignado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% for (Segmento s : segmentos) {
                            boolean ocupado = MantenimientoDAO.pendiente(s.getEstadoMantenimiento());
                            String id = "seg-" + s.getCodigoSegmento();
                        %>
                        <tr class="<%= ocupado ? "ocupado" : "" %>">
                            <td class="check">
                                <input id="<%= id %>" name="segmentos" type="checkbox" value="<%= s.getCodigoSegmento() %>"
                                       <%= ocupado ? "disabled" : (contiene(segmentosElegidos, s.getCodigoSegmento()) ? "checked" : "") %>/>
                            </td>
                            <td class="cell-main"><label for="<%= id %>" style="margin: 0"><%= s.getCodigoSegmento() %></label></td>
                            <td class="tramo"><%= s.getTramo() %></td>
                            <td><span class="badge <%= claseEstadoSegmento(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                            <td class="num"><%= s.getCantidadServicios() %></td>
                            <td>
                                <% if (ocupado) { %>
                                <span class="badge <%= claseEstadoMnt(s.getEstadoMantenimiento()) %>"><%= s.getCodigoMantenimiento() %> · <%= s.getEstadoMantenimiento() %></span>
                                <% } else { %>
                                <span class="small">Disponible</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </fieldset>

            <fieldset>
                <legend>Landing Stations</legend>
                <span class="hint" style="margin: 0 0 8px">Al elegir una estación se consideran afectados los servicios de
                    los segmentos que salen o llegan a ella.</span>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th class="check"></th>
                            <th>Estación</th>
                            <th>Ubicación</th>
                            <th>Estado actual</th>
                            <th>Mantenimiento asignado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% for (LandingStation ls : landings) {
                            boolean ocupada = MantenimientoDAO.pendiente(ls.getEstadoMantenimiento());
                            String id = "ls-" + ls.getIdLanding();
                        %>
                        <tr class="<%= ocupada ? "ocupado" : "" %>">
                            <td class="check">
                                <input id="<%= id %>" name="landingStations" type="checkbox" value="<%= ls.getIdLanding() %>"
                                       <%= ocupada ? "disabled" : (contiene(estacionesElegidas, ls.getIdLanding()) ? "checked" : "") %>/>
                            </td>
                            <td class="cell-main">
                                <label for="<%= id %>" style="margin: 0"><%= ls.getIdLanding() %></label>
                                <span class="cell-sub"><%= texto(ls.getNombre()) %></span>
                            </td>
                            <td><%= texto(ls.getCiudad()) %>, <%= texto(ls.getPais()) %></td>
                            <td><span class="badge <%= claseEstadoSegmento(ls.getEstado()) %>"><%= ls.getEstado() %></span></td>
                            <td>
                                <% if (ocupada) { %>
                                <span class="badge <%= claseEstadoMnt(ls.getEstadoMantenimiento()) %>"><%= ls.getCodigoMantenimiento() %> · <%= ls.getEstadoMantenimiento() %></span>
                                <% } else { %>
                                <span class="small">Disponible</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </fieldset>

            <div class="footer-action">
                <a class="ghost" href="<%= servlet %>?action=cancelarRegistro">Cancelar</a>
                <a class="secondary" href="<%= servlet %>?action=paso1">Atrás</a>
                <button class="primary" type="submit">Continuar</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
