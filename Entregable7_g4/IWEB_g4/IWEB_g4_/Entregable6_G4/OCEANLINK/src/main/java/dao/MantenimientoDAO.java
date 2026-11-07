package dao;

import beans.ActividadMantenimiento;
import beans.HistorialMantenimiento;
import beans.LandingStation;
import beans.Mantenimiento;
import beans.Paginacion;
import beans.Segmento;
import beans.ServicioAfectado;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/*
 * Consultas y operaciones del rol Maintenance Coordinator.
 *
 * Relación con la infraestructura (según el modelo de la BD):
 *   SEGMENTO.MANTENIMIENTO_id_mantenimiento y LANDING_STATION.MANTENIMIENTO_id_mantenimiento1
 *   guardan el último mantenimiento de cada elemento. Al registrar un mantenimiento se actualizan
 *   esas columnas, y así el Supervisor y el Network Operator lo ven en sus vistas.
 *
 * MANTENIMIENTO.ACTIVIDAD_MANTENIMIENTO_id_actividad apunta a la actividad principal (título y
 * descripción con los que se registró). Las demás actividades y los cambios de estado se enlazan
 * con la columna MANTENIMIENTO_codigo_mantenimiento que se agrega en prepararTablas()
 * (igual que el Network Operator hace con HIST_INCIDENCIA).
 */
public class MantenimientoDAO {

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


    // =====================================================
    // AJUSTE DE TABLAS (se ejecuta una sola vez al iniciar)
    // =====================================================

    public void prepararTablas() {

        String sqlExiste =
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " +
                        "WHERE TABLE_SCHEMA = DATABASE() " +
                        "AND UPPER(TABLE_NAME) = 'HIST_MANTENIMIENTO' " +
                        "AND UPPER(COLUMN_NAME) = 'MANTENIMIENTO_CODIGO_MANTENIMIENTO'";

        try (Connection conn = conectar();
             Statement stmt = conn.createStatement()) {

            try (ResultSet rs = stmt.executeQuery(sqlExiste)) {
                if (rs.next() && rs.getInt(1) > 0) {
                    return; // ya está ajustada
                }
            }

            stmt.executeUpdate(
                    "ALTER TABLE ACTIVIDAD_MANTENIMIENTO " +
                            "ADD COLUMN MANTENIMIENTO_codigo_mantenimiento VARCHAR(10) NULL");

            stmt.executeUpdate(
                    "ALTER TABLE HIST_MANTENIMIENTO " +
                            "ADD COLUMN MANTENIMIENTO_codigo_mantenimiento VARCHAR(10) NULL, " +
                            "ADD COLUMN observacion VARCHAR(500) NULL, " +
                            "ADD COLUMN USUARIO_dni_usuario INT NULL");

            // Datos de prueba: a qué mantenimiento pertenece cada actividad y cada cambio de estado
            String[][] actividades = {
                    {"MNT-001", "1", "2"}, {"MNT-002", "3", "4"}, {"MNT-003", "5", "7"}, {"MNT-005", "8", "9"}
            };
            String[][] historial = {
                    {"MNT-001", "1", "3"}, {"MNT-002", "4", "6"}, {"MNT-003", "7", "9"},
                    {"MNT-004", "10", "11"}, {"MNT-005", "12", "13"}, {"MNT-006", "14", "14"},
                    {"MNT-007", "15", "15"}, {"MNT-008", "16", "16"}, {"MNT-009", "17", "17"}
            };

            try (PreparedStatement psAct = conn.prepareStatement(
                    "UPDATE ACTIVIDAD_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = ? " +
                            "WHERE id_actividad BETWEEN ? AND ?");
                 PreparedStatement psHist = conn.prepareStatement(
                         "UPDATE HIST_MANTENIMIENTO SET MANTENIMIENTO_codigo_mantenimiento = ? " +
                                 "WHERE id_historial BETWEEN ? AND ?")) {

                for (String[] a : actividades) {
                    psAct.setString(1, a[0]);
                    psAct.setInt(2, Integer.parseInt(a[1]));
                    psAct.setInt(3, Integer.parseInt(a[2]));
                    psAct.executeUpdate();
                }
                for (String[] h : historial) {
                    psHist.setString(1, h[0]);
                    psHist.setInt(2, Integer.parseInt(h[1]));
                    psHist.setInt(3, Integer.parseInt(h[2]));
                    psHist.executeUpdate();
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }


    // =====================================================
    // Utilidades
    // =====================================================

    private boolean hay(String valor) {
        return valor != null && !valor.trim().isEmpty();
    }

    private boolean esFecha(String valor) {
        return valor != null && valor.matches("\\d{4}-\\d{2}-\\d{2}");
    }

    private void asignar(PreparedStatement pstmt, List<String> params, Paginacion pag) throws SQLException {
        int i = 1;
        for (String p : params) {
            pstmt.setString(i++, p);
        }
        if (pag != null) {
            pstmt.setInt(i++, pag.getInicio());
            pstmt.setInt(i, pag.getTamanio());
        }
    }

    // Antes de agregar LIMIT se cuenta el total de filas
    private String paginar(String sql, List<String> params, Paginacion pag) {
        if (pag == null) {
            return sql;
        }
        int total = 0;
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM (" + sql + ") AS t")) {
            asignar(pstmt, params, null);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    total = rs.getInt(1);
                }
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        pag.setTotalRegistros(total);
        return sql + " LIMIT ?, ?";
    }

    // "?, ?, ?" para un IN (...)
    private String marcadores(int cantidad) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < cantidad; i++) {
            sb.append(i == 0 ? "?" : ", ?");
        }
        return sb.toString();
    }

    private int largo(String[] arreglo) {
        return arreglo == null ? 0 : arreglo.length;
    }

    // Inserta una fila y devuelve el id autoincremental generado
    private int insertar(Connection conn, String sql, Object... valores) throws SQLException {
        try (PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            for (int i = 0; i < valores.length; i++) {
                if (valores[i] == null) {
                    pstmt.setNull(i + 1, Types.VARCHAR);
                } else {
                    pstmt.setObject(i + 1, valores[i]);
                }
            }
            pstmt.executeUpdate();
            try (ResultSet rs = pstmt.getGeneratedKeys()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    // Registra un cambio de estado y lo deja como último historial del mantenimiento
    private void registrarHistorial(Connection conn, String codigo, String estado,
                                    String observacion, Integer dni) throws SQLException {

        int idHist = insertar(conn,
                "INSERT INTO HIST_MANTENIMIENTO (estado, fecha, MANTENIMIENTO_codigo_mantenimiento, " +
                        "observacion, USUARIO_dni_usuario) VALUES (?, NOW(), ?, ?, ?)",
                estado, codigo, observacion, dni);

        try (PreparedStatement pstmt = conn.prepareStatement(
                "UPDATE MANTENIMIENTO SET HIST_MANTENIMIENTO_id_historial = ? WHERE codigo_mantenimiento = ?")) {
            pstmt.setInt(1, idHist);
            pstmt.setString(2, codigo);
            pstmt.executeUpdate();
        }
    }

    // Duración en horas -> "HH:00:00" (la columna TIME admite más de 24 horas)
    public static String duracionTexto(int horas) {
        return String.format("%02d:00:00", horas);
    }


    // =====================================================
    // LISTADO
    // =====================================================

    private final String SQL_MANTENIMIENTO =
            "SELECT m.codigo_mantenimiento, m.tipo, m.estado, m.fecha_programada, " +
                    "TIME_FORMAT(m.hora_inicio, '%H:%i') AS hora_inicio, m.duracion_estimada, " +
                    "a.id_actividad, a.titulo, a.descripcion, " +
                    "(SELECT GROUP_CONCAT(seg.codigo_segmento ORDER BY seg.codigo_segmento SEPARATOR ', ') " +
                    " FROM SEGMENTO seg WHERE seg.MANTENIMIENTO_id_mantenimiento = m.codigo_mantenimiento) AS segmentos, " +
                    "(SELECT GROUP_CONCAT(ls.id_landing ORDER BY ls.id_landing SEPARATOR ', ') " +
                    " FROM LANDING_STATION ls WHERE ls.MANTENIMIENTO_id_mantenimiento1 = m.codigo_mantenimiento) AS landings, " +
                    "f.resultado, f.resumen_final, f.observacion, " +
                    "DATE_FORMAT(f.fecha_fin, '%Y-%m-%d %H:%i') AS fecha_fin, f.estado_servicios " +
                    "FROM MANTENIMIENTO m " +
                    "LEFT JOIN ACTIVIDAD_MANTENIMIENTO a ON m.ACTIVIDAD_MANTENIMIENTO_id_actividad = a.id_actividad " +
                    "LEFT JOIN FINALIZACION_MANTENIMIENTO f ON m.FINALIZACION_MANTENIMIENTO_id_finalizacion = f.id_finalizacion ";

    private Mantenimiento leerMantenimiento(ResultSet rs) throws SQLException {
        Mantenimiento m = new Mantenimiento();
        m.setCodigoMantenimiento(rs.getString("codigo_mantenimiento"));
        m.setTipo(rs.getString("tipo"));
        m.setEstado(rs.getString("estado"));
        m.setFechaProgramada(rs.getString("fecha_programada"));
        m.setHoraInicio(rs.getString("hora_inicio"));
        m.setDuracionEstimada(rs.getString("duracion_estimada"));
        m.setIdActividad(rs.getInt("id_actividad"));
        m.setActividad(rs.getString("titulo"));
        m.setDescripcion(rs.getString("descripcion"));
        m.setSegmentos(rs.getString("segmentos"));
        m.setLandings(rs.getString("landings"));
        m.setResultado(rs.getString("resultado"));
        m.setResumenFinal(rs.getString("resumen_final"));
        m.setObservacionFinal(rs.getString("observacion"));
        m.setFechaFin(rs.getString("fecha_fin"));
        m.setEstadoServicios(rs.getString("estado_servicios"));
        return m;
    }

    /*
     * estado: estado exacto del mantenimiento | tipo: Preventivo / Correctivo
     * buscar: código, título, segmento o landing station | desde / hasta: fecha programada
     */
    public List<Mantenimiento> listarMantenimientos(String estado, String tipo, String buscar,
                                                    String desde, String hasta, Paginacion pag) {

        List<Mantenimiento> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = SQL_MANTENIMIENTO + "WHERE 1 = 1 ";

        if (hay(estado)) {
            sql += "AND m.estado = ? ";
            params.add(estado);
        }
        if (hay(tipo)) {
            sql += "AND m.tipo = ? ";
            params.add(tipo);
        }
        if (hay(buscar)) {
            sql += "AND (m.codigo_mantenimiento LIKE ? OR a.titulo LIKE ? " +
                    "OR m.codigo_mantenimiento IN (SELECT seg.MANTENIMIENTO_id_mantenimiento FROM SEGMENTO seg " +
                    "WHERE seg.codigo_segmento LIKE ?) " +
                    "OR m.codigo_mantenimiento IN (SELECT ls.MANTENIMIENTO_id_mantenimiento1 FROM LANDING_STATION ls " +
                    "WHERE ls.id_landing LIKE ? OR ls.nombre LIKE ?)) ";
            for (int i = 0; i < 5; i++) {
                params.add("%" + buscar.trim() + "%");
            }
        }
        if (esFecha(desde)) {
            sql += "AND m.fecha_programada >= ? ";
            params.add(desde);
        }
        if (esFecha(hasta)) {
            sql += "AND m.fecha_programada <= ? ";
            params.add(hasta);
        }

        // Primero lo que está en ejecución, luego lo programado y al final lo cerrado (más reciente primero)
        sql += "ORDER BY CASE m.estado WHEN 'En ejecución' THEN 0 WHEN 'Programado' THEN 1 ELSE 2 END, " +
                "CASE WHEN m.estado IN ('En ejecución', 'Programado') THEN m.fecha_programada END ASC, " +
                "m.fecha_programada DESC, m.codigo_mantenimiento";

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, pag);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(leerMantenimiento(rs));
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }

    // Cantidad de mantenimientos por estado (tarjetas del listado)
    public Map<String, Integer> contarPorEstado() {
        Map<String, Integer> mapa = new LinkedHashMap<>();
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT estado, COUNT(*) FROM MANTENIMIENTO GROUP BY estado");
             ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                mapa.put(rs.getString(1), rs.getInt(2));
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return mapa;
    }

    public Mantenimiento obtenerMantenimiento(String codigo) {

        if (!hay(codigo)) {
            return null;
        }

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     SQL_MANTENIMIENTO + "WHERE m.codigo_mantenimiento = ?")) {

            pstmt.setString(1, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return leerMantenimiento(rs);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return null;
    }


    // =====================================================
    // DETALLE: infraestructura, actividades e historial
    // =====================================================

    // Segmentos del mantenimiento (o todos si codigo es null), con el mantenimiento que tienen asignado
    public List<Segmento> listarSegmentos(String codigo) {

        List<Segmento> lista = new ArrayList<>();

        String sql = "SELECT seg.codigo_segmento, seg.capacidad_total, seg.capacidad_utilizada, " +
                "seg.capacidad_reservada, seg.estado, seg.MANTENIMIENTO_id_mantenimiento, m.estado AS estado_mnt, " +
                "o.id_landing AS id_origen, o.nombre AS nombre_origen, " +
                "d.id_landing AS id_destino, d.nombre AS nombre_destino, " +
                "(SELECT COUNT(DISTINCT s.id_servicio) FROM SERVICIO s " +
                " INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                " WHERE rhs.SEGMENTO_codigo_segmento = seg.codigo_segmento AND s.estado = 'Activo') AS servicios " +
                "FROM SEGMENTO seg " +
                "INNER JOIN LANDING_STATION o ON seg.LANDING_STATION_id_origen = o.id_landing " +
                "INNER JOIN LANDING_STATION d ON seg.LANDING_STATION_id_destino = d.id_landing " +
                "LEFT JOIN MANTENIMIENTO m ON seg.MANTENIMIENTO_id_mantenimiento = m.codigo_mantenimiento " +
                (codigo == null ? "" : "WHERE seg.MANTENIMIENTO_id_mantenimiento = ? ") +
                "ORDER BY seg.codigo_segmento";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            if (codigo != null) {
                pstmt.setString(1, codigo);
            }

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Segmento s = new Segmento();
                    s.setCodigoSegmento(rs.getString("codigo_segmento"));
                    s.setCapacidadTotal(rs.getDouble("capacidad_total"));
                    s.setCapacidadUtilizada(rs.getDouble("capacidad_utilizada"));
                    s.setCapacidadReservada(rs.getDouble("capacidad_reservada"));
                    s.setEstado(rs.getString("estado"));
                    s.setIdOrigen(rs.getString("id_origen"));
                    s.setNombreOrigen(rs.getString("nombre_origen"));
                    s.setIdDestino(rs.getString("id_destino"));
                    s.setNombreDestino(rs.getString("nombre_destino"));
                    s.setCantidadServicios(rs.getInt("servicios"));
                    s.setCodigoMantenimiento(rs.getString("MANTENIMIENTO_id_mantenimiento"));
                    s.setEstadoMantenimiento(rs.getString("estado_mnt"));
                    lista.add(s);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }

    // Landing stations del mantenimiento (o todas si codigo es null)
    public List<LandingStation> listarLandingStations(String codigo) {

        List<LandingStation> lista = new ArrayList<>();

        String sql = "SELECT ls.id_landing, ls.nombre, ls.ciudad, ls.pais, ls.estado, " +
                "ls.MANTENIMIENTO_id_mantenimiento1, m.estado AS estado_mnt, m.fecha_programada " +
                "FROM LANDING_STATION ls " +
                "LEFT JOIN MANTENIMIENTO m ON ls.MANTENIMIENTO_id_mantenimiento1 = m.codigo_mantenimiento " +
                (codigo == null ? "" : "WHERE ls.MANTENIMIENTO_id_mantenimiento1 = ? ") +
                "ORDER BY ls.id_landing";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            if (codigo != null) {
                pstmt.setString(1, codigo);
            }

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    LandingStation ls = new LandingStation();
                    ls.setIdLanding(rs.getString("id_landing"));
                    ls.setNombre(rs.getString("nombre"));
                    ls.setCiudad(rs.getString("ciudad"));
                    ls.setPais(rs.getString("pais"));
                    ls.setEstado(rs.getString("estado"));
                    ls.setCodigoMantenimiento(rs.getString("MANTENIMIENTO_id_mantenimiento1"));
                    ls.setEstadoMantenimiento(rs.getString("estado_mnt"));
                    ls.setFechaMantenimiento(rs.getString("fecha_programada"));
                    lista.add(ls);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }

    /*
     * Servicios que pasan por los segmentos elegidos o por segmentos que salen/llegan
     * a las landing stations elegidas (impacto del mantenimiento).
     */
    public List<ServicioAfectado> listarServiciosAfectados(String[] estaciones, String[] segmentos) {

        List<ServicioAfectado> lista = new ArrayList<>();

        if (largo(estaciones) == 0 && largo(segmentos) == 0) {
            return lista;
        }

        List<String> params = new ArrayList<>();
        String condicion = "";

        if (largo(segmentos) > 0) {
            condicion += "seg.codigo_segmento IN (" + marcadores(segmentos.length) + ") ";
            for (String s : segmentos) {
                params.add(s);
            }
        }
        if (largo(estaciones) > 0) {
            String in = marcadores(estaciones.length);
            condicion += (condicion.isEmpty() ? "" : "OR ") +
                    "seg.LANDING_STATION_id_origen IN (" + in + ") " +
                    "OR seg.LANDING_STATION_id_destino IN (" + in + ") ";
            for (String e : estaciones) {
                params.add(e);
            }
            for (String e : estaciones) {
                params.add(e);
            }
        }

        String sql = "SELECT s.id_servicio, s.capacidad_contratada, s.estado, r.id_ruta, r.codigo AS codigo_ruta, " +
                "c.id_cliente, c.razon_social, c.ruc, " +
                "GROUP_CONCAT(DISTINCT seg.codigo_segmento ORDER BY seg.codigo_segmento SEPARATOR ', ') AS segmentos " +
                "FROM SERVICIO s " +
                "INNER JOIN CLIENTE c ON s.CLIENTE_id_cliente = c.id_cliente " +
                "INNER JOIN RUTA r ON s.RUTA_id_ruta = r.id_ruta " +
                "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                "INNER JOIN SEGMENTO seg ON rhs.SEGMENTO_codigo_segmento = seg.codigo_segmento " +
                "WHERE (" + condicion + ") " +
                "GROUP BY s.id_servicio, s.capacidad_contratada, s.estado, r.id_ruta, r.codigo, " +
                "c.id_cliente, c.razon_social, c.ruc " +
                "ORDER BY s.id_servicio";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, null);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    ServicioAfectado sa = new ServicioAfectado();
                    sa.setIdServicio(rs.getInt("id_servicio"));
                    sa.setCapacidadContratada(rs.getDouble("capacidad_contratada"));
                    sa.setEstado(rs.getString("estado"));
                    sa.setIdRuta(rs.getInt("id_ruta"));
                    sa.setCodigoRuta(rs.getString("codigo_ruta"));
                    sa.setIdCliente(rs.getInt("id_cliente"));
                    sa.setRazonSocial(rs.getString("razon_social"));
                    sa.setRuc(rs.getString("ruc"));
                    sa.setSegmentos(rs.getString("segmentos"));
                    lista.add(sa);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }

    // Servicios afectados por un mantenimiento ya registrado (según su infraestructura)
    public List<ServicioAfectado> listarServiciosAfectados(String codigo) {
        List<String> segs = new ArrayList<>();
        for (Segmento s : listarSegmentos(codigo)) {
            segs.add(s.getCodigoSegmento());
        }
        List<String> ests = new ArrayList<>();
        for (LandingStation ls : listarLandingStations(codigo)) {
            ests.add(ls.getIdLanding());
        }
        return listarServiciosAfectados(ests.toArray(new String[0]), segs.toArray(new String[0]));
    }

    // Actividades del mantenimiento: la principal y las registradas durante la ejecución
    public List<ActividadMantenimiento> listarActividades(String codigo) {

        List<ActividadMantenimiento> lista = new ArrayList<>();

        String sql = "SELECT a.id_actividad, a.titulo, a.descripcion, a.fecha, " +
                "TIME_FORMAT(a.hora, '%H:%i') AS hora, a.tiempo_invertido, " +
                "(a.id_actividad = m.ACTIVIDAD_MANTENIMIENTO_id_actividad) AS principal, " +
                "NOT EXISTS (SELECT 1 FROM MANTENIMIENTO x " +
                " WHERE x.ACTIVIDAD_MANTENIMIENTO_id_actividad = a.id_actividad) AS borrable " +
                "FROM ACTIVIDAD_MANTENIMIENTO a " +
                "INNER JOIN MANTENIMIENTO m ON m.codigo_mantenimiento = ? " +
                "WHERE a.MANTENIMIENTO_codigo_mantenimiento = m.codigo_mantenimiento " +
                "OR a.id_actividad = m.ACTIVIDAD_MANTENIMIENTO_id_actividad " +
                "ORDER BY principal DESC, a.fecha, a.hora, a.id_actividad";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    ActividadMantenimiento a = new ActividadMantenimiento();
                    a.setIdActividad(rs.getInt("id_actividad"));
                    a.setCodigoMantenimiento(codigo);
                    a.setTitulo(rs.getString("titulo"));
                    a.setDescripcion(rs.getString("descripcion"));
                    a.setFecha(rs.getString("fecha"));
                    a.setHora(rs.getString("hora"));
                    a.setTiempoInvertido(rs.getString("tiempo_invertido"));
                    a.setPrincipal(rs.getBoolean("principal"));
                    a.setBorrable(rs.getBoolean("borrable"));
                    lista.add(a);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }

    public List<HistorialMantenimiento> listarHistorial(String codigo) {

        List<HistorialMantenimiento> lista = new ArrayList<>();

        String sql = "SELECT h.id_historial, h.estado, DATE_FORMAT(h.fecha, '%Y-%m-%d %H:%i') AS fecha, " +
                "h.observacion, CONCAT(u.nombre, ' ', u.apellido_1) AS usuario " +
                "FROM HIST_MANTENIMIENTO h " +
                "LEFT JOIN USUARIO u ON h.USUARIO_dni_usuario = u.dni_usuario " +
                "WHERE h.MANTENIMIENTO_codigo_mantenimiento = ? " +
                "ORDER BY h.fecha, h.id_historial";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    HistorialMantenimiento h = new HistorialMantenimiento();
                    h.setIdHistorial(rs.getInt("id_historial"));
                    h.setCodigoMantenimiento(codigo);
                    h.setEstado(rs.getString("estado"));
                    h.setFecha(rs.getString("fecha"));
                    h.setObservacion(rs.getString("observacion"));
                    h.setUsuario(rs.getString("usuario"));
                    lista.add(h);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // =====================================================
    // CREAR (wizard de 4 pasos)
    // =====================================================

    // Siguiente código libre con el formato de la BD: MNT-001, MNT-002, ...
    private String generarCodigo(Connection conn) throws SQLException {
        String sql = "SELECT COALESCE(MAX(CAST(SUBSTRING(codigo_mantenimiento, 5) AS UNSIGNED)), 0) " +
                "FROM MANTENIMIENTO WHERE codigo_mantenimiento LIKE 'MNT-%'";
        try (PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            int siguiente = rs.next() ? rs.getInt(1) + 1 : 1;
            return String.format("MNT-%03d", siguiente);
        }
    }

    // Elementos elegidos que ya tienen otro mantenimiento Programado o En ejecución
    public List<String> elementosOcupados(String[] estaciones, String[] segmentos) {

        List<String> ocupados = new ArrayList<>();

        for (Segmento s : listarSegmentos(null)) {
            if (contiene(segmentos, s.getCodigoSegmento()) && pendiente(s.getEstadoMantenimiento())) {
                ocupados.add(s.getCodigoSegmento() + " (" + s.getCodigoMantenimiento() + ")");
            }
        }
        for (LandingStation ls : listarLandingStations(null)) {
            if (contiene(estaciones, ls.getIdLanding()) && pendiente(ls.getEstadoMantenimiento())) {
                ocupados.add(ls.getIdLanding() + " (" + ls.getCodigoMantenimiento() + ")");
            }
        }
        return ocupados;
    }

    private boolean contiene(String[] arreglo, String valor) {
        if (arreglo != null) {
            for (String a : arreglo) {
                if (a.equals(valor)) {
                    return true;
                }
            }
        }
        return false;
    }

    public static boolean pendiente(String estadoMantenimiento) {
        return "Programado".equals(estadoMantenimiento) || "En ejecución".equals(estadoMantenimiento);
    }

    /*
     * Registra el mantenimiento en una transacción:
     * actividad principal -> mantenimiento -> historial "Programado" -> asigna segmentos y landing stations.
     * Devuelve el código generado o null si hubo un error.
     */
    public String crearMantenimiento(String tipo, String titulo, String descripcion, String fecha,
                                     String hora, int horas, String[] estaciones, String[] segmentos,
                                     Integer dni) {

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            String codigo = generarCodigo(conn);

            int idActividad = insertar(conn,
                    "INSERT INTO ACTIVIDAD_MANTENIMIENTO (titulo, descripcion, fecha, hora, tiempo_invertido, " +
                            "MANTENIMIENTO_codigo_mantenimiento) VALUES (?, ?, ?, ?, '00:00:00', ?)",
                    titulo.trim(), descripcion.trim(), fecha, hora, codigo);

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "INSERT INTO MANTENIMIENTO (codigo_mantenimiento, tipo, estado, fecha_programada, hora_inicio, " +
                            "duracion_estimada, ACTIVIDAD_MANTENIMIENTO_id_actividad) " +
                            "VALUES (?, ?, 'Programado', ?, ?, ?, ?)")) {
                pstmt.setString(1, codigo);
                pstmt.setString(2, tipo);
                pstmt.setString(3, fecha);
                pstmt.setString(4, hora);
                pstmt.setString(5, duracionTexto(horas));
                pstmt.setInt(6, idActividad);
                pstmt.executeUpdate();
            }

            registrarHistorial(conn, codigo, "Programado", "Mantenimiento registrado", dni);

            if (largo(segmentos) > 0) {
                try (PreparedStatement pstmt = conn.prepareStatement(
                        "UPDATE SEGMENTO SET MANTENIMIENTO_id_mantenimiento = ? " +
                                "WHERE codigo_segmento IN (" + marcadores(segmentos.length) + ")")) {
                    pstmt.setString(1, codigo);
                    for (int i = 0; i < segmentos.length; i++) {
                        pstmt.setString(i + 2, segmentos[i]);
                    }
                    pstmt.executeUpdate();
                }
            }

            if (largo(estaciones) > 0) {
                try (PreparedStatement pstmt = conn.prepareStatement(
                        "UPDATE LANDING_STATION SET MANTENIMIENTO_id_mantenimiento1 = ? " +
                                "WHERE id_landing IN (" + marcadores(estaciones.length) + ")")) {
                    pstmt.setString(1, codigo);
                    for (int i = 0; i < estaciones.length; i++) {
                        pstmt.setString(i + 2, estaciones[i]);
                    }
                    pstmt.executeUpdate();
                }
            }

            conn.commit();
            return codigo;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            deshacer(conn);
            return null;
        } finally {
            cerrar(conn);
        }
    }


    // =====================================================
    // EDITAR (solo si está Programado)
    // =====================================================

    public boolean actualizarMantenimiento(String codigo, String tipo, String titulo, String descripcion,
                                           String fecha, String hora, int horas, Integer dni) {

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            int filas;
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE MANTENIMIENTO SET tipo = ?, fecha_programada = ?, hora_inicio = ?, " +
                            "duracion_estimada = ? WHERE codigo_mantenimiento = ? AND estado = 'Programado'")) {
                pstmt.setString(1, tipo);
                pstmt.setString(2, fecha);
                pstmt.setString(3, hora);
                pstmt.setString(4, duracionTexto(horas));
                pstmt.setString(5, codigo);
                filas = pstmt.executeUpdate();
            }

            if (filas == 0) {
                deshacer(conn);
                return false;
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE ACTIVIDAD_MANTENIMIENTO a INNER JOIN MANTENIMIENTO m " +
                            "ON m.ACTIVIDAD_MANTENIMIENTO_id_actividad = a.id_actividad " +
                            "SET a.titulo = ?, a.descripcion = ?, a.fecha = ?, a.hora = ? " +
                            "WHERE m.codigo_mantenimiento = ?")) {
                pstmt.setString(1, titulo.trim());
                pstmt.setString(2, descripcion.trim());
                pstmt.setString(3, fecha);
                pstmt.setString(4, hora);
                pstmt.setString(5, codigo);
                pstmt.executeUpdate();
            }

            registrarHistorial(conn, codigo, "Programado",
                    "Programación actualizada: " + fecha + " " + hora + " (" + horas + " h)", dni);

            conn.commit();
            return true;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            deshacer(conn);
            return false;
        } finally {
            cerrar(conn);
        }
    }


    // =====================================================
    // CAMBIOS DE ESTADO
    // =====================================================

    /*
     * Programado -> En ejecución.
     * Los segmentos del mantenimiento pasan a "En mantenimiento" (lo ven el Network Operator y el Supervisor).
     */
    public boolean iniciarMantenimiento(String codigo, String observacion, Integer dni) {

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            int filas;
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE MANTENIMIENTO SET estado = 'En ejecución' " +
                            "WHERE codigo_mantenimiento = ? AND estado = 'Programado'")) {
                pstmt.setString(1, codigo);
                filas = pstmt.executeUpdate();
            }

            if (filas == 0) {
                deshacer(conn);
                return false;
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE SEGMENTO SET estado = 'En mantenimiento' WHERE MANTENIMIENTO_id_mantenimiento = ?")) {
                pstmt.setString(1, codigo);
                pstmt.executeUpdate();
            }

            registrarHistorial(conn, codigo, "En ejecución",
                    hay(observacion) ? observacion.trim() : "Inicio de los trabajos", dni);

            conn.commit();
            return true;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            deshacer(conn);
            return false;
        } finally {
            cerrar(conn);
        }
    }

    /*
     * En ejecución -> Finalizado.
     * Guarda el cierre (FINALIZACION_MANTENIMIENTO) y devuelve los segmentos al estado indicado.
     */
    public boolean finalizarMantenimiento(String codigo, String resultado, String resumen, String observacion,
                                          String estadoSegmentos, Integer dni) {

        // Estado de los servicios según cómo quedan los segmentos
        String estadoServicios;
        switch (estadoSegmentos) {
            case "Degradado":
                estadoServicios = "Operativo con degradación";
                break;
            case "Fuera de servicio":
                estadoServicios = "Interrumpido";
                break;
            default:
                estadoServicios = "Restablecido";
        }

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            String estadoActual = null;
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "SELECT estado FROM MANTENIMIENTO WHERE codigo_mantenimiento = ? FOR UPDATE")) {
                pstmt.setString(1, codigo);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        estadoActual = rs.getString(1);
                    }
                }
            }

            if (!"En ejecución".equals(estadoActual)) {
                deshacer(conn);
                return false;
            }

            int idFinal = insertar(conn,
                    "INSERT INTO FINALIZACION_MANTENIMIENTO (resultado, resumen_final, observacion, fecha_fin, " +
                            "estado_servicios) VALUES (?, ?, ?, NOW(), ?)",
                    resultado, resumen.trim(), hay(observacion) ? observacion.trim() : null, estadoServicios);

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE MANTENIMIENTO SET estado = 'Finalizado', FINALIZACION_MANTENIMIENTO_id_finalizacion = ? " +
                            "WHERE codigo_mantenimiento = ?")) {
                pstmt.setInt(1, idFinal);
                pstmt.setString(2, codigo);
                pstmt.executeUpdate();
            }

            // Solo los segmentos que siguen "En mantenimiento" (si el Network Operator registró
            // una falla mientras tanto, se respeta ese estado)
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE SEGMENTO SET estado = ? " +
                            "WHERE MANTENIMIENTO_id_mantenimiento = ? AND estado = 'En mantenimiento'")) {
                pstmt.setString(1, estadoSegmentos);
                pstmt.setString(2, codigo);
                pstmt.executeUpdate();
            }

            registrarHistorial(conn, codigo, "Finalizado", "Resultado: " + resultado, dni);

            conn.commit();
            return true;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            deshacer(conn);
            return false;
        } finally {
            cerrar(conn);
        }
    }

    // Programado -> Cancelado (el registro no se borra: queda en el historial)
    public boolean cancelarMantenimiento(String codigo, String motivo, Integer dni) {

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            int filas;
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE MANTENIMIENTO SET estado = 'Cancelado' " +
                            "WHERE codigo_mantenimiento = ? AND estado = 'Programado'")) {
                pstmt.setString(1, codigo);
                filas = pstmt.executeUpdate();
            }

            if (filas == 0) {
                deshacer(conn);
                return false;
            }

            registrarHistorial(conn, codigo, "Cancelado", motivo.trim(), dni);

            conn.commit();
            return true;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            deshacer(conn);
            return false;
        } finally {
            cerrar(conn);
        }
    }


    // =====================================================
    // ACTIVIDADES (bitácora durante la ejecución)
    // =====================================================

    public boolean registrarActividad(String codigo, String titulo, String descripcion, String fecha,
                                      String hora, int horas, int minutos) {

        String sql = "INSERT INTO ACTIVIDAD_MANTENIMIENTO (titulo, descripcion, fecha, hora, tiempo_invertido, " +
                "MANTENIMIENTO_codigo_mantenimiento) " +
                "SELECT ?, ?, ?, ?, ?, codigo_mantenimiento FROM MANTENIMIENTO " +
                "WHERE codigo_mantenimiento = ? AND estado = 'En ejecución'";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, titulo.trim());
            pstmt.setString(2, descripcion.trim());
            pstmt.setString(3, fecha);
            pstmt.setString(4, hora);
            pstmt.setString(5, String.format("%02d:%02d:00", horas, minutos));
            pstmt.setString(6, codigo);

            return pstmt.executeUpdate() > 0;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }

    // Borra una actividad registrada por error (solo mientras está En ejecución y si ningún
    // mantenimiento la usa como actividad principal)
    public boolean borrarActividad(int idActividad, String codigo) {

        String sql = "DELETE a FROM ACTIVIDAD_MANTENIMIENTO a " +
                "INNER JOIN MANTENIMIENTO m ON a.MANTENIMIENTO_codigo_mantenimiento = m.codigo_mantenimiento " +
                "WHERE a.id_actividad = ? AND m.codigo_mantenimiento = ? AND m.estado = 'En ejecución' " +
                "AND NOT EXISTS (SELECT 1 FROM MANTENIMIENTO x " +
                "WHERE x.ACTIVIDAD_MANTENIMIENTO_id_actividad = a.id_actividad)";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, idActividad);
            pstmt.setString(2, codigo);
            return pstmt.executeUpdate() > 0;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }


    // =====================================================
    // Transacciones
    // =====================================================

    private void deshacer(Connection conn) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
    }

    private void cerrar(Connection conn) {
        if (conn != null) {
            try {
                conn.setAutoCommit(true);
                conn.close();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
    }
}
