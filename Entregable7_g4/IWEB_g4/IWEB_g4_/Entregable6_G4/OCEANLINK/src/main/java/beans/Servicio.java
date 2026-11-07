package beans;

public class Servicio {

    private int idServicio;
    private double capacidadContratada;
    private String estado;
    private String codigoRuta;
    private String razonSocialCliente;
    private int idRuta;
    private String fechaActivacion;

    public Servicio() {
    }

    public int getIdServicio() {
        return idServicio;
    }

    public void setIdServicio(int idServicio) {
        this.idServicio = idServicio;
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

    public String getCodigoRuta() {
        return codigoRuta;
    }

    public void setCodigoRuta(String codigoRuta) {
        this.codigoRuta = codigoRuta;
    }

    public String getRazonSocialCliente() {
        return razonSocialCliente;
    }

    public void setRazonSocialCliente(String razonSocialCliente) {
        this.razonSocialCliente = razonSocialCliente;
    }


    public int getIdRuta() {
        return idRuta;
    }

    public void setIdRuta(int idRuta) {
        this.idRuta = idRuta;
    }

    public String getFechaActivacion() {
        return fechaActivacion;
    }

    public void setFechaActivacion(String fechaActivacion) {
        this.fechaActivacion = fechaActivacion;
    }

    // SRV-010
    public String getCodigo() {
        return String.format("SRV-%03d", idServicio);
    }
}
