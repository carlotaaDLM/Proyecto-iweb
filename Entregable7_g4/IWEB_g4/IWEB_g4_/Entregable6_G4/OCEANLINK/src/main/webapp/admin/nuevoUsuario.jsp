<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/UsuarioServlet";
    String error = (String) request.getAttribute("error");

    // Valores previos (si se vuelve al formulario por un error)
    String dni = request.getParameter("dni") == null ? "" : request.getParameter("dni");
    String nombre = request.getParameter("nombre") == null ? "" : request.getParameter("nombre");
    String apellido1 = request.getParameter("apellido1") == null ? "" : request.getParameter("apellido1");
    String apellido2 = request.getParameter("apellido2") == null ? "" : request.getParameter("apellido2");
    String correo = request.getParameter("correo") == null ? "" : request.getParameter("correo");
    String rolId = request.getParameter("rolId") == null ? "" : request.getParameter("rolId");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Nuevo usuario | OceanLink</title>
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
                <h1>Nuevo usuario</h1>
                <p class="small">El usuario se registra Activo y entra con su correo y la contraseña temporal.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <form action="<%= servlet %>" class="card" method="post">
            <input type="hidden" name="action" value="crear">

            <fieldset>
                <legend>Datos personales</legend>
                <div class="row">
                    <div class="col">
                        <label for="dni">DNI <span class="req">*</span></label>
                        <input id="dni" name="dni" type="text" inputmode="numeric" pattern="\d{8}" maxlength="8" required
                               placeholder="8 dígitos" value="<%= texto(dni) %>"/>
                    </div>
                    <div class="col">
                        <label for="nombre">Nombre <span class="req">*</span></label>
                        <input id="nombre" name="nombre" type="text" maxlength="45" required value="<%= texto(nombre) %>"/>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="apellido1">Primer apellido <span class="req">*</span></label>
                        <input id="apellido1" name="apellido1" type="text" maxlength="45" required value="<%= texto(apellido1) %>"/>
                    </div>
                    <div class="col">
                        <label for="apellido2">Segundo apellido <span class="req">*</span></label>
                        <input id="apellido2" name="apellido2" type="text" maxlength="45" required value="<%= texto(apellido2) %>"/>
                    </div>
                </div>
            </fieldset>

            <fieldset>
                <legend>Acceso</legend>
                <div class="row">
                    <div class="col">
                        <label for="correo">Correo <span class="req">*</span></label>
                        <input id="correo" name="correo" type="email" maxlength="100" required
                               placeholder="nombre@oceanlink.pe" value="<%= texto(correo) %>"/>
                    </div>
                    <div class="col">
                        <label for="rolId">Rol <span class="req">*</span></label>
                        <select id="rolId" name="rolId" required>
                            <option value="" disabled <%= rolId.isEmpty() ? "selected" : "" %>>Selecciona un rol</option>
                            <% for (int r = 1; r <= nombresRol.length; r++) { %>
                            <option value="<%= r %>" <%= String.valueOf(r).equals(rolId) ? "selected" : "" %>><%= nombresRol[r - 1] %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="password">Contraseña temporal <span class="req">*</span></label>
                        <input id="password" name="password" type="password" minlength="4" maxlength="50" required/>
                        <span class="hint">Entre 4 y 50 caracteres.</span>
                    </div>
                </div>
            </fieldset>

            <div class="footer-action">
                <a class="ghost" href="<%= servlet %>?action=lista">Cancelar</a>
                <button class="primary" type="submit">Registrar usuario</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
