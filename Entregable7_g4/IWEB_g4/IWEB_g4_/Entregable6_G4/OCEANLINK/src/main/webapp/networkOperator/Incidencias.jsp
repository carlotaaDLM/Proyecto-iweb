<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Incidencia" %>
<%@ include file="badges.jspf" %>
<%
    List<Incidencia> listaIncidencias = (List<Incidencia>) request.getAttribute("incidencias");
    if (listaIncidencias == null) listaIncidencias = new ArrayList<>();

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String severidadFiltro = request.getAttribute("severidad") == null ? "" : (String) request.getAttribute("severidad");
    String estadoFiltro = request.getAttribute("estado") == null ? "" : (String) request.getAttribute("estado");
    String desde = request.getAttribute("desde") == null ? "" : (String) request.getAttribute("desde");
    String hasta = request.getAttribute("hasta") == null ? "" : (String) request.getAttribute("hasta");

    String servlet = request.getContextPath() + "/NetworkOperatorServlet";
    String listar = servlet + "?action=listarIncidencias";

    String[] severidades = {"Crítica", "Alta", "Media", "Baja"};
    String[] estados = {"Detectada", "En análisis", "Reparación programada", "En reparación",
            "Servicio restaurado", "Cerrada"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Incidencias | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/networkOperator/networkOperator.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="listarIncidencias"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Incidencias</h1>
                <p class="small">Registro y seguimiento de los eventos de la red, clasificados por severidad.</p>
            </div>
            <a class="primary" href="<%= servlet %>?action=formRegistrar">Registrar incidencia</a>
        </div>

        <section class="stats cols-5">
            <a class="stat bad" href="<%= listar %>&severidad=<%= url("Crítica") %>">
                <span class="stat-label">Críticas</span>
                <span class="stat-value"><%= request.getAttribute("criticas") %></span>
                <span class="small">Interrumpen el servicio</span>
            </a>
            <a class="stat orange" href="<%= listar %>&severidad=Alta">
                <span class="stat-label">Altas</span>
                <span class="stat-value"><%= request.getAttribute("altas") %></span>
                <span class="small">Afectan a varios servicios</span>
            </a>
            <a class="stat warn" href="<%= listar %>&severidad=Media">
                <span class="stat-label">Medias</span>
                <span class="stat-value"><%= request.getAttribute("medias") %></span>
                <span class="small">Degradan el rendimiento</span>
            </a>
            <a class="stat info" href="<%= listar %>&severidad=Baja">
                <span class="stat-label">Bajas</span>
                <span class="stat-value"><%= request.getAttribute("bajas") %></span>
                <span class="small">Sin impacto en el tráfico</span>
            </a>
            <a class="stat" href="<%= listar %>">
                <span class="stat-label">Total</span>
                <span class="stat-value"><%= request.getAttribute("total") %></span>
                <span class="small"><%= request.getAttribute("abiertas") %> abiertas</span>
            </a>
        </section>

        <form action="<%= servlet %>" class="card filters" method="get">
            <input type="hidden" name="action" value="listarIncidencias"/>
            <div class="col col-wide">
                <label for="buscar">Buscar</label>
                <input id="buscar" name="buscar" placeholder="Código, título o segmento" type="text"
                       value="<%= texto(buscar) %>"/>
            </div>
            <div class="col">
                <label for="severidad">Severidad</label>
                <select id="severidad" name="severidad">
                    <option value="">Todas</option>
                    <% for (String s : severidades) { %>
                    <option <%= s.equals(severidadFiltro) ? "selected" : "" %>><%= s %></option>
                    <% } %>
                </select>
            </div>
            <div class="col">
                <label for="estado">Estado</label>
                <select id="estado" name="estado">
                    <option value="">Todos</option>
                    <option value="abiertas" <%= "abiertas".equals(estadoFiltro) ? "selected" : "" %>>Solo abiertas</option>
                    <% for (String e : estados) { %>
                    <option <%= e.equals(estadoFiltro) ? "selected" : "" %>><%= e %></option>
                    <% } %>
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
                <h2>Incidencias registradas</h2>
                <span class="small">más recientes primero</span>
            </div>
            <div class="table-wrap">
                <table class="table" id="tabla-incidencias">
                    <thead>
                    <tr>
                        <th>Código</th>
                        <th>Incidencia</th>
                        <th>Severidad</th>
                        <th>Estado</th>
                        <th>Detección</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (listaIncidencias.isEmpty()) { %>
                    <tr>
                        <td colspan="6" class="small">No se encontraron incidencias para los filtros seleccionados.</td>
                    </tr>
                    <% } %>
                    <% for (Incidencia incidencia : listaIncidencias) {
                        String detalle = servlet + "?action=detalleIncidencia&codigo=" + url(incidencia.getCodigoIncidencia());
                    %>
                    <tr>
                        <td class="cell-main">
                            <a class="cell-link" href="<%= detalle %>"><%= incidencia.getCodigoIncidencia() %></a>
                        </td>
                        <td>
                            <%= texto(incidencia.getTitulo()) %>
                            <span class="cell-sub">
                                <%= incidencia.getCodigoSegmento() == null ? "Sin segmento asociado" : incidencia.getCodigoSegmento() %>
                            </span>
                        </td>
                        <td><span class="badge <%= claseSeveridad(incidencia.getSeveridad()) %>"><%= incidencia.getSeveridad() %></span></td>
                        <td><span class="badge <%= claseEstadoIncidencia(incidencia.getEstado()) %>"><%= incidencia.getEstado() %></span></td>
                        <td class="date"><%= incidencia.getFechaDeteccion() %></td>
                        <td><a class="ghost btn-sm" href="<%= detalle %>">Ver detalle</a></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="incidencias"/>
            </jsp:include>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Niveles de severidad</h2>
            </div>
            <div class="legend">
                <div><span class="badge red">Crítica</span><p>Corte total o pérdida de servicio en uno o más segmentos.</p></div>
                <div><span class="badge orange">Alta</span><p>Falla que afecta a varios servicios o a una estación.</p></div>
                <div><span class="badge yellow">Media</span><p>Degradación del rendimiento sin corte del servicio.</p></div>
                <div><span class="badge blue">Baja</span><p>Alarma o anomalía sin impacto en el tráfico.</p></div>
            </div>
        </section>
    </main>
</div>

</body>
</html>
