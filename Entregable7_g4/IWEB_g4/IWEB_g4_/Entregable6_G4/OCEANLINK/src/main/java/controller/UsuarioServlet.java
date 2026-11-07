package controller;

import dao.UsuarioDAO;
import beans.Paginacion;
import beans.Rol;
import beans.Usuario;
import java.util.ArrayList;
import java.io.IOException;
import java.net.URLEncoder;
import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/*
 * Administrador: CRUD de usuarios.
 *   C - formCrear / crear (se muestra el usuario registrado)
 *   R - lista con filtros y paginación
 *   U - editar / actualizar y cambiarEstado (Activo <-> Inactivo)
 *   D - borrar: solo si el usuario no dejó registros (solicitudes, historiales); si los tiene se desactiva
 */
@WebServlet(name = "UsuarioServlet", value = "/UsuarioServlet")
public class UsuarioServlet extends HttpServlet {

    private static final int ROL_ADMINISTRADOR = 1;

    static final String[] NOMBRES_ROL = {
            "Administrador", "Capacity Planner", "Network Operator", "Maintenance Coordinator", "Supervisor"
    };

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        if (usuarioSesion(request) == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        String action = request.getParameter("action") == null
                ? "lista"
                : request.getParameter("action");

        UsuarioDAO usuarioDAO = new UsuarioDAO();
        RequestDispatcher view;

        switch (action) {

            case "editar": {

                Usuario usuario = usuarioDAO.obtenerUsuarioPorDni(numero(request.getParameter("id")));

                if (usuario == null) {
                    response.sendRedirect(request.getContextPath() + "/UsuarioServlet?action=lista");
                    return;
                }

                request.setAttribute("usuario", usuario);
                view = request.getRequestDispatcher("/admin/editarUsuario.jsp");
                view.forward(request, response);
                break;
            }

            case "formCrear":

                view = request.getRequestDispatcher("/admin/nuevoUsuario.jsp");
                view.forward(request, response);
                break;

            // Usuario recién registrado (resumen)
            case "creado": {

                Usuario usuario = usuarioDAO.obtenerUsuarioPorDni(numero(request.getParameter("id")));

                if (usuario == null) {
                    response.sendRedirect(request.getContextPath() + "/UsuarioServlet?action=lista");
                    return;
                }

                request.setAttribute("usuario", usuario);
                view = request.getRequestDispatcher("/admin/UsuarioCreado.jsp");
                view.forward(request, response);
                break;
            }

            default: {   // lista

                String buscar = request.getParameter("buscar");
                String rol = request.getParameter("rol");
                String estado = request.getParameter("estado");

                // Paginación en el servidor: 10 usuarios por página, conservando los filtros
                Paginacion paginacion = new Paginacion(request.getParameter("pagina"));

                ArrayList<Usuario> listaUsuarios =
                        usuarioDAO.obtenerListaUsuarios(buscar, rol, estado, paginacion);

                String enlace = request.getContextPath() + "/UsuarioServlet?action=lista&";
                if (buscar != null && !buscar.trim().isEmpty()) {
                    enlace += "buscar=" + URLEncoder.encode(buscar.trim(), "UTF-8") + "&";
                }
                if (rol != null && !rol.isEmpty()) {
                    enlace += "rol=" + URLEncoder.encode(rol, "UTF-8") + "&";
                }
                if (estado != null && !estado.isEmpty()) {
                    enlace += "estado=" + URLEncoder.encode(estado, "UTF-8") + "&";
                }
                paginacion.setUrl(enlace);

                request.setAttribute("lista", listaUsuarios);
                request.setAttribute("paginacion", paginacion);
                request.setAttribute("totalUsuarios", usuarioDAO.contarUsuarios(null));
                request.setAttribute("activos", usuarioDAO.contarUsuarios("Activo"));
                request.setAttribute("inactivos", usuarioDAO.contarUsuarios("Inactivo"));
                request.setAttribute("buscar", buscar);
                request.setAttribute("rol", rol);
                request.setAttribute("estado", estado);

                view = request.getRequestDispatcher("/admin/GestionUsuarios.jsp");
                view.forward(request, response);
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Usuario admin = usuarioSesion(request);
        if (admin == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        String action = request.getParameter("action") == null ? "" : request.getParameter("action");

        UsuarioDAO usuarioDAO = new UsuarioDAO();
        RequestDispatcher view;

        switch (action) {

            case "crear": {

                String dniTexto = request.getParameter("dni");
                String nombre = request.getParameter("nombre");
                String apellido1 = request.getParameter("apellido1");
                String apellido2 = request.getParameter("apellido2");
                String correo = request.getParameter("correo");
                int rolId = numero(request.getParameter("rolId"));
                String password = request.getParameter("password");

                String error;
                if (dniTexto == null || !dniTexto.trim().matches("\\d{8}")) {
                    error = "El DNI debe tener 8 dígitos.";
                } else {
                    error = validar(nombre, apellido1, apellido2, correo, rolId);
                }
                if (error == null && (password == null || password.length() < 4 || password.length() > 50)) {
                    error = "La contraseña temporal debe tener entre 4 y 50 caracteres.";
                }
                if (error == null && usuarioDAO.existeDni(Integer.parseInt(dniTexto.trim()))) {
                    error = "Ya existe un usuario con el DNI " + dniTexto.trim() + ".";
                }
                if (error == null && usuarioDAO.existeCorreo(correo, -1)) {
                    error = "El correo " + correo.trim() + " ya está registrado.";
                }
                if (error == null && !usuarioDAO.crearUsuario(Integer.parseInt(dniTexto.trim()), nombre.trim(),
                        apellido1.trim(), apellido2.trim(), correo.trim().toLowerCase(), password, rolId)) {
                    error = "No se pudo registrar. Error de la base de datos: " + usuarioDAO.getUltimoError();
                }

                if (error != null) {
                    request.setAttribute("error", error);
                    view = request.getRequestDispatcher("/admin/nuevoUsuario.jsp");
                    view.forward(request, response);
                    return;
                }

                response.sendRedirect(request.getContextPath() + "/UsuarioServlet?action=creado&id=" + dniTexto.trim());
                break;
            }

            case "editar": {

                int dni = numero(request.getParameter("dni"));
                Usuario actual = usuarioDAO.obtenerUsuarioPorDni(dni);

                if (actual == null) {
                    response.sendRedirect(request.getContextPath() + "/UsuarioServlet?action=lista");
                    return;
                }

                String nombre = request.getParameter("nombre");
                String apellido1 = request.getParameter("apellido1");
                String apellido2 = request.getParameter("apellido2");
                String correo = request.getParameter("correo");
                int rolId = numero(request.getParameter("rolId"));

                String error = validar(nombre, apellido1, apellido2, correo, rolId);
                if (error == null && usuarioDAO.existeCorreo(correo, dni)) {
                    error = "El correo " + correo.trim() + " ya lo usa otro usuario.";
                }
                if (error == null && dni == admin.getDniUsuario() && rolId != ROL_ADMINISTRADOR) {
                    error = "No puedes quitarte el rol de Administrador a ti mismo.";
                }
                if (error == null && !usuarioDAO.actualizarUsuario(String.valueOf(dni), nombre.trim(), apellido1.trim(),
                        apellido2.trim(), correo.trim().toLowerCase(), rolId)) {
                    error = "No se pudo guardar. Error de la base de datos: " + usuarioDAO.getUltimoError();
                }

                if (error != null) {
                    // se vuelve al formulario con lo que escribió el administrador
                    actual.setNombre(nombre);
                    actual.setApellido1(apellido1);
                    actual.setApellido2(apellido2);
                    actual.setCorreo(correo);
                    Rol rol = new Rol();
                    rol.setIdRol(rolId);
                    actual.setRol(rol);
                    request.setAttribute("usuario", actual);
                    request.setAttribute("error", error);
                    view = request.getRequestDispatcher("/admin/editarUsuario.jsp");
                    view.forward(request, response);
                    return;
                }

                redirigirLista(request, response, "actualizado", dni);
                break;
            }

            case "cambiarEstado": {

                int dni = numero(request.getParameter("id"));

                if (dni == admin.getDniUsuario()) {
                    redirigirLista(request, response, "propio", dni);
                    return;
                }

                redirigirLista(request, response, usuarioDAO.cambiarEstadoUsuario(dni) ? "estado" : "error", dni);
                break;
            }

            case "borrar": {

                int dni = numero(request.getParameter("id"));

                String msg;
                if (dni == admin.getDniUsuario()) {
                    msg = "propio";
                } else if (usuarioDAO.contarRegistros(dni) > 0) {
                    msg = "tieneRegistros";
                } else {
                    msg = usuarioDAO.borrarUsuario(dni) ? "eliminado" : "tieneRegistros";
                }

                redirigirLista(request, response, msg, dni);
                break;
            }

            default:
                response.sendRedirect(request.getContextPath() + "/UsuarioServlet?action=lista");
        }
    }


    private String validar(String nombre, String apellido1, String apellido2, String correo, int rolId) {
        String letras = "[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]{2,45}";
        if (nombre == null || !nombre.trim().matches(letras)) {
            return "Ingresa el nombre (solo letras, de 2 a 45 caracteres).";
        }
        if (apellido1 == null || !apellido1.trim().matches(letras)) {
            return "Ingresa el primer apellido (solo letras, de 2 a 45 caracteres).";
        }
        if (apellido2 == null || !apellido2.trim().matches(letras)) {
            return "Ingresa el segundo apellido (solo letras, de 2 a 45 caracteres).";
        }
        if (correo == null || !correo.trim().matches("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
                || correo.trim().length() > 100) {
            return "Ingresa un correo válido (por ejemplo nombre@oceanlink.pe).";
        }
        if (rolId < 1 || rolId > NOMBRES_ROL.length) {
            return "Selecciona el rol del usuario.";
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

    private void redirigirLista(HttpServletRequest request, HttpServletResponse response, String msg, int dni)
            throws IOException {
        // El mensaje va en sesión (no en el URL): la vista lo borra después de mostrarlo
        request.getSession().setAttribute("msg", msg);
        request.getSession().setAttribute("idMsg", String.valueOf(dni));
        response.sendRedirect(request.getContextPath() + "/UsuarioServlet?action=lista");
    }

    private int numero(String valor) {
        try {
            return Integer.parseInt(valor.trim());
        } catch (NumberFormatException | NullPointerException e) {
            return -1;
        }
    }
}
