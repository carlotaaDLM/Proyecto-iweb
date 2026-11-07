<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashSet" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Set" %>
<%@ page import="beans.ServicioAfectado" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";
    int pasoActual = 3;

    String[] estaciones = (String[]) session.getAttribute("mantEstaciones");
    String[] segmentos = (String[]) session.getAttribute("mantSegmentos");

    List<ServicioAfectado> servicios = (List<ServicioAfectado>) request.getAttribute("servicios");
    if (servicios == null) servicios = new ArrayList<>();

    int activos = 0;
    double capacidad = 0;
    Set<Integer> clientes = new HashSet<>();
    for (ServicioAfectado s : servicios) {
        if ("Activo".equals(s.getEstado())) {
            activos++;
            capacidad += s.getCapacidadContratada();
            clientes.add(s.getIdCliente());
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Nuevo mantenimiento | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/maintenanceCoordinator/mantenimiento.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="nuevo"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=paso2">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a la infraestructura
        </a>

        <div class="topbar">
            <div>
                <h1>Nuevo mantenimiento</h1>
                <p class="small">Revisa qué servicios y clientes se verán afectados durante el mantenimiento.</p>
            </div>
        </div>

        <%@ include file="pasos.jspf" %>

        <div class="split">
            <section class="card">
                <div class="card-header">
                    <h2>Servicios afectados</h2>
                    <span class="small"><%= servicios.size() %> servicios pasan por la infraestructura elegida</span>
                </div>
                <div class="table-wrap">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Servicio</th>
                            <th>Cliente</th>
                            <th>Ruta</th>
                            <th>Segmentos</th>
                            <th class="num">Gbps</th>
                            <th>Estado</th>
                        </tr>
                        </thead>
                        <tbody>
                        <% if (servicios.isEmpty()) { %>
                        <tr><td colspan="6" class="small">No hay servicios que pasen por la infraestructura seleccionada.</td></tr>
                        <% } %>
                        <% for (ServicioAfectado s : servicios) { %>
                        <tr>
                            <td class="cell-main"><%= String.format("SRV-%03d", s.getIdServicio()) %></td>
                            <td>
                                <%= texto(s.getRazonSocial()) %>
                                <span class="cell-sub">RUC <%= s.getRuc() %></span>
                            </td>
                            <td><%= texto(s.getCodigoRuta()) %></td>
                            <td><%= s.getSegmentos() %></td>
                            <td class="num"><%= numero(s.getCapacidadContratada()) %></td>
                            <td><span class="badge <%= claseEstadoSegmento(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </section>

            <aside class="card">
                <div class="card-header">
                    <h2>Impacto estimado</h2>
                </div>
                <dl class="kv">
                    <div><dt>Segmentos</dt><dd><%= segmentos == null || segmentos.length == 0 ? "—" : String.join(", ", segmentos) %></dd></div>
                    <div><dt>Landing Stations</dt><dd><%= estaciones == null || estaciones.length == 0 ? "—" : String.join(", ", estaciones) %></dd></div>
                    <div><dt>Servicios activos</dt><dd class="<%= activos > 0 ? "bad" : "" %>"><%= activos %></dd></div>
                    <div><dt>Clientes afectados</dt><dd class="<%= clientes.size() > 0 ? "bad" : "" %>"><%= clientes.size() %></dd></div>
                    <div><dt>Capacidad afectada</dt><dd><%= numero(capacidad) %> Gbps</dd></div>
                </dl>
                <% if (activos > 0) { %>
                <div class="alert warn" style="margin: 16px 0 0">
                    <strong>Coordina la ventana de mantenimiento</strong>
                    Informa a los clientes con servicios activos antes de la fecha programada.
                </div>
                <% } %>
            </aside>
        </div>

        <form action="<%= servlet %>" class="card" method="post">
            <input type="hidden" name="action" value="continuarPaso3">
            <div class="footer-action" style="border: none; margin: 0; padding: 0">
                <a class="ghost" href="<%= servlet %>?action=cancelarRegistro">Cancelar</a>
                <a class="secondary" href="<%= servlet %>?action=paso2">Atrás</a>
                <button class="primary" type="submit">Continuar</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
