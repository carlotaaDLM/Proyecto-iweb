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
    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String desde = request.getAttribute("desde") == null ? "" : (String) request.getAttribute("desde");
    String hasta = request.getAttribute("hasta") == null ? "" : (String) request.getAttribute("hasta");

    String servlet = request.getContextPath() + "/MantenimientoServlet";
    String listar = servlet + "?action=listar";

    // estado, clase de la tarjeta, texto, opción del menú
    String[][] tarjetas = {
            {"Programado", "", "Por ejecutar", "programado"},
            {"En ejecución", "warn", "Trabajos en curso", "ejecucion"},
            {"Finalizado", "ok", "Cerrados con resultado", "finalizado"},
            {"Cancelado", "bad", "No se realizaron", "cancelado"}
    };

    int total = 0;
    String activoMenu = "listar";
    for (String[] t : tarjetas) {
        Integer c = porEstado == null ? null : porEstado.get(t[0]);
        total += c == null ? 0 : c;
        if (t[0].equals(estado)) activoMenu = t[3];
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Mantenimientos | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/maintenanceCoordinator/mantenimiento.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="<%= activoMenu %>"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Mantenimientos</h1>
                <p class="small">Programación, ejecución y cierre de los mantenimientos de la red submarina.</p>
            </div>
            <a class="primary" href="<%= servlet %>?action=formCrear">Nuevo mantenimiento</a>
        </div>

        <!-- Tarjetas por estado: también filtran el listado -->
        <section class="stats cols-5">
            <% for (String[] t : tarjetas) {
                   Integer cantidad = porEstado == null ? null : porEstado.get(t[0]); %>
            <a class="stat <%= t[1] %><%= t[0].equals(estado) ? " selected" : "" %>" href="<%= listar %>&estado=<%= url(t[0]) %>">
                <span class="stat-label"><%= t[0] %></span>
                <span class="stat-value"><%= cantidad == null ? 0 : cantidad %></span>
                <span class="small"><%= t[2] %></span>
            </a>
            <% } %>
            <a class="stat info<%= estado.isEmpty() ? " selected" : "" %>" href="<%= listar %>">
                <span class="stat-label">Total</span>
                <span class="stat-value"><%= total %></span>
                <span class="small">Registrados</span>
            </a>
        </section>

        <form action="<%= servlet %>" class="card filters" method="get">
            <input type="hidden" name="action" value="listar"/>
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input id="buscar" name="buscar" placeholder="Código, título, segmento o estación" type="text"
                       value="<%= texto(buscar) %>"/>
            </div>
            <div class="col">
                <label for="estado">Estado</label>
                <select id="estado" name="estado">
                    <option value="">Todos</option>
                    <% for (String[] t : tarjetas) { %>
                    <option <%= t[0].equals(estado) ? "selected" : "" %>><%= t[0] %></option>
                    <% } %>
                </select>
            </div>
            <div class="col">
                <label for="tipo">Tipo</label>
                <select id="tipo" name="tipo">
                    <option value="">Todos</option>
                    <option <%= "Preventivo".equals(tipo) ? "selected" : "" %>>Preventivo</option>
                    <option <%= "Correctivo".equals(tipo) ? "selected" : "" %>>Correctivo</option>
                </select>
            </div>
            <div class="col">
                <label for="desde">Desde</label>
                <input id="desde" name="desde" type="date" value="<%= texto(desde) %>"/>
            </div>
            <div class="col">
                <label for="hasta">Hasta</label>
                <input id="hasta" name="hasta" type="date" value="<%= texto(hasta) %>"/>
            </div>
            <div class="col-action botones">
                <a class="ghost" href="<%= listar %>">Limpiar</a>
                <button class="primary" type="submit">Buscar</button>
            </div>
        </form>

        <section class="card">
            <div class="card-header">
                <h2>Mantenimientos registrados</h2>
                <span class="small">En ejecución y programados primero</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Código</th>
                        <th>Mantenimiento</th>
                        <th>Infraestructura</th>
                        <th>Inicio</th>
                        <th>Duración</th>
                        <th>Estado</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (mantenimientos.isEmpty()) { %>
                    <tr>
                        <td colspan="7" class="small">No se encontraron mantenimientos para los filtros seleccionados.</td>
                    </tr>
                    <% } %>
                    <% for (Mantenimiento m : mantenimientos) {
                        String detalle = servlet + "?action=detalle&codigo=" + url(m.getCodigoMantenimiento());
                    %>
                    <tr>
                        <td class="cell-main">
                            <a class="cell-link" href="<%= detalle %>"><%= m.getCodigoMantenimiento() %></a>
                        </td>
                        <td>
                            <%= texto(m.getActividad() == null ? "Sin título" : m.getActividad()) %>
                            <span class="cell-sub"><%= m.getTipo() %></span>
                        </td>
                        <td>
                            <%= m.getSegmentos() == null ? "—" : m.getSegmentos() %>
                            <% if (m.getLandings() != null) { %><span class="cell-sub"><%= m.getLandings() %></span><% } %>
                        </td>
                        <td class="date">
                            <%= fecha(m.getFechaProgramada()) %>
                            <span class="cell-sub"><%= m.getHoraInicio() == null ? "" : m.getHoraInicio() %></span>
                        </td>
                        <td><%= duracion(m.getDuracionEstimada()) %></td>
                        <td><span class="badge <%= claseEstadoMnt(m.getEstado()) %>"><%= m.getEstado() %></span></td>
                        <td>
                            <div class="botones">
                                <% if (m.isProgramado()) { %>
                                <a class="ghost btn-sm" href="<%= servlet %>?action=editar&codigo=<%= url(m.getCodigoMantenimiento()) %>">Editar</a>
                                <% } else if (m.isEnEjecucion()) { %>
                                <a class="ghost btn-sm" href="<%= servlet %>?action=finalizar&codigo=<%= url(m.getCodigoMantenimiento()) %>">Finalizar</a>
                                <% } %>
                                <a class="ghost btn-sm" href="<%= detalle %>">Ver detalle</a>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="mantenimientos"/>
            </jsp:include>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Flujo de un mantenimiento</h2>
            </div>
            <div class="legend">
                <div><span class="badge blue">Programado</span><p>Registrado con fecha, hora y duración. Se puede editar, iniciar o cancelar.</p></div>
                <div><span class="badge yellow">En ejecución</span><p>Los segmentos pasan a "En mantenimiento" y se registran las actividades.</p></div>
                <div><span class="badge green">Finalizado</span><p>Cerrado con un resultado; los segmentos vuelven al estado indicado.</p></div>
                <div><span class="badge grey">Cancelado</span><p>No se realizó. Queda en el historial con el motivo.</p></div>
            </div>
        </section>
    </main>
</div>

</body>
</html>
