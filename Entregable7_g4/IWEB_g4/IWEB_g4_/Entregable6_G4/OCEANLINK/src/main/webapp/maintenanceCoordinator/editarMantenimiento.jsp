<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Mantenimiento" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";

    Mantenimiento m = (Mantenimiento) request.getAttribute("mantenimiento");
    String error = (String) request.getAttribute("error");
    String hoy = (String) request.getAttribute("hoy");

    String codigo = m.getCodigoMantenimiento();
    String duracionValor = request.getAttribute("duracionElegida") != null
            ? (String) request.getAttribute("duracionElegida")
            : String.valueOf(m.getHorasEstimadas());
    String hora = m.getHoraInicio() == null ? "" : m.getHoraInicio();
    if (hora.length() > 5) hora = hora.substring(0, 5);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Editar <%= codigo %> | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/maintenanceCoordinator/mantenimiento.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="listar"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=detalle&codigo=<%= url(codigo) %>">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver al detalle
        </a>

        <div class="topbar">
            <div>
                <h1>Editar mantenimiento <%= codigo %></h1>
                <p class="small">Solo se puede editar mientras el mantenimiento está Programado. El cambio queda en el historial.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <div class="split">
            <form action="<%= servlet %>" class="card" method="post">
                <input type="hidden" name="action" value="actualizar">
                <input type="hidden" name="codigo" value="<%= codigo %>">

                <fieldset>
                    <legend>Datos generales</legend>
                    <div class="row">
                        <div class="col">
                            <label>Tipo de mantenimiento <span class="req">*</span></label>
                            <div class="option-cards">
                                <label>
                                    <input type="radio" name="tipo" value="Preventivo" required <%= "Preventivo".equals(m.getTipo()) ? "checked" : "" %>>
                                    <span><strong>Preventivo</strong><small>Planificado para prevenir fallas.</small></span>
                                </label>
                                <label>
                                    <input type="radio" name="tipo" value="Correctivo" required <%= "Correctivo".equals(m.getTipo()) ? "checked" : "" %>>
                                    <span><strong>Correctivo</strong><small>Para corregir una falla detectada.</small></span>
                                </label>
                            </div>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col">
                            <label for="titulo">Título <span class="req">*</span></label>
                            <input id="titulo" name="titulo" type="text" maxlength="100" required value="<%= texto(m.getActividad()) %>"/>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col">
                            <label for="descripcion">Descripción <span class="req">*</span></label>
                            <textarea class="textarea-sm" id="descripcion" name="descripcion" maxlength="500" required><%= texto(m.getDescripcion()) %></textarea>
                            <span class="hint">Máximo 500 caracteres.</span>
                        </div>
                    </div>
                </fieldset>

                <fieldset>
                    <legend>Programación</legend>
                    <div class="row">
                        <div class="col">
                            <label for="fechaInicio">Fecha de inicio <span class="req">*</span></label>
                            <input id="fechaInicio" name="fechaInicio" type="date" required min="<%= hoy %>"
                                   value="<%= texto(m.getFechaProgramada()) %>"/>
                        </div>
                        <div class="col">
                            <label for="horaInicio">Hora de inicio <span class="req">*</span></label>
                            <input id="horaInicio" name="horaInicio" type="time" required value="<%= texto(hora) %>"/>
                        </div>
                        <div class="col">
                            <label for="duracion">Duración estimada (horas) <span class="req">*</span></label>
                            <input id="duracion" name="duracion" type="number" min="1" max="240" required
                                   value="<%= texto(duracionValor) %>"/>
                        </div>
                    </div>
                </fieldset>

                <div class="footer-action">
                    <a class="ghost" href="<%= servlet %>?action=detalle&codigo=<%= url(codigo) %>">Cancelar</a>
                    <button class="primary" type="submit">Guardar cambios</button>
                </div>
            </form>

            <aside class="card">
                <div class="card-header">
                    <h2>Infraestructura</h2>
                </div>
                <dl class="kv">
                    <div><dt>Segmentos</dt><dd><%= m.getSegmentos() == null ? "—" : m.getSegmentos() %></dd></div>
                    <div><dt>Landing Stations</dt><dd><%= m.getLandings() == null ? "—" : m.getLandings() %></dd></div>
                    <div><dt>Estado</dt><dd><span class="badge <%= claseEstadoMnt(m.getEstado()) %>"><%= m.getEstado() %></span></dd></div>
                </dl>
                <div class="alert info" style="margin: 16px 0 0">
                    La infraestructura no se cambia aquí: si es otra, cancela este mantenimiento y registra uno nuevo.
                </div>
            </aside>
        </div>
    </main>
</div>

</body>
</html>
