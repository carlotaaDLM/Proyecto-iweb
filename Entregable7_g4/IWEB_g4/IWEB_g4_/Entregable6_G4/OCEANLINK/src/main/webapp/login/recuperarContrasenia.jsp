<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html lang="es">

<head>

    <meta charset="UTF-8">

    <title>
        Recuperar contraseña
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
            Recuperar contraseña
        </h2>


        <p>
            Ingresa el correo asociado a tu cuenta.
        </p>


        <form
                method="POST"
                action="../LoginServlet?action=recuperar"
        >


            <label>
                Correo electrónico
            </label>


            <input
                    type="email"
                    name="correo"
                    placeholder="correo@ejemplo.com"
                    required
            >


            <button type="submit">

                Enviar enlace

            </button>


        </form>


        <a href="loginIndex.jsp">

            Volver al inicio de sesión

        </a>


    </div>


</div>


</body>


</html>