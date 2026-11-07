package beans;

public class LandingStation {

    private String idLanding;
    private String nombre;
    private String ciudad;
    private String pais;
    private String estado;

    // Datos de apoyo para la vista del Supervisor
    private int cantidadSegmentos;
    private int incidenciasActivas;
    private String codigoMantenimiento;
    private String estadoMantenimiento;
    private String fechaMantenimiento;
    private int dependencias;            // registros que la usan (rutas, incidencias...); 0 = se puede eliminar

    public LandingStation() {
    }

    public String getIdLanding() {
        return idLanding;
    }

    public void setIdLanding(String idLanding) {
        this.idLanding = idLanding;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getCiudad() {
        return ciudad;
    }

    public void setCiudad(String ciudad) {
        this.ciudad = ciudad;
    }

    public String getPais() {
        return pais;
    }

    public void setPais(String pais) {
        this.pais = pais;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public int getCantidadSegmentos() {
        return cantidadSegmentos;
    }

    public void setCantidadSegmentos(int cantidadSegmentos) {
        this.cantidadSegmentos = cantidadSegmentos;
    }

    public int getIncidenciasActivas() {
        return incidenciasActivas;
    }

    public void setIncidenciasActivas(int incidenciasActivas) {
        this.incidenciasActivas = incidenciasActivas;
    }

    public String getCodigoMantenimiento() {
        return codigoMantenimiento;
    }

    public void setCodigoMantenimiento(String codigoMantenimiento) {
        this.codigoMantenimiento = codigoMantenimiento;
    }

    public String getEstadoMantenimiento() {
        return estadoMantenimiento;
    }

    public void setEstadoMantenimiento(String estadoMantenimiento) {
        this.estadoMantenimiento = estadoMantenimiento;
    }

    public String getFechaMantenimiento() {
        return fechaMantenimiento;
    }

    public void setFechaMantenimiento(String fechaMantenimiento) {
        this.fechaMantenimiento = fechaMantenimiento;
    }

    public int getDependencias() {
        return dependencias;
    }

    public void setDependencias(int dependencias) {
        this.dependencias = dependencias;
    }
}
