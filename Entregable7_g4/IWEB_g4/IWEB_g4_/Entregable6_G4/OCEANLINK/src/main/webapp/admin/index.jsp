<%
    response.sendRedirect(
        request.getContextPath() + "/UsuarioServlet?action=lista"
    );
%>