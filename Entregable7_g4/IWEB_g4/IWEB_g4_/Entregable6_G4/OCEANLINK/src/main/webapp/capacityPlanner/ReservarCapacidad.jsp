<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Ruta" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.SolicitudCapacidad" %>
<%@ include file="badges.jspf" %>
<%
    List<SolicitudCapacidad> porReservar = (List<SolicitudCapacidad>) request.getAttribute("porReservar");
    if (porReservar == null) porReservar = new ArrayList<>();

    SolicitudCapacidad sol = (SolicitudCapacidad) request.getAttribute("solicitud");
    Ruta ruta = (Ruta) request.getAttribute("ruta");
    String error = (String) request.getAttribute("error");

    String servlet = request.getContextPath() + "/CapacityPlannerServlet";

    // Se puede reservar si todos los segmentos tienen la capacidad pedida (regla 1)
    boolean sePuede = sol != null && ruta != null && !ruta.isTieneSegmentoFueraServicio()
            && ruta.getCapacidadDisponible() >= sol.getCapacidadRequerida();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Reservar capacidad | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/capacityPlanner/capacityPlanner.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="formReservar"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Reservar capacidad</h1>
                <p class="small">Reserva en cada segmento de la ruta la capacidad de una solicitud aprobada.</p>
            </div>
        </div>

        <div class="alert info">
            Solo las solicitudes <strong style="display: inline">Aprobadas</strong> pueden reservar capacidad.
            Sin reserva, una solicitud no puede pasar a Provisionada.
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>No se pudo reservar</strong><%= texto(error) %></div>
        <% } %>

        <% if (sol == null) { %>
        <section class="card">
            <p class="small">No hay solicitudes Aprobadas pendientes de reserva.
                <a class="cell-link" href="<%= servlet %>?action=listarSolicitudes">Ver solicitudes</a></p>
        </section>
        <% } else { %>

        <form class="card filters" method="get" action="<%= servlet %>">
            <input type="hidden" name="action" value="formReservar">
            <div class="col col-wide">
                <label for="solicitud">Solicitud aprobada</label>
                <select id="solicitud" name="id">
                    <% for (SolicitudCapacidad s : porReservar) { %>
                    <option value="<%= s.getIdSolicitud() %>"<%= sel(s.getIdSolicitud() == sol.getIdSolicitud()) %>>
                        <%= s.getCodigo() %> · <%= texto(s.getRazonSocialCliente()) %> · <%= numero(s.getCapacidadRequerida()) %> Gbps
                    </option>
                    <% } %>
                </select>
            </div>
            <div class="col-action">
                <button type="submit" class="primary">Cargar</button>
            </div>
        </form>

        <div class="split even">
            <section class="card">
                <div class="card-header">
                    <h2>Resumen de la solicitud</h2>
                    <span class="badge green">Aprobada</span>
                </div>
                <dl class="kv">
                    <div><dt>Solicitud</dt><dd><a class="cell-link" href="<%= servlet %>?action=detalleSolicitud&id=<%= sol.getIdSolicitud() %>"><%= sol.getCodigo() %></a></dd></div>
                    <div><dt>Cliente</dt><dd><%= texto(sol.getRazonSocialCliente()) %></dd></div>
                    <div><dt>Registrada por</dt><dd><%= sol.getNombreUsuario() == null ? "—" : texto(sol.getNombreUsuario()) %></dd></div>
                    <div><dt>Fecha de solicitud</dt><dd><%= fecha(sol.getFechaSolicitud()) %></dd></div>
                    <div><dt>Fecha requerida</dt><dd><%= fecha(sol.getFechaRequerida()) %></dd></div>
                    <div><dt>Capacidad a reservar</dt><dd><%= numero(sol.getCapacidadRequerida()) %> Gbps</dd></div>
                    <div><dt>Observaciones</dt><dd><%= sol.getObservaciones() == null ? "—" : texto(sol.getObservaciones()) %></dd></div>
                </dl>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Ruta seleccionada</h2>
                    <span class="small"><%= ruta == null ? 0 : ruta.getSegmentos().size() %> segmentos</span>
                </div>
                <% if (ruta == null) { %>
                <p class="small">La solicitud no tiene ruta asignada.</p>
                <% } else { %>
                <p class="route-title"><%= ruta.getCodigo() %></p>
                <p class="small" style="margin: 0"><%= ruta.getTramo() %> · disponible en la ruta: <%= numero(ruta.getCapacidadDisponible()) %> Gbps</p>
                <div class="route-line">
                    <div class="route-node"><span></span><strong><%= ruta.getSegmentos().get(0).getIdOrigen().replace("LS-", "") %></strong>
                        <small><%= ruta.getSegmentos().get(0).getNombreOrigen().replace("Estación ", "") %></small></div>
                    <% for (Segmento s : ruta.getSegmentos()) { %>
                    <div class="route-node"><span></span><strong><%= s.getIdDestino().replace("LS-", "") %></strong>
                        <small><%= s.getNombreDestino().replace("Estación ", "") %></small></div>
                    <% } %>
                </div>
                <% } %>
            </section>
        </div>

        <% if (ruta != null) { %>
        <section class="card">
            <div class="card-header">
                <h2>Segmentos de la ruta</h2>
                <span class="small">Se reserva la misma capacidad en todos los segmentos · ocupación = utilizada + reservada</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th class="num">#</th>
                        <th>Segmento</th>
                        <th>Tramo</th>
                        <th class="num">Disponible</th>
                        <th class="num">A reservar</th>
                        <th>Ocupación actual</th>
                        <th class="num">Tras la reserva</th>
                        <th>Validación</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% int orden = 1;
                       for (Segmento s : ruta.getSegmentos()) {
                           double tras = s.getCapacidadTotal() <= 0 ? 0
                                   : (s.getCapacidadUtilizada() + s.getCapacidadReservada() + sol.getCapacidadRequerida())
                                     * 100.0 / s.getCapacidadTotal();
                           boolean fuera = "Fuera de servicio".equals(s.getEstado());
                           boolean alcanza = s.getCapacidadDisponible() >= sol.getCapacidadRequerida();
                    %>
                    <tr>
                        <td class="num"><%= orden++ %></td>
                        <td class="cell-main"><%= s.getCodigoSegmento() %></td>
                        <td class="tramo"><%= s.getTramo() %></td>
                        <td class="num"><%= numero(s.getCapacidadDisponible()) %></td>
                        <td class="num"><%= numero(sol.getCapacidadRequerida()) %></td>
                        <td><%= barraUso(s.getPorcentajeOcupacion()) %></td>
                        <td class="num"><%= alcanza ? decimal(tras) + "%" : "—" %></td>
                        <td>
                            <% if (fuera) { %>
                            <span class="badge red">Fuera de servicio</span>
                            <% } else if (!alcanza) { %>
                            <span class="badge red">Excede lo disponible</span>
                            <% } else if (tras > 95) { %>
                            <span class="badge red">OK · utilización crítica</span>
                            <% } else if (tras >= 80) { %>
                            <span class="badge yellow">OK · alta utilización</span>
                            <% } else { %>
                            <span class="badge green">OK</span>
                            <% } %>
                        </td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <div class="footer-action" style="margin-top: 16px">
                <a href="<%= servlet %>?action=listarSolicitudes" class="ghost">Cancelar</a>
                <% if (sePuede) { %>
                <a href="#dialogoReserva" class="primary">Confirmar reserva</a>
                <% } else { %>
                <button type="button" class="primary" disabled>Confirmar reserva</button>
                <% } %>
            </div>
        </section>
        <% } %>
        <% } %>
    </main>
</div>

<% if (sePuede) { %>
<div id="dialogoReserva" class="overlay"><div class="modal">
    <form method="post" action="<%= servlet %>">
        <input type="hidden" name="action" value="reservar">
        <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
        <h2>¿Confirmar la reserva?</h2>
        <p>La capacidad quedará reservada para <%= sol.getCodigo() %> y no estará disponible para otras solicitudes.</p>
        <dl class="kv">
            <div><dt>Cliente</dt><dd><%= texto(sol.getRazonSocialCliente()) %></dd></div>
            <div><dt>Ruta</dt><dd><%= ruta.getCodigo() %></dd></div>
            <div><dt>Capacidad</dt><dd><%= numero(sol.getCapacidadRequerida()) %> Gbps</dd></div>
            <div><dt>Segmentos</dt><dd><%= ruta.getSegmentos().size() %></dd></div>
        </dl>
        <div class="botones" style="margin-top: 20px">
            <a href="#" class="ghost">Cancelar</a>
            <button type="submit" class="primary">Confirmar reserva</button>
        </div>
    </form>
</div></div>
<% } %>

</body>
</html>
