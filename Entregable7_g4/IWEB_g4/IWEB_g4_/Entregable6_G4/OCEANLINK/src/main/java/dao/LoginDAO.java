package dao;

import beans.Usuario;
import beans.Rol;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class LoginDAO {


    // ==========================================
    // VALIDAR LOGIN
    // ==========================================

    public Usuario validarLogin(String correo, String password) {

        Usuario usuario = null;

        String user = "root";
        String pass = "root";
        String url = "jdbc:mysql://localhost:3306/mibasededatos";


        try {

            Class.forName("com.mysql.cj.jdbc.Driver");


            try (Connection conn =
                         DriverManager.getConnection(url, user, pass)) {


                String sql =
                        "SELECT * FROM USUARIO " +
                                "WHERE correo = ? " +
                                "AND password = ? " +
                                "AND estado = 'Activo'";


                try (PreparedStatement pstmt =
                             conn.prepareStatement(sql)) {


                    pstmt.setString(1, correo);
                    pstmt.setString(2, password);


                    try (ResultSet rs =
                                 pstmt.executeQuery()) {


                        if (rs.next()) {

                            usuario = new Usuario();


                            usuario.setDniUsuario(
                                    rs.getInt("dni_usuario")
                            );


                            usuario.setNombre(
                                    rs.getString("nombre")
                            );


                            usuario.setApellido1(
                                    rs.getString("apellido_1")
                            );


                            usuario.setApellido2(
                                    rs.getString("apellido_2")
                            );


                            usuario.setCorreo(
                                    rs.getString("correo")
                            );


                            Rol rol = new Rol();


                            rol.setIdRol(
                                    rs.getInt("ROL_id_rol")
                            );


                            usuario.setRol(rol);


                            usuario.setEstado(
                                    rs.getString("estado")
                            );

                            // ¿Tiene foto de perfil? (se muestra en la barra superior)
                            usuario.setTieneFoto(
                                    rs.getBytes("foto") != null
                            );
                        }
                    }
                }
            }


        } catch (SQLException | ClassNotFoundException e) {

            e.printStackTrace();

        }


        return usuario;
    }


    // ==========================================
    // COMPROBAR SI EXISTE EL CORREO
    // ==========================================

    public boolean existeCorreo(String correo) {


        String user = "root";
        String pass = "root";
        String url = "jdbc:mysql://localhost:3306/mibasededatos";


        try {

            Class.forName("com.mysql.cj.jdbc.Driver");


            try (Connection conn =
                         DriverManager.getConnection(url, user, pass)) {


                String sql =
                        "SELECT * FROM USUARIO " +
                                "WHERE correo = ?";


                try (PreparedStatement pstmt =
                             conn.prepareStatement(sql)) {


                    pstmt.setString(1, correo);


                    try (ResultSet rs =
                                 pstmt.executeQuery()) {


                        return rs.next();
                    }
                }
            }


        } catch (SQLException | ClassNotFoundException e) {

            e.printStackTrace();

        }


        return false;
    }

}