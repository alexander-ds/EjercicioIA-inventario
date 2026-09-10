# ADR-001: Almacenamiento del JWT en inventory-front

## Estado

Aceptado.

## Fecha

2026-09-08

## Contexto

`inventory-front` recibe un JWT del `auth-service` tras un login exitoso.

El JWT debe persistirse en el cliente para:

* Mantener la sesión entre recargas de página.
* Adjuntar el header `Authorization: Bearer <JWT>` a las peticiones del `inventory-service`.

## Decisión

El JWT se almacena en `localStorage` bajo la clave `inventory.auth.token`.

El `user` mostrado en la UI se deriva de decodificar el payload del JWT en el
cliente. Es información de presentación; la seguridad nunca depende de ella.

## Motivación

* `localStorage` es síncrono y simple, adecuado para la aplicación actual.
* Los servicios exponen CORS abierto y no hay infraestructura de cookies
  (`HttpOnly`, `Secure`, `SameSite`) contratada todavía entre los servicios.
* No se requieren dependencias nuevas.

## Riesgos

* `localStorage` es accesible desde JavaScript: si hay XSS, el token puede
  exfiltrarse (igual que cualquier dato en el bundle).
* Un JWT stateless sigue siendo válido hasta su expiración aunque se elimine
  del cliente. La revocación inmediata requiere mecanismos adicionales.

## Alternativas consideradas

* **Cookies `HttpOnly`**: más seguro ante XSS, pero requiere cambios de
  arquitectura/contrato (CSRF, SameSite, CORS con credenciales) que aún no
  existen en el sistema.

## Migración futura

Si se adopta un modelo de cookies o refresh tokens, este ADR debe actualizarse
y el cambio debe reflejarse en `docs/authentication.md`.