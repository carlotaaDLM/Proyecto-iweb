<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ include file="badges.jspf" %>
<%
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String estado = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");

    String servlet = request.getContextPath() + "/NetworkOperatorServlet";
    String[] estados = {"Operativo", "Degradado", "En mantenimiento", "Fuera de servicio"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Estado de segmentos | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/networkOperator/networkOperator.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="estadoSegmentos"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Estado de segmentos</h1>
                <p class="small">Estado operativo actual de cada segmento de la red.</p>
            </div>
        </div>

        <section class="stats">
            <a class="stat ok" href="<%= servlet %>?action=estadoSegmentos&estado=Operativo">
                <span class="stat-label">Operativos</span>
                <span class="stat-value"><%= request.getAttribute("operativos") %></span>
                <span class="small">Funcionan con normalidad</span>
            </a>
            <a class="stat warn" href="<%= servlet %>?action=estadoSegmentos&estado=Degradado">
                <span class="stat-label">Degradados</span>
                <span class="stat-value"><%= request.getAttribute("degradados") %></span>
                <span class="small">Rendimiento afectado</span>
            </a>
            <a class="stat info" href="<%= servlet %>?action=estadoSegmentos&estado=<%= url("En mantenimiento") %>">
                <span class="stat-label">En mantenimiento</span>
                <span class="stat-value"><%= request.getAttribute("enMantenimiento") %></span>
                <span class="small">Intervención programada</span>
            </a>
            <a class="stat bad" href="<%= servlet %>?action=estadoSegmentos&estado=<%= url("Fuera de servicio") %>">
                <span class="stat-label">Fuera de servicio</span>
                <span class="stat-value"><%= request.getAttribute("fueraServicio") %></span>
                <span class="small">Sin tráfico</span>
            </a>
        </section>

        <form action="<%= servlet %>" class="card filters" method="get">
            <input type="hidden" name="action" value="estadoSegmentos"/>
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input id="buscar" name="buscar" placeholder="Código, estación o país" type="text"
                       value="<%= texto(buscar) %>"/>
            </div>
            <div class="col">
                <label for="estado">Estado</label>
                <select id="estado" name="estado">
                    <option value="">Todos</option>
                    <% for (String e : estados) { %>
                    <option <%= e.equals(estado) ? "selected" : "" %>><%= e %></option>
                    <% } %>
                </select>
            </div>
            <div class="col-action botones">
                <a class="ghost" href="<%= servlet %>?action=estadoSegmentos">Limpiar</a>
                <button class="primary" type="submit">Buscar</button>
            </div>
        </form>

        <section class="card">
            <div class="card-header">
                <h2>Segmentos de la red</h2>
                <span class="small"><%= ((beans.Paginacion) request.getAttribute("paginacion")).getTotalRegistros() %> segmentos</span>
            </div>
            <div class="table-wrap">
                <table class="table" id="tabla-segmentos">
                    <thead>
                    <tr>
                        <th>Segmento</th>
                        <th>Tramo</th>
                        <th>Estado</th>
                        <th>Uso de capacidad</th>
                        <th class="num">Servicios</th>
                        <th class="num">Incidencias abiertas</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (segmentos.isEmpty()) { %>
                    <tr>
                        <td colspan="7" class="small">No se encontraron segmentos para los filtros seleccionados.</td>
                    </tr>
                    <% } %>
                    <% for (Segmento seg : segmentos) {
                        String detalle = servlet + "?action=detalleSegmento&codigo=" + url(seg.getCodigoSegmento());
                        double uso = seg.getPorcentajeUso();
                    %>
                    <tr>
                        <td class="cell-main"><a class="cell-link" href="<%= detalle %>"><%= seg.getCodigoSegmento() %></a></td>
                        <td class="tramo">
                            <%= seg.getTramo() %>
                            <span class="cell-sub"><%= seg.getPaisOrigen() %> → <%= seg.getPaisDestino() %></span>
                        </td>
                        <td><span class="badge <%= claseEstadoSegmento(seg.getEstado()) %>"><%= seg.getEstado() %></span></td>
                        <td>
                            <div class="usage <%= claseUso(uso) %>">
                                <div class="usage-bar"><span style="width: <%= String.format(java.util.Locale.US, "%.1f", uso) %>%"></span></div>
                                <span class="usage-value"><%= decimal(uso) %>%</span>
                            </div>
                        </td>
                        <td class="num"><%= seg.getCantidadServicios() %></td>
                        <td class="num">
                            <% if (seg.getIncidenciasAbiertas() > 0) { %>
                            <span class="badge red"><%= seg.getIncidenciasAbiertas() %></span>
                            <% } else { %>
                            <span class="small">0</span>
                            <% } %>
                        </td>
                        <td><a class="ghost btn-sm" href="<%= detalle %>">Ver detalle</a></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="segmentos"/>
            </jsp:include>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Estados de un segmento</h2>
            </div>
            <div class="legend">
                <div><span class="badge green">Operativo</span><p>Funciona con normalidad.</p></div>
                <div><span class="badge yellow">Degradado</span><p>Capacidad reducida o rendimiento afectado.</p></div>
                <div><span class="badge blue">En mantenimiento</span><p>Intervención programada en curso.</p></div>
                <div><span class="badge red">Fuera de servicio</span><p>No disponible por falla o corte.</p></div>
            </div>
        </section>
    </main>
</div>

</body>
</html>
