package com.sara.automation.utils;

import com.sara.automation.utils.ProveedorPoolManager.Proveedor;

/**
 * ThreadLocal con el proveedor asignado al escenario actual.
 *
 * Se fija al diligenciar el proveedor (paso 'diligenciamos el proveedor') con un proveedor
 * aleatorio del pool, y se reutiliza al reloguear (paso de re-ingreso), garantizando que el
 * caso se gestione logueándose como el MISMO proveedor al que se asignó.
 *
 * Es ThreadLocal porque la ejecución es paralela (un fork/escenario por thread) y se limpia
 * en el @After del escenario para que cada escenario reciba un proveedor nuevo.
 */
public class ProveedorContext {

    private static final ThreadLocal<Proveedor> proveedor = new ThreadLocal<>();

    private ProveedorContext() {}

    public static void set(Proveedor p) {
        System.out.println("[ProveedorContext] Proveedor del escenario: " + p.getUsuario()
                + " (" + p.getNombreFormulario() + ")");
        proveedor.set(p);
    }

    public static Proveedor get() {
        Proveedor p = proveedor.get();
        if (p == null) {
            throw new IllegalStateException(
                    "No hay proveedor asignado en este thread. ¿Se ejecutó 'diligenciamos el proveedor' antes?");
        }
        return p;
    }

    /** Igual que {@link #get()} pero devuelve null en lugar de lanzar si no hay proveedor. */
    public static Proveedor getOrNull() {
        return proveedor.get();
    }

    public static void clear() {
        proveedor.remove();
    }
}
