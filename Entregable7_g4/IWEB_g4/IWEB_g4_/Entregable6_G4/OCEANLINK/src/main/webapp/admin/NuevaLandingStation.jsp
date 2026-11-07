<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/LandingStationServlet";
    String error = (String) request.getAttribute("error");
    List<String> paises = (List<String>) request.getAttribute("paises");

    // Valores previos (si se vuelve al formulario por un error)
    String id = request.getParameter("id_landing") == null ? "" : request.getParameter("id_landing");
    String nombre = request.getParameter("nombre") == null ? "" : request.getParameter("nombre");
    String ciudad = request.getParameter("ciudad") == null ? "" : request.getParameter("ciudad");
    String pais = request.getParameter("pais") == null ? "" : request.getParameter("pais");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Registrar landing station | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="landing"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=lista">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a Landing Stations
        </a>

        <div class="topbar">
            <div>
                <h1>Registrar landing station</h1>
                <p class="small">La estación se registra como Operativa.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <form action="<%= servlet %>" class="card" method="post">
            <input type="hidden" name="action" value="crear">
            <fieldset>
                <legend>Datos de la estación</legend>
                <div class="row">
                    <div class="col">
                        <label for="codigo">Código <span class="req">*</span></label>
                        <input id="codigo" name="id_landing" type="text" maxlength="10" required
                               placeholder="Ej. LS-TRU" value="<%= texto(id) %>"/>
                        <span class="hint">De 3 a 10 caracteres. No se podrá cambiar después.</span>
                    </div>
                    <div class="col">
                        <label for="nombre">Nombre <span class="req">*</span></label>
                        <input id="nombre" name="nombre" type="text" maxlength="100" required
                               placeholder="Ej. Estación Trujillo" value="<%= texto(nombre) %>"/>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="pais">País <span class="req">*</span></label>
                        <select id="pais" name="pais" required>
                            <option value="" disabled <%= pais.isEmpty() ? "selected" : "" %>>Selecciona un país</option>
                            <% for (String p : paises) { %>
                            <option <%= p.equals(pais) ? "selected" : "" %>><%= p %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="col">
                        <label for="ciudad">Ciudad <span class="req">*</span></label>
                        <input id="ciudad" name="ciudad" type="text" maxlength="50" required
                               placeholder="Ej. Trujillo" value="<%= texto(ciudad) %>"/>
                    </div>
                </div>
            </fieldset>

            <div class="footer-action">
                <a class="ghost" href="<%= servlet %>?action=lista">Cancelar</a>
                <button class="primary" type="submit">Registrar estación</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
