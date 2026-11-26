# EjercicioIA - Inventory

Proyecto de práctica que implementa un sistema de inventario distribuido con autenticación propia basada en JWT.

## Servicios

| Módulo | Descripción | Repositorio |
|---|---|---|
| `auth-service` | Microservicio de autenticación (Node.js): login, users, roles, permisos y generación de JWT | https://github.com/alexander-ds/auth-service |
| `inventory-service` | API principal (Spring Boot): lógica de negocio, inventario, autorización y validación del JWT | https://github.com/alexander-ds/inventory-service |
| `inventory-service-go/` | Implementación alternativa en Go de la API de inventario (mismo repositorio) | — |
| `inventory-front` | Aplicación web (React): interfaz de usuario, login/logout y consumo de APIs | https://github.com/alexander-ds/inventory-front |

> `inventory-service` e `inventory-service-go` son mutuamente excluyentes: solo uno está activo contra `inventory_db`. Ver ADR-002.

## Estructura del repositorio

```text
├── auth-service/       # Autenticación (Node.js)
├── inventory-service/  # API de negocio (Spring Boot)
├── inventory-service-go/  # API de negocio (Go, alternativa a la anterior)
├── inventory-front/    # Frontend (React)
├── docs/               # Documentación arquitectónica, contratos y ADRs
└── DDBB/               # Scripts SQL de las bases de datos
```

## Bases de datos

* `auth_db` — usuarios, roles, permisos y refresh tokens. Owner: `auth-service`.
* `inventory_db` — almacenes, categorías, proveedores, productos e inventario. Owner: servicio de inventario activo (`inventory-service` o `inventory-service-go`).

Los scripts de creación e inserts de ejemplo están en la carpeta `DDBB/`.

## Documentación

* `docs/architecture.md` — arquitectura general.
* `docs/authentication.md` — flujo de autenticación y JWT.
* `docs/api-contract.md` — contratos HTTP de autenticación e inventario.
* `docs/databases.md` — estructura de bases de datos.
* `docs/decisions/` — ADRs (decisiones de arquitectura), incluye ADR-002 (servicio de inventario en Go).

## Estándares

Antes de trabajar en el código, leer `AGENTS.md` de la raíz y el `AGENTS.md` del módulo afectado.