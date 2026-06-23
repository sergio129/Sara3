Feature: Creacion de Expedientes en el sistema de gestion de casos
  @batch1
  Scenario: Test Usuario 01 - ANTIOQUIA - MEDELLIN - AUTOS - PASO DE GASOLINA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio          |
      | ANTIOQUIA             | MEDELLIN           | NO                   | NO                  | AUTOS | PASO DE GASOLINA  |
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
      | BOGOTA D.C.                | BOGOTA D.C.             | NO                   | NO                  | AUTOS | ABOGADO EN SITIO |
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
      | VALLE DEL CAUCA       | BAJO CALIMA        | NO                   | NO                  | AUTOS | MECANICA BASICA  |
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
      | ATLANTICO             | BARANOA            | NO                   | NO                  | AUTOS | FRENOS   |
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
      | CUNDINAMARCA          | SOACHA             | NO                   | NO                  | AUTOS | AMBULANCIA   |
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
      | SANTANDER             | BUCARAMANGA        | NO                   | NO                  | AUTOS | GRUA     |
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
      | NORTE DE SANTANDER    | CUCUTA             | NO                   | NO                  | AUTOS | CAMBIO LLANTAS  |
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
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio                            |
      | MAGDALENA             | SANTA MARTA        | NO                   | NO                  | AUTOS | CERRAJERO AUTOS COMPLEJIDAD BAJA    |
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
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio                 |
      | BOLIVAR               | CARTAGENA LAGUNA CLUB | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR HORAS |
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
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio              |
      | NARIÑO                | PASTO              | NO                   | NO                  | AUTOS | FACILITADOR VIRTUAL   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS49 PRUEBAS49 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch11
  Scenario: Test Usuario 11 - CAUCA - ALMAGUER - AUTOS - ABOGADO VIRTUAL
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio         |
      | CAUCA                 | ALMAGUER           | NO                   | NO                  | AUTOS | ABOGADO VIRTUAL  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS50 PRUEBAS50 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor
  @batch12
  Scenario: Test Usuario 12 - QUINDIO - ARMENIA - AUTOS - ORIENTACION JURIDICA TELEFONICA AUTOS
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio                              |
      | QUINDIO               | ARMENIA            | NO                   | NO                  | AUTOS | ORIENTACION JURIDICA TELEFONICA AUTOS |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS40 PRUEBAS40 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch13
  Scenario: Test Usuario 13 - RISARALDA - PEREIRA - AUTOS - CONDUCTOR PROFESIONAL
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio               |
      | RISARALDA             | PEREIRA            | NO                   | NO                  | AUTOS | CONDUCTOR PROFESIONAL  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS41 PRUEBAS41 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch14
  Scenario: Test Usuario 14 - TOLIMA - IBAGUE - AUTOS - CONDUCTOR FAMILIAR
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio            |
      | TOLIMA                | IBAGUE             | NO                   | NO                  | AUTOS | CONDUCTOR FAMILIAR  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS42 PRUEBAS42 | TOMA SERVICIO |
  And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch15
  Scenario: Test Usuario 15 - META - VILLAVICENCIO - AUTOS - ESTANCIA CONDUCTOR POR HURTO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio                        |
      | META                  | VILLAVICENCIO      | NO                   | NO                  | AUTOS | ESTANCIA CONDUCTOR POR HURTO    |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS43 PRUEBAS43 | TOMA SERVICIO |
  And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch16
  Scenario: Test Usuario 16 - SUCRE - SINCELEJO - AUTOS - DESPLAZAMIENTO VIAJERO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio                |
      | SUCRE                 | SINCELEJO          | NO                   | NO                  | AUTOS | DESPLAZAMIENTO VIAJERO  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS44 PRUEBAS44 | TOMA SERVICIO |
   And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch17
  Scenario: Test Usuario 17 - CORDOBA - ABROJAL - AUTOS - HOSPEDAJE VIAJERO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio            |
      | CORDOBA               | ABROJAL            | NO                   | NO                  | AUTOS | HOSPEDAJE VIAJERO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS45 PRUEBAS45 | TOMA SERVICIO |
  And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch18
  Scenario: Test Usuario 18 - CESAR - VALLEDUPAR - AUTOS - TRASLADO VEHICULO DE REEMPLAZO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio                        |
      | CESAR                 | VALLEDUPAR         | NO                   | NO                  | AUTOS | TRASLADO VEHICULO DE REEMPLAZO  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS46 PRUEBAS46 | TOMA SERVICIO |
  And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch19
  Scenario: Test Usuario 19 - GUAJIRA - RIOHACHA - AUTOS - RESCATE PARQUEADERO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio              |
      | GUAJIRA               | RIOHACHA           | NO                   | NO                  | AUTOS | RESCATE PARQUEADERO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS47 PRUEBAS47 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch20
  Scenario: Test Usuario 20 - ARAUCA - PANAMA DE ARAUCA - AUTOS - PARQUEADERO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio    |
      | ARAUCA                | PANAMA DE ARAUCA   | NO                   | NO                  | AUTOS | PARQUEADERO |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS48 PRUEBAS48 | TOMA SERVICIO |
   And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch21
  Scenario: Test Usuario 21 - CASANARE - CARIBAYONA - AUTOS - DIAGNOSTICO VEHICULO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio              |
      | CASANARE              | CARIBAYONA         | NO                   | NO                  | AUTOS | DIAGNOSTICO VEHICULO  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS49 PRUEBAS49 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch22
  Scenario: Test Usuario 22 - VICHADA - PUERTO CARREÑO - AUTOS - CAMBIO DE BATERIA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio           |
      | VICHADA               | PUERTO CARREÑO     | NO                   | NO                  | AUTOS | CAMBIO DE BATERIA  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS50 PRUEBAS50 | TOMA SERVICIO |
   And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch23
  Scenario: Test Usuario 23 - VICHADA - PUERTO CARREÑO  - AUTOS - CAMBIO DE DISPOSITIVO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio               |
      | VICHADA               | PUERTO CARREÑO     | NO                   | NO                  | AUTOS | CAMBIO DE DISPOSITIVO  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS40 PRUEBAS40 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch24
  Scenario: Test Usuario 24 - VAUPÉS - MITÚ - AUTOS - INSTALACION
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio    |
      | VAUPES                | MITU               | NO                   | NO                  | AUTOS | INSTALACION |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS41 PRUEBAS41 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch25
  Scenario: Test Usuario 25 - AMAZONAS - ARARA - AUTOS - MANTENIMIENTO PREVENTIVO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio                   |
      | AMAZONAS              | ARARA              | NO                   | NO                  | AUTOS | MANTENIMIENTO PREVENTIVO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS42 PRUEBAS42 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor
  @batch26
  Scenario: Test Usuario 26 - PUTUMAYO - MOCOA - HOGARES - ATENCION VIRTUAL HOGAR
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                  |
      | PUTUMAYO              | MOCOA              | NO                   | NO                  | HOGARES | ATENCION VIRTUAL HOGAR    |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS43 PRUEBAS43 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch27
  Scenario: Test Usuario 27 - ANTIOQUIA - ENVIGADO - HOGARES - ABOGADO EN SITIO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio         |
      | ANTIOQUIA             | ENVIGADO           | NO                   | NO                  | HOGARES | ABOGADO EN SITIO |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS44 PRUEBAS44 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch28
  Scenario: Test Usuario 28 - ANTIOQUIA - ENVIGADO - HOGARES - ELECTRICISTA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio    |
      | ANTIOQUIA                | ENVIGADO             | NO                   | NO                  | HOGARES | ELECTRICISTA |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS45 PRUEBAS45 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch29
  Scenario: Test Usuario 29 - VALLE DEL CAUCA - CACHIMBAL - HOGARES - PLOMERO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio |
      | VALLE DEL CAUCA       | CACHIMBAL          | NO                   | NO                  | HOGARES | PLOMERO  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS46 PRUEBAS46 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch30
  Scenario: Test Usuario 30 - ATLANTICO - AGUADA DE PABLO - HOGARES - CERRAJERO HO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio    |
      | ATLANTICO             | AGUADA DE PABLO    | NO                   | NO                  | HOGARES | CERRAJERO HO |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS47 PRUEBAS47 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch31
  Scenario: Test Usuario 31 - CUNDINAMARCA - ZIPAQUIRA - HOGARES - VIDRIERO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio |
      | CUNDINAMARCA          | ZIPAQUIRA          | NO                   | NO                  | HOGARES | VIDRIERO |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS48 PRUEBAS48 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch32
  Scenario: Test Usuario 32 - SANTANORTE DE SANTANDER  - ARBOLEDAS - HOGARES - RETIRO DE ESCOMBROS
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                |
      | NORTE DE SANTANDER | ARBOLEDAS      | NO                   | NO                  | HOGARES | RETIRO DE ESCOMBROS     |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS49 PRUEBAS49 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch33
  Scenario: Test Usuario 33 - NORTE DE SANTANDER - OCAÑA - HOGARES - DESAGUE POR INUNDACION
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                    |
      | NORTE DE SANTANDER    | OCAÑA              | NO                   | NO                  | HOGARES | DESAGUE POR INUNDACION      |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS50 PRUEBAS50 | TOMA SERVICIO |
   And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch34
  Scenario: Test Usuario 34 - MAGDALENA - CIÉNAGA - HOGARES - ASESORIA JURIDICA PRESENCIAL
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                        |
      | MAGDALENA             | CIENAGA            | NO                   | NO                  | HOGARES | ASESORIA JURIDICA PRESENCIAL    |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS40 PRUEBAS40 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch35
  Scenario: Test Usuario 35 - BOLIVAR - TURBACO - HOGARES - ORIENTACION DIGITAL
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio             |
      | BOLIVAR               | TURBACO            | NO                   | NO                  | HOGARES | ORIENTACION DIGITAL  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS41 PRUEBAS41 | TOMA SERVICIO |
   And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch36
  Scenario: Test Usuario 36 - NARIÑO - IPIALES - HOGARES - FACILITADOR VIRTUAL
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio              |
      | NARIÑO                | IPIALES            | NO                   | NO                  | HOGARES | FACILITADOR VIRTUAL   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS42 PRUEBAS42 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch37
  Scenario: Test Usuario 37 - VICHADA - PUERTO CARREÑO - HOGARES - VIGILANTE
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio   |
      | VICHADA               | PUERTO CARREÑO     | NO                   | NO                  | HOGARES | VIGILANTE  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS43 PRUEBAS43 | TOMA SERVICIO |
   And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor
  @batch38
  Scenario: Test Usuario 38 - VAUPES - MITU - HOGARES - VIGILANTE SP
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio     |
      | VAUPES                | MITU               | NO                   | NO                  | HOGARES | VIGILANTE SP |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS44 PRUEBAS44 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch39
  Scenario: Test Usuario 39 - AMAZONAS - ARARA - HOGARES - HOSPEDAJE VIAJERO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio            |
      | AMAZONAS              | ARARA              | NO                   | NO                  | HOGARES | HOSPEDAJE VIAJERO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS45 PRUEBAS45 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor
  @batch40
  Scenario: Test Usuario 40 - PUTUMAYO - MOCOA - HOGARES - TRASLADO DE BIENES
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio            |
      | PUTUMAYO              | MOCOA              | NO                   | NO                  | HOGARES | TRASLADO DE BIENES  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS46 PRUEBAS46 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch41
  Scenario: Test Usuario 41 - ANTIOQUIA - ENVIGADO - HOGARES - SECADO DE ALFOMBRAS
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                 |
      | ANTIOQUIA             | ENVIGADO           | NO                   | NO                  | HOGARES | SECADO DE ALFOMBRAS |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS47 PRUEBAS47 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch42
  Scenario: Test Usuario 42 - ANTIOQUIA - ENVIGADO - HOGARES - SERVICIOS EXEQUIAL
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio              |
      | ANTIOQUIA             | ENVIGADO           | NO                   | NO                  | HOGARES | SERVICIOS EXEQUIAL |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS48 PRUEBAS48 | TOMA SERVICIO |
  And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch43
  Scenario: Test Usuario 43 - VALLE DEL CAUCA - CACHIMBAL - HOGARES - GASTOS DE MUDANZA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio             |
      | VALLE DEL CAUCA       | CACHIMBAL          | NO                   | NO                  | HOGARES | GASTOS DE MUDANZA |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS49 PRUEBAS49 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch44
  Scenario: Test Usuario 44 - ATLANTICO - AGUADA DE PABLO - HOGARES - SEGUIMIENTO A LA REPARACION
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                      |
      | ATLANTICO             | AGUADA DE PABLO    | NO                   | NO                  | HOGARES | SEGUIMIENTO A LA REPARACION |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS50 PRUEBAS50 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch45
  Scenario: Test Usuario 45 - CUNDINAMARCA - ZIPAQUIRA - HOGARES - REVISION Y REDACCION DE CONTRATOS
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                          |
      | CUNDINAMARCA          | ZIPAQUIRA          | NO                   | NO                  | HOGARES | REVISION Y REDACCION DE CONTRATOS |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS40 PRUEBAS40 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch46
  Scenario: Test Usuario 46 - NORTE DE SANTANDER - ARBOLEDAS - HOGARES - ASESORIA PSICOLOGICA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                |
      | NORTE DE SANTANDER | ARBOLEDAS        | NO                   | NO                  | HOGARES | ASESORIA PSICOLOGICA |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS41 PRUEBAS41 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch47
  Scenario: Test Usuario 47 - NORTE DE SANTANDER - OCAÑA - HOGARES - CONSEJERIA FAMILIAR VIRTUAL O TELEFONICO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                              |
      | NORTE DE SANTANDER    | OCAÑA              | NO                   | NO                  | HOGARES | CONSEJERIA FAMILIAR VIRTUAL O TELEFONICO |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS42 PRUEBAS42 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch48
  Scenario: Test Usuario 48 - MAGDALENA - CIENAGA - HOGARES - ORIENTACION JURIDICA TELEFONICA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                       |
      | MAGDALENA             | CIENAGA            | NO                   | NO                  | HOGARES | ORIENTACION JURIDICA TELEFONICA |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS43 PRUEBAS43 | TOMA SERVICIO |
      And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch49
  Scenario: Test Usuario 49 - BOLIVAR - TURBACO - HOGARES - ORIENTACION MEDICA TELEFONICA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio                      |
      | BOLIVAR               | TURBACO            | NO                   | NO                  | HOGARES | ORIENTACION MEDICA TELEFONICA |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS44 PRUEBAS44 | TOMA SERVICIO |
     And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

  @batch50
  Scenario: Test Usuario 50 - NARIÑO - IPIALES - HOGARES - PLAN DE ACCION
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea  | servicio        |
      | NARIÑO                | IPIALES            | NO                   | NO                  | HOGARES | PLAN DE ACCION |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PRUEBAS45 PRUEBAS45 | TOMA SERVICIO |
    And transicionamos los estados del caso hasta concluido
    And cerramos sesion del usuario
    And reingresamos como el proveedor asignado
    And buscamos el expediente guardado y abrimos su edicion
    And gestionamos los conceptos del proveedor

