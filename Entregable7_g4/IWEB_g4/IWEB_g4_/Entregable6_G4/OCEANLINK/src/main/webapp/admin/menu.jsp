<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Usuario" %>
<%--
    Barra superior + menú lateral del Administrador.
    Se incluye con:  <jsp:include page="menu.jsp"><jsp:param name="activo" value="..."/></jsp:include>
    Deja abierto <div class="layout">, que se cierra en la página que lo incluye.
--%>
<%-- Usuario que inició sesión (lo guarda el LoginServlet). Si no estuviera en sesión,
     class crea un Usuario vacío para que la página no lance error. --%>
<jsp:useBean id="usuarioSesion" scope="session" class="beans.Usuario"/>
<%
    String activo = request.getParameter("activo");
    String ctx = request.getContextPath();

    String nombreUsuario = "Administrador";
    String iniciales = "AD";
    if (usuarioSesion.getNombre() != null) {
        nombreUsuario = usuarioSesion.getNombre() + " " + usuarioSesion.getApellido1();
        iniciales = usuarioSesion.getNombre().substring(0, 1) + usuarioSesion.getApellido1().substring(0, 1);
    }
%>
<header class="navbar">
    <a href="<%= ctx %>/UsuarioServlet?action=lista">
        <img src="<%= ctx %>/OLlogo.png" alt="OceanLink Telecom" class="navbar-logo">
    </a>
    <%-- Al hacer clic se abre "Mi perfil" (editar datos y foto) --%>
    <a class="user-profile" href="<%= request.getContextPath() %>/PerfilServlet" title="Ver y editar mi perfil">
        <% if (usuarioSesion.isTieneFoto()) { %>
        <img class="avatar" src="<%= request.getContextPath() %>/PerfilServlet?action=foto&dni=<%= usuarioSesion.getDniUsuario() %>" alt="">
        <% } else { %>
        <div class="avatar" aria-hidden="true"><%= iniciales %></div>
        <% } %>
        <div class="user-info">
            <span class="user-name"><%= nombreUsuario %></span>
            <span class="user-role">Administrador</span>
        </div>
    </a>
</header>

<div class="layout">
    <aside class="sidebar">
        <nav class="menu" aria-label="Menú principal">
            <span class="menu-label">Accesos</span>

            <a href="<%= ctx %>/UsuarioServlet?action=lista"
               <%= "usuarios".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                Usuarios
            </a>

            <a href="<%= ctx %>/ClienteServlet?action=lista"
               <%= "clientes".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M3 13h18"/></svg>
                Clientes
            </a>

            <span class="menu-label">Infraestructura</span>

            <a href="<%= ctx %>/LandingStationServlet?action=lista"
               <%= "landing".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 22s7-6.2 7-12a7 7 0 1 0-14 0c0 5.8 7 12 7 12z"/><circle cx="12" cy="10" r="2.5"/></svg>
                Landing Stations
            </a>

            <a href="<%= ctx %>/SegmentoServlet?action=lista"
               <%= "segmentos".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="5" cy="12" r="3"/><circle cx="19" cy="12" r="3"/><path d="M8 12h8"/></svg>
                Segmentos de fibra
            </a>
        </nav>

        <nav class="menu menu-bottom">
            <a href="<%= ctx %>/LoginServlet?action=logout">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>
                Cerrar sesión
            </a>
        </nav>
    </aside>
