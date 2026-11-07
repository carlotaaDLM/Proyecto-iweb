<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Incidencia" %>
<%@ page import="beans.HistorialIncidencia" %>
<%@ include file="badges.jspf" %>
<%
    Incidencia inc = (Incidencia) request.getAttribute("incidencia");

    List<HistorialIncidencia> historialInc = (List<HistorialIncidencia>) request.getAttribute("historialIncidencia");
    if (historialInc == null) historialInc = new ArrayList<>();

    List<HistorialIncidencia> cambios = (List<HistorialIncidencia>) request.getAttribute("cambios");
    if (cambios == null) cambios = new ArrayList<>();

    List<Incidencia> listaIncidencias = (List<Incidencia>) request.getAttribute("listaIncidencias");
    if (listaIncidencias == null) listaIncidencias = new ArrayList<>();

    String codigo = request.getAttribute("codigo") == null ? "" : (String) request.getAttribute("codigo");
    String severidad = request.getAttribute("severidad") == null ? "" : (String) request.getAttribute("severidad");
    String desde = request.getAttribute("desde") == null ? "" : (String) request.getAttribute("desde");
    String hasta = request.getAttribute("hasta") == null ? "" : (String) request.getAttribute("hasta");

    String servlet = request.getContextPath() + "/NetworkOperatorServlet";
    String[] severidades = {"Crítica", "Alta", "Media", "Baja"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Historial de incidencias | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/networkOperator/networkOperator.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="historial"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Historial de incidencias</h1>
                <p class="small">Registro cronológico de cambios de estado y observaciones.</p>
            </div>
        </div>

        <form action="<%= servlet %>" class="card filters" method="get">
            <input type="hidden" name="action" value="historial"/>
            <div class="col col-wide">
                <label for="codigo">Incidencia</label>
                <select id="codigo" name="codigo">
                    <option value="">Todas</option>
                    <% for (Incidencia i : listaIncidencias) { %>
                    <option value="<%= i.getCodigoIncidencia() %>" <%= i.getCodigoIncidencia().equals(codigo) ? "selected" : "" %>>
                        <%= i.getCodigoIncidencia() %> · <%= texto(i.getTitulo()) %>
                    </option>
                    <% } %>
                </select>
            </div>
            <div class="col">
                <label for="severidad">Severidad</label>
                <select id="severidad" name="severidad">
                    <option value="">Todas</option>
                    <% for (String s : severidades) { %>
                    <option <%= s.equals(severidad) ? "selected" : "" %>><%= s %></option>
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
                <a class="ghost" href="<%= servlet %>?action=historial">Limpiar</a>
                <button class="primary" type="submit">Buscar</button>
            </div>
        </form>

        <% if (inc != null) { %>
        <section class="card">
            <div class="card-header">
                <div>
                    <span class="stat-label">
                        <a class="cell-link" href="<%= servlet %>?action=detalleIncidencia&codigo=<%= url(inc.getCodigoIncidencia()) %>"><%= inc.getCodigoIncidencia() %></a>
                    </span>
                    <h2 class="record-title"><%= texto(inc.getTitulo()) %></h2>
                    <p class="record-desc">
                        <%= inc.getCodigoSegmento() %> · <%= inc.getTramo() %> · estado actual: <%= inc.getEstado() %>
                    </p>
                </div>
                <span class="badge <%= claseSeveridad(inc.getSeveridad()) %>"><%= inc.getSeveridad() %></span>
            </div>
            <div class="table-wrap">
                <table class="table" id="tabla-historial-incidencia">
                    <thead>
                    <tr>
                        <th>Fecha y hora</th>
                        <th>Estado anterior</th>
                        <th>Estado nuevo</th>
                        <th>Usuario</th>
                        <th>Observaciones</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% for (HistorialIncidencia h : historialInc) { %>
                    <tr>
                        <td class="date"><%= h.getFecha() %></td>
                        <td>
                            <% if (h.getEstadoAnterior() == null) { %>
                            <span class="small">—</span>
                            <% } else { %>
                            <span class="badge <%= claseEstadoIncidencia(h.getEstadoAnterior()) %>"><%= h.getEstadoAnterior() %></span>
                            <% } %>
                        </td>
                        <td><span class="badge <%= claseEstadoIncidencia(h.getEstado()) %>"><%= h.getEstado() %></span></td>
                        <td class="date"><%= h.getUsuario() == null ? "—" : h.getUsuario() %></td>
                        <td class="obs"><%= h.getObservacion() == null ? "—" : texto(h.getObservacion()) %></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </section>
        <% } %>

        <section class="card">
            <div class="card-header">
                <h2><%= inc == null ? "Cambios en todas las incidencias" : "Cambios registrados" %></h2>
                <span class="small">más recientes primero</span>
            </div>
            <div class="table-wrap">
                <table class="table" id="tabla-historial-global">
                    <thead>
                    <tr>
                        <th>Fecha y hora</th>
                        <th>Código</th>
                        <th>Incidencia</th>
                        <th>Cambio de estado</th>
                        <th>Usuario</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (cambios.isEmpty()) { %>
                    <tr><td colspan="5" class="small">No hay cambios para los filtros seleccionados.</td></tr>
                    <% } %>
                    <% for (HistorialIncidencia h : cambios) { %>
                    <tr>
                        <td class="date"><%= h.getFecha() %></td>
                        <td class="cell-main">
                            <a class="cell-link" href="<%= servlet %>?action=detalleIncidencia&codigo=<%= url(h.getCodigoIncidencia()) %>"><%= h.getCodigoIncidencia() %></a>
                        </td>
                        <td><%= texto(h.getTituloIncidencia()) %></td>
                        <td>
                            <% if (h.getEstadoAnterior() == null) { %>
                            <span class="small">—</span>
                            <% } else { %>
                            <span class="badge <%= claseEstadoIncidencia(h.getEstadoAnterior()) %>"><%= h.getEstadoAnterior() %></span>
                            <% } %>
                            <span class="arrow">→</span>
                            <span class="badge <%= claseEstadoIncidencia(h.getEstado()) %>"><%= h.getEstado() %></span>
                        </td>
                        <td><%= h.getUsuario() == null ? "—" : h.getUsuario() %></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="cambios"/>
            </jsp:include>
        </section>
    </main>
</div>

</body>
</html>
