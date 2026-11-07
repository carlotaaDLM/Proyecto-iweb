package beans;


public class UtilizacionHist {

    private int idRegistro;
    private String codigoSegmento;
    private String fecha;
    private double capacidadTotal;
    private double capacidadUtilizada;
    private double capacidadDisponible;

    public UtilizacionHist() {
    }

    public int getIdRegistro() {
        return idRegistro;
    }

    public void setIdRegistro(int idRegistro) {
        this.idRegistro = idRegistro;
    }

    public String getCodigoSegmento() {
        return codigoSegmento;
    }

    public void setCodigoSegmento(String codigoSegmento) {
        this.codigoSegmento = codigoSegmento;
    }

    public String getFecha() {
        return fecha;
    }

    public void setFecha(String fecha) {
        this.fecha = fecha;
    }

    public double getCapacidadTotal() {
        return capacidadTotal;
    }

    public void setCapacidadTotal(double capacidadTotal) {
        this.capacidadTotal = capacidadTotal;
    }

    public double getCapacidadUtilizada() {
        return capacidadUtilizada;
    }

    public void setCapacidadUtilizada(double capacidadUtilizada) {
        this.capacidadUtilizada = capacidadUtilizada;
    }

    public double getCapacidadDisponible() {
        return capacidadDisponible;
    }

    public void setCapacidadDisponible(double capacidadDisponible) {
        this.capacidadDisponible = capacidadDisponible;
    }

    public double getPorcentajeUso() {
        if (capacidadTotal <= 0) {
            return 0;
        }
        return capacidadUtilizada * 100.0 / capacidadTotal;
    }

}
