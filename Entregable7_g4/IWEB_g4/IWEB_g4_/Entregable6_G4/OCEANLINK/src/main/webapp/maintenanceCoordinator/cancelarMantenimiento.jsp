<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Cancelar registro | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/maintenanceCoordinator/mantenimiento.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="nuevo"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Nuevo mantenimiento</h1>
                <p class="small">Registro en curso.</p>
            </div>
        </div>
    </main>
</div>

<!-- Confirmación para abandonar el registro (siempre visible en esta página) -->
<div class="overlay" style="display: flex">
    <div class="modal">
        <h2>¿Cancelar el registro?</h2>
        <p>Se descartarán los datos del mantenimiento que estás registrando. No se guardará nada en la base de datos.</p>
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="confirmarCancelarRegistro">
            <div class="botones">
                <a href="<%= servlet %>?action=continuar" class="ghost">No, continuar</a>
                <button type="submit" class="danger solid">Sí, cancelar</button>
            </div>
        </form>
    </div>
</div>

</body>
</html>
