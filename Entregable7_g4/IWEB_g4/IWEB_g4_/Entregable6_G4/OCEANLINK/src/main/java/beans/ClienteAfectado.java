package beans;

// Cliente con al menos un servicio afectado (RF35)
public class ClienteAfectado {

    private int idCliente;
    private String razonSocial;
    private String ruc;
    private String correo;
    private String telefono;
    private int serviciosAfectados;
    private double capacidadAfectada;
    private int tramosFueraServicio;
    private String servicios;
    private String incidencias;

    public ClienteAfectado() {
    }

    public int getIdCliente() {
        return idCliente;
    }

    public void setIdCliente(int idCliente) {
        this.idCliente = idCliente;
    }

    public String getRazonSocial() {
        return razonSocial;
    }

    public void setRazonSocial(String razonSocial) {
        this.razonSocial = razonSocial;
    }

    public String getRuc() {
        return ruc;
    }

    public void setRuc(String ruc) {
        this.ruc = ruc;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo = correo;
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono;
    }

    public int getServiciosAfectados() {
        return serviciosAfectados;
    }

    public void setServiciosAfectados(int serviciosAfectados) {
        this.serviciosAfectados = serviciosAfectados;
    }

    public double getCapacidadAfectada() {
        return capacidadAfectada;
    }

    public void setCapacidadAfectada(double capacidadAfectada) {
        this.capacidadAfectada = capacidadAfectada;
    }

    public int getTramosFueraServicio() {
        return tramosFueraServicio;
    }

    public void setTramosFueraServicio(int tramosFueraServicio) {
        this.tramosFueraServicio = tramosFueraServicio;
    }

    public String getServicios() {
        return servicios;
    }

    public void setServicios(String servicios) {
        this.servicios = servicios;
    }

    public String getIncidencias() {
        return incidencias;
    }

    public void setIncidencias(String incidencias) {
        this.incidencias = incidencias;
    }


    public String getSituacion() {
        return tramosFueraServicio > 0 ? "Interrumpido" : "Degradado";
    }
}
