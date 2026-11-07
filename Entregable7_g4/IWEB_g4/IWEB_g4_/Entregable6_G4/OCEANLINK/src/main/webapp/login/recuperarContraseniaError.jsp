<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<!DOCTYPE html>

<html lang="es">

<head>

    <meta charset="UTF-8">

    <title>
        Recuperar contraseña - Error
    </title>


    <link rel="stylesheet" href="estiloInicioSesion.css">

</head>



<body>


<div class="background">


    <div class="card">


        <img src="../OLlogo.png"
             class="logo"
             alt="OceanLink Telecom">



        <h2>
            Recuperar contraseña
        </h2>



        <p>
            Ingresa el correo asociado a tu cuenta.
        </p>



        <label>
            Correo electrónico
        </label>



        <input
                type="email"
                value="correo@ejemplo.com">



        <div class="error-message">

            <span class="error-icon">
                !
            </span>

            <span>
                El correo ingresado no se encuentra registrado.
            </span>

        </div>



        <button class="disabled-button" disabled>

            Enviar enlace

        </button>



        <a href="loginIndex.jsp">

            Volver al inicio de sesión

        </a>



    </div>


</div>


</body>


</html>