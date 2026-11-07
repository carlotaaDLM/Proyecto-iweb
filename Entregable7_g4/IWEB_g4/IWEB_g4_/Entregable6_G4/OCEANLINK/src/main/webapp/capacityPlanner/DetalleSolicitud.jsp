<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.HistorialSolicitud" %>
<%@ page import="beans.Ruta" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.SolicitudCapacidad" %>
<%@ page import="dao.SolicitudDAO" %>
<%@ include file="badges.jspf" %>
<%
    SolicitudCapacidad sol = (SolicitudCapacidad) request.getAttribute("solicitud");
    Ruta ruta = (Ruta) request.getAttribute("ruta");

    List<HistorialSolicitud> historial = (List<HistorialSolicitud>) request.getAttribute("historial");
    if (historial == null) historial = new ArrayList<>();

    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");

    String servlet = request.getContextPath() + "/CapacityPlannerServlet";
    String estado = sol.getEstado();
    double requerida = sol.getCapacidadRequerida();

    boolean evaluable = "Registrada".equals(estado) || "En evaluación".equals(estado)
            || "Pendiente por capacidad".equals(estado);
    boolean fueraServicio = ruta != null && ruta.isTieneSegmentoFueraServicio();
    // Si ya está reservada, lo reservado para esta solicitud no cuenta como ocupado por otra
    double disponibleRuta = ruta == null ? 0 : ruta.getCapacidadDisponible() + (sol.isReservada() ? requerida : 0);
    boolean alcanza = ruta != null && !fueraServicio && disponibleRuta >= requerida;
    Segmento cuello = ruta == null ? null : ruta.getSegmentoMasCargado();
    // La capacidad se compara mientras se evalúa o falta reservar
    boolean revisarCapacidad = evaluable || ("Aprobada".equals(estado) && !sol.isReservada());

    // Pasos del flujo que faltan (solo si el estado es parte del flujo principal)
    List<String> faltan = new ArrayList<>();
    int posicion = java.util.Arrays.asList(SolicitudDAO.FLUJO).indexOf(estado);
    if (posicion >= 0) {
        for (int i = posicion + 1; i < SolicitudDAO.FLUJO.length; i++) {
            faltan.add(SolicitudDAO.FLUJO[i]);
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Detalle de la solicitud | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/capacityPlanner/capacityPlanner.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="listarSolicitudes"/>
</jsp:include>

    <main class="content">
        <a href="<%= servlet %>?action=listarSolicitudes" class="back-link">
            Volver a evaluar solicitudes
        </a>

        <div class="topbar">
            <div>
                <h1>Detalle de la solicitud</h1>
                <p class="small">Compara la capacidad pedida con lo disponible en cada segmento de la ruta propuesta.</p>
            </div>
        </div>

        <% if ("registrada".equals(msg)) { %>
        <div class="alert ok"><strong>Solicitud registrada</strong>Quedó en estado Registrada. Inicia la evaluación para que el sistema calcule su ruta.</div>
        <% } else if ("actualizada".equals(msg)) { %>
        <div class="alert ok"><strong>Cambios guardados</strong>Se actualizaron los datos de la solicitud.</div>
        <% } else if ("aprobada".equals(msg)) { %>
        <div class="alert ok"><strong>Solicitud aprobada</strong>Ahora reserva la capacidad en los segmentos de la ruta.</div>
        <% } else if ("reservada".equals(msg)) { %>
        <div class="alert ok"><strong>Reserva registrada</strong>La capacidad quedó reservada y la solicitud ya puede pasar a Provisionada.</div>
        <% } else if ("provisionada".equals(msg)) { %>
        <div class="alert ok"><strong>Solicitud provisionada</strong>Se creó el servicio con la ruta de la solicitud.</div>
        <% } else if ("activada".equals(msg)) { %>
        <div class="alert ok"><strong>Servicio activo</strong>La capacidad reservada pasó a utilizada.</div>
        <% } %>
        <% if (error != null) { %>
        <div class="alert error"><strong>No se pudo completar la acción</strong><%= texto(error) %></div>
        <% } %>

        <section class="card">
            <div class="record-head">
                <div>
                    <span class="stat-label">Solicitud</span>
                    <span class="big"><%= sol.getCodigo() %></span>
                </div>
                <div>
                    <span class="stat-label">Estado actual</span>
                    <span class="badge <%= claseEstadoSolicitud(estado) %>"><%= estado %></span>
                </div>
                <div>
                    <span class="stat-label">Fecha de solicitud</span>
                    <%= fecha(sol.getFechaSolicitud()) %>
                </div>
                <div>
                    <span class="stat-label">Registrada por</span>
                    <%= sol.getNombreUsuario() == null ? "—" : texto(sol.getNombreUsuario()) %>
                </div>
            </div>
        </section>

        <div class="split">
            <div>
                <section class="card">
                    <div class="card-header">
                        <h2>Información de la solicitud</h2>
                    </div>
                    <dl class="kv">
                        <div><dt>Cliente</dt><dd><%= texto(sol.getRazonSocialCliente()) %></dd></div>
                        <div><dt>Origen → Destino</dt><dd><%= sol.getTramo() %></dd></div>
                        <div><dt>Capacidad requerida</dt><dd><%= numero(requerida) %> Gbps</dd></div>
                        <div><dt>Ruta propuesta</dt><dd><%= ruta == null ? "Se calcula al evaluar" : ruta.getCodigo() %></dd></div>
                        <div><dt>Fecha requerida</dt><dd><%= fecha(sol.getFechaRequerida()) %></dd></div>
                        <div><dt>Capacidad reservada</dt><dd><%= sol.isReservada() ? numero(sol.getCapacidadReservada()) + " Gbps por segmento" : "Sin reserva" %></dd></div>
                        <% if (sol.getIdServicio() != null) { %>
                        <div><dt>Servicio</dt><dd><a class="cell-link" href="<%= servlet %>?action=rutas&id_servicio=<%= sol.getIdServicio() %>"><%= String.format("SRV-%03d", sol.getIdServicio()) %></a></dd></div>
                        <% } %>
                        <div><dt>Observaciones</dt><dd><%= sol.getObservaciones() == null || sol.getObservaciones().isEmpty() ? "—" : texto(sol.getObservaciones()) %></dd></div>
                    </dl>
                    <% if (ruta != null) { %>
                    <div class="route-line">
                        <div class="route-node"><span></span><strong><%= ruta.getSegmentos().get(0).getIdOrigen().replace("LS-", "") %></strong>
                            <small><%= ruta.getSegmentos().get(0).getNombreOrigen().replace("Estación ", "") %></small></div>
                        <% for (Segmento s : ruta.getSegmentos()) { %>
                        <div class="route-node"><span></span><strong><%= s.getIdDestino().replace("LS-", "") %></strong>
                            <small><%= s.getNombreDestino().replace("Estación ", "") %></small></div>
                        <% } %>
                    </div>
                    <% } %>
                </section>

                <% if (ruta != null) { %>
                <section class="card">
                    <div class="card-header">
                        <h2>Segmentos de la ruta</h2>
                        <span class="small"><%= ruta.getSegmentos().size() %> segmentos</span>
                    </div>
                    <div class="table-wrap">
                        <table class="table">
                            <thead>
                            <tr>
                                <th>Segmento</th>
                                <th>Tramo</th>
                                <th class="num">Disponible</th>
                                <th>Ocupación</th>
                                <th>¿Alcanza?</th>
                            </tr>
                            </thead>
                            <tbody>
                            <% for (Segmento s : ruta.getSegmentos()) {
                                double disp = s.getCapacidadDisponible() + (sol.isReservada() ? requerida : 0);
                                boolean fuera = "Fuera de servicio".equals(s.getEstado());
                            %>
                            <tr>
                                <td class="cell-main"><%= s.getCodigoSegmento() %></td>
                                <td class="tramo"><%= s.getTramo() %></td>
                                <td class="num"><%= numero(s.getCapacidadDisponible()) %> Gbps</td>
                                <td><%= barraUso(s.getPorcentajeOcupacion()) %></td>
                                <td>
                                    <% if (sol.isReservada()) { %>
                                    <span class="badge green">Reservado</span>
                                    <% } else if (!revisarCapacidad) { %>
                                    <span class="small">—</span>
                                    <% } else if (fuera) { %>
                                    <span class="badge red">Fuera de servicio</span>
                                    <% } else if (disp >= requerida) { %>
                                    <span class="badge green">Suficiente</span>
                                    <% } else { %>
                                    <span class="badge red">Insuficiente</span>
                                    <% } %>
                                </td>
                            </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </section>
                <% } %>

                <section class="card">
                    <div class="card-header">
                        <h2>Historial de la solicitud</h2>
                    </div>
                    <ol class="timeline-v">
                        <% for (int i = 0; i < historial.size(); i++) {
                            HistorialSolicitud h = historial.get(i);
                            boolean actual = i == historial.size() - 1;
                        %>
                        <li class="<%= actual ? "current" : "done" %>">
                            <% if (actual) { %><strong><%= h.getEstado() %></strong><% } else { %><%= h.getEstado() %><% } %>
                            <span class="when"><%= fechaHora(h.getFecha()) %>
                                <%= h.getNombreUsuario() == null ? "" : " · " + texto(h.getNombreUsuario()) %>
                                <%= actual ? " · estado actual" : "" %></span>
                            <% if (h.getObservacion() != null && !h.getObservacion().isEmpty()) { %>
                            <span class="when"><%= texto(h.getObservacion()) %></span>
                            <% } %>
                        </li>
                        <% } %>
                        <% for (String paso : faltan) { %>
                        <li class="pending-step"><%= paso %></li>
                        <% } %>
                    </ol>
                </section>
            </div>

            <aside>
                <section class="card">
                    <div class="card-header">
                        <h2>Capacidad en la ruta</h2>
                    </div>
                    <% if (ruta == null) { %>
                    <p class="small">
                        <%= "Registrada".equals(estado)
                                ? "La ruta se calcula al iniciar la evaluación."
                                : "No hay una ruta activa que una el origen con el destino sin segmentos Fuera de servicio." %>
                    </p>
                    <% } else { %>
                    <dl class="kv">
                        <div><dt>Capacidad requerida</dt><dd><%= numero(requerida) %> Gbps</dd></div>
                        <div><dt>Disponible en la ruta</dt><dd class="<%= alcanza ? "ok" : "bad" %>"><%= numero(disponibleRuta) %> Gbps</dd></div>
                        <div><dt>Segmento más cargado</dt><dd><%= cuello == null ? "—" : cuello.getCodigoSegmento() %></dd></div>
                    </dl>
                    <% if (fueraServicio) { %>
                    <div class="alert error" style="margin: 16px 0 0">
                        <strong>Ruta con un segmento Fuera de servicio</strong>
                        No se puede reservar ni activar mientras siga así (regla 3).
                    </div>
                    <% } else if (!revisarCapacidad) { %>
                    <p class="small form-note">La capacidad de esta solicitud ya no está en evaluación.</p>
                    <% } else if (!alcanza) { %>
                    <div class="alert error" style="margin: 16px 0 0">
                        <strong>Capacidad insuficiente</strong>
                        <%= cuello.getCodigoSegmento() %> solo tiene <%= numero(cuello.getCapacidadDisponible()) %> Gbps libres
                        y se piden <%= numero(requerida) %> Gbps.
                    </div>
                    <% } else if (evaluable) { %>
                    <div class="alert ok" style="margin: 16px 0 0">
                        <strong>La ruta tiene capacidad suficiente</strong>
                        Se puede aprobar la solicitud.
                    </div>
                    <% } %>
                    <% } %>
                </section>

                <section class="card">
                    <div class="card-header">
                        <h2><%= evaluable ? "Decisión" : "Siguiente paso" %></h2>
                    </div>
                    <div class="actions-stack">

                        <% if ("Registrada".equals(estado)) { %>
                        <form method="post" action="<%= servlet %>">
                            <input type="hidden" name="action" value="evaluar">
                            <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
                            <button type="submit" class="primary" style="width: 100%">Iniciar evaluación</button>
                        </form>
                        <a href="<%= servlet %>?action=editar&id=<%= sol.getIdSolicitud() %>" class="secondary">Editar solicitud</a>
                        <a href="#dialogoRechazar" class="danger solid">Rechazar solicitud</a>
                        <a href="#dialogoEliminar" class="ghost">Eliminar solicitud</a>

                        <% } else if ("En evaluación".equals(estado)) { %>
                        <form method="post" action="<%= servlet %>">
                            <input type="hidden" name="action" value="aprobar">
                            <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
                            <button type="submit" class="approve" style="width: 100%"<%= alcanza ? "" : " disabled title=\"La ruta no tiene capacidad suficiente\"" %>>Aprobar solicitud</button>
                        </form>
                        <a href="#dialogoPendiente" class="pending">Pendiente por capacidad</a>
                        <a href="#dialogoRechazar" class="danger solid">Rechazar solicitud</a>
                        <form method="post" action="<%= servlet %>">
                            <input type="hidden" name="action" value="evaluar">
                            <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
                            <button type="submit" class="ghost" style="width: 100%">Recalcular ruta</button>
                        </form>

                        <% } else if ("Pendiente por capacidad".equals(estado)) { %>
                        <form method="post" action="<%= servlet %>">
                            <input type="hidden" name="action" value="evaluar">
                            <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
                            <button type="submit" class="primary" style="width: 100%">Volver a evaluar</button>
                        </form>
                        <a href="#dialogoRechazar" class="danger solid">Rechazar solicitud</a>

                        <% } else if ("Aprobada".equals(estado) && !sol.isReservada()) { %>
                        <a href="<%= servlet %>?action=formReservar&id=<%= sol.getIdSolicitud() %>" class="primary">Reservar capacidad</a>
                        <button type="button" class="approve" disabled title="Primero reserva la capacidad">Provisionar</button>
                        <% if (!alcanza) { %>
                        <a href="#dialogoPendiente" class="pending">Pendiente por capacidad</a>
                        <a href="#dialogoRechazar" class="danger solid">Rechazar solicitud</a>
                        <% } %>

                        <% } else if ("Aprobada".equals(estado)) { %>
                        <form method="post" action="<%= servlet %>">
                            <input type="hidden" name="action" value="provisionar">
                            <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
                            <button type="submit" class="approve" style="width: 100%">Provisionar</button>
                        </form>

                        <% } else if ("Provisionada".equals(estado)) { %>
                        <form method="post" action="<%= servlet %>">
                            <input type="hidden" name="action" value="activar">
                            <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
                            <button type="submit" class="approve" style="width: 100%"<%= fueraServicio || sol.getIdServicio() == null ? " disabled" : "" %>>Activar servicio</button>
                        </form>
                        <% if (sol.getIdServicio() == null) { %>
                        <p class="small">Esta solicitud se cargó sin servicio asociado, así que no se puede activar desde aquí.</p>
                        <% } %>

                        <% } else if ("Rechazada".equals(estado)) { %>
                        <a href="#dialogoEliminar" class="danger solid">Eliminar solicitud</a>

                        <% } else { %>
                        <p class="small">La solicitud completó el flujo.</p>
                        <% } %>
                    </div>
                    <p class="small form-note">
                        <%= "Aprobada".equals(estado) || "Provisionada".equals(estado)
                                ? "No se provisiona sin reserva previa (regla 2) ni se activa con un segmento Fuera de servicio (regla 3)."
                                : "Aprobar no reserva capacidad: la reserva se registra después, en Reservar capacidad." %>
                    </p>
                </section>
            </aside>
        </div>
    </main>
</div>

<div id="dialogoPendiente" class="overlay"><div class="modal">
    <form method="post" action="<%= servlet %>">
        <input type="hidden" name="action" value="pendiente">
        <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
        <h2>¿Dejar <%= sol.getCodigo() %> pendiente por capacidad?</h2>
        <p>La solicitud esperará hasta que la ruta tenga <%= numero(requerida) %> Gbps disponibles. Podrás evaluarla de nuevo.</p>
        <label for="obsPendiente">Observación (opcional)</label>
        <textarea id="obsPendiente" name="observacion" class="textarea-sm" maxlength="500"></textarea>
        <div class="botones" style="margin-top: 20px">
            <a href="#" class="ghost">Cancelar</a>
            <button type="submit" class="pending">Dejar pendiente</button>
        </div>
    </form>
</div></div>

<div id="dialogoRechazar" class="overlay"><div class="modal">
    <form method="post" action="<%= servlet %>">
        <input type="hidden" name="action" value="rechazar">
        <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
        <h2>¿Rechazar <%= sol.getCodigo() %>?</h2>
        <p>La solicitud pasará a Rechazada y no continuará el flujo. El motivo queda en el historial.</p>
        <label for="motivo">Motivo del rechazo</label>
        <textarea id="motivo" name="observacion" class="textarea-sm" maxlength="500" required
                  placeholder="Ej. Capacidad insuficiente en <%= cuello == null ? "la ruta" : cuello.getCodigoSegmento() %>"></textarea>
        <div class="botones" style="margin-top: 20px">
            <a href="#" class="ghost">Cancelar</a>
            <button type="submit" class="danger solid">Rechazar</button>
        </div>
    </form>
</div></div>

<div id="dialogoEliminar" class="overlay"><div class="modal">
    <h2>¿Eliminar <%= sol.getCodigo() %>?</h2>
    <p>Se borrará la solicitud y su historial. Esta acción no se puede deshacer.</p>
    <div class="botones" style="margin-top: 20px">
        <a href="#" class="ghost">Cancelar</a>
        <a href="<%= servlet %>?action=borrar&id=<%= sol.getIdSolicitud() %>" class="danger solid">Eliminar</a>
    </div>
</div></div>

</body>
</html>
