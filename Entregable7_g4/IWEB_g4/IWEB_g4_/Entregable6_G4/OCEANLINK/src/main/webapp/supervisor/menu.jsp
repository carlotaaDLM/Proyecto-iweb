<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Usuario" %>
<%--
    Barra superior + menú lateral del Supervisor.
    Se incluye con:  <jsp:include page="menu.jsp"><jsp:param name="activo" value="..."/></jsp:include>
    Deja abierto <div class="layout">, que se cierra en la página que lo incluye.
--%>
<%-- Usuario que inició sesión (lo guarda el LoginServlet). Si no estuviera en sesión,
     class crea un Usuario vacío para que la página no lance error. --%>
<jsp:useBean id="usuarioSesion" scope="session" class="beans.Usuario"/>
<%
    String activo = request.getParameter("activo");
    String servlet = request.getContextPath() + "/SupervisorServlet";

    String nombreUsuario = "Supervisor";
    String iniciales = "SU";
    if (usuarioSesion.getNombre() != null) {
        nombreUsuario = usuarioSesion.getNombre() + " " + usuarioSesion.getApellido1();
        iniciales = usuarioSesion.getNombre().substring(0, 1) + usuarioSesion.getApellido1().substring(0, 1);
    }
%>
<header class="navbar">
    <a href="<%= servlet %>?action=dashboard">
        <img src="<%= request.getContextPath() %>/supervisor/OLlogo.png"
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
            <span class="user-role">Supervisor</span>
        </div>
    </a>
</header>

<div class="layout">

    <aside class="sidebar">
            <nav class="menu" aria-label="Menú principal">
                <span class="menu-label">Red</span>
                <a href="<%= servlet %>?action=dashboard"
                   <%= "dashboard".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 10.5L12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/><path d="M10 21v-6h4v6"/></svg>
                    Dashboard
                </a>
                <a href="<%= servlet %>?action=segmentos"
                   <%= "segmentos".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 12h-4l-3 8L9 4l-3 8H2"/></svg>
                    Segmentos y utilización
                </a>
                <a href="<%= servlet %>?action=landing"
                   <%= "landing".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 12v9"/><path d="M8 21h8"/><circle cx="12" cy="9" r="2"/><path d="M7.8 13.2a6 6 0 0 1 0-8.4"/><path d="M16.2 4.8a6 6 0 0 1 0 8.4"/></svg>
                    Landing Stations
                </a>
                <span class="menu-label">Operación</span>
                <a href="<%= servlet %>?action=incidencias"
                   <%= "incidencias".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.3 3.9L1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
                    Incidencias activas
                </a>
                <a href="<%= servlet %>?action=afectados"
                   <%= "afectados".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.9"/><path d="M16 3.1a4 4 0 0 1 0 7.8"/></svg>
                    Servicios y clientes afectados
                </a>
                <a href="<%= servlet %>?action=mantenimientos"
                   <%= "mantenimientos".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.8-3.8a6 6 0 0 1-7.9 7.9l-6.9 6.9a2.1 2.1 0 0 1-3-3l6.9-6.9a6 6 0 0 1 7.9-7.9z"/></svg>
                    Mantenimientos
                </a>
                <span class="menu-label">Análisis</span>
                <a href="<%= servlet %>?action=reporte"
                   <%= "reporte".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M8 13h8"/><path d="M8 17h5"/></svg>
                    Reportes
                </a>
                <a href="<%= servlet %>?action=historicos"
                   <%= "historicos".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 3v18h18"/><path d="M8 17v-5"/><path d="M13 17V8"/><path d="M18 17v-9"/></svg>
                    Históricos
                </a>
            </nav>

            <nav class="menu menu-bottom">
                <a href="<%= request.getContextPath() %>/LoginServlet?action=logout">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>
                    Cerrar sesión
                </a>
            </nav>
        </aside>
