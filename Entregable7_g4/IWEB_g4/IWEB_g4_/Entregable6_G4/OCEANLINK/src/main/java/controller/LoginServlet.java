package controller;

import beans.Usuario;
import dao.LoginDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(
        name = "LoginServlet",
        value = "/LoginServlet"
)
public class LoginServlet extends HttpServlet {

    // Tiempo máximo sin actividad antes de que la sesión expire (en segundos): 30 minutos
    private static final int DURACION_SESION = 30 * 60;

    static String paginaInicio(int rolId) {
        switch (rolId) {
            case 1: return "/UsuarioServlet?action=lista";
            case 2: return "/CapacityPlannerServlet?action=capacidad";
            case 3: return "/NetworkOperatorServlet?action=vistaGeneral";
            case 4: return "/MantenimientoServlet?action=listar";
            case 5: return "/SupervisorServlet?action=dashboard";
            default: return null;
        }
    }


    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action") == null
                ? ""
                : request.getParameter("action");

        // CERRAR SESIÓN: se borra la sesión y todos sus atributos

        if (action.equals("logout")) {

            HttpSession session = request.getSession(false);
            if (session != null) {
                session.invalidate();
            }

            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }


        HttpSession session = request.getSession(false);
        Usuario usuarioSesion = session == null ? null : (Usuario) session.getAttribute("usuarioSesion");

        if (usuarioSesion != null && usuarioSesion.getRol() != null
                && paginaInicio(usuarioSesion.getRol().getIdRol()) != null) {

            response.sendRedirect(request.getContextPath() + paginaInicio(usuarioSesion.getRol().getIdRol()));
            return;
        }

        response.sendRedirect(
                request.getContextPath()
                        + "/login/loginIndex.jsp"
        );
    }


    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {


        String action = request.getParameter("action");


        if (action == null) {
            action = "login";
        }


        LoginDAO loginDAO = new LoginDAO();


        // LOGIN

        if (action.equals("login")) {


            String correo =
                    request.getParameter("correo");


            String password =
                    request.getParameter("password");


            Usuario usuario =
                    loginDAO.validarLogin(
                            correo,
                            password
                    );


            if (usuario != null && usuario.getRol() != null
                    && paginaInicio(usuario.getRol().getIdRol()) != null) {


                HttpSession session = request.getSession();
                session.setAttribute("usuarioSesion", usuario);
                session.setMaxInactiveInterval(DURACION_SESION);

                response.sendRedirect(
                        request.getContextPath()
                                + paginaInicio(usuario.getRol().getIdRol())
                );


            } else {


                response.sendRedirect(
                        request.getContextPath()
                                + "/login/loginError.jsp?correo="
                                    + java.net.URLEncoder.encode(correo == null ? "" : correo, "UTF-8")
                );
            }


        }

        // RECUPERAR CONTRASEÑA

        else if (action.equals("recuperar")) {


            String correo =
                    request.getParameter("correo");


            boolean existe =
                    loginDAO.existeCorreo(correo);


            if (existe) {


                response.sendRedirect(
                        request.getContextPath()
                                + "/login/correoEnviado.jsp"
                );


            } else {


                response.sendRedirect(
                        request.getContextPath()
                                + "/login/recuperarContraseniaError.jsp"
                );
            }

        }

        // ACCIÓN NO RECONOCIDA

        else {
            response.sendRedirect(
                    request.getContextPath()
                            + "/login/loginIndex.jsp"
            );
        }
    }
}