<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Usuario" %>
<%--
    Barra superior + menú lateral del Capacity Planner.
    Se incluye con:  <jsp:include page="menu.jsp"><jsp:param name="activo" value="..."/></jsp:include>
    Deja abierto <div class="layout">, que se cierra en la página que lo incluye.
--%>
<%-- Usuario que inició sesión (lo guarda el LoginServlet). Si no estuviera en sesión,
     class crea un Usuario vacío para que la página no lance error. --%>
<jsp:useBean id="usuarioSesion" scope="session" class="beans.Usuario"/>
<%
    String activo = request.getParameter("activo");
    String servlet = request.getContextPath() + "/CapacityPlannerServlet";

    String nombreUsuario = "Capacity Planner";
    String iniciales = "CP";
    if (usuarioSesion.getNombre() != null) {
        nombreUsuario = usuarioSesion.getNombre() + " " + usuarioSesion.getApellido1();
        iniciales = usuarioSesion.getNombre().substring(0, 1) + usuarioSesion.getApellido1().substring(0, 1);
    }
%>
<header class="navbar">
    <a href="<%= servlet %>?action=capacidad">
        <img src="<%= request.getContextPath() %>/capacityPlanner/OLlogo.png"
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
            <span class="user-role">Capacity Planner</span>
        </div>
    </a>
</header>

<div class="layout">
    <aside class="sidebar">
        <nav class="menu" aria-label="Menú principal">
            <a href="<%= servlet %>?action=capacidad"
               <%= "capacidad".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 14l4-4"/><path d="M3.3 19a10 10 0 1 1 17.4 0"/></svg>
                Capacidad de segmentos
            </a>

            <a href="<%= servlet %>?action=formRegistrar"
               <%= "formRegistrar".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6"/><path d="M12 12v6"/><path d="M9 15h6"/></svg>
                Registrar solicitud
            </a>

            <a href="<%= servlet %>?action=listarSolicitudes"
               <%= "listarSolicitudes".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 11l3 3 8-8"/><path d="M20 12v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h9"/></svg>
                Evaluar solicitudes
            </a>

            <a href="<%= servlet %>?action=formReservar"
               <%= "formReservar".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>
                Reservar capacidad
            </a>

            <a href="<%= servlet %>?action=rutas"
               <%= "rutas".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="6" cy="19" r="3"/><circle cx="18" cy="5" r="3"/><path d="M9 19h6.5a3.5 3.5 0 0 0 0-7h-7a3.5 3.5 0 0 1 0-7H15"/></svg>
                Rutas de servicios
            </a>

            <a href="<%= servlet %>?action=saturacion"
               <%= "saturacion".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.3 3.9L1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
                Próximos a saturación
            </a>

            <a href="<%= servlet %>?action=historial"
               <%= "historial".equals(activo) ? "class=\"active\" aria-current=\"page\"" : "" %>>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 3v18h18"/><path d="M7 15l4-4 3 3 6-6"/></svg>
                Historial de utilización
            </a>
        </nav>

        <nav class="menu menu-bottom">
            <a href="<%= request.getContextPath() %>/LoginServlet?action=logout">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>
                Cerrar sesión
            </a>
        </nav>
    </aside>
