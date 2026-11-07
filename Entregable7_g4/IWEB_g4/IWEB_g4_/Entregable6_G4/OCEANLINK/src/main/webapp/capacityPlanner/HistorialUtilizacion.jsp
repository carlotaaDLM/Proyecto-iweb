<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.UtilizacionHist" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();

    // Del más reciente al más antiguo
    List<UtilizacionHist> registros = (List<UtilizacionHist>) request.getAttribute("registros");
    if (registros == null) registros = new ArrayList<>();

    Segmento seg = (Segmento) request.getAttribute("segmento");
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    String desde = request.getAttribute("desde") == null ? "" : (String) request.getAttribute("desde");
    String hasta = request.getAttribute("hasta") == null ? "" : (String) request.getAttribute("hasta");

    String servlet = request.getContextPath() + "/CapacityPlannerServlet";

    // Indicadores del periodo
    UtilizacionHist maximo = null;
    double suma = 0;
    int mesesAlta = 0;
    for (UtilizacionHist u : registros) {
        if (maximo == null || u.getCapacidadUtilizada() > maximo.getCapacidadUtilizada()) maximo = u;
        suma += u.getCapacidadUtilizada();
        if (u.getPorcentajeUso() >= 80) mesesAlta++;
    }
    double promedio = registros.isEmpty() ? 0 : suma / registros.size();
    UtilizacionHist ultimo = registros.isEmpty() ? null : registros.get(0);

    Double variacion = null;
    if (registros.size() >= 2 && registros.get(1).getCapacidadUtilizada() > 0) {
        variacion = (registros.get(0).getCapacidadUtilizada() - registros.get(1).getCapacidadUtilizada())
                * 100.0 / registros.get(1).getCapacidadUtilizada();
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Historial de utilización | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/capacityPlanner/capacityPlanner.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="historial"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Historial de utilización</h1>
                <p class="small">Evolución mensual de la capacidad de un segmento, aunque ya no esté en uso.</p>
            </div>
        </div>

        <form class="card filters" method="get" action="<%= servlet %>">
            <input type="hidden" name="action" value="historial">
            <div class="col col-wide">
                <label for="segmento">Segmento</label>
                <select id="segmento" name="segmento">
                    <% for (Segmento s : segmentos) { %>
                    <option value="<%= s.getCodigoSegmento() %>"<%= sel(seg != null && s.getCodigoSegmento().equals(seg.getCodigoSegmento())) %>>
                        <%= s.getCodigoSegmento() %> · <%= s.getTramo() %>
                    </option>
                    <% } %>
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
            <div class="col-action">
                <button type="submit" class="primary">Actualizar</button>
            </div>
        </form>

        <% if (seg != null) { %>
        <section class="stats">
            <div class="stat ">
                <span class="stat-label">Capacidad total</span>
                <span class="stat-value"><%= numero(seg.getCapacidadTotal()) %> <small>Gbps</small></span>
                <span class="small"><%= seg.getCodigoSegmento() %> · <%= seg.getTramo() %></span>
            </div>
            <div class="stat info">
                <span class="stat-label">Utilización actual</span>
                <span class="stat-value"><%= numero(seg.getCapacidadUtilizada()) %> <small>Gbps</small></span>
                <span class="small"><%= decimal(seg.getPorcentajeUso()) %>% · <%= ultimo == null ? "sin registros" : mes(ultimo.getFecha()) %></span>
            </div>
            <div class="stat warn">
                <span class="stat-label">Máximo del periodo</span>
                <span class="stat-value"><%= maximo == null ? "—" : numero(maximo.getCapacidadUtilizada()) %> <small>Gbps</small></span>
                <span class="small"><%= maximo == null ? "—" : decimal(maximo.getPorcentajeUso()) + "% · " + mes(maximo.getFecha()) %></span>
            </div>
            <div class="stat ok">
                <span class="stat-label">Promedio del periodo</span>
                <span class="stat-value"><%= numero(promedio) %> <small>Gbps</small></span>
                <span class="small"><%= decimal(seg.getCapacidadTotal() > 0 ? promedio * 100 / seg.getCapacidadTotal() : 0) %>% de la capacidad</span>
            </div>
        </section>

        <div>
            <section class="card">
                <div class="card-header">
                    <h2>Análisis del segmento</h2>
                </div>
                <dl class="kv">
                    <div><dt>Nivel actual</dt><dd><span class="badge <%= claseNivel(seg.getNivelUso()) %>"><%= textoNivel(seg.getNivelUso()) %></span></dd></div>
                    <div><dt>Estado</dt><dd><span class="badge <%= claseEstadoSegmento(seg.getEstado()) %>"><%= seg.getEstado() %></span></dd></div>
                    <div><dt>Variación vs. mes anterior</dt><dd><%= tendencia(variacion) %></dd></div>
                    <div><dt>Meses en alta utilización</dt><dd><%= mesesAlta %> de <%= registros.size() %></dd></div>
                    <div><dt>Reservada actual</dt><dd><%= numero(seg.getCapacidadReservada()) %> Gbps</dd></div>
                    <div><dt>Disponible actual</dt><dd><%= numero(seg.getCapacidadDisponible()) %> Gbps</dd></div>
                </dl>
                <p class="small form-note">
                    Desde el 80% de la capacidad el segmento entra en alta utilización. El nivel actual
                    cuenta también lo reservado.
                </p>
            </section>
        </div>

        <section class="card">
            <div class="card-header">
                <h2>Historial detallado</h2>
                <span class="small"><%= registros.size() %> registros</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Mes</th>
                        <th class="num">Total</th>
                        <th class="num">Utilizada</th>
                        <th class="num">Disponible</th>
                        <th>Uso</th>
                        <th>Variación</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% // solo las filas de la página actual (la variación usa el mes siguiente de la lista)
                       for (int i = paginacion.getInicio(); i < paginacion.getFin(); i++) {
                        UtilizacionHist u = registros.get(i);
                        Double var = null;
                        if (i + 1 < registros.size() && registros.get(i + 1).getCapacidadUtilizada() > 0) {
                            var = (u.getCapacidadUtilizada() - registros.get(i + 1).getCapacidadUtilizada())
                                    * 100.0 / registros.get(i + 1).getCapacidadUtilizada();
                        }
                    %>
                    <tr>
                        <td><%= mes(u.getFecha()) %></td>
                        <td class="num"><%= numero(u.getCapacidadTotal()) %></td>
                        <td class="num"><%= numero(u.getCapacidadUtilizada()) %></td>
                        <td class="num"><%= numero(u.getCapacidadDisponible()) %></td>
                        <td><%= barraUso(u.getPorcentajeUso()) %></td>
                        <td><%= tendencia(var) %></td>
                    </tr>
                    <% } %>
                    <% if (registros.isEmpty()) { %>
                    <tr>
                        <td colspan="6" class="small">No hay registros en el periodo elegido.</td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="registros"/>
            </jsp:include>
        </section>
        <% } %>
    </main>
</div>

</body>
</html>
