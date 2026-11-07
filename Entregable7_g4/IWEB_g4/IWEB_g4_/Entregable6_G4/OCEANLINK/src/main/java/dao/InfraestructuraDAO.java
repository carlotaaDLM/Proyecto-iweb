package dao;

import beans.LandingStation;
import beans.Paginacion;
import beans.Segmento;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/*
 * Consultas del Administrador para la infraestructura de la red:
 * Landing Stations y segmentos de fibra (CRUD).
 *
 * Reglas:
 * - Una estación nueva se registra Operativa; un segmento nuevo, Operativo y sin capacidad usada.
 * - Solo se elimina lo que nadie usa (segmentos, rutas, incidencias, solicitudes, reservas o histórico).
 *   Lo que ya tiene historia se deja Inactivo / Fuera de servicio desde Editar.
 * - La capacidad total de un segmento no puede quedar por debajo de lo utilizado + reservado.
 */
public class InfraestructuraDAO {

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
    // AJUSTE DE TABLAS (una sola vez al iniciar)
    // En el modelo original, toda estación y todo segmento debía tener un mantenimiento
    // (columna NOT NULL), así que no se podía registrar uno nuevo. Se permite NULL.
    // =====================================================

    public void prepararTablas() {

        String[][] columnas = {
                {"LANDING_STATION", "MANTENIMIENTO_id_mantenimiento1"},
                {"SEGMENTO", "MANTENIMIENTO_id_mantenimiento"}
        };

        try (Connection conn = conectar();
             Statement stmt = conn.createStatement()) {

            for (String[] c : columnas) {
                String sql = "SELECT IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS " +
                        "WHERE TABLE_SCHEMA = DATABASE() AND UPPER(TABLE_NAME) = '" + c[0] + "' " +
                        "AND UPPER(COLUMN_NAME) = '" + c[1].toUpperCase() + "'";
                boolean nulo = true;
                try (ResultSet rs = stmt.executeQuery(sql)) {
                    if (rs.next()) {
                        nulo = "YES".equals(rs.getString(1));
                    }
                }
                if (!nulo) {
                    stmt.executeUpdate("ALTER TABLE " + c[0] + " MODIFY COLUMN " + c[1] + " VARCHAR(10) NULL");
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
        pag.setTotalRegistros(contar("SELECT COUNT(*) FROM (" + sql + ") AS t", params));
        return sql + " LIMIT ?, ?";
    }

    private int contar(String sql, List<String> params) {
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            asignar(pstmt, params, null);
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

    private List<String> lista(String... valores) {
        List<String> l = new ArrayList<>();
        for (String v : valores) {
            l.add(v);
        }
        return l;
    }

    // Ejecuta un INSERT / UPDATE / DELETE; devuelve false y guarda el error si falla
    private boolean ejecutar(String sql, Object... valores) {
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            for (int i = 0; i < valores.length; i++) {
                pstmt.setObject(i + 1, valores[i]);
            }
            return pstmt.executeUpdate() > 0;
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            return false;
        }
    }


    // =====================================================
    // LANDING STATIONS
    // =====================================================

    // Registros que usan la estación: segmentos, incidencias y solicitudes de capacidad
    private final String DEPENDENCIAS_LANDING =
            "((SELECT COUNT(*) FROM SEGMENTO s WHERE s.LANDING_STATION_id_origen = ls.id_landing " +
                    "  OR s.LANDING_STATION_id_destino = ls.id_landing) " +
                    "+ (SELECT COUNT(*) FROM INCIDENCIA i WHERE i.LANDING_STATION_id_landing = ls.id_landing) " +
                    "+ (SELECT COUNT(*) FROM SOLICITUD_CAPACIDAD sc WHERE sc.LANDING_STATION_id_origen = ls.id_landing " +
                    "  OR sc.LANDING_STATION_id_destino = ls.id_landing)) ";

    private final String SQL_LANDING =
            "SELECT ls.id_landing, ls.nombre, ls.ciudad, ls.pais, ls.estado, " +
                    "(SELECT COUNT(*) FROM SEGMENTO s WHERE s.LANDING_STATION_id_origen = ls.id_landing " +
                    " OR s.LANDING_STATION_id_destino = ls.id_landing) AS segmentos, " +
                    "(SELECT COUNT(*) FROM INCIDENCIA i WHERE i.LANDING_STATION_id_landing = ls.id_landing " +
                    " AND i.estado NOT IN ('Cerrada', 'Servicio restaurado')) AS incidencias, " +
                    DEPENDENCIAS_LANDING + "AS dependencias " +
                    "FROM LANDING_STATION ls ";

    private LandingStation leerLanding(ResultSet rs) throws SQLException {
        LandingStation ls = new LandingStation();
        ls.setIdLanding(rs.getString("id_landing"));
        ls.setNombre(rs.getString("nombre"));
        ls.setCiudad(rs.getString("ciudad"));
        ls.setPais(rs.getString("pais"));
        ls.setEstado(rs.getString("estado"));
        ls.setCantidadSegmentos(rs.getInt("segmentos"));
        ls.setIncidenciasActivas(rs.getInt("incidencias"));
        ls.setDependencias(rs.getInt("dependencias"));
        return ls;
    }

    // buscar: código, nombre o ciudad | pais / estado: valor exacto
    public List<LandingStation> listarLandingStations(String buscar, String pais, String estado, Paginacion pag) {

        List<LandingStation> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = SQL_LANDING + "WHERE 1 = 1 ";
        if (hay(buscar)) {
            sql += "AND (ls.id_landing LIKE ? OR ls.nombre LIKE ? OR ls.ciudad LIKE ?) ";
            for (int k = 0; k < 3; k++) {
                params.add("%" + buscar.trim() + "%");
            }
        }
        if (hay(pais)) {
            sql += "AND ls.pais = ? ";
            params.add(pais);
        }
        if (hay(estado)) {
            sql += "AND ls.estado = ? ";
            params.add(estado);
        }
        sql += "ORDER BY ls.pais, ls.id_landing";

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            asignar(pstmt, params, pag);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(leerLanding(rs));
                }
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return lista;
    }

    // Todas (para los combos de origen y destino)
    public List<LandingStation> listarLandingStations() {
        return listarLandingStations(null, null, null, null);
    }

    public LandingStation obtenerLandingStation(String id) {
        if (!hay(id)) {
            return null;
        }
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(SQL_LANDING + "WHERE ls.id_landing = ?")) {
            pstmt.setString(1, id.trim());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return leerLanding(rs);
                }
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }

    // Países registrados (para el filtro)
    public List<String> listarPaises() {
        List<String> paises = new ArrayList<>();
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT DISTINCT pais FROM LANDING_STATION ORDER BY pais");
             ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                paises.add(rs.getString(1));
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return paises;
    }

    public int contarLandingPorEstado(String estado) {
        return contar("SELECT COUNT(*) FROM LANDING_STATION WHERE estado = ?", lista(estado));
    }

    public boolean existeLandingStation(String id) {
        return contar("SELECT COUNT(*) FROM LANDING_STATION WHERE id_landing = ?", lista(id.trim())) > 0;
    }

    public boolean crearLandingStation(String id, String nombre, String ciudad, String pais) {
        return ejecutar("INSERT INTO LANDING_STATION (id_landing, nombre, ciudad, pais, estado) " +
                        "VALUES (?, ?, ?, ?, 'Operativa')",
                id.trim().toUpperCase(), nombre.trim(), ciudad.trim(), pais.trim());
    }

    public boolean actualizarLandingStation(String id, String nombre, String ciudad, String pais, String estado) {
        return ejecutar("UPDATE LANDING_STATION SET nombre = ?, ciudad = ?, pais = ?, estado = ? WHERE id_landing = ?",
                nombre.trim(), ciudad.trim(), pais.trim(), estado, id);
    }

    // Solo si nadie la usa (la consulta lo vuelve a comprobar)
    public boolean borrarLandingStation(String id) {
        return ejecutar("DELETE ls FROM LANDING_STATION ls WHERE ls.id_landing = ? AND " +
                DEPENDENCIAS_LANDING.replace("ls.id_landing", "?") + "= 0", id, id, id, id, id, id);
    }


    // =====================================================
    // SEGMENTOS DE FIBRA
    // =====================================================

    // Registros que usan el segmento: rutas, incidencias, reservas e histórico de utilización
    private final String DEPENDENCIAS_SEGMENTO =
            "((SELECT COUNT(*) FROM RUTA_has_SEGMENTO r WHERE r.SEGMENTO_codigo_segmento = seg.codigo_segmento) " +
                    "+ (SELECT COUNT(*) FROM INCIDENCIA i WHERE i.SEGMENTO_codigo_segmento = seg.codigo_segmento) " +
                    "+ (SELECT COUNT(*) FROM INCIDENCIA_SEGMENTO isg WHERE isg.codigo_segmento = seg.codigo_segmento) " +
                    "+ (SELECT COUNT(*) FROM RESERVA_CAPACIDAD rc WHERE rc.SEGMENTO_codigo_segmento = seg.codigo_segmento) " +
                    "+ (SELECT COUNT(*) FROM UTILIZACION_HIST u WHERE u.SEGMENTO_codigo_segmento = seg.codigo_segmento)) ";

    private final String SQL_SEGMENTO =
            "SELECT seg.codigo_segmento, seg.capacidad_total, seg.capacidad_utilizada, seg.capacidad_reservada, " +
                    "seg.estado, o.id_landing AS id_origen, o.nombre AS nombre_origen, o.pais AS pais_origen, " +
                    "d.id_landing AS id_destino, d.nombre AS nombre_destino, d.pais AS pais_destino, " +
                    "(SELECT COUNT(DISTINCT s.id_servicio) FROM SERVICIO s " +
                    " INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                    " WHERE rhs.SEGMENTO_codigo_segmento = seg.codigo_segmento AND s.estado = 'Activo') AS servicios, " +
                    DEPENDENCIAS_SEGMENTO + "AS dependencias " +
                    "FROM SEGMENTO seg " +
                    "INNER JOIN LANDING_STATION o ON seg.LANDING_STATION_id_origen = o.id_landing " +
                    "INNER JOIN LANDING_STATION d ON seg.LANDING_STATION_id_destino = d.id_landing ";

    private Segmento leerSegmento(ResultSet rs) throws SQLException {
        Segmento s = new Segmento();
        s.setCodigoSegmento(rs.getString("codigo_segmento"));
        s.setCapacidadTotal(rs.getDouble("capacidad_total"));
        s.setCapacidadUtilizada(rs.getDouble("capacidad_utilizada"));
        s.setCapacidadReservada(rs.getDouble("capacidad_reservada"));
        s.setEstado(rs.getString("estado"));
        s.setIdOrigen(rs.getString("id_origen"));
        s.setNombreOrigen(rs.getString("nombre_origen"));
        s.setPaisOrigen(rs.getString("pais_origen"));
        s.setIdDestino(rs.getString("id_destino"));
        s.setNombreDestino(rs.getString("nombre_destino"));
        s.setPaisDestino(rs.getString("pais_destino"));
        s.setCantidadServicios(rs.getInt("servicios"));
        s.setDependencias(rs.getInt("dependencias"));
        return s;
    }

    // buscar: código o estación | estado: valor exacto | landing: segmentos que salen o llegan a esa estación
    public List<Segmento> listarSegmentos(String buscar, String estado, String landing, Paginacion pag) {

        List<Segmento> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = SQL_SEGMENTO + "WHERE 1 = 1 ";
        if (hay(buscar)) {
            sql += "AND (seg.codigo_segmento LIKE ? OR o.nombre LIKE ? OR d.nombre LIKE ?) ";
            for (int k = 0; k < 3; k++) {
                params.add("%" + buscar.trim() + "%");
            }
        }
        if (hay(estado)) {
            sql += "AND seg.estado = ? ";
            params.add(estado);
        }
        if (hay(landing)) {
            sql += "AND (o.id_landing = ? OR d.id_landing = ?) ";
            params.add(landing);
            params.add(landing);
        }
        sql += "ORDER BY seg.codigo_segmento";

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            asignar(pstmt, params, pag);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(leerSegmento(rs));
                }
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return lista;
    }

    public Segmento obtenerSegmento(String codigo) {
        if (!hay(codigo)) {
            return null;
        }
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(SQL_SEGMENTO + "WHERE seg.codigo_segmento = ?")) {
            pstmt.setString(1, codigo.trim());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return leerSegmento(rs);
                }
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }

    public int contarSegmentosPorEstado(String estado) {
        return contar("SELECT COUNT(*) FROM SEGMENTO WHERE estado = ?", lista(estado));
    }

    public double[] obtenerCapacidadRed() {
        double[] r = new double[3];
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT COALESCE(SUM(capacidad_total), 0), COALESCE(SUM(capacidad_utilizada), 0), " +
                             "COALESCE(SUM(capacidad_reservada), 0) FROM SEGMENTO");
             ResultSet rs = pstmt.executeQuery()) {
            if (rs.next()) {
                r[0] = rs.getDouble(1);
                r[1] = rs.getDouble(2);
                r[2] = rs.getDouble(3);
            }
        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        return r;
    }

    public boolean existeSegmento(String codigo) {
        return contar("SELECT COUNT(*) FROM SEGMENTO WHERE codigo_segmento = ?", lista(codigo.trim())) > 0;
    }

    // ¿Ya hay un segmento entre esas dos estaciones (en cualquier sentido)?
    public String segmentoEntre(String origen, String destino) {
        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT codigo_segmento FROM SEGMENTO WHERE " +
                             "(LANDING_STATION_id_origen = ? AND LANDING_STATION_id_destino = ?) " +
                             "OR (LANDING_STATION_id_origen = ? AND LANDING_STATION_id_destino = ?) LIMIT 1")) {
            pstmt.setString(1, origen);
            pstmt.setString(2, destino);
            pstmt.setString(3, destino);
            pstmt.setString(4, origen);
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

    public boolean crearSegmento(String codigo, double capacidadTotal, String origen, String destino) {
        return ejecutar("INSERT INTO SEGMENTO (codigo_segmento, capacidad_total, capacidad_utilizada, " +
                        "capacidad_reservada, estado, LANDING_STATION_id_origen, LANDING_STATION_id_destino) " +
                        "VALUES (?, ?, 0, 0, 'Operativo', ?, ?)",
                codigo.trim().toUpperCase(), capacidadTotal, origen, destino);
    }

    // La capacidad no puede quedar por debajo de lo utilizado + reservado (la consulta lo vuelve a comprobar)
    public boolean actualizarSegmento(String codigo, double capacidadTotal, String estado) {
        return ejecutar("UPDATE SEGMENTO SET capacidad_total = ?, estado = ? " +
                        "WHERE codigo_segmento = ? AND capacidad_utilizada + capacidad_reservada <= ?",
                capacidadTotal, estado, codigo, capacidadTotal);
    }

    // Solo si nadie lo usa (la consulta lo vuelve a comprobar)
    public boolean borrarSegmento(String codigo) {
        return ejecutar("DELETE seg FROM SEGMENTO seg WHERE seg.codigo_segmento = ? AND " +
                DEPENDENCIAS_SEGMENTO.replace("seg.codigo_segmento", "?") + "= 0",
                codigo, codigo, codigo, codigo, codigo, codigo);
    }
}
