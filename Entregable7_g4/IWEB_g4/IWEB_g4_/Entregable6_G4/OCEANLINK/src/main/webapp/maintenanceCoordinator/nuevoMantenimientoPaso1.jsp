<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";
    int pasoActual = 1;

    String error = (String) request.getAttribute("error");

    // Si se vuelve desde el paso 2 (o hubo un error) se muestra lo que ya se ingresó
    String tipo = request.getAttribute("tipoElegido") != null
            ? (String) request.getAttribute("tipoElegido")
            : (String) session.getAttribute("mantTipo");
    String titulo = (String) session.getAttribute("mantTitulo");
    String descripcion = (String) session.getAttribute("mantDescripcion");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Nuevo mantenimiento | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/maintenanceCoordinator/mantenimiento.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="nuevo"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=listar">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a mantenimientos
        </a>

        <div class="topbar">
            <div>
                <h1>Nuevo mantenimiento</h1>
                <p class="small">El mantenimiento se registra en estado Programado sobre la infraestructura elegida.</p>
            </div>
        </div>

        <%@ include file="pasos.jspf" %>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <form action="<%= servlet %>" class="card" method="post">
            <input type="hidden" name="action" value="guardarPaso1">

            <fieldset>
                <legend>Datos generales</legend>
                <div class="row">
                    <div class="col">
                        <label>Tipo de mantenimiento <span class="req">*</span></label>
                        <div class="option-cards">
                            <label>
                                <input type="radio" name="tipo" value="Preventivo" required <%= "Preventivo".equals(tipo) ? "checked" : "" %>>
                                <span><strong>Preventivo</strong><small>Planificado para prevenir fallas.</small></span>
                            </label>
                            <label>
                                <input type="radio" name="tipo" value="Correctivo" required <%= "Correctivo".equals(tipo) ? "checked" : "" %>>
                                <span><strong>Correctivo</strong><small>Para corregir una falla detectada.</small></span>
                            </label>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="titulo">Título <span class="req">*</span></label>
                        <input id="titulo" maxlength="100" name="titulo" type="text" required
                               placeholder="Ej. Medición OTDR del tramo Lurín - Máncora" value="<%= texto(titulo) %>"/>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="descripcion">Descripción <span class="req">*</span></label>
                        <textarea class="textarea-sm" id="descripcion" maxlength="500" name="descripcion" required
                                  placeholder="Actividades que se realizarán"><%= texto(descripcion) %></textarea>
                        <span class="hint">Máximo 500 caracteres. Se guarda como la actividad principal del mantenimiento.</span>
                    </div>
                </div>
            </fieldset>

            <div class="footer-action">
                <a class="ghost" href="<%= servlet %>?action=cancelarRegistro">Cancelar</a>
                <button class="primary" type="submit">Continuar</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
