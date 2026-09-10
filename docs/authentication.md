# Authentication

## 1. Estado actual

El sistema utiliza un microservicio Node.js para autenticación.

Actualmente el usuario se identifica mediante:

```text
username
password
```

El servicio consulta PostgreSQL y, si las credenciales son correctas, genera un JWT.

## 2. Flujo

```text
inventory-front
  │
  │ username/password
  ▼
Auth Service
  │
  ▼
PostgreSQL
  │
  │ valid
  ▼
JWT
  │
  ▼
inventory-front
  │
  │ Bearer JWT
  ▼
inventory-service
```

## 3. JWT

El JWT representa la identidad autenticada.

Ejemplo conceptual:

```json
{
  "sub": "123",
  "email": "juan@example.com",
  "name": "Juan",
  "iat": 1700000000,
  "exp": 1700003600
}
```

`name` solo se incluye si el usuario lo tiene registrado; es un claim opcional.

Este ejemplo es ilustrativo.

El contrato real debe obtenerse del `auth-service`.

## 4. Validaciones del inventory-service

Spring Security debe validar:

* Firma.
* Algoritmo.
* Expiración.
* Issuer, si existe.
* Audience, si existe.
* Claims necesarios.

Nunca considerar suficiente que el token tenga una estructura JWT válida.

## 5. Authorization Header

Las peticiones protegidas utilizarán:

```http
Authorization: Bearer <JWT>
```

No utilizar tokens en query parameters.

## 6. Respuestas HTTP

### 401 Unauthorized

Utilizar cuando:

* No existe token.
* Token inválido.
* Token expirado.
* Firma inválida.

### 403 Forbidden

Utilizar cuando:

* El usuario está autenticado.
* El usuario no tiene autorización para el recurso.

## 7. Roles futuros

El sistema está diseñado para soportar roles.

Ejemplo:

```json
{
  "sub": "123",
  "username": "juan",
  "roles": [
    "USER",
    "ADMIN"
  ],
  "iat": 1700000000,
  "exp": 1700003600
}
```

El claim `roles` todavía debe considerarse una decisión futura hasta que se implemente oficialmente.

## 8. Reglas para roles

Cuando se implementen:

```text
Auth Service
      │
      │ JWT + roles
      ▼
Spring Security
      │
      ▼
Authorization
```

inventory-front puede utilizar los roles para UX, pero no para seguridad.

Ejemplo:

```text
inventory-front:
ADMIN → muestra botón "Eliminar usuario"

inventory-service:
ADMIN → permite DELETE
USER  → 403
```

## 9. Almacenamiento

Debe evaluarse cuidadosamente el almacenamiento del token.

Cuando la arquitectura lo permita, considerar cookies:

```text
HttpOnly
Secure
SameSite
```

Si se utiliza `localStorage`, documentar explícitamente la decisión y sus riesgos.

## 10. Logout

Eliminar el token del cliente evita nuevas peticiones desde ese cliente.

Sin embargo, un JWT stateless puede continuar siendo válido hasta su expiración.

La revocación inmediata requeriría mecanismos adicionales.

## 11. Secretos

Nunca almacenar:

```text
JWT_SECRET
passwords
private keys
```

en código fuente.

Utilizar variables de entorno o mecanismos equivalentes.

## 12. Regla para OpenCode

Antes de implementar JWT en Spring Boot:

1. Inspeccionar el JWT real.
2. Identificar algoritmo.
3. Identificar claims.
4. Identificar expiración.
5. Identificar issuer.
6. Identificar audience.
7. Revisar el código Node.
8. Implementar compatibilidad.

No inventar el contrato.
