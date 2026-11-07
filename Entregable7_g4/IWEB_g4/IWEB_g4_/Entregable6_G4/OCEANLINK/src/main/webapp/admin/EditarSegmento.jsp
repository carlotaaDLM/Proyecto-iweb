<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="beans.Segmento" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/SegmentoServlet";
    String error = (String) request.getAttribute("error");
    Segmento s = (Segmento) request.getAttribute("segmento");
    List<String> estados = (List<String>) request.getAttribute("estados");

    double minimo = s.getCapacidadUtilizada() + s.getCapacidadReservada();
    // Si hubo un error se muestra lo que escribió el administrador
    String capacidad = request.getParameter("capacidad_total") != null
            ? request.getParameter("capacidad_total")
            : String.valueOf(s.getCapacidadTotal());
    String estado = request.getParameter("estado") != null ? request.getParameter("estado") : s.getEstado();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Editar <%= s.getCodigoSegmento() %> | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="segmentos"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=lista">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a segmentos
        </a>

        <div class="topbar">
            <div>
                <h1>Editar segmento</h1>
                <p class="small">El código y el tramo no se pueden cambiar.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <div class="split">
            <form action="<%= servlet %>" class="card" method="post">
                <input type="hidden" name="action" value="actualizar">
                <input type="hidden" name="codigo_segmento" value="<%= s.getCodigoSegmento() %>">
                <fieldset>
                    <legend>Datos del segmento</legend>
                    <div class="row">
                        <div class="col">
                            <label for="codigo">Código</label>
                            <input id="codigo" type="text" value="<%= s.getCodigoSegmento() %>" readonly/>
                        </div>
                        <div class="col">
                            <label for="tramo">Tramo</label>
                            <input id="tramo" type="text" value="<%= texto(s.getNombreOrigen()) %> - <%= texto(s.getNombreDestino()) %>" readonly/>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col">
                            <label for="capacidad">Capacidad total (Gbps) <span class="req">*</span></label>
                            <input id="capacidad" name="capacidad_total" type="number" min="<%= Math.max(1, minimo) %>" max="100000"
                                   step="0.01" required value="<%= texto(capacidad) %>"/>
                            <span class="hint">Mínimo <%= numero(minimo) %> Gbps (lo utilizado + reservado).</span>
                        </div>
                        <div class="col">
                            <label for="estado">Estado <span class="req">*</span></label>
                            <select id="estado" name="estado" required>
                                <% for (String e : estados) { %>
                                <option <%= e.equals(estado) ? "selected" : "" %>><%= e %></option>
                                <% } %>
                            </select>
                        </div>
                    </div>
                </fieldset>

                <div class="footer-action">
                    <a class="ghost" href="<%= servlet %>?action=lista">Cancelar</a>
                    <button class="primary" type="submit">Guardar cambios</button>
                </div>
            </form>

            <aside class="card">
                <div class="card-header">
                    <h2>Capacidad actual</h2>
                </div>
                <dl class="kv">
                    <div><dt>Total</dt><dd><%= numero(s.getCapacidadTotal()) %> Gbps</dd></div>
                    <div><dt>Utilizada</dt><dd><%= numero(s.getCapacidadUtilizada()) %> Gbps</dd></div>
                    <div><dt>Reservada</dt><dd><%= numero(s.getCapacidadReservada()) %> Gbps</dd></div>
                    <div><dt>Disponible</dt><dd class="ok"><%= numero(s.getCapacidadDisponible()) %> Gbps</dd></div>
                    <div><dt>Servicios activos</dt><dd><%= s.getCantidadServicios() %></dd></div>
                </dl>
                <div class="usage <%= claseUso(s.getPorcentajeOcupacion()) %>" style="margin-top: 14px">
                    <div class="usage-bar"><span style="width: <%= Math.min(100, s.getPorcentajeOcupacion()) %>%"></span></div>
                    <span class="usage-value"><%= decimal(s.getPorcentajeOcupacion()) %>%</span>
                </div>
            </aside>
        </div>
    </main>
</div>

</body>
</html>
