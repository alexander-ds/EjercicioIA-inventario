# Architecture

## 1. Objetivo

Este documento describe la arquitectura general del sistema y las responsabilidades de cada componente.

## 2. Componentes

> Nota terminológica: dónde se diga `backend` se refiere a `inventory-service`; dónde se diga `frontend` se refiere a `inventory-front`.

### inventory-front

Tecnología:

```text
React
```

Responsabilidad:

* Presentación.
* Interacción con usuario.
* Autenticación desde el punto de vista del cliente.
* Consumo de APIs.

### Auth Service

Tecnología:

```text
Node.js
PostgreSQL
JWT
```

Responsabilidad:

* Autenticar usuarios.
* Validar credenciales.
* Emitir JWT.

### inventory-service

Tecnología:

```text
Java
Spring Boot
Spring Security
```

Responsabilidad:

* Lógica de negocio.
* APIs.
* Autorización.
* Validación de JWT.

## 3. Comunicación

```text
inventory-front
  │
  ├──────────────► Auth Service
  │                  │
  │                  ▼
  │              PostgreSQL
  │
  │
  └──────────────► inventory-service
                     │
                     ▼
               Business Database
```

## 4. Flujo de login

```text
Usuario
   │
   ▼
inventory-front
   │
   │ username/password
   ▼
Auth Service
   │
   │ validar credenciales
   ▼
PostgreSQL
   │
   │ usuario válido
   ▼
Auth Service
   │
   │ genera JWT
   ▼
inventory-front
```

## 5. Request autenticada

```text
inventory-front
   │
   │ Authorization: Bearer JWT
   ▼
inventory-service
   │
   ▼
Spring Security
   │
   ├── JWT inválido → 401
   │
   ├── autenticado pero sin permiso → 403
   │
   └── válido → Controller
```

## 6. Separación de bases de datos

El `auth-service` es propietario de la información de autenticación.

El `inventory-service` es propietario de la información de negocio.

Conceptualmente:

```text
Auth DB
└── users
    ├── id
    ├── username
    └── password_hash

Business DB
└── business tables
```

No se debe asumir que ambos servicios comparten tablas.

## 7. Roles futuros

La arquitectura soportará posteriormente:

```text
User
 └── Roles
      ├── USER
      ├── ADMIN
      └── MANAGER
```

El `auth-service` podrá emitir los roles dentro del JWT.

Spring Security podrá convertirlos en authorities.

El `inventory-service` aplicará la autorización.

## 8. Autenticación vs autorización

Autenticación:

```text
¿Quién eres?
```

Responsable:

```text
auth-service
```

Autorización:

```text
¿Qué puedes hacer?
```

Responsable:

```text
inventory-service
```

## 9. Principios

* Cada servicio tiene una responsabilidad clara.
* No duplicar autenticación.
* No compartir secretos innecesariamente.
* No depender directamente de bases de datos de otros servicios.
* Los contratos entre servicios deben estar documentados.
* Los cambios arquitectónicos deben documentarse mediante ADR.
