package beans;

// Datos para paginar un listado en el servidor:
// el DAO usa getInicio() y getTamanio() en "LIMIT ?, ?" y la vista arma los enlaces
public class Paginacion {

    public static final int TAMANIO = 10;   // filas por página

    private int pagina;          // página actual (empieza en 1)
    private int tamanio;
    private int totalRegistros;  // resultado del SELECT COUNT(*)
    private String url;          // enlace con los filtros, sin el número de página

    public Paginacion() {
        this.pagina = 1;
        this.tamanio = TAMANIO;
    }

    // Lee el parámetro "pagina" (si no es un número válido se queda en 1)
    public Paginacion(String pagina) {
        this();
        try {
            this.pagina = Integer.parseInt(pagina.trim());
        } catch (NumberFormatException | NullPointerException e) {
            this.pagina = 1;
        }
        if (this.pagina < 1) {
            this.pagina = 1;
        }
    }

    public int getPagina() {
        return pagina;
    }

    public void setPagina(int pagina) {
        this.pagina = pagina;
    }

    public int getTamanio() {
        return tamanio;
    }

    public void setTamanio(int tamanio) {
        this.tamanio = tamanio;
    }

    public int getTotalRegistros() {
        return totalRegistros;
    }

    // Al conocer el total se corrige la página si se pidió una que no existe
    public void setTotalRegistros(int totalRegistros) {
        this.totalRegistros = totalRegistros;
        if (pagina > getTotalPaginas()) {
            pagina = getTotalPaginas();
        }
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public int getTotalPaginas() {
        if (totalRegistros <= 0) {
            return 1;
        }
        return (totalRegistros + tamanio - 1) / tamanio;
    }

    // Primer registro de la página (para LIMIT ?, ?)
    public int getInicio() {
        return (pagina - 1) * tamanio;
    }

    // Número del último registro que se muestra (para "Mostrando 1 a 10 de 24")
    public int getFin() {
        return Math.min(getInicio() + tamanio, totalRegistros);
    }
}
