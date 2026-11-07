package controller;

import beans.Cliente;
import beans.Paginacion;
import beans.Usuario;
import dao.ClienteDAO;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.net.URLEncoder;


@WebServlet(name = "ClienteServlet", value = "/ClienteServlet")
public class ClienteServlet extends HttpServlet {

    private static final int ROL_ADMINISTRADOR = 1;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (usuarioSesion(request) == null) {
            response.sendRedirect(request.getContextPath() + "/login/loginIndex.jsp");
            return;
        }

        String action = request.getParameter("action") == null ? "lista" : request.getParameter("action");
        ClienteDAO dao = new ClienteDAO();
        RequestDispatcher view;

        switch (action) {

            case "formCrear":
                view = request.getRequestDispatcher("/admin/NuevoCliente.jsp");
                view.forward(request, response);
                break;

            case "editar": {
                Cliente cliente = dao.obtenerCliente(numero(request.getParameter("id")));
                if (cliente == null) {
                    response.sendRedirect(request.getContextPath() + "/ClienteServlet?action=lista");
                    return;
                }
                request.setAttribute("cliente", cliente);
                view = request.getRequestDispatcher("/admin/EditarCliente.jsp");
                view.forward(request, response);
                break;
            }

            default: {   // lista
                String buscar = request.getParameter("buscar");

                Paginacion pag = new Paginacion(request.getParameter("pagina"));
                String enlace = request.getContextPath() + "/ClienteServlet?action=lista&";
                if (buscar != null && !buscar.trim().isEmpty()) {
                    enlace += "buscar=" + URLEncoder.encode(buscar.trim(), "UTF-8") + "&";
                }
                pag.setUrl(enlace);

                request.setAttribute("clientes", dao.listarClientes(buscar, pag));
                request.setAttribute("paginacion", pag);
                request.setAttribute("buscar", buscar);

                view = request.getRequestDispatcher("/admin/Clientes.jsp");
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
        ClienteDAO dao = new ClienteDAO();
        RequestDispatcher view;

        int id = numero(request.getParameter("id"));
        String razonSocial = request.getParameter("razon_social");
        String ruc = request.getParameter("ruc");
        String correo = request.getParameter("correo");
        String telefono = request.getParameter("telefono");

        switch (action) {

            case "crear": {
                String error = validar(dao, -1, razonSocial, ruc, correo, telefono);
                Integer idNuevo = null;
                if (error == null) {
                    idNuevo = dao.crearCliente(razonSocial, ruc, correo, telefono);
                    if (idNuevo == null) {
                        error = "No se pudo registrar. Error de la base de datos: " + dao.getUltimoError();
                    }
                }

                if (error != null) {
                    request.setAttribute("error", error);
                    view = request.getRequestDispatcher("/admin/NuevoCliente.jsp");
                    view.forward(request, response);
                    return;
                }

                mensaje(request, "msg", "creado");
                response.sendRedirect(request.getContextPath() + "/ClienteServlet?action=lista");
                break;
            }

            case "actualizar": {
                Cliente actual = dao.obtenerCliente(id);
                if (actual == null) {
                    response.sendRedirect(request.getContextPath() + "/ClienteServlet?action=lista");
                    return;
                }

                String error = validar(dao, id, razonSocial, ruc, correo, telefono);
                if (error == null && !dao.actualizarCliente(id, razonSocial, ruc, correo, telefono)) {
                    error = "No se pudo guardar. Error de la base de datos: " + dao.getUltimoError();
                }

                if (error != null) {
                    actual.setRazonSocial(razonSocial);
                    actual.setRuc(ruc);
                    actual.setCorreo(correo);
                    actual.setTelefono(telefono);
                    request.setAttribute("cliente", actual);
                    request.setAttribute("error", error);
                    view = request.getRequestDispatcher("/admin/EditarCliente.jsp");
                    view.forward(request, response);
                    return;
                }

                mensaje(request, "msg", "actualizado");
                response.sendRedirect(request.getContextPath() + "/ClienteServlet?action=lista");
                break;
            }

            case "borrar": {
                boolean borrado = dao.borrarCliente(id);
                mensaje(request, "msg", borrado ? "eliminado" : "noEliminado");
                response.sendRedirect(request.getContextPath() + "/ClienteServlet?action=lista");
                break;
            }

            default:
                response.sendRedirect(request.getContextPath() + "/ClienteServlet?action=lista");
        }
    }


    private String validar(ClienteDAO dao, int id, String razonSocial, String ruc, String correo, String telefono) {
        if (razonSocial == null || razonSocial.trim().length() < 3 || razonSocial.trim().length() > 100) {
            return "Ingresa la razón social (de 3 a 100 caracteres).";
        }
        if (ruc == null || !ruc.trim().matches("\\d{11}")) {
            return "El RUC debe tener 11 dígitos.";
        }
        if (correo == null || !correo.trim().matches("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
                || correo.trim().length() > 100) {
            return "Ingresa un correo válido (por ejemplo contacto@empresa.pe).";
        }
        if (telefono != null && !telefono.trim().isEmpty() && !telefono.trim().matches("[0-9 +-]{6,20}")) {
            return "El teléfono solo puede tener números, espacios, + o - (de 6 a 20 caracteres).";
        }
        if (dao.existe("ruc", ruc, id)) {
            return "Ya existe un cliente con el RUC " + ruc.trim() + ".";
        }
        if (dao.existe("correo", correo, id)) {
            return "El correo " + correo.trim() + " ya lo usa otro cliente.";
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

    private int numero(String valor) {
        try {
            return Integer.parseInt(valor.trim());
        } catch (NumberFormatException | NullPointerException e) {
            return -1;
        }
    }


    // Mensaje para la siguiente vista
    private void mensaje(HttpServletRequest request, String nombre, String valor) {
        request.getSession().setAttribute(nombre, valor);
    }
}
