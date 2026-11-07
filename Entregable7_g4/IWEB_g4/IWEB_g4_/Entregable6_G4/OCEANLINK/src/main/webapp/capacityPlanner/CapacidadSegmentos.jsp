<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();

    List<Segmento> todos = (List<Segmento>) request.getAttribute("todos");
    if (todos == null) todos = new ArrayList<>();

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    String nivel = request.getAttribute("nivel") == null ? "" : (String) request.getAttribute("nivel");

    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");

    String servlet = request.getContextPath() + "/CapacityPlannerServlet";

    // Totales de la red (RF07): total - utilizada - reservada = disponible
    double total = 0, utilizada = 0, reservada = 0;
    for (Segmento s : todos) {
        total += s.getCapacidadTotal();
        utilizada += s.getCapacidadUtilizada();
        reservada += s.getCapacidadReservada();
    }
    double disponible = total - utilizada - reservada;
    double base = total > 0 ? total : 1;

    String[] estados = {"Operativo", "Degradado", "En mantenimiento", "Fuera de servicio"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Capacidad de segmentos | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/capacityPlanner/capacityPlanner.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="capacidad"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Capacidad de segmentos</h1>
                <p class="small">Capacidad total, utilizada, reservada y disponible de cada segmento de la red.</p>
            </div>
            <a href="<%= servlet %>?action=formRegistrar" class="primary">Registrar solicitud</a>
        </div>

        <section class="stats" aria-label="Resumen de la red">
            <div class="stat ">
                <span class="stat-label">Capacidad total</span>
                <span class="stat-value"><%= numero(total) %> <small>Gbps</small></span>
                <span class="small"><%= todos.size() %> segmentos en la red</span>
            </div>
            <div class="stat info">
                <span class="stat-label">Utilizada</span>
                <span class="stat-value"><%= numero(utilizada) %> <small>Gbps</small></span>
                <span class="small"><%= decimal(utilizada * 100 / base) %>% del total</span>
            </div>
            <div class="stat warn">
                <span class="stat-label">Reservada</span>
                <span class="stat-value"><%= numero(reservada) %> <small>Gbps</small></span>
                <span class="small"><%= decimal(reservada * 100 / base) %>% del total</span>
            </div>
            <div class="stat ok">
                <span class="stat-label">Disponible</span>
                <span class="stat-value"><%= numero(disponible) %> <small>Gbps</small></span>
                <span class="small"><%= decimal(disponible * 100 / base) %>% del total</span>
            </div>
        </section>

        <form class="card filters" method="get" action="<%= servlet %>">
            <input type="hidden" name="action" value="capacidad">
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input type="text" id="buscar" name="buscar" value="<%= texto(buscar) %>"
                       placeholder="Código, estación o país">
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
                <label for="nivel">Nivel de uso</label>
                <select id="nivel" name="nivel">
                    <option value="">Todos</option>
                    <option value="Normal"<%= sel("Normal".equals(nivel)) %>>Normal (&lt; 80%)</option>
                    <option value="Alta"<%= sel("Alta".equals(nivel)) %>>Alta (80% - 95%)</option>
                    <option value="Crítica"<%= sel("Crítica".equals(nivel)) %>>Crítica (&gt; 95%)</option>
                </select>
            </div>
            <div class="col-action">
                <button type="submit" class="primary">Buscar</button>
            </div>
        </form>

        <section class="card">
            <div class="card-header">
                <h2>Segmentos de la red</h2>
                <span class="small"><%= paginacion.getTotalRegistros() %> segmentos</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Segmento</th>
                        <th>Tramo</th>
                        <th class="num">Total</th>
                        <th class="num">Utilizada</th>
                        <th class="num">Reservada</th>
                        <th class="num">Disponible</th>
                        <th>Ocupación</th>
                        <th>Estado</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% for (Segmento s : segmentos) { %>
                    <tr>
                        <td class="cell-main">
                            <a href="<%= servlet %>?action=historial&segmento=<%= url(s.getCodigoSegmento()) %>"
                               class="cell-link" title="Ver historial de <%= s.getCodigoSegmento() %>"><%= s.getCodigoSegmento() %></a>
                        </td>
                        <td class="tramo">
                            <%= s.getTramo() %>
                            <span class="cell-sub"><%= s.getPaisOrigen() %> → <%= s.getPaisDestino() %></span>
                        </td>
                        <td class="num"><%= numero(s.getCapacidadTotal()) %></td>
                        <td class="num"><%= numero(s.getCapacidadUtilizada()) %></td>
                        <td class="num"><%= numero(s.getCapacidadReservada()) %></td>
                        <td class="num"><strong><%= numero(s.getCapacidadDisponible()) %></strong></td>
                        <td><%= barraUso(s.getPorcentajeOcupacion()) %></td>
                        <td><span class="badge <%= claseEstadoSegmento(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                    </tr>
                    <% } %>
                    <% if (segmentos.isEmpty()) { %>
                    <tr>
                        <td colspan="8" class="small">No hay segmentos que coincidan con la búsqueda.</td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="segmentos"/>
            </jsp:include>
            <p class="small table-note">
                Disponible = total − utilizada − reservada. Ocupación = (utilizada + reservada) / total.
                Ninguna solicitud puede asignar más de lo disponible. Haz clic en un segmento para ver su historial.
            </p>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Niveles de uso</h2>
            </div>
            <div class="legend cols-3">
                <div>
                    <span class="badge green">Normal</span>
                    <p>Menos del 80% de la capacidad total está ocupada.</p>
                </div>
                <div>
                    <span class="badge yellow">Alta utilización</span>
                    <p>Entre 80% y 95%. Conviene planificar ampliaciones.</p>
                </div>
                <div>
                    <span class="badge red">Utilización crítica</span>
                    <p>Más del 95%. No admite nuevas solicitudes grandes.</p>
                </div>
            </div>
        </section>
    </main>
</div>

</body>
</html>
