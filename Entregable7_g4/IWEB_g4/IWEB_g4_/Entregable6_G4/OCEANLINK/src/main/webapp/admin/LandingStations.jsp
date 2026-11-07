<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<LandingStation> estaciones = (List<LandingStation>) request.getAttribute("estaciones");
    if (estaciones == null) estaciones = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    List<String> paises = (List<String>) request.getAttribute("paisesFiltro");
    List<String> estados = (List<String>) request.getAttribute("estados");

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String pais = request.getAttribute("pais") == null ? "" : (String) request.getAttribute("pais");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");

    String servlet = request.getContextPath() + "/LandingStationServlet";
    String listar = servlet + "?action=lista";

    // Mensaje que dejó el Servlet en sesión: se muestra una sola vez y se borra (F5 no lo repite)
    String msg = (String) session.getAttribute("msg");
    session.removeAttribute("msg");
    String idMsg = session.getAttribute("idMsg") == null ? "" : (String) session.getAttribute("idMsg");
    session.removeAttribute("idMsg");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Landing Stations | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="landing"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Landing Stations</h1>
                <p class="small">Puntos donde los cables submarinos se conectan con la red terrestre.</p>
            </div>
            <a class="primary" href="<%= servlet %>?action=formCrear">Registrar landing station</a>
        </div>

        <% if ("creada".equals(msg)) { %>
        <div class="alert ok"><strong>Landing Station <%= texto(idMsg) %> registrada</strong> Quedó Operativa y ya puede usarse en nuevos segmentos.</div>
        <% } else if ("actualizada".equals(msg)) { %>
        <div class="alert ok"><strong>Cambios guardados</strong> Se actualizó la estación <%= texto(idMsg) %>.</div>
        <% } else if ("eliminada".equals(msg)) { %>
        <div class="alert ok"><strong>Landing Station eliminada</strong> Se eliminó la estación <%= texto(idMsg) %>.</div>
        <% } else if ("noEliminada".equals(msg)) { %>
        <div class="alert warn"><strong>No se eliminó la estación <%= texto(idMsg) %></strong>
            Tiene segmentos, incidencias o solicitudes asociadas. Puedes dejarla Inactiva desde Editar.</div>
        <% } %>

        <section class="stats cols-3">
            <a class="stat ok<%= "Operativa".equals(estado) ? " selected" : "" %>" href="<%= listar %>&estado=Operativa">
                <span class="stat-label">Operativas</span>
                <span class="stat-value"><%= request.getAttribute("operativas") %></span>
                <span class="small">En funcionamiento</span>
            </a>
            <a class="stat info<%= "En mantenimiento".equals(estado) ? " selected" : "" %>" href="<%= listar %>&estado=<%= url("En mantenimiento") %>">
                <span class="stat-label">En mantenimiento</span>
                <span class="stat-value"><%= request.getAttribute("enMantenimiento") %></span>
                <span class="small">Intervención en curso</span>
            </a>
            <a class="stat<%= "Inactiva".equals(estado) ? " selected" : "" %>" href="<%= listar %>&estado=Inactiva">
                <span class="stat-label">Inactivas</span>
                <span class="stat-value"><%= request.getAttribute("inactivas") %></span>
                <span class="small">Fuera de operación</span>
            </a>
        </section>

        <form action="<%= servlet %>" class="card filters" method="get">
            <input type="hidden" name="action" value="lista"/>
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input id="buscar" name="buscar" placeholder="Código, nombre o ciudad" type="text" value="<%= texto(buscar) %>"/>
            </div>
            <div class="col">
                <label for="pais">País</label>
                <select id="pais" name="pais">
                    <option value="">Todos</option>
                    <% for (String p : paises) { %>
                    <option <%= p.equals(pais) ? "selected" : "" %>><%= texto(p) %></option>
                    <% } %>
                </select>
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
            <div class="col-action botones">
                <a class="ghost" href="<%= listar %>">Limpiar</a>
                <button class="primary" type="submit">Buscar</button>
            </div>
        </form>

        <section class="card">
            <div class="card-header">
                <h2>Estaciones registradas</h2>
                <span class="small"><%= paginacion.getTotalRegistros() %> estaciones</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Código</th>
                        <th>Nombre</th>
                        <th>Ciudad</th>
                        <th>País</th>
                        <th class="num">Segmentos</th>
                        <th class="num">Incidencias activas</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (estaciones.isEmpty()) { %>
                    <tr><td colspan="8" class="small">No se encontraron estaciones para los filtros seleccionados.</td></tr>
                    <% } %>
                    <% for (LandingStation ls : estaciones) { %>
                    <tr>
                        <td class="cell-main"><%= ls.getIdLanding() %></td>
                        <td><%= texto(ls.getNombre()) %></td>
                        <td><%= texto(ls.getCiudad()) %></td>
                        <td><%= texto(ls.getPais()) %></td>
                        <td class="num">
                            <a class="cell-link" href="<%= request.getContextPath() %>/SegmentoServlet?action=lista&landing=<%= url(ls.getIdLanding()) %>"><%= ls.getCantidadSegmentos() %></a>
                        </td>
                        <td class="num"><%= ls.getIncidenciasActivas() %></td>
                        <td><span class="badge <%= claseEstado(ls.getEstado()) %>"><%= ls.getEstado() %></span></td>
                        <td>
                            <div class="botones">
                                <a href="<%= servlet %>?action=editar&id=<%= url(ls.getIdLanding()) %>" class="ghost btn-sm">Editar</a>
                                <% if (ls.getDependencias() == 0) { %>
                                <a href="#eliminar-<%= ls.getIdLanding() %>" class="danger btn-sm">Eliminar</a>
                                <% } else { %>
                                <button type="button" class="danger btn-sm" disabled
                                        title="Tiene segmentos, incidencias o solicitudes asociadas">Eliminar</button>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="estaciones"/>
            </jsp:include>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Estados de una estación</h2>
            </div>
            <div class="legend cols-3">
                <div><span class="badge green">Operativa</span><p>Funciona con normalidad.</p></div>
                <div><span class="badge blue">En mantenimiento</span><p>Intervención programada en curso.</p></div>
                <div><span class="badge grey">Inactiva</span><p>Fuera de operación. No se usa en nuevas rutas.</p></div>
            </div>
            <p class="small table-note">
                Solo se puede eliminar una estación que nadie usa. Si ya tiene segmentos o incidencias, déjala Inactiva.
            </p>
        </section>
    </main>
</div>

<%-- Confirmación para eliminar (se abre con el enlace #eliminar-..., sin JavaScript) --%>
<% for (LandingStation ls : estaciones) {
    if (ls.getDependencias() > 0) continue; %>
<div id="eliminar-<%= ls.getIdLanding() %>" class="overlay">
    <div class="modal">
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="borrar">
            <input type="hidden" name="id_landing" value="<%= ls.getIdLanding() %>">
            <h2>¿Eliminar la estación <%= ls.getIdLanding() %>?</h2>
            <p><%= texto(ls.getNombre()) %> (<%= texto(ls.getCiudad()) %>, <%= texto(ls.getPais()) %>) dejará de existir.
                Esta acción no se puede deshacer.</p>
            <div class="botones">
                <a href="#" class="ghost">Cancelar</a>
                <button type="submit" class="danger solid">Eliminar estación</button>
            </div>
        </form>
    </div>
</div>
<% } %>

</body>
</html>
