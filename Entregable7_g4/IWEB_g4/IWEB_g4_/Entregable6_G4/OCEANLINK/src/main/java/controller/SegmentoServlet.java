package controller;

import beans.Paginacion;
import beans.Segmento;
import beans.Usuario;
import dao.InfraestructuraDAO;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.net.URLEncoder;
import java.util.Arrays;
import java.util.List;

/*
 * Administrador: CRUD de segmentos de fibra submarina.
 *   C - formCrear / crear      R - lista (filtros + paginación)
 *   U - editar / actualizar    D - borrar (solo si ninguna ruta, incidencia, reserva ni histórico lo usa)
 */
@WebServlet(name = "SegmentoServlet", value = "/SegmentoServlet")
public class SegmentoServlet extends HttpServlet {

    private static final int ROL_ADMINISTRADOR = 1;
    private static final double CAPACIDAD_MAXIMA = 100000;   // Gbps

    static final List<String> ESTADOS = Arrays.asList("Operativo", "Degradado", "En mantenimiento", "Fuera de servicio");


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (usuarioSesion(request) == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        String action = request.getParameter("action") == null ? "lista" : request.getParameter("action");
        InfraestructuraDAO dao = new InfraestructuraDAO();
        RequestDispatcher view;

        switch (action) {

            case "formCrear":
                request.setAttribute("landings", dao.listarLandingStations());
                view = request.getRequestDispatcher("/admin/NuevoSegmento.jsp");
                view.forward(request, response);
                break;

            case "editar": {
                Segmento s = dao.obtenerSegmento(request.getParameter("id"));
                if (s == null) {
                    response.sendRedirect(request.getContextPath() + "/SegmentoServlet?action=lista");
                    return;
                }
                request.setAttribute("segmento", s);
                request.setAttribute("estados", ESTADOS);
                view = request.getRequestDispatcher("/admin/EditarSegmento.jsp");
                view.forward(request, response);
                break;
            }

            default: {   // lista
                String buscar = request.getParameter("buscar");
                String estado = request.getParameter("estado");
                String landing = request.getParameter("landing");

                Paginacion pag = new Paginacion(request.getParameter("pagina"));
                pag.setUrl(armarUrl(request, "buscar", buscar, "estado", estado, "landing", landing));

                request.setAttribute("segmentos", dao.listarSegmentos(buscar, estado, landing, pag));
                request.setAttribute("paginacion", pag);
                request.setAttribute("landings", dao.listarLandingStations());
                request.setAttribute("estados", ESTADOS);
                request.setAttribute("capacidadRed", dao.obtenerCapacidadRed());
                for (String e : ESTADOS) {
                    request.setAttribute("total" + e.replace(" ", ""), dao.contarSegmentosPorEstado(e));
                }
                request.setAttribute("buscar", buscar);
                request.setAttribute("estado", estado);
                request.setAttribute("landing", landing);

                view = request.getRequestDispatcher("/admin/SegmentosFibra.jsp");
                view.forward(request, response);
            }
        }
    }


    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (usuarioSesion(request) == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        String action = request.getParameter("action") == null ? "" : request.getParameter("action");
        InfraestructuraDAO dao = new InfraestructuraDAO();
        RequestDispatcher view;

        String codigo = request.getParameter("codigo_segmento");
        double capacidad = numero(request.getParameter("capacidad_total"));

        switch (action) {

            case "crear": {
                String origen = request.getParameter("id_origen");
                String destino = request.getParameter("id_destino");

                String error = null;
                String existente;
                if (vacio(codigo) || !codigo.trim().matches("[A-Za-z0-9-]{3,12}")) {
                    error = "El código debe tener de 3 a 12 caracteres (letras, números o guion). Ej. SEG-LUR-TRU.";
                } else if (dao.existeSegmento(codigo)) {
                    error = "Ya existe un segmento con el código " + codigo.trim().toUpperCase() + ".";
                } else if (capacidad <= 0 || capacidad > CAPACIDAD_MAXIMA) {
                    error = "La capacidad total debe ser mayor que 0 y como máximo " + (int) CAPACIDAD_MAXIMA + " Gbps.";
                } else if (vacio(origen) || dao.obtenerLandingStation(origen) == null) {
                    error = "Selecciona la estación de origen.";
                } else if (vacio(destino) || dao.obtenerLandingStation(destino) == null) {
                    error = "Selecciona la estación de destino.";
                } else if ("Inactiva".equals(dao.obtenerLandingStation(origen).getEstado())
                        || "Inactiva".equals(dao.obtenerLandingStation(destino).getEstado())) {
                    error = "No se puede crear un segmento con una estación Inactiva.";
                } else if (origen.equals(destino)) {
                    error = "La estación de destino debe ser distinta de la de origen.";
                } else if ((existente = dao.segmentoEntre(origen, destino)) != null) {
                    error = "Ya existe un segmento entre esas estaciones: " + existente + ".";
                }
                if (error == null && !dao.crearSegmento(codigo, capacidad, origen, destino)) {
                    error = "No se pudo registrar. Error de la base de datos: " + dao.getUltimoError();
                }

                if (error != null) {
                    request.setAttribute("error", error);
                    request.setAttribute("landings", dao.listarLandingStations());
                    view = request.getRequestDispatcher("/admin/NuevoSegmento.jsp");
                    view.forward(request, response);
                    return;
                }

                mensaje(request, "msg", "creado");
                mensaje(request, "idMsg", codigo.trim().toUpperCase());
                response.sendRedirect(request.getContextPath() + "/SegmentoServlet?action=lista");
                break;
            }

            case "actualizar": {
                Segmento actual = dao.obtenerSegmento(codigo);
                if (actual == null) {
                    response.sendRedirect(request.getContextPath() + "/SegmentoServlet?action=lista");
                    return;
                }

                String estado = request.getParameter("estado");
                double minimo = actual.getCapacidadUtilizada() + actual.getCapacidadReservada();

                String error = null;
                if (capacidad <= 0 || capacidad > CAPACIDAD_MAXIMA) {
                    error = "La capacidad total debe ser mayor que 0 y como máximo " + (int) CAPACIDAD_MAXIMA + " Gbps.";
                } else if (capacidad < minimo) {
                    error = "La capacidad total no puede ser menor que lo utilizado y reservado ("
                            + String.format(new java.util.Locale("es", "ES"), "%,.0f", minimo) + " Gbps).";
                } else if (!ESTADOS.contains(estado)) {
                    error = "Selecciona el estado del segmento.";
                }
                if (error == null && !dao.actualizarSegmento(actual.getCodigoSegmento(), capacidad, estado)) {
                    error = "No se pudo guardar. Error de la base de datos: " + dao.getUltimoError();
                }

                if (error != null) {
                    request.setAttribute("segmento", actual);
                    request.setAttribute("estados", ESTADOS);
                    request.setAttribute("error", error);
                    view = request.getRequestDispatcher("/admin/EditarSegmento.jsp");
                    view.forward(request, response);
                    return;
                }

                mensaje(request, "msg", "actualizado");
                mensaje(request, "idMsg", actual.getCodigoSegmento());
                response.sendRedirect(request.getContextPath() + "/SegmentoServlet?action=lista");
                break;
            }

            case "borrar": {
                boolean borrado = !vacio(codigo) && dao.borrarSegmento(codigo);
                mensaje(request, "msg", borrado ? "eliminado" : "noEliminado");
                mensaje(request, "idMsg", codigo == null ? "" : codigo);
                response.sendRedirect(request.getContextPath() + "/SegmentoServlet?action=lista");
                break;
            }

            default:
                response.sendRedirect(request.getContextPath() + "/SegmentoServlet?action=lista");
        }
    }


    private Usuario usuarioSesion(HttpServletRequest request) {
        Usuario u = (Usuario) request.getSession().getAttribute("usuarioSesion");
        if (u == null || u.getRol() == null || u.getRol().getIdRol() != ROL_ADMINISTRADOR) {
            return null;
        }
        return u;
    }

    private String armarUrl(HttpServletRequest request, String... filtros) throws IOException {
        String url = request.getContextPath() + "/SegmentoServlet?action=lista&";
        for (int i = 0; i + 1 < filtros.length; i += 2) {
            if (!vacio(filtros[i + 1])) {
                url += filtros[i] + "=" + URLEncoder.encode(filtros[i + 1], "UTF-8") + "&";
            }
        }
        return url;
    }

    private double numero(String valor) {
        try {
            return Double.parseDouble(valor.trim());
        } catch (NumberFormatException | NullPointerException e) {
            return -1;
        }
    }

    private boolean vacio(String valor) {
        return valor == null || valor.trim().isEmpty();
    }


    // Mensaje para la siguiente vista: se guarda en sesión antes del sendRedirect y la vista
    // lo borra después de mostrarlo, así al presionar F5 ya no vuelve a aparecer.
    private void mensaje(HttpServletRequest request, String nombre, String valor) {
        request.getSession().setAttribute(nombre, valor);
    }
}
