<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Incidencia" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.Servicio" %>
<%@ page import="beans.Cliente" %>
<%@ page import="beans.HistorialIncidencia" %>
<%@ page import="dao.IncidenciaDAO" %>
<%@ include file="badges.jspf" %>
<%
    Incidencia inc = (Incidencia) request.getAttribute("incidencia");
    String siguienteEstado = (String) request.getAttribute("siguienteEstado");
    String msg = (String) request.getAttribute("msg");
    String ultimoCambio = request.getAttribute("ultimoCambio") == null
            ? inc.getFechaDeteccionIso() : (String) request.getAttribute("ultimoCambio");

    List<Segmento> segmentosInc = (List<Segmento>) request.getAttribute("segmentosIncidencia");
    if (segmentosInc == null) segmentosInc = new ArrayList<>();

    List<Servicio> servicios = (List<Servicio>) request.getAttribute("servicios");
    if (servicios == null) servicios = new ArrayList<>();

    List<Cliente> clientes = (List<Cliente>) request.getAttribute("clientes");
    if (clientes == null) clientes = new ArrayList<>();

    List<HistorialIncidencia> historial = (List<HistorialIncidencia>) request.getAttribute("historial");
    if (historial == null) historial = new ArrayList<>();

    String servlet = request.getContextPath() + "/NetworkOperatorServlet";
    String estado = inc.getEstado();

    boolean abierta = !"Servicio restaurado".equals(estado) && !"Cerrada".equals(estado);
    boolean puedeRestaurar = "En reparación".equals(estado);

    // Situación de los servicios según el estado de los segmentos
    boolean hayCorte = false;
    for (Segmento s : segmentosInc) {
        if ("Fuera de servicio".equals(s.getEstado())) hayCorte = true;
    }
    String situacionServicio = !abierta ? "Restablecido" : (hayCorte ? "Interrumpido" : "Afectado");
    String situacionCliente = !abierta ? "Restablecido" : (hayCorte ? "Sin servicio" : "Afectado");
    String claseSituacion = !abierta ? "green" : (hayCorte ? "red" : "yellow");

    // Fecha de cada estado del flujo (tomada del historial)
    String[] flujo = IncidenciaDAO.FLUJO;
    int posicionActual = java.util.Arrays.asList(flujo).indexOf(estado);

    String[] severidades = {"Crítica", "Alta", "Media", "Baja"};
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Detalle de incidencia | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/networkOperator/networkOperator.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="listarIncidencias"/>
</jsp:include>

    <main class="content">

        <a href="<%= servlet %>?action=listarIncidencias" class="back-link">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
            Volver a incidencias
        </a>

        <div class="topbar">
            <div>
                <h1>Detalle de incidencia</h1>
                <p class="small">Seguimiento, servicios y clientes afectados.</p>
            </div>
            <div class="botones">
                <a href="#dialogoEliminar" class="danger">Eliminar</a>
                <% if (puedeRestaurar) { %>
                <a href="#dialogoRestauracion" class="primary">Registrar restauración del servicio</a>
                <% } %>
            </div>
        </div>

        <% if ("registrada".equals(msg)) { %>
        <div class="alert ok">
            <strong>Incidencia <%= inc.getCodigoIncidencia() %> registrada</strong>
            Quedó en estado Detectada.
        </div>
        <% } else if ("faltaObservacion".equals(msg)) { %>
        <div class="alert error">
            <strong>No se guardó el cambio</strong>
            Escribe una observación antes de guardar.
        </div>
        <% } else if ("fechaInvalida".equals(msg)) { %>
        <div class="alert error">
            <strong>No se registró la restauración</strong>
            Ingresa una fecha y hora válidas: entre el último cambio de la incidencia y ahora.
        </div>
        <% } else if ("restaurada".equals(msg) && "Servicio restaurado".equals(estado)) { %>
        <div class="alert ok">
            <strong>Servicio restaurado</strong>
            Cuando confirmes la estabilidad del enlace podrás cerrar la incidencia.
        </div>
        <% } %>

        <section class="card">
            <div class="card-header">
                <div>
                    <span class="stat-label"><%= inc.getCodigoIncidencia() %></span>
                    <h2 class="record-title"><%= texto(inc.getTitulo()) %></h2>
                    <p class="record-desc"><%= texto(inc.getDescripcion()) %></p>
                </div>
                <span class="badge <%= claseSeveridad(inc.getSeveridad()) %>"><%= inc.getSeveridad() %></span>
            </div>

            <div class="record-meta">
                <div>
                    <span class="stat-label">Estado actual</span>
                    <span class="badge <%= claseEstadoIncidencia(estado) %>"><%= estado %></span>
                </div>
                <div>
                    <span class="stat-label">Detectada</span>
                    <%= inc.getFechaDeteccion() %>
                </div>
                <div>
                    <span class="stat-label">Registrada por</span>
                    <%= inc.getRegistradaPor() == null ? "—" : inc.getRegistradaPor() %>
                </div>
                <div>
                    <span class="stat-label">Infraestructura afectada</span>
                    <div class="chips">
                        <% for (Segmento s : segmentosInc) { %>
                        <a href="<%= servlet %>?action=detalleSegmento&codigo=<%= url(s.getCodigoSegmento()) %>"
                           class="chip" title="<%= s.getTramo() %>">
                            <%= s.getCodigoSegmento() %>
                        </a>
                        <% } %>
                        <span class="chip"><%= inc.getIdLanding() %></span>
                    </div>
                </div>
            </div>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Flujo de la incidencia</h2>
            </div>

            <ol class="flow">
                <% for (int i = 0; i < flujo.length; i++) {
                    String fechaPaso = null;
                    for (HistorialIncidencia h : historial) {
                        if (flujo[i].equals(h.getEstado())) fechaPaso = h.getFecha();
                    }
                    String clasePaso = i < posicionActual ? "done" : (i == posicionActual ? "current" : "");
                %>
                <li class="<%= clasePaso %>">
                    <%= flujo[i] %>
                    <% if (fechaPaso != null) { %><small><%= fechaPaso %></small><% } %>
                </li>
                <% } %>
            </ol>

            <% if (!"Cerrada".equals(estado)) { %>
            <!-- UPDATE: estado, severidad y observación -->
            <form class="panel-form" method="post" action="<%= servlet %>?action=actualizar">
                <input type="hidden" name="codigo" value="<%= inc.getCodigoIncidencia() %>">

                <h3>Actualizar la incidencia</h3>

                <div class="row">
                    <div class="col">
                        <label for="nuevoEstado">Nuevo estado <span class="req">*</span></label>
                        <select id="nuevoEstado" name="estado">
                            <option value="<%= estado %>" selected>Sin cambio · solo registrar una observación</option>
                            <% if (siguienteEstado != null && !"Servicio restaurado".equals(siguienteEstado)) { %>
                            <option value="<%= siguienteEstado %>"><%= siguienteEstado %></option>
                            <% } else if ("Servicio restaurado".equals(siguienteEstado)) { %>
                            <option disabled>Servicio restaurado · usa "Registrar restauración"</option>
                            <% } %>
                        </select>
                        <span class="hint">Solo se puede avanzar al siguiente estado del flujo.</span>
                    </div>

                    <div class="col">
                        <label for="severidad">Severidad <span class="req">*</span></label>
                        <select id="severidad" name="severidad" >
                            <% for (String s : severidades) { %>
                            <option <%= s.equals(inc.getSeveridad()) ? "selected" : "" %>><%= s %></option>
                            <% } %>
                        </select>
                        <span class="hint">Reclasifica la incidencia si cambió su impacto.</span>
                    </div>
                </div>

                <div class="row">
                    <div class="col col-wide">
                        <label for="obs">Observaciones de la atención <span class="req">*</span></label>
                        <textarea id="obs" name="observacion" class="textarea-sm" maxlength="500"
                                  placeholder="Acciones realizadas, avances o hallazgos"></textarea>
                    </div>
                </div>

                <div class="footer-action" style="border: none; padding-top: 14px">
                    <button type="submit" class="primary">Guardar actualización</button>
                </div>
            </form>
            <% } %>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Servicios afectados</h2>
                <span class="small"><%= servicios.size() %> servicios</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Servicio</th>
                        <th>Cliente</th>
                        <th>Ruta</th>
                        <th class="num">Gbps</th>
                        <th>Situación</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (servicios.isEmpty()) { %>
                    <tr><td colspan="5" class="small">No hay servicios activos sobre los segmentos de esta incidencia.</td></tr>
                    <% } %>
                    <% for (Servicio s : servicios) { %>
                    <tr>
                        <td class="cell-main"><%= String.format("SRV-%03d", s.getIdServicio()) %></td>
                        <td><%= s.getRazonSocialCliente() %></td>
                        <td><%= s.getCodigoRuta() %></td>
                        <td class="num"><%= numero(s.getCapacidadContratada()) %></td>
                        <td><span class="badge <%= claseSituacion %>"><%= situacionServicio %></span></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Clientes afectados</h2>
                <span class="small"><%= clientes.size() %> clientes</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Cliente</th>
                        <th>Contacto</th>
                        <th class="num">Servicios</th>
                        <th>Situación</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (clientes.isEmpty()) { %>
                    <tr><td colspan="4" class="small">No hay clientes afectados.</td></tr>
                    <% } %>
                    <% for (Cliente c : clientes) { %>
                    <tr>
                        <td class="cell-main">
                            <%= c.getRazonSocial() %>
                            <span class="cell-sub">RUC <%= c.getRuc() %></span>
                        </td>
                        <td><%= c.getCorreo() %></td>
                        <td class="num"><%= c.getCantidadServicios() %></td>
                        <td><span class="badge <%= claseSituacion %>"><%= situacionCliente %></span></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Historial de la incidencia</h2>
                <a href="<%= servlet %>?action=historial&codigo=<%= url(inc.getCodigoIncidencia()) %>" class="cell-link small">
                    Ver en el historial
                </a>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Fecha y hora</th>
                        <th>Estado</th>
                        <th>Usuario</th>
                        <th>Observaciones</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% for (HistorialIncidencia h : historial) { %>
                    <tr>
                        <td class="date"><%= h.getFecha() %></td>
                        <td><span class="badge <%= claseEstadoIncidencia(h.getEstado()) %>"><%= h.getEstado() %></span></td>
                        <td class="date"><%= h.getUsuario() == null ? "—" : h.getUsuario() %></td>
                        <td class="obs"><%= h.getObservacion() == null ? "—" : texto(h.getObservacion()) %></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </section>

    </main>
</div>

<!-- Confirmación para eliminar (se abre con el enlace #dialogoEliminar, sin JavaScript) -->
<div id="dialogoEliminar" class="overlay">
    <div class="modal">
        <h2>¿Eliminar la incidencia <%= inc.getCodigoIncidencia() %>?</h2>
        <p>Se eliminarán la incidencia y su historial. Esta acción no se puede deshacer.</p>
        <div class="botones">
            <a href="#" class="ghost">Cancelar</a>
            <a href="<%= servlet %>?action=borrar&codigo=<%= url(inc.getCodigoIncidencia()) %>" class="danger solid">Eliminar incidencia</a>
        </div>
    </div>
</div>

<% if (puedeRestaurar) { %>
<!-- RF22. Restauración del servicio -->
<div id="dialogoRestauracion" class="overlay">
    <div class="modal" style="width: min(560px, 94vw)">
        <form method="post" action="<%= servlet %>?action=restaurar">
            <input type="hidden" name="codigo" value="<%= inc.getCodigoIncidencia() %>">

            <h2>Registrar restauración del servicio</h2>
            <p>La incidencia pasará a Servicio restaurado y se agregará un evento al historial.</p>

            <dl class="kv" style="margin-bottom: 14px">
                <div><dt>Incidencia</dt><dd><%= inc.getCodigoIncidencia() %></dd></div>
                <div>
                    <dt>Segmentos</dt>
                    <dd>
                        <% for (Segmento s : segmentosInc) { %>
                        <%= s.getCodigoSegmento() %> · <%= s.getTramo() %><br>
                        <% } %>
                    </dd>
                </div>
                <div><dt>Servicios afectados</dt><dd><%= servicios.size() %></dd></div>
            </dl>

            <div class="row">
                <div class="col">
                    <label for="fechaRest">Fecha y hora <span class="req">*</span></label>
                    <input type="datetime-local" id="fechaRest" name="fecha_restauracion">
                </div>
                <div class="col">
                    <label for="estadoSeg">Estado del segmento <span class="req">*</span></label>
                    <select id="estadoSeg" name="estado_segmento" >
                        <option value="Operativo">Operativo</option>
                        <option value="Degradado">Degradado</option>
                    </select>
                </div>
            </div>

            <div class="row">
                <div class="col">
                    <label for="obsRest">Observaciones de la restauración <span class="req">*</span></label>
                    <textarea id="obsRest" name="observacion" class="textarea-sm" maxlength="500"
                                  placeholder="Acciones realizadas y resultado de la intervención"></textarea>
                    <span class="hint">Máximo 500 caracteres.</span>
                </div>
            </div>

            <div class="botones" style="margin-top: 20px; justify-content: flex-end">
                <a href="#" class="ghost">Cancelar</a>
                <button type="submit" class="primary">Confirmar restauración</button>
            </div>
        </form>
    </div>
</div>
<% } %>

</body>
</html>
