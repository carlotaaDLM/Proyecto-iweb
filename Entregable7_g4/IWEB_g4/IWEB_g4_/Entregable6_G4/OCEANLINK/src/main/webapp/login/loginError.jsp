<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%
    // Correo que se escribió (lo envía el LoginServlet) para no volver a escribirlo
    String correo = request.getParameter("correo") == null ? "" : request.getParameter("correo");
    correo = correo.replace("&", "&amp;").replace("\"", "&quot;").replace("<", "&lt;");
%>
<!DOCTYPE html>
<html lang="es">

<head>

    <meta charset="UTF-8">

    <title>
        OceanLink - Error de inicio de sesión
    </title>

    <link rel="stylesheet" href="<%= request.getContextPath() %>/login/estiloInicioSesion.css">

</head>


<body>


<div class="background">


    <div class="card">


        <img
                src="<%= request.getContextPath() %>/OLlogo.png"
                class="logo"
                alt="OceanLink Telecom"
        >


        <h2>
            Iniciar sesión
        </h2>


        <div class="error-message">

            <span class="error-icon">!</span>

            <span>
                Correo electrónico o contraseña incorrectos.
            </span>

        </div>


        <form
                method="POST"
                action="<%= request.getContextPath() %>/LoginServlet?action=login"
        >


            <input
                    class="input-error"
                    type="email"
                    name="correo"
                    placeholder="Correo electrónico"
                    value="<%= correo %>"
            >


            <input
                    class="input-error"
                    type="password"
                    name="password"
                    placeholder="Contraseña"
            >


            <button type="submit">

                Intentar nuevamente

            </button>


        </form>


        <a href="<%= request.getContextPath() %>/login/recuperarContrasenia.jsp">

            ¿Olvidaste tu contraseña?

        </a>


    </div>


</div>


</body>


</html>
