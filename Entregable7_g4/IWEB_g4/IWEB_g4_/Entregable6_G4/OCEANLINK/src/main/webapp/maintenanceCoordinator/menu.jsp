<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Usuario" %>
<%--
    Barra superior + menú lateral del Maintenance Coordinator.
    Se incluye con:  <jsp:include page="menu.jsp"><jsp:param name="activo" value="..."/></jsp:include>
    Deja abierto <div class="layout">, que se cierra en la página que lo incluye.
--%>
<%-- Usuario que inició sesión (lo guarda el LoginServlet). Si no estuviera en sesión,
     class crea un Usuario vacío para que la página no lance error. --%>
<jsp:useBean id="usuarioSesion" scope="session" class="beans.Usuario"/>
<%
    String activo = request.getParameter("activo");
    String servlet = request.getContextPath() + "/MantenimientoServlet";

    String nombreUsuario = "Maintenance Coordinator";
    String iniciales = "MC";
    if (usuarioSesion.getNombre() != null) {
        nombreUsuario = usuarioSesion.getNombre() + " " + usuarioSesion.getApellido1();
        iniciales = usuarioSesion.getNombre().substring(0, 1) + usuarioSesion.getApellido1().substring(0, 1);
    }
%>
<header class="navbar">
    <a href="<%= servlet %>?action=listar">
        <img src="<%= request.getContextPath() %>/maintenanceCoordinator/OLlogo.png"
             alt="OceanLink Telecom" class="navbar-logo">
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
            <span class="user-role">Maintenance Coordinator</span>
        </div>
    </a>
</header>

<div class="layout">
    <aside class="sidebar">
        <nav class="menu" aria-label="Menú principal">
            <span class="menu-label">Mantenimientos</span>

            <a href="<%= servlet %>?action=listar"
               <%= "listar".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="M3 6h.01"/><path d="M3 12h.01"/><path d="M3 18h.01"/></svg>
                Listado de mantenimientos
            </a>

            <a href="<%= servlet %>?action=formCrear"
               <%= "nuevo".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.8-3.8a6 6 0 0 1-7.9 7.9l-6.9 6.9a2.1 2.1 0 0 1-3-3l6.9-6.9a6 6 0 0 1 7.9-7.9z"/></svg>
                Nuevo mantenimiento
            </a>

            <span class="menu-label">Por estado</span>

            <a href="<%= servlet %>?action=listar&estado=Programado"
               <%= "programado".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/></svg>
                Programados
            </a>

            <a href="<%= servlet %>?action=listar&estado=En%20ejecuci%C3%B3n"
               <%= "ejecucion".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>
                En ejecución
            </a>

            <a href="<%= servlet %>?action=listar&estado=Finalizado"
               <%= "finalizado".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6L9 17l-5-5"/></svg>
                Finalizados
            </a>

            <a href="<%= servlet %>?action=listar&estado=Cancelado"
               <%= "cancelado".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M15 9l-6 6"/><path d="M9 9l6 6"/></svg>
                Cancelados
            </a>
        </nav>

        <nav class="menu menu-bottom">
            <a href="<%= request.getContextPath() %>/LoginServlet?action=logout">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>
                Cerrar sesión
            </a>
        </nav>
    </aside>
