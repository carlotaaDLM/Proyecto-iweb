<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Cliente" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<Cliente> clientes = (List<Cliente>) request.getAttribute("clientes");
    if (clientes == null) clientes = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");

    String servlet = request.getContextPath() + "/ClienteServlet";
    String listar = servlet + "?action=lista";

    // Mensaje que dejó el Servlet en sesión: se muestra una sola vez y se borra (F5 no lo repite)
    String msg = (String) session.getAttribute("msg");
    session.removeAttribute("msg");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Clientes | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="clientes"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Clientes</h1>
                <p class="small">Empresas que contratan capacidad. Aparecen al registrar una solicitud en el Capacity Planner.</p>
            </div>
            <a class="primary" href="<%= servlet %>?action=formCrear">Registrar cliente</a>
        </div>

        <% if ("creado".equals(msg)) { %>
        <div class="alert ok"><strong>Cliente registrado</strong> Ya aparece en la lista de clientes del Capacity Planner.</div>
        <% } else if ("actualizado".equals(msg)) { %>
        <div class="alert ok"><strong>Cambios guardados</strong> Se actualizaron los datos del cliente.</div>
        <% } else if ("eliminado".equals(msg)) { %>
        <div class="alert ok"><strong>Cliente eliminado</strong> Se eliminó el cliente.</div>
        <% } else if ("noEliminado".equals(msg)) { %>
        <div class="alert warn"><strong>No se eliminó el cliente</strong> Tiene solicitudes o servicios registrados.</div>
        <% } %>

        <form action="<%= servlet %>" class="card filters" method="get">
            <input type="hidden" name="action" value="lista"/>
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input id="buscar" name="buscar" placeholder="Razón social, RUC o correo" type="text" value="<%= texto(buscar) %>"/>
            </div>
            <div class="col-action botones">
                <a class="ghost" href="<%= listar %>">Limpiar</a>
                <button class="primary" type="submit">Buscar</button>
            </div>
        </form>

        <section class="card">
            <div class="card-header">
                <h2>Clientes registrados</h2>
                <span class="small"><%= paginacion.getTotalRegistros() %> clientes</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Razón social</th>
                        <th>RUC</th>
                        <th>Correo</th>
                        <th>Teléfono</th>
                        <th class="num">Solicitudes</th>
                        <th class="num">Servicios</th>
                        <th>Acciones</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (clientes.isEmpty()) { %>
                    <tr><td colspan="7" class="small">No se encontraron clientes.</td></tr>
                    <% } %>
                    <% for (Cliente c : clientes) {
                        boolean enUso = c.getCantidadSolicitudes() > 0 || c.getCantidadServicios() > 0; %>
                    <tr>
                        <td class="cell-main"><%= texto(c.getRazonSocial()) %></td>
                        <td><%= texto(c.getRuc()) %></td>
                        <td><%= texto(c.getCorreo()) %></td>
                        <td><%= c.getTelefono() == null ? "—" : texto(c.getTelefono()) %></td>
                        <td class="num"><%= c.getCantidadSolicitudes() %></td>
                        <td class="num"><%= c.getCantidadServicios() %></td>
                        <td>
                            <div class="botones">
                                <a href="<%= servlet %>?action=editar&id=<%= c.getIdCliente() %>" class="ghost btn-sm">Editar</a>
                                <% if (!enUso) { %>
                                <a href="#eliminar<%= c.getIdCliente() %>" class="danger btn-sm">Eliminar</a>
                                <% } else { %>
                                <button type="button" class="danger btn-sm" disabled
                                        title="Tiene solicitudes o servicios registrados">Eliminar</button>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="clientes"/>
            </jsp:include>
            <p class="small table-note">
                Solo se puede eliminar un cliente sin solicitudes ni servicios, para no perder su historial.
            </p>
        </section>
    </main>
</div>

<%-- Confirmación para eliminar (se abre con el enlace #eliminar..., sin JavaScript) --%>
<% for (Cliente c : clientes) {
    if (c.getCantidadSolicitudes() > 0 || c.getCantidadServicios() > 0) continue; %>
<div id="eliminar<%= c.getIdCliente() %>" class="overlay">
    <div class="modal">
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="borrar">
            <input type="hidden" name="id" value="<%= c.getIdCliente() %>">
            <h2>¿Eliminar el cliente?</h2>
            <p><%= texto(c.getRazonSocial()) %> (RUC <%= texto(c.getRuc()) %>) dejará de existir.
                Esta acción no se puede deshacer.</p>
            <div class="botones">
                <a href="#" class="ghost">Cancelar</a>
                <button type="submit" class="danger solid">Eliminar cliente</button>
            </div>
        </form>
    </div>
</div>
<% } %>

</body>
</html>
