<%-- Página de inicio de la aplicación: redirige al login --%>
<%
    response.sendRedirect(
        request.getContextPath() + "/login/loginIndex.jsp"
    );
%>
