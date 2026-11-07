package controller;

import beans.Paginacion;
import beans.Ruta;
import beans.Segmento;
import beans.Servicio;
import beans.SolicitudCapacidad;
import beans.Usuario;
import dao.CapacidadDAO;
import dao.SolicitudDAO;

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
        name = "CapacityPlannerServlet",
        value = "/CapacityPlannerServlet",
        loadOnStartup = 2
)
public class CapacityPlannerServlet extends HttpServlet {


    private static final int ROL_CAPACITY_PLANNER = 2;


    @Override
    public void init() throws ServletException {
        new SolicitudDAO().prepararTablas();
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
                ? "capacidad"
                : request.getParameter("action");

        CapacidadDAO capacidadDAO = new CapacidadDAO();
        SolicitudDAO solicitudDAO = new SolicitudDAO();
        RequestDispatcher view;

        switch (action) {


            case "capacidad":

                String buscar = request.getParameter("buscar");
                String estado = request.getParameter("estado");
                String nivel = request.getParameter("nivel");

                Paginacion pagSeg = new Paginacion(request.getParameter("pagina"));
                request.setAttribute("segmentos", capacidadDAO.listarSegmentos(buscar, estado, nivel, false, pagSeg));
                pagSeg.setUrl(armarUrl(request, "capacidad", "buscar", buscar, "estado", estado, "nivel", nivel));
                request.setAttribute("paginacion", pagSeg);
                request.setAttribute("todos", capacidadDAO.listarSegmentos(null, null, null));
                request.setAttribute("buscar", buscar);
                request.setAttribute("estado", estado);
                request.setAttribute("nivel", nivel);

                view = request.getRequestDispatcher("/capacityPlanner/CapacidadSegmentos.jsp");
                view.forward(request, response);
                break;


            case "formRegistrar":

                cargarFormulario(request, capacidadDAO);

                view = request.getRequestDispatcher("/capacityPlanner/RegistrarSolicitud.jsp");
                view.forward(request, response);
                break;


            case "editar":

                SolicitudCapacidad aEditar = solicitudDAO.obtenerSolicitud(entero(request.getParameter("id")));

                if (aEditar == null || !"Registrada".equals(aEditar.getEstado())) {
                    response.sendRedirect(request.getContextPath()
                            + "/CapacityPlannerServlet?action=listarSolicitudes");
                } else {
                    request.setAttribute("solicitud", aEditar);
                    cargarFormulario(request, capacidadDAO);

                    view = request.getRequestDispatcher("/capacityPlanner/RegistrarSolicitud.jsp");
                    view.forward(request, response);
                }
                break;


            case "listarSolicitudes":

                String buscarSol = request.getParameter("buscar");
                String estadoSol = request.getParameter("estado");

                Paginacion pagSol = new Paginacion(request.getParameter("pagina"));
                request.setAttribute("solicitudes", solicitudDAO.listarSolicitudes(buscarSol, estadoSol, pagSol));
                pagSol.setUrl(armarUrl(request, "listarSolicitudes", "buscar", buscarSol, "estado", estadoSol));
                request.setAttribute("paginacion", pagSol);
                request.setAttribute("porEvaluar", solicitudDAO.contarPorEstado("Registrada", "En evaluación"));
                request.setAttribute("pendientes", solicitudDAO.contarPorEstado("Pendiente por capacidad"));
                request.setAttribute("aprobadas", solicitudDAO.contarPorEstado("Aprobada"));
                request.setAttribute("porReservar", solicitudDAO.listarPorReservar().size());
                request.setAttribute("rechazadas", solicitudDAO.contarPorEstado("Rechazada"));
                request.setAttribute("buscar", buscarSol);
                request.setAttribute("estado", estadoSol);
                request.setAttribute("msg", leerMensaje(request, "msg"));

                view = request.getRequestDispatcher("/capacityPlanner/EvaluarSolicitudes.jsp");
                view.forward(request, response);
                break;


            case "detalleSolicitud":

                SolicitudCapacidad solicitud = solicitudDAO.obtenerSolicitud(entero(request.getParameter("id")));

                if (solicitud == null) {
                    response.sendRedirect(request.getContextPath()
                            + "/CapacityPlannerServlet?action=listarSolicitudes");
                } else {
                    request.setAttribute("solicitud", solicitud);
                    request.setAttribute("ruta", capacidadDAO.obtenerRuta(solicitud.getIdRuta()));
                    request.setAttribute("historial", solicitudDAO.listarHistorial(solicitud.getIdSolicitud()));
                    request.setAttribute("msg", leerMensaje(request, "msg"));
                    request.setAttribute("error", leerMensaje(request, "error"));

                    view = request.getRequestDispatcher("/capacityPlanner/DetalleSolicitud.jsp");
                    view.forward(request, response);
                }
                break;


            case "formReservar":

                List<SolicitudCapacidad> porReservar = solicitudDAO.listarPorReservar();
                SolicitudCapacidad elegida = null;

                int idElegida = entero(request.getParameter("id"));
                for (SolicitudCapacidad s : porReservar) {
                    if (s.getIdSolicitud() == idElegida) {
                        elegida = s;
                    }
                }
                if (elegida == null && !porReservar.isEmpty()) {
                    elegida = porReservar.get(0);
                }

                request.setAttribute("porReservar", porReservar);
                request.setAttribute("solicitud", elegida);
                request.setAttribute("ruta", elegida == null ? null : capacidadDAO.obtenerRuta(elegida.getIdRuta()));
                request.setAttribute("error", leerMensaje(request, "error"));

                view = request.getRequestDispatcher("/capacityPlanner/ReservarCapacidad.jsp");
                view.forward(request, response);
                break;


            case "rutas":

                List<Servicio> servicios = capacidadDAO.listarServicios();
                Servicio servicio = null;

                int idServicio = entero(request.getParameter("id_servicio"));
                for (Servicio s : servicios) {
                    if (s.getIdServicio() == idServicio) {
                        servicio = s;
                    }
                }
                if (servicio == null && !servicios.isEmpty()) {
                    servicio = servicios.get(0);
                }

                request.setAttribute("servicios", servicios);
                request.setAttribute("servicio", servicio);
                request.setAttribute("rutaServicio", servicio == null ? null : capacidadDAO.obtenerRuta(servicio.getIdRuta()));
                Paginacion pagRutas = new Paginacion(request.getParameter("pagina"));
                request.setAttribute("rutas", capacidadDAO.listarRutas(pagRutas));
                pagRutas.setUrl(armarUrl(request, "rutas", "id_servicio",
                        servicio == null ? null : String.valueOf(servicio.getIdServicio())));
                request.setAttribute("paginacion", pagRutas);
                request.setAttribute("segmentos", capacidadDAO.listarSegmentos(null, null, null));
                request.setAttribute("msg", leerMensaje(request, "msg"));
                request.setAttribute("error", leerMensaje(request, "error"));

                view = request.getRequestDispatcher("/capacityPlanner/RutasServicios.jsp");
                view.forward(request, response);
                break;


            case "saturacion":

                String nivelSat = request.getParameter("nivel");
                List<Segmento> todos = capacidadDAO.listarSegmentos(null, null, null);

                int normales = 0;
                int altas = 0;
                int criticas = 0;
                for (Segmento s : todos) {
                    if ("Crítica".equals(s.getNivelUso())) criticas++;
                    else if ("Alta".equals(s.getNivelUso())) altas++;
                    else normales++;
                }

                Paginacion pagSat = new Paginacion(request.getParameter("pagina"));
                request.setAttribute("segmentos", capacidadDAO.listarPorOcupacion(nivelSat, pagSat));
                pagSat.setUrl(armarUrl(request, "saturacion", "nivel", nivelSat));
                request.setAttribute("paginacion", pagSat);
                request.setAttribute("tendencias", capacidadDAO.obtenerTendencias());
                request.setAttribute("normales", normales);
                request.setAttribute("altas", altas);
                request.setAttribute("criticas", criticas);
                request.setAttribute("nivel", nivelSat);

                view = request.getRequestDispatcher("/capacityPlanner/SegmentosSaturacion.jsp");
                view.forward(request, response);
                break;


            case "historial":

                List<Segmento> segmentos = capacidadDAO.listarSegmentos(null, null, null);
                String codigo = request.getParameter("segmento");
                Segmento segmento = codigo == null ? null : capacidadDAO.obtenerSegmento(codigo);

                if (segmento == null && !segmentos.isEmpty()) {
                    segmento = segmentos.get(0);
                }

                String desde = request.getParameter("desde");
                String hasta = request.getParameter("hasta");

                List<beans.UtilizacionHist> registros = segmento == null ? new ArrayList<>()
                        : capacidadDAO.listarHistorial(segmento.getCodigoSegmento(), desde, hasta);

                // Los indicadores de la página usan todos los registros del periodo,
                // por eso aquí la tabla se pagina sobre la lista ya cargada
                Paginacion pagHist = new Paginacion(request.getParameter("pagina"));
                pagHist.setTotalRegistros(registros.size());
                pagHist.setUrl(armarUrl(request, "historial",
                        "segmento", segmento == null ? null : segmento.getCodigoSegmento(),
                        "desde", desde, "hasta", hasta));

                request.setAttribute("segmentos", segmentos);
                request.setAttribute("segmento", segmento);
                request.setAttribute("registros", registros);
                request.setAttribute("paginacion", pagHist);
                request.setAttribute("desde", desde);
                request.setAttribute("hasta", hasta);

                view = request.getRequestDispatcher("/capacityPlanner/HistorialUtilizacion.jsp");
                view.forward(request, response);
                break;


            case "borrar":

                boolean borrada = solicitudDAO.borrarSolicitud(entero(request.getParameter("id")));

                mensaje(request, "msg", borrada ? "borrada" : "noBorrada");
                response.sendRedirect(request.getContextPath()
                        + "/CapacityPlannerServlet?action=listarSolicitudes");
                break;


            case "borrarRuta":

                // Se elimina con el formulario (POST) de la ventana de confirmación
                response.sendRedirect(request.getContextPath() + "/CapacityPlannerServlet?action=rutas");
                break;

            default:
                response.sendRedirect(request.getContextPath()
                        + "/CapacityPlannerServlet?action=capacidad");
        }
    }


    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Usuario usuarioSesion = usuarioSesion(request);
        if (usuarioSesion == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }
        Integer dni = usuarioSesion.getDniUsuario();

        String action = request.getParameter("action") == null
                ? ""
                : request.getParameter("action");

        CapacidadDAO capacidadDAO = new CapacidadDAO();
        SolicitudDAO solicitudDAO = new SolicitudDAO();
        RequestDispatcher view;

        int id = entero(request.getParameter("id"));
        String detalle = request.getContextPath() + "/CapacityPlannerServlet?action=detalleSolicitud&id=" + id;

        switch (action) {


            case "calcular":
            case "crear":
            case "actualizar":

                String error = validarSolicitud(request);

                if (error != null || "calcular".equals(action)) {
                    request.setAttribute("error", error);
                    if (error == null) {
                        request.setAttribute("rutaCalculada", capacidadDAO.calcularRuta(
                                request.getParameter("id_origen"), request.getParameter("id_destino")));
                        request.setAttribute("calculada", true);
                    }
                    if (id > 0) {
                        request.setAttribute("solicitud", solicitudDAO.obtenerSolicitud(id));
                    }
                    request.setAttribute("valores", request.getParameterMap());
                    cargarFormulario(request, capacidadDAO);

                    view = request.getRequestDispatcher("/capacityPlanner/RegistrarSolicitud.jsp");
                    view.forward(request, response);
                    break;
                }

                int idCliente = entero(request.getParameter("id_cliente"));
                String origen = request.getParameter("id_origen");
                String destino = request.getParameter("id_destino");
                double capacidad = Double.parseDouble(request.getParameter("capacidad_requerida"));
                String fechaRequerida = request.getParameter("fecha_requerida");
                String observaciones = request.getParameter("observaciones");

                if ("crear".equals(action)) {

                    Integer idNuevo = solicitudDAO.crearSolicitud(idCliente, origen, destino,
                            capacidad, fechaRequerida, observaciones, dni);

                    if (idNuevo == null) {
                        request.setAttribute("error", "No se pudo registrar la solicitud. "
                                + "Error de la base de datos: " + solicitudDAO.getUltimoError());
                        request.setAttribute("valores", request.getParameterMap());
                        cargarFormulario(request, capacidadDAO);

                        view = request.getRequestDispatcher("/capacityPlanner/RegistrarSolicitud.jsp");
                        view.forward(request, response);
                    } else {
                        mensaje(request, "msg", "registrada");
                        response.sendRedirect(request.getContextPath()
                                + "/CapacityPlannerServlet?action=detalleSolicitud&id=" + idNuevo);
                    }

                } else {

                    boolean ok = solicitudDAO.actualizarSolicitud(id, idCliente, origen, destino,
                            capacidad, fechaRequerida, observaciones);

                    if (ok) {
                        mensaje(request, "msg", "actualizada");
                    } else {
                        mensaje(request, "error", "Solo se puede editar una solicitud Registrada.");
                    }
                    response.sendRedirect(detalle);
                }
                break;

            case "evaluar":

                SolicitudCapacidad aEvaluar = solicitudDAO.obtenerSolicitud(id);

                if (aEvaluar != null && ("Registrada".equals(aEvaluar.getEstado())
                        || "En evaluación".equals(aEvaluar.getEstado())
                        || "Pendiente por capacidad".equals(aEvaluar.getEstado()))) {

                    Ruta ruta = capacidadDAO.calcularRuta(aEvaluar.getIdOrigen(), aEvaluar.getIdDestino());

                    // Ruta nueva armada con los segmentos (id 0): primero se registra en RUTA
                    if (ruta != null && ruta.getIdRuta() == 0) {
                        List<String> codigos = new ArrayList<>();
                        for (Segmento s : ruta.getSegmentos()) {
                            codigos.add(s.getCodigoSegmento());
                        }
                        ruta = capacidadDAO.crearRuta(ruta.getCodigo(), codigos) == null
                                ? capacidadDAO.calcularRuta(aEvaluar.getIdOrigen(), aEvaluar.getIdDestino())
                                : null;
                    }

                    solicitudDAO.iniciarEvaluacion(id, ruta, dni);
                }

                response.sendRedirect(detalle);
                break;


            case "aprobar":

                SolicitudCapacidad aAprobar = solicitudDAO.obtenerSolicitud(id);
                Ruta rutaAprobar = aAprobar == null ? null : capacidadDAO.obtenerRuta(aAprobar.getIdRuta());

                if (aAprobar == null || !"En evaluación".equals(aAprobar.getEstado())) {
                    response.sendRedirect(detalle);
                } else if (rutaAprobar == null || rutaAprobar.isTieneSegmentoFueraServicio()
                        || rutaAprobar.getCapacidadDisponible() < aAprobar.getCapacidadRequerida()) {
                    mensaje(request, "error", "La ruta no tiene capacidad suficiente: no se puede aprobar.");
                    response.sendRedirect(detalle);
                } else {
                    solicitudDAO.registrarDecision(id, "Aprobada", vacio(request.getParameter("observacion"))
                            ? "Solicitud aprobada." : request.getParameter("observacion"), dni);
                    mensaje(request, "msg", "aprobada");
                    response.sendRedirect(detalle);
                }
                break;


            case "pendiente":

                SolicitudCapacidad aPendiente = solicitudDAO.obtenerSolicitud(id);

                if (aPendiente != null && ("En evaluación".equals(aPendiente.getEstado())
                        || ("Aprobada".equals(aPendiente.getEstado()) && !aPendiente.isReservada()))) {
                    solicitudDAO.registrarDecision(id, "Pendiente por capacidad",
                            vacio(request.getParameter("observacion"))
                                    ? "Espera capacidad disponible en la ruta."
                                    : request.getParameter("observacion"), dni);
                }

                response.sendRedirect(detalle);
                break;


            case "rechazar":

                SolicitudCapacidad aRechazar = solicitudDAO.obtenerSolicitud(id);

                if (vacio(request.getParameter("observacion"))) {
                    mensaje(request, "error", "Ingresa el motivo del rechazo.");
                    response.sendRedirect(detalle);
                    break;
                }

                if (aRechazar != null && ("Registrada".equals(aRechazar.getEstado())
                        || "En evaluación".equals(aRechazar.getEstado())
                        || "Pendiente por capacidad".equals(aRechazar.getEstado())
                        || ("Aprobada".equals(aRechazar.getEstado()) && !aRechazar.isReservada()))) {
                    solicitudDAO.registrarDecision(id, "Rechazada", request.getParameter("observacion"), dni);
                }

                response.sendRedirect(detalle);
                break;


            case "reservar":

                String errorReserva = solicitudDAO.reservarCapacidad(id, dni);

                if (errorReserva == null) {
                    mensaje(request, "msg", "reservada");
                    response.sendRedirect(detalle);
                } else {
                    mensaje(request, "error", errorReserva);
                    response.sendRedirect(request.getContextPath()
                            + "/CapacityPlannerServlet?action=formReservar&id=" + id);
                }
                break;


            case "provisionar":

                String errorProvision = solicitudDAO.provisionar(id, dni);

                if (errorProvision == null) {
                    mensaje(request, "msg", "provisionada");
                } else {
                    mensaje(request, "error", errorProvision);
                }
                response.sendRedirect(detalle);
                break;

            case "activar":

                SolicitudCapacidad aActivar = solicitudDAO.obtenerSolicitud(id);
                String errorActivar = solicitudDAO.activar(id,
                        aActivar == null ? null : capacidadDAO.obtenerRuta(aActivar.getIdRuta()), dni);

                if (errorActivar == null) {
                    mensaje(request, "msg", "activada");
                } else {
                    mensaje(request, "error", errorActivar);
                }
                response.sendRedirect(detalle);
                break;


            case "crearRuta":

                String codigoRuta = request.getParameter("codigo") == null
                        ? "" : request.getParameter("codigo").trim().toUpperCase();

                List<Segmento> elegidos = new ArrayList<>();
                List<String> codigos = new ArrayList<>();
                for (int i = 1; i <= 4; i++) {
                    String c = request.getParameter("segmento" + i);
                    if (!vacio(c)) {
                        Segmento s = capacidadDAO.obtenerSegmento(c);
                        if (s != null) {
                            elegidos.add(s);
                            codigos.add(s.getCodigoSegmento());
                        }
                    }
                }

                String errorRuta = null;

                if (codigoRuta.isEmpty() || codigoRuta.length() > 20) {
                    errorRuta = "Ingresa un código de ruta de hasta 20 caracteres (ej. RUTA-LIM-HER-02).";
                } else if (elegidos.isEmpty()) {
                    errorRuta = "Elige al menos un segmento.";
                } else {
                    for (int i = 0; i < elegidos.size() && errorRuta == null; i++) {
                        if (codigos.indexOf(codigos.get(i)) != i) {
                            errorRuta = "El segmento " + codigos.get(i) + " está repetido.";
                        } else if (i > 0 && !elegidos.get(i - 1).getIdDestino().equals(elegidos.get(i).getIdOrigen())) {
                            errorRuta = elegidos.get(i).getCodigoSegmento() + " no empieza donde termina "
                                    + elegidos.get(i - 1).getCodigoSegmento() + ".";
                        }
                    }
                    if (errorRuta == null && elegidos.get(0).getIdOrigen()
                            .equals(elegidos.get(elegidos.size() - 1).getIdDestino())) {
                        errorRuta = "La ruta no puede terminar en la misma estación donde empieza.";
                    }
                }

                if (errorRuta == null) {
                    errorRuta = capacidadDAO.crearRuta(codigoRuta, codigos);
                }

                if (errorRuta == null) {
                    mensaje(request, "msg", "rutaCreada");
                } else {
                    mensaje(request, "error", errorRuta);
                }
                response.sendRedirect(request.getContextPath() + "/CapacityPlannerServlet?action=rutas");
                break;


            case "borrarRuta":

                boolean borrada = capacidadDAO.borrarRuta(id);

                if (borrada) {
                    mensaje(request, "msg", "rutaBorrada");
                } else {
                    mensaje(request, "error", "No se pudo eliminar la ruta. "
                            + (capacidadDAO.getUltimoError() == null ? "" : capacidadDAO.getUltimoError()));
                }
                response.sendRedirect(request.getContextPath() + "/CapacityPlannerServlet?action=rutas");
                break;

            case "estadoRuta":

                String nuevoEstado = "Inactiva".equals(request.getParameter("estado")) ? "Inactiva" : "Activa";
                capacidadDAO.cambiarEstadoRuta(id, nuevoEstado);

                mensaje(request, "msg", "rutaActualizada");
                response.sendRedirect(request.getContextPath() + "/CapacityPlannerServlet?action=rutas");
                break;

            default:
                response.sendRedirect(request.getContextPath()
                        + "/CapacityPlannerServlet?action=capacidad");
        }
    }



    private Usuario usuarioSesion(HttpServletRequest request) {
        Usuario u = (Usuario) request.getSession().getAttribute("usuarioSesion");
        if (u == null || u.getRol() == null || u.getRol().getIdRol() != ROL_CAPACITY_PLANNER) {
            return null;
        }
        return u;
    }


    private void cargarFormulario(HttpServletRequest request, CapacidadDAO capacidadDAO) {
        request.setAttribute("clientes", capacidadDAO.listarClientes());
        request.setAttribute("landings", capacidadDAO.listarLandingStations());
        request.setAttribute("hoy", java.time.LocalDate.now().toString());
    }


    private String validarSolicitud(HttpServletRequest request) {

        String origen = request.getParameter("id_origen");
        String destino = request.getParameter("id_destino");
        String capacidad = request.getParameter("capacidad_requerida");
        String fecha = request.getParameter("fecha_requerida");
        String observaciones = request.getParameter("observaciones");

        if (entero(request.getParameter("id_cliente")) <= 0) {
            return "Selecciona el cliente.";
        }
        if (vacio(origen) || vacio(destino)) {
            return "Selecciona la Landing Station de origen y la de destino.";
        }
        if (origen.equals(destino)) {
            return "El origen y el destino deben ser estaciones distintas.";
        }
        double valor;
        try {
            valor = Double.parseDouble(capacidad);
        } catch (NumberFormatException | NullPointerException e) {
            return "Ingresa la capacidad requerida en Gbps.";
        }
        if (valor <= 0 || valor > 99999999) {
            return "La capacidad requerida debe ser mayor que 0.";
        }
        if (vacio(fecha) || !fecha.matches("\\d{4}-\\d{2}-\\d{2}")) {
            return "Ingresa la fecha requerida.";
        }
        if (fecha.compareTo(java.time.LocalDate.now().toString()) < 0) {
            return "La fecha requerida no puede ser anterior a hoy.";
        }
        if (observaciones != null && observaciones.length() > 255) {
            return "Las observaciones pueden tener como máximo 255 caracteres.";
        }
        return null;
    }

    private boolean vacio(String valor) {
        return valor == null || valor.trim().isEmpty();
    }


    private int entero(String valor) {
        try {
            return Integer.parseInt(valor.trim());
        } catch (NumberFormatException | NullPointerException e) {
            return 0;
        }
    }

    private String url(String valor) throws IOException {
        return URLEncoder.encode(valor, "UTF-8");
    }



    // Enlace a una acción con sus filtros (solo los que tienen valor)
    private String armarUrl(HttpServletRequest request, String action, String... filtros) throws IOException {
        String enlace = request.getContextPath() + "/CapacityPlannerServlet?action=" + action + "&";
        for (int i = 0; i + 1 < filtros.length; i += 2) {
            if (!vacio(filtros[i + 1])) {
                enlace += filtros[i] + "=" + url(filtros[i + 1]) + "&";
            }
        }
        return enlace;
    }


    // Mensaje para la siguiente vista
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
}
