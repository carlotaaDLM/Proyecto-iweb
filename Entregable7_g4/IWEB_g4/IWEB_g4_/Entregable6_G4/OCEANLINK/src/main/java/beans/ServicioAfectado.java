package beans;


public class ServicioAfectado {

    private int idServicio;
    private int idRuta;
    private String codigoRuta;
    private double capacidadContratada;
    private String estado;
    private int idCliente;
    private String razonSocial;
    private String ruc;
    private String incidencias;
    private String segmentos;
    private String severidadMaxima;
    private int tramosFueraServicio;

    public ServicioAfectado() {
    }

    public int getIdServicio() {
        return idServicio;
    }

    public void setIdServicio(int idServicio) {
        this.idServicio = idServicio;
    }

    public int getIdRuta() {
        return idRuta;
    }

    public void setIdRuta(int idRuta) {
        this.idRuta = idRuta;
    }

    public String getCodigoRuta() {
        return codigoRuta;
    }

    public void setCodigoRuta(String codigoRuta) {
        this.codigoRuta = codigoRuta;
    }

    public double getCapacidadContratada() {
        return capacidadContratada;
    }

    public void setCapacidadContratada(double capacidadContratada) {
        this.capacidadContratada = capacidadContratada;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
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

    public String getIncidencias() {
        return incidencias;
    }

    public void setIncidencias(String incidencias) {
        this.incidencias = incidencias;
    }

    public String getSegmentos() {
        return segmentos;
    }

    public void setSegmentos(String segmentos) {
        this.segmentos = segmentos;
    }

    public String getSeveridadMaxima() {
        return severidadMaxima;
    }

    public void setSeveridadMaxima(String severidadMaxima) {
        this.severidadMaxima = severidadMaxima;
    }

    public int getTramosFueraServicio() {
        return tramosFueraServicio;
    }

    public void setTramosFueraServicio(int tramosFueraServicio) {
        this.tramosFueraServicio = tramosFueraServicio;
    }

    // Interrumpido si algún segmento de la ruta está Fuera de servicio; si no, Degradado
    public String getSituacion() {
        return tramosFueraServicio > 0 ? "Interrumpido" : "Degradado";
    }
}
