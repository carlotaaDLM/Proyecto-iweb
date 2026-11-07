<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Usuario" %>
<%--
    Barra superior + menú lateral del Network Operator.
    Se incluye con:  <jsp:include page="menu.jsp"><jsp:param name="activo" value="..."/></jsp:include>
    Deja abierto <div class="layout">, que se cierra en la página que lo incluye.
--%>
<%-- Usuario que inició sesión (lo guarda el LoginServlet). Si no estuviera en sesión,
     class crea un Usuario vacío para que la página no lance error. --%>
<jsp:useBean id="usuarioSesion" scope="session" class="beans.Usuario"/>
<%
    String activo = request.getParameter("activo");
    String servlet = request.getContextPath() + "/NetworkOperatorServlet";

    String nombreUsuario = "Network Operator";
    String iniciales = "NO";
    if (usuarioSesion.getNombre() != null) {
        nombreUsuario = usuarioSesion.getNombre() + " " + usuarioSesion.getApellido1();
        iniciales = usuarioSesion.getNombre().substring(0, 1) + usuarioSesion.getApellido1().substring(0, 1);
    }
%>
<header class="navbar">
    <a href="<%= servlet %>?action=vistaGeneral">
        <img src="<%= request.getContextPath() %>/networkOperator/OLlogo.png"
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
            <span class="user-role">Network Operator</span>
        </div>
    </a>
</header>

<div class="layout">
    <aside class="sidebar">
        <nav class="menu" aria-label="Menú principal">
            <span class="menu-label">Red</span>

            <a href="<%= servlet %>?action=vistaGeneral"
               <%= "vistaGeneral".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 10.5L12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/><path d="M10 21v-6h4v6"/></svg>
                Vista general
            </a>

            <a href="<%= servlet %>?action=estadoSegmentos"
               <%= "estadoSegmentos".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 12h-4l-3 8L9 4l-3 8H2"/></svg>
                Estado de segmentos
            </a>

            <span class="menu-label">Incidencias</span>

            <a href="<%= servlet %>?action=listarIncidencias"
               <%= "listarIncidencias".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="M3 6h.01"/><path d="M3 12h.01"/><path d="M3 18h.01"/></svg>
                Listado de incidencias
            </a>

            <a href="<%= servlet %>?action=formRegistrar"
               <%= "formRegistrar".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.3 3.9L1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
                Registrar incidencia
            </a>

            <a href="<%= servlet %>?action=historial"
               <%= "historial".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/></svg>
                Historial de incidencias
            </a>
        </nav>

        <nav class="menu menu-bottom">
            <a href="<%= request.getContextPath() %>/LoginServlet?action=logout">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>
                Cerrar sesión
            </a>
        </nav>
    </aside>
