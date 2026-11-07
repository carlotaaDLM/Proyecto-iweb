package beans;

// Resumen de la utilización histórica de un segmento en un periodo
public class UtilizacionSegmento {

    private String codigoSegmento;
    private double capacidadTotal;
    private String mesInicial;
    private double porcentajeInicial;
    private String mesFinal;
    private double porcentajeFinal;
    private double porcentajeMaximo;

    public UtilizacionSegmento() {
    }

    // Toma en cuenta un registro mensual de UTILIZACION_HIST
    public void agregar(UtilizacionHist u) {
        double porcentaje = u.getCapacidadTotal() > 0
                ? u.getCapacidadUtilizada() * 100.0 / u.getCapacidadTotal()
                : 0;
        if (mesInicial == null) {
            mesInicial = u.getFecha();
            porcentajeInicial = porcentaje;
        }
        mesFinal = u.getFecha();
        porcentajeFinal = porcentaje;
        capacidadTotal = u.getCapacidadTotal();
        if (porcentaje > porcentajeMaximo) {
            porcentajeMaximo = porcentaje;
        }
    }

    // Puntos porcentuales que subió o bajó entre el primer y el último mes
    public double getVariacion() {
        return porcentajeFinal - porcentajeInicial;
    }

    public String getCodigoSegmento() {
        return codigoSegmento;
    }

    public void setCodigoSegmento(String codigoSegmento) {
        this.codigoSegmento = codigoSegmento;
    }

    public double getCapacidadTotal() {
        return capacidadTotal;
    }

    public String getMesInicial() {
        return mesInicial;
    }

    public double getPorcentajeInicial() {
        return porcentajeInicial;
    }

    public String getMesFinal() {
        return mesFinal;
    }

    public double getPorcentajeFinal() {
        return porcentajeFinal;
    }

    public double getPorcentajeMaximo() {
        return porcentajeMaximo;
    }
}
