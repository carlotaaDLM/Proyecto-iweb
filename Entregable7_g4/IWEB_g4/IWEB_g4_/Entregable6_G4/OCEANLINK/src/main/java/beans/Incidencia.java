package beans;

public class Incidencia {

    private String codigoIncidencia;
    private String titulo;
    private String descripcion;
    private String severidad;
    private String estado;
    private String fechaDeteccion;
    private String codigoSegmento;
    private String idLanding;
    private String tramo;
    private String registradaPor;
    private String fechaDeteccionIso;
    private String nombreLanding;       // nombre de la Landing Station (Supervisor)
    private int serviciosAfectados;     // servicios activos que pasan por sus segmentos (Supervisor)

    public Incidencia() {
    }

    public String getCodigoIncidencia() {
        return codigoIncidencia;
    }

    public void setCodigoIncidencia(String codigoIncidencia) {
        this.codigoIncidencia = codigoIncidencia;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public String getSeveridad() {
        return severidad;
    }

    public void setSeveridad(String severidad) {
        this.severidad = severidad;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getFechaDeteccion() {
        return fechaDeteccion;
    }

    public void setFechaDeteccion(String fechaDeteccion) {
        this.fechaDeteccion = fechaDeteccion;
    }

    public String getCodigoSegmento() {
        return codigoSegmento;
    }

    public void setCodigoSegmento(String codigoSegmento) {
        this.codigoSegmento = codigoSegmento;
    }

    public String getIdLanding() {
        return idLanding;
    }

    public void setIdLanding(String idLanding) {
        this.idLanding = idLanding;
    }

    public String getTramo() {
        return tramo;
    }

    public void setTramo(String tramo) {
        this.tramo = tramo;
    }

    public String getRegistradaPor() {
        return registradaPor;
    }

    public void setRegistradaPor(String registradaPor) {
        this.registradaPor = registradaPor;
    }

    public String getFechaDeteccionIso() {
        return fechaDeteccionIso;
    }

    public void setFechaDeteccionIso(String fechaDeteccionIso) {
        this.fechaDeteccionIso = fechaDeteccionIso;
    }

    public int getServiciosAfectados() {
        return serviciosAfectados;
    }

    public void setServiciosAfectados(int serviciosAfectados) {
        this.serviciosAfectados = serviciosAfectados;
    }

    public String getNombreLanding() {
        return nombreLanding;
    }

    public void setNombreLanding(String nombreLanding) {
        this.nombreLanding = nombreLanding;
    }
}
