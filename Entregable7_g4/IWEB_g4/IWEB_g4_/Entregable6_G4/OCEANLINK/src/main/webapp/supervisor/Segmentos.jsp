<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();
    List<LandingStation> landings = (List<LandingStation>) request.getAttribute("landings");
    if (landings == null) landings = new ArrayList<>();
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");

    double[] capacidad = (double[]) request.getAttribute("capacidadRed");
    int normal = (Integer) request.getAttribute("normal");
    int alta = (Integer) request.getAttribute("alta");
    int critica = (Integer) request.getAttribute("critica");

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    String nivel = request.getAttribute("nivel") == null ? "" : (String) request.getAttribute("nivel");
    String landing = request.getAttribute("landing") == null ? "" : (String) request.getAttribute("landing");

    String servlet = request.getContextPath() + "/SupervisorServlet";
    String[] estados = {"Operativo", "Degradado", "En mantenimiento", "Fuera de servicio"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Segmentos y utilización | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="segmentos"/>
</jsp:include>

        <main class="content">
            <div class="topbar">
                <div>
                    <h1>Segmentos y utilización</h1>
                    <p class="small">Estado y uso de capacidad de cada segmento de fibra submarina.</p>
                </div>
            </div>

            <section class="stats">
                <div class="stat info">
                    <span class="stat-label">Utilización promedio</span>
                    <span class="stat-value"><%= decimal(capacidad[0] > 0 ? capacidad[1] * 100 / capacidad[0] : 0) %>%</span>
                    <span class="small"><%= numero(capacidad[1]) %> de <%= numero(capacidad[0]) %> Gbps</span>
                </div>
                <a href="<%= servlet %>?action=segmentos&nivel=normal" class="stat ok">
                    <span class="stat-label">Normal</span>
                    <span class="stat-value"><%= normal %></span>
                    <span class="small">Menos del 80%</span>
                </a>
                <a href="<%= servlet %>?action=segmentos&nivel=alta" class="stat orange">
                    <span class="stat-label">Alta</span>
                    <span class="stat-value"><%= alta %></span>
                    <span class="small">Entre 80% y 95%</span>
                </a>
                <a href="<%= servlet %>?action=segmentos&nivel=critica" class="stat bad">
                    <span class="stat-label">Crítica</span>
                    <span class="stat-value"><%= critica %></span>
                    <span class="small">Más del 95%</span>
                </a>
            </section>

            <form class="card filters" method="get" action="<%= servlet %>">
                <input type="hidden" name="action" value="segmentos">
                <div class="col col-wide">
                    <label for="buscar">Buscar</label>
                    <input type="text" id="buscar" name="buscar" value="<%= texto(buscar) %>" placeholder="Código, estación o país">
                </div>
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
                    <label for="nivel">Utilización</label>
                    <select id="nivel" name="nivel">
                        <option value="">Todas</option>
                        <option value="normal"<%= sel("normal".equals(nivel)) %>>Normal (&lt; 80%)</option>
                        <option value="alta"<%= sel("alta".equals(nivel)) %>>Alta (80% – 95%)</option>
                        <option value="critica"<%= sel("critica".equals(nivel)) %>>Crítica (&gt; 95%)</option>
                        <option value="minimo80"<%= sel("minimo80".equals(nivel)) %>>Alta o crítica (80% o más)</option>
                    </select>
                </div>
                <div class="col">
                    <label for="landing">Landing Station</label>
                    <select id="landing" name="landing">
                        <option value="">Todas</option>
                        <% for (LandingStation ls : landings) { %>
                        <option value="<%= ls.getIdLanding() %>"<%= sel(ls.getIdLanding().equals(landing)) %>><%= ls.getIdLanding() %> · <%= ls.getNombre().replace("Estación ", "") %></option>
                        <% } %>
                    </select>
                </div>
                <div class="col-action botones">
                    <a href="<%= servlet %>?action=segmentos" class="ghost">Limpiar</a>
                    <button type="submit" class="primary">Aplicar filtros</button>
                </div>
            </form>

            <section class="card">
                <div class="card-header">
                    <h2>Segmentos de la red</h2>
                    <span class="small"><%= paginacion.getTotalRegistros() %> segmentos · ordenados por código</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Segmento</th>
                            <th>Tramo</th>
                            <th class="num">Capacidad (Gbps)</th>
                            <th>Utilización</th>
                            <th>Nivel</th>
                            <th class="num">Disponible (Gbps)</th>
                            <th>Estado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (segmentos.isEmpty()) { %>
                        <tr><td colspan="7" class="small">No hay segmentos que cumplan los filtros.</td></tr>
                        <% } %>
                        <% for (Segmento s : segmentos) { %>
                        <tr>
                            <td class="cell-main"><a href="<%= servlet %>?action=detalleSegmento&codigo=<%= url(s.getCodigoSegmento()) %>" class="cell-link"><%= s.getCodigoSegmento() %></a></td>
                            <td class="tramo">
                                <%= s.getTramo() %>
                                <span class="cell-sub"><%= s.getPaisOrigen() %> → <%= s.getPaisDestino() %></span>
                            </td>
                            <td class="num"><%= numero(s.getCapacidadTotal()) %></td>
                            <td><%= barraUso(s.getPorcentajeOcupacion()) %></td>
                            <td><span class="badge <%= claseNivel(s.getNivelUso()) %>"><%= s.getNivelUso() %></span></td>
                            <td class="num"><%= numero(s.getCapacidadDisponible()) %></td>
                            <td><span class="badge <%= claseEstadoSegmento(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="segmentos"/>
                </jsp:include>
                <p class="small form-note">Utilización = (capacidad utilizada + reservada) / capacidad total, igual que en Capacity Planner. Haz clic en el código de un segmento para ver su detalle.</p>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Niveles de utilización</h2>
                </div>
                <div class="legend cols-3">
                    <div><span class="badge green">Normal</span><p>Menos del 80% de la capacidad total en uso.</p></div>
                    <div><span class="badge orange">Alta</span><p>Entre 80% y 95%: conviene planificar ampliación.</p></div>
                    <div><span class="badge red">Crítica</span><p>Más del 95%: riesgo de saturación del segmento.</p></div>
                </div>
            </section>
        </main>

    </div>

</body>
</html>
