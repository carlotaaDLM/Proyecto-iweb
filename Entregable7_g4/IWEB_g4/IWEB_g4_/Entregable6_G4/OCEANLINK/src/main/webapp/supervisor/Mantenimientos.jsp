<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="beans.Mantenimiento" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<Mantenimiento> mantenimientos = (List<Mantenimiento>) request.getAttribute("mantenimientos");
    if (mantenimientos == null) mantenimientos = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    Map<String, Integer> porEstado = (Map<String, Integer>) request.getAttribute("porEstado");

    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    String tipo = request.getAttribute("tipo") == null ? "" : (String) request.getAttribute("tipo");
    String desde = request.getAttribute("desde") == null ? "" : (String) request.getAttribute("desde");
    String hasta = request.getAttribute("hasta") == null ? "" : (String) request.getAttribute("hasta");

    String servlet = request.getContextPath() + "/SupervisorServlet";
    String[] estados = {"Programado", "En ejecución", "Finalizado", "Cancelado"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mantenimientos | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="mantenimientos"/>
</jsp:include>

        <main class="content">
            <div class="topbar">
                <div>
                    <h1>Mantenimientos</h1>
                    <p class="small">Mantenimientos programados, en ejecución y realizados en segmentos y estaciones.</p>
                </div>
            </div>

            <section class="stats">
                <a href="<%= servlet %>?action=mantenimientos&estado=Programado" class="stat info">
                    <span class="stat-label">Programados</span>
                    <span class="stat-value"><%= cantidad(porEstado, "Programado") %></span>
                    <span class="small">Pendientes de ejecutar</span>
                </a>
                <a href="<%= servlet %>?action=mantenimientos&estado=<%= url("En ejecución") %>" class="stat warn">
                    <span class="stat-label">En ejecución</span>
                    <span class="stat-value"><%= cantidad(porEstado, "En ejecución") %></span>
                    <span class="small">Trabajos en curso</span>
                </a>
                <a href="<%= servlet %>?action=mantenimientos&estado=Finalizado" class="stat ok">
                    <span class="stat-label">Finalizados</span>
                    <span class="stat-value"><%= cantidad(porEstado, "Finalizado") %></span>
                    <span class="small">Completados</span>
                </a>
                <a href="<%= servlet %>?action=mantenimientos&estado=Cancelado" class="stat ">
                    <span class="stat-label">Cancelados</span>
                    <span class="stat-value"><%= cantidad(porEstado, "Cancelado") %></span>
                    <span class="small">No realizados</span>
                </a>
            </section>

            <form class="card filters" method="get" action="<%= servlet %>">
                <input type="hidden" name="action" value="mantenimientos">
                <div class="col">
                    <label for="estado">Estado</label>
                    <select id="estado" name="estado">
                        <option value="">Todos</option>
                        <% for (String e : estados) { %>
                        <option<%= sel(e.equals(estado)) %>><%= e %></option>
                        <% } %>
                    </select>
                </div>
                <div class="col">
                    <label for="tipo">Tipo</label>
                    <select id="tipo" name="tipo">
                        <option value="">Todos</option>
                        <option<%= sel("Preventivo".equals(tipo)) %>>Preventivo</option>
                        <option<%= sel("Correctivo".equals(tipo)) %>>Correctivo</option>
                    </select>
                </div>
                <div class="col">
                    <label for="desde">Desde</label>
                    <input type="date" id="desde" name="desde" value="<%= texto(desde) %>">
                </div>
                <div class="col">
                    <label for="hasta">Hasta</label>
                    <input type="date" id="hasta" name="hasta" value="<%= texto(hasta) %>">
                </div>
                <div class="col-action botones">
                    <a href="<%= servlet %>?action=mantenimientos" class="ghost">Limpiar</a>
                    <button type="submit" class="primary">Aplicar filtros</button>
                </div>
            </form>

            <section class="card">
                <div class="card-header">
                    <h2>Mantenimientos</h2>
                    <span class="small"><%= paginacion.getTotalRegistros() %> registros · pendientes primero</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Código</th>
                            <th>Actividad</th>
                            <th>Elemento</th>
                            <th>Fecha programada</th>
                            <th class="num">Duración</th>
                            <th>Estado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (mantenimientos.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay mantenimientos que cumplan los filtros.</td></tr>
                        <% } %>
                        <% for (Mantenimiento m : mantenimientos) { %>
                        <%@ include file="filaMantenimiento.jspf" %>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="mantenimientos"/>
                </jsp:include>
            </section>
        </main>

    </div>

</body>
</html>
