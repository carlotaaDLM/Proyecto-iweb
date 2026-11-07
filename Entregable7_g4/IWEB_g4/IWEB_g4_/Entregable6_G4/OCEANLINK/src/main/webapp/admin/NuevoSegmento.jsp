<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.LandingStation" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/SegmentoServlet";
    String error = (String) request.getAttribute("error");
    List<LandingStation> landings = (List<LandingStation>) request.getAttribute("landings");

    // Valores previos (si se vuelve al formulario por un error)
    String codigo = request.getParameter("codigo_segmento") == null ? "" : request.getParameter("codigo_segmento");
    String capacidad = request.getParameter("capacidad_total") == null ? "" : request.getParameter("capacidad_total");
    String origen = request.getParameter("id_origen") == null ? "" : request.getParameter("id_origen");
    String destino = request.getParameter("id_destino") == null ? "" : request.getParameter("id_destino");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Nuevo segmento | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="segmentos"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=lista">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a segmentos
        </a>

        <div class="topbar">
            <div>
                <h1>Nuevo segmento</h1>
                <p class="small">Une dos Landing Stations. El segmento se registra como Operativo y sin capacidad utilizada.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <form action="<%= servlet %>" class="card" method="post">
            <input type="hidden" name="action" value="crear">
            <fieldset>
                <legend>Datos del segmento</legend>
                <div class="row">
                    <div class="col">
                        <label for="codigo">Código <span class="req">*</span></label>
                        <input id="codigo" name="codigo_segmento" type="text" maxlength="12" required
                               placeholder="Ej. SEG-LUR-TRU" value="<%= texto(codigo) %>"/>
                        <span class="hint">De 3 a 12 caracteres. No se podrá cambiar después.</span>
                    </div>
                    <div class="col">
                        <label for="capacidad">Capacidad total (Gbps) <span class="req">*</span></label>
                        <input id="capacidad" name="capacidad_total" type="number" min="1" max="100000" step="0.01" required
                               placeholder="Ej. 8000" value="<%= texto(capacidad) %>"/>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="origen">Estación origen <span class="req">*</span></label>
                        <select id="origen" name="id_origen" required>
                            <option value="" disabled <%= origen.isEmpty() ? "selected" : "" %>>Selecciona una estación</option>
                            <% for (LandingStation ls : landings) { %>
                            <option value="<%= ls.getIdLanding() %>" <%= ls.getIdLanding().equals(origen) ? "selected" : "" %>>
                                <%= ls.getIdLanding() %> - <%= texto(ls.getNombre()) %> (<%= texto(ls.getPais()) %>)
                            </option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="destino">Estación destino <span class="req">*</span></label>
                        <select id="destino" name="id_destino" required>
                            <option value="" disabled <%= destino.isEmpty() ? "selected" : "" %>>Selecciona una estación</option>
                            <% for (LandingStation ls : landings) { %>
                            <option value="<%= ls.getIdLanding() %>" <%= ls.getIdLanding().equals(destino) ? "selected" : "" %>>
                                <%= ls.getIdLanding() %> - <%= texto(ls.getNombre()) %> (<%= texto(ls.getPais()) %>)
                            </option>
                            <% } %>
                        </select>
                        <span class="hint">Debe ser distinta de la estación origen y no repetir un tramo existente.</span>
                    </div>
                </div>
            </fieldset>

            <div class="footer-action">
                <a class="ghost" href="<%= servlet %>?action=lista">Cancelar</a>
                <button class="primary" type="submit">Registrar segmento</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
