<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%@ page import="java.util.List" %>
<%@ page import="beans.Incidencia" %>
<%@ page import="beans.SegmentoAtencion" %>
<%@ include file="badges.jspf" %>

<%
    Integer segmentosOperativos =
            (Integer) request.getAttribute("segmentosOperativos");

    Integer segmentosSeguimiento =
            (Integer) request.getAttribute("segmentosSeguimiento");

    Integer segmentosFueraServicio =
            (Integer) request.getAttribute("segmentosFueraServicio");

    Integer totalSegmentos =
            (Integer) request.getAttribute("totalSegmentos");

    Integer incidenciasAbiertas =
            (Integer) request.getAttribute("incidenciasAbiertas");

    Integer serviciosActivos =
            (Integer) request.getAttribute("serviciosActivos");

   Integer serviciosAfectados =
           (Integer) request.getAttribute("serviciosAfectados");

   Integer clientesAfectados =
           (Integer) request.getAttribute("clientesAfectados");

   if (clientesAfectados == null) {
       clientesAfectados = 0;
   }

    List<Incidencia> incidencias =
            (List<Incidencia>) request.getAttribute("incidencias");


    List<SegmentoAtencion> segmentosAtencion =
            (List<SegmentoAtencion>) request.getAttribute("segmentosAtencion");

    if (segmentosAtencion == null) {
        segmentosAtencion = new java.util.ArrayList<>();
    }

    if (serviciosActivos == null)
        serviciosActivos = 0;

    if (serviciosAfectados == null)
        serviciosAfectados = 0;

    if (incidenciasAbiertas == null)
        incidenciasAbiertas = 0;

    if (segmentosOperativos == null)
        segmentosOperativos = 0;

    if (segmentosSeguimiento == null)
        segmentosSeguimiento = 0;

    if (segmentosFueraServicio == null)
        segmentosFueraServicio = 0;

    if (clientesAfectados == null) {
           clientesAfectados = 0;
       }

    if (totalSegmentos == null)
        totalSegmentos = 0;

    Integer incidenciasRestauradas =
            (Integer) request.getAttribute("incidenciasRestauradas");

    if (incidenciasRestauradas == null)
        incidenciasRestauradas = 0;

    String servlet = request.getContextPath() + "/NetworkOperatorServlet";

    String actualizado = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm")
            .format(new java.util.Date());

    double disponibilidad =
            totalSegmentos > 0
                    ? (segmentosOperativos * 100.0 / totalSegmentos)
                    : 0;


    System.out.println(
            "JSP - INCIDENCIAS: " +
            (incidencias == null ? "NULL" : incidencias.size())
    );
%>


<!DOCTYPE html>
<html lang="es">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1">

    <title>Vista general | OceanLink</title>

    <link rel="stylesheet"
          href="<%= request.getContextPath() %>/networkOperator/networkOperator.css">

</head>


<body>


<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="vistaGeneral"/>
</jsp:include>


    <main class="content">


        <div class="topbar">

            <div>

                <h1>
                    Vista general
                </h1>

                <p class="small">
                    Estado actual de la red y de las incidencias en curso.
                </p>

            </div>


            <a href="<%= servlet %>?action=formRegistrar"
               class="primary">

                Registrar incidencia

            </a>

        </div>



        <section class="stats">


            <a href="<%= servlet %>?action=estadoSegmentos&estado=Operativo"
               class="stat ok">

                <span class="stat-label">
                    Segmentos operativos
                </span>

                <span class="stat-value">

                    <%= segmentosOperativos %>

                    <small>
                        de <%= totalSegmentos %>
                    </small>

                </span>

                <span class="small">
                    Funcionan con normalidad
                </span>

            </a>



            <a href="<%= servlet %>?action=estadoSegmentos"
               class="stat warn">

                <span class="stat-label">
                    Requieren seguimiento
                </span>

                <span class="stat-value">
                    <%= segmentosSeguimiento %>
                </span>

                <span class="small">
                    Segmentos degradados o en mantenimiento
                </span>

            </a>



            <a href="<%= servlet %>?action=estadoSegmentos&estado=Fuera+de+servicio"
               class="stat bad">

                <span class="stat-label">
                    Fuera de servicio
                </span>

                <span class="stat-value">
                    <%= segmentosFueraServicio %>
                </span>

                <span class="small">
                    Interrupción del servicio
                </span>

            </a>



            <a href="<%= servlet %>?action=listarIncidencias"
               class="stat info">

                <span class="stat-label">
                    Incidencias abiertas
                </span>

                <span class="stat-value">
                    <%= incidenciasAbiertas %>
                </span>

                <span class="small">
                    <%= incidenciasRestauradas %> más con servicio restaurado
                </span>

            </a>


        </section>



        <section class="card">


            <div class="card-header">

                <h2>
                    Estado de la red
                </h2>

                <span class="small">
                    Actualizado al <%= actualizado %>
                </span>

            </div>


            <div class="record-head">


                <div>

                    <span class="stat-label">
                        Segmentos
                    </span>

                    <span class="big">
                        <%= totalSegmentos %>
                    </span>

                    <span class="small">
                        en la red submarina
                    </span>

                </div>



                <div>

                    <span class="stat-label">
                        Disponibilidad
                    </span>

                    <span class="big">

                        <%= String.format(
                                "%.1f",
                                disponibilidad
                           ).replace('.', ',') %>%

                    </span>

                    <span class="small">
                        de segmentos operativos
                    </span>

                </div>



                <div>

                    <span class="stat-label">
                        Servicios activos
                    </span>

                    <span class="big">
                        <%= serviciosActivos %>
                    </span>

                    <span class="small">
                        <%= serviciosAfectados %> afectados por incidencias
                    </span>

                </div>



                <div>

                    <span class="stat-label">
                        Clientes afectados
                    </span>

                    <span class="big">
                        <%= clientesAfectados %>
                    </span>

                    <span class="small">
                        por incidencias abiertas
                    </span>

                </div>


            </div>


        </section>



        <!-- ========================================= -->
        <!-- INCIDENCIAS ABIERTAS MÁS RECIENTES -->
        <!-- ========================================= -->


        <section class="card">


            <div class="card-header">

                <h2>
                    Incidencias abiertas más recientes
                </h2>

                <a href="<%= servlet %>?action=listarIncidencias"
                   class="cell-link small">

                    Ver todas

                </a>

            </div>



            <div class="table-wrap">


                <table class="table">


                    <thead>

                        <tr>

                            <th>
                                Código
                            </th>

                            <th>
                                Incidencia
                            </th>

                            <th>
                                Severidad
                            </th>

                            <th>
                                Estado
                            </th>

                            <th>
                                Detección
                            </th>

                            <th>
                            </th>

                        </tr>

                    </thead>



                    <tbody>


                    <%
                        if (incidencias != null &&
                            !incidencias.isEmpty()) {


                            for (Incidencia incidencia : incidencias) {
                    %>


                        <tr>


                            <td class="cell-main">

                                <a href="<%= servlet %>?action=detalleIncidencia&codigo=<%= url(incidencia.getCodigoIncidencia()) %>"
                                   class="cell-link">

                                    <%= incidencia.getCodigoIncidencia() %>

                                </a>

                            </td>



                            <td>

                                <%= incidencia.getTitulo() %>

                                <span class="cell-sub">

                                    <%= incidencia.getCodigoSegmento() %>

                                </span>

                            </td>



                            <td>

                                <span class="badge <%= claseSeveridad(incidencia.getSeveridad()) %>"><%= incidencia.getSeveridad() %></span>

                            </td>



                            <td>

                                <span class="badge <%= claseEstadoIncidencia(incidencia.getEstado()) %>"><%= incidencia.getEstado() %></span>

                            </td>



                            <td class="date">

                                <%= incidencia.getFechaDeteccion() %>

                            </td>



                            <td>

                                <a href="<%= servlet %>?action=detalleIncidencia&codigo=<%= url(incidencia.getCodigoIncidencia()) %>"
                                   class="ghost btn-sm">

                                    Ver detalle

                                </a>

                            </td>


                        </tr>


                    <%
                            }

                        } else {
                    %>


                        <tr>

                            <td colspan="6">

                                No hay incidencias abiertas.

                            </td>

                        </tr>


                    <%
                        }
                    %>


                    </tbody>


                </table>


            </div>


        </section>



        <!-- ========================================= -->
        <!-- SEGMENTOS QUE REQUIEREN ATENCIÓN -->
        <!-- ========================================= -->


        <section class="card">


            <div class="card-header">

                <h2>
                    Segmentos que requieren atención
                </h2>

                <a href="<%= servlet %>?action=estadoSegmentos"
                   class="cell-link small">

                    Ver todos los segmentos

                </a>

            </div>



            <div class="table-wrap">


                <table class="table">


                    <thead>

                        <tr>

                            <th>
                                Segmento
                            </th>

                            <th>
                                Tramo
                            </th>

                            <th>
                                Estado
                            </th>

                            <th class="num">
                                Incidencias abiertas
                            </th>

                            <th class="num">
                                Servicios que lo usan
                            </th>

                            <th>
                            </th>

                        </tr>

                    </thead>

                    <tbody>

                    <%

                        if (segmentosAtencion != null && !segmentosAtencion.isEmpty()) {

                            for (beans.SegmentoAtencion segmento : segmentosAtencion) {

                                String claseEstado = "blue";

                                if ("Degradado".equals(segmento.getEstado())) {
                                    claseEstado = "yellow";
                                } else if ("Fuera de servicio".equals(segmento.getEstado())) {
                                    claseEstado = "red";
                                } else if ("En mantenimiento".equals(segmento.getEstado())) {
                                    claseEstado = "blue";
                                }
                    %>

                    <tr>

                        <td class="cell-main">
                            <a href="<%= servlet %>?action=detalleSegmento&codigo=<%= url(segmento.getCodigoSegmento()) %>" class="cell-link">
                                <%= segmento.getCodigoSegmento() %>
                            </a>
                        </td>

                        <td class="tramo">
                            <%= segmento.getTramo() %>
                        </td>

                        <td>
                            <span class="badge <%= claseEstado %>">
                                <%= segmento.getEstado() %>
                            </span>
                        </td>

                        <td class="num">
                            <%= segmento.getIncidenciasAbiertas() %>
                        </td>

                        <td class="num">
                            <%= segmento.getServiciosQueLoUsan() %>
                        </td>

                        <td>
                            <a href="<%= servlet %>?action=detalleSegmento&codigo=<%= url(segmento.getCodigoSegmento()) %>" class="ghost btn-sm">
                                Ver detalle
                            </a>
                        </td>

                    </tr>

                    <%
                            }

                        } else {
                    %>

                    <tr>
                        <td colspan="6">
                            No hay segmentos que requieran atención.
                        </td>
                    </tr>

                    <%
                        }
                    %>

                    </tbody>


                </table>


            </div>


        </section>


    </main>


</div>


</body>

</html>