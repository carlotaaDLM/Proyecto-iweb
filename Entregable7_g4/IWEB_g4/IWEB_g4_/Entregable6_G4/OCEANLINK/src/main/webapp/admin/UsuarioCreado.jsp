<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Usuario" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/UsuarioServlet";
    Usuario usuario = (Usuario) request.getAttribute("usuario");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Usuario registrado | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="usuarios"/>
</jsp:include>

    <main class="content">
        <section class="card success">
            <div class="success-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6L9 17l-5-5"/></svg>
            </div>

            <h1>Usuario registrado</h1>
            <p class="small">Ya puede iniciar sesión con su correo y la contraseña temporal.</p>

            <dl class="summary">
                <div><dt>Nombre</dt><dd><%= texto(usuario.getNombre()) %> <%= texto(usuario.getApellido1()) %> <%= texto(usuario.getApellido2()) %></dd></div>
                <div><dt>DNI</dt><dd><%= usuario.getDniUsuario() %></dd></div>
                <div><dt>Correo</dt><dd><%= texto(usuario.getCorreo()) %></dd></div>
                <div><dt>Rol</dt><dd><%= nombreRol(usuario.getRol().getIdRol()) %></dd></div>
                <div><dt>Estado</dt><dd><span class="badge <%= claseEstado(usuario.getEstado()) %>"><%= usuario.getEstado() %></span></dd></div>
            </dl>

            <div class="botones">
                <a href="<%= servlet %>?action=formCrear" class="ghost">Registrar otro usuario</a>
                <a href="<%= servlet %>?action=lista" class="primary">Volver a usuarios</a>
            </div>
        </section>
    </main>
</div>

</body>
</html>
