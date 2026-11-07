package controller;

import beans.LandingStation;
import beans.Mantenimiento;
import beans.Paginacion;
import beans.Segmento;
import beans.ServicioAfectado;
import beans.Usuario;
import dao.MantenimientoDAO;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Arrays;
import java.util.List;


@WebServlet(name = "MantenimientoServlet", value = "/MantenimientoServlet", loadOnStartup = 1)
public class MantenimientoServlet extends HttpServlet {

    private static final int ROL_MAINTENANCE_COORDINATOR = 4;

    private static final List<String> TIPOS = Arrays.asList("Preventivo", "Correctivo");
    private static final List<String> RESULTADOS = Arrays.asList("Exitoso", "Parcial", "Fallido");
    private static final List<String> ESTADOS_SEGMENTO = Arrays.asList("Operativo", "Degradado", "Fuera de servicio");

    private static final int DURACION_MAXIMA = 240;   // horas


    @Override
    public void init() throws ServletException {
        new MantenimientoDAO().prepararTablas();
    }


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (usuarioSesion(request) == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        String action = request.getParameter("action") == null ? "listar" : request.getParameter("action");

        MantenimientoDAO dao = new MantenimientoDAO();
        HttpSession session = request.getSession();
        RequestDispatcher view;

        switch (action) {

            // LISTADO CON FILTROS Y PAGINACIÓN
            case "listar": {

                String estado = request.getParameter("estado");
                String tipo = request.getParameter("tipo");
                String buscar = request.getParameter("buscar");
                String desde = request.getParameter("desde");
                String hasta = request.getParameter("hasta");

                Paginacion pag = new Paginacion(request.getParameter("pagina"));
                pag.setUrl(armarUrl(request, "listar", "estado", estado, "tipo", tipo, "buscar", buscar,
                        "desde", desde, "hasta", hasta));

                request.setAttribute("mantenimientos", dao.listarMantenimientos(estado, tipo, buscar, desde, hasta, pag));
                request.setAttribute("paginacion", pag);
                request.setAttribute("porEstado", dao.contarPorEstado());
                request.setAttribute("estado", estado);
                request.setAttribute("tipo", tipo);
                request.setAttribute("buscar", buscar);
                request.setAttribute("desde", desde);
                request.setAttribute("hasta", hasta);

                view = request.getRequestDispatcher("/maintenanceCoordinator/mantenimientos.jsp");
                view.forward(request, response);
                break;
            }

            // DETALLE: datos, infraestructura, servicios, actividades e historial
            case "detalle": {

                if (!cargarDetalle(request, dao, request.getParameter("codigo"))) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                    return;
                }

                view = request.getRequestDispatcher("/maintenanceCoordinator/detalleMantenimiento.jsp");
                view.forward(request, response);
                break;
            }

            // NUEVO MANTENIMIENTO: empieza desde cero
            case "formCrear": {

                limpiarRegistro(session);
                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=paso1");
                break;
            }

            // PASO 1: DATOS GENERALES (vuelve con lo que ya se ingresó)
            case "paso1": {

                session.setAttribute("mantPasoActual", "paso1");

                view = request.getRequestDispatcher("/maintenanceCoordinator/nuevoMantenimientoPaso1.jsp");
                view.forward(request, response);
                break;
            }

            // PASO 2: INFRAESTRUCTURA (landing stations y segmentos de la BD)
            case "paso2": {

                if (session.getAttribute("mantTipo") == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=paso1");
                    return;
                }

                session.setAttribute("mantPasoActual", "paso2");
                cargarInfraestructura(request, dao);

                view = request.getRequestDispatcher("/maintenanceCoordinator/nuevoMantenimientoPaso2.jsp");
                view.forward(request, response);
                break;
            }

            // PASO 3: IMPACTO EN SERVICIOS
            case "paso3": {

                if (!hayInfraestructura(session)) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=paso2");
                    return;
                }

                session.setAttribute("mantPasoActual", "paso3");

                String[] estaciones = (String[]) session.getAttribute("mantEstaciones");
                String[] segmentos = (String[]) session.getAttribute("mantSegmentos");

                request.setAttribute("servicios", dao.listarServiciosAfectados(estaciones, segmentos));

                view = request.getRequestDispatcher("/maintenanceCoordinator/nuevoMantenimientoPaso3.jsp");
                view.forward(request, response);
                break;
            }

            // PASO 4: PROGRAMACIÓN
            case "paso4": {

                if (!hayInfraestructura(session)) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=paso2");
                    return;
                }

                session.setAttribute("mantPasoActual", "paso4");
                request.setAttribute("hoy", LocalDate.now().toString());

                view = request.getRequestDispatcher("/maintenanceCoordinator/nuevoMantenimientoPaso4.jsp");
                view.forward(request, response);
                break;
            }

            // MANTENIMIENTO REGISTRADO
            case "exito": {

                String codigo = (String) session.getAttribute("mantCodigoRegistrado");
                Mantenimiento registrado = dao.obtenerMantenimiento(codigo);

                if (registrado == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                    return;
                }

                request.setAttribute("mantenimiento", registrado);
                request.setAttribute("servicios", dao.listarServiciosAfectados(codigo).size());

                view = request.getRequestDispatcher("/maintenanceCoordinator/nuevoMantenimientoExito.jsp");
                view.forward(request, response);
                break;
            }

            // CONFIRMAR SI SE ABANDONA EL REGISTRO
            case "cancelarRegistro": {

                view = request.getRequestDispatcher("/maintenanceCoordinator/cancelarMantenimiento.jsp");
                view.forward(request, response);
                break;
            }

            // SEGUIR CON EL REGISTRO EN EL PASO DONDE SE QUEDÓ
            case "continuar": {

                String paso = (String) session.getAttribute("mantPasoActual");
                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action="
                        + (paso == null ? "paso1" : paso));
                break;
            }

            // EDITAR PROGRAMACIÓN (solo Programado)
            case "editar": {

                Mantenimiento m = dao.obtenerMantenimiento(request.getParameter("codigo"));

                if (m == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                    return;
                }
                if (!m.isProgramado()) {
                    redirigirDetalle(request, response, m.getCodigoMantenimiento(), "noEditable");
                    return;
                }

                request.setAttribute("mantenimiento", m);
                request.setAttribute("hoy", LocalDate.now().toString());

                view = request.getRequestDispatcher("/maintenanceCoordinator/editarMantenimiento.jsp");
                view.forward(request, response);
                break;
            }

            // FORMULARIO DE CIERRE (solo En ejecución)
            case "finalizar": {

                String codigo = request.getParameter("codigo");
                Mantenimiento m = dao.obtenerMantenimiento(codigo);

                if (m == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                    return;
                }
                if (!m.isEnEjecucion()) {
                    redirigirDetalle(request, response, codigo, "noFinalizable");
                    return;
                }

                request.setAttribute("mantenimiento", m);
                request.setAttribute("segmentos", dao.listarSegmentos(codigo));
                request.setAttribute("actividades", dao.listarActividades(codigo));

                view = request.getRequestDispatcher("/maintenanceCoordinator/finalizarMantenimiento.jsp");
                view.forward(request, response);
                break;
            }

            default:
                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
        }
    }


    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Usuario usuario = usuarioSesion(request);
        if (usuario == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }
        Integer dni = usuario.getDniUsuario();

        String action = request.getParameter("action") == null ? "" : request.getParameter("action");

        MantenimientoDAO dao = new MantenimientoDAO();
        HttpSession session = request.getSession();
        RequestDispatcher view;

        switch (action) {

            // GUARDAR PASO 1: DATOS GENERALES
            case "guardarPaso1": {

                String tipo = request.getParameter("tipo");
                String titulo = request.getParameter("titulo");
                String descripcion = request.getParameter("descripcion");

                // se guarda lo ingresado para no perderlo si hay un error
                session.setAttribute("mantTitulo", titulo);
                session.setAttribute("mantDescripcion", descripcion);

                String error = validarDatosGenerales(tipo, titulo, descripcion);

                if (error != null) {
                    request.setAttribute("error", error);
                    request.setAttribute("tipoElegido", tipo);
                    view = request.getRequestDispatcher("/maintenanceCoordinator/nuevoMantenimientoPaso1.jsp");
                    view.forward(request, response);
                    return;
                }

                session.setAttribute("mantTipo", tipo);
                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=paso2");
                break;
            }

            // GUARDAR PASO 2: INFRAESTRUCTURA
            case "guardarPaso2": {

                if (session.getAttribute("mantTipo") == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=paso1");
                    return;
                }

                String[] estaciones = request.getParameterValues("landingStations");
                String[] segmentos = request.getParameterValues("segmentos");

                session.setAttribute("mantEstaciones", estaciones);
                session.setAttribute("mantSegmentos", segmentos);

                String error = null;
                if ((estaciones == null || estaciones.length == 0) && (segmentos == null || segmentos.length == 0)) {
                    error = "Selecciona al menos una Landing Station o un segmento.";
                } else {
                    List<String> ocupados = dao.elementosOcupados(estaciones, segmentos);
                    if (!ocupados.isEmpty()) {
                        error = "Estos elementos ya tienen un mantenimiento pendiente: "
                                + String.join(", ", ocupados) + ".";
                    }
                }

                if (error != null) {
                    request.setAttribute("error", error);
                    cargarInfraestructura(request, dao);
                    view = request.getRequestDispatcher("/maintenanceCoordinator/nuevoMantenimientoPaso2.jsp");
                    view.forward(request, response);
                    return;
                }

                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=paso3");
                break;
            }

            // CONTINUAR DESDE EL PASO 3
            case "continuarPaso3": {

                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action="
                        + (hayInfraestructura(session) ? "paso4" : "paso2"));
                break;
            }

            // REGISTRAR EL MANTENIMIENTO
            case "crear": {

                if (!hayInfraestructura(session)) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=paso1");
                    return;
                }

                String fecha = request.getParameter("fechaInicio");
                String hora = request.getParameter("horaInicio");
                String duracion = request.getParameter("duracion");

                session.setAttribute("mantFecha", fecha);
                session.setAttribute("mantHora", hora);
                session.setAttribute("mantDuracion", duracion);

                String[] estaciones = (String[]) session.getAttribute("mantEstaciones");
                String[] segmentos = (String[]) session.getAttribute("mantSegmentos");

                String error = validarProgramacion(fecha, hora, duracion);
                if (error == null) {
                    // otro usuario pudo asignarlos mientras se completaban los pasos
                    List<String> ocupados = dao.elementosOcupados(estaciones, segmentos);
                    if (!ocupados.isEmpty()) {
                        error = "Estos elementos ya tienen un mantenimiento pendiente: "
                                + String.join(", ", ocupados) + ". Vuelve al paso 2 y cámbialos.";
                    }
                }

                String codigo = null;
                if (error == null) {
                    codigo = dao.crearMantenimiento(
                            (String) session.getAttribute("mantTipo"),
                            (String) session.getAttribute("mantTitulo"),
                            (String) session.getAttribute("mantDescripcion"),
                            fecha, hora, Integer.parseInt(duracion.trim()),
                            estaciones, segmentos, dni);
                    if (codigo == null) {
                        error = "No se pudo registrar el mantenimiento. Error de la base de datos: "
                                + dao.getUltimoError();
                    }
                }

                if (error != null) {
                    request.setAttribute("error", error);
                    request.setAttribute("hoy", LocalDate.now().toString());
                    view = request.getRequestDispatcher("/maintenanceCoordinator/nuevoMantenimientoPaso4.jsp");
                    view.forward(request, response);
                    return;
                }

                limpiarRegistro(session);
                session.setAttribute("mantCodigoRegistrado", codigo);
                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=exito");
                break;
            }

            // ABANDONAR EL REGISTRO
            case "confirmarCancelarRegistro": {

                limpiarRegistro(session);
                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                break;
            }

            // GUARDAR LA EDICIÓN (solo Programado)
            case "actualizar": {

                String codigo = request.getParameter("codigo");
                Mantenimiento m = dao.obtenerMantenimiento(codigo);

                if (m == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                    return;
                }
                if (!m.isProgramado()) {
                    redirigirDetalle(request, response, codigo, "noEditable");
                    return;
                }

                String tipo = request.getParameter("tipo");
                String titulo = request.getParameter("titulo");
                String descripcion = request.getParameter("descripcion");
                String fecha = request.getParameter("fechaInicio");
                String hora = request.getParameter("horaInicio");
                String duracion = request.getParameter("duracion");

                String error = validarDatosGenerales(tipo, titulo, descripcion);
                if (error == null) {
                    error = validarProgramacion(fecha, hora, duracion);
                }
                if (error == null && !dao.actualizarMantenimiento(codigo, tipo, titulo, descripcion, fecha, hora,
                        Integer.parseInt(duracion.trim()), dni)) {
                    error = "No se pudo guardar. Error de la base de datos: " + dao.getUltimoError();
                }

                if (error != null) {
                    // se vuelve al formulario con lo que escribió el usuario
                    m.setTipo(tipo);
                    m.setActividad(titulo);
                    m.setDescripcion(descripcion);
                    m.setFechaProgramada(fecha);
                    m.setHoraInicio(hora);
                    request.setAttribute("duracionElegida", duracion);
                    request.setAttribute("mantenimiento", m);
                    request.setAttribute("error", error);
                    request.setAttribute("hoy", LocalDate.now().toString());
                    view = request.getRequestDispatcher("/maintenanceCoordinator/editarMantenimiento.jsp");
                    view.forward(request, response);
                    return;
                }

                redirigirDetalle(request, response, codigo, "actualizado");
                break;
            }

            // PROGRAMADO -> EN EJECUCIÓN
            case "iniciar": {

                String codigo = request.getParameter("codigo");
                Mantenimiento m = dao.obtenerMantenimiento(codigo);

                if (m == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                    return;
                }

                String msg;
                if (!m.isProgramado()) {
                    msg = "noIniciable";
                } else if (m.getFechaProgramada().compareTo(LocalDate.now().toString()) > 0) {
                    msg = "antesDeFecha";
                } else {
                    msg = dao.iniciarMantenimiento(codigo, request.getParameter("observacion"), dni)
                            ? "iniciado" : "errorBD";
                }

                redirigirDetalle(request, response, codigo, msg);
                break;
            }

            // REGISTRAR UNA ACTIVIDAD (solo En ejecución)
            case "registrarActividad": {

                String codigo = request.getParameter("codigo");
                Mantenimiento m = dao.obtenerMantenimiento(codigo);

                if (m == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                    return;
                }

                String titulo = request.getParameter("titulo");
                String descripcion = request.getParameter("descripcion");
                String fecha = request.getParameter("fecha");
                String hora = request.getParameter("hora");
                int horas = numero(request.getParameter("horas"));
                int minutos = numero(request.getParameter("minutos"));
                String hoy = LocalDate.now().toString();

                String error = null;
                if (!m.isEnEjecucion()) {
                    error = "Solo se registran actividades mientras el mantenimiento está En ejecución.";
                } else if (vacio(titulo)) {
                    error = "Ingresa el título de la actividad.";
                } else if (titulo.trim().length() > 100) {
                    error = "El título no puede tener más de 100 caracteres.";
                } else if (vacio(descripcion)) {
                    error = "Ingresa la descripción de la actividad.";
                } else if (descripcion.trim().length() > 500) {
                    error = "La descripción no puede tener más de 500 caracteres.";
                } else if (!esFecha(fecha)) {
                    error = "Ingresa la fecha de la actividad.";
                } else if (fecha.compareTo(m.getFechaProgramada()) < 0) {
                    error = "La fecha no puede ser anterior al inicio programado (" + m.getFechaProgramada() + ").";
                } else if (fecha.compareTo(hoy) > 0) {
                    error = "La fecha de la actividad no puede ser posterior a hoy.";
                } else if (!esHora(hora)) {
                    error = "Ingresa la hora de la actividad.";
                } else if (horas < 0 || horas > 99 || minutos < 0 || minutos > 59 || (horas == 0 && minutos == 0)) {
                    error = "Ingresa el tiempo invertido (entre 1 minuto y 99 horas).";
                }

                if (error == null && !dao.registrarActividad(codigo, titulo, descripcion, fecha, hora, horas, minutos)) {
                    error = "No se pudo registrar la actividad. Error de la base de datos: " + dao.getUltimoError();
                }

                if (error != null) {
                    cargarDetalle(request, dao, codigo);
                    request.setAttribute("errorActividad", error);
                    view = request.getRequestDispatcher("/maintenanceCoordinator/detalleMantenimiento.jsp");
                    view.forward(request, response);
                    return;
                }

                redirigirDetalle(request, response, codigo, "actividad");
                break;
            }

            // BORRAR UNA ACTIVIDAD REGISTRADA POR ERROR
            case "borrarActividad": {

                String codigo = request.getParameter("codigo");
                boolean borrada = dao.borrarActividad(numero(request.getParameter("idActividad")), codigo);
                redirigirDetalle(request, response, codigo, borrada ? "actividadBorrada" : "noBorrada");
                break;
            }

            // EN EJECUCIÓN -> FINALIZADO
            case "finalizar": {

                String codigo = request.getParameter("codigo");
                Mantenimiento m = dao.obtenerMantenimiento(codigo);

                if (m == null) {
                    response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
                    return;
                }
                if (!m.isEnEjecucion()) {
                    redirigirDetalle(request, response, codigo, "noFinalizable");
                    return;
                }

                String resultado = request.getParameter("resultado");
                String resumen = request.getParameter("resumen");
                String observacion = request.getParameter("observacion");
                String estadoSegmentos = request.getParameter("estadoSegmentos");

                String error = null;
                if (!RESULTADOS.contains(resultado)) {
                    error = "Selecciona el resultado del mantenimiento.";
                } else if (vacio(resumen)) {
                    error = "Ingresa el resumen final.";
                } else if (resumen.trim().length() > 500) {
                    error = "El resumen no puede tener más de 500 caracteres.";
                } else if (observacion != null && observacion.trim().length() > 500) {
                    error = "La observación no puede tener más de 500 caracteres.";
                } else if (!ESTADOS_SEGMENTO.contains(estadoSegmentos)) {
                    error = "Selecciona cómo quedan los segmentos.";
                }

                if (error == null && !dao.finalizarMantenimiento(codigo, resultado, resumen, observacion,
                        estadoSegmentos, dni)) {
                    error = "No se pudo finalizar. Error de la base de datos: " + dao.getUltimoError();
                }

                if (error != null) {
                    request.setAttribute("mantenimiento", m);
                    request.setAttribute("segmentos", dao.listarSegmentos(codigo));
                    request.setAttribute("actividades", dao.listarActividades(codigo));
                    request.setAttribute("error", error);
                    view = request.getRequestDispatcher("/maintenanceCoordinator/finalizarMantenimiento.jsp");
                    view.forward(request, response);
                    return;
                }

                redirigirDetalle(request, response, codigo, "finalizado");
                break;
            }

            // PROGRAMADO -> CANCELADO
            case "cancelarMantenimiento": {

                String codigo = request.getParameter("codigo");
                String motivo = request.getParameter("motivo");

                String msg;
                if (vacio(motivo)) {
                    msg = "faltaMotivo";
                } else if (motivo.trim().length() > 500) {
                    msg = "motivoLargo";
                } else {
                    msg = dao.cancelarMantenimiento(codigo, motivo, dni) ? "cancelado" : "noCancelable";
                }

                redirigirDetalle(request, response, codigo, msg);
                break;
            }

            default:
                response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=listar");
        }
    }


    // =====================================================
    // Métodos de apoyo
    // =====================================================

    // Solo entra el usuario con sesión y rol Maintenance Coordinator
    private Usuario usuarioSesion(HttpServletRequest request) {
        Usuario u = (Usuario) request.getSession().getAttribute("usuarioSesion");
        if (u == null || u.getRol() == null || u.getRol().getIdRol() != ROL_MAINTENANCE_COORDINATOR) {
            return null;
        }
        return u;
    }

    private boolean cargarDetalle(HttpServletRequest request, MantenimientoDAO dao, String codigo) {

        Mantenimiento m = dao.obtenerMantenimiento(codigo);
        if (m == null) {
            return false;
        }

        List<Segmento> segmentos = dao.listarSegmentos(codigo);
        List<LandingStation> landings = dao.listarLandingStations(codigo);
        List<ServicioAfectado> servicios = dao.listarServiciosAfectados(codigo);

        request.setAttribute("mantenimiento", m);
        request.setAttribute("segmentos", segmentos);
        request.setAttribute("landings", landings);
        request.setAttribute("servicios", servicios);
        request.setAttribute("actividades", dao.listarActividades(codigo));
        request.setAttribute("historial", dao.listarHistorial(codigo));
        request.setAttribute("hoy", LocalDate.now().toString());
        return true;
    }

    // Listas del paso 2 y elementos que ya tienen un mantenimiento pendiente
    private void cargarInfraestructura(HttpServletRequest request, MantenimientoDAO dao) {
        request.setAttribute("landingsDisponibles", dao.listarLandingStations(null));
        request.setAttribute("segmentosDisponibles", dao.listarSegmentos(null));
    }

    private boolean hayInfraestructura(HttpSession session) {
        String[] estaciones = (String[]) session.getAttribute("mantEstaciones");
        String[] segmentos = (String[]) session.getAttribute("mantSegmentos");
        return session.getAttribute("mantTipo") != null
                && ((estaciones != null && estaciones.length > 0) || (segmentos != null && segmentos.length > 0));
    }

    private void limpiarRegistro(HttpSession session) {
        String[] atributos = {"mantTipo", "mantTitulo", "mantDescripcion", "mantEstaciones", "mantSegmentos",
                "mantFecha", "mantHora", "mantDuracion", "mantPasoActual"};
        for (String a : atributos) {
            session.removeAttribute(a);
        }
    }

    private String validarDatosGenerales(String tipo, String titulo, String descripcion) {
        if (!TIPOS.contains(tipo)) {
            return "Selecciona el tipo de mantenimiento.";
        }
        if (vacio(titulo)) {
            return "Ingresa el título del mantenimiento.";
        }
        if (titulo.trim().length() > 100) {
            return "El título no puede tener más de 100 caracteres.";
        }
        if (vacio(descripcion)) {
            return "Ingresa la descripción del mantenimiento.";
        }
        if (descripcion.trim().length() > 500) {
            return "La descripción no puede tener más de 500 caracteres.";
        }
        return null;
    }

    private String validarProgramacion(String fecha, String hora, String duracion) {
        String hoy = LocalDate.now().toString();
        if (!esFecha(fecha)) {
            return "Ingresa la fecha de inicio.";
        }
        if (fecha.compareTo(hoy) < 0) {
            return "La fecha de inicio no puede ser anterior a hoy.";
        }
        if (!esHora(hora)) {
            return "Ingresa la hora de inicio.";
        }
        if (fecha.equals(hoy) && hora.compareTo(LocalTime.now().toString().substring(0, 5)) < 0) {
            return "Si el mantenimiento es hoy, la hora de inicio no puede haber pasado.";
        }
        int horas = numero(duracion);
        if (horas < 1 || horas > DURACION_MAXIMA) {
            return "La duración estimada debe estar entre 1 y " + DURACION_MAXIMA + " horas.";
        }
        return null;
    }

    private void redirigirDetalle(HttpServletRequest request, HttpServletResponse response,
                                  String codigo, String msg) throws IOException {
        // El mensaje va en sesión (no en el URL): la vista lo borra después de mostrarlo
        request.getSession().setAttribute("msg", msg);
        response.sendRedirect(request.getContextPath() + "/MantenimientoServlet?action=detalle&codigo="
                + URLEncoder.encode(codigo == null ? "" : codigo, "UTF-8"));
    }

    // Enlace a una acción con sus filtros (solo los que tienen valor), listo para agregarle "pagina=N"
    private String armarUrl(HttpServletRequest request, String action, String... filtros) throws IOException {
        String url = request.getContextPath() + "/MantenimientoServlet?action=" + action + "&";
        for (int i = 0; i + 1 < filtros.length; i += 2) {
            if (!vacio(filtros[i + 1])) {
                url += filtros[i] + "=" + URLEncoder.encode(filtros[i + 1], "UTF-8") + "&";
            }
        }
        return url;
    }

    private int numero(String valor) {
        try {
            return Integer.parseInt(valor.trim());
        } catch (NumberFormatException | NullPointerException e) {
            return -1;
        }
    }

    private boolean vacio(String valor) {
        return valor == null || valor.trim().isEmpty();
    }

    private boolean esFecha(String valor) {
        if (valor == null || !valor.matches("\\d{4}-\\d{2}-\\d{2}")) {
            return false;
        }
        try {
            LocalDate.parse(valor);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private boolean esHora(String valor) {
        return valor != null && valor.matches("([01]\\d|2[0-3]):[0-5]\\d");
    }
}
