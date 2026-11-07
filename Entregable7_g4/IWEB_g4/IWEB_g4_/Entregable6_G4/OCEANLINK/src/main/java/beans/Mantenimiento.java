package beans;

// Mantenimiento programado o realizado (RF36). El elemento es el segmento
// cuya columna MANTENIMIENTO_id_mantenimiento apunta a este mantenimiento.
public class Mantenimiento {

    private String codigoMantenimiento;
    private String tipo;
    private String estado;
    private String fechaProgramada;
    private String horaInicio;
    private String duracionEstimada;
    private String actividad;
    private String codigoSegmento;
    private String tramo;

    // Datos que usa el Maintenance Coordinator (detalle del mantenimiento)
    private String descripcion;        // descripción de la actividad principal (plan)
    private int idActividad;           // actividad principal (ACTIVIDAD_MANTENIMIENTO_id_actividad)
    private String segmentos;          // segmentos asociados, separados por coma
    private String landings;           // landing stations asociadas, separadas por coma
    private String resultado;          // FINALIZACION_MANTENIMIENTO
    private String resumenFinal;
    private String observacionFinal;
    private String fechaFin;
    private String estadoServicios;

    public Mantenimiento() {
    }

    public String getCodigoMantenimiento() {
        return codigoMantenimiento;
    }

    public void setCodigoMantenimiento(String codigoMantenimiento) {
        this.codigoMantenimiento = codigoMantenimiento;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getFechaProgramada() {
        return fechaProgramada;
    }

    public void setFechaProgramada(String fechaProgramada) {
        this.fechaProgramada = fechaProgramada;
    }

    public String getHoraInicio() {
        return horaInicio;
    }

    public void setHoraInicio(String horaInicio) {
        this.horaInicio = horaInicio;
    }

    public String getDuracionEstimada() {
        return duracionEstimada;
    }

    public void setDuracionEstimada(String duracionEstimada) {
        this.duracionEstimada = duracionEstimada;
    }

    public String getActividad() {
        return actividad;
    }

    public void setActividad(String actividad) {
        this.actividad = actividad;
    }

    public String getCodigoSegmento() {
        return codigoSegmento;
    }

    public void setCodigoSegmento(String codigoSegmento) {
        this.codigoSegmento = codigoSegmento;
    }

    public String getTramo() {
        return tramo;
    }

    public void setTramo(String tramo) {
        this.tramo = tramo;
    }

    // "72:00:00" -> 72 (horas de duración estimada)
    public int getHorasEstimadas() {
        if (duracionEstimada == null || !duracionEstimada.contains(":")) {
            return 0;
        }
        return Integer.parseInt(duracionEstimada.substring(0, duracionEstimada.indexOf(":")));
    }

    // Pendiente = todavía no termina (Programado o En ejecución)
    public boolean isPendiente() {
        return "Programado".equals(estado) || "En ejecución".equals(estado);
    }
    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public int getIdActividad() {
        return idActividad;
    }

    public void setIdActividad(int idActividad) {
        this.idActividad = idActividad;
    }

    public String getSegmentos() {
        return segmentos;
    }

    public void setSegmentos(String segmentos) {
        this.segmentos = segmentos;
    }

    public String getLandings() {
        return landings;
    }

    public void setLandings(String landings) {
        this.landings = landings;
    }

    public String getResultado() {
        return resultado;
    }

    public void setResultado(String resultado) {
        this.resultado = resultado;
    }

    public String getResumenFinal() {
        return resumenFinal;
    }

    public void setResumenFinal(String resumenFinal) {
        this.resumenFinal = resumenFinal;
    }

    public String getObservacionFinal() {
        return observacionFinal;
    }

    public void setObservacionFinal(String observacionFinal) {
        this.observacionFinal = observacionFinal;
    }

    public String getFechaFin() {
        return fechaFin;
    }

    public void setFechaFin(String fechaFin) {
        this.fechaFin = fechaFin;
    }

    public String getEstadoServicios() {
        return estadoServicios;
    }

    public void setEstadoServicios(String estadoServicios) {
        this.estadoServicios = estadoServicios;
    }

    // Solo un mantenimiento Programado se puede editar, iniciar o cancelar
    public boolean isProgramado() {
        return "Programado".equals(estado);
    }

    // Solo un mantenimiento En ejecución puede registrar actividades y finalizarse
    public boolean isEnEjecucion() {
        return "En ejecución".equals(estado);
    }
}
