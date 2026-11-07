package dao;

import beans.ClienteAfectado;
import beans.EventoHistorico;
import beans.Incidencia;
import beans.IndicadorMes;
import beans.LandingStation;
import beans.Mantenimiento;
import beans.Paginacion;
import beans.Segmento;
import beans.Servicio;
import beans.ServicioAfectado;
import beans.UtilizacionHist;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;


/*
 * Consultas del rol Supervisor (RF32 - RF39).
 * El Supervisor solo consulta: aquí no hay INSERT, UPDATE ni DELETE.
 *
 * Los listados largos se paginan en el servidor: si se recibe un objeto Paginacion,
 * primero se cuenta el total con SELECT COUNT(*) y luego se agrega "LIMIT ?, ?".
 * Si se recibe null, se devuelven todas las filas (por ejemplo, para los totales de un reporte).
 */
public class SupervisorDAO {

    private final String url = "jdbc:mysql://localhost:3306/mibasededatos";
    private final String user = "root";
    private final String pass = "root";


    private Connection conectar() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(url, user, pass);
    }


    // =====================================================
    // Condiciones que se repiten en varias consultas
    // =====================================================

    // Incidencia activa: aún no tiene el servicio restaurado ni está cerrada
    private final String INCIDENCIA_ACTIVA = "i.estado NOT IN ('Cerrada', 'Servicio restaurado') ";

    // Ocupación = (utilizada + reservada) / total, igual que Segmento.getPorcentajeOcupacion()
    // (es la misma regla que usa el Capacity Planner para las alertas de RF12)
    private final String OCUPACION =
            "((seg.capacidad_utilizada + seg.capacidad_reservada) * 100 / seg.capacidad_total) ";

    // Cantidad de segmentos Fuera de servicio en la ruta del servicio "s" (> 0 = Interrumpido)
    private final String TRAMOS_FUERA_SERVICIO =
            "(SELECT COUNT(*) FROM RUTA_has_SEGMENTO x " +
                    "INNER JOIN SEGMENTO y ON x.SEGMENTO_codigo_segmento = y.codigo_segmento " +
                    "WHERE x.RUTA_id_ruta = s.RUTA_id_ruta AND y.estado = 'Fuera de servicio') ";

    // Incidencias activas del segmento "seg" (columna de INCIDENCIA o tabla INCIDENCIA_SEGMENTO)
    private final String INCIDENCIAS_ACTIVAS_SEGMENTO =
            "(SELECT COUNT(*) FROM INCIDENCIA i " +
                    "WHERE " + INCIDENCIA_ACTIVA +
                    "AND (i.SEGMENTO_codigo_segmento = seg.codigo_segmento " +
                    "OR i.codigo_incidencia IN (SELECT isg.codigo_incidencia FROM INCIDENCIA_SEGMENTO isg " +
                    "WHERE isg.codigo_segmento = seg.codigo_segmento))) ";

    // Servicios activos que pasan por algún segmento de la incidencia "i"
    private final String SERVICIOS_DE_INCIDENCIA =
            "(SELECT COUNT(DISTINCT s.id_servicio) FROM SERVICIO s " +
                    "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                    "WHERE s.estado = 'Activo' " +
                    "AND (rhs.SEGMENTO_codigo_segmento = i.SEGMENTO_codigo_segmento " +
                    "OR rhs.SEGMENTO_codigo_segmento IN (SELECT isg.codigo_segmento FROM INCIDENCIA_SEGMENTO isg " +
                    "WHERE isg.codigo_incidencia = i.codigo_incidencia))) ";


    private boolean hay(String valor) {
        return valor != null && !valor.trim().isEmpty();
    }

    private boolean esFecha(String valor) {
        return valor != null && valor.matches("\\d{4}-\\d{2}-\\d{2}");
    }

    // "Estación Lurín" -> "Lurín"
    private String nombreCorto(String nombreEstacion) {
        return nombreEstacion == null ? "" : nombreEstacion.replace("Estación ", "");
    }

    // Asigna los parámetros (todos texto) y, si hay paginación, los dos de LIMIT ?, ?
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

    // Cuenta las filas que devolvería una consulta (para la paginación)
    private int contarFilas(String sql, List<String> params) {
        return contar("SELECT COUNT(*) FROM (" + sql + ") AS t", params);
    }

    // Ejecuta un SELECT que devuelve un solo número
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

    // Ejecuta un "SELECT columna, COUNT(*) ... GROUP BY columna" y lo guarda en un mapa
    private Map<String, Integer> contarPorGrupo(String sql, List<String> params) {

        Map<String, Integer> mapa = new LinkedHashMap<>();

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, null);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    mapa.put(rs.getString(1), rs.getInt(2));
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return mapa;
    }

    // Antes de agregar LIMIT se cuenta el total de filas
    private String paginar(String sql, List<String> params, Paginacion pag) {
        if (pag == null) {
            return sql;
        }
        pag.setTotalRegistros(contarFilas(sql, params));
        return sql + " LIMIT ?, ?";
    }


    // =====================================================
    // SEGMENTOS (RF33, RF37)
    // =====================================================

    private final String SQL_SEGMENTO =
            "SELECT seg.codigo_segmento, seg.capacidad_total, " +
                    "seg.capacidad_utilizada, seg.capacidad_reservada, seg.estado, " +
                    "o.id_landing AS id_origen, o.nombre AS nombre_origen, " +
                    "o.ciudad AS ciudad_origen, o.pais AS pais_origen, " +
                    "d.id_landing AS id_destino, d.nombre AS nombre_destino, " +
                    "d.ciudad AS ciudad_destino, d.pais AS pais_destino, " +
                    INCIDENCIAS_ACTIVAS_SEGMENTO + "AS incidencias_activas " +
                    "FROM SEGMENTO seg " +
                    "INNER JOIN LANDING_STATION o ON seg.LANDING_STATION_id_origen = o.id_landing " +
                    "INNER JOIN LANDING_STATION d ON seg.LANDING_STATION_id_destino = d.id_landing ";


    private Segmento leerSegmento(ResultSet rs) throws SQLException {

        Segmento segmento = new Segmento();

        segmento.setCodigoSegmento(rs.getString("codigo_segmento"));
        segmento.setCapacidadTotal(rs.getDouble("capacidad_total"));
        segmento.setCapacidadUtilizada(rs.getDouble("capacidad_utilizada"));
        segmento.setCapacidadReservada(rs.getDouble("capacidad_reservada"));
        segmento.setEstado(rs.getString("estado"));

        segmento.setIdOrigen(rs.getString("id_origen"));
        segmento.setNombreOrigen(rs.getString("nombre_origen"));
        segmento.setCiudadOrigen(rs.getString("ciudad_origen"));
        segmento.setPaisOrigen(rs.getString("pais_origen"));

        segmento.setIdDestino(rs.getString("id_destino"));
        segmento.setNombreDestino(rs.getString("nombre_destino"));
        segmento.setCiudadDestino(rs.getString("ciudad_destino"));
        segmento.setPaisDestino(rs.getString("pais_destino"));

        segmento.setIncidenciasAbiertas(rs.getInt("incidencias_activas"));

        return segmento;
    }


    /*
     * buscar: código, estación o país | estado: estado del segmento
     * nivel: normal (< 80%), alta (80% - 95%), critica (> 95%) o minimo80 (80% o más)
     * landing: segmentos que salen o llegan a esa estación | codigo: un solo segmento
     * porOcupacion: true = de mayor a menor ocupación; false = por código
     */
    public List<Segmento> listarSegmentos(String buscar, String estado, String nivel, String landing,
                                         String codigo, boolean porOcupacion, Paginacion pag) {

        List<Segmento> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = SQL_SEGMENTO + "WHERE 1 = 1 ";

        if (hay(buscar)) {
            sql += "AND (seg.codigo_segmento LIKE ? OR o.nombre LIKE ? OR d.nombre LIKE ? " +
                    "OR o.pais LIKE ? OR d.pais LIKE ?) ";
            for (int k = 0; k < 5; k++) {
                params.add("%" + buscar.trim() + "%");
            }
        }
        if (hay(estado)) {
            sql += "AND seg.estado = ? ";
            params.add(estado);
        }
        if ("normal".equals(nivel)) {
            sql += "AND " + OCUPACION + "< 80 ";
        } else if ("alta".equals(nivel)) {
            sql += "AND " + OCUPACION + ">= 80 AND " + OCUPACION + "<= 95 ";
        } else if ("critica".equals(nivel)) {
            sql += "AND " + OCUPACION + "> 95 ";
        } else if ("minimo80".equals(nivel)) {
            sql += "AND " + OCUPACION + ">= 80 ";
        }
        if (hay(landing)) {
            sql += "AND (seg.LANDING_STATION_id_origen = ? OR seg.LANDING_STATION_id_destino = ?) ";
            params.add(landing);
            params.add(landing);
        }
        if (hay(codigo)) {
            sql += "AND seg.codigo_segmento = ? ";
            params.add(codigo);
        }

        sql += porOcupacion
                ? "ORDER BY " + OCUPACION + "DESC, seg.codigo_segmento"
                : "ORDER BY seg.codigo_segmento";

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
        List<Segmento> lista = listarSegmentos(null, null, null, null, codigo, false, null);
        return lista.isEmpty() ? null : lista.get(0);
    }


    // Cantidad de segmentos por estado (Operativo, Degradado, ...)
    public Map<String, Integer> contarSegmentosPorEstado() {
        return contarPorGrupo("SELECT estado, COUNT(*) FROM SEGMENTO GROUP BY estado", new ArrayList<>());
    }


    // [0] total, [1] utilizada, [2] reservada de toda la red (Gbps)
    public double[] obtenerCapacidadRed() {

        double[] capacidad = new double[3];

        String sql = "SELECT SUM(capacidad_total), SUM(capacidad_utilizada), SUM(capacidad_reservada) " +
                "FROM SEGMENTO";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            if (rs.next()) {
                capacidad[0] = rs.getDouble(1);
                capacidad[1] = rs.getDouble(2);
                capacidad[2] = rs.getDouble(3);
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return capacidad;
    }


    // Cantidad de segmentos en un nivel de utilización (normal, alta, critica, minimo80)
    public int contarSegmentosPorNivel(String nivel) {
        String sql = "SELECT COUNT(*) FROM SEGMENTO seg WHERE ";
        if ("normal".equals(nivel)) {
            sql += OCUPACION + "< 80";
        } else if ("alta".equals(nivel)) {
            sql += OCUPACION + ">= 80 AND " + OCUPACION + "<= 95";
        } else if ("critica".equals(nivel)) {
            sql += OCUPACION + "> 95";
        } else {
            sql += OCUPACION + ">= 80";
        }
        return contar(sql, new ArrayList<>());
    }


    // Códigos de las rutas que pasan por el segmento
    public List<String> listarRutasDeSegmento(String codigo) {

        List<String> lista = new ArrayList<>();

        String sql = "SELECT r.codigo FROM RUTA r " +
                "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = r.id_ruta " +
                "WHERE rhs.SEGMENTO_codigo_segmento = ? ORDER BY r.codigo";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    lista.add(rs.getString(1));
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // Servicios (no cancelados) cuya ruta pasa por el segmento, con el RUC del cliente
    public List<ServicioAfectado> listarServiciosDeSegmento(String codigo) {

        List<ServicioAfectado> lista = new ArrayList<>();

        String sql = "SELECT s.id_servicio, s.RUTA_id_ruta, r.codigo, s.capacidad_contratada, s.estado, " +
                "c.id_cliente, c.razon_social, c.ruc " +
                "FROM SERVICIO s " +
                "INNER JOIN RUTA r ON s.RUTA_id_ruta = r.id_ruta " +
                "INNER JOIN CLIENTE c ON s.CLIENTE_id_cliente = c.id_cliente " +
                "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                "WHERE rhs.SEGMENTO_codigo_segmento = ? AND s.estado <> 'Cancelado' " +
                "ORDER BY s.id_servicio";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    ServicioAfectado sa = new ServicioAfectado();
                    sa.setIdServicio(rs.getInt("id_servicio"));
                    sa.setIdRuta(rs.getInt("RUTA_id_ruta"));
                    sa.setCodigoRuta(rs.getString("codigo"));
                    sa.setCapacidadContratada(rs.getDouble("capacidad_contratada"));
                    sa.setIdCliente(rs.getInt("id_cliente"));
                    sa.setRazonSocial(rs.getString("razon_social"));
                    sa.setRuc(rs.getString("ruc"));
                    sa.setEstado(rs.getString("estado"));
                    lista.add(sa);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // Registros mensuales de UTILIZACION_HIST (de un segmento, de los segmentos de una estación o de toda la red)
    public List<UtilizacionHist> listarHistorialUtilizacion(String codigo, String landing, String desde, String hasta) {

        List<UtilizacionHist> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = "SELECT id_registro, SEGMENTO_codigo_segmento, fecha, capacidad_total, " +
                "capacidad_utilizada, capacidad_disponible " +
                "FROM UTILIZACION_HIST WHERE 1 = 1 ";

        if (hay(codigo)) {
            sql += "AND SEGMENTO_codigo_segmento = ? ";
            params.add(codigo);
        }
        if (hay(landing)) {
            sql += "AND SEGMENTO_codigo_segmento IN (SELECT codigo_segmento FROM SEGMENTO " +
                    "WHERE LANDING_STATION_id_origen = ? OR LANDING_STATION_id_destino = ?) ";
            params.add(landing);
            params.add(landing);
        }
        if (esFecha(desde)) {
            sql += "AND fecha >= ? ";
            params.add(desde);
        }
        if (esFecha(hasta)) {
            sql += "AND fecha <= ? ";
            params.add(hasta);
        }
        sql += "ORDER BY SEGMENTO_codigo_segmento, fecha";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, null);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    UtilizacionHist u = new UtilizacionHist();
                    u.setIdRegistro(rs.getInt("id_registro"));
                    u.setCodigoSegmento(rs.getString("SEGMENTO_codigo_segmento"));
                    u.setFecha(rs.getString("fecha"));
                    u.setCapacidadTotal(rs.getDouble("capacidad_total"));
                    u.setCapacidadUtilizada(rs.getDouble("capacidad_utilizada"));
                    u.setCapacidadDisponible(rs.getDouble("capacidad_disponible"));
                    lista.add(u);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // =====================================================
    // LANDING STATIONS (RF32)
    // =====================================================

    public List<LandingStation> listarLandingStations(String buscar, String estado, boolean conIncidencias,
                                                      Paginacion pag) {

        List<LandingStation> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = "SELECT ls.id_landing, ls.nombre, ls.ciudad, ls.pais, ls.estado, " +
                "(SELECT COUNT(*) FROM SEGMENTO seg WHERE seg.LANDING_STATION_id_origen = ls.id_landing " +
                "OR seg.LANDING_STATION_id_destino = ls.id_landing) AS segmentos, " +
                "(SELECT COUNT(*) FROM INCIDENCIA i WHERE i.LANDING_STATION_id_landing = ls.id_landing " +
                "AND " + INCIDENCIA_ACTIVA + ") AS incidencias, " +
                "m.codigo_mantenimiento, m.estado AS estado_mantenimiento, m.fecha_programada " +
                "FROM LANDING_STATION ls " +
                "LEFT JOIN MANTENIMIENTO m ON ls.MANTENIMIENTO_id_mantenimiento1 = m.codigo_mantenimiento " +
                "WHERE 1 = 1 ";

        if (hay(buscar)) {
            sql += "AND (ls.id_landing LIKE ? OR ls.nombre LIKE ? OR ls.ciudad LIKE ? OR ls.pais LIKE ?) ";
            for (int k = 0; k < 4; k++) {
                params.add("%" + buscar.trim() + "%");
            }
        }
        if (hay(estado)) {
            sql += "AND ls.estado = ? ";
            params.add(estado);
        }
        // solo estaciones con al menos una incidencia activa (mismo criterio que contarLandingConIncidencias)
        if (conIncidencias) {
            sql += "AND EXISTS (SELECT 1 FROM INCIDENCIA i WHERE i.LANDING_STATION_id_landing = ls.id_landing " +
                    "AND " + INCIDENCIA_ACTIVA + ") ";
        }
        sql += "ORDER BY ls.id_landing";

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, pag);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    LandingStation ls = new LandingStation();
                    ls.setIdLanding(rs.getString("id_landing"));
                    ls.setNombre(rs.getString("nombre"));
                    ls.setCiudad(rs.getString("ciudad"));
                    ls.setPais(rs.getString("pais"));
                    ls.setEstado(rs.getString("estado"));
                    ls.setCantidadSegmentos(rs.getInt("segmentos"));
                    ls.setIncidenciasActivas(rs.getInt("incidencias"));
                    ls.setCodigoMantenimiento(rs.getString("codigo_mantenimiento"));
                    ls.setEstadoMantenimiento(rs.getString("estado_mantenimiento"));
                    ls.setFechaMantenimiento(rs.getString("fecha_programada"));
                    lista.add(ls);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    public Map<String, Integer> contarLandingPorEstado() {
        return contarPorGrupo("SELECT estado, COUNT(*) FROM LANDING_STATION GROUP BY estado", new ArrayList<>());
    }


    // Estaciones con al menos una incidencia activa
    public int contarLandingConIncidencias() {
        return contar("SELECT COUNT(DISTINCT i.LANDING_STATION_id_landing) FROM INCIDENCIA i " +
                "WHERE " + INCIDENCIA_ACTIVA, new ArrayList<>());
    }


    // =====================================================
    // INCIDENCIAS (RF34)
    // =====================================================

    /*
     * Arma el WHERE de las incidencias con los filtros que vengan llenos.
     * grupo: "abiertas" (activas) o "cerradas" (Servicio restaurado o Cerrada)
     * segmento: incidencias de ese segmento (columna de INCIDENCIA o tabla INCIDENCIA_SEGMENTO)
     * desde / hasta: fecha de detección
     */
    private String whereIncidencias(String grupo, String estado, String severidad, String segmento,
                                    String landing, String desde, String hasta, List<String> params) {

        String sql = "WHERE 1 = 1 ";

        if ("abiertas".equals(grupo)) {
            sql += "AND " + INCIDENCIA_ACTIVA;
        } else if ("cerradas".equals(grupo)) {
            sql += "AND i.estado IN ('Cerrada', 'Servicio restaurado') ";
        }
        if (hay(estado)) {
            sql += "AND i.estado = ? ";
            params.add(estado);
        }
        if (hay(severidad)) {
            sql += "AND i.severidad = ? ";
            params.add(severidad);
        }
        if (hay(segmento)) {
            sql += "AND (i.SEGMENTO_codigo_segmento = ? OR i.codigo_incidencia IN " +
                    "(SELECT isg.codigo_incidencia FROM INCIDENCIA_SEGMENTO isg WHERE isg.codigo_segmento = ?)) ";
            params.add(segmento);
            params.add(segmento);
        }
        if (hay(landing)) {
            sql += "AND i.LANDING_STATION_id_landing = ? ";
            params.add(landing);
        }
        if (esFecha(desde)) {
            sql += "AND DATE(i.fecha_deteccion) >= ? ";
            params.add(desde);
        }
        if (esFecha(hasta)) {
            sql += "AND DATE(i.fecha_deteccion) <= ? ";
            params.add(hasta);
        }
        return sql;
    }


    /*
     * orden: "severidad" (Crítica primero y luego por fecha), "reciente" (más nuevas primero)
     * o cualquier otro valor (por fecha de detección, de la más antigua a la más nueva)
     */
    public List<Incidencia> listarIncidencias(String grupo, String estado, String severidad, String segmento,
                                              String landing, String desde, String hasta,
                                              String orden, Paginacion pag) {

        List<Incidencia> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = "SELECT i.codigo_incidencia, i.titulo, i.descripcion, i.severidad, i.estado, " +
                "DATE(i.fecha_deteccion) AS fecha, i.hora, " +
                "i.SEGMENTO_codigo_segmento, i.LANDING_STATION_id_landing, " +
                "o.nombre AS nombre_origen, d.nombre AS nombre_destino, ls.nombre AS nombre_landing, " +
                SERVICIOS_DE_INCIDENCIA + "AS servicios " +
                "FROM INCIDENCIA i " +
                "INNER JOIN SEGMENTO seg ON i.SEGMENTO_codigo_segmento = seg.codigo_segmento " +
                "INNER JOIN LANDING_STATION o ON seg.LANDING_STATION_id_origen = o.id_landing " +
                "INNER JOIN LANDING_STATION d ON seg.LANDING_STATION_id_destino = d.id_landing " +
                "INNER JOIN LANDING_STATION ls ON i.LANDING_STATION_id_landing = ls.id_landing " +
                whereIncidencias(grupo, estado, severidad, segmento, landing, desde, hasta, params);

        if ("severidad".equals(orden)) {
            sql += "ORDER BY CASE i.severidad WHEN 'Crítica' THEN 1 WHEN 'Alta' THEN 2 " +
                    "WHEN 'Media' THEN 3 ELSE 4 END, i.fecha_deteccion, i.hora";
        } else if ("reciente".equals(orden)) {
            sql += "ORDER BY i.fecha_deteccion DESC, i.hora DESC";
        } else {
            sql += "ORDER BY i.fecha_deteccion, i.hora";
        }

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, pag);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Incidencia inc = new Incidencia();
                    inc.setCodigoIncidencia(rs.getString("codigo_incidencia"));
                    inc.setTitulo(rs.getString("titulo"));
                    inc.setDescripcion(rs.getString("descripcion"));
                    inc.setSeveridad(rs.getString("severidad"));
                    inc.setEstado(rs.getString("estado"));
                    inc.setFechaDeteccion(rs.getString("fecha") + " " + rs.getString("hora"));
                    inc.setCodigoSegmento(rs.getString("SEGMENTO_codigo_segmento"));
                    inc.setIdLanding(rs.getString("LANDING_STATION_id_landing"));
                    inc.setNombreLanding(nombreCorto(rs.getString("nombre_landing")));
                    inc.setTramo(nombreCorto(rs.getString("nombre_origen")) + " → "
                            + nombreCorto(rs.getString("nombre_destino")));
                    inc.setServiciosAfectados(rs.getInt("servicios"));
                    lista.add(inc);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // Incidencias agrupadas por una columna ("severidad" o "estado"), con los mismos filtros del listado
    public Map<String, Integer> contarIncidenciasPor(String columna, String grupo, String severidad,
                                                     String segmento, String landing, String desde, String hasta) {
        List<String> params = new ArrayList<>();
        String col = "estado".equals(columna) ? "i.estado" : "i.severidad";
        String sql = "SELECT " + col + ", COUNT(*) FROM INCIDENCIA i " +
                whereIncidencias(grupo, null, severidad, segmento, landing, desde, hasta, params) +
                "GROUP BY " + col;
        return contarPorGrupo(sql, params);
    }


    public int contarIncidencias(String grupo, String severidad, String segmento,
                                 String landing, String desde, String hasta) {
        List<String> params = new ArrayList<>();
        String sql = "SELECT COUNT(*) FROM INCIDENCIA i " +
                whereIncidencias(grupo, null, severidad, segmento, landing, desde, hasta, params);
        return contar(sql, params);
    }


    // Segmento con más incidencias según los filtros: [0] código, [1] cantidad
    public String[] obtenerSegmentoMasAfectado(String grupo, String severidad, String segmento,
                                               String landing, String desde, String hasta) {

        List<String> params = new ArrayList<>();
        String sql = "SELECT i.SEGMENTO_codigo_segmento, COUNT(*) AS cantidad FROM INCIDENCIA i " +
                whereIncidencias(grupo, null, severidad, segmento, landing, desde, hasta, params) +
                "GROUP BY i.SEGMENTO_codigo_segmento ORDER BY cantidad DESC, i.SEGMENTO_codigo_segmento LIMIT 1";

        Map<String, Integer> mapa = contarPorGrupo(sql, params);
        for (String codigo : mapa.keySet()) {
            return new String[]{codigo, String.valueOf(mapa.get(codigo))};
        }
        return null;
    }


    // =====================================================
    // SERVICIOS Y CLIENTES AFECTADOS (RF35)
    // =====================================================

    /*
     * WHERE de los servicios afectados: servicios Activos cuya ruta pasa por un segmento
     * con incidencias activas. Los filtros (incidencia, severidad, landing) se aplican a las
     * incidencias; segmento limita los segmentos afectados; situacion: Interrumpido o Degradado.
     */
    private String whereAfectados(String incidencia, String severidad, String segmento, String landing,
                                  String situacion, List<String> params) {

        String condicion = "";
        List<String> paramsCondicion = new ArrayList<>();

        if (hay(incidencia)) {
            condicion += "AND i.codigo_incidencia = ? ";
            paramsCondicion.add(incidencia);
        }
        if (hay(severidad)) {
            condicion += "AND i.severidad = ? ";
            paramsCondicion.add(severidad);
        }
        if (hay(landing)) {
            condicion += "AND i.LANDING_STATION_id_landing = ? ";
            paramsCondicion.add(landing);
        }

        // Segmentos con incidencias activas (columna de INCIDENCIA + tabla INCIDENCIA_SEGMENTO)
        String segmentosAfectados =
                "(SELECT i.SEGMENTO_codigo_segmento FROM INCIDENCIA i " +
                        "WHERE " + INCIDENCIA_ACTIVA + condicion +
                        "UNION " +
                        "SELECT isg.codigo_segmento FROM INCIDENCIA_SEGMENTO isg " +
                        "INNER JOIN INCIDENCIA i ON isg.codigo_incidencia = i.codigo_incidencia " +
                        "WHERE " + INCIDENCIA_ACTIVA + condicion + ") ";

        String sql = "s.estado = 'Activo' AND s.RUTA_id_ruta IN " +
                "(SELECT rhs.RUTA_id_ruta FROM RUTA_has_SEGMENTO rhs " +
                "WHERE rhs.SEGMENTO_codigo_segmento IN " + segmentosAfectados;

        // los parámetros de la condición van dos veces (una por cada parte del UNION)
        params.addAll(paramsCondicion);
        params.addAll(paramsCondicion);

        if (hay(segmento)) {
            sql += "AND rhs.SEGMENTO_codigo_segmento = ? ";
            params.add(segmento);
        }
        sql += ") ";

        if ("Interrumpido".equals(situacion)) {
            sql += "AND " + TRAMOS_FUERA_SERVICIO + "> 0 ";
        } else if ("Degradado".equals(situacion)) {
            sql += "AND " + TRAMOS_FUERA_SERVICIO + "= 0 ";
        }
        return sql;
    }


    // Servicios afectados (interrumpidos primero). idCliente > 0 = solo los de ese cliente
    public List<ServicioAfectado> listarServiciosAfectados(String buscar, String incidencia, String severidad,
                                                           String segmento, String landing, String situacion,
                                                           int idCliente, Paginacion pag) {

        List<ServicioAfectado> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = "SELECT s.id_servicio, s.RUTA_id_ruta, r.codigo, s.capacidad_contratada, " +
                "c.id_cliente, c.razon_social, c.ruc, " +
                TRAMOS_FUERA_SERVICIO + "AS tramos " +
                "FROM SERVICIO s " +
                "INNER JOIN RUTA r ON s.RUTA_id_ruta = r.id_ruta " +
                "INNER JOIN CLIENTE c ON s.CLIENTE_id_cliente = c.id_cliente " +
                "WHERE " + whereAfectados(incidencia, severidad, segmento, landing, situacion, params);

        if (hay(buscar)) {
            sql += "AND (c.razon_social LIKE ? OR c.ruc LIKE ?) ";
            params.add("%" + buscar.trim() + "%");
            params.add("%" + buscar.trim() + "%");
        }
        if (idCliente > 0) {
            sql += "AND c.id_cliente = ? ";
            params.add(String.valueOf(idCliente));
        }
        sql += "ORDER BY tramos DESC, s.id_servicio";

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, pag);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    ServicioAfectado sa = new ServicioAfectado();
                    sa.setIdServicio(rs.getInt("id_servicio"));
                    sa.setIdRuta(rs.getInt("RUTA_id_ruta"));
                    sa.setCodigoRuta(rs.getString("codigo"));
                    sa.setCapacidadContratada(rs.getDouble("capacidad_contratada"));
                    sa.setIdCliente(rs.getInt("id_cliente"));
                    sa.setRazonSocial(rs.getString("razon_social"));
                    sa.setRuc(rs.getString("ruc"));
                    sa.setTramosFueraServicio(rs.getInt("tramos"));
                    lista.add(sa);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        // Incidencias activas de la ruta de cada servicio de la página
        for (ServicioAfectado sa : lista) {
            completarIncidencias(sa);
        }

        return lista;
    }


    // Llena "incidencias", "segmentos" y "severidadMaxima" con las incidencias activas de la ruta
    private void completarIncidencias(ServicioAfectado sa) {

        String sql = "SELECT i.codigo_incidencia, i.severidad, i.SEGMENTO_codigo_segmento AS segmento " +
                "FROM INCIDENCIA i " +
                "WHERE " + INCIDENCIA_ACTIVA +
                "AND i.SEGMENTO_codigo_segmento IN " +
                "(SELECT SEGMENTO_codigo_segmento FROM RUTA_has_SEGMENTO WHERE RUTA_id_ruta = ?) " +
                "UNION " +
                "SELECT i.codigo_incidencia, i.severidad, isg.codigo_segmento AS segmento " +
                "FROM INCIDENCIA_SEGMENTO isg " +
                "INNER JOIN INCIDENCIA i ON isg.codigo_incidencia = i.codigo_incidencia " +
                "WHERE " + INCIDENCIA_ACTIVA +
                "AND isg.codigo_segmento IN " +
                "(SELECT SEGMENTO_codigo_segmento FROM RUTA_has_SEGMENTO WHERE RUTA_id_ruta = ?) " +
                "ORDER BY codigo_incidencia DESC";

        List<String> incidencias = new ArrayList<>();
        List<String> segmentos = new ArrayList<>();
        String severidadMaxima = null;

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, sa.getIdRuta());
            pstmt.setInt(2, sa.getIdRuta());

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    String codigo = rs.getString("codigo_incidencia");
                    String segmento = rs.getString("segmento");
                    String severidad = rs.getString("severidad");
                    if (!incidencias.contains(codigo)) {
                        incidencias.add(codigo);
                    }
                    if (!segmentos.contains(segmento)) {
                        segmentos.add(segmento);
                    }
                    if (pesoSeveridad(severidad) > pesoSeveridad(severidadMaxima)) {
                        severidadMaxima = severidad;
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        sa.setIncidencias(String.join(", ", incidencias));
        sa.setSegmentos(String.join(", ", segmentos));
        sa.setSeveridadMaxima(severidadMaxima);
    }


    // Crítica = 4, Alta = 3, Media = 2, Baja = 1
    public static int pesoSeveridad(String severidad) {
        if ("Crítica".equals(severidad)) return 4;
        if ("Alta".equals(severidad)) return 3;
        if ("Media".equals(severidad)) return 2;
        if ("Baja".equals(severidad)) return 1;
        return 0;
    }


    // Clientes con servicios afectados (cantidad de servicios, Gbps y peor situación)
    public List<ClienteAfectado> listarClientesAfectados(String buscar, String incidencia, String severidad,
                                                         String segmento, String landing, String situacion,
                                                         Paginacion pag) {

        List<ClienteAfectado> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = "SELECT c.id_cliente, c.razon_social, c.ruc, c.correo, c.telefono, " +
                "COUNT(*) AS servicios, SUM(a.capacidad_contratada) AS gbps, MAX(a.tramos) AS tramos " +
                "FROM (SELECT s.id_servicio, s.CLIENTE_id_cliente, s.capacidad_contratada, " +
                TRAMOS_FUERA_SERVICIO + "AS tramos " +
                "FROM SERVICIO s " +
                "WHERE " + whereAfectados(incidencia, severidad, segmento, landing, situacion, params) +
                ") AS a " +
                "INNER JOIN CLIENTE c ON a.CLIENTE_id_cliente = c.id_cliente ";

        if (hay(buscar)) {
            sql += "WHERE c.razon_social LIKE ? OR c.ruc LIKE ? ";
            params.add("%" + buscar.trim() + "%");
            params.add("%" + buscar.trim() + "%");
        }
        sql += "GROUP BY c.id_cliente, c.razon_social, c.ruc, c.correo, c.telefono " +
                "ORDER BY c.id_cliente";

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, pag);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    ClienteAfectado ca = new ClienteAfectado();
                    ca.setIdCliente(rs.getInt("id_cliente"));
                    ca.setRazonSocial(rs.getString("razon_social"));
                    ca.setRuc(rs.getString("ruc"));
                    ca.setCorreo(rs.getString("correo"));
                    ca.setTelefono(rs.getString("telefono"));
                    ca.setServiciosAfectados(rs.getInt("servicios"));
                    ca.setCapacidadAfectada(rs.getDouble("gbps"));
                    ca.setTramosFueraServicio(rs.getInt("tramos"));
                    lista.add(ca);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // [0] servicios afectados, [1] clientes afectados, [2] Gbps afectados
    public double[] resumirAfectados(String incidencia, String severidad, String segmento,
                                     String landing, String situacion) {

        double[] resumen = new double[3];
        List<String> params = new ArrayList<>();

        String sql = "SELECT COUNT(*), COUNT(DISTINCT s.CLIENTE_id_cliente), SUM(s.capacidad_contratada) " +
                "FROM SERVICIO s WHERE " +
                whereAfectados(incidencia, severidad, segmento, landing, situacion, params);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, null);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    resumen[0] = rs.getInt(1);
                    resumen[1] = rs.getInt(2);
                    resumen[2] = rs.getDouble(3);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return resumen;
    }


    public int contarServiciosActivos() {
        return contar("SELECT COUNT(*) FROM SERVICIO WHERE estado = 'Activo'", new ArrayList<>());
    }

    public int contarClientes() {
        return contar("SELECT COUNT(*) FROM CLIENTE", new ArrayList<>());
    }


    // =====================================================
    // MANTENIMIENTOS (RF36)
    // =====================================================

    /*
     * estado: un estado exacto, "abiertas" (Programado / En ejecución) o "cerradas" (Finalizado / Cancelado)
     * desde / hasta: fecha programada | segmento / landing: elemento del mantenimiento
     */
    public List<Mantenimiento> listarMantenimientos(String estado, String tipo, String desde, String hasta,
                                                    String segmento, String landing, Paginacion pag) {

        List<Mantenimiento> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = "SELECT m.codigo_mantenimiento, m.tipo, m.estado, m.fecha_programada, " +
                "m.hora_inicio, m.duracion_estimada, a.titulo, seg.codigo_segmento, " +
                "o.nombre AS nombre_origen, d.nombre AS nombre_destino " +
                "FROM MANTENIMIENTO m " +
                "LEFT JOIN ACTIVIDAD_MANTENIMIENTO a ON m.ACTIVIDAD_MANTENIMIENTO_id_actividad = a.id_actividad " +
                "LEFT JOIN SEGMENTO seg ON seg.MANTENIMIENTO_id_mantenimiento = m.codigo_mantenimiento " +
                "LEFT JOIN LANDING_STATION o ON seg.LANDING_STATION_id_origen = o.id_landing " +
                "LEFT JOIN LANDING_STATION d ON seg.LANDING_STATION_id_destino = d.id_landing " +
                "WHERE 1 = 1 ";

        if ("abiertas".equals(estado)) {
            sql += "AND m.estado IN ('Programado', 'En ejecución') ";
        } else if ("cerradas".equals(estado)) {
            sql += "AND m.estado IN ('Finalizado', 'Cancelado') ";
        } else if (hay(estado)) {
            sql += "AND m.estado = ? ";
            params.add(estado);
        }
        if (hay(tipo)) {
            sql += "AND m.tipo = ? ";
            params.add(tipo);
        }
        if (esFecha(desde)) {
            sql += "AND m.fecha_programada >= ? ";
            params.add(desde);
        }
        if (esFecha(hasta)) {
            sql += "AND m.fecha_programada <= ? ";
            params.add(hasta);
        }
        if (hay(segmento)) {
            sql += "AND seg.codigo_segmento = ? ";
            params.add(segmento);
        }
        if (hay(landing)) {
            sql += "AND (seg.LANDING_STATION_id_origen = ? OR seg.LANDING_STATION_id_destino = ?) ";
            params.add(landing);
            params.add(landing);
        }

        // Pendientes primero (por fecha) y luego los terminados
        sql += "ORDER BY CASE WHEN m.estado IN ('Programado', 'En ejecución') THEN 0 ELSE 1 END, " +
                "m.fecha_programada, m.codigo_mantenimiento";

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, pag);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Mantenimiento m = new Mantenimiento();
                    m.setCodigoMantenimiento(rs.getString("codigo_mantenimiento"));
                    m.setTipo(rs.getString("tipo"));
                    m.setEstado(rs.getString("estado"));
                    m.setFechaProgramada(rs.getString("fecha_programada"));
                    m.setHoraInicio(rs.getString("hora_inicio"));
                    m.setDuracionEstimada(rs.getString("duracion_estimada"));
                    m.setActividad(rs.getString("titulo"));
                    m.setCodigoSegmento(rs.getString("codigo_segmento"));
                    if (rs.getString("codigo_segmento") != null) {
                        m.setTramo(nombreCorto(rs.getString("nombre_origen")) + " → "
                                + nombreCorto(rs.getString("nombre_destino")));
                    }
                    lista.add(m);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    public Map<String, Integer> contarMantenimientosPorEstado() {
        return contarPorGrupo("SELECT estado, COUNT(*) FROM MANTENIMIENTO GROUP BY estado", new ArrayList<>());
    }


    // =====================================================
    // HISTÓRICOS (RF39)
    // =====================================================

    // Utilización de la red (o de un segmento / estación) mes a mes, según UTILIZACION_HIST
    public List<IndicadorMes> listarIndicadoresMensuales(String segmento, String landing,
                                                         String desde, String hasta) {

        List<IndicadorMes> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sql = "SELECT fecha, SUM(capacidad_utilizada) AS utilizada, SUM(capacidad_total) AS total, " +
                "SUM(CASE WHEN capacidad_utilizada * 100 / capacidad_total >= 80 THEN 1 ELSE 0 END) AS altos " +
                "FROM UTILIZACION_HIST WHERE 1 = 1 ";

        if (hay(segmento)) {
            sql += "AND SEGMENTO_codigo_segmento = ? ";
            params.add(segmento);
        }
        if (hay(landing)) {
            sql += "AND SEGMENTO_codigo_segmento IN (SELECT codigo_segmento FROM SEGMENTO " +
                    "WHERE LANDING_STATION_id_origen = ? OR LANDING_STATION_id_destino = ?) ";
            params.add(landing);
            params.add(landing);
        }
        if (esFecha(desde)) {
            sql += "AND fecha >= ? ";
            params.add(desde);
        }
        if (esFecha(hasta)) {
            sql += "AND fecha <= ? ";
            params.add(hasta);
        }
        sql += "GROUP BY fecha ORDER BY fecha";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, null);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    IndicadorMes im = new IndicadorMes();
                    im.setMes(rs.getString("fecha"));
                    im.setCapacidadUtilizada(rs.getDouble("utilizada"));
                    im.setCapacidadTotal(rs.getDouble("total"));
                    im.setSegmentosAlta(rs.getInt("altos"));
                    lista.add(im);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        // Incidencias detectadas y mantenimientos programados en cada mes
        for (IndicadorMes im : lista) {
            String inicio = im.getMes();
            String fin = java.time.LocalDate.parse(inicio).plusMonths(1).minusDays(1).toString();
            im.setIncidencias(contarIncidencias(null, null, segmento, landing, inicio, fin));
            im.setMantenimientos(listarMantenimientos(null, null, inicio, fin, segmento, landing, null).size());
        }

        return lista;
    }


    // Primer mes con registros en UTILIZACION_HIST (para el filtro "Desde" por defecto)
    public String obtenerPrimerMesHistorial() {

        String sql = "SELECT MIN(fecha) FROM UTILIZACION_HIST";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            if (rs.next()) {
                return rs.getString(1);
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return null;
    }


    // Incidencias y mantenimientos del periodo, los más recientes primero. tipo: Incidencia, Mantenimiento o vacío
    public List<EventoHistorico> listarEventos(String desde, String hasta, String segmento, String tipo,
                                               Paginacion pag) {

        List<EventoHistorico> lista = new ArrayList<>();
        List<String> params = new ArrayList<>();

        String sqlIncidencias = "SELECT DATE(i.fecha_deteccion) AS fecha, i.hora AS hora, " +
                "i.SEGMENTO_codigo_segmento AS elemento, 'Incidencia' AS tipo, i.codigo_incidencia AS codigo, " +
                "i.titulo AS descripcion, i.estado AS estado " +
                "FROM INCIDENCIA i " +
                whereIncidencias(null, null, null, segmento, null, desde, hasta, params);

        String sqlMantenimientos = "SELECT m.fecha_programada AS fecha, m.hora_inicio AS hora, " +
                "seg.codigo_segmento AS elemento, 'Mantenimiento' AS tipo, m.codigo_mantenimiento AS codigo, " +
                "a.titulo AS descripcion, m.estado AS estado " +
                "FROM MANTENIMIENTO m " +
                "LEFT JOIN ACTIVIDAD_MANTENIMIENTO a ON m.ACTIVIDAD_MANTENIMIENTO_id_actividad = a.id_actividad " +
                "LEFT JOIN SEGMENTO seg ON seg.MANTENIMIENTO_id_mantenimiento = m.codigo_mantenimiento " +
                "WHERE 1 = 1 ";

        List<String> paramsMant = new ArrayList<>();
        if (esFecha(desde)) {
            sqlMantenimientos += "AND m.fecha_programada >= ? ";
            paramsMant.add(desde);
        }
        if (esFecha(hasta)) {
            sqlMantenimientos += "AND m.fecha_programada <= ? ";
            paramsMant.add(hasta);
        }
        if (hay(segmento)) {
            sqlMantenimientos += "AND seg.codigo_segmento = ? ";
            paramsMant.add(segmento);
        }

        String sql;
        if ("Incidencia".equals(tipo)) {
            sql = sqlIncidencias;
        } else if ("Mantenimiento".equals(tipo)) {
            sql = sqlMantenimientos;
            params = paramsMant;
        } else {
            sql = sqlIncidencias + "UNION ALL " + sqlMantenimientos;
            params.addAll(paramsMant);
        }

        sql = "SELECT * FROM (" + sql + ") AS eventos ORDER BY fecha DESC, hora DESC";

        sql = paginar(sql, params, pag);

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            asignar(pstmt, params, pag);

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    EventoHistorico ev = new EventoHistorico();
                    ev.setFecha(rs.getString("fecha"));
                    ev.setHora(rs.getString("hora"));
                    ev.setElemento(rs.getString("elemento"));
                    ev.setTipo(rs.getString("tipo"));
                    ev.setCodigo(rs.getString("codigo"));
                    ev.setDescripcion(rs.getString("descripcion"));
                    ev.setEstado(rs.getString("estado"));
                    lista.add(ev);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // Cantidad de mantenimientos con un estado dentro del periodo (por fecha programada)
    public int contarMantenimientos(String estado, String desde, String hasta, String segmento) {
        return listarMantenimientos(estado, null, desde, hasta, segmento, null, null).size();
    }


    // =====================================================
    // LISTAS PARA LOS FILTROS
    // =====================================================

    public List<LandingStation> listarLandingStations() {
        return listarLandingStations(null, null, false, null);
    }

    public List<Segmento> listarSegmentos() {
        return listarSegmentos(null, null, null, null, null, false, null);
    }
}
