package controller;

import beans.ClienteAfectado;
import beans.Paginacion;
import beans.Segmento;
import beans.ServicioAfectado;
import beans.Usuario;
import beans.UtilizacionHist;
import beans.UtilizacionSegmento;
import dao.SupervisorDAO;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/*
 * Controlador del rol Supervisor (RF32 - RF39).
 * El Supervisor solo consulta información: todas las acciones son GET y ninguna modifica la BD.
 * Los listados se paginan en el servidor (parámetro "pagina", 10 filas por página).
 */
@WebServlet(name = "SupervisorServlet", value = "/SupervisorServlet")
public class SupervisorServlet extends HttpServlet {


    private static final int ROL_SUPERVISOR = 5;


    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {


        if (usuarioSesion(request) == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        String action = request.getParameter("action") == null
                ? "dashboard"
                : request.getParameter("action");

        SupervisorDAO dao = new SupervisorDAO();
        RequestDispatcher view;

        switch (action) {


            // RF32, RF33, RF34, RF36, RF37: vista general de la red
            case "dashboard":

                request.setAttribute("segmentosPorEstado", dao.contarSegmentosPorEstado());
                request.setAttribute("landingPorEstado", dao.contarLandingPorEstado());
                request.setAttribute("landingConIncidencias", dao.contarLandingConIncidencias());
                request.setAttribute("capacidadRed", dao.obtenerCapacidadRed());
                request.setAttribute("altaUtilizacion", dao.listarSegmentos(null, null, "minimo80", null, null, true, null));
                request.setAttribute("incidenciasPorSeveridad", dao.contarIncidenciasPor("severidad", "abiertas", null, null, null, null, null));
                request.setAttribute("afectados", dao.resumirAfectados(null, null, null, null, null));
                request.setAttribute("clientes", dao.contarClientes());
                request.setAttribute("mantenimientosPendientes", dao.listarMantenimientos("abiertas", null, null, null, null, null, null));
                request.setAttribute("ahora", ahora());

                view = request.getRequestDispatcher("/supervisor/Dashboard.jsp");
                view.forward(request, response);
                break;


            // RF33, RF37: segmentos y su nivel de utilización
            case "segmentos":

                String buscar = request.getParameter("buscar");
                String estado = request.getParameter("estado");
                String nivel = request.getParameter("nivel");
                String landing = request.getParameter("landing");

                Paginacion pagSeg = new Paginacion(request.getParameter("pagina"));
                pagSeg.setUrl(armarUrl(request, "segmentos", "buscar", buscar, "estado", estado,
                        "nivel", nivel, "landing", landing));

                request.setAttribute("segmentos", dao.listarSegmentos(buscar, estado, nivel, landing, null, false, pagSeg));
                request.setAttribute("paginacion", pagSeg);
                request.setAttribute("capacidadRed", dao.obtenerCapacidadRed());
                request.setAttribute("normal", dao.contarSegmentosPorNivel("normal"));
                request.setAttribute("alta", dao.contarSegmentosPorNivel("alta"));
                request.setAttribute("critica", dao.contarSegmentosPorNivel("critica"));
                request.setAttribute("landings", dao.listarLandingStations());
                request.setAttribute("buscar", buscar);
                request.setAttribute("estado", estado);
                request.setAttribute("nivel", nivel);
                request.setAttribute("landing", landing);

                view = request.getRequestDispatcher("/supervisor/Segmentos.jsp");
                view.forward(request, response);
                break;


            // Detalle de un segmento: capacidad, incidencias, servicios, mantenimientos e histórico
            case "detalleSegmento":

                String codigo = request.getParameter("codigo");
                Segmento segmento = vacio(codigo) ? null : dao.obtenerSegmento(codigo);

                if (segmento == null) {
                    response.sendRedirect(request.getContextPath() + "/SupervisorServlet?action=segmentos");
                    return;
                }

                request.setAttribute("segmento", segmento);
                request.setAttribute("incidencias", dao.listarIncidencias(null, null, null, codigo, null, null, null, "reciente", null));
                request.setAttribute("servicios", dao.listarServiciosDeSegmento(codigo));
                request.setAttribute("rutas", dao.listarRutasDeSegmento(codigo));
                request.setAttribute("mantenimientos", dao.listarMantenimientos(null, null, null, null, codigo, null, null));
                request.setAttribute("historial", dao.listarHistorialUtilizacion(codigo, null, null, null));

                view = request.getRequestDispatcher("/supervisor/DetalleSegmento.jsp");
                view.forward(request, response);
                break;


            // RF32: Landing Stations
            case "landing":

                String buscarLs = request.getParameter("buscar");
                String estadoLs = request.getParameter("estado");
                // "activas": solo estaciones con incidencias activas (tarjeta "Con incidencias activas")
                String incidenciasLs = "activas".equals(request.getParameter("incidencias")) ? "activas" : null;

                Paginacion pagLs = new Paginacion(request.getParameter("pagina"));
                pagLs.setUrl(armarUrl(request, "landing", "buscar", buscarLs, "estado", estadoLs,
                        "incidencias", incidenciasLs));

                request.setAttribute("estaciones", dao.listarLandingStations(buscarLs, estadoLs, incidenciasLs != null, pagLs));
                request.setAttribute("paginacion", pagLs);
                request.setAttribute("landingPorEstado", dao.contarLandingPorEstado());
                request.setAttribute("landingConIncidencias", dao.contarLandingConIncidencias());
                request.setAttribute("buscar", buscarLs);
                request.setAttribute("estado", estadoLs);
                request.setAttribute("incidencias", incidenciasLs);

                view = request.getRequestDispatcher("/supervisor/LandingStations.jsp");
                view.forward(request, response);
                break;


            // RF34: incidencias activas y su severidad
            case "incidencias":

                String severidad = request.getParameter("severidad");
                String estadoInc = request.getParameter("estado");
                String segmentoInc = request.getParameter("segmento");

                Paginacion pagInc = new Paginacion(request.getParameter("pagina"));
                pagInc.setUrl(armarUrl(request, "incidencias", "severidad", severidad,
                        "estado", estadoInc, "segmento", segmentoInc));

                request.setAttribute("incidencias", dao.listarIncidencias("abiertas", estadoInc, severidad,
                        segmentoInc, null, null, null, "severidad", pagInc));
                request.setAttribute("paginacion", pagInc);
                request.setAttribute("porSeveridad", dao.contarIncidenciasPor("severidad", "abiertas", null, null, null, null, null));
                request.setAttribute("totalRegistradas", dao.contarIncidencias(null, null, null, null, null, null));
                request.setAttribute("segmentosFiltro", dao.listarSegmentos());
                request.setAttribute("severidad", severidad);
                request.setAttribute("estado", estadoInc);
                request.setAttribute("segmento", segmentoInc);

                view = request.getRequestDispatcher("/supervisor/IncidenciasActivas.jsp");
                view.forward(request, response);
                break;


            // RF35: servicios y clientes afectados (dos tablas, cada una con su paginación)
            case "afectados":

                String buscarAf = request.getParameter("buscar");
                String incidencia = request.getParameter("incidencia");
                String situacion = request.getParameter("situacion");

                Paginacion pagServ = new Paginacion(request.getParameter("pagina"));
                Paginacion pagCli = new Paginacion(request.getParameter("paginaCli"));

                List<ServicioAfectado> servicios = dao.listarServiciosAfectados(buscarAf, incidencia, null, null,
                        null, situacion, 0, pagServ);
                List<ClienteAfectado> clientesAf = dao.listarClientesAfectados(buscarAf, incidencia, null, null,
                        null, situacion, pagCli);

                // cada tabla conserva la página en la que está la otra
                pagServ.setUrl(armarUrl(request, "afectados", "buscar", buscarAf, "incidencia", incidencia,
                        "situacion", situacion, "paginaCli", String.valueOf(pagCli.getPagina())));
                pagCli.setUrl(armarUrl(request, "afectados", "buscar", buscarAf, "incidencia", incidencia,
                        "situacion", situacion, "pagina", String.valueOf(pagServ.getPagina())));

                request.setAttribute("servicios", servicios);
                request.setAttribute("clientesAfectados", clientesAf);
                request.setAttribute("paginacion", pagServ);
                request.setAttribute("paginacionClientes", pagCli);
                request.setAttribute("afectados", dao.resumirAfectados(null, null, null, null, null));
                request.setAttribute("interrumpidos", dao.resumirAfectados(null, null, null, null, "Interrumpido")[0]);
                request.setAttribute("serviciosActivos", dao.contarServiciosActivos());
                request.setAttribute("clientes", dao.contarClientes());
                request.setAttribute("incidenciasFiltro", dao.listarIncidencias("abiertas", null, null, null, null, null, null, "severidad", null));
                request.setAttribute("buscar", buscarAf);
                request.setAttribute("incidencia", incidencia);
                request.setAttribute("situacion", situacion);

                view = request.getRequestDispatcher("/supervisor/ServiciosAfectados.jsp");
                view.forward(request, response);
                break;


            // RF36: mantenimientos programados y realizados
            case "mantenimientos":

                String estadoMnt = request.getParameter("estado");
                String tipo = request.getParameter("tipo");
                String desdeMnt = request.getParameter("desde");
                String hastaMnt = request.getParameter("hasta");

                Paginacion pagMnt = new Paginacion(request.getParameter("pagina"));
                pagMnt.setUrl(armarUrl(request, "mantenimientos", "estado", estadoMnt, "tipo", tipo,
                        "desde", desdeMnt, "hasta", hastaMnt));

                request.setAttribute("mantenimientos", dao.listarMantenimientos(estadoMnt, tipo, desdeMnt, hastaMnt, null, null, pagMnt));
                request.setAttribute("paginacion", pagMnt);
                request.setAttribute("porEstado", dao.contarMantenimientosPorEstado());
                request.setAttribute("estado", estadoMnt);
                request.setAttribute("tipo", tipo);
                request.setAttribute("desde", desdeMnt);
                request.setAttribute("hasta", hastaMnt);

                view = request.getRequestDispatcher("/supervisor/Mantenimientos.jsp");
                view.forward(request, response);
                break;


            // RF38: reportes con criterios y filtros
            case "reporte":

                cargarReporte(request, dao);

                view = request.getRequestDispatcher("/supervisor/Reportes.jsp");
                view.forward(request, response);
                break;


            // RF39: indicadores históricos de operación
            case "historicos":

                String desdeH = request.getParameter("desde");
                String hastaH = request.getParameter("hasta");
                String segmentoH = request.getParameter("segmento");
                String tipoH = request.getParameter("tipo");

                // por defecto: desde el primer mes con historial hasta hoy
                if (!esFecha(desdeH)) {
                    desdeH = dao.obtenerPrimerMesHistorial();
                    if (desdeH == null) {
                        desdeH = java.time.LocalDate.now().minusMonths(6).withDayOfMonth(1).toString();
                    }
                }
                if (!esFecha(hastaH)) {
                    hastaH = java.time.LocalDate.now().toString();
                }

                Paginacion pagEv = new Paginacion(request.getParameter("pagina"));
                pagEv.setUrl(armarUrl(request, "historicos", "desde", desdeH, "hasta", hastaH,
                        "segmento", segmentoH, "tipo", tipoH));

                request.setAttribute("eventos", dao.listarEventos(desdeH, hastaH, segmentoH, tipoH, pagEv));
                request.setAttribute("paginacion", pagEv);
                request.setAttribute("meses", dao.listarIndicadoresMensuales(segmentoH, null, desdeH, hastaH));
                request.setAttribute("incidenciasPeriodo", dao.contarIncidencias(null, null, segmentoH, null, desdeH, hastaH));
                request.setAttribute("resueltasPeriodo", dao.contarIncidencias("cerradas", null, segmentoH, null, desdeH, hastaH));
                request.setAttribute("finalizadosPeriodo", dao.contarMantenimientos("Finalizado", desdeH, hastaH, segmentoH));
                request.setAttribute("enEjecucionPeriodo", dao.contarMantenimientos("En ejecución", desdeH, hastaH, segmentoH));
                request.setAttribute("segmentosFiltro", dao.listarSegmentos());
                request.setAttribute("desde", desdeH);
                request.setAttribute("hasta", hastaH);
                request.setAttribute("segmento", segmentoH);
                request.setAttribute("tipo", tipoH);

                view = request.getRequestDispatcher("/supervisor/Historicos.jsp");
                view.forward(request, response);
                break;


            default:
                response.sendRedirect(request.getContextPath() + "/SupervisorServlet?action=dashboard");
        }
    }

    /*
     * RF38: arma el reporte elegido. Cada tipo reutiliza las consultas de su página,
     * con los filtros del formulario. El detalle del reporte se pagina igual que los listados.
     */
    private void cargarReporte(HttpServletRequest request, SupervisorDAO dao) throws IOException {

        String tipo = request.getParameter("tipo");
        if (vacio(tipo)) {
            tipo = "incidencias";
        }
        String desde = request.getParameter("desde");
        String hasta = request.getParameter("hasta");
        String segmento = request.getParameter("segmento");
        String landing = request.getParameter("landing");
        String severidad = request.getParameter("severidad");
        String estado = request.getParameter("estado");   // "abiertas" o "cerradas"

        // por defecto: desde el inicio de hace dos meses hasta hoy
        if (!esFecha(desde)) {
            desde = java.time.LocalDate.now().minusMonths(2).withDayOfMonth(1).toString();
        }
        if (!esFecha(hasta)) {
            hasta = java.time.LocalDate.now().toString();
        }
        String error = null;
        if (desde.compareTo(hasta) > 0) {
            error = "La fecha \"Desde\" no puede ser posterior a la fecha \"Hasta\".";
        }

        Paginacion pag = new Paginacion(request.getParameter("pagina"));
        pag.setUrl(armarUrl(request, "reporte", "tipo", tipo, "desde", desde, "hasta", hasta,
                "segmento", segmento, "landing", landing, "severidad", severidad, "estado", estado));

        if (error == null) {
            switch (tipo) {

                case "red":
                    // situación actual: no depende de las fechas
                    request.setAttribute("segmentosPorEstado", dao.contarSegmentosPorEstado());
                    request.setAttribute("landingPorEstado", dao.contarLandingPorEstado());
                    request.setAttribute("incidenciasPorSeveridad", dao.contarIncidenciasPor("severidad", "abiertas", null, null, null, null, null));
                    request.setAttribute("afectados", dao.resumirAfectados(null, null, null, null, null));
                    request.setAttribute("detalle", dao.listarSegmentos(null, null, null, landing, segmento, false, pag));
                    break;

                case "utilizacion":
                    List<UtilizacionHist> registros = dao.listarHistorialUtilizacion(segmento, landing, desde, hasta);

                    // un resumen por segmento (primer mes, último mes y máximo del periodo)
                    Map<String, UtilizacionSegmento> porSegmento = new LinkedHashMap<>();
                    for (UtilizacionHist u : registros) {
                        UtilizacionSegmento us = porSegmento.get(u.getCodigoSegmento());
                        if (us == null) {
                            us = new UtilizacionSegmento();
                            us.setCodigoSegmento(u.getCodigoSegmento());
                            porSegmento.put(u.getCodigoSegmento(), us);
                        }
                        us.agregar(u);
                    }
                    List<UtilizacionSegmento> resumen = new ArrayList<>(porSegmento.values());
                    resumen.sort((a, b) -> Double.compare(b.getPorcentajeFinal(), a.getPorcentajeFinal()));

                    request.setAttribute("resumenSegmentos", resumen);
                    request.setAttribute("meses", dao.listarIndicadoresMensuales(segmento, landing, desde, hasta));

                    // este detalle se arma en Java (no es una sola consulta), por eso se pagina la lista
                    pag.setTotalRegistros(resumen.size());
                    request.setAttribute("detalle", resumen.subList(pag.getInicio(), pag.getFin()));
                    break;

                case "afectados":
                    // situación actual de las incidencias activas (filtros: segmento, landing, severidad)
                    List<ServicioAfectado> todos = dao.listarServiciosAfectados(null, null, severidad, segmento,
                            landing, null, 0, null);
                    List<ClienteAfectado> clientes = dao.listarClientesAfectados(null, null, severidad, segmento,
                            landing, null, pag);

                    // servicios e incidencias de cada cliente de la página
                    for (ClienteAfectado ca : clientes) {
                        List<String> codServicios = new ArrayList<>();
                        List<String> codIncidencias = new ArrayList<>();
                        for (ServicioAfectado sa : todos) {
                            if (sa.getIdCliente() == ca.getIdCliente()) {
                                codServicios.add(String.format("SRV-%03d", sa.getIdServicio()));
                                for (String inc : sa.getIncidencias().split(", ")) {
                                    if (!inc.isEmpty() && !codIncidencias.contains(inc)) {
                                        codIncidencias.add(inc);
                                    }
                                }
                            }
                        }
                        java.util.Collections.sort(codIncidencias);
                        ca.setServicios(String.join(", ", codServicios));
                        ca.setIncidencias(String.join(", ", codIncidencias));
                    }

                    request.setAttribute("serviciosAfectados", todos);
                    request.setAttribute("afectados", dao.resumirAfectados(null, severidad, segmento, landing, null));
                    request.setAttribute("serviciosActivos", dao.contarServiciosActivos());
                    request.setAttribute("clientes", dao.contarClientes());
                    request.setAttribute("detalle", clientes);
                    break;

                case "mantenimientos":
                    request.setAttribute("todos", dao.listarMantenimientos(estado, null, desde, hasta, segmento, landing, null));
                    request.setAttribute("detalle", dao.listarMantenimientos(estado, null, desde, hasta, segmento, landing, pag));
                    break;

                default: // incidencias
                    tipo = "incidencias";
                    request.setAttribute("registradas", dao.contarIncidencias(estado, severidad, segmento, landing, desde, hasta));
                    // si se filtró por "cerradas" no puede haber activas
                    request.setAttribute("activas", "cerradas".equals(estado) ? 0
                            : dao.contarIncidencias("abiertas", severidad, segmento, landing, desde, hasta));
                    request.setAttribute("porSeveridad", dao.contarIncidenciasPor("severidad", estado, severidad, segmento, landing, desde, hasta));
                    request.setAttribute("porEstado", dao.contarIncidenciasPor("estado", estado, severidad, segmento, landing, desde, hasta));
                    request.setAttribute("masAfectado", dao.obtenerSegmentoMasAfectado(estado, severidad, segmento, landing, desde, hasta));
                    request.setAttribute("detalle", dao.listarIncidencias(estado, null, severidad, segmento, landing, desde, hasta, "fecha", pag));
            }
        }

        request.setAttribute("tipo", tipo);
        request.setAttribute("desde", desde);
        request.setAttribute("hasta", hasta);
        request.setAttribute("segmento", segmento);
        request.setAttribute("landing", landing);
        request.setAttribute("severidad", severidad);
        request.setAttribute("estado", estado);
        request.setAttribute("error", error);
        request.setAttribute("paginacion", pag);
        request.setAttribute("segmentosFiltro", dao.listarSegmentos());
        request.setAttribute("landingsFiltro", dao.listarLandingStations());
        request.setAttribute("ahora", ahora());
    }


    // Solo entra el usuario con sesión y rol Supervisor (regla de negocio 8)
    private Usuario usuarioSesion(HttpServletRequest request) {
        Usuario u = (Usuario) request.getSession().getAttribute("usuarioSesion");
        if (u == null || u.getRol() == null || u.getRol().getIdRol() != ROL_SUPERVISOR) {
            return null;
        }
        return u;
    }


    /*
     * Enlace a una acción con sus filtros (solo los que tienen valor), listo para agregarle
     * "pagina=N". Se pasa en pares: nombre, valor, nombre, valor...
     * Ejemplo: /OCEANLINK/SupervisorServlet?action=segmentos&estado=Degradado&
     */
    private String armarUrl(HttpServletRequest request, String action, String... filtros) throws IOException {
        String url = request.getContextPath() + "/SupervisorServlet?action=" + action + "&";
        for (int i = 0; i + 1 < filtros.length; i += 2) {
            if (!vacio(filtros[i + 1])) {
                url += filtros[i] + "=" + URLEncoder.encode(filtros[i + 1], "UTF-8") + "&";
            }
        }
        return url;
    }


    private String ahora() {
        return java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
    }

    private boolean vacio(String valor) {
        return valor == null || valor.trim().isEmpty();
    }

    private boolean esFecha(String valor) {
        return valor != null && valor.matches("\\d{4}-\\d{2}-\\d{2}");
    }
}
