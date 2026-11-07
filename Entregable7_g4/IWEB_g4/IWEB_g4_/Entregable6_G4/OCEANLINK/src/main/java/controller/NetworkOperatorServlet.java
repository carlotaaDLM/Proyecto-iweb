package controller;

import beans.Incidencia;
import beans.Paginacion;
import beans.Segmento;
import beans.Usuario;
import dao.IncidenciaDAO;
import dao.NetworkOperatorDAO;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

@WebServlet(
        name = "NetworkOperatorServlet",
        value = "/NetworkOperatorServlet",
        loadOnStartup = 1
)
public class NetworkOperatorServlet extends HttpServlet {

    private static final int ROL_NETWORK_OPERATOR = 3;


    @Override
    public void init() throws ServletException {
        new IncidenciaDAO().prepararTablas();
    }



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
                ? "vistaGeneral"
                : request.getParameter("action");

        NetworkOperatorDAO dao = new NetworkOperatorDAO();
        IncidenciaDAO incidenciaDAO = new IncidenciaDAO();
        RequestDispatcher view;

        switch (action) {


            case "vistaGeneral":

                request.setAttribute("segmentos", dao.listarSegmentos());
                request.setAttribute("incidencias", dao.listarIncidenciasRecientes());
                request.setAttribute("segmentosAtencion", dao.obtenerSegmentosAtencion());

                request.setAttribute("segmentosOperativos", dao.contarSegmentosOperativos());
                request.setAttribute("segmentosSeguimiento", dao.contarSegmentosSeguimiento());
                request.setAttribute("segmentosFueraServicio", dao.contarSegmentosFueraServicio());
                request.setAttribute("totalSegmentos", dao.contarTotalSegmentos());
                request.setAttribute("incidenciasAbiertas", dao.contarIncidenciasAbiertas());
                request.setAttribute("incidenciasRestauradas", dao.contarIncidenciasRestauradas());
                request.setAttribute("serviciosActivos", dao.contarServiciosActivos());
                request.setAttribute("serviciosAfectados", dao.contarServiciosAfectados());
                request.setAttribute("clientesAfectados", dao.contarClientesAfectados());

                view = request.getRequestDispatcher("/networkOperator/VistaGeneral.jsp");
                view.forward(request, response);
                break;


            case "estadoSegmentos":

                String buscarSeg = request.getParameter("buscar");
                String estadoSeg = request.getParameter("estado");

                // Paginación en el servidor (10 por página), conservando los filtros
                Paginacion pagSeg = new Paginacion(request.getParameter("pagina"));
                pagSeg.setUrl(armarUrl(request, "estadoSegmentos", "buscar", buscarSeg, "estado", estadoSeg));

                request.setAttribute("segmentos", dao.listarSegmentosFiltrados(buscarSeg, estadoSeg, pagSeg));
                request.setAttribute("paginacion", pagSeg);
                request.setAttribute("operativos", dao.contarSegmentosOperativos());
                request.setAttribute("degradados", dao.contarSegmentosPorEstado("Degradado"));
                request.setAttribute("enMantenimiento", dao.contarSegmentosPorEstado("En mantenimiento"));
                request.setAttribute("fueraServicio", dao.contarSegmentosFueraServicio());
                request.setAttribute("buscar", buscarSeg);
                request.setAttribute("estado", estadoSeg);

                view = request.getRequestDispatcher("/networkOperator/EstadoSegmentos.jsp");
                view.forward(request, response);
                break;


            case "detalleSegmento":

                String codigoSegmento = request.getParameter("codigo");
                Segmento segmento = dao.obtenerSegmento(codigoSegmento);

                if (segmento == null) {
                    response.sendRedirect(request.getContextPath()
                            + "/NetworkOperatorServlet?action=estadoSegmentos");
                } else {
                    request.setAttribute("segmento", segmento);
                    request.setAttribute("servicios", dao.listarServiciosPorSegmento(codigoSegmento));
                    request.setAttribute("rutas", dao.listarRutasPorSegmento(codigoSegmento));
                    request.setAttribute("incidencias", dao.listarIncidenciasPorSegmento(codigoSegmento));

                    view = request.getRequestDispatcher("/networkOperator/DetalleSegmento.jsp");
                    view.forward(request, response);
                }
                break;


            case "listarIncidencias":

                String buscar = request.getParameter("buscar");
                String severidad = request.getParameter("severidad");
                String estado = request.getParameter("estado");
                String desde = request.getParameter("desde");
                String hasta = request.getParameter("hasta");

                Paginacion pagInc = new Paginacion(request.getParameter("pagina"));
                pagInc.setUrl(armarUrl(request, "listarIncidencias", "buscar", buscar, "severidad", severidad,
                        "estado", estado, "desde", desde, "hasta", hasta));

                request.setAttribute("incidencias",
                        dao.listarIncidenciasFiltradas(buscar, severidad, estado, desde, hasta, pagInc));
                request.setAttribute("paginacion", pagInc);

                request.setAttribute("criticas", dao.contarIncidenciasPorSeveridad("Crítica"));
                request.setAttribute("altas", dao.contarIncidenciasPorSeveridad("Alta"));
                request.setAttribute("medias", dao.contarIncidenciasPorSeveridad("Media"));
                request.setAttribute("bajas", dao.contarIncidenciasPorSeveridad("Baja"));
                request.setAttribute("total", dao.contarTotalIncidencias());
                request.setAttribute("abiertas", dao.contarIncidenciasAbiertas());

                request.setAttribute("buscar", buscar);
                request.setAttribute("severidad", severidad);
                request.setAttribute("estado", estado);
                request.setAttribute("desde", desde);
                request.setAttribute("hasta", hasta);

                view = request.getRequestDispatcher("/networkOperator/Incidencias.jsp");
                view.forward(request, response);
                break;


            case "formRegistrar":

                request.setAttribute("segmentos", dao.listarSegmentosFiltrados(null, null));
                request.setAttribute("landings", dao.listarLandingStations());
                request.setAttribute("segmentoMarcado", request.getParameter("segmento"));

                view = request.getRequestDispatcher("/networkOperator/RegistrarIncidencia.jsp");
                view.forward(request, response);
                break;


            case "detalleIncidencia":

                String codigo = request.getParameter("codigo");
                Incidencia incidencia = incidenciaDAO.obtenerIncidencia(codigo);

                if (incidencia == null) {
                    response.sendRedirect(request.getContextPath()
                            + "/NetworkOperatorServlet?action=listarIncidencias");
                } else {
                    request.setAttribute("incidencia", incidencia);
                    request.setAttribute("siguienteEstado",
                            IncidenciaDAO.siguienteEstado(incidencia.getEstado()));
                    request.setAttribute("segmentosIncidencia",
                            incidenciaDAO.listarSegmentosDeIncidencia(codigo));
                    request.setAttribute("servicios",
                            incidenciaDAO.listarServiciosAfectados(codigo));
                    request.setAttribute("clientes",
                            incidenciaDAO.listarClientesAfectados(codigo));
                    request.setAttribute("historial",
                            incidenciaDAO.listarHistorial(codigo, null, null, null, "DESC"));
                    request.setAttribute("ultimoCambio",
                            incidenciaDAO.obtenerFechaUltimoCambio(codigo));
                    request.setAttribute("msg", leerMensaje(request, "msg"));

                    view = request.getRequestDispatcher("/networkOperator/DetalleIncidencia.jsp");
                    view.forward(request, response);
                }
                break;


            case "historial":

                String codigoHist = request.getParameter("codigo");
                String severidadHist = request.getParameter("severidad");
                String desdeHist = request.getParameter("desde");
                String hastaHist = request.getParameter("hasta");

                if (codigoHist != null && !codigoHist.isEmpty()) {
                    request.setAttribute("incidencia", incidenciaDAO.obtenerIncidencia(codigoHist));
                    request.setAttribute("historialIncidencia",
                            incidenciaDAO.listarHistorial(codigoHist, null, null, null, "ASC"));
                }

                request.setAttribute("listaIncidencias",
                        dao.listarIncidenciasFiltradas(null, null, null, null, null));
                Paginacion pagHist = new Paginacion(request.getParameter("pagina"));
                pagHist.setUrl(armarUrl(request, "historial", "codigo", codigoHist, "severidad", severidadHist,
                        "desde", desdeHist, "hasta", hastaHist));

                request.setAttribute("cambios",
                        incidenciaDAO.listarHistorial(codigoHist, severidadHist, desdeHist, hastaHist, "DESC", pagHist));
                request.setAttribute("paginacion", pagHist);

                request.setAttribute("codigo", codigoHist);
                request.setAttribute("severidad", severidadHist);
                request.setAttribute("desde", desdeHist);
                request.setAttribute("hasta", hastaHist);

                view = request.getRequestDispatcher("/networkOperator/HistorialIncidencias.jsp");
                view.forward(request, response);
                break;


            case "borrar":

                incidenciaDAO.borrarIncidencia(request.getParameter("codigo"));

                response.sendRedirect(request.getContextPath()
                        + "/NetworkOperatorServlet?action=listarIncidencias");
                break;

            default:
                response.sendRedirect(request.getContextPath()
                        + "/NetworkOperatorServlet?action=vistaGeneral");
        }
    }


    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (usuarioSesion(request) == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        String action = request.getParameter("action") == null
                ? ""
                : request.getParameter("action");

        NetworkOperatorDAO dao = new NetworkOperatorDAO();
        IncidenciaDAO incidenciaDAO = new IncidenciaDAO();
        RequestDispatcher view;


        Integer dni = usuarioSesion(request).getDniUsuario();

        switch (action) {


            case "confirmar":

                String[] segmentosMarcados = request.getParameterValues("segmentos");
                String fechaDeteccion = request.getParameter("fecha_deteccion");
                String ahora = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm")
                        .format(new java.util.Date());


                String error = null;

                if (vacio(request.getParameter("titulo"))) {
                    error = "Ingresa el título de la incidencia.";
                } else if (vacio(request.getParameter("descripcion"))) {
                    error = "Ingresa la descripción de la incidencia.";
                } else if (vacio(request.getParameter("severidad"))) {
                    error = "Selecciona la severidad.";
                } else if (vacio(fechaDeteccion) || fechaDeteccion.length() < 16) {
                    error = "Ingresa la fecha y hora de detección.";
                } else if (fechaDeteccion.compareTo(ahora) > 0) {
                    error = "La fecha de detección no puede ser posterior a la fecha actual.";
                } else if (vacio(request.getParameter("id_landing"))) {
                    error = "Selecciona la Landing Station donde se detectó.";
                } else if (segmentosMarcados == null || segmentosMarcados.length == 0) {
                    error = "Marca al menos un segmento afectado.";
                }

                if (error != null) {
                    request.setAttribute("error", error);
                    request.setAttribute("segmentos", dao.listarSegmentosFiltrados(null, null));
                    request.setAttribute("landings", dao.listarLandingStations());

                    view = request.getRequestDispatcher("/networkOperator/RegistrarIncidencia.jsp");
                    view.forward(request, response);
                    break;
                }

                List<Segmento> seleccionados = new ArrayList<>();
                for (String codigoSeg : segmentosMarcados) {
                    Segmento s = dao.obtenerSegmento(codigoSeg);
                    if (s != null) {
                        seleccionados.add(s);
                    }
                }

                request.setAttribute("seleccionados", seleccionados);
                request.setAttribute("landing",
                        dao.obtenerLandingStation(request.getParameter("id_landing")));
                request.setAttribute("serviciosAfectados",
                        incidenciaDAO.contarAfectadosPorSegmentos(segmentosMarcados, "servicios"));
                request.setAttribute("clientesAfectados",
                        incidenciaDAO.contarAfectadosPorSegmentos(segmentosMarcados, "clientes"));

                view = request.getRequestDispatcher("/networkOperator/ConfirmarIncidencia.jsp");
                view.forward(request, response);
                break;


            // "Atrás" en la confirmación: vuelve al formulario con lo ya ingresado (sin JavaScript)
            case "volverFormulario":

                request.setAttribute("segmentos", dao.listarSegmentosFiltrados(null, null));
                request.setAttribute("landings", dao.listarLandingStations());

                view = request.getRequestDispatcher("/networkOperator/RegistrarIncidencia.jsp");
                view.forward(request, response);
                break;


            case "crear":

                String codigoNuevo = incidenciaDAO.crearIncidencia(
                        request.getParameter("titulo"),
                        request.getParameter("descripcion"),
                        request.getParameter("severidad"),
                        request.getParameter("fecha_deteccion"),
                        request.getParameter("id_landing"),
                        request.getParameterValues("segmentos"),
                        request.getParameter("estado_segmento"),
                        dni
                );

                if (codigoNuevo == null) {

                    request.setAttribute("error", "No se pudo registrar la incidencia. "
                            + "Error de la base de datos: " + incidenciaDAO.getUltimoError());
                    request.setAttribute("segmentos", dao.listarSegmentosFiltrados(null, null));
                    request.setAttribute("landings", dao.listarLandingStations());

                    view = request.getRequestDispatcher("/networkOperator/RegistrarIncidencia.jsp");
                    view.forward(request, response);
                } else {
                    mensaje(request, "msg", "registrada");
                    response.sendRedirect(request.getContextPath()
                            + "/NetworkOperatorServlet?action=detalleIncidencia&codigo=" + codigoNuevo);
                }
                break;


            case "actualizar":

                String codigo = request.getParameter("codigo");
                Incidencia actual = incidenciaDAO.obtenerIncidencia(codigo);

                if (vacio(request.getParameter("observacion"))) {
                    mensaje(request, "msg", "faltaObservacion");
                    response.sendRedirect(request.getContextPath()
                            + "/NetworkOperatorServlet?action=detalleIncidencia&codigo="
                            + URLEncoder.encode(codigo == null ? "" : codigo, "UTF-8"));
                    break;
                }

                if (actual != null) {
                    String nuevoEstado = request.getParameter("estado");
                    String siguiente = IncidenciaDAO.siguienteEstado(actual.getEstado());


                    boolean valido = actual.getEstado().equals(nuevoEstado)
                            || (nuevoEstado != null && nuevoEstado.equals(siguiente)
                                && !"Servicio restaurado".equals(siguiente));

                    if (valido && !"Cerrada".equals(actual.getEstado())) {
                        incidenciaDAO.actualizarIncidencia(
                                codigo,
                                nuevoEstado,
                                request.getParameter("severidad"),
                                request.getParameter("observacion"),
                                dni
                        );
                    }
                }

                response.sendRedirect(request.getContextPath()
                        + "/NetworkOperatorServlet?action=detalleIncidencia&codigo="
                        + URLEncoder.encode(codigo == null ? "" : codigo, "UTF-8"));
                break;


            case "restaurar":

                String codigoRest = request.getParameter("codigo");
                String fechaRest = request.getParameter("fecha_restauracion");
                Incidencia incRest = incidenciaDAO.obtenerIncidencia(codigoRest);
                String ultimoCambio = incidenciaDAO.obtenerFechaUltimoCambio(codigoRest);


                boolean fechaValida = fechaRest != null && fechaRest.length() >= 16
                        && (ultimoCambio == null || fechaRest.compareTo(ultimoCambio) >= 0)
                        && fechaRest.compareTo(new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm")
                                .format(new java.util.Date())) <= 0;

                if (vacio(request.getParameter("observacion"))) {
                    mensaje(request, "msg", "faltaObservacion");
                    response.sendRedirect(request.getContextPath()
                            + "/NetworkOperatorServlet?action=detalleIncidencia&codigo="
                            + URLEncoder.encode(codigoRest == null ? "" : codigoRest, "UTF-8"));
                    break;
                }

                if (incRest != null && "En reparación".equals(incRest.getEstado()) && fechaValida) {
                    incidenciaDAO.registrarRestauracion(
                            codigoRest,
                            fechaRest,
                            request.getParameter("estado_segmento"),
                            request.getParameter("observacion"),
                            dni
                    );
                }

                mensaje(request, "msg", fechaValida ? "restaurada" : "fechaInvalida");
                response.sendRedirect(request.getContextPath()
                        + "/NetworkOperatorServlet?action=detalleIncidencia&codigo="
                        + URLEncoder.encode(codigoRest == null ? "" : codigoRest, "UTF-8"));
                break;

            default:
                response.sendRedirect(request.getContextPath()
                        + "/NetworkOperatorServlet?action=vistaGeneral");
        }
    }


    private boolean vacio(String valor) {
        return valor == null || valor.trim().isEmpty();
    }

    /*
     * Enlace a una acción con sus filtros (solo los que tienen valor), listo para agregarle
     * "pagina=N". Se pasa en pares: nombre, valor, nombre, valor...
     */
    private String armarUrl(HttpServletRequest request, String action, String... filtros) throws IOException {
        String url = request.getContextPath() + "/NetworkOperatorServlet?action=" + action + "&";
        for (int i = 0; i + 1 < filtros.length; i += 2) {
            if (!vacio(filtros[i + 1])) {
                url += filtros[i] + "=" + URLEncoder.encode(filtros[i + 1], "UTF-8") + "&";
            }
        }
        return url;
    }


    // Mensaje para la siguiente vista: se guarda en sesión antes del sendRedirect y la vista
    // lo borra después de mostrarlo, así al presionar F5 ya no vuelve a aparecer.
    private void mensaje(HttpServletRequest request, String nombre, String valor) {
        request.getSession().setAttribute(nombre, valor);
    }

    // Lee un mensaje guardado en sesión y lo borra (se muestra una sola vez)
    private String leerMensaje(HttpServletRequest request, String nombre) {
        HttpSession session = request.getSession();
        String valor = (String) session.getAttribute(nombre);
        session.removeAttribute(nombre);
        return valor;
    }

    // Solo entra el usuario con sesión y rol Network Operator
    private Usuario usuarioSesion(HttpServletRequest request) {
        Usuario u = (Usuario) request.getSession().getAttribute("usuarioSesion");
        if (u == null || u.getRol() == null || u.getRol().getIdRol() != ROL_NETWORK_OPERATOR) {
            return null;
        }
        return u;
    }
}
