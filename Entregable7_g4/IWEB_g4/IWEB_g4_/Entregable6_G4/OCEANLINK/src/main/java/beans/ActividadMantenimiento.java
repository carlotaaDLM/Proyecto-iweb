package beans;

// Actividad registrada durante un mantenimiento
public class ActividadMantenimiento {

    private int idActividad;
    private String codigoMantenimiento;
    private String titulo;
    private String descripcion;
    private String fecha;
    private String hora;
    private String tiempoInvertido;
    private boolean principal;
    private boolean borrable;

    public ActividadMantenimiento() {
    }

    public int getIdActividad() {
        return idActividad;
    }

    public void setIdActividad(int idActividad) {
        this.idActividad = idActividad;
    }

    public String getCodigoMantenimiento() {
        return codigoMantenimiento;
    }

    public void setCodigoMantenimiento(String codigoMantenimiento) {
        this.codigoMantenimiento = codigoMantenimiento;
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

    public String getFecha() {
        return fecha;
    }

    public void setFecha(String fecha) {
        this.fecha = fecha;
    }

    public String getHora() {
        return hora;
    }

    public void setHora(String hora) {
        this.hora = hora;
    }

    public String getTiempoInvertido() {
        return tiempoInvertido;
    }

    public void setTiempoInvertido(String tiempoInvertido) {
        this.tiempoInvertido = tiempoInvertido;
    }

    public boolean isPrincipal() {
        return principal;
    }

    public void setPrincipal(boolean principal) {
        this.principal = principal;
    }

    public boolean isBorrable() {
        return borrable;
    }

    public void setBorrable(boolean borrable) {
        this.borrable = borrable;
    }
}
