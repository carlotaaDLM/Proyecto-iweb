package dao;

import beans.Cliente;
import beans.Paginacion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/*
 * Administrador: CRUD de clientes (tabla CLIENTE).
 * Los clientes registrados aquí aparecen en la lista de clientes del
 * Capacity Planner (Registrar solicitud) y en las demás vistas que los muestran.
 * Solo se elimina un cliente que no tiene solicitudes ni servicios.
 */
public class ClienteDAO {

    private final String url = "jdbc:mysql://localhost:3306/mibasededatos";
    private final String user = "root";
    private final String pass = "root";

    private String ultimoError;

    private Connection conectar() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(url, user, pass);
    }

    public String getUltimoError() {
        return ultimoError;
    }


    private final String SQL_CLIENTE =
            "SELECT c.id_cliente, c.razon_social, c.ruc, c.correo, c.telefono, " +
                    "(SELECT COUNT(*) FROM SERVICIO s WHERE s.CLIENTE_id_cliente = c.id_cliente) AS servicios, " +
                    "(SELECT COUNT(*) FROM SOLICITUD_CAPACIDAD sc WHERE sc.CLIENTE_id_cliente = c.id_cliente) AS solicitudes " +
                    "FROM CLIENTE c ";

    private Cliente leerCliente(ResultSet rs) throws SQLException {
        Cliente c = new Cliente();
        c.setIdCliente(rs.getInt("id_cliente"));
        c.setRazonSocial(rs.getString("razon_social"));
        c.setRuc(rs.getString("ruc"));
        c.setCorreo(rs.getString("correo"));
        c.setTelefono(rs.getString("telefono"));
        c.setCantidadServicios(rs.getInt("servicios"));
        c.setCantidadSolicitudes(rs.getInt("solicitudes"));
        return c;
    }


    // buscar: razón social, RUC o correo | pag: null = todos
    public List<Cliente> listarClientes(String buscar, Paginacion pag) {

        List<Cliente> lista = new ArrayList<>();

        boolean hayBuscar = buscar != null && !buscar.trim().isEmpty();
        String sql = SQL_CLIENTE;
        if (hayBuscar) {
            sql += "WHERE c.razon_social LIKE ? OR c.ruc LIKE ? OR c.correo LIKE ? ";
        }
        sql += "ORDER BY c.razon_social";

        try (Connection conn = conectar()) {

            if (pag != null) {
                try (PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM (" + sql + ") AS t")) {
                    if (hayBuscar) {
                        for (int i = 1; i <= 3; i++) {
                            pstmt.setString(i, "%" + buscar.trim() + "%");
                        }
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
                if (hayBuscar) {
                    for (; i <= 3; i++) {
                        pstmt.setString(i, "%" + buscar.trim() + "%");
                    }
                }
                if (pag != null) {
                    pstmt.setInt(i++, pag.getInicio());
                    pstmt.setInt(i, pag.getTamanio());
                }
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        lista.add(leerCliente(rs));
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    public Cliente obtenerCliente(int idCliente) {

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(SQL_CLIENTE + "WHERE c.id_cliente = ?")) {

            pstmt.setInt(1, idCliente);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return leerCliente(rs);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return null;
    }


    // ¿Otro cliente (distinto de idExcluido) ya usa ese valor en la columna? (ruc o correo)
    public boolean existe(String columna, String valor, int idExcluido) {

        String sql = "SELECT COUNT(*) FROM CLIENTE WHERE " + ("ruc".equals(columna) ? "ruc" : "correo")
                + " = ? AND id_cliente <> ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, valor.trim());
            pstmt.setInt(2, idExcluido);
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            return false;
        }
    }


    // Devuelve el id del cliente nuevo, o null si falla
    public Integer crearCliente(String razonSocial, String ruc, String correo, String telefono) {

        String sql = "INSERT INTO CLIENTE (razon_social, ruc, correo, telefono) VALUES (?, ?, ?, ?)";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {

            pstmt.setString(1, razonSocial.trim());
            pstmt.setString(2, ruc.trim());
            pstmt.setString(3, correo.trim().toLowerCase());
            pstmt.setString(4, telefono == null || telefono.trim().isEmpty() ? null : telefono.trim());
            pstmt.executeUpdate();

            try (ResultSet rs = pstmt.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
        }

        return null;
    }


    public boolean actualizarCliente(int idCliente, String razonSocial, String ruc, String correo, String telefono) {

        String sql = "UPDATE CLIENTE SET razon_social = ?, ruc = ?, correo = ?, telefono = ? WHERE id_cliente = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, razonSocial.trim());
            pstmt.setString(2, ruc.trim());
            pstmt.setString(3, correo.trim().toLowerCase());
            pstmt.setString(4, telefono == null || telefono.trim().isEmpty() ? null : telefono.trim());
            pstmt.setInt(5, idCliente);
            return pstmt.executeUpdate() > 0;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }


    // Solo se elimina si el cliente no tiene solicitudes ni servicios
    public boolean borrarCliente(int idCliente) {

        Cliente c = obtenerCliente(idCliente);
        if (c == null || c.getCantidadServicios() > 0 || c.getCantidadSolicitudes() > 0) {
            return false;
        }

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement("DELETE FROM CLIENTE WHERE id_cliente = ?")) {

            pstmt.setInt(1, idCliente);
            return pstmt.executeUpdate() > 0;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }
}
