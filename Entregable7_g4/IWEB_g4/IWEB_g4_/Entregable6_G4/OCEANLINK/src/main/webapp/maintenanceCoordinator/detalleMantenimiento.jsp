<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.ActividadMantenimiento" %>
<%@ page import="beans.HistorialMantenimiento" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Mantenimiento" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.ServicioAfectado" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/MantenimientoServlet";

    Mantenimiento m = (Mantenimiento) request.getAttribute("mantenimiento");
    List<Segmento> segmentos = (List<Segmento>) request.getAttribute("segmentos");
    List<LandingStation> landings = (List<LandingStation>) request.getAttribute("landings");
    List<ServicioAfectado> servicios = (List<ServicioAfectado>) request.getAttribute("servicios");
    List<ActividadMantenimiento> actividades = (List<ActividadMantenimiento>) request.getAttribute("actividades");
    List<HistorialMantenimiento> historial = (List<HistorialMantenimiento>) request.getAttribute("historial");
    if (segmentos == null) segmentos = new ArrayList<>();
    if (landings == null) landings = new ArrayList<>();
    if (servicios == null) servicios = new ArrayList<>();
    if (actividades == null) actividades = new ArrayList<>();
    if (historial == null) historial = new ArrayList<>();

    String hoy = (String) request.getAttribute("hoy");
    String codigo = m.getCodigoMantenimiento();
    String estado = m.getEstado();

    // Flujo del mantenimiento (un cancelado termina en el segundo paso)
    String[] flujo = "Cancelado".equals(estado)
            ? new String[]{"Programado", "Cancelado"}
            : new String[]{"Programado", "En ejecución", "Finalizado"};
    int posicionActual = 0;
    for (int i = 0; i < flujo.length; i++) {
        if (flujo[i].equals(estado)) posicionActual = i;
    }

    int serviciosActivos = 0;
    for (ServicioAfectado s : servicios) {
        if ("Activo".equals(s.getEstado())) serviciosActivos++;
    }

    // Mensaje que dejó el Servlet en sesión: se muestra una sola vez y se borra (F5 no lo repite)
    String msg = (String) session.getAttribute("msg");
    session.removeAttribute("msg");

    // Valores del formulario de actividad (si hubo un error se muestran de nuevo)
    String errorActividad = (String) request.getAttribute("errorActividad");
    String actTitulo = errorActividad == null ? "" : request.getParameter("titulo");
    String actDescripcion = errorActividad == null ? "" : request.getParameter("descripcion");
    String actFecha = errorActividad == null ? hoy : request.getParameter("fecha");
    String actHora = errorActividad == null ? "" : request.getParameter("hora");
    String actHoras = errorActividad == null ? "" : request.getParameter("horas");
    String actMinutos = errorActividad == null ? "0" : request.getParameter("minutos");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title><%= codigo %> | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/maintenanceCoordinator/mantenimiento.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="listar"/>
</jsp:include>

    <main class="content">

        <a href="<%= servlet %>?action=listar" class="back-link">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
            Volver a mantenimientos
        </a>

        <div class="topbar">
            <div>
                <h1>Detalle del mantenimiento</h1>
                <p class="small">Programación, infraestructura, actividades y servicios afectados.</p>
            </div>
            <div class="botones">
                <% if (m.isProgramado()) { %>
                <a href="#dialogoCancelar" class="danger">Cancelar mantenimiento</a>
                <a href="<%= servlet %>?action=editar&codigo=<%= url(codigo) %>" class="secondary">Editar</a>
                <a href="#dialogoIniciar" class="primary">Iniciar mantenimiento</a>
                <% } else if (m.isEnEjecucion()) { %>
                <a href="#actividades" class="secondary">Registrar actividad</a>
                <a href="<%= servlet %>?action=finalizar&codigo=<%= url(codigo) %>" class="primary">Finalizar mantenimiento</a>
                <% } %>
            </div>
        </div>

        <% if ("actualizado".equals(msg)) { %>
        <div class="alert ok"><strong>Cambios guardados</strong> La nueva programación quedó anotada en el historial.</div>
        <% } else if ("iniciado".equals(msg)) { %>
        <div class="alert ok"><strong>Mantenimiento iniciado</strong> Sus segmentos pasaron a "En mantenimiento".</div>
        <% } else if ("actividad".equals(msg)) { %>
        <div class="alert ok"><strong>Actividad registrada</strong> Se agregó a la bitácora del mantenimiento.</div>
        <% } else if ("actividadBorrada".equals(msg)) { %>
        <div class="alert ok"><strong>Actividad eliminada</strong></div>
        <% } else if ("finalizado".equals(msg)) { %>
        <div class="alert ok"><strong>Mantenimiento finalizado</strong> Se actualizó el estado de sus segmentos.</div>
        <% } else if ("cancelado".equals(msg)) { %>
        <div class="alert ok"><strong>Mantenimiento cancelado</strong> Queda registrado en el historial con el motivo.</div>
        <% } else if ("antesDeFecha".equals(msg)) { %>
        <div class="alert warn"><strong>Aún no llega la fecha programada</strong>
            El mantenimiento empieza el <%= fecha(m.getFechaProgramada()) %>. Si se adelantó, edita la programación primero.</div>
        <% } else if ("noEditable".equals(msg)) { %>
        <div class="alert warn"><strong>No se puede editar</strong> Solo se edita un mantenimiento Programado.</div>
        <% } else if ("noIniciable".equals(msg)) { %>
        <div class="alert warn"><strong>No se puede iniciar</strong> Solo se inicia un mantenimiento Programado.</div>
        <% } else if ("noFinalizable".equals(msg)) { %>
        <div class="alert warn"><strong>No se puede finalizar</strong> Solo se finaliza un mantenimiento En ejecución.</div>
        <% } else if ("noCancelable".equals(msg)) { %>
        <div class="alert warn"><strong>No se puede cancelar</strong> Solo se cancela un mantenimiento Programado.</div>
        <% } else if ("noBorrada".equals(msg)) { %>
        <div class="alert warn"><strong>No se eliminó la actividad</strong> La actividad principal no se puede eliminar.</div>
        <% } else if ("faltaMotivo".equals(msg)) { %>
        <div class="alert error"><strong>No se canceló</strong> Escribe el motivo de la cancelación.</div>
        <% } else if ("motivoLargo".equals(msg)) { %>
        <div class="alert error"><strong>No se canceló</strong> El motivo no puede tener más de 500 caracteres.</div>
        <% } else if ("errorBD".equals(msg)) { %>
        <div class="alert error"><strong>No se completó la acción</strong> Ocurrió un error en la base de datos.</div>
        <% } %>

        <section class="card">
            <div class="card-header">
                <div>
                    <span class="stat-label"><%= codigo %></span>
                    <h2 class="record-title"><%= texto(m.getActividad() == null ? "Mantenimiento" : m.getActividad()) %></h2>
                    <p class="record-desc"><%= texto(m.getDescripcion()) %></p>
                </div>
                <span class="badge <%= "Correctivo".equals(m.getTipo()) ? "orange" : "blue" %>"><%= m.getTipo() %></span>
            </div>

            <div class="record-meta">
                <div>
                    <span class="stat-label">Estado actual</span>
                    <span class="badge <%= claseEstadoMnt(estado) %>"><%= estado %></span>
                </div>
                <div>
                    <span class="stat-label">Inicio programado</span>
                    <%= fecha(m.getFechaProgramada()) %> · <%= m.getHoraInicio() == null ? "—" : m.getHoraInicio() %>
                </div>
                <div>
                    <span class="stat-label">Duración estimada</span>
                    <%= duracion(m.getDuracionEstimada()) %>
                </div>
                <div>
                    <span class="stat-label">Infraestructura</span>
                    <div class="chips">
                        <% for (Segmento s : segmentos) { %>
                        <span class="chip" title="<%= s.getTramo() %>"><%= s.getCodigoSegmento() %></span>
                        <% } %>
                        <% for (LandingStation ls : landings) { %>
                        <span class="chip" title="<%= texto(ls.getNombre()) %>"><%= ls.getIdLanding() %></span>
                        <% } %>
                        <% if (segmentos.isEmpty() && landings.isEmpty()) { %>
                        <span class="small">Sin elementos asignados</span>
                        <% } %>
                    </div>
                </div>
            </div>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Flujo del mantenimiento</h2>
            </div>

            <ol class="flow">
                <% for (int i = 0; i < flujo.length; i++) {
                    String fechaPaso = null;
                    for (HistorialMantenimiento h : historial) {
                        if (flujo[i].equals(h.getEstado()) && fechaPaso == null) fechaPaso = h.getFecha();
                    }
                    String clasePaso = i < posicionActual ? "done" : (i == posicionActual ? "current" : "");
                %>
                <li class="<%= clasePaso %>">
                    <%= flujo[i] %>
                    <% if (fechaPaso != null) { %><small><%= fecha(fechaPaso) %></small><% } %>
                </li>
                <% } %>
            </ol>
        </section>

        <% if (m.getResultado() != null) { %>
        <section class="card">
            <div class="card-header">
                <h2>Cierre del mantenimiento</h2>
                <span class="badge <%= claseResultado(m.getResultado()) %>"><%= m.getResultado() %></span>
            </div>
            <dl class="kv">
                <div><dt>Fecha de fin</dt><dd><%= fecha(m.getFechaFin()) %></dd></div>
                <div><dt>Estado de los servicios</dt><dd><%= texto(m.getEstadoServicios()) %></dd></div>
                <div><dt>Resumen final</dt><dd><%= texto(m.getResumenFinal()) %></dd></div>
                <div><dt>Observación</dt><dd><%= m.getObservacionFinal() == null ? "—" : texto(m.getObservacionFinal()) %></dd></div>
            </dl>
        </section>
        <% } %>

        <section class="card" id="actividades">
            <div class="card-header">
                <h2>Actividades</h2>
                <span class="small"><%= actividades.size() %> registradas</span>
            </div>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                    <tr>
                        <th>Fecha y hora</th>
                        <th>Actividad</th>
                        <th>Tiempo invertido</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <% if (actividades.isEmpty()) { %>
                    <tr><td colspan="4" class="small">Aún no hay actividades registradas.</td></tr>
                    <% } %>
                    <% for (ActividadMantenimiento a : actividades) { %>
                    <tr>
                        <td class="date"><%= fecha(a.getFecha()) %><span class="cell-sub"><%= a.getHora() %></span></td>
                        <td class="obs">
                            <strong><%= texto(a.getTitulo()) %></strong>
                            <% if (a.isPrincipal()) { %><span class="badge blue">Principal</span><% } %>
                            <span class="cell-sub"><%= texto(a.getDescripcion()) %></span>
                        </td>
                        <td><%= duracion(a.getTiempoInvertido()) %></td>
                        <td>
                            <% if (m.isEnEjecucion() && a.isBorrable()) { %>
                            <a href="#dialogoBorrar<%= a.getIdActividad() %>" class="danger btn-sm">Eliminar</a>
                            <% } %>
                        </td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>

            <% if (m.isEnEjecucion()) { %>
            <!-- CREATE: actividad del mantenimiento -->
            <form class="panel-form" method="post" action="<%= servlet %>#actividades">
                <input type="hidden" name="action" value="registrarActividad">
                <input type="hidden" name="codigo" value="<%= codigo %>">

                <h3>Registrar actividad</h3>

                <% if (errorActividad != null) { %>
                <div class="alert error"><strong>No se registró</strong> <%= texto(errorActividad) %></div>
                <% } %>

                <div class="row">
                    <div class="col col-wide">
                        <label for="titulo">Título <span class="req">*</span></label>
                        <input type="text" id="titulo" name="titulo" maxlength="100" required
                               placeholder="Ej. Empalme de fibra" value="<%= texto(actTitulo) %>">
                    </div>
                    <div class="col">
                        <label for="fecha">Fecha <span class="req">*</span></label>
                        <input type="date" id="fecha" name="fecha" required min="<%= m.getFechaProgramada() %>"
                               max="<%= hoy %>" value="<%= texto(actFecha) %>">
                    </div>
                    <div class="col">
                        <label for="hora">Hora <span class="req">*</span></label>
                        <input type="time" id="hora" name="hora" required value="<%= texto(actHora) %>">
                    </div>
                    <div class="col">
                        <label for="horas">Horas <span class="req">*</span></label>
                        <input type="number" id="horas" name="horas" min="0" max="99" required value="<%= texto(actHoras) %>">
                    </div>
                    <div class="col">
                        <label for="minutos">Minutos</label>
                        <input type="number" id="minutos" name="minutos" min="0" max="59" step="5" value="<%= texto(actMinutos) %>">
                    </div>
                </div>

                <div class="row">
                    <div class="col">
                        <label for="descripcionAct">Descripción <span class="req">*</span></label>
                        <textarea id="descripcionAct" name="descripcion" class="textarea-sm" maxlength="500" required
                                  placeholder="Qué se hizo y con qué resultado"><%= texto(actDescripcion) %></textarea>
                    </div>
                </div>

                <div class="footer-action" style="border: none; padding-top: 14px">
                    <button type="submit" class="primary">Registrar actividad</button>
                </div>
            </form>
            <% } %>
        </section>

        <section class="card">
            <div class="card-header">
                <h2>Servicios afectados</h2>
                <span class="small"><%= serviciosActivos %> activos de <%= servicios.size() %> servicios</span>
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
                    <tr><td colspan="6" class="small">No hay servicios que pasen por la infraestructura de este mantenimiento.</td></tr>
                    <% } %>
                    <% for (ServicioAfectado s : servicios) { %>
                    <tr>
                        <td class="cell-main"><%= String.format("SRV-%03d", s.getIdServicio()) %></td>
                        <td><%= texto(s.getRazonSocial()) %><span class="cell-sub">RUC <%= s.getRuc() %></span></td>
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

        <section class="card">
            <div class="card-header">
                <h2>Historial del mantenimiento</h2>
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
                    <% if (historial.isEmpty()) { %>
                    <tr><td colspan="4" class="small">Sin cambios de estado registrados.</td></tr>
                    <% } %>
                    <% for (HistorialMantenimiento h : historial) { %>
                    <tr>
                        <td class="date"><%= fecha(h.getFecha()) %></td>
                        <td><span class="badge <%= claseEstadoMnt(h.getEstado()) %>"><%= h.getEstado() %></span></td>
                        <td class="date"><%= h.getUsuario() == null ? "—" : texto(h.getUsuario()) %></td>
                        <td class="obs"><%= h.getObservacion() == null ? "—" : texto(h.getObservacion()) %></td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </section>

    </main>
</div>

<% if (m.isEnEjecucion()) {
       for (ActividadMantenimiento a : actividades) {
           if (!a.isBorrable()) continue; %>
<!-- DELETE: confirmación para borrar una actividad (sin JavaScript, se abre con el enlace #dialogoBorrar...) -->
<div id="dialogoBorrar<%= a.getIdActividad() %>" class="overlay">
    <div class="modal">
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="borrarActividad">
            <input type="hidden" name="codigo" value="<%= codigo %>">
            <input type="hidden" name="idActividad" value="<%= a.getIdActividad() %>">

            <h2>Eliminar actividad</h2>
            <p>Se eliminará la actividad "<%= texto(a.getTitulo()) %>" del <%= fecha(a.getFecha()) %>.
                Esta acción no se puede deshacer.</p>

            <div class="botones">
                <a href="#actividades" class="ghost">Volver</a>
                <button type="submit" class="danger solid">Eliminar</button>
            </div>
        </form>
    </div>
</div>
<%     }
   } %>

<% if (m.isProgramado()) { %>
<!-- UPDATE: Programado -> En ejecución -->
<div id="dialogoIniciar" class="overlay">
    <div class="modal" style="width: min(560px, 94vw)">
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="iniciar">
            <input type="hidden" name="codigo" value="<%= codigo %>">

            <h2>Iniciar mantenimiento</h2>
            <p>El mantenimiento pasará a En ejecución y sus segmentos a "En mantenimiento". Lo verán el Network
                Operator y el Supervisor.</p>

            <dl class="kv" style="margin-bottom: 14px">
                <div><dt>Mantenimiento</dt><dd><%= codigo %></dd></div>
                <div><dt>Inicio programado</dt><dd><%= fecha(m.getFechaProgramada()) %> · <%= m.getHoraInicio() %></dd></div>
                <div><dt>Segmentos</dt><dd><%= m.getSegmentos() == null ? "—" : m.getSegmentos() %></dd></div>
                <div><dt>Servicios activos afectados</dt><dd class="bad"><%= serviciosActivos %></dd></div>
            </dl>

            <% if (m.getFechaProgramada().compareTo(hoy) > 0) { %>
            <div class="alert warn"><strong>Aún no llega la fecha</strong> No se puede iniciar antes del
                <%= fecha(m.getFechaProgramada()) %>. Si se adelantó, edita la programación.</div>
            <% } %>

            <div class="row">
                <div class="col">
                    <label for="obsIniciar">Observación</label>
                    <textarea id="obsIniciar" name="observacion" class="textarea-sm" maxlength="500"
                              placeholder="Ej. Cuadrilla en sitio, ventana coordinada con los clientes"></textarea>
                    <span class="hint">Opcional. Se guarda en el historial.</span>
                </div>
            </div>

            <div class="botones" style="margin-top: 20px; justify-content: flex-end">
                <a href="#" class="ghost">Volver</a>
                <button type="submit" class="primary">Confirmar inicio</button>
            </div>
        </form>
    </div>
</div>

<!-- DELETE lógico: Programado -> Cancelado -->
<div id="dialogoCancelar" class="overlay">
    <div class="modal" style="width: min(560px, 94vw)">
        <form method="post" action="<%= servlet %>">
            <input type="hidden" name="action" value="cancelarMantenimiento">
            <input type="hidden" name="codigo" value="<%= codigo %>">

            <h2>Cancelar mantenimiento</h2>
            <p>El mantenimiento <%= codigo %> quedará como Cancelado. No se borra: se conserva en el historial con el motivo.</p>

            <div class="row">
                <div class="col">
                    <label for="motivo">Motivo de la cancelación <span class="req">*</span></label>
                    <textarea id="motivo" name="motivo" class="textarea-sm" maxlength="500" required
                              placeholder="Ej. Condiciones climáticas no permiten el trabajo en altamar"></textarea>
                    <span class="hint">Máximo 500 caracteres.</span>
                </div>
            </div>

            <div class="botones" style="margin-top: 20px; justify-content: flex-end">
                <a href="#" class="ghost">Volver</a>
                <button type="submit" class="danger solid">Cancelar mantenimiento</button>
            </div>
        </form>
    </div>
</div>
<% } %>

</body>
</html>
