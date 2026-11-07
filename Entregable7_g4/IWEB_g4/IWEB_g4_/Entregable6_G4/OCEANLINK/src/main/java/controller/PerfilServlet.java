package controller;

import beans.Usuario;
import dao.UsuarioDAO;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/*
 * Perfil de cualquier rol: ver y editar nombre, apellidos, correo y foto.
 *   GET  (sin action)   -> vista del perfil
 *   GET  action=foto    -> imagen de la foto del usuario (se guarda en USUARIO.foto)
 *   POST action=actualizar (formulario multipart/form-data para subir la foto)
 */
@WebServlet(name = "PerfilServlet", value = "/PerfilServlet", loadOnStartup = 4)
@MultipartConfig(maxFileSize = 2 * 1024 * 1024, maxRequestSize = 3 * 1024 * 1024)
public class PerfilServlet extends HttpServlet {

    // Carpeta (menú y estilos) de cada rol: 1 Admin, 2 CP, 3 NO, 4 MC, 5 Supervisor
    static final String[] CARPETAS = {"admin", "capacityPlanner", "networkOperator", "maintenanceCoordinator", "supervisor"};
    static final String[] ESTILOS = {"admin.css", "capacityPlanner.css", "networkOperator.css", "mantenimiento.css", "supervisor.css"};


    @Override
    public void init() throws ServletException {
        new UsuarioDAO().prepararTablas();
    }


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Usuario sesion = (Usuario) request.getSession().getAttribute("usuarioSesion");
        if (sesion == null || sesion.getRol() == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        UsuarioDAO dao = new UsuarioDAO();

        if ("foto".equals(request.getParameter("action"))) {
            int dni = numero(request.getParameter("dni"));
            byte[] foto = dao.obtenerFoto(dni);
            if (foto == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            String tipo = dao.obtenerTipoFoto(dni);
            response.setContentType(tipo == null ? "image/jpeg" : tipo);
            response.setHeader("Cache-Control", "no-cache");
            response.setContentLength(foto.length);
            response.getOutputStream().write(foto);
            return;
        }

        Usuario usuario = dao.obtenerUsuarioPorDni(sesion.getDniUsuario());
        if (usuario == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }
        usuario.setTieneFoto(dao.tieneFoto(usuario.getDniUsuario()));

        mostrar(request, response, usuario);
    }


    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Usuario sesion = (Usuario) request.getSession().getAttribute("usuarioSesion");
        if (sesion == null || sesion.getRol() == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        UsuarioDAO dao = new UsuarioDAO();
        int dni = sesion.getDniUsuario();
        Usuario actual = dao.obtenerUsuarioPorDni(dni);

        String nombre;
        String apellido1;
        String apellido2;
        String correo;
        Part foto;
        try {
            nombre = request.getParameter("nombre");
            apellido1 = request.getParameter("apellido1");
            apellido2 = request.getParameter("apellido2");
            correo = request.getParameter("correo");
            foto = request.getPart("foto");
        } catch (IllegalStateException e) {
            // la imagen pasa el tamaño máximo (@MultipartConfig)
            request.getSession().setAttribute("msg", "fotoPesada");
            response.sendRedirect(request.getContextPath() + "/PerfilServlet");
            return;
        }
        boolean quitarFoto = request.getParameter("quitarFoto") != null;

        String error = null;
        String letras = "[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]{2,45}";
        if (nombre == null || !nombre.trim().matches(letras)) {
            error = "Ingresa tu nombre (solo letras, de 2 a 45 caracteres).";
        } else if (apellido1 == null || !apellido1.trim().matches(letras)) {
            error = "Ingresa tu primer apellido (solo letras, de 2 a 45 caracteres).";
        } else if (apellido2 == null || !apellido2.trim().matches(letras)) {
            error = "Ingresa tu segundo apellido (solo letras, de 2 a 45 caracteres).";
        } else if (correo == null || !correo.trim().matches("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
                || correo.trim().length() > 100) {
            error = "Ingresa un correo válido (por ejemplo nombre@oceanlink.pe).";
        } else if (dao.existeCorreo(correo, dni)) {
            error = "El correo " + correo.trim() + " ya lo usa otro usuario.";
        }

        boolean hayFoto = foto != null && foto.getSize() > 0;
        String tipo = hayFoto ? foto.getContentType() : null;
        if (error == null && hayFoto && (tipo == null || !(tipo.equals("image/jpeg") || tipo.equals("image/png")
                || tipo.equals("image/gif") || tipo.equals("image/webp")))) {
            error = "La foto debe ser una imagen JPG, PNG, GIF o WEBP.";
        }

        if (error == null && !dao.actualizarPerfil(dni, nombre.trim(), apellido1.trim(), apellido2.trim(),
                correo.trim().toLowerCase())) {
            error = "No se pudo guardar. Error de la base de datos: " + dao.getUltimoError();
        }

        if (error == null && hayFoto) {
            // Se lee la imagen subida en bloques de 8 KB
            ByteArrayOutputStream salida = new ByteArrayOutputStream();
            try (InputStream in = foto.getInputStream()) {
                byte[] bloque = new byte[8192];
                int leidos;
                while ((leidos = in.read(bloque)) != -1) {
                    salida.write(bloque, 0, leidos);
                }
            }
            byte[] bytes = salida.toByteArray();
            if (!dao.guardarFoto(dni, bytes, tipo)) {
                error = "No se pudo guardar la foto. Error de la base de datos: " + dao.getUltimoError();
            }
        } else if (error == null && quitarFoto) {
            dao.guardarFoto(dni, null, null);
        }

        if (error != null) {
            actual.setNombre(nombre);
            actual.setApellido1(apellido1);
            actual.setApellido2(apellido2);
            actual.setCorreo(correo);
            actual.setTieneFoto(dao.tieneFoto(dni));
            request.setAttribute("error", error);
            mostrar(request, response, actual);
            return;
        }

        // Se actualiza el usuario de la sesión para que la barra superior muestre los cambios
        Usuario nuevo = dao.obtenerUsuarioPorDni(dni);
        nuevo.setTieneFoto(dao.tieneFoto(dni));
        request.getSession().setAttribute("usuarioSesion", nuevo);

        request.getSession().setAttribute("msg", "actualizado");
        response.sendRedirect(request.getContextPath() + "/PerfilServlet");
    }


    private void mostrar(HttpServletRequest request, HttpServletResponse response, Usuario usuario)
            throws ServletException, IOException {

        int rol = usuario.getRol() == null ? 1 : usuario.getRol().getIdRol();
        if (rol < 1 || rol > CARPETAS.length) {
            rol = 1;
        }
        request.setAttribute("usuario", usuario);
        request.setAttribute("carpeta", CARPETAS[rol - 1]);
        request.setAttribute("estilo", ESTILOS[rol - 1]);
        request.setAttribute("nombreRol", UsuarioServlet.NOMBRES_ROL[rol - 1]);

        RequestDispatcher view = request.getRequestDispatcher("/perfil/Perfil.jsp");
        view.forward(request, response);
    }

    private int numero(String valor) {
        try {
            return Integer.parseInt(valor.trim());
        } catch (NumberFormatException | NullPointerException e) {
            return -1;
        }
    }
}
