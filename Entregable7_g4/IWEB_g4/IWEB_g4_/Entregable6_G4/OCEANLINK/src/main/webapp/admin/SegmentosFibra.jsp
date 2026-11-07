<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Paginacion" %>
<%@ page import="beans.Segmento" %>
<%@ include file="badges.jspf" %>
<%
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    List<LandingStation> landings = (List<LandingStation>) request.getAttribute("landings");
    List<String> estados = (List<String>) request.getAttribute("estados");
    double[] capacidadRed = (double[]) request.getAttribute("capacidadRed");

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    String landing = request.getAttribute("landing") == null ? "" : (String) request.getAttribute("landing");

    String servlet = request.getContextPath() + "/SegmentoServlet";
    String listar = servlet + "?action=lista";

    // Mensaje que dejó el Servlet en sesión: se muestra una sola vez y se borra (F5 no lo repite)
    String msg = (String) session.getAttribute("msg");
    session.removeAttribute("msg");
    String idMsg = session.getAttribute("idMsg") == null ? "" : (String) session.getAttribute("idMsg");
    session.removeAttribute("idMsg");

    // estado, clase de la tarjeta, texto
    String[][] tarjetas = {
            {"Operativo", "ok", "Funcionan con normalidad"},
            {"Degradado", "warn", "Rendimiento afectado"},
            {"En mantenimiento", "info", "Intervención en curso"},
            {"Fuera de servicio", "bad", "Sin servicio"}
    };
    double ocupacionRed = capacidadRed[0] <= 0 ? 0 : (capacidadRed[1] + capacidadRed[2]) * 100 / capacidadRed[0];
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Segmentos de fibra | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="segmentos"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Segmentos de fibra</h1>
                <p class="small">Tramos de cable submarino entre dos Landing Stations y su capacidad.
                    Red: <%= numero(capacidadRed[0]) %> Gbps · <%= decimal(ocupacionRed) %>% ocupada.</p>
            </div>
            <a class="primary" href="<%= servlet %>?action=formCrear">Nuevo segmento</a>
        </div>

        <% if ("creado".equals(msg)) { %>
        <div class="alert ok"><strong>Segmento <%= texto(idMsg) %> registrado</strong> Quedó Operativo y sin capacidad utilizada.</div>
        <% } else if ("actualizado".equals(msg)) { %>
        <div class="alert ok"><strong>Cambios guardados</strong> Se actualizó el segmento <%= texto(idMsg) %>.</div>
        <% } else if ("eliminado".equals(msg)) { %>
        <div class="alert ok"><strong>Segmento eliminado</strong> Se eliminó el segmento <%= texto(idMsg) %>.</div>
        <% } else if ("noEliminado".equals(msg)) { %>
        <div class="alert warn"><strong>No se eliminó el segmento <%= texto(idMsg) %></strong>
            Lo usan rutas, incidencias, reservas o su histórico. Puedes dejarlo Fuera de servicio desde Editar.</div>
        <% } %>

        <section class="stats">
            <% for (String[] t : tarjetas) { %>
            <a class="stat <%= t[1] %><%= t[0].equals(estado) ? " selected" : "" %>" href="<%= listar %>&estado=<%= url(t[0]) %>">
                <span class="stat-label"><%= t[0] %></span>
                <span class="stat-value"><%= request.getAttribute("total" + t[0].replace(" ", "")) %></span>
                <span class="small"><%= t[2] %></span>
            </a>
            <% } %>
        </section>

        <form action="<%= servlet %>" class="card filters" method="get">
            <input type="hidden" name="action" value="lista"/>
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input id="buscar" name="buscar" placeholder="Código o estación" type="text" value="<%= texto(buscar) %>"/>
            </div>
            <div class="col">
                <label for="estado">Estado</label>
                <select id="estado" name="estado">
                    <option value="">Todos</option>
                    <% for (String e : estados) { %>
                    <option <%= e.equals(estado) ? "selected" : "" %>><%= e %></option>
                    <% } %>
                </select>
            </div>
            <div class="col">
                <label for="landing">Landing Station</label>
                <select id="landing" name="landing">
                    <option value="">Todas</option>
                    <% for (LandingStation ls : landings) { %>
                    <option value="<%= ls.getIdLanding() %>" <%= ls.getIdLanding().equals(landing) ? "selected" : "" %>>
                        <%= ls.getIdLanding() %> · <%= texto(ls.getNombre()) %>
                    </option>
                    <% } %>
                </select>
            </div>
            <div class="col-action botones">
                <a class="ghost" href="<%= listar %>">Limpiar</a>
                <button class="primary" type="submit">Buscar</button>
            </div>
        </form>

        <section class="card">
            <div class="card-header">
                <h2>Segmentos registrados</h2>
                <span class="small"><%= paginacion.getTotalRegistros() %> segmentos</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Código</th>
                        <th>Tramo</th>
                        <th class="num">Capacidad (Gbps)</th>
                        <th>Ocupación</th>
                        <th class="num">Servicios</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (segmentos.isEmpty()) { %>
                    <tr><td colspan="7" class="small">No se encontraron segmentos para los filtros seleccionados.</td></tr>
                    <% } %>
                    <% for (Segmento s : segmentos) {
                        double ocupacion = s.getPorcentajeOcupacion(); %>
                    <tr>
                        <td class="cell-main"><%= s.getCodigoSegmento() %></td>
                        <td class="tramo">
                            <%= s.getTramo() %>
                            <span class="cell-sub"><%= s.getIdOrigen() %> → <%= s.getIdDestino() %></span>
                        </td>
                        <td class="num"><%= numero(s.getCapacidadTotal()) %></td>
                        <td>
                            <div class="usage <%= claseUso(ocupacion) %>"
                                 title="<%= numero(s.getCapacidadUtilizada()) %> utilizados y <%= numero(s.getCapacidadReservada()) %> reservados de <%= numero(s.getCapacidadTotal()) %> Gbps">
                                <div class="usage-bar"><span style="width: <%= Math.min(100, ocupacion) %>%"></span></div>
                                <span class="usage-value"><%= decimal(ocupacion) %>%</span>
                            </div>
                        </td>
                        <td class="num"><%= s.getCantidadServicios() %></td>
                        <td><span class="badge <%= claseEstado(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                        <td>
                            <div class="botones">
                                <a href="<%= servlet %>?action=editar&id=<%= url(s.getCodigoSegmento()) %>" class="ghost btn-sm">Editar</a>
                                <% if (s.getDependencias() == 0) { %>
                                <a href="#eliminar-<%= s.getCodigoSegmento() %>" class="danger btn-sm">Eliminar</a>
                                <% } else { %>
                                <button type="button" class="danger btn-sm" disabled
                                        title="Lo usan rutas, incidencias, reservas o su histórico">Eliminar</button>
                                <% } %>
                            </div>
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

        <section class="card">
            <div class="card-header">
                <h2>Estados de un segmento</h2>
            </div>
            <div class="legend">
                <div><span class="badge green">Operativo</span><p>Funciona con normalidad.</p></div>
                <div><span class="badge yellow">Degradado</span><p>Capacidad reducida o rendimiento afectado.</p></div>
                <div><span class="badge blue">En mantenimiento</span><p>Intervención programada en curso.</p></div>
                <div><span class="badge red">Fuera de servicio</span><p>No disponible por falla o corte.</p></div>
            </div>
            <p class="small table-note">
                La barra de ocupación (utilizado + reservado) se pone amarilla desde el 80% y roja por encima del 95%.
            </p>
        </section>
    </main>
</div>

<%-- Confirmación para eliminar (se abre con el enlace #eliminar-..., sin JavaScript) --%>
<% for (Segmento s : segmentos) {
    if (s.getDependencias() > 0) continue; %>
<div id="eliminar-<%= s.getCodigoSegmento() %>" class="overlay">
    <div class="modal">
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="borrar">
            <input type="hidden" name="codigo_segmento" value="<%= s.getCodigoSegmento() %>">
            <h2>¿Eliminar el segmento <%= s.getCodigoSegmento() %>?</h2>
            <p>El tramo <%= s.getTramo() %> dejará de existir. Esta acción no se puede deshacer.</p>
            <div class="botones">
                <a href="#" class="ghost">Cancelar</a>
                <button type="submit" class="danger solid">Eliminar segmento</button>
            </div>
        </form>
    </div>
</div>
<% } %>

</body>
</html>
