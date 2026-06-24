Feature: Creacion de Expedientes en el sistema de gestion de casos
  @batch1
  Scenario: Test Usuario 01 - ANTIOQUIA - MEDELLIN - AUTOS - PASO DE GASOLINA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
   And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio          |
      | ANTIOQUIA             | MEDELLIN           | NO                   | NO                  | AUTOS | GRUA  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS40 PRUEBAS40 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch2
  Scenario: Test Usuario 02 - BOGOTA - BOGOTA - AUTOS - ABOGADO EN SITIO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
   And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio         |
      | BOGOTA D.C.                | BOGOTA D.C.             | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR INMOVILIZACION DEL VH|
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS41 PRUEBAS41 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch3
  Scenario: Test Usuario 03 - VALLE DEL CAUCA - BAJO CALIMA - AUTOS - MECANICA BASICA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
   And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio         |
      | ANTIOQUIA     | MEDELLIN          | NO                   | NO                  | CONDUCTOR ELEGIDO | CONDUCTOR ELEGIDO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS42 PRUEBAS42 | TOMA SERVICIO |
   And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch4
  Scenario: Test Usuario 04 - ATLANTICO - BARANOA - AUTOS - FRENOS
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
   And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio |
      | ANTIOQUIA             | MEDELLIN            | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR INMOVILIZACION DEL VH   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS43 PRUEBAS43 | TOMA SERVICIO |
  And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch5
  Scenario: Test Usuario 05 - CUNDINAMARCA - SOACHA - AUTOS - AMBULANCIA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio     |
      | BOGOTA D.C.          | BOGOTA D.C.             | NO                   | NO                  | AUTOS | CONDUCTOR ELEGIDO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS44 PRUEBAS44 | TOMA SERVICIO |
  And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch6
  Scenario: Test Usuario 06 - SANTANDER - BUCARAMANGA - AUTOS - GRUA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio |
      | BOGOTA D.C.            | BOGOTA D.C.      | NO                   | NO                  | AUTOS | GRUA     |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS45 PRUEBAS45 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch7
  Scenario: Test Usuario 07 - NORTE DE SANTANDER - CUCUTA - AUTOS - CAMBIO LLANTAS
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
   And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio        |
      | BOGOTA D.C.          | BOGOTA D.C.       | NO                   | NO                  | AUTOS | CONDUCTOR ELEGIDO  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS46 PRUEBAS46 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch8
  Scenario: Test Usuario 08 - MAGDALENA - SANTA MARTA - AUTOS - CERRAJERO AUTOS COMPLEJIDAD BAJA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
   And diligencia caso express completo desde feature
           | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio         |
      | ANTIOQUIA     | MEDELLIN          | NO                   | NO                  | CONDUCTOR ELEGIDO | CONDUCTOR ELEGIDO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS47 PRUEBAS47 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch9
  Scenario: Test Usuario 09 - BOLIVAR - CARTAGENA LAGUNA CLUB - AUTOS - DESPLAZAMIENTO POR HORAS
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
    | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio |
      | ANTIOQUIA             | MEDELLIN            | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR INMOVILIZACION DEL VH   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS48 PRUEBAS48 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch10
  Scenario: Test Usuario 10 - NARIÑO - PASTO - AUTOS - FACILITADOR VIRTUAL
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio |
      | ANTIOQUIA             | MEDELLIN            | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR INMOVILIZACION DEL VH   |
          And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS49 PRUEBAS49 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor
  @batch11
  Scenario: Reclamaciones - Creacion de caso de reclamacion 51
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch12
  Scenario: Reclamaciones - Creacion de caso de reclamacion 52
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch13
  Scenario: Reclamaciones - Creacion de caso de reclamacion 53
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch14
  Scenario: Reclamaciones - Creacion de caso de reclamacion 54
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch15
  Scenario: Reclamaciones - Creacion de caso de reclamacion 55
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch16
  Scenario: Reclamaciones - Creacion de caso de reclamacion 56
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch17
  Scenario: Reclamaciones - Creacion de caso de reclamacion 57
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch18
  Scenario: Reclamaciones - Creacion de caso de reclamacion 58
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch19
  Scenario: Reclamaciones - Creacion de caso de reclamacion 59
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion

  @batch20
  Scenario: Reclamaciones - Creacion de caso de reclamacion 60
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And creamos un caso de reclamaciones
    And gestionamos la reclamacion
