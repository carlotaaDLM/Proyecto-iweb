package beans;

// Indicadores de un mes (RF39): utilización de la red, segmentos >= 80%, incidencias y mantenimientos
public class IndicadorMes {

    private String mes;
    private double capacidadUtilizada;
    private double capacidadTotal;
    private int segmentosAlta;
    private int incidencias;
    private int mantenimientos;

    public IndicadorMes() {
    }

    public String getMes() {
        return mes;
    }

    public void setMes(String mes) {
        this.mes = mes;
    }

    public double getCapacidadUtilizada() {
        return capacidadUtilizada;
    }

    public void setCapacidadUtilizada(double capacidadUtilizada) {
        this.capacidadUtilizada = capacidadUtilizada;
    }

    public double getCapacidadTotal() {
        return capacidadTotal;
    }

    public void setCapacidadTotal(double capacidadTotal) {
        this.capacidadTotal = capacidadTotal;
    }

    public int getSegmentosAlta() {
        return segmentosAlta;
    }

    public void setSegmentosAlta(int segmentosAlta) {
        this.segmentosAlta = segmentosAlta;
    }

    public int getIncidencias() {
        return incidencias;
    }

    public void setIncidencias(int incidencias) {
        this.incidencias = incidencias;
    }

    public int getMantenimientos() {
        return mantenimientos;
    }

    public void setMantenimientos(int mantenimientos) {
        this.mantenimientos = mantenimientos;
    }

    // Porcentaje de la capacidad total de la red utilizada en el mes
    public double getPorcentajeUso() {
        if (capacidadTotal <= 0) {
            return 0;
        }
        return capacidadUtilizada * 100.0 / capacidadTotal;
    }
}
