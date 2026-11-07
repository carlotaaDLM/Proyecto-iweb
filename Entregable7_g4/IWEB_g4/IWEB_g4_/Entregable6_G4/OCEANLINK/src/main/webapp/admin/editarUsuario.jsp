<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Usuario" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/UsuarioServlet";
    Usuario usuario = (Usuario) request.getAttribute("usuario");
    String error = (String) request.getAttribute("error");
    int rolId = usuario.getRol() == null ? 0 : usuario.getRol().getIdRol();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Editar usuario | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="usuarios"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=lista">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a usuarios
        </a>

        <div class="topbar">
            <div>
                <h1>Editar usuario</h1>
                <p class="small">El DNI no se puede cambiar. La contraseña la gestiona cada usuario.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <form action="<%= servlet %>" class="card" method="post">
            <input type="hidden" name="action" value="editar">
            <input type="hidden" name="dni" value="<%= usuario.getDniUsuario() %>">

            <fieldset>
                <legend>Datos personales</legend>
                <div class="row">
                    <div class="col">
                        <label for="dniVer">DNI</label>
                        <input id="dniVer" type="text" value="<%= usuario.getDniUsuario() %>" readonly/>
                    </div>
                    <div class="col">
                        <label for="nombre">Nombre <span class="req">*</span></label>
                        <input id="nombre" name="nombre" type="text" maxlength="45" required value="<%= texto(usuario.getNombre()) %>"/>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="apellido1">Primer apellido <span class="req">*</span></label>
                        <input id="apellido1" name="apellido1" type="text" maxlength="45" required value="<%= texto(usuario.getApellido1()) %>"/>
                    </div>
                    <div class="col">
                        <label for="apellido2">Segundo apellido <span class="req">*</span></label>
                        <input id="apellido2" name="apellido2" type="text" maxlength="45" required value="<%= texto(usuario.getApellido2()) %>"/>
                    </div>
                </div>
            </fieldset>

            <fieldset>
                <legend>Acceso</legend>
                <div class="row">
                    <div class="col">
                        <label for="correo">Correo <span class="req">*</span></label>
                        <input id="correo" name="correo" type="email" maxlength="100" required value="<%= texto(usuario.getCorreo()) %>"/>
                    </div>
                    <div class="col">
                        <label for="rolId">Rol <span class="req">*</span></label>
                        <select id="rolId" name="rolId" required>
                            <% for (int r = 1; r <= nombresRol.length; r++) { %>
                            <option value="<%= r %>" <%= r == rolId ? "selected" : "" %>><%= nombresRol[r - 1] %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label>Estado</label>
                        <span class="badge <%= claseEstado(usuario.getEstado()) %>"><%= usuario.getEstado() %></span>
                        <span class="hint">Se cambia desde el listado (Activar / Desactivar).</span>
                    </div>
                </div>
            </fieldset>

            <div class="footer-action">
                <a class="ghost" href="<%= servlet %>?action=lista">Cancelar</a>
                <button class="primary" type="submit">Guardar cambios</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
