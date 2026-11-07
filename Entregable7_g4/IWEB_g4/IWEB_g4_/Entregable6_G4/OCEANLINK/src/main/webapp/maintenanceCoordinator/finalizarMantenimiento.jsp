<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.ActividadMantenimiento" %>
<%@ page import="beans.Mantenimiento" %>
<%@ page import="beans.Segmento" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";

    Mantenimiento m = (Mantenimiento) request.getAttribute("mantenimiento");
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();
    List<ActividadMantenimiento> actividades = (List<ActividadMantenimiento>) request.getAttribute("actividades");
    if (actividades == null) actividades = new ArrayList<>();
    String error = (String) request.getAttribute("error");

    String codigo = m.getCodigoMantenimiento();

    String resultado = request.getParameter("resultado");
    String resumen = request.getParameter("resumen");
    String observacion = request.getParameter("observacion");
    String estadoSegmentos = request.getParameter("estadoSegmentos") == null ? "Operativo" : request.getParameter("estadoSegmentos");

    String[][] resultados = {
            {"Exitoso", "Se cumplió todo lo previsto."},
            {"Parcial", "Quedaron pendientes o parámetros fuera de rango."},
            {"Fallido", "No se pudo completar el trabajo."}
    };
    String[][] estadosSegmento = {
            {"Operativo", "Operativo · servicios restablecidos"},
            {"Degradado", "Degradado · operativo con degradación"},
            {"Fuera de servicio", "Fuera de servicio · servicios interrumpidos"}
    };

    // Tiempo total registrado en las actividades
    int minutosTotales = 0;
    for (ActividadMantenimiento a : actividades) {
        String[] p = a.getTiempoInvertido().split(":");
        minutosTotales += Integer.parseInt(p[0]) * 60 + Integer.parseInt(p[1]);
    }
    String tiempoTotal = String.format("%02d:%02d:00", minutosTotales / 60, minutosTotales % 60);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Finalizar <%= codigo %> | OceanLink</title>
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
                <h1>Finalizar mantenimiento <%= codigo %></h1>
                <p class="small"><%= texto(m.getActividad()) %> · el cierre no se puede deshacer.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <div class="split">
            <form action="<%= servlet %>" class="card" method="post">
                <input type="hidden" name="action" value="finalizar">
                <input type="hidden" name="codigo" value="<%= codigo %>">

                <fieldset>
                    <legend>Resultado</legend>
                    <div class="row">
                        <div class="col">
                            <label>Resultado del mantenimiento <span class="req">*</span></label>
                            <div class="option-cards cols-3">
                                <% for (String[] r : resultados) { %>
                                <label>
                                    <input type="radio" name="resultado" value="<%= r[0] %>" required <%= r[0].equals(resultado) ? "checked" : "" %>>
                                    <span><strong><%= r[0] %></strong><small><%= r[1] %></small></span>
                                </label>
                                <% } %>
                            </div>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col">
                            <label for="estadoSegmentos">Estado en que quedan los segmentos <span class="req">*</span></label>
                            <select id="estadoSegmentos" name="estadoSegmentos" required>
                                <% for (String[] e : estadosSegmento) { %>
                                <option value="<%= e[0] %>" <%= e[0].equals(estadoSegmentos) ? "selected" : "" %>><%= e[1] %></option>
                                <% } %>
                            </select>
                            <span class="hint">Solo cambian los segmentos que siguen "En mantenimiento"; si el Network Operator
                                registró una falla en alguno, se respeta ese estado.</span>
                        </div>
                    </div>
                </fieldset>

                <fieldset>
                    <legend>Informe de cierre</legend>
                    <div class="row">
                        <div class="col">
                            <label for="resumen">Resumen final <span class="req">*</span></label>
                            <textarea class="textarea-sm" id="resumen" name="resumen" maxlength="500" required
                                      placeholder="Ej. Parámetros ópticos dentro de rango"><%= texto(resumen) %></textarea>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col">
                            <label for="observacion">Observación</label>
                            <textarea class="textarea-sm" id="observacion" name="observacion" maxlength="500"
                                      placeholder="Ej. Programar nueva medición en 30 días"><%= texto(observacion) %></textarea>
                            <span class="hint">Opcional. Máximo 500 caracteres.</span>
                        </div>
                    </div>
                </fieldset>

                <div class="footer-action">
                    <a class="ghost" href="<%= servlet %>?action=detalle&codigo=<%= url(codigo) %>">Cancelar</a>
                    <button class="primary" type="submit">Finalizar mantenimiento</button>
                </div>
            </form>

            <aside class="card">
                <div class="card-header">
                    <h2>Resumen de la ejecución</h2>
                </div>
                <dl class="kv">
                    <div><dt>Inicio programado</dt><dd><%= fecha(m.getFechaProgramada()) %> · <%= m.getHoraInicio() == null ? "—" : m.getHoraInicio() %></dd></div>
                    <div><dt>Duración estimada</dt><dd><%= duracion(m.getDuracionEstimada()) %></dd></div>
                    <div><dt>Actividades</dt><dd><%= actividades.size() %></dd></div>
                    <div><dt>Tiempo invertido</dt><dd><%= duracion(tiempoTotal) %></dd></div>
                </dl>

                <div class="table-wrap" style="margin-top: 16px">
                    <table class="table">
                        <thead>
                        <tr><th>Segmento</th><th>Estado actual</th></tr>
                        </thead>
                        <tbody>
                        <% if (segmentos.isEmpty()) { %>
                        <tr><td colspan="2" class="small">Sin segmentos asignados.</td></tr>
                        <% } %>
                        <% for (Segmento s : segmentos) { %>
                        <tr>
                            <td class="cell-main"><%= s.getCodigoSegmento() %><span class="cell-sub"><%= s.getTramo() %></span></td>
                            <td><span class="badge <%= claseEstadoSegmento(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </aside>
        </div>
    </main>
</div>

</body>
</html>
