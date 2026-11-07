package beans;

public class SolicitudCapacidad {

    private int idSolicitud;
    private int idCliente;
    private String razonSocialCliente;
    private String idOrigen;
    private String nombreOrigen;
    private String idDestino;
    private String nombreDestino;
    private Integer idRuta;
    private String codigoRuta;
    private double capacidadRequerida;
    private String estado;
    private String fechaSolicitud;
    private String fechaRequerida;
    private String observaciones;
    private int dniUsuario;
    private String nombreUsuario;
    private Integer idServicio;
    private double capacidadReservada;

    public SolicitudCapacidad() {
    }

    public int getIdSolicitud() {
        return idSolicitud;
    }

    public void setIdSolicitud(int idSolicitud) {
        this.idSolicitud = idSolicitud;
    }

    public int getIdCliente() {
        return idCliente;
    }

    public void setIdCliente(int idCliente) {
        this.idCliente = idCliente;
    }

    public String getRazonSocialCliente() {
        return razonSocialCliente;
    }

    public void setRazonSocialCliente(String razonSocialCliente) {
        this.razonSocialCliente = razonSocialCliente;
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

    public Integer getIdRuta() {
        return idRuta;
    }

    public void setIdRuta(Integer idRuta) {
        this.idRuta = idRuta;
    }

    public String getCodigoRuta() {
        return codigoRuta;
    }

    public void setCodigoRuta(String codigoRuta) {
        this.codigoRuta = codigoRuta;
    }

    public double getCapacidadRequerida() {
        return capacidadRequerida;
    }

    public void setCapacidadRequerida(double capacidadRequerida) {
        this.capacidadRequerida = capacidadRequerida;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getFechaSolicitud() {
        return fechaSolicitud;
    }

    public void setFechaSolicitud(String fechaSolicitud) {
        this.fechaSolicitud = fechaSolicitud;
    }

    public String getFechaRequerida() {
        return fechaRequerida;
    }

    public void setFechaRequerida(String fechaRequerida) {
        this.fechaRequerida = fechaRequerida;
    }

    public String getObservaciones() {
        return observaciones;
    }

    public void setObservaciones(String observaciones) {
        this.observaciones = observaciones;
    }

    public int getDniUsuario() {
        return dniUsuario;
    }

    public void setDniUsuario(int dniUsuario) {
        this.dniUsuario = dniUsuario;
    }

    public String getNombreUsuario() {
        return nombreUsuario;
    }

    public void setNombreUsuario(String nombreUsuario) {
        this.nombreUsuario = nombreUsuario;
    }

    public Integer getIdServicio() {
        return idServicio;
    }

    public void setIdServicio(Integer idServicio) {
        this.idServicio = idServicio;
    }

    public double getCapacidadReservada() {
        return capacidadReservada;
    }

    public void setCapacidadReservada(double capacidadReservada) {
        this.capacidadReservada = capacidadReservada;
    }

    // SOL-004
    public String getCodigo() {
        return String.format("SOL-%03d", idSolicitud);
    }

    // "Lurín → Balboa"
    public String getTramo() {
        return nombreCorto(nombreOrigen) + " → " + nombreCorto(nombreDestino);
    }

    // Ya tiene reservada toda la capacidad pedida en su ruta
    public boolean isReservada() {
        return capacidadReservada > 0;
    }

    private String nombreCorto(String nombreEstacion) {
        return nombreEstacion == null ? "" : nombreEstacion.replace("Estación ", "");
    }

}
