package com.sara.automation.utils;

/**
 * ThreadLocal para almacenar el número de expediente del caso creado.
 *
 * Se captura cuando el caso llega a "Concluido" (ver CapturarExpediente) y se
 * reutiliza más adelante en el mismo escenario (p. ej. tras cerrar sesión y
 * reingresar como proveedor PRUEBAS50, para buscar el expediente).
 *
 * Es ThreadLocal porque la ejecución es paralela: cada fork/escenario corre en
 * su propio thread y debe ver únicamente SU expediente.
 */
public class ExpedienteContext {

    private static final ThreadLocal<String> expediente = new ThreadLocal<>();

    private ExpedienteContext() {}

    public static void setExpediente(String numero) {
        System.out.println("[ExpedienteContext] GUARDAR expediente '" + numero
                + "' en thread: " + Thread.currentThread().getName());
        expediente.set(numero);
    }

    /**
     * @return el expediente capturado para este thread.
     * @throws IllegalStateException si aún no se ha capturado (evita usar null silenciosamente).
     */
    public static String getExpediente() {
        String numero = expediente.get();
        if (numero == null || numero.trim().isEmpty()) {
            throw new IllegalStateException(
                    "No hay expediente capturado en este thread. ¿Se ejecutó 'capturamos el numero de expediente' antes?");
        }
        System.out.println("[ExpedienteContext] OBTENER expediente '" + numero
                + "' del thread: " + Thread.currentThread().getName());
        return numero;
    }

    public static boolean tieneExpediente() {
        String numero = expediente.get();
        return numero != null && !numero.trim().isEmpty();
    }

    public static void clear() {
        expediente.remove();
    }
}
