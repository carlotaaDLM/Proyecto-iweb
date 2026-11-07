package beans;

public class SegmentoAtencion {

    private String codigoSegmento;
    private String tramo;
    private String estado;
    private int incidenciasAbiertas;
    private int serviciosQueLoUsan;

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

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public int getIncidenciasAbiertas() {
        return incidenciasAbiertas;
    }

    public void setIncidenciasAbiertas(int incidenciasAbiertas) {
        this.incidenciasAbiertas = incidenciasAbiertas;
    }

    public int getServiciosQueLoUsan() {
        return serviciosQueLoUsan;
    }

    public void setServiciosQueLoUsan(int serviciosQueLoUsan) {
        this.serviciosQueLoUsan = serviciosQueLoUsan;
    }
}