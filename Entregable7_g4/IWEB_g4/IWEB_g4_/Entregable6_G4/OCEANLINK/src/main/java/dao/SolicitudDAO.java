package dao;

import beans.HistorialSolicitud;
import beans.Paginacion;
import beans.Ruta;
import beans.Segmento;
import beans.SolicitudCapacidad;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;


public class SolicitudDAO {

    private final String url = "jdbc:mysql://localhost:3306/mibasededatos";
    private final String user = "root";
    private final String pass = "root";


    public static final String[] FLUJO = {
            "Registrada",
            "En evaluación",
            "Aprobada",
            "Provisionada",
            "Activa"
    };


    private String ultimoError;

    public String getUltimoError() {
        return ultimoError;
    }


    private Connection conectar() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(url, user, pass);
    }




    public void prepararTablas() {

        String sqlExiste =
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " +
                        "WHERE TABLE_SCHEMA = DATABASE() " +
                        "AND UPPER(TABLE_NAME) = 'SOLICITUD_CAPACIDAD' " +
                        "AND UPPER(COLUMN_NAME) = 'CLIENTE_ID_CLIENTE'";

        try (Connection conn = conectar();
             Statement stmt = conn.createStatement()) {

            try (ResultSet rs = stmt.executeQuery(sqlExiste)) {
                if (rs.next() && rs.getInt(1) > 0) {
                    return; // ya está ajustada
                }
            }


            stmt.executeUpdate(
                    "ALTER TABLE SOLICITUD_CAPACIDAD " +
                            "ADD COLUMN CLIENTE_id_cliente INT NULL, " +
                            "ADD COLUMN LANDING_STATION_id_origen VARCHAR(10) NULL, " +
                            "ADD COLUMN LANDING_STATION_id_destino VARCHAR(10) NULL, " +
                            "MODIFY COLUMN id_ruta_propuesta INT NULL, " +
                            "MODIFY COLUMN estado VARCHAR(50) NOT NULL, " +
                            "MODIFY COLUMN observaciones VARCHAR(255) NULL");


            int[][] clientes = {
                    {1, 7}, {2, 1}, {3, 4}, {4, 2}, {5, 4}, {6, 5}, {7, 8}, {8, 6},
                    {9, 11}, {10, 10}, {11, 15}, {12, 13}, {13, 14}, {14, 12}, {15, 9}
            };
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE SOLICITUD_CAPACIDAD SET CLIENTE_id_cliente = ? WHERE id_solicitud = ?")) {
                for (int[] c : clientes) {
                    pstmt.setInt(1, c[1]);
                    pstmt.setInt(2, c[0]);
                    pstmt.executeUpdate();
                }
            }
            stmt.executeUpdate(
                    "UPDATE SOLICITUD_CAPACIDAD SET CLIENTE_id_cliente = " +
                            "(SELECT MIN(id_cliente) FROM CLIENTE) WHERE CLIENTE_id_cliente IS NULL");


            stmt.executeUpdate(
                    "UPDATE SOLICITUD_CAPACIDAD sc SET " +
                            "LANDING_STATION_id_origen = (SELECT seg.LANDING_STATION_id_origen " +
                            "  FROM RUTA_has_SEGMENTO rhs INNER JOIN SEGMENTO seg " +
                            "  ON seg.codigo_segmento = rhs.SEGMENTO_codigo_segmento " +
                            "  WHERE rhs.RUTA_id_ruta = sc.id_ruta_propuesta ORDER BY rhs.orden ASC LIMIT 1), " +
                            "LANDING_STATION_id_destino = (SELECT seg.LANDING_STATION_id_destino " +
                            "  FROM RUTA_has_SEGMENTO rhs INNER JOIN SEGMENTO seg " +
                            "  ON seg.codigo_segmento = rhs.SEGMENTO_codigo_segmento " +
                            "  WHERE rhs.RUTA_id_ruta = sc.id_ruta_propuesta ORDER BY rhs.orden DESC LIMIT 1)");


            stmt.executeUpdate(
                    "UPDATE SOLICITUD_CAPACIDAD SET id_ruta_propuesta = NULL WHERE estado = 'Registrada'");

            stmt.executeUpdate(
                    "ALTER TABLE SOLICITUD_CAPACIDAD " +
                            "MODIFY COLUMN CLIENTE_id_cliente INT NOT NULL, " +
                            "MODIFY COLUMN LANDING_STATION_id_origen VARCHAR(10) NOT NULL, " +
                            "MODIFY COLUMN LANDING_STATION_id_destino VARCHAR(10) NOT NULL, " +
                            "ADD CONSTRAINT fk_SOLICITUD_CLIENTE FOREIGN KEY (CLIENTE_id_cliente) " +
                            "  REFERENCES CLIENTE (id_cliente), " +
                            "ADD CONSTRAINT fk_SOLICITUD_ORIGEN FOREIGN KEY (LANDING_STATION_id_origen) " +
                            "  REFERENCES LANDING_STATION (id_landing), " +
                            "ADD CONSTRAINT fk_SOLICITUD_DESTINO FOREIGN KEY (LANDING_STATION_id_destino) " +
                            "  REFERENCES LANDING_STATION (id_landing), " +
                            "ADD CONSTRAINT fk_SOLICITUD_RUTA FOREIGN KEY (id_ruta_propuesta) " +
                            "  REFERENCES RUTA (id_ruta)");


            stmt.executeUpdate(
                    "ALTER TABLE HIST_SOLICITUD " +
                            "ADD COLUMN SOLICITUD_id_solicitud INT NULL, " +
                            "ADD COLUMN observacion VARCHAR(500) NULL, " +
                            "ADD COLUMN USUARIO_dni_usuario INT NULL");


            stmt.executeUpdate(
                    "UPDATE HIST_SOLICITUD h INNER JOIN (" +
                            "  SELECT DISTINCT sc.id_solicitud, sc.USUARIO_id_usuario AS dni, " +
                            "  sc.HIST_SOLICITUD_id_historial AS fin, " +
                            "  (SELECT MAX(h2.id_historial) FROM HIST_SOLICITUD h2 " +
                            "   WHERE h2.estado = 'Registrada' " +
                            "   AND h2.id_historial <= sc.HIST_SOLICITUD_id_historial) AS inicio " +
                            "  FROM SOLICITUD_CAPACIDAD sc) r " +
                            "ON h.id_historial BETWEEN r.inicio AND r.fin " +
                            "SET h.SOLICITUD_id_solicitud = r.id_solicitud, h.USUARIO_dni_usuario = r.dni, " +
                            "h.observacion = IF(h.estado = 'Registrada', 'Solicitud registrada.', h.observacion)");


            stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS RESERVA_CAPACIDAD (" +
                            "id_reserva INT NOT NULL AUTO_INCREMENT, " +
                            "SOLICITUD_id_solicitud INT NOT NULL, " +
                            "SEGMENTO_codigo_segmento VARCHAR(12) NOT NULL, " +
                            "capacidad DECIMAL(10,2) NOT NULL, " +
                            "fecha DATETIME NOT NULL, " +
                            "estado VARCHAR(20) NOT NULL, " +   // Reservada / Utilizada / Liberada
                            "PRIMARY KEY (id_reserva), " +
                            "CONSTRAINT fk_RESERVA_SOLICITUD FOREIGN KEY (SOLICITUD_id_solicitud) " +
                            "  REFERENCES SOLICITUD_CAPACIDAD (id_solicitud), " +
                            "CONSTRAINT fk_RESERVA_SEGMENTO FOREIGN KEY (SEGMENTO_codigo_segmento) " +
                            "  REFERENCES SEGMENTO (codigo_segmento)) ENGINE = InnoDB");


            stmt.executeUpdate(
                    "INSERT INTO RESERVA_CAPACIDAD (SOLICITUD_id_solicitud, SEGMENTO_codigo_segmento, " +
                            "capacidad, fecha, estado) " +
                            "SELECT 3, rhs.SEGMENTO_codigo_segmento, 800.00, '2026-09-17 10:00:00', 'Reservada' " +
                            "FROM RUTA_has_SEGMENTO rhs " +
                            "INNER JOIN SOLICITUD_CAPACIDAD sc ON sc.id_ruta_propuesta = rhs.RUTA_id_ruta " +
                            "INNER JOIN SEGMENTO seg ON seg.codigo_segmento = rhs.SEGMENTO_codigo_segmento " +
                            "WHERE sc.id_solicitud = 3 AND sc.estado = 'Aprobada' " +
                            "AND sc.capacidad_requerida = 800 AND seg.capacidad_reservada >= 800");


            stmt.executeUpdate(
                    "ALTER TABLE SERVICIO ADD COLUMN SOLICITUD_id_solicitud INT NULL, " +
                            "ADD CONSTRAINT fk_SERVICIO_SOLICITUD FOREIGN KEY (SOLICITUD_id_solicitud) " +
                            "  REFERENCES SOLICITUD_CAPACIDAD (id_solicitud)");


            stmt.executeUpdate(
                    "ALTER TABLE UTILIZACION_HIST ADD COLUMN SEGMENTO_codigo_segmento VARCHAR(12) NULL");
            stmt.executeUpdate(
                    "UPDATE UTILIZACION_HIST u INNER JOIN SEGMENTO seg " +
                            "ON u.id_registro BETWEEN seg.UTILIZACION_HIST_id_registro - 5 " +
                            "AND seg.UTILIZACION_HIST_id_registro " +
                            "SET u.SEGMENTO_codigo_segmento = seg.codigo_segmento");
            stmt.executeUpdate(
                    "ALTER TABLE SEGMENTO MODIFY COLUMN UTILIZACION_HIST_id_registro INT NULL");


            stmt.executeUpdate("SET FOREIGN_KEY_CHECKS = 0");
            stmt.executeUpdate(
                    "ALTER TABLE RUTA_has_SEGMENTO MODIFY COLUMN SEGMENTO_codigo_segmento VARCHAR(12) NOT NULL");
            stmt.executeUpdate("SET FOREIGN_KEY_CHECKS = 1");

            System.out.println("OCEANLINK - BD ajustada para el Capacity Planner");

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }


    public static String siguienteEstado(String estadoActual) {
        for (int i = 0; i < FLUJO.length - 1; i++) {
            if (FLUJO[i].equals(estadoActual)) {
                return FLUJO[i + 1];
            }
        }
        return null;
    }


    private final String SQL_SOLICITUD =
            "SELECT sc.id_solicitud, sc.CLIENTE_id_cliente, c.razon_social, " +
                    "sc.LANDING_STATION_id_origen, o.nombre AS nombre_origen, " +
                    "sc.LANDING_STATION_id_destino, d.nombre AS nombre_destino, " +
                    "sc.id_ruta_propuesta, r.codigo AS codigo_ruta, " +
                    "sc.capacidad_requerida, sc.estado, sc.fecha_solicitud, sc.fecha_requerida, " +
                    "sc.observaciones, sc.USUARIO_id_usuario, " +
                    "CONCAT(u.nombre, ' ', u.apellido_1) AS nombre_usuario, " +
                    "(SELECT MIN(s.id_servicio) FROM SERVICIO s " +
                    " WHERE s.SOLICITUD_id_solicitud = sc.id_solicitud) AS id_servicio, " +
                    "(SELECT COALESCE(MIN(rc.capacidad), 0) FROM RESERVA_CAPACIDAD rc " +
                    " WHERE rc.SOLICITUD_id_solicitud = sc.id_solicitud " +
                    " AND rc.estado = 'Reservada') AS capacidad_reservada " +
                    "FROM SOLICITUD_CAPACIDAD sc " +
                    "INNER JOIN CLIENTE c ON sc.CLIENTE_id_cliente = c.id_cliente " +
                    "INNER JOIN LANDING_STATION o ON sc.LANDING_STATION_id_origen = o.id_landing " +
                    "INNER JOIN LANDING_STATION d ON sc.LANDING_STATION_id_destino = d.id_landing " +
                    "LEFT JOIN RUTA r ON sc.id_ruta_propuesta = r.id_ruta " +
                    "LEFT JOIN USUARIO u ON sc.USUARIO_id_usuario = u.dni_usuario ";


    private SolicitudCapacidad leerSolicitud(ResultSet rs) throws SQLException {

        SolicitudCapacidad s = new SolicitudCapacidad();

        s.setIdSolicitud(rs.getInt("id_solicitud"));
        s.setIdCliente(rs.getInt("CLIENTE_id_cliente"));
        s.setRazonSocialCliente(rs.getString("razon_social"));
        s.setIdOrigen(rs.getString("LANDING_STATION_id_origen"));
        s.setNombreOrigen(rs.getString("nombre_origen"));
        s.setIdDestino(rs.getString("LANDING_STATION_id_destino"));
        s.setNombreDestino(rs.getString("nombre_destino"));

        int idRuta = rs.getInt("id_ruta_propuesta");
        s.setIdRuta(rs.wasNull() ? null : idRuta);
        s.setCodigoRuta(rs.getString("codigo_ruta"));

        s.setCapacidadRequerida(rs.getDouble("capacidad_requerida"));
        s.setEstado(rs.getString("estado"));
        s.setFechaSolicitud(rs.getString("fecha_solicitud"));
        s.setFechaRequerida(rs.getString("fecha_requerida"));
        s.setObservaciones(rs.getString("observaciones"));
        s.setDniUsuario(rs.getInt("USUARIO_id_usuario"));
        s.setNombreUsuario(rs.getString("nombre_usuario"));

        int idServicio = rs.getInt("id_servicio");
        s.setIdServicio(rs.wasNull() ? null : idServicio);
        s.setCapacidadReservada(rs.getDouble("capacidad_reservada"));

        return s;
    }



    public List<SolicitudCapacidad> listarSolicitudes(String buscar, String estado) {
        return listarSolicitudes(buscar, estado, null);
    }


    // pag: null = todas las solicitudes; si no, solo las de la página (LIMIT ?, ?)
    public List<SolicitudCapacidad> listarSolicitudes(String buscar, String estado, Paginacion pag) {

        List<SolicitudCapacidad> lista = new ArrayList<>();

        String sql = SQL_SOLICITUD + "WHERE 1 = 1 ";

        boolean hayBuscar = buscar != null && !buscar.trim().isEmpty();
        boolean hayEstado = estado != null && !estado.isEmpty();

        if (hayBuscar) {
            sql += "AND (CONCAT('SOL-', LPAD(sc.id_solicitud, 3, '0')) LIKE ? " +
                    "OR c.razon_social LIKE ? OR r.codigo LIKE ? " +
                    "OR o.nombre LIKE ? OR d.nombre LIKE ?) ";
        }
        if (hayEstado) {
            sql += "AND sc.estado = ? ";
        }
        sql += "ORDER BY sc.fecha_solicitud DESC, sc.id_solicitud DESC";

        try (Connection conn = conectar()) {

            // Paginación: primero se cuenta el total y luego se piden solo las filas de la página
            if (pag != null) {
                try (PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM (" + sql + ") AS t")) {
                    asignarFiltrosSolicitud(pstmt, buscar, estado);
                    try (ResultSet rs = pstmt.executeQuery()) {
                        if (rs.next()) {
                            pag.setTotalRegistros(rs.getInt(1));
                        }
                    }
                }
                sql += " LIMIT ?, ?";
            }

            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {

                int i = asignarFiltrosSolicitud(pstmt, buscar, estado);
                if (pag != null) {
                    pstmt.setInt(i++, pag.getInicio());
                    pstmt.setInt(i, pag.getTamanio());
                }

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        lista.add(leerSolicitud(rs));
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // Asigna los parámetros de buscar y estado; devuelve la posición del siguiente parámetro
    private int asignarFiltrosSolicitud(PreparedStatement pstmt, String buscar, String estado) throws SQLException {
        int i = 1;
        if (buscar != null && !buscar.trim().isEmpty()) {
            String patron = "%" + buscar.trim() + "%";
            for (int k = 0; k < 5; k++) {
                pstmt.setString(i++, patron);
            }
        }
        if (estado != null && !estado.isEmpty()) {
            pstmt.setString(i++, estado);
        }
        return i;
    }


    public List<SolicitudCapacidad> listarPorReservar() {

        List<SolicitudCapacidad> lista = new ArrayList<>();
        for (SolicitudCapacidad s : listarSolicitudes(null, "Aprobada")) {
            if (!s.isReservada()) {
                lista.add(s);
            }
        }
        return lista;
    }


    public int contarPorEstado(String... estados) {

        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM SOLICITUD_CAPACIDAD WHERE estado IN (");
        for (int i = 0; i < estados.length; i++) {
            sql.append(i == 0 ? "?" : ", ?");
        }
        sql.append(")");

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < estados.length; i++) {
                pstmt.setString(i + 1, estados[i]);
            }

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return 0;
    }


    public SolicitudCapacidad obtenerSolicitud(int idSolicitud) {

        String sql = SQL_SOLICITUD + "WHERE sc.id_solicitud = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, idSolicitud);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return leerSolicitud(rs);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return null;
    }


    public List<HistorialSolicitud> listarHistorial(int idSolicitud) {

        List<HistorialSolicitud> lista = new ArrayList<>();

        String sql =
                "SELECT h.id_historial, h.estado, h.fecha, h.observacion, " +
                        "CONCAT(u.nombre, ' ', u.apellido_1) AS nombre_usuario " +
                        "FROM HIST_SOLICITUD h " +
                        "LEFT JOIN USUARIO u ON h.USUARIO_dni_usuario = u.dni_usuario " +
                        "WHERE h.SOLICITUD_id_solicitud = ? " +
                        "ORDER BY h.fecha ASC, h.id_historial ASC";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, idSolicitud);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    HistorialSolicitud h = new HistorialSolicitud();
                    h.setIdHistorial(rs.getInt("id_historial"));
                    h.setIdSolicitud(idSolicitud);
                    h.setEstado(rs.getString("estado"));
                    h.setFecha(rs.getString("fecha"));
                    h.setObservacion(rs.getString("observacion"));
                    h.setNombreUsuario(rs.getString("nombre_usuario"));
                    lista.add(h);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    private int insertarHistorial(Connection conn, Integer idSolicitud, String estado,
                                  String observacion, Integer dniUsuario) throws SQLException {

        String sql =
                "INSERT INTO HIST_SOLICITUD (estado, fecha, SOLICITUD_id_solicitud, " +
                        "observacion, USUARIO_dni_usuario) VALUES (?, NOW(), ?, ?, ?)";

        try (PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            pstmt.setString(1, estado);
            if (idSolicitud == null) {
                pstmt.setNull(2, Types.INTEGER);
            } else {
                pstmt.setInt(2, idSolicitud);
            }
            pstmt.setString(3, observacion);
            if (dniUsuario == null) {
                pstmt.setNull(4, Types.INTEGER);
            } else {
                pstmt.setInt(4, dniUsuario);
            }
            pstmt.executeUpdate();

            try (ResultSet rs = pstmt.getGeneratedKeys()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }


    private void cambiarEstado(Connection conn, int idSolicitud, String estado,
                               String observacion, Integer dniUsuario) throws SQLException {

        int idHistorial = insertarHistorial(conn, idSolicitud, estado, observacion, dniUsuario);

        try (PreparedStatement pstmt = conn.prepareStatement(
                "UPDATE SOLICITUD_CAPACIDAD SET estado = ?, HIST_SOLICITUD_id_historial = ? " +
                        "WHERE id_solicitud = ?")) {
            pstmt.setString(1, estado);
            pstmt.setInt(2, idHistorial);
            pstmt.setInt(3, idSolicitud);
            pstmt.executeUpdate();
        }
    }


    public Integer crearSolicitud(int idCliente, String idOrigen, String idDestino,
                                  double capacidad, String fechaRequerida,
                                  String observaciones, Integer dniUsuario) {

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            // 1. Primer estado del historial (luego se enlaza con la solicitud)
            int idHistorial = insertarHistorial(conn, null, "Registrada",
                    "Solicitud registrada.", dniUsuario);

            // 2. La solicitud, sin ruta (se calcula al evaluar)
            String sql =
                    "INSERT INTO SOLICITUD_CAPACIDAD (id_ruta_propuesta, capacidad_requerida, estado, " +
                            "fecha_solicitud, HIST_SOLICITUD_id_historial, USUARIO_id_usuario, " +
                            "fecha_requerida, observaciones, CLIENTE_id_cliente, " +
                            "LANDING_STATION_id_origen, LANDING_STATION_id_destino) " +
                            "VALUES (NULL, ?, 'Registrada', CURDATE(), ?, ?, ?, ?, ?, ?, ?)";

            int idSolicitud;

            try (PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                pstmt.setDouble(1, capacidad);
                pstmt.setInt(2, idHistorial);
                pstmt.setInt(3, dniUsuario == null ? 0 : dniUsuario);
                pstmt.setString(4, fechaRequerida);
                pstmt.setString(5, observaciones);
                pstmt.setInt(6, idCliente);
                pstmt.setString(7, idOrigen);
                pstmt.setString(8, idDestino);
                pstmt.executeUpdate();

                try (ResultSet rs = pstmt.getGeneratedKeys()) {
                    rs.next();
                    idSolicitud = rs.getInt(1);
                }
            }

            // Si antes existió otra solicitud con este mismo número (se borró desde la BD),
            // su historial y sus reservas quedaron sueltos: se limpian para no mezclarlos.
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM HIST_SOLICITUD WHERE SOLICITUD_id_solicitud = ? AND id_historial <> ?")) {
                pstmt.setInt(1, idSolicitud);
                pstmt.setInt(2, idHistorial);
                pstmt.executeUpdate();
            }
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM RESERVA_CAPACIDAD WHERE SOLICITUD_id_solicitud = ?")) {
                pstmt.setInt(1, idSolicitud);
                pstmt.executeUpdate();
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE HIST_SOLICITUD SET SOLICITUD_id_solicitud = ? WHERE id_historial = ?")) {
                pstmt.setInt(1, idSolicitud);
                pstmt.setInt(2, idHistorial);
                pstmt.executeUpdate();
            }

            conn.commit();
            return idSolicitud;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            rollback(conn);
        } finally {
            cerrar(conn);
        }

        return null;
    }


    public boolean actualizarSolicitud(int idSolicitud, int idCliente, String idOrigen,
                                       String idDestino, double capacidad,
                                       String fechaRequerida, String observaciones) {

        String sql =
                "UPDATE SOLICITUD_CAPACIDAD SET CLIENTE_id_cliente = ?, " +
                        "LANDING_STATION_id_origen = ?, LANDING_STATION_id_destino = ?, " +
                        "capacidad_requerida = ?, fecha_requerida = ?, observaciones = ? " +
                        "WHERE id_solicitud = ? AND estado = 'Registrada'";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, idCliente);
            pstmt.setString(2, idOrigen);
            pstmt.setString(3, idDestino);
            pstmt.setDouble(4, capacidad);
            pstmt.setString(5, fechaRequerida);
            pstmt.setString(6, observaciones);
            pstmt.setInt(7, idSolicitud);

            return pstmt.executeUpdate() > 0;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
        }

        return false;
    }


    public boolean borrarSolicitud(int idSolicitud) {

        SolicitudCapacidad s = obtenerSolicitud(idSolicitud);

        if (s == null || !("Registrada".equals(s.getEstado()) || "Rechazada".equals(s.getEstado()))
                || s.getIdServicio() != null) {
            return false;
        }

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM RESERVA_CAPACIDAD WHERE SOLICITUD_id_solicitud = ? AND estado <> 'Reservada'")) {
                pstmt.setInt(1, idSolicitud);
                pstmt.executeUpdate();
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM SOLICITUD_CAPACIDAD WHERE id_solicitud = ?")) {
                pstmt.setInt(1, idSolicitud);
                pstmt.executeUpdate();
            }

            // Después de la solicitud, porque ella apunta a su último cambio
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM HIST_SOLICITUD WHERE SOLICITUD_id_solicitud = ?")) {
                pstmt.setInt(1, idSolicitud);
                pstmt.executeUpdate();
            }

            conn.commit();
            return true;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            rollback(conn);
        } finally {
            cerrar(conn);
        }

        return false;
    }


    public void iniciarEvaluacion(int idSolicitud, Ruta ruta, Integer dniUsuario) {

        String observacion = ruta == null
                ? "No hay una ruta activa que una el origen con el destino."
                : "Ruta propuesta por el sistema: " + ruta.getCodigo() + " ("
                + String.format(java.util.Locale.US, "%.0f", ruta.getCapacidadDisponible())
                + " Gbps disponibles).";

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE SOLICITUD_CAPACIDAD SET id_ruta_propuesta = ? WHERE id_solicitud = ?")) {
                if (ruta == null) {
                    pstmt.setNull(1, Types.INTEGER);
                } else {
                    pstmt.setInt(1, ruta.getIdRuta());
                }
                pstmt.setInt(2, idSolicitud);
                pstmt.executeUpdate();
            }

            cambiarEstado(conn, idSolicitud, "En evaluación", observacion, dniUsuario);

            conn.commit();

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            rollback(conn);
        } finally {
            cerrar(conn);
        }
    }


    public void registrarDecision(int idSolicitud, String estado, String observacion,
                                  Integer dniUsuario) {

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            cambiarEstado(conn, idSolicitud, estado, observacion, dniUsuario);

            conn.commit();

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            rollback(conn);
        } finally {
            cerrar(conn);
        }
    }


    public String reservarCapacidad(int idSolicitud, Integer dniUsuario) {

        SolicitudCapacidad s = obtenerSolicitud(idSolicitud);

        if (s == null || !"Aprobada".equals(s.getEstado())) {
            return "Solo se puede reservar capacidad para una solicitud Aprobada.";
        }
        if (s.isReservada()) {
            return s.getCodigo() + " ya tiene su capacidad reservada.";
        }
        if (s.getIdRuta() == null) {
            return s.getCodigo() + " no tiene una ruta asignada.";
        }

        double capacidad = s.getCapacidadRequerida();

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            // Se bloquean los segmentos de la ruta mientras se valida (FOR UPDATE)
            List<String> codigos = new ArrayList<>();

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "SELECT seg.codigo_segmento, seg.estado, " +
                            "seg.capacidad_total - seg.capacidad_utilizada - seg.capacidad_reservada AS disponible " +
                            "FROM RUTA_has_SEGMENTO rhs " +
                            "INNER JOIN SEGMENTO seg ON seg.codigo_segmento = rhs.SEGMENTO_codigo_segmento " +
                            "WHERE rhs.RUTA_id_ruta = ? ORDER BY rhs.orden FOR UPDATE")) {

                pstmt.setInt(1, s.getIdRuta());

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        if ("Fuera de servicio".equals(rs.getString("estado"))) {
                            conn.rollback();
                            return rs.getString("codigo_segmento") + " está Fuera de servicio.";
                        }
                        if (rs.getDouble("disponible") < capacidad) {
                            conn.rollback();
                            return rs.getString("codigo_segmento") + " solo tiene "
                                    + String.format(java.util.Locale.US, "%.0f", rs.getDouble("disponible"))
                                    + " Gbps disponibles y se piden "
                                    + String.format(java.util.Locale.US, "%.0f", capacidad) + " Gbps.";
                        }
                        codigos.add(rs.getString("codigo_segmento"));
                    }
                }
            }

            try (PreparedStatement psReserva = conn.prepareStatement(
                    "INSERT INTO RESERVA_CAPACIDAD (SOLICITUD_id_solicitud, SEGMENTO_codigo_segmento, " +
                            "capacidad, fecha, estado) VALUES (?, ?, ?, NOW(), 'Reservada')");
                 PreparedStatement psSegmento = conn.prepareStatement(
                         "UPDATE SEGMENTO SET capacidad_reservada = capacidad_reservada + ? " +
                                 "WHERE codigo_segmento = ?")) {

                for (String codigo : codigos) {
                    psReserva.setInt(1, idSolicitud);
                    psReserva.setString(2, codigo);
                    psReserva.setDouble(3, capacidad);
                    psReserva.executeUpdate();

                    psSegmento.setDouble(1, capacidad);
                    psSegmento.setString(2, codigo);
                    psSegmento.executeUpdate();

                    registrarUtilizacionMes(conn, codigo);
                }
            }

            cambiarEstado(conn, idSolicitud, "Aprobada",
                    "Capacidad reservada: " + String.format(java.util.Locale.US, "%.0f", capacidad)
                            + " Gbps en " + codigos.size() + " segmento(s).", dniUsuario);

            conn.commit();
            return null;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            rollback(conn);
            return "No se pudo registrar la reserva: " + e.getMessage();
        } finally {
            cerrar(conn);
        }
    }


    public String provisionar(int idSolicitud, Integer dniUsuario) {

        SolicitudCapacidad s = obtenerSolicitud(idSolicitud);

        if (s == null || !"Aprobada".equals(s.getEstado())) {
            return "Solo se puede provisionar una solicitud Aprobada.";
        }
        if (!s.isReservada()) {
            return "No se puede provisionar: primero reserva la capacidad de " + s.getCodigo() + ".";
        }

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            int idServicio;

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "INSERT INTO SERVICIO (capacidad_contratada, estado, RUTA_id_ruta, " +
                            "CLIENTE_id_cliente, fecha_activacion, SOLICITUD_id_solicitud) " +
                            "VALUES (?, 'Provisionado', ?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS)) {

                pstmt.setDouble(1, s.getCapacidadRequerida());
                pstmt.setInt(2, s.getIdRuta());
                pstmt.setInt(3, s.getIdCliente());
                pstmt.setString(4, s.getFechaRequerida()); // fecha prevista; se actualiza al activar
                pstmt.setInt(5, idSolicitud);
                pstmt.executeUpdate();

                try (ResultSet rs = pstmt.getGeneratedKeys()) {
                    rs.next();
                    idServicio = rs.getInt(1);
                }
            }

            cambiarEstado(conn, idSolicitud, "Provisionada",
                    String.format("Servicio SRV-%03d creado sobre %s.", idServicio, s.getCodigoRuta()),
                    dniUsuario);

            conn.commit();
            return null;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            rollback(conn);
            return "No se pudo provisionar: " + e.getMessage();
        } finally {
            cerrar(conn);
        }
    }



    public String activar(int idSolicitud, Ruta ruta, Integer dniUsuario) {

        SolicitudCapacidad s = obtenerSolicitud(idSolicitud);

        if (s == null || !"Provisionada".equals(s.getEstado())) {
            return "Solo se puede activar una solicitud Provisionada.";
        }
        if (ruta == null) {
            return s.getCodigo() + " no tiene una ruta asignada.";
        }
        if (ruta.isTieneSegmentoFueraServicio()) {
            return "No se puede activar: la ruta " + ruta.getCodigo()
                    + " tiene un segmento Fuera de servicio.";
        }
        if (s.getIdServicio() == null) {
            return s.getCodigo() + " no tiene un servicio asociado.";
        }

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            List<String[]> reservas = new ArrayList<>();

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "SELECT id_reserva, SEGMENTO_codigo_segmento, capacidad FROM RESERVA_CAPACIDAD " +
                            "WHERE SOLICITUD_id_solicitud = ? AND estado = 'Reservada' FOR UPDATE")) {
                pstmt.setInt(1, idSolicitud);
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        reservas.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3)});
                    }
                }
            }

            try (PreparedStatement psSegmento = conn.prepareStatement(
                    "UPDATE SEGMENTO SET capacidad_reservada = capacidad_reservada - ?, " +
                            "capacidad_utilizada = capacidad_utilizada + ? WHERE codigo_segmento = ?");
                 PreparedStatement psReserva = conn.prepareStatement(
                         "UPDATE RESERVA_CAPACIDAD SET estado = 'Utilizada' WHERE id_reserva = ?")) {

                for (String[] r : reservas) {
                    double capacidad = Double.parseDouble(r[2]);
                    psSegmento.setDouble(1, capacidad);
                    psSegmento.setDouble(2, capacidad);
                    psSegmento.setString(3, r[1]);
                    psSegmento.executeUpdate();

                    psReserva.setInt(1, Integer.parseInt(r[0]));
                    psReserva.executeUpdate();

                    registrarUtilizacionMes(conn, r[1]);
                }
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE SERVICIO SET estado = 'Activo', fecha_activacion = CURDATE() " +
                            "WHERE id_servicio = ?")) {
                pstmt.setInt(1, s.getIdServicio());
                pstmt.executeUpdate();
            }

            cambiarEstado(conn, idSolicitud, "Activa",
                    String.format("Servicio SRV-%03d activado.", s.getIdServicio()), dniUsuario);

            conn.commit();
            return null;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            rollback(conn);
            return "No se pudo activar: " + e.getMessage();
        } finally {
            cerrar(conn);
        }
    }


    private void registrarUtilizacionMes(Connection conn, String codigoSegmento) throws SQLException {

        String sqlActualizar =
                "UPDATE UTILIZACION_HIST u INNER JOIN SEGMENTO seg " +
                        "ON seg.codigo_segmento = u.SEGMENTO_codigo_segmento " +
                        "SET u.capacidad_total = seg.capacidad_total, " +
                        "u.capacidad_utilizada = seg.capacidad_utilizada, " +
                        "u.capacidad_disponible = seg.capacidad_total - seg.capacidad_utilizada " +
                        "  - seg.capacidad_reservada " +
                        "WHERE u.SEGMENTO_codigo_segmento = ? " +
                        "AND u.fecha = DATE_FORMAT(CURDATE(), '%Y-%m-01')";

        String sqlInsertar =
                "INSERT INTO UTILIZACION_HIST (fecha, capacidad_utilizada, capacidad_disponible, " +
                        "capacidad_total, SEGMENTO_codigo_segmento) " +
                        "SELECT DATE_FORMAT(CURDATE(), '%Y-%m-01'), capacidad_utilizada, " +
                        "capacidad_total - capacidad_utilizada - capacidad_reservada, " +
                        "capacidad_total, codigo_segmento FROM SEGMENTO WHERE codigo_segmento = ?";

        try (PreparedStatement pstmt = conn.prepareStatement(sqlActualizar)) {
            pstmt.setString(1, codigoSegmento);
            if (pstmt.executeUpdate() > 0) {
                return;
            }
        }

        try (PreparedStatement pstmt = conn.prepareStatement(sqlInsertar)) {
            pstmt.setString(1, codigoSegmento);
            pstmt.executeUpdate();
        }
    }


    private void rollback(Connection conn) {
        try {
            if (conn != null) conn.rollback();
        } catch (SQLException ex) {
            ex.printStackTrace();
        }
    }

    private void cerrar(Connection conn) {
        try {
            if (conn != null) conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
