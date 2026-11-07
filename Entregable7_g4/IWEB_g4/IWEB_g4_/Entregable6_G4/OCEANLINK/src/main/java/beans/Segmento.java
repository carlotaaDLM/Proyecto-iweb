package beans;

public class Segmento {

    private String codigoSegmento;
    private double capacidadTotal;
    private double capacidadUtilizada;
    private double capacidadReservada;
    private String estado;
    private String idOrigen;
    private String nombreOrigen;
    private String ciudadOrigen;
    private String paisOrigen;
    private String idDestino;
    private String nombreDestino;
    private String ciudadDestino;
    private String paisDestino;
    private int cantidadServicios;
    private int incidenciasAbiertas;
    private String codigoMantenimiento;   // último mantenimiento asignado (Maintenance Coordinator)
    private String estadoMantenimiento;
    private int dependencias;            // registros que la usan (rutas, incidencias...)

    public Segmento() {
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

    public void setCapacidadTotal(double capacidadTotal) {
        this.capacidadTotal = capacidadTotal;
    }

    public double getCapacidadUtilizada() {
        return capacidadUtilizada;
    }

    public void setCapacidadUtilizada(double capacidadUtilizada) {
        this.capacidadUtilizada = capacidadUtilizada;
    }

    public double getCapacidadReservada() {
        return capacidadReservada;
    }

    public void setCapacidadReservada(double capacidadReservada) {
        this.capacidadReservada = capacidadReservada;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getIdOrigen() {
        return idOrigen;
    }

    public void setIdOrigen(String idOrigen) {
        this.idOrigen = idOrigen;
    }

    public String getNombreOrigen() {
        return nombreOrigen;
    }

    public void setNombreOrigen(String nombreOrigen) {
        this.nombreOrigen = nombreOrigen;
    }

    public String getCiudadOrigen() {
        return ciudadOrigen;
    }

    public void setCiudadOrigen(String ciudadOrigen) {
        this.ciudadOrigen = ciudadOrigen;
    }

    public String getPaisOrigen() {
        return paisOrigen;
    }

    public void setPaisOrigen(String paisOrigen) {
        this.paisOrigen = paisOrigen;
    }

    public String getIdDestino() {
        return idDestino;
    }

    public void setIdDestino(String idDestino) {
        this.idDestino = idDestino;
    }

    public String getNombreDestino() {
        return nombreDestino;
    }

    public void setNombreDestino(String nombreDestino) {
        this.nombreDestino = nombreDestino;
    }

    public String getCiudadDestino() {
        return ciudadDestino;
    }

    public void setCiudadDestino(String ciudadDestino) {
        this.ciudadDestino = ciudadDestino;
    }

    public String getPaisDestino() {
        return paisDestino;
    }

    public void setPaisDestino(String paisDestino) {
        this.paisDestino = paisDestino;
    }

    public int getCantidadServicios() {
        return cantidadServicios;
    }

    public void setCantidadServicios(int cantidadServicios) {
        this.cantidadServicios = cantidadServicios;
    }

    public int getIncidenciasAbiertas() {
        return incidenciasAbiertas;
    }

    public void setIncidenciasAbiertas(int incidenciasAbiertas) {
        this.incidenciasAbiertas = incidenciasAbiertas;
    }

    // Capacidad disponible = total - utilizada - reservada
    public double getCapacidadDisponible() {
        return capacidadTotal - capacidadUtilizada - capacidadReservada;
    }

    // Tramo con el nombre corto de las estaciones: "Lurín → Máncora"
    public String getTramo() {
        return nombreCorto(nombreOrigen) + " → " + nombreCorto(nombreDestino);
    }

    private String nombreCorto(String nombreEstacion) {
        return nombreEstacion == null ? "" : nombreEstacion.replace("Estación ", "");
    }

    // Porcentaje de uso del segmento
    public double getPorcentajeUso() {
        if (capacidadTotal <= 0) {
            return 0;
        }
        return capacidadUtilizada * 100.0 / capacidadTotal;
    }

    // Ocupación = (utilizada + reservada) / total. Lo reservado ya no está
    // disponible para nuevas solicitudes, por eso cuenta para las alertas (RF12)
    public double getPorcentajeOcupacion() {
        if (capacidadTotal <= 0) {
            return 0;
        }
        return (capacidadUtilizada + capacidadReservada) * 100.0 / capacidadTotal;
    }

    // Nivel de alerta: menor a 80% Normal, 80%-95% Alta, mayor a 95% Crítica
    public String getNivelUso() {
        double porcentaje = getPorcentajeOcupacion();
        if (porcentaje > 95) {
            return "Crítica";
        }
        if (porcentaje >= 80) {
            return "Alta";
        }
        return "Normal";
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

    public int getDependencias() {
        return dependencias;
    }

    public void setDependencias(int dependencias) {
        this.dependencias = dependencias;
    }

    public void invertir() {
        String id = idOrigen, nombre = nombreOrigen, ciudad = ciudadOrigen, pais = paisOrigen;
        idOrigen = idDestino;
        nombreOrigen = nombreDestino;
        ciudadOrigen = ciudadDestino;
        paisOrigen = paisDestino;
        idDestino = id;
        nombreDestino = nombre;
        ciudadDestino = ciudad;
        paisDestino = pais;
    }
}
