# AGENTS.md

## 1. Propósito

Este repositorio contiene una aplicación distribuida compuesta por:

* `auth-service/`: microservicio de autenticación desarrollado en Node.js.
* `inventory-service/`: API principal desarrollada en Spring Boot.
* `inventory-front/`: aplicación web desarrollada en React.
* `docs/`: documentación arquitectónica, contratos, decisiones y estándares del proyecto.

## 2. Arquitectura

> Nota terminológica: dónde se diga `backend` se refiere a `inventory-service`; dónde se diga `frontend` se refiere a `inventory-front`.

```text
                         ┌────────────────────┐
                         │  inventory-front   │
                         │       React        │
                         └────────┬───────────┘
                                  │
                     login        │       API + JWT
                                  │
                                  ▼
                         ┌──────────────────┐
                         │   Auth Service   │
                         │     Node.js      │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │    PostgreSQL    │
                         │  Authentication  │
                         └──────────────────┘

                                  │
                                  │ JWT
                                  ▼

                         ┌────────────────────┐
                         │  inventory-service │
                         │    Spring Boot    │
                         └────────┬───────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │ Business Database│
                         └──────────────────┘
```

## 3. Responsabilidades

### Auth Service

Responsable de:

* Autenticación.
* Usuarios.
* Credenciales.
* Password hashing.
* Login.
* Generación de JWT.
* Futura gestión de roles.

No debe implementar lógica de negocio.

### inventory-service

Responsable de:

* APIs REST.
* Lógica de negocio.
* Persistencia de negocio.
* Autorización.
* Validación del JWT.
* Reglas de acceso.
* Roles y permisos cuando se implementen.

No debe duplicar el login del `auth-service`.

### inventory-front

Responsable de:

* UI.
* Navegación.
* Formularios.
* Login.
* Logout.
* Estado de sesión.
* Consumo de APIs.
* Protección de rutas a nivel UX.

El frontend nunca es la autoridad de seguridad.

## 4. Orden de lectura para OpenCode

Antes de realizar cambios:

1. Leer este `AGENTS.md`.
2. Leer el `AGENTS.md` del módulo afectado.
3. Revisar la documentación relacionada.
4. Revisar los ADR aplicables.
5. Inspeccionar el código existente.
6. Evitar asumir que una implementación futura ya existe.

## 5. Regla fundamental

No duplicar responsabilidades.

```text
¿Es autenticación?
        ↓
   auth-service

¿Es negocio o autorización?
        ↓
 inventory-service

¿Es presentación?
        ↓
 inventory-front
```

## 6. Cambios arquitectónicos

No realizar cambios arquitectónicos importantes sin actualizar la documentación correspondiente.

Cambios que requieren especial atención:

* JWT.
* Claims.
* Roles.
* Permisos.
* Endpoints.
* Contratos entre servicios.
* Bases de datos.
* Seguridad.
* Límites entre servicios.

## 7. Seguridad

Nunca:

* Commitear secretos.
* Hardcodear passwords.
* Hardcodear JWT secrets.
* Loguear passwords.
* Loguear JWT completos.
* Desactivar seguridad para solucionar problemas.
* Confiar en el frontend para autorización.

## 8. Configuración

Los valores dependientes del entorno deben configurarse externamente.

Ejemplos:

```text
DATABASE_URL
JWT_SECRET
JWT_ISSUER
JWT_AUDIENCE
API_URL
AUTH_SERVICE_URL
```

Los nombres reales deben respetar la implementación del proyecto.

## 9. Principio de mínimo cambio

Cuando OpenCode modifique código:

* Cambiar únicamente lo necesario.
* Reutilizar código existente.
* No introducir dependencias innecesarias.
* No reorganizar todo el proyecto sin necesidad.
* Mantener compatibilidad con los contratos existentes.

## 10. Regla antes de implementar

Antes de escribir código, responder:

1. ¿Qué componente es responsable?
2. ¿Existe ya una implementación?
3. ¿Existe documentación?
4. ¿El cambio afecta otro servicio?
5. ¿Necesita actualizarse un ADR?
6. ¿Necesita actualizarse un contrato?
7. ¿Cómo se probará?

## 11. Calidad

Todo cambio relevante debe incluir pruebas apropiadas.

La implementación debe priorizar:

* Claridad.
* Seguridad.
* Mantenibilidad.
* Testabilidad.
* Bajo acoplamiento.
