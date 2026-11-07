<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="beans.Paginacion" %>
<%@ page import="beans.Usuario" %>
<%@ include file="badges.jspf" %>
<%
    ArrayList<Usuario> listaUsuarios = (ArrayList<Usuario>) request.getAttribute("lista");
    if (listaUsuarios == null) listaUsuarios = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String rolFiltro = request.getAttribute("rol") == null ? "" : (String) request.getAttribute("rol");
    String estadoFiltro = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");

    String servlet = request.getContextPath() + "/UsuarioServlet";
    String listar = servlet + "?action=lista";

    Usuario sesion = (Usuario) session.getAttribute("usuarioSesion");
    int dniSesion = sesion == null ? -1 : sesion.getDniUsuario();

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
    <title>Usuarios | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="usuarios"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Gestión de usuarios</h1>
                <p class="small">Cuentas de acceso a OceanLink y el rol con el que trabaja cada persona.</p>
            </div>
            <a class="primary" href="<%= servlet %>?action=formCrear">Nuevo usuario</a>
        </div>

        <% if ("actualizado".equals(msg)) { %>
        <div class="alert ok"><strong>Cambios guardados</strong> Se actualizaron los datos del usuario <%= texto(idMsg) %>.</div>
        <% } else if ("estado".equals(msg)) { %>
        <div class="alert ok"><strong>Estado actualizado</strong> Un usuario Inactivo no puede iniciar sesión.</div>
        <% } else if ("eliminado".equals(msg)) { %>
        <div class="alert ok"><strong>Usuario eliminado</strong> Se eliminó el usuario con DNI <%= texto(idMsg) %>.</div>
        <% } else if ("tieneRegistros".equals(msg)) { %>
        <div class="alert warn"><strong>No se eliminó el usuario</strong>
            Tiene solicitudes o cambios registrados en el sistema. Desactívalo para que ya no pueda ingresar.</div>
        <% } else if ("propio".equals(msg)) { %>
        <div class="alert warn"><strong>Acción no permitida</strong> No puedes desactivar ni eliminar tu propia cuenta.</div>
        <% } else if ("error".equals(msg)) { %>
        <div class="alert error"><strong>No se completó la acción</strong> Ocurrió un error en la base de datos.</div>
        <% } %>

        <section class="stats cols-3">
            <a class="stat info<%= estadoFiltro.isEmpty() ? " selected" : "" %>" href="<%= listar %>">
                <span class="stat-label">Usuarios</span>
                <span class="stat-value"><%= request.getAttribute("totalUsuarios") %></span>
                <span class="small">Registrados</span>
            </a>
            <a class="stat ok<%= "Activo".equals(estadoFiltro) ? " selected" : "" %>" href="<%= listar %>&estado=Activo">
                <span class="stat-label">Activos</span>
                <span class="stat-value"><%= request.getAttribute("activos") %></span>
                <span class="small">Pueden iniciar sesión</span>
            </a>
            <a class="stat<%= "Inactivo".equals(estadoFiltro) ? " selected" : "" %>" href="<%= listar %>&estado=Inactivo">
                <span class="stat-label">Inactivos</span>
                <span class="stat-value"><%= request.getAttribute("inactivos") %></span>
                <span class="small">Sin acceso</span>
            </a>
        </section>

        <form action="<%= servlet %>" class="card filters" method="get">
            <input type="hidden" name="action" value="lista"/>
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input id="buscar" name="buscar" placeholder="Nombre, DNI o correo" type="text" value="<%= texto(buscar) %>"/>
            </div>
            <div class="col">
                <label for="filtroRol">Rol</label>
                <select id="filtroRol" name="rol">
                    <option value="">Todos</option>
                    <% for (int r = 1; r <= nombresRol.length; r++) { %>
                    <option value="<%= r %>" <%= String.valueOf(r).equals(rolFiltro) ? "selected" : "" %>><%= nombresRol[r - 1] %></option>
                    <% } %>
                </select>
            </div>
            <div class="col">
                <label for="filtroEstado">Estado</label>
                <select id="filtroEstado" name="estado">
                    <option value="">Todos</option>
                    <option <%= "Activo".equals(estadoFiltro) ? "selected" : "" %>>Activo</option>
                    <option <%= "Inactivo".equals(estadoFiltro) ? "selected" : "" %>>Inactivo</option>
                </select>
            </div>
            <div class="col-action botones">
                <a class="ghost" href="<%= listar %>">Limpiar</a>
                <button class="primary" type="submit">Buscar</button>
            </div>
        </form>

        <section class="card">
            <div class="card-header">
                <h2>Usuarios registrados</h2>
                <span class="small"><%= paginacion.getTotalRegistros() %> usuarios</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Usuario</th>
                        <th>Correo</th>
                        <th>Rol</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (listaUsuarios.isEmpty()) { %>
                    <tr><td colspan="5" class="small">No se encontraron usuarios para los filtros seleccionados.</td></tr>
                    <% } %>
                    <% for (Usuario u : listaUsuarios) {
                        boolean propio = u.getDniUsuario() == dniSesion; %>
                    <tr>
                        <td class="cell-main">
                            <%= texto(u.getNombre()) %> <%= texto(u.getApellido1()) %> <%= texto(u.getApellido2()) %>
                            <span class="cell-sub">DNI <%= u.getDniUsuario() %><%= propio ? " · tu cuenta" : "" %></span>
                        </td>
                        <td><%= texto(u.getCorreo()) %></td>
                        <td><%= nombreRol(u.getRol().getIdRol()) %></td>
                        <td><span class="badge <%= claseEstado(u.getEstado()) %>"><%= u.getEstado() %></span></td>
                        <td>
                            <div class="botones">
                                <a href="<%= servlet %>?action=editar&id=<%= u.getDniUsuario() %>" class="ghost btn-sm">Editar</a>
                                <% if (!propio) { %>
                                <a href="#estado<%= u.getDniUsuario() %>" class="secondary btn-sm">
                                    <%= "Activo".equals(u.getEstado()) ? "Desactivar" : "Activar" %>
                                </a>
                                <a href="#eliminar<%= u.getDniUsuario() %>" class="danger btn-sm">Eliminar</a>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="usuarios"/>
            </jsp:include>
        </section>
    </main>
</div>

<%-- Confirmaciones (se abren con los enlaces #estado... y #eliminar..., sin JavaScript) --%>
<% for (Usuario u : listaUsuarios) {
    if (u.getDniUsuario() == dniSesion) continue;
    boolean activo = "Activo".equals(u.getEstado());
    String nombre = texto(u.getNombre() + " " + u.getApellido1()); %>
<div id="estado<%= u.getDniUsuario() %>" class="overlay">
    <div class="modal">
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="cambiarEstado">
            <input type="hidden" name="id" value="<%= u.getDniUsuario() %>">
            <h2><%= activo ? "¿Desactivar" : "¿Activar" %> a <%= nombre %>?</h2>
            <p><%= activo ? "No podrá iniciar sesión hasta que vuelvas a activarlo. Sus registros se conservan."
                          : "Podrá volver a iniciar sesión con su correo y contraseña." %></p>
            <div class="botones">
                <a href="#" class="ghost">Cancelar</a>
                <button type="submit" class="primary"><%= activo ? "Desactivar" : "Activar" %></button>
            </div>
        </form>
    </div>
</div>

<div id="eliminar<%= u.getDniUsuario() %>" class="overlay">
    <div class="modal">
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="borrar">
            <input type="hidden" name="id" value="<%= u.getDniUsuario() %>">
            <h2>¿Eliminar a <%= nombre %>?</h2>
            <p>Solo se elimina si no tiene solicitudes ni cambios registrados; si los tiene, desactívalo.
                Esta acción no se puede deshacer.</p>
            <div class="botones">
                <a href="#" class="ghost">Cancelar</a>
                <button type="submit" class="danger solid">Eliminar usuario</button>
            </div>
        </form>
    </div>
</div>
<% } %>

</body>
</html>
