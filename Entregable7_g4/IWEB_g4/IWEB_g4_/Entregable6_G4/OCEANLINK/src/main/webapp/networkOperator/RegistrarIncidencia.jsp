<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.LandingStation" %>
<%@ include file="badges.jspf" %>
<%
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();

    List<LandingStation> landings = (List<LandingStation>) request.getAttribute("landings");
    if (landings == null) landings = new ArrayList<>();

    String error = (String) request.getAttribute("error");

    // Valores previos (si se vuelve al formulario por un error)
    String titulo = request.getParameter("titulo") == null ? "" : request.getParameter("titulo");
    String descripcion = request.getParameter("descripcion") == null ? "" : request.getParameter("descripcion");
    String severidad = request.getParameter("severidad") == null ? "" : request.getParameter("severidad");
    String fecha = request.getParameter("fecha_deteccion") == null ? "" : request.getParameter("fecha_deteccion");
    String idLanding = request.getParameter("id_landing") == null ? "" : request.getParameter("id_landing");
    String estadoSegmento = request.getParameter("estado_segmento") == null ? "" : request.getParameter("estado_segmento");

    List<String> marcados = new ArrayList<>();
    if (request.getParameterValues("segmentos") != null) {
        marcados = Arrays.asList(request.getParameterValues("segmentos"));
    } else if (request.getAttribute("segmentoMarcado") != null) {
        marcados.add((String) request.getAttribute("segmentoMarcado"));
    }


    String servlet = request.getContextPath() + "/NetworkOperatorServlet";

    String[][] severidades = {
            {"Crítica", "Crítica · corte o pérdida total del servicio"},
            {"Alta", "Alta · afecta a varios servicios"},
            {"Media", "Media · degradación sin corte"},
            {"Baja", "Baja · sin impacto en el tráfico"}
    };
    String[] estadosSegmento = {"Sin cambio", "Degradado", "Fuera de servicio"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Registrar incidencia | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/networkOperator/networkOperator.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="formRegistrar"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=listarIncidencias">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a incidencias
        </a>

        <div class="topbar">
            <div>
                <h1>Registrar incidencia</h1>
                <p class="small">La incidencia se registra en estado Detectada y queda lista para su seguimiento.</p>
            </div>
        </div>

        <ol class="wizard">
            <li class="current"><span>1</span>Datos de la incidencia</li>
            <li><span>2</span>Confirmación</li>
        </ol>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= error %></div>
        <% } %>

        <form action="<%= servlet %>?action=confirmar" class="card" method="post">
            <fieldset>
                <legend>Información general</legend>
                <div class="row">
                    <div class="col">
                        <label for="titulo">Título <span class="req">*</span></label>
                        <input id="titulo" maxlength="100" name="titulo" placeholder="Ej. Pérdida de señal óptica"
                               type="text" value="<%= texto(titulo) %>"/>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="descripcion">Descripción <span class="req">*</span></label>
                        <textarea class="textarea-sm" id="descripcion" maxlength="500" name="descripcion"
                                  placeholder="Qué se detectó, dónde y cómo afecta al tráfico" ><%= texto(descripcion) %></textarea>
                        <span class="hint">Máximo 500 caracteres.</span>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="severidad">Severidad <span class="req">*</span></label>
                        <select id="severidad" name="severidad" >
                            <option disabled value="" <%= severidad.isEmpty() ? "selected" : "" %>>Selecciona la severidad</option>
                            <% for (String[] s : severidades) { %>
                            <option value="<%= s[0] %>" <%= s[0].equals(severidad) ? "selected" : "" %>><%= s[1] %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="fecha">Fecha y hora de detección <span class="req">*</span></label>
                        <input id="fecha" name="fecha_deteccion" type="datetime-local"
                               value="<%= texto(fecha) %>"/>
                    </div>
                </div>
            </fieldset>

            <fieldset>
                <legend>Infraestructura afectada</legend>
                <div class="row">
                    <div class="col">
                        <label for="landing">Landing Station donde se detectó <span class="req">*</span></label>
                        <select id="landing" name="id_landing" >
                            <option disabled value="" <%= idLanding.isEmpty() ? "selected" : "" %>>Selecciona una estación</option>
                            <% for (LandingStation ls : landings) { %>
                            <option value="<%= ls.getIdLanding() %>" <%= ls.getIdLanding().equals(idLanding) ? "selected" : "" %>>
                                <%= ls.getIdLanding() %> · <%= ls.getNombre() %> (<%= ls.getPais() %>)
                            </option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="nuevoEstado">Estado de los segmentos afectados <span class="req">*</span></label>
                        <select id="nuevoEstado" name="estado_segmento" >
                            <% for (String e : estadosSegmento) { %>
                            <option value="<%= e %>" <%= e.equals(estadoSegmento) ? "selected" : "" %>><%= e %></option>
                            <% } %>
                        </select>
                        <span class="hint">Se actualizará el estado de los segmentos marcados.</span>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label>Segmentos afectados <span class="req">*</span></label>
                        <span class="hint" style="margin: 0 0 8px">Marca uno o más segmentos.</span>
                        <div class="table-wrap">
                            <table class="table" id="tabla-segmentos-afectados">
                                <thead>
                                <tr>
                                    <th class="check"></th>
                                    <th>Segmento</th>
                                    <th>Tramo</th>
                                    <th>Estado actual</th>
                                </tr>
                                </thead>
                                <tbody>
                                <% for (Segmento seg : segmentos) {
                                    String id = "chk-" + seg.getCodigoSegmento();
                                %>
                                <tr>
                                    <td class="check">
                                        <input id="<%= id %>" name="segmentos" type="checkbox" value="<%= seg.getCodigoSegmento() %>"
                                               <%= marcados.contains(seg.getCodigoSegmento()) ? "checked" : "" %>/>
                                    </td>
                                    <td class="cell-main"><label for="<%= id %>" style="margin: 0"><%= seg.getCodigoSegmento() %></label></td>
                                    <td class="tramo"><%= seg.getTramo() %></td>
                                    <td><span class="badge <%= claseEstadoSegmento(seg.getEstado()) %>"><%= seg.getEstado() %></span></td>
                                </tr>
                                <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </fieldset>

            <div class="footer-action">
                <a class="ghost" href="<%= servlet %>?action=listarIncidencias">Cancelar</a>
                <button class="primary" type="submit">Continuar</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
