<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="beans.Cliente" %>
<%@ include file="badges.jspf" %>
<%
    String servlet = request.getContextPath() + "/ClienteServlet";
    String error = (String) request.getAttribute("error");
    Cliente cliente = (Cliente) request.getAttribute("cliente");

    // Valores del formulario: los que se escribieron (si hubo error) o los del cliente
    String razonSocial = request.getParameter("razon_social") != null ? request.getParameter("razon_social")
            : (cliente == null ? "" : cliente.getRazonSocial());
    String ruc = request.getParameter("ruc") != null ? request.getParameter("ruc")
            : (cliente == null ? "" : cliente.getRuc());
    String correo = request.getParameter("correo") != null ? request.getParameter("correo")
            : (cliente == null ? "" : cliente.getCorreo());
    String telefono = request.getParameter("telefono") != null ? request.getParameter("telefono")
            : (cliente == null || cliente.getTelefono() == null ? "" : cliente.getTelefono());
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8"/>
    <meta content="width=device-width, initial-scale=1" name="viewport"/>
    <title>Editar cliente | OceanLink</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/admin/admin.css"/>
</head>
<body>

<jsp:include page="menu.jsp">
    <jsp:param name="activo" value="clientes"/>
</jsp:include>

    <main class="content">
        <a class="back-link" href="<%= servlet %>?action=lista">
            <svg aria-hidden="true" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"></path></svg>
            Volver a Clientes
        </a>

        <div class="topbar">
            <div>
                <h1>Editar cliente</h1>
                <p class="small">Los cambios se ven en las solicitudes y servicios del cliente.</p>
            </div>
        </div>

        <% if (error != null) { %>
        <div class="alert error"><strong>Revisa el formulario</strong> <%= texto(error) %></div>
        <% } %>

        <form action="<%= servlet %>" class="card" method="post">
            <input type="hidden" name="action" value="actualizar">
            <% if (cliente != null) { %>
            <input type="hidden" name="id" value="<%= cliente.getIdCliente() %>">
            <% } %>
            <fieldset>
                <legend>Datos del cliente</legend>
                <div class="row">
                    <div class="col">
                        <label for="razon_social">Razón social <span class="req">*</span></label>
                        <input id="razon_social" name="razon_social" type="text" maxlength="100" required
                               placeholder="Ej. Andina Telecom S.A.C." value="<%= texto(razonSocial) %>"/>
                    </div>
                    <div class="col">
                        <label for="ruc">RUC <span class="req">*</span></label>
                        <input id="ruc" name="ruc" type="text" inputmode="numeric" pattern="\d{11}" maxlength="11" required
                               placeholder="Ej. 20512345671" value="<%= texto(ruc) %>"/>
                        <span class="hint">11 dígitos.</span>
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        <label for="correo">Correo de contacto <span class="req">*</span></label>
                        <input id="correo" name="correo" type="email" maxlength="100" required
                               placeholder="Ej. contacto@empresa.pe" value="<%= texto(correo) %>"/>
                    </div>
                    <div class="col">
                        <label for="telefono">Teléfono</label>
                        <input id="telefono" name="telefono" type="text" maxlength="20"
                               placeholder="Ej. 014567890" value="<%= texto(telefono) %>"/>
                    </div>
                </div>
            </fieldset>

            <div class="footer-action">
                <a class="ghost" href="<%= servlet %>?action=lista">Cancelar</a>
                <button class="primary" type="submit">Guardar cambios</button>
            </div>
        </form>
    </main>
</div>

</body>
</html>
