<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Ruta" %>
<%@ page import="beans.Paginacion" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Servicio" %>
<%@ include file="badges.jspf" %>
<%
    List<Servicio> servicios = (List<Servicio>) request.getAttribute("servicios");
    if (servicios == null) servicios = new ArrayList<>();

    List<Ruta> rutas = (List<Ruta>) request.getAttribute("rutas");
    if (rutas == null) rutas = new ArrayList<>();

    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    if (segmentos == null) segmentos = new ArrayList<>();

    Servicio servicio = (Servicio) request.getAttribute("servicio");
    Ruta rutaServicio = (Ruta) request.getAttribute("rutaServicio");

    String msg = (String) request.getAttribute("msg");
    Paginacion paginacion = (Paginacion) request.getAttribute("paginacion");
    String error = (String) request.getAttribute("error");

    String servlet = request.getContextPath() + "/CapacityPlannerServlet";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Rutas de servicios | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/capacityPlanner/capacityPlanner.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="rutas"/>
</jsp:include>

    <main class="content">
        <div class="topbar">
            <div>
                <h1>Rutas de servicios</h1>
                <p class="small">Consulta qué segmentos usa cada servicio y administra las rutas de la red.</p>
            </div>
            <a href="#dialogoRuta" class="primary">Registrar ruta</a>
        </div>

        <% if ("rutaCreada".equals(msg)) { %>
        <div class="alert ok"><strong>Ruta registrada</strong>Ya se puede proponer para nuevas solicitudes.</div>
        <% } else if ("rutaBorrada".equals(msg)) { %>
        <div class="alert ok"><strong>Ruta eliminada</strong> Se eliminó la ruta. Sus servicios se eliminaron y su capacidad se liberó en los segmentos.</div>
        <% } else if ("rutaActualizada".equals(msg)) { %>
        <div class="alert ok"><strong>Ruta actualizada</strong>Se cambió el estado de la ruta.</div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert error"><strong>No se pudo completar la acción</strong><%= texto(error) %></div>
        <% } %>

        <form class="card filters" method="get" action="<%= servlet %>">
            <input type="hidden" name="action" value="rutas">
            <div class="col col-wide">
                <label for="servicio">Servicio</label>
                <select id="servicio" name="id_servicio">
                    <% for (Servicio s : servicios) { %>
                    <option value="<%= s.getIdServicio() %>"<%= sel(servicio != null && s.getIdServicio() == servicio.getIdServicio()) %>>
                        <%= s.getCodigo() %> · <%= texto(s.getRazonSocialCliente()) %>
                    </option>
                    <% } %>
                </select>
            </div>
            <div class="col-action">
                <button type="submit" class="primary">Ver ruta</button>
            </div>
        </form>

        <% if (servicio != null && rutaServicio != null) {
            Segmento primero = rutaServicio.getSegmentos().isEmpty() ? null : rutaServicio.getSegmentos().get(0);
            Segmento ultimo = rutaServicio.getSegmentos().isEmpty() ? null
                    : rutaServicio.getSegmentos().get(rutaServicio.getSegmentos().size() - 1);
        %>
        <div class="split">
            <section class="card">
                <div class="card-header">
                    <h2>Ruta del servicio</h2>
                    <span class="small"><%= rutaServicio.getSegmentos().size() %> segmentos</span>
                </div>
                <p class="route-title"><%= rutaServicio.getCodigo() %></p>
                <p class="small" style="margin: 0"><%= rutaServicio.getTramo() %></p>
                <% if (primero != null) { %>
                <div class="route-line">
                    <div class="route-node"><span></span><strong><%= primero.getIdOrigen().replace("LS-", "") %></strong>
                        <small><%= primero.getNombreOrigen().replace("Estación ", "") %></small></div>
                    <% for (Segmento s : rutaServicio.getSegmentos()) { %>
                    <div class="route-node"><span></span><strong><%= s.getIdDestino().replace("LS-", "") %></strong>
                        <small><%= s.getNombreDestino().replace("Estación ", "") %></small></div>
                    <% } %>
                </div>
                <% } %>
            </section>

            <section class="card">
                <div class="card-header">
                    <h2>Detalle del servicio</h2>
                    <span class="badge <%= "Activo".equals(servicio.getEstado()) ? "green" : "blue" %>"><%= servicio.getEstado() %></span>
                </div>
                <dl class="kv">
                    <div><dt>Servicio</dt><dd><%= servicio.getCodigo() %></dd></div>
                    <div><dt>Cliente</dt><dd><%= texto(servicio.getRazonSocialCliente()) %></dd></div>
                    <div><dt>Origen</dt><dd><%= primero == null ? "—" : primero.getNombreOrigen().replace("Estación ", "") + " (" + primero.getPaisOrigen() + ")" %></dd></div>
                    <div><dt>Destino</dt><dd><%= ultimo == null ? "—" : ultimo.getNombreDestino().replace("Estación ", "") + " (" + ultimo.getPaisDestino() + ")" %></dd></div>
                    <div><dt>Capacidad contratada</dt><dd><%= numero(servicio.getCapacidadContratada()) %> Gbps</dd></div>
                    <div><dt><%= "Activo".equals(servicio.getEstado()) ? "Fecha de activación" : "Activación prevista" %></dt><dd><%= fecha(servicio.getFechaActivacion()) %></dd></div>
                </dl>
            </section>
        </div>

        <section class="card">
            <div class="card-header">
                <h2>Segmentos usados (en orden)</h2>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th class="num">#</th>
                        <th>Segmento</th>
                        <th>Tramo</th>
                        <th class="num">Total</th>
                        <th class="num">Asignada al servicio</th>
                        <th>Ocupación del segmento</th>
                        <th>Estado</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% int orden = 1;
                       for (Segmento s : rutaServicio.getSegmentos()) { %>
                    <tr>
                        <td class="num"><%= orden++ %></td>
                        <td class="cell-main"><%= s.getCodigoSegmento() %></td>
                        <td class="tramo"><%= s.getTramo() %></td>
                        <td class="num"><%= numero(s.getCapacidadTotal()) %></td>
                        <td class="num"><%= numero(servicio.getCapacidadContratada()) %></td>
                        <td><%= barraUso(s.getPorcentajeOcupacion()) %></td>
                        <td><span class="badge <%= claseEstadoSegmento(s.getEstado()) %>"><%= s.getEstado() %></span></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </section>
        <% } %>

        <section class="card">
            <div class="card-header">
                <h2>Rutas registradas</h2>
                <span class="small"><%= paginacion.getTotalRegistros() %> rutas</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Ruta</th>
                        <th>Recorrido</th>
                        <th class="num">Segmentos</th>
                        <th class="num">Disponible</th>
                        <th class="num">Servicios</th>
                        <th>Estado</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <% for (Ruta r : rutas) {
                        boolean activa = "Activa".equals(r.getEstado());
                    %>
                    <tr>
                        <td class="cell-main"><%= r.getCodigo() %></td>
                        <td><%= r.getRecorrido() %></td>
                        <td class="num"><%= r.getSegmentos().size() %></td>
                        <td class="num"><%= numero(r.getCapacidadDisponible()) %></td>
                        <td class="num"><%= r.getCantidadServicios() %></td>
                        <td>
                            <% if (!activa) { %>
                            <span class="badge grey">Inactiva</span>
                            <% } else if (r.isTieneSegmentoFueraServicio()) { %>
                            <span class="badge red">Con segmento fuera de servicio</span>
                            <% } else { %>
                            <span class="badge green">Activa</span>
                            <% } %>
                        </td>
                        <td>
                            <div class="botones">
                                <form method="post" action="<%= servlet %>">
                                    <input type="hidden" name="action" value="estadoRuta">
                                    <input type="hidden" name="id" value="<%= r.getIdRuta() %>">
                                    <input type="hidden" name="estado" value="<%= activa ? "Inactiva" : "Activa" %>">
                                    <button type="submit" class="ghost btn-sm"><%= activa ? "Desactivar" : "Activar" %></button>
                                </form>
                                <a href="#eliminarRuta<%= r.getIdRuta() %>" class="danger btn-sm">Eliminar</a>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <jsp:include page="/paginacion.jsp">
                <jsp:param name="etiqueta" value="rutas"/>
            </jsp:include>
            <p class="small table-note">
                Un servicio no puede activarse si alguno de los segmentos de su ruta está Fuera de servicio.
                Una ruta Inactiva no se propone para nuevas solicitudes. Al eliminar una ruta también se eliminan
                sus servicios y las solicitudes que la usaban quedan sin ruta propuesta.
            </p>
        </section>
    </main>
</div>

<%-- Confirmación para eliminar cada ruta (se abre con el enlace #eliminarRuta..., sin JavaScript) --%>
<% for (Ruta r : rutas) { %>
<div id="eliminarRuta<%= r.getIdRuta() %>" class="overlay"><div class="modal">
    <form method="post" action="<%= servlet %>">
        <input type="hidden" name="action" value="borrarRuta">
        <input type="hidden" name="id" value="<%= r.getIdRuta() %>">
        <h2>¿Eliminar la ruta <%= r.getCodigo() %>?</h2>
        <p><%= r.getRecorrido() %></p>
        <% if (r.getCantidadServicios() > 0 || r.getCantidadSolicitudes() > 0) { %>
        <p>
            Esta ruta está en uso: se eliminarán sus <strong><%= r.getCantidadServicios() %> servicio(s)</strong>
            (su capacidad se libera en los segmentos) y <strong><%= r.getCantidadSolicitudes() %> solicitud(es)</strong>
            quedarán sin ruta propuesta.
        </p>
        <% } %>
        <p>Esta acción no se puede deshacer.</p>
        <div class="botones" style="margin-top: 20px">
            <a href="#" class="ghost">Cancelar</a>
            <button type="submit" class="danger solid">Eliminar ruta</button>
        </div>
    </form>
</div></div>
<% } %>

<div id="dialogoRuta" class="overlay"><div class="modal">
    <form method="post" action="<%= servlet %>">
        <input type="hidden" name="action" value="crearRuta">
        <h2>Registrar una ruta</h2>
        <p>Elige los segmentos en orden. Cada segmento debe empezar en la estación donde termina el anterior.</p>

        <label for="codigo">Código de la ruta</label>
        <input type="text" id="codigo" name="codigo" maxlength="20" required placeholder="Ej. RUTA-LIM-HER-02">

        <% for (int i = 1; i <= 4; i++) { %>
        <label for="segmento<%= i %>" style="margin-top: 14px">Segmento <%= i %><%= i == 1 ? "" : " (opcional)" %></label>
        <select id="segmento<%= i %>" name="segmento<%= i %>"<%= i == 1 ? " required" : "" %>>
            <option value=""><%= i == 1 ? "Selecciona el primer segmento" : "—" %></option>
            <% for (Segmento s : segmentos) { %>
            <option value="<%= s.getCodigoSegmento() %>"><%= s.getCodigoSegmento() %> · <%= s.getTramo() %> · <%= numero(s.getCapacidadDisponible()) %> Gbps libres</option>
            <% } %>
        </select>
        <% } %>

        <div class="botones" style="margin-top: 20px">
            <a href="#" class="ghost">Cancelar</a>
            <button type="submit" class="primary">Registrar ruta</button>
        </div>
    </form>
</div></div>

</body>
</html>
