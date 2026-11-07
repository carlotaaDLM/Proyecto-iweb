package dao;

import beans.Usuario;
import beans.Rol;
import beans.Paginacion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.PreparedStatement;
import java.util.ArrayList;

public class UsuarioDAO {

    private String ultimoError;

    // Mensaje del último error de la base de datos (para mostrarlo en la vista)
    public String getUltimoError() {
        return ultimoError;
    }

    private Connection conectar() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection("jdbc:mysql://localhost:3306/mibasededatos", "root", "root");
    }

    // ¿Ya existe un usuario con ese DNI?
    public boolean existeDni(int dni) {
        return obtenerUsuarioPorDni(dni) != null;
    }

    // ¿Otro usuario (distinto de dniExcluido) ya usa ese correo?
    public boolean existeCorreo(String correo, int dniExcluido) {
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT COUNT(*) FROM USUARIO WHERE correo = ? AND dni_usuario <> ?")) {
            pstmt.setString(1, correo.trim());
            pstmt.setInt(2, dniExcluido);
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            return false;
        }
    }

    // Registros que el usuario dejó en el sistema (solicitudes e historiales).
    // Si tiene alguno no se elimina: se desactiva, para no perder quién hizo cada cambio.
    public int contarRegistros(int dni) {
        String[] consultas = {
                "SELECT COUNT(*) FROM SOLICITUD_CAPACIDAD WHERE USUARIO_id_usuario = ?",
                "SELECT COUNT(*) FROM HIST_SOLICITUD WHERE USUARIO_dni_usuario = ?",
                "SELECT COUNT(*) FROM HIST_INCIDENCIA WHERE USUARIO_dni_usuario = ?",
                "SELECT COUNT(*) FROM HIST_MANTENIMIENTO WHERE USUARIO_dni_usuario = ?"
        };
        int total = 0;
        try (Connection conn = conectar()) {
            for (String sql : consultas) {
                try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                    pstmt.setInt(1, dni);
                    try (ResultSet rs = pstmt.executeQuery()) {
                        if (rs.next()) {
                            total += rs.getInt(1);
                        }
                    }
                } catch (SQLException e) {
                    // la columna aún no existe en esta BD: no cuenta
                }
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return total;
    }

    // Cantidad de usuarios (todos o por estado) para las tarjetas de la gestión de usuarios
    public int contarUsuarios(String estado) {
        String sql = "SELECT COUNT(*) FROM USUARIO" + (estado == null ? "" : " WHERE estado = ?");
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            if (estado != null) {
                pstmt.setString(1, estado);
            }
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            return 0;
        }
    }

    public ArrayList<Usuario> obtenerListaUsuarios() {
        return obtenerListaUsuarios(null, null, null, null);
    }


    /*
     * Lista de usuarios con los filtros de la vista Gestión de usuarios.
     * buscar: nombre, apellidos, DNI o correo | rol: id del rol | estado: Activo o Inactivo
     * pag: null = todos; si no, primero se cuenta el total y luego se usa LIMIT ?, ?
     */
    public ArrayList<Usuario> obtenerListaUsuarios(String buscar, String rol, String estado, Paginacion pag) {

        ArrayList<Usuario> listaUsuarios = new ArrayList<>();

        String user = "root";
        String pass = "root";
        String url = "jdbc:mysql://localhost:3306/mibasededatos";

        String sql = "SELECT * FROM USUARIO WHERE 1 = 1 ";
        ArrayList<String> params = new ArrayList<>();

        if (buscar != null && !buscar.trim().isEmpty()) {
            sql += "AND (nombre LIKE ? OR apellido_1 LIKE ? OR apellido_2 LIKE ? " +
                    "OR CAST(dni_usuario AS CHAR) LIKE ? OR correo LIKE ?) ";
            for (int k = 0; k < 5; k++) {
                params.add("%" + buscar.trim() + "%");
            }
        }
        if (rol != null && !rol.isEmpty()) {
            sql += "AND ROL_id_rol = ? ";
            params.add(rol);
        }
        if (estado != null && !estado.isEmpty()) {
            sql += "AND estado = ? ";
            params.add(estado);
        }
        sql += "ORDER BY nombre, apellido_1";

        try {

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(url, user, pass)) {

                // Paginación: total de usuarios con los mismos filtros
                if (pag != null) {
                    try (PreparedStatement pstmt =
                                 conn.prepareStatement("SELECT COUNT(*) FROM (" + sql + ") AS t")) {
                        for (int i = 0; i < params.size(); i++) {
                            pstmt.setString(i + 1, params.get(i));
                        }
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next()) {
                                pag.setTotalRegistros(rs.getInt(1));
                            }
                        }
                    }
                    sql += " LIMIT ?, ?";
                }

                try (PreparedStatement pstmt = conn.prepareStatement(sql)) {

                    int i = 1;
                    for (String p : params) {
                        pstmt.setString(i++, p);
                    }
                    if (pag != null) {
                        pstmt.setInt(i++, pag.getInicio());
                        pstmt.setInt(i, pag.getTamanio());
                    }

                    try (ResultSet rs = pstmt.executeQuery()) {

                        while (rs.next()) {

                            Usuario usuario = new Usuario();
                            Rol rolUsuario = new Rol();

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

                            rolUsuario.setIdRol(
                                    rs.getInt("ROL_id_rol")
                            );

                            usuario.setRol(rolUsuario);

                            usuario.setEstado(
                                    rs.getString("estado")
                            );

                            listaUsuarios.add(usuario);
                        }
                    }
                }
            }

        } catch (ClassNotFoundException | SQLException e) {

            e.printStackTrace();
        }

        return listaUsuarios;
    }


    public Usuario obtenerUsuarioPorDni(int dni) {

        Usuario usuario = null;

        try {

            String user = "root";
            String pass = "root";
            String url = "jdbc:mysql://localhost:3306/mibasededatos";

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn =
                         DriverManager.getConnection(url, user, pass)) {

                String sql =
                        "SELECT * FROM USUARIO WHERE dni_usuario = ?";

                try (PreparedStatement pstmt =
                             conn.prepareStatement(sql)) {

                    pstmt.setInt(1, dni);

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
                        }
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {

            e.printStackTrace();
        }

        return usuario;
    }


    public boolean actualizarUsuario(
            String dni,
            String nombre,
            String apellido1,
            String apellido2,
            String correo,
            int rolId) {

        try {

            String user = "root";
            String pass = "root";
            String url = "jdbc:mysql://localhost:3306/mibasededatos";

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn =
                         DriverManager.getConnection(url, user, pass)) {

                String sql =
                        "UPDATE USUARIO SET " +
                                "nombre = ?, " +
                                "apellido_1 = ?, " +
                                "apellido_2 = ?, " +
                                "correo = ?, " +
                                "ROL_id_rol = ? " +
                                "WHERE dni_usuario = ?";

                try (PreparedStatement pstmt =
                             conn.prepareStatement(sql)) {

                    pstmt.setString(1, nombre);
                    pstmt.setString(2, apellido1);
                    pstmt.setString(3, apellido2);
                    pstmt.setString(4, correo);

                    pstmt.setInt(5, rolId);

                    pstmt.setInt(
                            6,
                            Integer.parseInt(dni)
                    );

                    return pstmt.executeUpdate() > 0;
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }


    public boolean crearUsuario(
            int dni,
            String nombre,
            String apellido1,
            String apellido2,
            String correo,
            String password,
            int rolId) {

        try {

            String user = "root";
            String pass = "root";
            String url = "jdbc:mysql://localhost:3306/mibasededatos";

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn =
                         DriverManager.getConnection(url, user, pass)) {

                String sql =
                        "INSERT INTO USUARIO " +
                                "(dni_usuario, nombre, apellido_1, apellido_2, " +
                                "correo, password, estado, ROL_id_rol) " +
                                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

                try (PreparedStatement pstmt =
                             conn.prepareStatement(sql)) {

                    pstmt.setInt(1, dni);

                    pstmt.setString(2, nombre);

                    pstmt.setString(3, apellido1);

                    pstmt.setString(4, apellido2);

                    pstmt.setString(5, correo);

                    pstmt.setString(6, password);

                    pstmt.setString(7, "Activo");

                    pstmt.setInt(8, rolId);

                    return pstmt.executeUpdate() > 0;
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }


    public boolean borrarUsuario(int dni) {

        try {

            String user = "root";
            String pass = "root";
            String url = "jdbc:mysql://localhost:3306/mibasededatos";

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn =
                         DriverManager.getConnection(url, user, pass)) {

                String sql =
                        "DELETE FROM USUARIO WHERE dni_usuario = ?";

                try (PreparedStatement pstmt =
                             conn.prepareStatement(sql)) {

                    pstmt.setInt(1, dni);

                    return pstmt.executeUpdate() > 0;
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }


    public boolean cambiarEstadoUsuario(int dni) {

        try {

            String user = "root";
            String pass = "root";
            String url = "jdbc:mysql://localhost:3306/mibasededatos";

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn =
                         DriverManager.getConnection(url, user, pass)) {

                String sql =
                        "UPDATE USUARIO " +
                                "SET estado = CASE " +
                                "WHEN estado = 'Activo' THEN 'Inactivo' " +
                                "ELSE 'Activo' " +
                                "END " +
                                "WHERE dni_usuario = ?";

                try (PreparedStatement pstmt =
                             conn.prepareStatement(sql)) {

                    pstmt.setInt(1, dni);

                    return pstmt.executeUpdate() > 0;
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }


    // =====================================================
    // PERFIL (cada usuario edita sus propios datos y su foto)
    // =====================================================

    // Agrega las columnas de la foto si la BD todavía no las tiene (una sola vez al iniciar)
    public void prepararTablas() {

        String sql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " +
                "WHERE TABLE_SCHEMA = DATABASE() AND UPPER(TABLE_NAME) = 'USUARIO' " +
                "AND UPPER(COLUMN_NAME) = 'FOTO'";

        try (Connection conn = conectar();
             Statement stmt = conn.createStatement()) {

            try (ResultSet rs = stmt.executeQuery(sql)) {
                if (rs.next() && rs.getInt(1) > 0) {
                    return;
                }
            }
            stmt.executeUpdate("ALTER TABLE USUARIO " +
                    "ADD COLUMN foto MEDIUMBLOB NULL, " +
                    "ADD COLUMN foto_tipo VARCHAR(50) NULL");

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }


    public boolean tieneFoto(int dni) {

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT COUNT(*) FROM USUARIO WHERE dni_usuario = ? AND foto IS NOT NULL")) {

            pstmt.setInt(1, dni);
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            return false;
        }
    }


    public byte[] obtenerFoto(int dni) {

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT foto FROM USUARIO WHERE dni_usuario = ?")) {

            pstmt.setInt(1, dni);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getBytes("foto");
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }


    public String obtenerTipoFoto(int dni) {

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT foto_tipo FROM USUARIO WHERE dni_usuario = ?")) {

            pstmt.setInt(1, dni);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("foto_tipo");
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }


    // Datos que el usuario puede cambiar en su perfil (no cambia su rol ni su estado)
    public boolean actualizarPerfil(int dni, String nombre, String apellido1, String apellido2, String correo) {

        String sql = "UPDATE USUARIO SET nombre = ?, apellido_1 = ?, apellido_2 = ?, correo = ? " +
                "WHERE dni_usuario = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, nombre);
            pstmt.setString(2, apellido1);
            pstmt.setString(3, apellido2);
            pstmt.setString(4, correo);
            pstmt.setInt(5, dni);
            return pstmt.executeUpdate() > 0;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }


    // foto = null quita la foto
    public boolean guardarFoto(int dni, byte[] foto, String tipo) {

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "UPDATE USUARIO SET foto = ?, foto_tipo = ? WHERE dni_usuario = ?")) {

            pstmt.setBytes(1, foto);
            pstmt.setString(2, tipo);
            pstmt.setInt(3, dni);
            return pstmt.executeUpdate() > 0;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }
}
