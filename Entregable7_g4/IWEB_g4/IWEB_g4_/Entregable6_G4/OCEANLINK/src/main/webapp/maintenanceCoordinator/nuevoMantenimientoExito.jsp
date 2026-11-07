<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Mantenimiento" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";
    int pasoActual = 5;

    Mantenimiento m = (Mantenimiento) request.getAttribute("mantenimiento");
    Integer servicios = (Integer) request.getAttribute("servicios");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Mantenimiento registrado | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/maintenanceCoordinator/mantenimiento.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="nuevo"/>
</jsp:include>

    <main class="content">
        <%@ include file="pasos.jspf" %>

        <section class="card success">
            <div class="success-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6L9 17l-5-5"/></svg>
            </div>

            <h1>Mantenimiento <%= m.getCodigoMantenimiento() %> registrado</h1>
            <p class="small">Quedó Programado y asignado a su infraestructura. El Supervisor ya lo ve en sus vistas.</p>

            <dl class="summary">
                <div><dt>Título</dt><dd><%= texto(m.getActividad()) %></dd></div>
                <div><dt>Tipo</dt><dd><%= m.getTipo() %></dd></div>
                <div><dt>Segmentos</dt><dd><%= m.getSegmentos() == null ? "—" : m.getSegmentos() %></dd></div>
                <div><dt>Landing Stations</dt><dd><%= m.getLandings() == null ? "—" : m.getLandings() %></dd></div>
                <div><dt>Inicio</dt><dd><%= fecha(m.getFechaProgramada()) %> · <%= m.getHoraInicio() %></dd></div>
                <div><dt>Duración estimada</dt><dd><%= duracion(m.getDuracionEstimada()) %></dd></div>
                <div><dt>Servicios relacionados</dt><dd><%= servicios %></dd></div>
                <div><dt>Estado</dt><dd><span class="badge <%= claseEstadoMnt(m.getEstado()) %>"><%= m.getEstado() %></span></dd></div>
            </dl>

            <div class="botones">
                <a href="<%= servlet %>?action=formCrear" class="ghost">Registrar otro</a>
                <a href="<%= servlet %>?action=listar" class="ghost">Volver a mantenimientos</a>
                <a href="<%= servlet %>?action=detalle&codigo=<%= url(m.getCodigoMantenimiento()) %>" class="primary">Ver detalle</a>
            </div>
        </section>
    </main>
</div>

</body>
</html>
