package com.sara.automation.utils;

import java.util.ArrayList;
import java.util.List;
import java.util.MissingResourceException;
import java.util.ResourceBundle;
import java.util.stream.Collectors;

/**
 * Pool de proveedores para el flujo de gestión (asignación ALEATORIA por escenario).
 *
 * Independiente del pool de agentes (UserPoolManager). Carga las credenciales desde
 * credentials.properties con las claves:
 *   proveedor_usuario1, proveedor_contrasena1, proveedor_usuario2, ...
 *
 * Cada escenario toma un proveedor al azar (ver ProveedorContext, que lo fija al
 * diligenciar y lo reutiliza al reloguear), de modo que el caso se crea a nombre del
 * proveedor X y luego se gestiona logueándose como X (un proveedor solo ve sus expedientes).
 * Rotar entre varios genera tráfico de login multi-proveedor en pruebas de carga.
 */
public class ProveedorPoolManager {

    private static final ResourceBundle bundle = ResourceBundle.getBundle("credentials");
    private static final List<Proveedor> proveedores = new ArrayList<>();

    static {
        cargar();
    }

    private ProveedorPoolManager() {}

    private static void cargar() {
        int i = 1;
        while (true) {
            try {
                String usuario = bundle.getString("proveedor_usuario" + i);
                String contrasena = bundle.getString("proveedor_contrasena" + i);
                if (usuario != null && !usuario.trim().isEmpty()) {
                    proveedores.add(new Proveedor(usuario.trim(), contrasena));
                }
                i++;
            } catch (MissingResourceException e) {
                break;
            }
        }
        System.out.println("[ProveedorPoolManager] Pool de proveedores cargado: " + proveedores.size() + " proveedores");
        if (proveedores.isEmpty()) {
            throw new RuntimeException(
                    "No hay proveedores en el pool. Define proveedor_usuario1/proveedor_contrasena1 (..N) en credentials.properties");
        }
    }

    /**
     * Busca el proveedor del pool a partir del NOMBRE que viene en el feature
     * (p.ej. 'PRUEBAS40 PRUEBAS40'): deriva el login tomando el primer token en minúsculas
     * ('pruebas40') y lo localiza en el pool para obtener su contraseña.
     */
    public static Proveedor getByNombreFormulario(String nombreFormulario) {
        if (nombreFormulario == null || nombreFormulario.trim().isEmpty()) {
            throw new IllegalArgumentException("El nombre del proveedor del feature está vacío.");
        }
        String usuario = nombreFormulario.trim().split("\\s+")[0].toLowerCase();
        for (Proveedor p : proveedores) {
            if (p.getUsuario().equalsIgnoreCase(usuario)) {
                System.out.println("[ProveedorPoolManager] Proveedor del feature: " + nombreFormulario
                        + " -> login " + p.getUsuario());
                return p;
            }
        }
        throw new IllegalArgumentException("El proveedor '" + nombreFormulario + "' (login '" + usuario
                + "') no está en el pool. Define su credencial en credentials.properties (proveedor_usuarioN). "
                + "Disponibles: " + usuariosDisponibles());
    }

    public static int getTotal() {
        return proveedores.size();
    }

    private static String usuariosDisponibles() {
        return proveedores.stream().map(Proveedor::getUsuario).collect(Collectors.joining(", "));
    }

    /** Credenciales de un proveedor y su nombre tal como aparece en el formulario. */
    public static class Proveedor {
        private final String usuario;
        private final String contrasena;

        public Proveedor(String usuario, String contrasena) {
            this.usuario = usuario;
            this.contrasena = contrasena;
        }

        public String getUsuario() {
            return usuario;
        }

        public String getContrasena() {
            return contrasena;
        }

        /**
         * Nombre del proveedor tal como se escribe/busca en el formulario:
         * el usuario en MAYÚSCULAS y duplicado. Ej: 'pruebas40' -> 'PRUEBAS40 PRUEBAS40'.
         */
        public String getNombreFormulario() {
            String mayus = usuario.toUpperCase();
            return mayus + " " + mayus;
        }
    }
}
