<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ page import="beans.LandingStation" %>
<%@ page import="beans.Usuario" %>
<%@ include file="badges.jspf" %>
<%
    List<Segmento> seleccionados = (List<Segmento>) request.getAttribute("seleccionados");
    if (seleccionados == null) seleccionados = new ArrayList<>();

    LandingStation landing = (LandingStation) request.getAttribute("landing");

    String titulo = request.getParameter("titulo");
    String descripcion = request.getParameter("descripcion");
    String severidad = request.getParameter("severidad");
    String fecha = request.getParameter("fecha_deteccion");
    String idLanding = request.getParameter("id_landing");
    String estadoSegmento = request.getParameter("estado_segmento");

    // 2026-10-21T14:20 -> 21/10/2026 14:20
    String fechaMostrar = fecha;
    if (fecha != null && fecha.length() >= 16) {
        fechaMostrar = fecha.substring(8, 10) + "/" + fecha.substring(5, 7) + "/"
                + fecha.substring(0, 4) + " " + fecha.substring(11, 16);
    }

    Usuario usuarioSesion = (Usuario) session.getAttribute("usuarioSesion");
    String registradaPor = usuarioSesion == null ? "—"
            : usuarioSesion.getNombre() + " " + usuarioSesion.getApellido1();

    String servlet = request.getContextPath() + "/NetworkOperatorServlet";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Confirmar incidencia | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/networkOperator/networkOperator.css">
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="formRegistrar"/>
</jsp:include>

    <main class="content">
        <%-- "Volver" reenvía los mismos datos al Servlet (formulario de abajo), sin JavaScript --%>
        <button type="submit" form="formConfirmar" formaction="<%= servlet %>?action=volverFormulario" class="back-link">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
            Volver a editar los datos
        </button>

        <div class="topbar">
            <div>
                <h1>Registrar incidencia</h1>
                <p class="small">Revisa la información antes de registrar la incidencia.</p>
            </div>
        </div>

        <ol class="wizard">
            <li class="done"><span>✓</span>Datos de la incidencia</li>
            <li class="current"><span>2</span>Confirmación</li>
        </ol>

        <div class="split">
            <div>
                <section class="card">
                    <div class="card-header">
                        <h2>Información general</h2>
                    </div>
                    <dl class="kv">
                        <div><dt>Título</dt><dd><%= texto(titulo) %></dd></div>
                        <div><dt>Descripción</dt><dd><%= texto(descripcion) %></dd></div>
                        <div><dt>Severidad</dt><dd><span class="badge <%= claseSeveridad(severidad) %>"><%= texto(severidad) %></span></dd></div>
                        <div><dt>Fecha de detección</dt><dd><%= texto(fechaMostrar) %></dd></div>
                        <div><dt>Estado inicial</dt><dd><span class="badge red">Detectada</span></dd></div>
                        <div><dt>Registrada por</dt><dd><%= registradaPor %></dd></div>
                    </dl>
                </section>

                <section class="card">
                    <div class="card-header">
                        <h2>Infraestructura afectada</h2>
                        <span class="small">
                            <%= landing == null ? texto(idLanding) : "Estación " + landing.getIdLanding() + " · " + landing.getNombre().replace("Estación ", "") %>
                        </span>
                    </div>
                    <div class="table-wrap">
                        <table class="table">
                            <thead>
                            <tr>
                                <th>Segmento</th>
                                <th>Tramo</th>
                                <th>Cambio de estado</th>
                            </tr>
                            </thead>
                            <tbody>
                            <% for (Segmento seg : seleccionados) { %>
                            <tr>
                                <td class="cell-main"><%= seg.getCodigoSegmento() %></td>
                                <td class="tramo"><%= seg.getTramo() %></td>
                                <td>
                                    <span class="badge <%= claseEstadoSegmento(seg.getEstado()) %>"><%= seg.getEstado() %></span>
                                    <% if (!"Sin cambio".equals(estadoSegmento)) { %>
                                    <span class="arrow">→</span>
                                    <span class="badge <%= claseEstadoSegmento(estadoSegmento) %>"><%= texto(estadoSegmento) %></span>
                                    <% } %>
                                </td>
                            </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </section>
            </div>

            <aside class="card">
                <div class="card-header">
                    <h2>Impacto estimado</h2>
                </div>
                <dl class="kv">
                    <div><dt>Segmentos afectados</dt><dd><%= seleccionados.size() %></dd></div>
                    <div><dt>Servicios afectados</dt><dd class="bad"><%= request.getAttribute("serviciosAfectados") %></dd></div>
                    <div><dt>Clientes afectados</dt><dd class="bad"><%= request.getAttribute("clientesAfectados") %></dd></div>
                </dl>
                <div class="alert info" style="margin: 16px 0 0">
                    Después de registrarla podrás actualizar su estado, añadir observaciones y consultar los servicios y clientes afectados.
                </div>
            </aside>
        </div>

        <!-- Los datos de la incidencia se envían al Servlet para guardarlos -->
        <form id="formConfirmar" class="card footer-action" method="post" action="<%= servlet %>?action=crear"
              style="border-top: 1px solid var(--border)">
            <input type="hidden" name="titulo" value="<%= texto(titulo) %>">
            <input type="hidden" name="descripcion" value="<%= texto(descripcion) %>">
            <input type="hidden" name="severidad" value="<%= texto(severidad) %>">
            <input type="hidden" name="fecha_deteccion" value="<%= texto(fecha) %>">
            <input type="hidden" name="id_landing" value="<%= texto(idLanding) %>">
            <input type="hidden" name="estado_segmento" value="<%= texto(estadoSegmento) %>">
            <% for (Segmento seg : seleccionados) { %>
            <input type="hidden" name="segmentos" value="<%= seg.getCodigoSegmento() %>">
            <% } %>
            <button type="submit" formaction="<%= servlet %>?action=volverFormulario" class="ghost">Atrás</button>
            <button type="submit" class="primary">Registrar incidencia</button>
        </form>
    </main>
</div>

</body>
</html>
