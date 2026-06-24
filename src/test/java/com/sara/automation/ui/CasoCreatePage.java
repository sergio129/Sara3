package com.sara.automation.ui;

import net.serenitybdd.screenplay.targets.Target;
import org.openqa.selenium.By;

public class CasoCreatePage {
    // Localizador principal: busca en AMBOS idiomas (Express Case o Caso Express)
    public static final Target Caso_Express = Target.the("Boton Caso Express / Express Case")
            .located(By.xpath("//button[contains(normalize-space(.), 'Express Case') or contains(normalize-space(.), 'Caso Express')] | " +
                             "//a[contains(normalize-space(.), 'Express Case') or contains(normalize-space(.), 'Caso Express')]"));

    // Fallback 1: sin normalize-space (a veces falla en headless)
    public static final Target Caso_Express_FALLBACK = Target.the("Boton Express Case / Caso Express (fallback)")
            .located(By.xpath("//button[contains(., 'Express Case') or contains(., 'Caso Express')] | " +
                             "//a[contains(., 'Express Case') or contains(., 'Caso Express')] | " +
                             "//*[contains(@class, 'menu-item') and (contains(., 'Express Case') or contains(., 'Caso Express'))]"));

    // Fallback 2: por data-testid o id específico
    public static final Target Caso_Express_FALLBACK2 = Target.the("Boton Express Case por testid")
            .located(By.xpath("//button[contains(@data-testid, 'express') or contains(@data-testid, 'caso') or contains(@id, 'express') or contains(@id, 'caso')] | " +
                             "//*[@role='tab' and (contains(., 'Express') or contains(., 'Caso'))]"));

    // Fallback 3: búsqueda flexible por contenido
    public static final Target Caso_Express_FALLBACK3 = Target.the("Boton por contenido flexible")
            .located(By.xpath("//div[@role='menuitem' or @class='menu-item']//span[contains(., 'Express') or contains(., 'Caso')]/ancestor::*[self::button or self::a or self::div[@role='menuitem' or @role='tab']]"));

    // Nuevo: item de menú que aparece al abrir Caso Express
    public static final Target Formulario_Creacion_ASISTENCIA = Target.the("Formulario Creación de Casos (ASISTENCIA)")
            .located(By.xpath("//div[.//span[normalize-space(text())='Formulario Creación de Casos (ASISTENCIA)'] and @role='menuitem']"));

    // Item de menú para el flujo de RECLAMACIONES
    public static final Target Formulario_Creacion_RECLAMACIONES = Target.the("Formulario Creación de Casos (RECLAMACIONES)")
            .located(By.xpath("//div[@role='menuitem'][.//span[contains(normalize-space(.),'RECLAMACIONES')]]"));

    // Boton que aparece en la pantalla de creación/edición para habilitar el formulario (dentro del panel card-body)
    // Usa CSS selector para evitar problemas con corchetes en XPath
    public static final Target Habilitar_Formulario = Target.the("Boton Habilitar Formulario")
            .located(By.cssSelector("button[name*='habilitar_edicion_del_caso']"));

    // Fallback: buscar por clase dentro del panel específico
    public static final Target Habilitar_Formulario_FALLBACK = Target.the("Boton Habilitar Formulario (ref button)")
            .located(By.xpath("//div[@id='eoq0dnq-habilitar_edicion_del_caso_panel']//button[@ref='button']"));
    
    // Fallback 2: búsqueda más flexible por contenido
    public static final Target Habilitar_Formulario_FALLBACK2 = Target.the("Boton Habilitar Formulario (flexible)")
            .located(By.xpath("//div[contains(@class, 'card-body') and .//button[contains(normalize-space(.), 'Habilitar')]]//button[contains(@class, 'btn-primary')]"));
    
    // Fallback 3: búsqueda genérica dentro de panel
    public static final Target Habilitar_Formulario_FALLBACK3 = Target.the("Boton Habilitar Formulario (genérico)")
            .located(By.xpath("//button[contains(normalize-space(.), 'Habilitar Formulario')]"));

    // OneScript Iframe selector
    public static final By Form_OneScript_Iframe_By = By.id("form_onescript_iframe");

    // Campos a diligenciar automaticamente (selectores por atributo name para mayor estabilidad)
    public static final Target Numero_Expediente = Target.the("Número expediente")
            .located(By.cssSelector("input[name='data[numero_expediente]']"));

    public static final Target Nombre_Solicitante = Target.the("Nombre solicitante")
            .located(By.cssSelector("input[name='data[nombre_solicitante]']"));

    public static final Target Cedula_Solicitante = Target.the("Cédula del solicitante")
            .located(By.cssSelector("input[name='data[cedula_del_solicitante]'], input[name='data[cedula_solicitante]']"));

    public static final Target Telefono_1 = Target.the("Teléfono 1")
            .located(By.cssSelector("input[name='data[telefono_1]']"));

    public static final Target Telefono_2 = Target.the("Teléfono 2")
            .located(By.cssSelector("input[name='data[telefono_2]']"));

    public static final Target Placa = Target.the("Placa")
            .located(By.cssSelector("input[name='data[placa]']"));

    public static final Target Marca_Vehiculo = Target.the("Marca vehículo")
            .located(By.cssSelector("input[name='data[marca_vehiculo]']"));

    public static final Target Direccion_Servicio = Target.the("Dirección servicio")
            .located(By.cssSelector("input[name='data[direccion_servicio]']"));

    public static final Target Direccion_Destino = Target.the("Dirección del destino")
            .located(By.cssSelector("input[name='data[direccion_del_destino]']"));

    public static final Target Detalle_Direccion_Servicio = Target.the("Detalle dirección servicio")
            .located(By.cssSelector("input[name='data[detalle_direccion_servicio]']"));

    public static final Target Detalle_Direccion_Destino = Target.the("Detalle dirección destino")
            .located(By.cssSelector("input[name='data[detalle_direccion_destino]']"));

    public static final Target Ubicacion_Servicio = Target.the("Ubicación servicio")
            .located(By.cssSelector("input[name='data[ubicacion_servicio]']"));

    // Seccion inferior para anclar combos dependientes
    public static final Target Seccion_Asignacion = Target.the("Sección Asignación")
            .located(By.xpath("//div[contains(@class,'panel') or contains(@class,'card')][.//*[normalize-space(.)='Asignación'] or .//h3[normalize-space(.)='Asignación']]"));

    // Campo de observaciones/comentario libre al final del formulario, antes de Guardar.
    public static final Target Observacion_Final = Target.the("Observación final del caso")
            .located(By.xpath("//button[contains(@class,'mic-button')]/ancestor::div[contains(@class,'form-group')][1]//textarea[@maxlength='1024' and @rows='6'] | //textarea[contains(@class,'form-control') and @maxlength='1024' and @rows='6']"));

    // Combos en seccion General (listas dependientes)
    public static final Target Departamento_Solicita_Combo = Target.the("Departamento solicita")
            .located(By.xpath("//div[contains(@class,'formio-component-departamento_solicita')]//div[contains(@class,'custom-dropdown-control')]"));

    public static final Target Municipio_Solicita_Combo = Target.the("Municipio solicita")
            .located(By.xpath("//div[contains(@class,'formio-component-municipio_solicita')]//div[contains(@class,'custom-dropdown-control')]"));

    // Municipio por name (si existe como input/select estándar)
    public static final Target Municipio_Solicita_Input = Target.the("Municipio solicita (input/select by name)")
            .located(By.cssSelector("select[name='data[municipio_solicita]'], input[name='data[municipio_solicita]']"));

    // Combos en seccion Asignacion
    public static final Target Gestor_Coordinacion_Combo = Target.the("Gestor de coordinación")
            .located(By.xpath("//div[.//*[normalize-space(.)='Asignación']]//label[contains(normalize-space(.),'Gestor de coordinación')]/following::*[(self::button or self::input or self::div[contains(@class,'select')]) and not(self::input[@type='hidden'])][1]"));

    public static final Target Linea_Combo = Target.the("Línea")
            .located(By.xpath("//div[.//*[normalize-space(.)='Asignación']]//label[normalize-space()='Línea *' or normalize-space()='Línea']/following::*[(self::button or self::input or self::div[contains(@class,'select')]) and not(self::input[@type='hidden'])][1]"));

    public static final Target Servicio_Combo = Target.the("Servicio")
            .located(By.xpath("//div[.//*[normalize-space(.)='Asignación']]//label[normalize-space()='Servicio *' or normalize-space()='Servicio']/following::*[(self::button or self::input or self::div[contains(@class,'select')]) and not(self::input[@type='hidden'])][1]"));

    // Servicios especiales (combo) — suele ser un select con opciones NO/YES
    public static final Target Servicios_Especiales_Combo = Target.the("Servicios especiales")
            .located(By.cssSelector("select[name='data[servicios_especiales]'], input[name='data[servicios_especiales]'], div[data-name='servicios_especiales']"));

    public static final Target Opcion_Lista = Target.the("Opcion lista {0}")
            .locatedBy("//div[@role='option' and normalize-space(.)='{0}'] | //li[normalize-space(.)='{0}'] | //span[normalize-space(.)='{0}']");

    public static final Target Opcion_Lista_Contiene = Target.the("Opcion lista contiene {0}")
            .locatedBy("//div[@role='option' and contains(normalize-space(.),'{0}')] | //li[contains(normalize-space(.),'{0}')] | //span[contains(normalize-space(.),'{0}')]");

    // Custom dropdown helpers
    public static final Target CustomDropdownSearch = Target.the("Custom dropdown search input")
            .located(By.cssSelector("input.custom-dropdown-search, input[placeholder*='buscar']"));

    public static final Target CustomDropdownListItem = Target.the("Custom dropdown list item {0}")
            .locatedBy("//div[@class='custom-dropdown-item' and contains(normalize-space(), '{0}')] | //div[@role='option' and contains(normalize-space(), '{0}')]");

    // Save buttons
    public static final Target Guardar_Formulario = Target.the("Guardar Formulario")
            .located(By.xpath("//button[@name='data[kaceCustomSubmit]' or contains(normalize-space(.), 'Guardar')]") );

    public static final Target Guardar_Formulario_FALLBACK = Target.the("Guardar Formulario (Fallback)")
            .located(By.xpath("//button[@name='data[kaceCustomSubmit]' or contains(@class, 'btn-info') and contains(normalize-space(.), 'Guardar')]") );

    public static final Target Guardar_General_Flotante = Target.the("Guardar General (Flotante)")
            .located(By.xpath("//button[@id='kaceCustomSubmit' and @name='data[kaceCustomSubmit1]' and contains(normalize-space(.),'Guardar')]") );

    // Provider Management Tab
    public static final Target Tab_Gestion_Proveedores = Target.the("Tab Gestión de Proveedores")
            .located(By.xpath("//a[contains(normalize-space(.), 'Gestión de Proveedores') or contains(normalize-space(.), 'Proveedor') or contains(@href, 'gestion') and contains(@href, 'proveedor')] | //button[contains(normalize-space(.), 'Gestión de Proveedores') or contains(normalize-space(.), 'Proveedor')]"));

    public static final Target Tab_Gestion_Proveedores_FALLBACK = Target.the("Tab Gestión de Proveedores (Fallback)")
            .located(By.xpath("//a[contains(translate(normalize-space(.), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'gestión') or contains(translate(normalize-space(.), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'proveedor')]"));

    public static final Target Boton_Crear_Proveedor = Target.the("Botón Crear Proveedor")
            .located(By.xpath("//button[contains(normalize-space(.), 'Crear') and contains(@ref, 'gestion_proveedor')]"));

    public static final Target Boton_Crear_Proveedor_FALLBACK = Target.the("Botón Crear Proveedor (Fallback)")
            .located(By.xpath("//button[contains(normalize-space(.), 'Crear') and contains(@class, 'btn-primary')]")); 

    public static final Target Proveedor_Dialog = Target.the("Proveedor dialog")
            .located(By.xpath("//div[contains(@class,'formio-dialog') and descendant::label[normalize-space()='Nombre'] and descendant::label[normalize-space()='Respuesta de proveedor']]") );

    // Provider dropdown controls
    public static final Target Nombre_Proveedor_Dropdown_Control = Target.the("Nombre Proveedor Dropdown Control")
            .located(By.xpath("//div[contains(@class,'formio-dialog')]//div[contains(@class,'formio-component-custom-select') and contains(@class,'formio-component-nombre')]//div[contains(@class,'custom-dropdown-control')]") );

    public static final Target Nombre_Proveedor_Dropdown_Search = Target.the("Nombre Proveedor Dropdown Search")
            .located(By.xpath("//div[contains(@class,'formio-dialog')]//div[contains(@class,'formio-component-custom-select') and contains(@class,'formio-component-nombre')]//input[contains(@class,'custom-dropdown-search') or contains(translate(@placeholder,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'buscar')]") );

    public static final Target Respuesta_Proveedor_Dropdown_Control = Target.the("Respuesta Proveedor Dropdown Control")
            .located(By.xpath("//div[contains(@class,'formio-dialog')]//div[contains(@class,'formio-component-custom-select') and contains(@class,'formio-component-respuesta_de_proveedor')]//div[contains(@class,'custom-dropdown-control')]") );

    public static final Target Respuesta_Proveedor_Dropdown_Search = Target.the("Respuesta Proveedor Dropdown Search")
            .located(By.xpath("//div[contains(@class,'formio-dialog')]//div[contains(@class,'formio-component-custom-select') and contains(@class,'formio-component-respuesta_de_proveedor')]//input[contains(@class,'custom-dropdown-search') or contains(translate(@placeholder,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),'buscar')]") );

    // Provider form fields
    public static final Target Tiempo_Monitoreo_Sitio_Minutos = Target.the("Tiempo Monitoreo Sitio (Minutos)")
            .located(By.cssSelector("input[name*='tiempo_monitoreo_en_sitio']"));

    public static final Target Tiempo_Monitoreo_Destino_Minutos = Target.the("Tiempo Monitoreo Destino (Minutos)")
            .located(By.cssSelector("input[name*='tiempo_monitoreo_destino_minutos']"));

    public static final Target Celular_Tecnico_Proveedor = Target.the("Celular Técnico Proveedor")
            .located(By.cssSelector("input[name*='celular_tecnico']"));

    public static final Target Guardar_Proveedor = Target.the("Guardar Proveedor")
            .located(By.xpath("//div[@role='dialog']//button[contains(@class, 'btn-primary') and contains(normalize-space(text()), 'Guard')]"));

    // State transition buttons
    public static final Target Boton_Estado_Programado = Target.the("Botón Estado Programado")
            .located(By.xpath("//button[contains(normalize-space(.), 'Programado')]"));

    public static final Target Boton_Estado_Aceptado_Desplazamiento = Target.the("Botón Estado Aceptado y en Desplazamiento")
            .located(By.xpath("//button[contains(normalize-space(.), 'Aceptado')]"));

    public static final Target Boton_Estado_Concluido = Target.the("Botón Estado Concluido")
            .located(By.xpath("//button[contains(normalize-space(.), 'Concluido')]"));

    public static final Target Boton_Estado_Finalizado = Target.the("Botón Estado Finalizado")
            .located(By.xpath("//button[contains(normalize-space(.), 'Finalizado')]"));
}
