<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.LandingStation" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/LandingStationServlet";
    String error = (String) request.getAttribute("error");
    LandingStation ls = (LandingStation) request.getAttribute("estacion");
    List<String> paises = (List<String>) request.getAttribute("paises");
    List<String> estados = (List<String>) request.getAttribute("estados");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Editar <%= ls.getIdLanding() %> | OceanLink</title>
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
                <h1>Editar landing station</h1>
                <p class="small">El código no se puede cambiar.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <div class="split">
            <form action="<%= servlet %>" class="card" method="post">
                <input type="hidden" name="action" value="actualizar">
                <input type="hidden" name="id_landing" value="<%= ls.getIdLanding() %>">
                <fieldset>
                    <legend>Datos de la estación</legend>
                    <div class="row">
                        <div class="col">
                            <label for="codigo">Código</label>
                            <input id="codigo" type="text" value="<%= ls.getIdLanding() %>" readonly/>
                        </div>
                        <div class="col">
                            <label for="nombre">Nombre <span class="req">*</span></label>
                            <input id="nombre" name="nombre" type="text" maxlength="100" required value="<%= texto(ls.getNombre()) %>"/>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col">
                            <label for="pais">País <span class="req">*</span></label>
                            <select id="pais" name="pais" required>
                                <% for (String p : paises) { %>
                                <option <%= p.equals(ls.getPais()) ? "selected" : "" %>><%= p %></option>
                                <% } %>
                            </select>
                        </div>
                        <div class="col">
                            <label for="ciudad">Ciudad <span class="req">*</span></label>
                            <input id="ciudad" name="ciudad" type="text" maxlength="50" required value="<%= texto(ls.getCiudad()) %>"/>
                        </div>
                        <div class="col">
                            <label for="estado">Estado <span class="req">*</span></label>
                            <select id="estado" name="estado" required>
                                <% for (String e : estados) { %>
                                <option <%= e.equals(ls.getEstado()) ? "selected" : "" %>><%= e %></option>
                                <% } %>
                            </select>
                        </div>
                    </div>
                </fieldset>

                <div class="footer-action">
                    <a class="ghost" href="<%= servlet %>?action=lista">Cancelar</a>
                    <button class="primary" type="submit">Guardar cambios</button>
                </div>
            </form>

            <aside class="card">
                <div class="card-header">
                    <h2>Uso de la estación</h2>
                </div>
                <dl class="kv">
                    <div><dt>Segmentos conectados</dt><dd><%= ls.getCantidadSegmentos() %></dd></div>
                    <div><dt>Incidencias activas</dt><dd class="<%= ls.getIncidenciasActivas() > 0 ? "bad" : "" %>"><%= ls.getIncidenciasActivas() %></dd></div>
                </dl>
                <div class="alert info" style="margin: 16px 0 0">
                    Si la estación deja de operar, cámbiala a Inactiva: sus segmentos e historial se conservan.
                </div>
            </aside>
        </div>
    </main>
</div>

</body>
</html>
