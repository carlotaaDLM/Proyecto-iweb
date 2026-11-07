<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="beans.Cliente" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Ruta" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.SolicitudCapacidad" %>
<%@ include file="badges.jspf" %>
<%!
    // Valor de un campo: lo que se envió en el formulario, o el de la solicitud que se edita
    String valor(Map<String, String[]> valores, String campo, String porDefecto) {
        if (valores != null && valores.get(campo) != null && valores.get(campo).length > 0) {
            return valores.get(campo)[0];
        }
        return porDefecto == null ? "" : porDefecto;
    }
%>
<%
    List<Cliente> clientes = (List<Cliente>) request.getAttribute("clientes");
    if (clientes == null) clientes = new ArrayList<>();

    List<LandingStation> landings = (List<LandingStation>) request.getAttribute("landings");
    if (landings == null) landings = new ArrayList<>();

    SolicitudCapacidad sol = (SolicitudCapacidad) request.getAttribute("solicitud");
    boolean editar = sol != null;

    Map<String, String[]> valores = (Map<String, String[]>) request.getAttribute("valores");

    String idCliente = valor(valores, "id_cliente", editar ? String.valueOf(sol.getIdCliente()) : "");
    String idOrigen = valor(valores, "id_origen", editar ? sol.getIdOrigen() : "");
    String idDestino = valor(valores, "id_destino", editar ? sol.getIdDestino() : "");
    String capacidad = valor(valores, "capacidad_requerida",
            editar ? String.format(java.util.Locale.US, "%.2f", sol.getCapacidadRequerida()) : "");
    String fechaRequerida = valor(valores, "fecha_requerida", editar ? sol.getFechaRequerida() : "");
    String observaciones = valor(valores, "observaciones", editar ? sol.getObservaciones() : "");

    String error = (String) request.getAttribute("error");
    boolean calculada = request.getAttribute("calculada") != null;
    Ruta ruta = (Ruta) request.getAttribute("rutaCalculada");
    String hoy = (String) request.getAttribute("hoy");

    double pedida = 0;
    try { pedida = Double.parseDouble(capacidad); } catch (NumberFormatException e) { pedida = 0; }

    String servlet = request.getContextPath() + "/CapacityPlannerServlet";
    String activoMenu = editar ? "listarSolicitudes" : "formRegistrar";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= editar ? "Editar solicitud" : "Registrar solicitud" %> | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/capacityPlanner/capacityPlanner.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="<%= activoMenu %>"/>
</jsp:include>

    <main class="content">
        <% if (editar) { %>
        <a href="<%= servlet %>?action=detalleSolicitud&id=<%= sol.getIdSolicitud() %>" class="back-link">
            Volver al detalle de <%= sol.getCodigo() %>
        </a>
        <% } %>

        <div class="topbar">
            <div>
                <h1><%= editar ? "Editar solicitud " + sol.getCodigo() : "Registrar solicitud de capacidad" %></h1>
                <p class="small">
                    <%= editar ? "Solo se puede editar mientras la solicitud sigue Registrada."
                            : "La solicitud queda en estado Registrada y pasa a evaluación." %>
                </p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>No se pudo continuar</strong><%= texto(error) %></div>
        <% } %>

        <div class="split">
            <form class="card" method="post" action="<%= servlet %>">
                <% if (editar) { %>
                <input type="hidden" name="id" value="<%= sol.getIdSolicitud() %>">
                <% } %>
                <fieldset>
                    <legend>Datos de la solicitud</legend>

                    <div class="row">
                        <div class="col">
                            <label for="cliente">Cliente</label>
                            <select id="cliente" name="id_cliente" required>
                                <option value="" disabled<%= sel(idCliente.isEmpty()) %>>Selecciona un cliente</option>
                                <% for (Cliente c : clientes) { %>
                                <option value="<%= c.getIdCliente() %>"<%= sel(String.valueOf(c.getIdCliente()).equals(idCliente)) %>>
                                    <%= texto(c.getRazonSocial()) %>
                                </option>
                                <% } %>
                            </select>
                        </div>
                        <div class="col">
                            <label for="capacidad">Capacidad requerida (Gbps)</label>
                            <input type="number" id="capacidad" name="capacidad_requerida" min="1" step="0.01"
                                   value="<%= texto(capacidad) %>" placeholder="Ej. 600" required>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col">
                            <label for="origen">Landing Station de origen</label>
                            <select id="origen" name="id_origen" required>
                                <option value="" disabled<%= sel(idOrigen.isEmpty()) %>>Selecciona el origen</option>
                                <% for (LandingStation ls : landings) { %>
                                <option value="<%= ls.getIdLanding() %>"<%= sel(ls.getIdLanding().equals(idOrigen)) %>>
                                    <%= texto(ls.getNombre()) %> (<%= texto(ls.getPais()) %>)
                                </option>
                                <% } %>
                            </select>
                        </div>
                        <div class="col">
                            <label for="destino">Landing Station de destino</label>
                            <select id="destino" name="id_destino" required>
                                <option value="" disabled<%= sel(idDestino.isEmpty()) %>>Selecciona el destino</option>
                                <% for (LandingStation ls : landings) { %>
                                <option value="<%= ls.getIdLanding() %>"<%= sel(ls.getIdLanding().equals(idDestino)) %>>
                                    <%= texto(ls.getNombre()) %> (<%= texto(ls.getPais()) %>)
                                </option>
                                <% } %>
                            </select>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col">
                            <label for="fecha">Fecha requerida</label>
                            <input type="date" id="fecha" name="fecha_requerida" min="<%= hoy %>"
                                   value="<%= texto(fechaRequerida) %>" required>
                        </div>
                        <div class="col">
                            <span class="hint">La ruta la calcula el sistema a partir del origen y el destino.</span>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col">
                            <label for="observaciones">Observaciones</label>
                            <textarea id="observaciones" name="observaciones" class="textarea-sm" maxlength="255"
                                      placeholder="Motivo de la solicitud, tipo de tráfico, etc."><%= texto(observaciones) %></textarea>
                            <span class="hint">Máximo 255 caracteres.</span>
                        </div>
                    </div>
                </fieldset>

                <div class="footer-action">
                    <a href="<%= editar ? servlet + "?action=detalleSolicitud&id=" + sol.getIdSolicitud()
                            : servlet + "?action=capacidad" %>" class="ghost">Cancelar</a>
                    <button type="submit" name="action" value="calcular" class="secondary">Calcular ruta</button>
                    <button type="submit" name="action" value="<%= editar ? "actualizar" : "crear" %>" class="primary">
                        <%= editar ? "Guardar cambios" : "Registrar solicitud" %>
                    </button>
                </div>
            </form>

            <aside class="card">
                <div class="card-header">
                    <h2>Ruta que propondría el sistema</h2>
                </div>

                <% if (!calculada) { %>
                <p class="small">
                    Elige el origen y el destino y presiona <strong>Calcular ruta</strong> para ver qué ruta
                    se propondría y cuánta capacidad tiene disponible.
                </p>
                <p class="small form-note">
                    El sistema elige, entre las rutas activas que unen ambas estaciones y no tienen segmentos
                    Fuera de servicio, la de mayor capacidad disponible. Si no hay ninguna, arma una ruta nueva
                    con los segmentos disponibles. La ruta definitiva se fija al evaluar.
                </p>
                <% } else if (ruta == null) { %>
                <div class="alert error" style="margin: 0">
                    <strong>No hay una ruta disponible</strong>
                    No hay segmentos que unan esas estaciones sin pasar por uno Fuera de servicio.
                    Puedes registrar la solicitud igual: al evaluarla quedará Pendiente por capacidad o se rechazará.
                </div>
                <% } else {
                    Segmento cuello = ruta.getSegmentoMasCargado();
                    boolean alcanza = ruta.getCapacidadDisponible() >= pedida;
                %>
                <p class="route-title"><%= ruta.getCodigo() %></p>
                <% if (ruta.getIdRuta() == 0) { %>
                <p class="small">Ruta nueva armada con los segmentos disponibles: se registrará al evaluar la solicitud.</p>
                <% } %>
                <div class="route-line">
                    <div class="route-node"><span></span><strong><%= ruta.getSegmentos().get(0).getIdOrigen().replace("LS-", "") %></strong>
                        <small><%= ruta.getSegmentos().get(0).getNombreOrigen().replace("Estación ", "") %></small></div>
                    <% for (Segmento s : ruta.getSegmentos()) { %>
                    <div class="route-node"><span></span><strong><%= s.getIdDestino().replace("LS-", "") %></strong>
                        <small><%= s.getNombreDestino().replace("Estación ", "") %></small></div>
                    <% } %>
                </div>
                <dl class="kv" style="margin-top: 18px">
                    <div><dt>Segmentos</dt><dd><%= ruta.getSegmentos().size() %></dd></div>
                    <div><dt>Disponible en la ruta</dt><dd class="<%= alcanza ? "ok" : "bad" %>"><%= numero(ruta.getCapacidadDisponible()) %> Gbps</dd></div>
                    <div><dt>Segmento más cargado</dt><dd><%= cuello == null ? "—" : cuello.getCodigoSegmento() %></dd></div>
                    <div><dt>Capacidad solicitada</dt><dd><%= pedida > 0 ? numero(pedida) + " Gbps" : "—" %></dd></div>
                </dl>
                <% if (alcanza) { %>
                <div class="alert ok" style="margin: 16px 0 0">
                    <strong>La ruta tiene capacidad disponible</strong>
                    Si al evaluarla ya no alcanza, la solicitud quedará Pendiente por capacidad o será rechazada.
                </div>
                <% } else { %>
                <div class="alert warn" style="margin: 16px 0 0">
                    <strong>Hoy la capacidad no alcanza</strong>
                    Puedes registrarla igual; al evaluarla podrá quedar Pendiente por capacidad.
                </div>
                <% } %>
                <% } %>
                <p class="small form-note">
                    La capacidad de una ruta la limita su segmento con menos capacidad disponible.
                </p>
            </aside>
        </div>
    </main>
</div>

</body>
</html>
