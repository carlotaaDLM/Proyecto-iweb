<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="beans.Usuario" %>
<%
    // Si ya inició sesión no se vuelve a mostrar el login: el LoginServlet lo lleva a la página de su rol.
    // Se valida el usuario (no solo que exista la sesión), porque toda página JSP crea una sesión.
    Usuario usuarioLogueado = (Usuario) session.getAttribute("usuarioSesion");
    if (usuarioLogueado != null && usuarioLogueado.getRol() != null) {
        response.sendRedirect(request.getContextPath() + "/LoginServlet");
        return;
    }
%>

<!DOCTYPE html>
<html lang="es">

<head>

    <meta charset="UTF-8">

    <title>
        OceanLink - Inicio de sesión
    </title>

    <link rel="stylesheet" href="estiloInicioSesion.css">

</head>


<body>


<div class="background">


    <div class="card">


        <img
                src="../OLlogo.png"
                class="logo"
                alt="OceanLink Telecom"
        >


        <h2>
            Iniciar sesión
        </h2>


        <form
                method="POST"
                action="../LoginServlet?action=login"
        >


            <input
                    type="email"
                    name="correo"
                    placeholder="Correo electrónico"
            >


            <div class="password-box">


                <input
                        id="password"
                        type="password"
                        name="password"
                        placeholder="Contraseña"
                >


                <span>
                    👁
                </span>


            </div>


            <button type="submit">

                Iniciar sesión

            </button>


        </form>


        <a href="recuperarContrasenia.jsp">

            ¿Olvidaste tu contraseña?

        </a>


    </div>


</div>


</body>


</html>