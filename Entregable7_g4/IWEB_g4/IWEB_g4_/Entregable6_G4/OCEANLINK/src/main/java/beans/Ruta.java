package beans;


public class Ruta {

    private int idRuta;
    private String codigo;
    private String estado;
    private java.util.List<Segmento> segmentos;
    private int cantidadServicios;
    private int cantidadSolicitudes;

    public Ruta() {
    }

    public int getIdRuta() {
        return idRuta;
    }

    public void setIdRuta(int idRuta) {
        this.idRuta = idRuta;
    }

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public java.util.List<Segmento> getSegmentos() {
        return segmentos;
    }

    public void setSegmentos(java.util.List<Segmento> segmentos) {
        this.segmentos = segmentos;
    }

    public int getCantidadServicios() {
        return cantidadServicios;
    }

    public void setCantidadServicios(int cantidadServicios) {
        this.cantidadServicios = cantidadServicios;
    }

    public int getCantidadSolicitudes() {
        return cantidadSolicitudes;
    }

    public void setCantidadSolicitudes(int cantidadSolicitudes) {
        this.cantidadSolicitudes = cantidadSolicitudes;
    }

    public String getIdOrigen() {
        return segmentos == null || segmentos.isEmpty() ? null : segmentos.get(0).getIdOrigen();
    }

    public String getIdDestino() {
        return segmentos == null || segmentos.isEmpty() ? null : segmentos.get(segmentos.size() - 1).getIdDestino();
    }

    // "Lurín → Máncora → Salinas"
    public String getRecorrido() {
        if (segmentos == null || segmentos.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder(nombreCorto(segmentos.get(0).getNombreOrigen()));
        for (Segmento s : segmentos) {
            sb.append(" → ").append(nombreCorto(s.getNombreDestino()));
        }
        return sb.toString();
    }

    // "Lurín → Salinas"
    public String getTramo() {
        if (segmentos == null || segmentos.isEmpty()) {
            return "";
        }
        return nombreCorto(segmentos.get(0).getNombreOrigen()) + " → "
                + nombreCorto(segmentos.get(segmentos.size() - 1).getNombreDestino());
    }

    // La capacidad de una ruta la limita su segmento con menos disponible
    public double getCapacidadDisponible() {
        if (segmentos == null) {
            return 0;
        }
        double minimo = -1;
        for (Segmento s : segmentos) {
            if (minimo < 0 || s.getCapacidadDisponible() < minimo) {
                minimo = s.getCapacidadDisponible();
            }
        }
        return minimo < 0 ? 0 : minimo;
    }

    // Segmento con menos capacidad disponible (cuello de botella)
    public Segmento getSegmentoMasCargado() {
        Segmento cuello = null;
        if (segmentos == null) {
            return null;
        }
        for (Segmento s : segmentos) {
            if (cuello == null || s.getCapacidadDisponible() < cuello.getCapacidadDisponible()) {
                cuello = s;
            }
        }
        return cuello;
    }

    public boolean isTieneSegmentoFueraServicio() {
        if (segmentos == null) {
            return false;
        }
        for (Segmento s : segmentos) {
            if ("Fuera de servicio".equals(s.getEstado())) {
                return true;
            }
        }
        return false;
    }

    private String nombreCorto(String nombreEstacion) {
        return nombreEstacion == null ? "" : nombreEstacion.replace("Estación ", "");
    }

}
