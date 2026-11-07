<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Paginacion" %>
<%--
    Barra de paginación que usan todos los roles. Se incluye debajo de la tabla con:
        <jsp:include page="/paginacion.jsp">
            <jsp:param name="atributo" value="paginacion"/>    (nombre del objeto Paginacion en el request)
            <jsp:param name="parametro" value="pagina"/>       (nombre del parámetro de la página en el enlace)
            <jsp:param name="etiqueta" value="segmentos"/>     (texto: "Mostrando 1 a 10 de 24 segmentos")
            <jsp:param name="ancla" value="clientes"/>         (opcional: vuelve a esa sección de la página)
        </jsp:include>
    El Servlet arma el objeto Paginacion y el DAO usa LIMIT ?, ? con él.
--%>
<%
    String atributo = request.getParameter("atributo") == null ? "paginacion" : request.getParameter("atributo");
    String parametro = request.getParameter("parametro") == null ? "pagina" : request.getParameter("parametro");
    String etiqueta = request.getParameter("etiqueta") == null ? "registros" : request.getParameter("etiqueta");
    String ancla = request.getParameter("ancla") == null ? "" : "#" + request.getParameter("ancla");

    Paginacion pag = (Paginacion) request.getAttribute(atributo);

    if (pag != null && pag.getTotalRegistros() > 0) {
        int actual = pag.getPagina();
        int ultima = pag.getTotalPaginas();
        String base = pag.getUrl() + parametro + "=";
%>
<div class="pagination">
    <span class="small">Mostrando <%= pag.getInicio() + 1 %> a <%= pag.getFin() %> de <%= pag.getTotalRegistros() %> <%= etiqueta %></span>
    <% if (ultima > 1) { %>
    <nav class="pages" aria-label="Paginación">
        <% if (actual > 1) { %>
        <a href="<%= base + (actual - 1) + ancla %>">Anterior</a>
        <% } else { %>
        <span class="disabled">Anterior</span>
        <% } %>

        <%
            // Se muestran la primera, la última y las páginas cercanas a la actual
            for (int p = 1; p <= ultima; p++) {
                if (p == 1 || p == ultima || (p >= actual - 1 && p <= actual + 1)) {
                    if (p == actual) {
        %>
        <span class="current" aria-current="page"><%= p %></span>
        <%          } else { %>
        <a href="<%= base + p + ancla %>"><%= p %></a>
        <%
                    }
                } else if (p == actual - 2 || p == actual + 2) {
        %>
        <span class="disabled">…</span>
        <%
                }
            }
        %>

        <% if (actual < ultima) { %>
        <a href="<%= base + (actual + 1) + ancla %>">Siguiente</a>
        <% } else { %>
        <span class="disabled">Siguiente</span>
        <% } %>
    </nav>
    <% } %>
</div>
<%
    }
%>
