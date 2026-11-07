<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.ServicioAfectado" %>
<%@ page import="beans.ClienteAfectado" %>
<%@ page import="beans.Incidencia" %>
<%@ page import="beans.Paginacion" %>
<%@ include file="badges.jspf" %>
<%
    List<ServicioAfectado> servicios = (List<ServicioAfectado>) request.getAttribute("servicios");
    if (servicios == null) servicios = new ArrayList<>();
    List<ClienteAfectado> clientesAfectados = (List<ClienteAfectado>) request.getAttribute("clientesAfectados");
    if (clientesAfectados == null) clientesAfectados = new ArrayList<>();
    List<Incidencia> incidenciasFiltro = (List<Incidencia>) request.getAttribute("incidenciasFiltro");
    if (incidenciasFiltro == null) incidenciasFiltro = new ArrayList<>();

    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    Paginacion paginacionClientes = (Paginacion) request.getAttribute("paginacionClientes");

    double[] afectados = (double[]) request.getAttribute("afectados");
    double interrumpidos = (Double) request.getAttribute("interrumpidos");
    int serviciosActivos = (Integer) request.getAttribute("serviciosActivos");
    int clientes = (Integer) request.getAttribute("clientes");

    String buscar = request.getAttribute("buscar") == null ? "" : (String) request.getAttribute("buscar");
    String incidencia = request.getAttribute("incidencia") == null ? "" : (String) request.getAttribute("incidencia");
    String situacion = request.getAttribute("situacion") == null ? "" : (String) request.getAttribute("situacion");

    String servlet = request.getContextPath() + "/SupervisorServlet";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Servicios y clientes afectados | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/supervisor/supervisor.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="afectados"/>
</jsp:include>

        <main class="content">
            <div class="topbar">
                <div>
                    <h1>Servicios y clientes afectados</h1>
                    <p class="small">Servicios activos cuya ruta pasa por un segmento con incidencias activas.</p>
                </div>
            </div>

            <section class="stats">
                <div class="stat warn">
                    <span class="stat-label">Servicios afectados</span>
                    <span class="stat-value"><%= (int) afectados[0] %></span>
                    <span class="small">de <%= serviciosActivos %> activos</span>
                </div>
                <a href="<%= servlet %>?action=afectados&situacion=Interrumpido" class="stat bad">
                    <span class="stat-label">Interrumpidos</span>
                    <span class="stat-value"><%= (int) interrumpidos %></span>
                    <span class="small">Ruta con segmento fuera de servicio</span>
                </a>
                <a href="#clientes" class="stat orange">
                    <span class="stat-label">Clientes afectados</span>
                    <span class="stat-value"><%= (int) afectados[1] %></span>
                    <span class="small">de <%= clientes %> clientes</span>
                </a>
                <div class="stat info">
                    <span class="stat-label">Capacidad afectada</span>
                    <span class="stat-value"><%= numero(afectados[2]) %> <small>Gbps</small></span>
                    <span class="small">Suma de los servicios</span>
                </div>
            </section>

            <form class="card filters" method="get" action="<%= servlet %>">
                <input type="hidden" name="action" value="afectados">
                <div class="col col-wide">
                    <label for="buscar">Buscar cliente</label>
                    <input type="text" id="buscar" name="buscar" value="<%= texto(buscar) %>" placeholder="Razón social o RUC">
                </div>
                <div class="col">
                    <label for="incidencia">Incidencia</label>
                    <select id="incidencia" name="incidencia">
                        <option value="">Todas las activas</option>
                        <% for (Incidencia inc : incidenciasFiltro) { %>
                        <option value="<%= inc.getCodigoIncidencia() %>"<%= sel(inc.getCodigoIncidencia().equals(incidencia)) %>><%= inc.getCodigoIncidencia() %> · <%= inc.getSeveridad() %></option>
                        <% } %>
                    </select>
                </div>
                <div class="col">
                    <label for="situacion">Situación</label>
                    <select id="situacion" name="situacion">
                        <option value="">Todas</option>
                        <option<%= sel("Interrumpido".equals(situacion)) %>>Interrumpido</option>
                        <option<%= sel("Degradado".equals(situacion)) %>>Degradado</option>
                    </select>
                </div>
                <div class="col-action botones">
                    <a href="<%= servlet %>?action=afectados" class="ghost">Limpiar</a>
                    <button type="submit" class="primary">Aplicar filtros</button>
                </div>
            </form>

            <section class="card">
                <div class="card-header">
                    <h2>Servicios afectados</h2>
                    <span class="small"><%= paginacion.getTotalRegistros() %> servicios · interrumpidos primero</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Servicio</th>
                            <th>Cliente</th>
                            <th>Ruta</th>
                            <th class="num">Gbps</th>
                            <th>Incidencias</th>
                            <th>Severidad máx.</th>
                            <th>Situación</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (servicios.isEmpty()) { %>
                        <tr><td colspan="7" class="small">No hay servicios afectados que cumplan los filtros.</td></tr>
                        <% } %>
                        <% for (ServicioAfectado sa : servicios) { %>
                        <tr>
                            <td class="cell-main"><%= codigo("SRV", sa.getIdServicio()) %></td>
                            <td><%= texto(sa.getRazonSocial()) %></td>
                            <td><%= sa.getCodigoRuta() %></td>
                            <td class="num"><%= numero(sa.getCapacidadContratada()) %></td>
                            <td>
                                <%= sa.getIncidencias() %>
                                <span class="cell-sub"><%= sa.getSegmentos() %></span>
                            </td>
                            <td><span class="badge <%= claseSeveridad(sa.getSeveridadMaxima()) %>"><%= sa.getSeveridadMaxima() %></span></td>
                            <td><span class="badge <%= claseSituacion(sa.getSituacion()) %>"><%= sa.getSituacion() %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="etiqueta" value="servicios"/>
                </jsp:include>
            </section>

            <section id="clientes" class="card">
                <div class="card-header">
                    <h2>Clientes afectados</h2>
                    <span class="small"><%= paginacionClientes.getTotalRegistros() %> clientes</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Código</th>
                            <th>Cliente</th>
                            <th>Contacto</th>
                            <th class="num">Servicios afectados</th>
                            <th class="num">Gbps afectados</th>
                            <th>Peor situación</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (clientesAfectados.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay clientes afectados que cumplan los filtros.</td></tr>
                        <% } %>
                        <% for (ClienteAfectado ca : clientesAfectados) { %>
                        <tr>
                            <td class="cell-main"><%= codigo("CLI", ca.getIdCliente()) %></td>
                            <td>
                                <%= texto(ca.getRazonSocial()) %>
                                <span class="cell-sub">RUC <%= ca.getRuc() %></span>
                            </td>
                            <td>
                                <%= texto(ca.getCorreo()) %>
                                <span class="cell-sub">Tel. <%= ca.getTelefono() == null ? "—" : ca.getTelefono() %></span>
                            </td>
                            <td class="num"><%= ca.getServiciosAfectados() %></td>
                            <td class="num"><%= numero(ca.getCapacidadAfectada()) %></td>
                            <td><span class="badge <%= claseSituacion(ca.getSituacion()) %>"><%= ca.getSituacion() %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
                <jsp:include page="/paginacion.jsp">
                    <jsp:param name="atributo" value="paginacionClientes"/>
                    <jsp:param name="parametro" value="paginaCli"/>
                    <jsp:param name="etiqueta" value="clientes"/>
                    <jsp:param name="ancla" value="clientes"/>
                </jsp:include>
            </section>
        </main>

    </div>

</body>
</html>
