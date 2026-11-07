<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";
    int pasoActual = 4;

    String error = (String) request.getAttribute("error");
    String hoy = (String) request.getAttribute("hoy");

    String tipo = (String) session.getAttribute("mantTipo");
    String titulo = (String) session.getAttribute("mantTitulo");
    String descripcion = (String) session.getAttribute("mantDescripcion");
    String[] estaciones = (String[]) session.getAttribute("mantEstaciones");
    String[] segmentos = (String[]) session.getAttribute("mantSegmentos");

    String fechaIng = (String) session.getAttribute("mantFecha");
    String horaIng = (String) session.getAttribute("mantHora");
    String duracionIng = (String) session.getAttribute("mantDuracion");
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
        <a class="back-link" href="<%= servlet %>?action=paso3">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver al impacto de servicios
        </a>

        <div class="topbar">
            <div>
                <h1>Nuevo mantenimiento</h1>
                <p class="small">Define cuándo empieza y cuánto durará. Revisa el resumen antes de registrarlo.</p>
            </div>
        </div>

        <%@ include file="pasos.jspf" %>

        <% if (error != null) { %>
        <div class="alert error"><strong>No se registró el mantenimiento</strong> <%= texto(error) %></div>
        <% } %>

        <div class="split">
            <form action="<%= servlet %>" class="card" method="post">
                <input type="hidden" name="action" value="crear">

                <fieldset>
                    <legend>Programación</legend>
                    <div class="row">
                        <div class="col">
                            <label for="fechaInicio">Fecha de inicio <span class="req">*</span></label>
                            <input id="fechaInicio" name="fechaInicio" type="date" required min="<%= hoy %>"
                                   value="<%= texto(fechaIng) %>"/>
                        </div>
                        <div class="col">
                            <label for="horaInicio">Hora de inicio <span class="req">*</span></label>
                            <input id="horaInicio" name="horaInicio" type="time" required value="<%= texto(horaIng) %>"/>
                        </div>
                        <div class="col">
                            <label for="duracion">Duración estimada (horas) <span class="req">*</span></label>
                            <input id="duracion" name="duracion" type="number" min="1" max="240" required
                                   placeholder="Ej. 6" value="<%= texto(duracionIng) %>"/>
                        </div>
                    </div>
                    <span class="hint">La fecha no puede ser anterior a hoy. La duración va de 1 a 240 horas
                        (los trabajos submarinos pueden durar varios días).</span>
                </fieldset>

                <div class="footer-action">
                    <a class="ghost" href="<%= servlet %>?action=cancelarRegistro">Cancelar</a>
                    <a class="secondary" href="<%= servlet %>?action=paso3">Atrás</a>
                    <button class="primary" type="submit">Registrar mantenimiento</button>
                </div>
            </form>

            <aside class="card">
                <div class="card-header">
                    <h2>Resumen</h2>
                </div>
                <dl class="kv">
                    <div><dt>Tipo</dt><dd><%= texto(tipo) %></dd></div>
                    <div><dt>Título</dt><dd><%= texto(titulo) %></dd></div>
                    <div><dt>Descripción</dt><dd><%= texto(descripcion) %></dd></div>
                    <div><dt>Segmentos</dt><dd><%= segmentos == null || segmentos.length == 0 ? "—" : String.join(", ", segmentos) %></dd></div>
                    <div><dt>Landing Stations</dt><dd><%= estaciones == null || estaciones.length == 0 ? "—" : String.join(", ", estaciones) %></dd></div>
                    <div><dt>Estado inicial</dt><dd><span class="badge blue">Programado</span></dd></div>
                </dl>
            </aside>
        </div>
    </main>
</div>

</body>
</html>
