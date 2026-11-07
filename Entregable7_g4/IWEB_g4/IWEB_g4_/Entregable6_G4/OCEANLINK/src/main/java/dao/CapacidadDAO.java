package dao;

import beans.Cliente;
import beans.LandingStation;
import beans.Paginacion;
import beans.Ruta;
import beans.Segmento;
import beans.Servicio;
import beans.UtilizacionHist;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;



public class CapacidadDAO {

    private final String url = "jdbc:mysql://localhost:3306/mibasededatos";
    private final String user = "root";
    private final String pass = "root";


    private String ultimoError;

    public String getUltimoError() {
        return ultimoError;
    }


    private Connection conectar() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(url, user, pass);
    }



    private final String SQL_SEGMENTO =
            "SELECT seg.codigo_segmento, seg.capacidad_total, " +
                    "seg.capacidad_utilizada, seg.capacidad_reservada, seg.estado, " +
                    "o.id_landing AS id_origen, o.nombre AS nombre_origen, " +
                    "o.ciudad AS ciudad_origen, o.pais AS pais_origen, " +
                    "d.id_landing AS id_destino, d.nombre AS nombre_destino, " +
                    "d.ciudad AS ciudad_destino, d.pais AS pais_destino " +
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

        return segmento;
    }




    public List<Segmento> listarSegmentos(String buscar, String estado, String nivel) {
        return listarSegmentos(buscar, estado, nivel, false, null);
    }


    // Ocupación = (utilizada + reservada) / total, igual que Segmento.getPorcentajeOcupacion()
    private final String OCUPACION =
            "((seg.capacidad_utilizada + seg.capacidad_reservada) * 100 / seg.capacidad_total) ";


    /*
     * Lista de segmentos con filtros. El nivel (Normal, Alta, Crítica) se filtra en el SQL
     * para que la paginación (LIMIT ?, ?) cuente bien las filas.
     * porOcupacion: true = de mayor a menor ocupación; false = por código.
     * pag: null = todas las filas.
     */
    public List<Segmento> listarSegmentos(String buscar, String estado, String nivel,
                                         boolean porOcupacion, Paginacion pag) {

        List<Segmento> lista = new ArrayList<>();

        String sql = SQL_SEGMENTO + "WHERE 1 = 1 ";

        boolean hayBuscar = buscar != null && !buscar.trim().isEmpty();
        boolean hayEstado = estado != null && !estado.isEmpty();

        if (hayBuscar) {
            sql += "AND (seg.codigo_segmento LIKE ? OR o.nombre LIKE ? OR d.nombre LIKE ? " +
                    "OR o.pais LIKE ? OR d.pais LIKE ?) ";
        }
        if (hayEstado) {
            sql += "AND seg.estado = ? ";
        }
        if ("Normal".equals(nivel)) {
            sql += "AND " + OCUPACION + "< 80 ";
        } else if ("Alta".equals(nivel)) {
            sql += "AND " + OCUPACION + ">= 80 AND " + OCUPACION + "<= 95 ";
        } else if ("Crítica".equals(nivel)) {
            sql += "AND " + OCUPACION + "> 95 ";
        }
        sql += porOcupacion
                ? "ORDER BY " + OCUPACION + "DESC, seg.codigo_segmento"
                : "ORDER BY seg.codigo_segmento";

        try (Connection conn = conectar()) {

            // Paginación: primero se cuenta el total y luego se piden solo las filas de la página
            if (pag != null) {
                try (PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM (" + sql + ") AS t")) {
                    asignarFiltrosSegmento(pstmt, buscar, estado);
                    try (ResultSet rs = pstmt.executeQuery()) {
                        if (rs.next()) {
                            pag.setTotalRegistros(rs.getInt(1));
                        }
                    }
                }
                sql += " LIMIT ?, ?";
            }

            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {

                int i = asignarFiltrosSegmento(pstmt, buscar, estado);
                if (pag != null) {
                    pstmt.setInt(i++, pag.getInicio());
                    pstmt.setInt(i, pag.getTamanio());
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


    // Asigna los parámetros de buscar y estado; devuelve la posición del siguiente parámetro
    private int asignarFiltrosSegmento(PreparedStatement pstmt, String buscar, String estado) throws SQLException {
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


    public Segmento obtenerSegmento(String codigo) {

        String sql = SQL_SEGMENTO + "WHERE seg.codigo_segmento = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, codigo);

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


    public List<Segmento> listarPorOcupacion(String nivel) {
        return listarSegmentos(null, null, nivel, true, null);
    }


    // De mayor a menor ocupación, paginado (RF12)
    public List<Segmento> listarPorOcupacion(String nivel, Paginacion pag) {
        return listarSegmentos(null, null, nivel, true, pag);
    }


    public Map<String, Double> obtenerTendencias() {

        Map<String, Double> tendencias = new HashMap<>();

        String sql =
                "SELECT SEGMENTO_codigo_segmento, capacidad_utilizada " +
                        "FROM UTILIZACION_HIST " +
                        "WHERE SEGMENTO_codigo_segmento IS NOT NULL " +
                        "ORDER BY SEGMENTO_codigo_segmento, fecha DESC";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            Map<String, List<Double>> ultimos = new HashMap<>();

            while (rs.next()) {
                String codigo = rs.getString(1);
                ultimos.computeIfAbsent(codigo, k -> new ArrayList<>());
                if (ultimos.get(codigo).size() < 2) {
                    ultimos.get(codigo).add(rs.getDouble(2));
                }
            }

            for (Map.Entry<String, List<Double>> e : ultimos.entrySet()) {
                List<Double> v = e.getValue();
                if (v.size() == 2 && v.get(1) > 0) {
                    tendencias.put(e.getKey(), (v.get(0) - v.get(1)) * 100.0 / v.get(1));
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return tendencias;
    }



    public List<UtilizacionHist> listarHistorial(String codigoSegmento, String desde, String hasta) {

        List<UtilizacionHist> lista = new ArrayList<>();

        String sql =
                "SELECT id_registro, SEGMENTO_codigo_segmento, fecha, capacidad_total, " +
                        "capacidad_utilizada, capacidad_disponible " +
                        "FROM UTILIZACION_HIST " +
                        "WHERE SEGMENTO_codigo_segmento = ? ";

        boolean hayDesde = desde != null && desde.matches("\\d{4}-\\d{2}-\\d{2}");
        boolean hayHasta = hasta != null && hasta.matches("\\d{4}-\\d{2}-\\d{2}");

        if (hayDesde) {
            sql += "AND fecha >= ? ";
        }
        if (hayHasta) {
            sql += "AND fecha <= ? ";
        }
        sql += "ORDER BY fecha DESC";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            int i = 1;
            pstmt.setString(i++, codigoSegmento);
            if (hayDesde) {
                pstmt.setString(i++, desde);
            }
            if (hayHasta) {
                pstmt.setString(i, hasta);
            }

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



    public List<Ruta> listarRutas() {
        return listarRutas(null);
    }


    // Rutas registradas con sus segmentos. pag: null = todas; si no, solo las de la página (LIMIT ?, ?)
    public List<Ruta> listarRutas(Paginacion pag) {

        Map<Integer, Ruta> rutas = new LinkedHashMap<>();

        String sqlRutas =
                "SELECT r.id_ruta, r.codigo, r.estado, " +
                        "(SELECT COUNT(*) FROM SERVICIO s WHERE s.RUTA_id_ruta = r.id_ruta " +
                        " AND s.estado <> 'Cancelado') AS cantidad_servicios, " +
                        "(SELECT COUNT(*) FROM SOLICITUD_CAPACIDAD sc " +
                        " WHERE sc.id_ruta_propuesta = r.id_ruta) AS cantidad_solicitudes " +
                        "FROM RUTA r ORDER BY r.id_ruta";

        if (pag != null) {
            pag.setTotalRegistros(contarRutas());
            sqlRutas += " LIMIT ?, ?";
        }

        String sqlSegmentos =
                SQL_SEGMENTO.replace("SELECT ", "SELECT rhs.RUTA_id_ruta, ") +
                        "INNER JOIN RUTA_has_SEGMENTO rhs ON rhs.SEGMENTO_codigo_segmento = seg.codigo_segmento " +
                        "ORDER BY rhs.RUTA_id_ruta, rhs.orden";

        try (Connection conn = conectar()) {

            try (PreparedStatement pstmt = conn.prepareStatement(sqlRutas)) {

                if (pag != null) {
                    pstmt.setInt(1, pag.getInicio());
                    pstmt.setInt(2, pag.getTamanio());
                }

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        Ruta ruta = new Ruta();
                        ruta.setIdRuta(rs.getInt("id_ruta"));
                        ruta.setCodigo(rs.getString("codigo"));
                        ruta.setEstado(rs.getString("estado"));
                        ruta.setCantidadServicios(rs.getInt("cantidad_servicios"));
                        ruta.setCantidadSolicitudes(rs.getInt("cantidad_solicitudes"));
                        ruta.setSegmentos(new ArrayList<>());
                        rutas.put(ruta.getIdRuta(), ruta);
                    }
                }
            }

            try (PreparedStatement pstmt = conn.prepareStatement(sqlSegmentos);
                 ResultSet rs = pstmt.executeQuery()) {

                while (rs.next()) {
                    Ruta ruta = rutas.get(rs.getInt("RUTA_id_ruta"));
                    if (ruta != null) {
                        ruta.getSegmentos().add(leerSegmento(rs));
                    }
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        for (Ruta r : rutas.values()) {
            orientar(r.getSegmentos());
        }

        return new ArrayList<>(rutas.values());
    }


    // Pone cada segmento en el sentido del recorrido, para que la ruta quede encadenada
    // (una ruta puede usar un segmento en sentido contrario al registrado)
    private void orientar(List<Segmento> segs) {

        if (segs.size() < 2) {
            return;
        }
        Segmento primero = segs.get(0);
        Segmento segundo = segs.get(1);
        if (!primero.getIdDestino().equals(segundo.getIdOrigen())
                && !primero.getIdDestino().equals(segundo.getIdDestino())) {
            primero.invertir();
        }
        for (int i = 1; i < segs.size(); i++) {
            if (!segs.get(i).getIdOrigen().equals(segs.get(i - 1).getIdDestino())) {
                segs.get(i).invertir();
            }
        }
    }


    public int contarRutas() {

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM RUTA");
             ResultSet rs = pstmt.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return 0;
    }


    public Ruta obtenerRuta(Integer idRuta) {

        if (idRuta == null) {
            return null;
        }
        for (Ruta r : listarRutas()) {
            if (r.getIdRuta() == idRuta) {
                return r;
            }
        }
        return null;
    }




    public Ruta calcularRuta(String idOrigen, String idDestino) {

        Ruta mejor = null;

        for (Ruta r : listarRutas()) {

            boolean une = idOrigen != null && idOrigen.equals(r.getIdOrigen())
                    && idDestino != null && idDestino.equals(r.getIdDestino());

            // La misma ruta sirve en sentido contrario (la fibra transmite en ambos sentidos)
            boolean uneAlReves = idOrigen != null && idOrigen.equals(r.getIdDestino())
                    && idDestino != null && idDestino.equals(r.getIdOrigen());

            if ((!une && !uneAlReves) || !"Activa".equals(r.getEstado()) || r.isTieneSegmentoFueraServicio()) {
                continue;
            }

            if (uneAlReves) {
                List<Segmento> alReves = new ArrayList<>();
                for (Segmento s : r.getSegmentos()) {
                    s.invertir();
                    alReves.add(0, s);
                }
                r.setSegmentos(alReves);
            }

            if (mejor == null || r.getCapacidadDisponible() > mejor.getCapacidadDisponible()) {
                mejor = r;
            }
        }

        // Ninguna ruta registrada une esas estaciones: se arma una nueva con los segmentos
        if (mejor == null && idOrigen != null && idDestino != null && !idOrigen.equals(idDestino)) {
            mejor = buscarRutaNueva(idOrigen, idDestino);
        }

        return mejor;
    }


    /*
     * Busca un camino de origen a destino usando los segmentos (búsqueda en anchura:
     * el camino con menos segmentos), sin pasar por segmentos Fuera de servicio.
     * Un segmento se puede recorrer en ambos sentidos.
     * La ruta se devuelve sin guardar (id 0): se registra en RUTA al evaluar la solicitud.
     */
    private Ruta buscarRutaNueva(String idOrigen, String idDestino) {

        List<Segmento> segmentos = listarSegmentos(null, null, null);

        // estación -> segmento por el que se llegó a ella
        Map<String, Segmento> llegoPor = new HashMap<>();
        List<String> cola = new ArrayList<>();

        llegoPor.put(idOrigen, null);
        cola.add(idOrigen);

        for (int i = 0; i < cola.size() && !llegoPor.containsKey(idDestino); i++) {
            String actual = cola.get(i);
            for (Segmento s : segmentos) {
                if ("Fuera de servicio".equals(s.getEstado())) {
                    continue;
                }
                String otra = null;      // estación al otro extremo del segmento
                if (actual.equals(s.getIdOrigen())) {
                    otra = s.getIdDestino();
                } else if (actual.equals(s.getIdDestino())) {
                    otra = s.getIdOrigen();
                }
                if (otra != null && !llegoPor.containsKey(otra)) {
                    llegoPor.put(otra, s);
                    cola.add(otra);
                }
            }
        }

        if (!llegoPor.containsKey(idDestino)) {
            return null;
        }

        // Se reconstruye el camino desde el destino hacia el origen
        List<Segmento> camino = new ArrayList<>();
        String estacion = idDestino;
        while (llegoPor.get(estacion) != null) {
            Segmento s = llegoPor.get(estacion);
            if (!estacion.equals(s.getIdDestino())) {
                s.invertir();      // se recorre en sentido contrario al registrado
            }
            camino.add(0, s);
            estacion = s.getIdOrigen();
        }

        Ruta ruta = new Ruta();
        ruta.setIdRuta(0);
        ruta.setCodigo(codigoNuevaRuta(idOrigen, idDestino));
        ruta.setEstado("Activa");
        ruta.setSegmentos(camino);
        return ruta;
    }


    // Código libre para una ruta nueva, por ejemplo RUTA-ARI-VAL-01
    private String codigoNuevaRuta(String idOrigen, String idDestino) {

        String base = "RUTA-" + parteCodigo(idOrigen) + "-" + parteCodigo(idDestino) + "-";

        List<String> usados = new ArrayList<>();
        for (Ruta r : listarRutas()) {
            usados.add(r.getCodigo());
        }

        int n = 1;
        while (usados.contains(base + (n < 10 ? "0" + n : "" + n))) {
            n++;
        }
        return base + (n < 10 ? "0" + n : "" + n);
    }

    private String parteCodigo(String idLanding) {
        String parte = idLanding.replace("LS-", "");
        return parte.length() > 4 ? parte.substring(0, 4) : parte;
    }



    public String crearRuta(String codigo, List<String> codigosSegmento) {

        String sqlRuta = "INSERT INTO RUTA (codigo, estado) VALUES (?, 'Activa')";
        String sqlSeg =
                "INSERT INTO RUTA_has_SEGMENTO (RUTA_id_ruta, SEGMENTO_codigo_segmento, orden) " +
                        "VALUES (?, ?, ?)";

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            int idRuta;

            try (PreparedStatement pstmt = conn.prepareStatement(sqlRuta,
                    PreparedStatement.RETURN_GENERATED_KEYS)) {
                pstmt.setString(1, codigo);
                pstmt.executeUpdate();
                try (ResultSet rs = pstmt.getGeneratedKeys()) {
                    rs.next();
                    idRuta = rs.getInt(1);
                }
            }

            try (PreparedStatement pstmt = conn.prepareStatement(sqlSeg)) {
                int orden = 1;
                for (String codigoSegmento : codigosSegmento) {
                    pstmt.setInt(1, idRuta);
                    pstmt.setString(2, codigoSegmento);
                    pstmt.setInt(3, orden++);
                    pstmt.executeUpdate();
                }
            }

            conn.commit();
            return null;

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            ultimoError = e.getMessage();
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
            return e.getMessage() != null && e.getMessage().contains("Duplicate")
                    ? "Ya existe una ruta con el código " + codigo + "."
                    : "No se pudo registrar la ruta: " + e.getMessage();
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }




    public void cambiarEstadoRuta(int idRuta, String estado) {

        String sql = "UPDATE RUTA SET estado = ? WHERE id_ruta = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, estado);
            pstmt.setInt(2, idRuta);
            pstmt.executeUpdate();

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }


    /*
     * Elimina una ruta aunque esté en uso:
     *  - sus servicios se eliminan y su capacidad se libera en los segmentos de la ruta
     *  - las solicitudes que la tenían como ruta propuesta quedan sin ruta (se recalcula al evaluar)
     */
    public boolean borrarRuta(int idRuta) {

        Ruta ruta = obtenerRuta(idRuta);

        if (ruta == null) {
            return false;
        }

        Connection conn = null;

        try {
            conn = conectar();
            conn.setAutoCommit(false);

            // 1. Capacidad que ocupaban los servicios (los cancelados ya no ocupan)
            double ocupada = 0;
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "SELECT SUM(capacidad_contratada) FROM SERVICIO " +
                            "WHERE RUTA_id_ruta = ? AND estado <> 'Cancelado'")) {
                pstmt.setInt(1, idRuta);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        ocupada = rs.getDouble(1);
                    }
                }
            }

            if (ocupada > 0) {
                try (PreparedStatement pstmt = conn.prepareStatement(
                        "UPDATE SEGMENTO SET capacidad_utilizada = " +
                                "CASE WHEN capacidad_utilizada > ? THEN capacidad_utilizada - ? ELSE 0 END " +
                                "WHERE codigo_segmento = ?")) {
                    for (Segmento s : ruta.getSegmentos()) {
                        pstmt.setDouble(1, ocupada);
                        pstmt.setDouble(2, ocupada);
                        pstmt.setString(3, s.getCodigoSegmento());
                        pstmt.executeUpdate();
                    }
                }
            }

            // 2. Servicios de la ruta
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM SERVICIO WHERE RUTA_id_ruta = ?")) {
                pstmt.setInt(1, idRuta);
                pstmt.executeUpdate();
            }

            // 3. Solicitudes que la proponían
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE SOLICITUD_CAPACIDAD SET id_ruta_propuesta = NULL WHERE id_ruta_propuesta = ?")) {
                pstmt.setInt(1, idRuta);
                pstmt.executeUpdate();
            }

            // 4. Segmentos de la ruta y la ruta
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM RUTA_has_SEGMENTO WHERE RUTA_id_ruta = ?")) {
                pstmt.setInt(1, idRuta);
                pstmt.executeUpdate();
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM RUTA WHERE id_ruta = ?")) {
                pstmt.setInt(1, idRuta);
                pstmt.executeUpdate();
            }

            conn.commit();
            return true;

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

        return false;
    }



    private final String SQL_SERVICIO =
            "SELECT s.id_servicio, s.capacidad_contratada, s.estado, s.fecha_activacion, " +
                    "s.RUTA_id_ruta, r.codigo AS codigo_ruta, c.razon_social " +
                    "FROM SERVICIO s " +
                    "INNER JOIN RUTA r ON s.RUTA_id_ruta = r.id_ruta " +
                    "INNER JOIN CLIENTE c ON s.CLIENTE_id_cliente = c.id_cliente ";


    private Servicio leerServicio(ResultSet rs) throws SQLException {

        Servicio s = new Servicio();
        s.setIdServicio(rs.getInt("id_servicio"));
        s.setCapacidadContratada(rs.getDouble("capacidad_contratada"));
        s.setEstado(rs.getString("estado"));
        s.setFechaActivacion(rs.getString("fecha_activacion"));
        s.setIdRuta(rs.getInt("RUTA_id_ruta"));
        s.setCodigoRuta(rs.getString("codigo_ruta"));
        s.setRazonSocialCliente(rs.getString("razon_social"));
        return s;
    }


    public List<Servicio> listarServicios() {

        List<Servicio> lista = new ArrayList<>();

        String sql = SQL_SERVICIO + "WHERE s.estado <> 'Cancelado' ORDER BY s.id_servicio";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                lista.add(leerServicio(rs));
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    public Servicio obtenerServicio(int idServicio) {

        String sql = SQL_SERVICIO + "WHERE s.id_servicio = ?";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, idServicio);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return leerServicio(rs);
                }
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return null;
    }



    public List<Cliente> listarClientes() {

        List<Cliente> lista = new ArrayList<>();

        String sql = "SELECT id_cliente, razon_social, ruc, correo FROM CLIENTE ORDER BY razon_social";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                Cliente c = new Cliente();
                c.setIdCliente(rs.getInt("id_cliente"));
                c.setRazonSocial(rs.getString("razon_social"));
                c.setRuc(rs.getString("ruc"));
                c.setCorreo(rs.getString("correo"));
                lista.add(c);
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }


    // Solo las Landing Stations operativas pueden ser origen o destino
    public List<LandingStation> listarLandingStations() {

        List<LandingStation> lista = new ArrayList<>();

        String sql =
                "SELECT id_landing, nombre, ciudad, pais, estado FROM LANDING_STATION " +
                        "WHERE estado = 'Operativa' ORDER BY nombre";

        try (Connection conn = conectar();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                LandingStation ls = new LandingStation();
                ls.setIdLanding(rs.getString("id_landing"));
                ls.setNombre(rs.getString("nombre"));
                ls.setCiudad(rs.getString("ciudad"));
                ls.setPais(rs.getString("pais"));
                ls.setEstado(rs.getString("estado"));
                lista.add(ls);
            }

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
        }

        return lista;
    }
}
