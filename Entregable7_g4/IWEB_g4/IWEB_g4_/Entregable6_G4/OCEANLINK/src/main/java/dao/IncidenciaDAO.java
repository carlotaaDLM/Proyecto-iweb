package dao;

import beans.Paginacion;

import beans.Cliente;
import beans.HistorialIncidencia;
import beans.Incidencia;
import beans.Segmento;
import beans.Servicio;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;



public class IncidenciaDAO {

    private final String url = "jdbc:mysql://localhost:3306/mibasededatos";
    private final String user = "root";
    private final String pass = "root";


    public static final String[] FLUJO = {
            "Detectada",
            "En análisis",
            "Reparación programada",
            "En reparación",
            "Servicio restaurado",
            "Cerrada"
    };



    private String ultimoError;

    public String getUltimoError() {
        return ultimoError;
    }


    private Connection conectar() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(url, user, pass);
    }




    private void crearUsuariosNetworkOperator() {

        String[][] usuarios = {
                {"35021881", "Diego", "Quispe", "Jimenez", "diegoqj@oceanlink.pe"},
                {"20354448", "Valeria", "Rojas", "Chavez", "valeriarc@oceanlink.pe"}
        };

        String sqlExiste = "SELECT COUNT(*) FROM USUARIO WHERE correo = ?";

        String sqlGuardar =
                "INSERT INTO USUARIO (dni_usuario, nombre, apellido_1, apellido_2, " +
                        "correo, password, estado, ROL_id_rol) " +
                        "VALUES (?, ?, ?, ?, ?, 'iweb', 'Activo', 3) " +
                        "ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), " +
                        "apellido_1 = VALUES(apellido_1), apellido_2 = VALUES(apellido_2), " +
                        "correo = VALUES(correo), password = 'iweb', " +
                        "estado = 'Activo', ROL_id_rol = 3";

        try (Connection conn = conectar();
             Statement stmt = conn.createStatement();
             PreparedStatement psExiste = conn.prepareStatement(sqlExiste);
             PreparedStatement psGuardar = conn.prepareStatement(sqlGuardar)) {


            stmt.executeUpdate("INSERT IGNORE INTO ROL (id_rol, nombre) VALUES (3, 'Network Operator')");

            for (String[] u : usuarios) {

                psExiste.setString(1, u[4]);
                try (ResultSet rs = psExiste.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        continue; // ya existe, no se toca
                    }
                }

                psGuardar.setInt(1, Integer.parseInt(u[0]));
                psGuardar.setString(2, u[1]);
                psGuardar.setString(3, u[2]);
                psGuardar.setString(4, u[3]);
                psGuardar.setString(5, u[4]);
                psGuardar.executeUpdate();

                System.out.println("OCEANLINK - usuario Network Operator creado: " + u[4]);
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }



    public void prepararTablas() {

        crearUsuariosNetworkOperator();

        String sqlExiste =
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " +
                        "WHERE TABLE_SCHEMA = DATABASE() " +
                        "AND UPPER(TABLE_NAME) = 'HIST_INCIDENCIA' " +
                        "AND UPPER(COLUMN_NAME) = 'INCIDENCIA_CODIGO_INCIDENCIA'";

        try (Connection conn = conectar();
             Statement stmt = conn.createStatement()) {

            try (ResultSet rs = stmt.executeQuery(sqlExiste)) {
                if (rs.next() && rs.getInt(1) > 0) {
                    return; // ya está ajustada
                }
            }

            stmt.executeUpdate(
                    "ALTER TABLE HIST_INCIDENCIA " +
                            "ADD COLUMN INCIDENCIA_codigo_incidencia VARCHAR(10) NULL, " +
                            "ADD COLUMN observacion VARCHAR(500) NULL, " +
                            "ADD COLUMN USUARIO_dni_usuario INT NULL");

            int[][] rangos = {
                    {1, 6}, {7, 12}, {13, 17}, {18, 20}, {21, 22}, {23, 26}, {27, 27}, {28, 30},
                    {31, 33}, {34, 37}, {38, 39}, {40, 42}, {43, 45}, {46, 48}, {49, 51}
            };

            String sqlUpdate =
                    "UPDATE HIST_INCIDENCIA SET INCIDENCIA_codigo_incidencia = ? " +
                            "WHERE id_historial BETWEEN ? AND ?";

            try (PreparedStatement pstmt = conn.prepareStatement(sqlUpdate)) {
                for (int i = 0; i < rangos.length; i++) {
                    pstmt.setString(1, String.format("INC-%03d", i + 1));
                    pstmt.setInt(2, rangos[i][0]);
                    pstmt.setInt(3, rangos[i][1]);
                    pstmt.executeUpdate();
                }
            }

            stmt.executeUpdate(
                    "UPDATE HIST_INCIDENCIA SET USUARIO_dni_usuario = 20354448 " +
                            "WHERE id_historial BETWEEN 1 AND 51");

            stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS INCIDENCIA_SEGMENTO (" +
                            "codigo_incidencia VARCHAR(10) NOT NULL, " +
                            "codigo_segmento VARCHAR(12) NOT NULL, " +
                            "PRIMARY KEY (codigo_incidencia, codigo_segmento)) ENGINE = InnoDB");

            System.out.println("OCEANLINK - HIST_INCIDENCIA ajustada para el Network Operator");

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


    private final String SQL_SEGMENTOS_INCIDENCIA =
            "(SELECT SEGMENTO_codigo_segmento FROM INCIDENCIA WHERE codigo_incidencia = ? " +
                    " UNION " +
                    " SELECT codigo_segmento FROM INCIDENCIA_SEGMENTO WHERE codigo_incidencia = ?)";



    public Incidencia obtenerIncidencia(String codigo) {

        Incidencia incidencia = null;

        String sql =
                "SELECT i.codigo_incidencia, i.titulo, i.descripcion, i.severidad, i.estado, " +
                        "DATE_FORMAT(i.fecha_deteccion, '%d/%m/%Y') AS fecha, " +
                        "TIME_FORMAT(i.hora, '%H:%i') AS hora, " +
                        "CONCAT(DATE_FORMAT(i.fecha_deteccion, '%Y-%m-%d'), 'T', " +
                        "       TIME_FORMAT(i.hora, '%H:%i')) AS fecha_iso, " +
                        "i.SEGMENTO_codigo_segmento AS codigo_segmento, " +
                        "i.LANDING_STATION_id_landing AS id_landing, " +
                        "CONCAT(REPLACE(o.nombre, 'Estación ', ''), ' → ', REPLACE(d.nombre, 'Estación ', '')) AS tramo, " +
                        "(SELECT CONCAT(u.nombre, ' ', u.apellido_1) " +
                        "   FROM HIST_INCIDENCIA h " +
                        "   INNER JOIN USUARIO u ON h.USUARIO_dni_usuario = u.dni_usuario " +
                        "   WHERE h.INCIDENCIA_codigo_incidencia = i.codigo_incidencia " +
                        "   ORDER BY h.fecha, h.id_historial LIMIT 1) AS registrada_por " +
                        "FROM INCIDENCIA i " +
                        "LEFT JOIN SEGMENTO seg ON i.SEGMENTO_codigo_segmento = seg.codigo_segmento " +
                        "LEFT JOIN LANDING_STATION o ON seg.LANDING_STATION_id_origen = o.id_landing " +
                        "LEFT JOIN LANDING_STATION d ON seg.LANDING_STATION_id_destino = d.id_landing " +
                        "WHERE i.codigo_incidencia = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    incidencia = new Incidencia();
                    incidencia.setCodigoIncidencia(rs.getString("codigo_incidencia"));
                    incidencia.setTitulo(rs.getString("titulo"));
                    incidencia.setDescripcion(rs.getString("descripcion"));
                    incidencia.setSeveridad(rs.getString("severidad"));
                    incidencia.setEstado(rs.getString("estado"));
                    incidencia.setFechaDeteccion(rs.getString("fecha") + " " + rs.getString("hora"));
                    incidencia.setFechaDeteccionIso(rs.getString("fecha_iso"));
                    incidencia.setCodigoSegmento(rs.getString("codigo_segmento"));
                    incidencia.setIdLanding(rs.getString("id_landing"));
                    incidencia.setTramo(rs.getString("tramo"));
                    incidencia.setRegistradaPor(rs.getString("registrada_por"));
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return incidencia;
    }


    public List<Segmento> listarSegmentosDeIncidencia(String codigo) {

        List<Segmento> lista = new ArrayList<>();

        String sql =
                "SELECT seg.codigo_segmento, seg.estado, o.nombre AS nombre_origen, " +
                        "d.nombre AS nombre_destino " +
                        "FROM SEGMENTO seg " +
                        "INNER JOIN LANDING_STATION o ON seg.LANDING_STATION_id_origen = o.id_landing " +
                        "INNER JOIN LANDING_STATION d ON seg.LANDING_STATION_id_destino = d.id_landing " +
                        "WHERE seg.codigo_segmento IN " + SQL_SEGMENTOS_INCIDENCIA + " " +
                        "ORDER BY seg.codigo_segmento";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);
            pstmt.setString(2, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Segmento segmento = new Segmento();
                    segmento.setCodigoSegmento(rs.getString("codigo_segmento"));
                    segmento.setEstado(rs.getString("estado"));
                    segmento.setNombreOrigen(rs.getString("nombre_origen"));
                    segmento.setNombreDestino(rs.getString("nombre_destino"));
                    lista.add(segmento);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }



    public List<Servicio> listarServiciosAfectados(String codigo) {

        List<Servicio> lista = new ArrayList<>();

        String sql =
                "SELECT DISTINCT s.id_servicio, s.capacidad_contratada, s.estado, " +
                        "r.codigo AS codigo_ruta, c.razon_social " +
                        "FROM SERVICIO s " +
                        "INNER JOIN RUTA r ON s.RUTA_id_ruta = r.id_ruta " +
                        "INNER JOIN CLIENTE c ON s.CLIENTE_id_cliente = c.id_cliente " +
                        "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                        "WHERE s.estado = 'Activo' " +
                        "AND rhs.SEGMENTO_codigo_segmento IN " + SQL_SEGMENTOS_INCIDENCIA + " " +
                        "ORDER BY s.id_servicio";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);
            pstmt.setString(2, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Servicio servicio = new Servicio();
                    servicio.setIdServicio(rs.getInt("id_servicio"));
                    servicio.setCapacidadContratada(rs.getDouble("capacidad_contratada"));
                    servicio.setEstado(rs.getString("estado"));
                    servicio.setCodigoRuta(rs.getString("codigo_ruta"));
                    servicio.setRazonSocialCliente(rs.getString("razon_social"));
                    lista.add(servicio);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    public List<Cliente> listarClientesAfectados(String codigo) {

        List<Cliente> lista = new ArrayList<>();

        String sql =
                "SELECT c.id_cliente, c.razon_social, c.ruc, c.correo, " +
                        "COUNT(DISTINCT s.id_servicio) AS cantidad_servicios " +
                        "FROM CLIENTE c " +
                        "INNER JOIN SERVICIO s ON s.CLIENTE_id_cliente = c.id_cliente " +
                        "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                        "WHERE s.estado = 'Activo' " +
                        "AND rhs.SEGMENTO_codigo_segmento IN " + SQL_SEGMENTOS_INCIDENCIA + " " +
                        "GROUP BY c.id_cliente, c.razon_social, c.ruc, c.correo " +
                        "ORDER BY c.razon_social";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);
            pstmt.setString(2, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Cliente cliente = new Cliente();
                    cliente.setIdCliente(rs.getInt("id_cliente"));
                    cliente.setRazonSocial(rs.getString("razon_social"));
                    cliente.setRuc(rs.getString("ruc"));
                    cliente.setCorreo(rs.getString("correo"));
                    cliente.setCantidadServicios(rs.getInt("cantidad_servicios"));
                    lista.add(cliente);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    public int contarAfectadosPorSegmentos(String[] segmentos, String tipo) {

        if (segmentos == null || segmentos.length == 0) {
            return 0;
        }

        String columna = "clientes".equals(tipo) ? "s.CLIENTE_id_cliente" : "s.id_servicio";

        StringBuilder sql = new StringBuilder(
                "SELECT COUNT(DISTINCT " + columna + ") " +
                        "FROM SERVICIO s " +
                        "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                        "WHERE s.estado = 'Activo' AND rhs.SEGMENTO_codigo_segmento IN ("
        );

        for (int i = 0; i < segmentos.length; i++) {
            sql.append(i == 0 ? "?" : ", ?");
        }
        sql.append(")");

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < segmentos.length; i++) {
                pstmt.setString(i + 1, segmentos[i]);
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


    public List<HistorialIncidencia> listarHistorial(
            String codigo, String severidad, String desde, String hasta, String orden) {
        return listarHistorial(codigo, severidad, desde, hasta, orden, null);
    }

    // Con paginación: pag != null agrega LIMIT y guarda el total en pag
    public List<HistorialIncidencia> listarHistorial(
            String codigo, String severidad, String desde, String hasta, String orden, Paginacion pag) {

        List<HistorialIncidencia> lista = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
                "SELECT h.id_historial, h.INCIDENCIA_codigo_incidencia AS codigo, " +
                        "i.titulo, h.estado, h.observacion, " +
                        "DATE_FORMAT(h.fecha, '%d/%m/%Y %H:%i') AS fecha, " +
                        "CONCAT(u.nombre, ' ', u.apellido_1) AS usuario, " +
                        "(SELECT h2.estado FROM HIST_INCIDENCIA h2 " +
                        "  WHERE h2.INCIDENCIA_codigo_incidencia = h.INCIDENCIA_codigo_incidencia " +
                        "  AND (h2.fecha < h.fecha OR (h2.fecha = h.fecha AND h2.id_historial < h.id_historial)) " +
                        "  ORDER BY h2.fecha DESC, h2.id_historial DESC LIMIT 1) AS estado_anterior " +
                        "FROM HIST_INCIDENCIA h " +
                        "INNER JOIN INCIDENCIA i ON h.INCIDENCIA_codigo_incidencia = i.codigo_incidencia " +
                        "LEFT JOIN USUARIO u ON h.USUARIO_dni_usuario = u.dni_usuario " +
                        "WHERE 1=1 "
        );

        List<String> parametros = new ArrayList<>();

        if (codigo != null && !codigo.trim().isEmpty()) {
            sql.append("AND h.INCIDENCIA_codigo_incidencia = ? ");
            parametros.add(codigo.trim());
        }
        if (severidad != null && !severidad.trim().isEmpty()) {
            sql.append("AND i.severidad = ? ");
            parametros.add(severidad.trim());
        }
        if (desde != null && !desde.trim().isEmpty()) {
            sql.append("AND DATE(h.fecha) >= ? ");
            parametros.add(desde.trim());
        }
        if (hasta != null && !hasta.trim().isEmpty()) {
            sql.append("AND DATE(h.fecha) <= ? ");
            parametros.add(hasta.trim());
        }

        if ("ASC".equals(orden)) {
            sql.append("ORDER BY h.fecha ASC, h.id_historial ASC");
        } else {
            sql.append("ORDER BY h.fecha DESC, h.id_historial DESC");
        }

        if (pag != null) {
            pag.setTotalRegistros(contarFilas(sql.toString(), parametros));
            sql.append(" LIMIT ?, ?");
        }

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < parametros.size(); i++) {
                pstmt.setString(i + 1, parametros.get(i));
            }
            if (pag != null) {
                pstmt.setInt(parametros.size() + 1, pag.getInicio());
                pstmt.setInt(parametros.size() + 2, pag.getTamanio());
            }

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    HistorialIncidencia h = new HistorialIncidencia();
                    h.setIdHistorial(rs.getInt("id_historial"));
                    h.setCodigoIncidencia(rs.getString("codigo"));
                    h.setTituloIncidencia(rs.getString("titulo"));
                    h.setEstado(rs.getString("estado"));
                    h.setEstadoAnterior(rs.getString("estado_anterior"));
                    h.setObservacion(rs.getString("observacion"));
                    h.setFecha(rs.getString("fecha"));
                    h.setUsuario(rs.getString("usuario"));
                    lista.add(h);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    public String obtenerFechaUltimoCambio(String codigo) {

        String sql =
                "SELECT DATE_FORMAT(MAX(fecha), '%Y-%m-%dT%H:%i') " +
                        "FROM HIST_INCIDENCIA WHERE INCIDENCIA_codigo_incidencia = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString(1);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return null;
    }


    private int insertarHistorial(Connection conn, String codigo, String estado,
                                  String fecha, String observacion, Integer dniUsuario)
            throws SQLException {

        String sql =
                "INSERT INTO HIST_INCIDENCIA " +
                        "(estado, fecha, INCIDENCIA_codigo_incidencia, observacion, USUARIO_dni_usuario) " +
                        "VALUES (?, " + (fecha == null ? "NOW()" : "?") + ", ?, ?, ?)";

        try (PreparedStatement pstmt =
                     conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            int i = 1;
            pstmt.setString(i++, estado);
            if (fecha != null) {
                pstmt.setString(i++, fecha);
            }
            pstmt.setString(i++, codigo);
            pstmt.setString(i++, observacion);
            if (dniUsuario == null) {
                pstmt.setNull(i, Types.INTEGER);
            } else {
                pstmt.setInt(i, dniUsuario);
            }
            pstmt.executeUpdate();

            try (ResultSet rs = pstmt.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }


    private void actualizarEstadoSegmentos(Connection conn, List<String> segmentos, String estado)
            throws SQLException {

        String sql = "UPDATE SEGMENTO SET estado = ? WHERE codigo_segmento = ?";

        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            for (String codigoSegmento : segmentos) {
                pstmt.setString(1, estado);
                pstmt.setString(2, codigoSegmento);
                pstmt.executeUpdate();
            }
        }
    }


    private String generarCodigo(Connection conn) throws SQLException {

        String sql =
                "SELECT IFNULL(MAX(CAST(SUBSTRING(codigo_incidencia, 5) AS UNSIGNED)), 0) + 1 " +
                        "FROM INCIDENCIA";

        try (PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            if (rs.next()) {
                return String.format("INC-%03d", rs.getInt(1));
            }
        }
        return "INC-001";
    }


    public String crearIncidencia(String titulo, String descripcion, String severidad,
                                  String fechaDeteccion, String idLanding,
                                  String[] segmentos, String estadoSegmento,
                                  Integer dniUsuario) {

        String fecha = fechaDeteccion.replace("T", " ") + ":00";
        String hora = fecha.substring(11);

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            String codigo = generarCodigo(conn);


            int idHistorial = insertarHistorial(conn, codigo, "Detectada", fecha,
                    "Incidencia registrada.", dniUsuario);


            String sql =
                    "INSERT INTO INCIDENCIA (codigo_incidencia, descripcion, severidad, estado, " +
                            "fecha_deteccion, titulo, SEGMENTO_codigo_segmento, " +
                            "LANDING_STATION_id_landing, hora, HIST_INCIDENCIA_id_historial) " +
                            "VALUES (?, ?, ?, 'Detectada', ?, ?, ?, ?, ?, ?)";

            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, codigo);
                pstmt.setString(2, descripcion);
                pstmt.setString(3, severidad);
                pstmt.setString(4, fecha);
                pstmt.setString(5, titulo);
                pstmt.setString(6, segmentos[0]);
                pstmt.setString(7, idLanding);
                pstmt.setString(8, hora);
                pstmt.setInt(9, idHistorial);
                pstmt.executeUpdate();
            }


            String sqlSeg =
                    "INSERT INTO INCIDENCIA_SEGMENTO (codigo_incidencia, codigo_segmento) " +
                            "VALUES (?, ?)";

            try (PreparedStatement pstmt = conn.prepareStatement(sqlSeg)) {
                for (String codigoSegmento : segmentos) {
                    pstmt.setString(1, codigo);
                    pstmt.setString(2, codigoSegmento);
                    pstmt.executeUpdate();
                }
            }


            if (estadoSegmento != null && !"Sin cambio".equals(estadoSegmento)) {
                List<String> lista = new ArrayList<>();
                for (String s : segmentos) {
                    lista.add(s);
                }
                actualizarEstadoSegmentos(conn, lista, estadoSegmento);
            }

            conn.commit();
            return codigo;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        return null;
    }


    public void actualizarIncidencia(String codigo, String nuevoEstado, String severidad,
                                     String observacion, Integer dniUsuario) {

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            int idHistorial = insertarHistorial(conn, codigo, nuevoEstado, null,
                    observacion, dniUsuario);

            String sql =
                    "UPDATE INCIDENCIA SET estado = ?, severidad = ?, " +
                            "HIST_INCIDENCIA_id_historial = ? " +
                            "WHERE codigo_incidencia = ?";

            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, nuevoEstado);
                pstmt.setString(2, severidad);
                pstmt.setInt(3, idHistorial);
                pstmt.setString(4, codigo);
                pstmt.executeUpdate();
            }

            conn.commit();

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }



    public void registrarRestauracion(String codigo, String fechaRestauracion,
                                      String estadoSegmento, String observacion,
                                      Integer dniUsuario) {

        String fecha = fechaRestauracion.replace("T", " ") + ":00";

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            int idHistorial = insertarHistorial(conn, codigo, "Servicio restaurado", fecha,
                    observacion, dniUsuario);

            String sql =
                    "UPDATE INCIDENCIA SET estado = 'Servicio restaurado', " +
                            "HIST_INCIDENCIA_id_historial = ? " +
                            "WHERE codigo_incidencia = ?";

            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, idHistorial);
                pstmt.setString(2, codigo);
                pstmt.executeUpdate();
            }


            List<String> segmentos = new ArrayList<>();
            String sqlSeg = "SELECT * FROM " + SQL_SEGMENTOS_INCIDENCIA + " AS segs";

            try (PreparedStatement pstmt = conn.prepareStatement(sqlSeg)) {
                pstmt.setString(1, codigo);
                pstmt.setString(2, codigo);
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        if (rs.getString(1) != null) {
                            segmentos.add(rs.getString(1));
                        }
                    }
                }
            }

            actualizarEstadoSegmentos(conn, segmentos, estadoSegmento);

            conn.commit();

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }


    public void borrarIncidencia(String codigo) {

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            String[] sentencias = {
                    "DELETE FROM INCIDENCIA_SEGMENTO WHERE codigo_incidencia = ?",
                    "DELETE FROM INCIDENCIA WHERE codigo_incidencia = ?",
                    "DELETE FROM HIST_INCIDENCIA WHERE INCIDENCIA_codigo_incidencia = ?"
            };

            for (String sql : sentencias) {
                try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                    pstmt.setString(1, codigo);
                    pstmt.executeUpdate();
                }
            }

            conn.commit();

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }


    // =========================================================
    // PAGINACIÓN EN EL SERVIDOR (igual que en el Supervisor):
    // primero se cuenta el total y luego se agrega "LIMIT ?, ?"
    // =========================================================

    private int contarFilas(String sql, List<?> parametros) {
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM (" + sql + ") AS t")) {
            for (int i = 0; i < parametros.size(); i++) {
                pstmt.setObject(i + 1, parametros.get(i));
            }
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }
}
