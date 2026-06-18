Feature: Creacion de Expedientes en el sistema de gestion de casos
  @batch1
  Scenario: Test 01 - ANTIOQUIA - MEDELLIN - AUTOS -GRUA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio          |
      | ANTIOQUIA             | MEDELLIN           | NO                   | NO                  | AUTOS | GRUA  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

  @batch2
  Scenario: Test  02 - BOGOTA - BOGOTA - AUTOS - DESPLAZAMIENTO POR INMOVILIZACION DEL VH
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio         |
      | BOGOTA D.C.                | BOGOTA D.C.             | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR INMOVILIZACION DEL VH|
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

  @batch3
  Scenario: Test  03 - ANTIOQUIA - MEDELLIN - CONDUCTOR ELEGIDO 
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio         |
      | ANTIOQUIA     | MEDELLIN          | NO                   | NO                  | CONDUCTOR ELEGIDO | CONDUCTOR ELEGIDO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

  @batch4
  Scenario: Test  04 - ANTIOQUIA - DESPLAZAMIENTO POR INMOVILIZACION DEL VH
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio |
      | ANTIOQUIA             | MEDELLIN            | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR INMOVILIZACION DEL VH   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

  @batch5
  Scenario: Test  05 - BOGOTA D.C. - BOGOTA D.C. - AUTOS - AMBULANCIA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio     |
      | BOGOTA D.C.          | BOGOTA D.C.             | NO                   | NO                  | AUTOS | CONDUCTOR ELEGIDO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

  @batch6
  Scenario: Test  06 - BOGOTA D.C. - BOGOTA D.C. - AUTOS - GRUA
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio |
      | BOGOTA D.C.            | BOGOTA D.C.      | NO                   | NO                  | AUTOS | GRUA     |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

  @batch7
  Scenario: Test  07 - BOGOTA D.C. - BOGOTA D.C. - AUTOS - CONDUCTOR ELEGIDO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
      | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio        |
      | BOGOTA D.C.          | BOGOTA D.C.       | NO                   | NO                  | AUTOS | CONDUCTOR ELEGIDO  |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

  @batch8
  Scenario: Test  08 - ANTIOQUIA - MEDELLIN - CONDUCTOR ELEGIDO - CONDUCTOR ELEGIDO
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
           | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio         |
      | ANTIOQUIA     | MEDELLIN          | NO                   | NO                  | CONDUCTOR ELEGIDO | CONDUCTOR ELEGIDO   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

  @batch9
  Scenario: Test 09 - ANTIOQUIA - MEDELLIN - AUTOS - DESPLAZAMIENTO POR INMOVILIZACION DEL VH 
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
    | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio |
      | ANTIOQUIA             | MEDELLIN            | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR INMOVILIZACION DEL VH   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"


  @batch10
  Scenario: Test 10 - ANTIOQUIA - MEDELLIN - AUTOS - DESPLAZAMIENTO POR INMOVILIZACION DEL VH 
    Given el actor tiene un navegador disponible
    When abre la pagina de casos
    And realiza login con credenciales
    And navega a agent
    And diligencia caso express completo desde feature
    | departamento_solicita | municipio_solicita | servicios_especiales | gestor_coordinacion | linea | servicio |
      | ANTIOQUIA             | MEDELLIN            | NO                   | NO                  | AUTOS | DESPLAZAMIENTO POR INMOVILIZACION DEL VH   |
    And diligenciamos el proveedor
      | Nombre del proveedor | Servicio      |
      | PROVEEDOR PRUEBA     | TOMA SERVICIO |
    And transicionamos los estados del caso
    And Se valida que quede en estado "Abierto"

