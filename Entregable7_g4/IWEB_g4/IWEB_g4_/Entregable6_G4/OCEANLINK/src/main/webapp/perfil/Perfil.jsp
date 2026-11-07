<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Usuario" %>
<%!
    // Evita romper el HTML con comillas o < > en textos ingresados
    String texto(String valor) {
        if (valor == null) return "";
        return valor.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    Usuario usuario = (Usuario) request.getAttribute("usuario");
    String carpeta = (String) request.getAttribute("carpeta");
    String estilo = (String) request.getAttribute("estilo");
    String nombreRol = (String) request.getAttribute("nombreRol");
    String error = (String) request.getAttribute("error");
    // Mensaje que dejó el Servlet en sesión: se muestra una sola vez y se borra (F5 no lo repite)
    String msg = (String) session.getAttribute("msg");
    session.removeAttribute("msg");

    String ctx = request.getContextPath();
    String servlet = ctx + "/PerfilServlet";
    String iniciales = usuario.getNombre().substring(0, 1) + usuario.getApellido1().substring(0, 1);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Mi perfil | OceanLink</title>
    <link rel="stylesheet" href="<%= ctx %>/<%= carpeta %>/<%= estilo %>"/>
</head>
<body>

<%-- Barra superior y menú del rol del usuario --%>
<jsp:include page="<%= \"/\" + carpeta + \"/menu.jsp\" %>">
    <jsp:param name="activo" value="perfil"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Mi perfil</h1>
                <p class="small">Actualiza tus datos y tu foto. El rol y el estado de la cuenta los cambia el Administrador.</p>
            </div>
        </div>

        <% if ("actualizado".equals(msg)) { %>
        <div class="alert ok"><strong>Perfil actualizado</strong> Tus cambios ya se ven en la barra superior.</div>
        <% } %>
        <% if ("fotoPesada".equals(msg)) { %>
        <div class="alert error"><strong>La foto es muy pesada</strong> Elige una imagen de máximo 2 MB.</div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <%-- multipart/form-data: necesario para enviar la foto al Servlet --%>
        <form action="<%= servlet %>" class="card" method="post" enctype="multipart/form-data">
            <input type="hidden" name="action" value="actualizar">

            <div class="perfil-cabecera">
                <% if (usuario.isTieneFoto()) { %>
                <img class="perfil-foto" src="<%= servlet %>?action=foto&dni=<%= usuario.getDniUsuario() %>" alt="Foto de perfil">
                <% } else { %>
                <div class="perfil-foto perfil-iniciales" aria-hidden="true"><%= iniciales %></div>
                <% } %>
                <div>
                    <h2><%= texto(usuario.getNombre()) %> <%= texto(usuario.getApellido1()) %> <%= texto(usuario.getApellido2()) %></h2>
                    <p class="small"><%= nombreRol %> · DNI <%= usuario.getDniUsuario() %> · <%= texto(usuario.getEstado()) %></p>
                </div>
            </div>

            <fieldset>
                <legend>Datos personales</legend>
                <div class="row">
                    <div class="col">
                        <label for="nombre">Nombre</label>
                        <input id="nombre" name="nombre" type="text" maxlength="45" required value="<%= texto(usuario.getNombre()) %>"/>
                    </div>
                    <div class="col">
                        <label for="correo">Correo</label>
                        <input id="correo" name="correo" type="email" maxlength="100" required value="<%= texto(usuario.getCorreo()) %>"/>
                        <span class="hint">Con este correo inicias sesión.</span>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="apellido1">Primer apellido</label>
                        <input id="apellido1" name="apellido1" type="text" maxlength="45" required value="<%= texto(usuario.getApellido1()) %>"/>
                    </div>
                    <div class="col">
                        <label for="apellido2">Segundo apellido</label>
                        <input id="apellido2" name="apellido2" type="text" maxlength="45" required value="<%= texto(usuario.getApellido2()) %>"/>
                    </div>
                </div>
            </fieldset>

            <fieldset>
                <legend>Foto de perfil</legend>
                <div class="row">
                    <div class="col">
                        <label for="foto">Subir una foto nueva</label>
                        <input id="foto" name="foto" type="file" accept="image/png, image/jpeg, image/gif, image/webp"/>
                        <span class="hint">JPG, PNG, GIF o WEBP de máximo 2 MB. Si no eliges una, se mantiene la actual.</span>
                    </div>
                    <% if (usuario.isTieneFoto()) { %>
                    <div class="col">
                        <label class="perfil-check">
                            <input type="checkbox" name="quitarFoto" value="si"> Quitar mi foto actual
                        </label>
                    </div>
                    <% } %>
                </div>
            </fieldset>

            <div class="footer-action">
                <button class="primary" type="submit">Guardar cambios</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
