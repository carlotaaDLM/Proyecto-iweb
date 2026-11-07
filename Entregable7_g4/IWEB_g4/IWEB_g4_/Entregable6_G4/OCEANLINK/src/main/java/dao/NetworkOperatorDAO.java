package dao;

import beans.Segmento;
import beans.Incidencia;
import beans.Paginacion;
import beans.SegmentoAtencion;
import beans.Servicio;
import beans.LandingStation;
import util.Conexion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.List;

public class NetworkOperatorDAO {

    private final String url =
            "jdbc:mysql://localhost:3306/mibasededatos";

    private final String user = "root";

    private final String pass = "root";


    // =========================================================
    // CONEXIÓN
    // =========================================================

    private Connection conectar() throws SQLException {

        return DriverManager.getConnection(
                url,
                user,
                pass
        );
    }


    // =========================================================
    // LISTAR SEGMENTOS
    // =========================================================

    public List<Segmento> listarSegmentos() {

        List<Segmento> lista =
                new ArrayList<>();

        String sql =
                "SELECT codigo_segmento, " +
                        "capacidad_total, " +
                        "capacidad_utilizada, " +
                        "capacidad_reservada, " +
                        "estado " +
                        "FROM SEGMENTO " +
                        "ORDER BY codigo_segmento";


        try {

            Class.forName(
                    "com.mysql.cj.jdbc.Driver"
            );

            try (
                    Connection conn = conectar();

                    PreparedStatement pstmt =
                            conn.prepareStatement(sql);

                    ResultSet rs =
                            pstmt.executeQuery()
            ) {

                while (rs.next()) {

                    Segmento segmento =
                            new Segmento();

                    segmento.setCodigoSegmento(
                            rs.getString(
                                    "codigo_segmento"
                            )
                    );

                    segmento.setCapacidadTotal(
                            rs.getDouble(
                                    "capacidad_total"
                            )
                    );

                    segmento.setCapacidadUtilizada(
                            rs.getDouble(
                                    "capacidad_utilizada"
                            )
                    );

                    segmento.setCapacidadReservada(
                            rs.getDouble(
                                    "capacidad_reservada"
                            )
                    );

                    segmento.setEstado(
                            rs.getString(
                                    "estado"
                            )
                    );

                    lista.add(segmento);
                }

            }

        } catch (
                SQLException |
                ClassNotFoundException e
        ) {

            e.printStackTrace();
        }

        return lista;
    }


    // =========================================================
    // SEGMENTOS OPERATIVOS
    // =========================================================

    public int contarSegmentosOperativos() {

        String sql =
                "SELECT COUNT(*) " +
                        "FROM segmento " +
                        "WHERE estado = ?";

        return contarPorEstado(
                sql,
                "Operativo"
        );
    }


    // =========================================================
    // SEGMENTOS FUERA DE SERVICIO
    // =========================================================

    public int contarSegmentosFueraServicio() {

        String sql =
                "SELECT COUNT(*) " +
                        "FROM segmento " +
                        "WHERE estado = ?";

        return contarPorEstado(
                sql,
                "Fuera de servicio"
        );
    }


    // =========================================================
    // SEGMENTOS QUE REQUIEREN SEGUIMIENTO
    // =========================================================

    public int contarSegmentosSeguimiento() {

        String sql =
                "SELECT COUNT(*) " +
                        "FROM segmento " +
                        "WHERE estado IN " +
                        "('Degradado', 'En mantenimiento')";

        return ejecutarConteo(sql);
    }


    // =========================================================
    // TOTAL DE SEGMENTOS
    // =========================================================

    public int contarTotalSegmentos() {

        String sql =
                "SELECT COUNT(*) " +
                        "FROM segmento";

        return ejecutarConteo(sql);
    }

    // =========================================================
    // INCIDENCIAS RECIENTES
    // =========================================================

    public List<Incidencia> listarIncidenciasRecientes() {

        List<Incidencia> lista = new ArrayList<>();

        String sql =
                "SELECT " +
                        "i.codigo_incidencia, " +
                        "i.titulo, " +
                        "i.descripcion, " +
                        "i.severidad, " +
                        "i.estado, " +
                        "DATE_FORMAT(i.fecha_deteccion, '%d/%m/%Y') AS fecha_deteccion, " +
                        "TIME_FORMAT(i.hora, '%H:%i:%s') AS hora, " +
                        "i.SEGMENTO_codigo_segmento AS codigo_segmento " +
                        "FROM INCIDENCIA i " +
                        "WHERE i.estado NOT IN " +
                        "('Cerrada', 'Servicio restaurado') " +
                        // Las últimas registradas primero (INC-016, INC-015...)
                        "ORDER BY CAST(SUBSTRING(i.codigo_incidencia, 5) AS UNSIGNED) DESC " +
                        "LIMIT 5";

        try {

            Class.forName(
                    "com.mysql.cj.jdbc.Driver"
            );

            try (
                    Connection conn = conectar();

                    PreparedStatement pstmt =
                            conn.prepareStatement(sql);

                    ResultSet rs =
                            pstmt.executeQuery()
            ) {

                while (rs.next()) {

                    Incidencia incidencia =
                            new Incidencia();

                    incidencia.setCodigoIncidencia(
                            rs.getString(
                                    "codigo_incidencia"
                            )
                    );

                    incidencia.setTitulo(
                            rs.getString(
                                    "titulo"
                            )
                    );

                    incidencia.setDescripcion(
                            rs.getString(
                                    "descripcion"
                            )
                    );

                    incidencia.setSeveridad(
                            rs.getString(
                                    "severidad"
                            )
                    );

                    incidencia.setEstado(
                            rs.getString(
                                    "estado"
                            )
                    );

                    incidencia.setFechaDeteccion(
                            rs.getString(
                                    "fecha_deteccion"
                            )
                                    + " "
                                    + rs.getString(
                                    "hora"
                            )
                    );

                    incidencia.setCodigoSegmento(
                            rs.getString(
                                    "codigo_segmento"
                            )
                    );

                    lista.add(incidencia);
                }
            }

        } catch (
                SQLException |
                ClassNotFoundException e
        ) {

            e.printStackTrace();
        }

        return lista;
    }

    // =========================================================
    // METODO PARA CONTAR POR ESTADO
    // =========================================================

    private int contarPorEstado(
            String sql,
            String estado
    ) {

        try {

            Class.forName(
                    "com.mysql.cj.jdbc.Driver"
            );

            try (
                    Connection conn = conectar();

                    PreparedStatement pstmt =
                            conn.prepareStatement(sql)
            ) {

                pstmt.setString(
                        1,
                        estado
                );

                try (
                        ResultSet rs =
                                pstmt.executeQuery()
                ) {

                    if (rs.next()) {

                        return rs.getInt(1);
                    }
                }

            }

        } catch (
                SQLException |
                ClassNotFoundException e
        ) {

            e.printStackTrace();
        }

        return 0;
    }


    // =========================================================
    // EJECUTAR CONTEO
    // =========================================================

    private int ejecutarConteo(
            String sql
    ) {

        try {

            Class.forName(
                    "com.mysql.cj.jdbc.Driver"
            );

            try (
                    Connection conn = conectar();

                    PreparedStatement pstmt =
                            conn.prepareStatement(sql);

                    ResultSet rs =
                            pstmt.executeQuery()
            ) {

                if (rs.next()) {

                    return rs.getInt(1);
                }

            }

        } catch (
                SQLException |
                ClassNotFoundException e
        ) {

            e.printStackTrace();
        }

        return 0;
    }

    public int contarIncidenciasAbiertas() {

        String sql = "SELECT COUNT(*) " +
                "FROM INCIDENCIA " +
                "WHERE estado NOT IN ('Cerrada', 'Servicio restaurado')";

        try (Connection c = Conexion.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    public int contarServiciosActivos() {

        String sql =
                "SELECT COUNT(*) " +
                        "FROM SERVICIO " +
                        "WHERE estado = 'Activo'";

        try (Connection c = Conexion.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                int total = rs.getInt(1);
                System.out.println("DAO - SERVICIOS ACTIVOS: " + total);
                return total;
            }

        } catch (SQLException e) {
            System.out.println("ERROR EN CONTAR SERVICIOS ACTIVOS:");
            e.printStackTrace();
        }

        return 0;

    }


    public int contarServiciosAfectados() {

        String sql =
                "SELECT COUNT(DISTINCT s.id_servicio) " +
                        "FROM SERVICIO s " +
                        "INNER JOIN RUTA_has_SEGMENTO rhs " +
                        "ON s.RUTA_id_ruta = rhs.RUTA_id_ruta " +
                        "INNER JOIN INCIDENCIA i " +
                        "ON rhs.SEGMENTO_codigo_segmento = i.SEGMENTO_codigo_segmento " +
                        "WHERE s.estado = 'Activo' " +
                        "AND i.estado NOT IN ('Cerrada', 'Servicio restaurado')";

        try (Connection c = Conexion.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    public int contarClientesAfectados() {

        String sql =
                "SELECT COUNT(DISTINCT s.CLIENTE_id_cliente) AS clientes_afectados " +
                        "FROM INCIDENCIA i " +
                        "INNER JOIN RUTA_has_SEGMENTO rhs " +
                        "ON i.SEGMENTO_codigo_segmento = rhs.SEGMENTO_codigo_segmento " +
                        "INNER JOIN SERVICIO s " +
                        "ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                        "WHERE i.estado IN ('Detectada', 'En análisis', " +
                        "'Reparación programada', 'En reparación') " +
                        "AND s.estado = 'Activo'";

        try (Connection conn = Conexion.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt("clientes_afectados");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    public List<SegmentoAtencion> obtenerSegmentosAtencion() {

        List<SegmentoAtencion> lista =
                new ArrayList<>();

        String sql =
                "SELECT " +
                "seg.codigo_segmento, " +
                "CONCAT(origen.ciudad, ' → ', destino.ciudad) AS tramo, " +
                "seg.estado, " +

                "COUNT(DISTINCT CASE " +
                "WHEN i.estado NOT IN ('Cerrada', 'Servicio restaurado') " +
                "THEN i.codigo_incidencia " +
                "END) AS incidencias_abiertas, " +

                "COUNT(DISTINCT CASE " +
                "WHEN s.estado = 'Activo' " +
                "THEN s.id_servicio " +
                "END) AS servicios_que_lo_usan " +

                "FROM SEGMENTO seg " +

                "INNER JOIN LANDING_STATION origen " +
                "ON seg.LANDING_STATION_id_origen = origen.id_landing " +

                "INNER JOIN LANDING_STATION destino " +
                "ON seg.LANDING_STATION_id_destino = destino.id_landing " +

                "LEFT JOIN RUTA_has_SEGMENTO rhs " +
                "ON seg.codigo_segmento = rhs.SEGMENTO_codigo_segmento " +

                "LEFT JOIN SERVICIO s " +
                "ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +

                "LEFT JOIN INCIDENCIA i " +
                "ON seg.codigo_segmento = i.SEGMENTO_codigo_segmento " +

                "WHERE seg.estado <> 'Operativo' " +

                "GROUP BY " +
                "seg.codigo_segmento, " +
                "origen.ciudad, " +
                "destino.ciudad, " +
                "seg.estado " +

                "ORDER BY " +
                "incidencias_abiertas DESC, " +
                "seg.codigo_segmento " +

                "LIMIT 3";

        try (
                Connection conn = Conexion.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()
        ) {

            while (rs.next()) {

                SegmentoAtencion segmento =
                        new SegmentoAtencion();

                segmento.setCodigoSegmento(
                        rs.getString("codigo_segmento")
                );

                segmento.setTramo(
                        rs.getString("tramo")
                );

                segmento.setEstado(
                        rs.getString("estado")
                );

                segmento.setIncidenciasAbiertas(
                        rs.getInt("incidencias_abiertas")
                );

                segmento.setServiciosQueLoUsan(
                        rs.getInt("servicios_que_lo_usan")
                );

                lista.add(segmento);
            }

        } catch (SQLException e) {

            System.out.println(
                    "DAO - ERROR SEGMENTOS ATENCION: "
                    + e.getMessage()
            );

            e.printStackTrace();
        }

        return lista;
    }


    public List<Incidencia> listarIncidenciasFiltradas(
            String buscar,
            String severidad,
            String estado,
            String desde,
            String hasta) {
        return listarIncidenciasFiltradas(buscar, severidad, estado, desde, hasta, null);
    }

    // Con paginación: pag != null agrega LIMIT y guarda el total en pag
    public List<Incidencia> listarIncidenciasFiltradas(
            String buscar,
            String severidad,
            String estado,
            String desde,
            String hasta,
            Paginacion pag) {

        List<Incidencia> lista = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
                "SELECT i.codigo_incidencia, i.titulo, " +
                        "i.descripcion, i.severidad, i.estado, " +
                        "DATE_FORMAT(i.fecha_deteccion, '%d/%m/%Y') " +
                        "AS fecha_deteccion, " +
                        "TIME_FORMAT(i.hora, '%H:%i') AS hora, " +
                        "i.SEGMENTO_codigo_segmento AS codigo_segmento " +
                        "FROM INCIDENCIA i WHERE 1=1 "
        );

        List<Object> parametros = new ArrayList<>();

        if (buscar != null && !buscar.trim().isEmpty()) {
            sql.append(
                    "AND (i.codigo_incidencia LIKE ? " +
                            "OR i.titulo LIKE ? " +
                            "OR i.descripcion LIKE ? " +
                            "OR i.SEGMENTO_codigo_segmento LIKE ?) "
            );

            String texto = "%" + buscar.trim() + "%";

            parametros.add(texto);
            parametros.add(texto);
            parametros.add(texto);
            parametros.add(texto);
        }

        if (severidad != null && !severidad.trim().isEmpty()) {
            sql.append("AND i.severidad = ? ");
            parametros.add(severidad.trim());
        }

        if (estado != null && !estado.trim().isEmpty()) {
            if (estado.equalsIgnoreCase("abiertas")) {
                sql.append(
                        "AND i.estado NOT IN " +
                                "('Cerrada', 'Servicio restaurado') "
                );
            } else {
                sql.append("AND i.estado = ? ");
                parametros.add(estado.trim());
            }
        }

        if (desde != null && !desde.trim().isEmpty()) {
            sql.append("AND DATE(i.fecha_deteccion) >= ? ");
            parametros.add(desde.trim());
        }

        if (hasta != null && !hasta.trim().isEmpty()) {
            sql.append("AND DATE(i.fecha_deteccion) <= ? ");
            parametros.add(hasta.trim());
        }

        sql.append(
                "ORDER BY i.fecha_deteccion DESC, i.hora DESC"
        );

        if (pag != null) {
            pag.setTotalRegistros(contarFilas(sql.toString(), parametros));
            sql.append(" LIMIT ?, ?");
        }

        try (
                Connection conn = conectar();
                PreparedStatement pstmt =
                        conn.prepareStatement(sql.toString())
        ) {
            for (int i = 0; i < parametros.size(); i++) {
                pstmt.setObject(i + 1, parametros.get(i));
            }
            if (pag != null) {
                pstmt.setInt(parametros.size() + 1, pag.getInicio());
                pstmt.setInt(parametros.size() + 2, pag.getTamanio());
            }

            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Incidencia incidencia = new Incidencia();

                    incidencia.setCodigoIncidencia(
                            rs.getString("codigo_incidencia")
                    );
                    incidencia.setTitulo(
                            rs.getString("titulo")
                    );
                    incidencia.setDescripcion(
                            rs.getString("descripcion")
                    );
                    incidencia.setSeveridad(
                            rs.getString("severidad")
                    );
                    incidencia.setEstado(
                            rs.getString("estado")
                    );
                    incidencia.setFechaDeteccion(
                            rs.getString("fecha_deteccion")
                                    + " "
                                    + rs.getString("hora")
                    );
                    incidencia.setCodigoSegmento(
                            rs.getString("codigo_segmento")
                    );

                    lista.add(incidencia);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // =========================================================
    // ===============  CRUD NETWORK OPERATOR  =================
    // =========================================================


    // =========================================================
    // CONTAR SEGMENTOS DE UN ESTADO (Degradado, En mantenimiento...)
    // =========================================================

    public int contarSegmentosPorEstado(String estado) {

        String sql =
                "SELECT COUNT(*) " +
                        "FROM segmento " +
                        "WHERE estado = ?";

        return contarPorEstado(sql, estado);
    }


    // =========================================================
    // CONTAR INCIDENCIAS POR SEVERIDAD
    // =========================================================

    public int contarIncidenciasPorSeveridad(String severidad) {

        String sql =
                "SELECT COUNT(*) " +
                        "FROM INCIDENCIA " +
                        "WHERE severidad = ?";

        return contarPorEstado(sql, severidad);
    }


    // =========================================================
    // TOTAL DE INCIDENCIAS
    // =========================================================

    public int contarTotalIncidencias() {

        return ejecutarConteo(
                "SELECT COUNT(*) FROM INCIDENCIA"
        );
    }


    // =========================================================
    // INCIDENCIAS CON SERVICIO RESTAURADO (aún sin cerrar)
    // =========================================================

    public int contarIncidenciasRestauradas() {

        String sql =
                "SELECT COUNT(*) " +
                        "FROM INCIDENCIA " +
                        "WHERE estado = ?";

        return contarPorEstado(sql, "Servicio restaurado");
    }


    // =========================================================
    // CONSULTA BASE DE SEGMENTOS (con estaciones, servicios
    // e incidencias abiertas)
    // =========================================================

    private final String SQL_SEGMENTO =
            "SELECT seg.codigo_segmento, seg.capacidad_total, " +
                    "seg.capacidad_utilizada, seg.capacidad_reservada, seg.estado, " +
                    "o.id_landing AS id_origen, o.nombre AS nombre_origen, " +
                    "o.ciudad AS ciudad_origen, o.pais AS pais_origen, " +
                    "d.id_landing AS id_destino, d.nombre AS nombre_destino, " +
                    "d.ciudad AS ciudad_destino, d.pais AS pais_destino, " +

                    "(SELECT COUNT(DISTINCT s.id_servicio) " +
                    " FROM RUTA_has_SEGMENTO rhs " +
                    " INNER JOIN SERVICIO s ON s.RUTA_id_ruta = rhs.RUTA_id_ruta " +
                    " WHERE rhs.SEGMENTO_codigo_segmento = seg.codigo_segmento " +
                    " AND s.estado <> 'Cancelado') AS cantidad_servicios, " +

                    "(SELECT COUNT(*) FROM INCIDENCIA i " +
                    " WHERE i.estado NOT IN ('Cerrada', 'Servicio restaurado') " +
                    " AND (i.SEGMENTO_codigo_segmento = seg.codigo_segmento " +
                    "      OR EXISTS (SELECT 1 FROM INCIDENCIA_SEGMENTO isg " +
                    "                 WHERE isg.codigo_incidencia = i.codigo_incidencia " +
                    "                 AND isg.codigo_segmento = seg.codigo_segmento))" +
                    ") AS incidencias_abiertas " +

                    "FROM SEGMENTO seg " +
                    "INNER JOIN LANDING_STATION o " +
                    "ON seg.LANDING_STATION_id_origen = o.id_landing " +
                    "INNER JOIN LANDING_STATION d " +
                    "ON seg.LANDING_STATION_id_destino = d.id_landing ";


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

        segmento.setCantidadServicios(rs.getInt("cantidad_servicios"));
        segmento.setIncidenciasAbiertas(rs.getInt("incidencias_abiertas"));

        return segmento;
    }


    // =========================================================
    // LISTAR SEGMENTOS CON FILTROS (RF14 - Estado de segmentos)
    // =========================================================

    public List<Segmento> listarSegmentosFiltrados(String buscar, String estado) {
        return listarSegmentosFiltrados(buscar, estado, null);
    }

    // Con paginación: pag != null agrega LIMIT y guarda el total en pag
    public List<Segmento> listarSegmentosFiltrados(String buscar, String estado, Paginacion pag) {

        List<Segmento> lista = new ArrayList<>();

        String sql = SQL_SEGMENTO + "WHERE 1=1 ";

        List<String> parametros = new ArrayList<>();

        if (estado != null && !estado.trim().isEmpty()) {
            sql += "AND seg.estado = ? ";
            parametros.add(estado.trim());
        }

        if (buscar != null && !buscar.trim().isEmpty()) {
            sql += "AND (seg.codigo_segmento LIKE ? " +
                    "OR o.nombre LIKE ? OR d.nombre LIKE ? " +
                    "OR o.ciudad LIKE ? OR d.ciudad LIKE ? " +
                    "OR o.pais LIKE ? OR d.pais LIKE ?) ";

            String texto = "%" + buscar.trim() + "%";
            for (int i = 0; i < 7; i++) {
                parametros.add(texto);
            }
        }

        sql += "ORDER BY seg.codigo_segmento";

        if (pag != null) {
            pag.setTotalRegistros(contarFilas(sql, parametros));
            sql += " LIMIT ?, ?";
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = conectar();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {

                for (int i = 0; i < parametros.size(); i++) {
                    pstmt.setString(i + 1, parametros.get(i));
                }
                if (pag != null) {
                    pstmt.setInt(parametros.size() + 1, pag.getInicio());
                    pstmt.setInt(parametros.size() + 2, pag.getTamanio());
                }

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        lista.add(leerSegmento(rs));
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // =========================================================
    // OBTENER UN SEGMENTO (Detalle del segmento)
    // =========================================================

    public Segmento obtenerSegmento(String codigoSegmento) {

        Segmento segmento = null;

        String sql = SQL_SEGMENTO + "WHERE seg.codigo_segmento = ?";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = conectar();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {

                pstmt.setString(1, codigoSegmento);

                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        segmento = leerSegmento(rs);
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return segmento;
    }


    // =========================================================
    // SERVICIOS QUE USAN UN SEGMENTO
    // =========================================================

    public List<Servicio> listarServiciosPorSegmento(String codigoSegmento) {

        List<Servicio> lista = new ArrayList<>();

        String sql =
                "SELECT DISTINCT s.id_servicio, s.capacidad_contratada, s.estado, " +
                        "r.codigo AS codigo_ruta, c.razon_social " +
                        "FROM SERVICIO s " +
                        "INNER JOIN RUTA r ON s.RUTA_id_ruta = r.id_ruta " +
                        "INNER JOIN CLIENTE c ON s.CLIENTE_id_cliente = c.id_cliente " +
                        "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = s.RUTA_id_ruta " +
                        "WHERE rhs.SEGMENTO_codigo_segmento = ? " +
                        "AND s.estado <> 'Cancelado' " +
                        "ORDER BY s.id_servicio";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = conectar();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {

                pstmt.setString(1, codigoSegmento);

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
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // =========================================================
    // RUTAS QUE INCLUYEN UN SEGMENTO
    // =========================================================

    public List<String> listarRutasPorSegmento(String codigoSegmento) {

        List<String> lista = new ArrayList<>();

        String sql =
                "SELECT r.codigo " +
                        "FROM RUTA r " +
                        "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.RUTA_id_ruta = r.id_ruta " +
                        "WHERE rhs.SEGMENTO_codigo_segmento = ? " +
                        "ORDER BY r.codigo";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = conectar();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {

                pstmt.setString(1, codigoSegmento);

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        lista.add(rs.getString("codigo"));
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // =========================================================
    // INCIDENCIAS RELACIONADAS CON UN SEGMENTO
    // =========================================================

    public List<Incidencia> listarIncidenciasPorSegmento(String codigoSegmento) {

        List<Incidencia> lista = new ArrayList<>();

        String sql =
                "SELECT i.codigo_incidencia, i.titulo, i.descripcion, " +
                        "i.severidad, i.estado, " +
                        "DATE_FORMAT(i.fecha_deteccion, '%d/%m/%Y') AS fecha_deteccion, " +
                        "TIME_FORMAT(i.hora, '%H:%i') AS hora, " +
                        "i.SEGMENTO_codigo_segmento AS codigo_segmento " +
                        "FROM INCIDENCIA i " +
                        "WHERE i.SEGMENTO_codigo_segmento = ? " +
                        "OR i.codigo_incidencia IN (SELECT codigo_incidencia " +
                        "    FROM INCIDENCIA_SEGMENTO WHERE codigo_segmento = ?) " +
                        "ORDER BY i.fecha_deteccion DESC, i.hora DESC";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = conectar();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {

                pstmt.setString(1, codigoSegmento);
                pstmt.setString(2, codigoSegmento);

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        Incidencia incidencia = new Incidencia();
                        incidencia.setCodigoIncidencia(rs.getString("codigo_incidencia"));
                        incidencia.setTitulo(rs.getString("titulo"));
                        incidencia.setDescripcion(rs.getString("descripcion"));
                        incidencia.setSeveridad(rs.getString("severidad"));
                        incidencia.setEstado(rs.getString("estado"));
                        incidencia.setFechaDeteccion(
                                rs.getString("fecha_deteccion") + " " + rs.getString("hora")
                        );
                        incidencia.setCodigoSegmento(rs.getString("codigo_segmento"));
                        lista.add(incidencia);
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // =========================================================
    // LANDING STATIONS OPERATIVAS (formulario de registro)
    // =========================================================

    public List<LandingStation> listarLandingStations() {

        List<LandingStation> lista = new ArrayList<>();

        String sql =
                "SELECT id_landing, nombre, ciudad, pais, estado " +
                        "FROM LANDING_STATION " +
                        "WHERE estado = 'Operativa' " +
                        "ORDER BY id_landing";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = conectar();
                 PreparedStatement pstmt = conn.prepareStatement(sql);
                 ResultSet rs = pstmt.executeQuery()) {

                while (rs.next()) {
                    LandingStation landing = new LandingStation();
                    landing.setIdLanding(rs.getString("id_landing"));
                    landing.setNombre(rs.getString("nombre"));
                    landing.setCiudad(rs.getString("ciudad"));
                    landing.setPais(rs.getString("pais"));
                    landing.setEstado(rs.getString("estado"));
                    lista.add(landing);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // =========================================================
    // OBTENER UNA LANDING STATION
    // =========================================================

    public LandingStation obtenerLandingStation(String idLanding) {

        LandingStation landing = null;

        String sql =
                "SELECT id_landing, nombre, ciudad, pais, estado " +
                        "FROM LANDING_STATION WHERE id_landing = ?";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = conectar();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {

                pstmt.setString(1, idLanding);

                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        landing = new LandingStation();
                        landing.setIdLanding(rs.getString("id_landing"));
                        landing.setNombre(rs.getString("nombre"));
                        landing.setCiudad(rs.getString("ciudad"));
                        landing.setPais(rs.getString("pais"));
                        landing.setEstado(rs.getString("estado"));
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return landing;
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
