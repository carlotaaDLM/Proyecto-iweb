<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();

    Map<String, Double> tendencias = (Map<String, Double>) request.getAttribute("tendencias");
    if (tendencias == null) tendencias = new HashMap<>();

    String nivel = request.getAttribute("nivel") == null ? "" : (String) request.getAttribute("nivel");
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");

    String servlet = request.getContextPath() + "/CapacityPlannerServlet";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Próximos a saturación | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/capacityPlanner/capacityPlanner.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="saturacion"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Segmentos próximos a saturación</h1>
                <p class="small">Segmentos ordenados de mayor a menor ocupación (utilizada + reservada), con su nivel de alerta.</p>
            </div>
        </div>

        <section class="stats cols-3">
            <a href="<%= servlet %>?action=saturacion&nivel=Normal" class="stat ok<%= "Normal".equals(nivel) ? " selected" : "" %>">
                <span class="stat-label">Normal (menos de 80%)</span>
                <span class="stat-value"><%= request.getAttribute("normales") %> <small>segmentos</small></span>
                <span class="small">Ver estos segmentos</span>
            </a>
            <a href="<%= servlet %>?action=saturacion&nivel=Alta" class="stat warn<%= "Alta".equals(nivel) ? " selected" : "" %>">
                <span class="stat-label">Alta (80% a 95%)</span>
                <span class="stat-value"><%= request.getAttribute("altas") %> <small>segmentos</small></span>
                <span class="small">Ver estos segmentos</span>
            </a>
            <a href="<%= servlet %>?action=saturacion&nivel=<%= url("Crítica") %>" class="stat bad<%= "Crítica".equals(nivel) ? " selected" : "" %>">
                <span class="stat-label">Crítica (más de 95%)</span>
                <span class="stat-value"><%= request.getAttribute("criticas") %> <small>segmentos</small></span>
                <span class="small">Ver estos segmentos</span>
            </a>
        </section>

        <section class="card">
            <form class="card-header" method="get" action="<%= servlet %>" style="align-items: center">
                <input type="hidden" name="action" value="saturacion">
                <h2>Segmentos por ocupación</h2>
                <div class="botones" style="align-items: flex-end">
                    <div style="width: 200px">
                        <label for="nivel" class="small" style="margin-bottom: 4px">Nivel</label>
                        <select id="nivel" name="nivel">
                            <option value="">Todos los niveles</option>
                            <option value="Normal"<%= sel("Normal".equals(nivel)) %>>Normal</option>
                            <option value="Alta"<%= sel("Alta".equals(nivel)) %>>Alta</option>
                            <option value="Crítica"<%= sel("Crítica".equals(nivel)) %>>Crítica</option>
                        </select>
                    </div>
                    <button type="submit" class="primary">Filtrar</button>
                </div>
            </form>

            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th class="num">#</th>
                        <th>Segmento</th>
                        <th>Tramo</th>
                        <th class="num">Total</th>
                        <th class="num">Disponible</th>
                        <th>Ocupación</th>
                        <th>Nivel</th>
                        <th>Estado</th>
                        <th>Tendencia</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% int orden = paginacion.getInicio() + 1;
                       for (Segmento s : segmentos) { %>
                    <tr>
                        <td class="num"><%= orden++ %></td>
                        <td class="cell-main">
                            <a href="<%= servlet %>?action=historial&segmento=<%= url(s.getCodigoSegmento()) %>" class="cell-link"><%= s.getCodigoSegmento() %></a>
                        </td>
                        <td class="tramo"><%= s.getTramo() %></td>
                        <td class="num"><%= numero(s.getCapacidadTotal()) %></td>
                        <td class="num"><strong><%= numero(s.getCapacidadDisponible()) %></strong></td>
                        <td><%= barraUso(s.getPorcentajeOcupacion()) %></td>
                        <td><span class="badge <%= claseNivel(s.getNivelUso()) %>"><%= s.getNivelUso() %></span></td>
                        <td><span class="badge <%= claseEstadoSegmento(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                        <td title="Respecto al mes anterior"><%= tendencia(tendencias.get(s.getCodigoSegmento())) %></td>
                    </tr>
                    <% } %>
                    <% if (segmentos.isEmpty()) { %>
                    <tr>
                        <td colspan="9" class="small">Ningún segmento está en este nivel.</td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="segmentos"/>
            </jsp:include>
            <p class="small table-note">
                La tendencia compara la capacidad utilizada del último mes registrado con la del mes anterior.
            </p>
        </section>
    </main>
</div>

</body>
</html>
