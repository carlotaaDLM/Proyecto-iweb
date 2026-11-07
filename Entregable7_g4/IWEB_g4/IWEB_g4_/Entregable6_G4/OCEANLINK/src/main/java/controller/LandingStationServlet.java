package controller;

import beans.LandingStation;
import beans.Paginacion;
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


@WebServlet(name = "LandingStationServlet", value = "/LandingStationServlet", loadOnStartup = 3)
public class LandingStationServlet extends HttpServlet {

    private static final int ROL_ADMINISTRADOR = 1;

    static final List<String> PAISES = Arrays.asList(
            "Chile", "Colombia", "Ecuador", "Estados Unidos", "Panamá", "Perú");
    static final List<String> ESTADOS = Arrays.asList("Operativa", "En mantenimiento", "Inactiva");


    @Override
    public void init() throws ServletException {
        new InfraestructuraDAO().prepararTablas();
    }


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
                request.setAttribute("paises", PAISES);
                view = request.getRequestDispatcher("/admin/NuevaLandingStation.jsp");
                view.forward(request, response);
                break;

            case "editar": {
                LandingStation ls = dao.obtenerLandingStation(request.getParameter("id"));
                if (ls == null) {
                    response.sendRedirect(request.getContextPath() + "/LandingStationServlet?action=lista");
                    return;
                }
                request.setAttribute("estacion", ls);
                request.setAttribute("paises", PAISES);
                request.setAttribute("estados", ESTADOS);
                view = request.getRequestDispatcher("/admin/EditarLandingStation.jsp");
                view.forward(request, response);
                break;
            }

            default: {   // lista
                String buscar = request.getParameter("buscar");
                String pais = request.getParameter("pais");
                String estado = request.getParameter("estado");

                Paginacion pag = new Paginacion(request.getParameter("pagina"));
                pag.setUrl(armarUrl(request, "buscar", buscar, "pais", pais, "estado", estado));

                request.setAttribute("estaciones", dao.listarLandingStations(buscar, pais, estado, pag));
                request.setAttribute("paginacion", pag);
                request.setAttribute("paisesFiltro", dao.listarPaises());
                request.setAttribute("estados", ESTADOS);
                request.setAttribute("operativas", dao.contarLandingPorEstado("Operativa"));
                request.setAttribute("enMantenimiento", dao.contarLandingPorEstado("En mantenimiento"));
                request.setAttribute("inactivas", dao.contarLandingPorEstado("Inactiva"));
                request.setAttribute("buscar", buscar);
                request.setAttribute("pais", pais);
                request.setAttribute("estado", estado);

                view = request.getRequestDispatcher("/admin/LandingStations.jsp");
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

        String id = request.getParameter("id_landing");
        String nombre = request.getParameter("nombre");
        String ciudad = request.getParameter("ciudad");
        String pais = request.getParameter("pais");

        switch (action) {

            case "crear": {
                String error = validar(nombre, ciudad, pais);
                if (vacio(id) || !id.trim().matches("[A-Za-z0-9-]{3,10}")) {
                    error = "El código debe tener de 3 a 10 caracteres (letras, números o guion). Ej. LS-TRU.";
                } else if (error == null && dao.existeLandingStation(id)) {
                    error = "Ya existe una Landing Station con el código " + id.trim().toUpperCase() + ".";
                }
                if (error == null && !dao.crearLandingStation(id, nombre, ciudad, pais)) {
                    error = "No se pudo registrar. Error de la base de datos: " + dao.getUltimoError();
                }

                if (error != null) {
                    request.setAttribute("error", error);
                    request.setAttribute("paises", PAISES);
                    view = request.getRequestDispatcher("/admin/NuevaLandingStation.jsp");
                    view.forward(request, response);
                    return;
                }

                mensaje(request, "msg", "creada");
                mensaje(request, "idMsg", id.trim().toUpperCase());
                response.sendRedirect(request.getContextPath() + "/LandingStationServlet?action=lista");
                break;
            }

            case "actualizar": {
                LandingStation actual = dao.obtenerLandingStation(id);
                if (actual == null) {
                    response.sendRedirect(request.getContextPath() + "/LandingStationServlet?action=lista");
                    return;
                }

                String estado = request.getParameter("estado");
                String error = validar(nombre, ciudad, pais);
                if (error == null && !ESTADOS.contains(estado)) {
                    error = "Selecciona el estado de la estación.";
                }
                if (error == null && !dao.actualizarLandingStation(actual.getIdLanding(), nombre, ciudad, pais, estado)) {
                    error = "No se pudo guardar. Error de la base de datos: " + dao.getUltimoError();
                }

                if (error != null) {
                    actual.setNombre(nombre);
                    actual.setCiudad(ciudad);
                    actual.setPais(pais);
                    actual.setEstado(estado);
                    request.setAttribute("estacion", actual);
                    request.setAttribute("error", error);
                    request.setAttribute("paises", PAISES);
                    request.setAttribute("estados", ESTADOS);
                    view = request.getRequestDispatcher("/admin/EditarLandingStation.jsp");
                    view.forward(request, response);
                    return;
                }

                mensaje(request, "msg", "actualizada");
                mensaje(request, "idMsg", actual.getIdLanding());
                response.sendRedirect(request.getContextPath() + "/LandingStationServlet?action=lista");
                break;
            }

            case "borrar": {
                boolean borrada = !vacio(id) && dao.borrarLandingStation(id);
                mensaje(request, "msg", borrada ? "eliminada" : "noEliminada");
                mensaje(request, "idMsg", id == null ? "" : id);
                response.sendRedirect(request.getContextPath() + "/LandingStationServlet?action=lista");
                break;
            }

            default:
                response.sendRedirect(request.getContextPath() + "/LandingStationServlet?action=lista");
        }
    }


    private String validar(String nombre, String ciudad, String pais) {
        if (vacio(nombre) || nombre.trim().length() > 100) {
            return "Ingresa el nombre de la estación (máximo 100 caracteres).";
        }
        if (vacio(ciudad) || ciudad.trim().length() > 50) {
            return "Ingresa la ciudad (máximo 50 caracteres).";
        }
        if (!PAISES.contains(pais)) {
            return "Selecciona el país.";
        }
        return null;
    }

    // Solo entra el usuario con sesión y rol Administrador
    private Usuario usuarioSesion(HttpServletRequest request) {
        Usuario u = (Usuario) request.getSession().getAttribute("usuarioSesion");
        if (u == null || u.getRol() == null || u.getRol().getIdRol() != ROL_ADMINISTRADOR) {
            return null;
        }
        return u;
    }

    private String armarUrl(HttpServletRequest request, String... filtros) throws IOException {
        String url = request.getContextPath() + "/LandingStationServlet?action=lista&";
        for (int i = 0; i + 1 < filtros.length; i += 2) {
            if (!vacio(filtros[i + 1])) {
                url += filtros[i] + "=" + URLEncoder.encode(filtros[i + 1], "UTF-8") + "&";
            }
        }
        return url;
    }

    private boolean vacio(String valor) {
        return valor == null || valor.trim().isEmpty();
    }


    // Mensaje para la siguiente vista
    private void mensaje(HttpServletRequest request, String nombre, String valor) {
        request.getSession().setAttribute(nombre, valor);
    }
}
