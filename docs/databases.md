# Database Structure

## 1. Principios

La estructura de bases de datos sigue los límites de responsabilidad definidos en la arquitectura.

```text
auth-service
    │
    ▼
auth_db

inventory-service
    │
    ▼
inventory_db
```

Cada servicio es propietario de su propia base de datos.

No se comparten tablas ni se utilizan Foreign Keys entre bases de datos.

---

# 2. Auth DB

La `auth_db` pertenece exclusivamente a `auth-service`.

Su responsabilidad es gestionar:

* Usuarios.
* Credenciales.
* Roles.
* Permisos.
* Relación entre usuarios y roles.
* Relación entre roles y permisos.
* Sesiones / refresh tokens.

```text
auth_db
│
├── users
│
├── roles
│
├── permissions
│
├── user_roles
│
├── role_permissions
│
└── refresh_tokens
```

## 2.1 users

```text
users
├── id                  UUID PK
├── email               VARCHAR UNIQUE
├── password_hash       VARCHAR
├── name                VARCHAR
├── active              BOOLEAN
├── email_verified      BOOLEAN
├── last_login_at       TIMESTAMP
├── created_at          TIMESTAMP
└── updated_at          TIMESTAMP
```

Responsabilidad:

Identidad y credenciales del usuario.

El `password_hash` contiene únicamente el hash de la contraseña.

La contraseña nunca se almacena en texto plano.

---

## 2.2 roles

```text
roles
├── id                  UUID PK
├── code                VARCHAR UNIQUE
├── name                VARCHAR
├── description         VARCHAR
├── active              BOOLEAN
└── created_at          TIMESTAMP
```

Ejemplos:

```text
USER
ADMIN
MANAGER
```

Los roles pertenecen al dominio de autenticación/autorización.

---

## 2.3 permissions

```text
permissions
├── id                  UUID PK
├── code                VARCHAR UNIQUE
├── name                VARCHAR
├── description         VARCHAR
├── active              BOOLEAN
└── created_at          TIMESTAMP
```

Ejemplos:

```text
PRODUCT_READ
PRODUCT_CREATE
PRODUCT_UPDATE
PRODUCT_DELETE

INVENTORY_READ
INVENTORY_ADJUST

MOVEMENT_READ
MOVEMENT_CREATE

WAREHOUSE_READ
WAREHOUSE_CREATE
WAREHOUSE_UPDATE
```

Los permisos permiten evolucionar de un sistema basado únicamente en roles hacia un modelo RBAC.

---

## 2.4 user_roles

Relación N:M entre usuarios y roles.

```text
user_roles
├── user_id             UUID FK → users.id
├── role_id             UUID FK → roles.id
└── created_at          TIMESTAMP
```

Relación:

```text
users
   │
   │ N:M
   ▼
user_roles
   │
   ▼
roles
```

Un usuario puede tener uno o varios roles.

---

## 2.5 role_permissions

Relación N:M entre roles y permisos.

```text
role_permissions
├── role_id             UUID FK → roles.id
└── permission_id       UUID FK → permissions.id
```

Relación:

```text
roles
   │
   │ N:M
   ▼
role_permissions
   │
   ▼
permissions
```

---

## 2.6 refresh_tokens

Opcional si el sistema implementa refresh tokens.

```text
refresh_tokens
├── id                  UUID PK
├── user_id             UUID FK → users.id
├── token_hash          VARCHAR
├── expires_at           TIMESTAMP
├── revoked_at           TIMESTAMP
└── created_at            TIMESTAMP
```

El token debe almacenarse de forma segura.

---

# 3. Auth DB - Relaciones

```text
                    ┌──────────────┐
                    │    users     │
                    └──────┬───────┘
                           │
                           │ N:M
                           ▼
                    ┌──────────────┐
                    │  user_roles  │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    roles     │
                    └──────┬───────┘
                           │
                           │ N:M
                           ▼
                 ┌────────────────────┐
                 │  role_permissions  │
                 └─────────┬──────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ permissions  │
                    └──────────────┘


                    ┌──────────────┐
                    │    users     │
                    └──────┬───────┘
                           │
                           │ 1:N
                           ▼
                    ┌────────────────┐
                    │ refresh_tokens │
                    └────────────────┘
```

---

# 4. Inventory DB

La `inventory_db` pertenece exclusivamente a `inventory-service`.

Su responsabilidad es gestionar la información de negocio relacionada con inventario.

```text
inventory_db
│
├── warehouses
│
├── categories
│
├── suppliers
│
├── products
│
├── inventory
│
├── movements
│
├── transfers
│
└── transfer_details
```

---

# 5. warehouses

Representa los almacenes físicos o lógicos del sistema.

```text
warehouses
├── id                  UUID PK
├── code                VARCHAR UNIQUE
├── name                VARCHAR
├── description         TEXT
├── address             TEXT
├── active              BOOLEAN
├── created_at          TIMESTAMP
└── updated_at          TIMESTAMP
```

Ejemplo:

```text
WH-001 → Principal
WH-002 → Norte
WH-003 → Sur
```

Los almacenes pertenecen a `inventory-service`, no a `auth-service`.

---

# 6. categories

```text
categories
├── id                  UUID PK
├── name                VARCHAR UNIQUE
├── description         TEXT
├── active              BOOLEAN
└── created_at          TIMESTAMP
```

---

# 7. suppliers

```text
suppliers
├── id                  UUID PK
├── name                VARCHAR
├── identification      VARCHAR
├── phone               VARCHAR
├── email               VARCHAR
├── address             TEXT
├── active              BOOLEAN
└── created_at          TIMESTAMP
```

---

# 8. products

```text
products
├── id                  UUID PK
├── sku                 VARCHAR UNIQUE
├── barcode             VARCHAR UNIQUE
├── name                VARCHAR
├── description         TEXT
├── category_id         UUID FK → categories.id
├── supplier_id         UUID FK → suppliers.id
├── purchase_price      NUMERIC
├── sale_price          NUMERIC
├── unit                VARCHAR
├── active              BOOLEAN
├── created_at          TIMESTAMP
└── updated_at          TIMESTAMP
```

Relaciones:

```text
categories
      │
      │ 1:N
      ▼
   products
      ▲
      │ 1:N
      │
  suppliers
```

---

# 9. inventory

El stock se define por combinación de producto y almacén.

```text
inventory
├── product_id          UUID PK/FK → products.id
├── warehouse_id        UUID PK/FK → warehouses.id
├── quantity            NUMERIC
├── minimum_stock       NUMERIC
├── maximum_stock       NUMERIC
└── updated_at          TIMESTAMP
```

La clave primaria será:

```text
(product_id, warehouse_id)
```

Esto permite:

```text
                     Principal     Norte       Sur

Laptop                   50          20         10
Mouse                   100          35         25
Keyboard                 30          15          8
```

Los niveles mínimo y máximo pueden ser diferentes para cada almacén.

---

# 10. movements

Registra las operaciones que modifican el inventario.

```text
movements
├── id                  UUID PK
├── product_id          UUID FK → products.id
├── warehouse_id        UUID FK → warehouses.id
├── user_id             UUID
├── type                VARCHAR
├── quantity            NUMERIC
├── previous_quantity   NUMERIC
├── new_quantity        NUMERIC
├── reference           VARCHAR
├── observation         TEXT
└── created_at          TIMESTAMP
```

Tipos de movimiento:

```text
ENTRY
EXIT
ADJUSTMENT
TRANSFER
```

### user_id

`user_id` representa el `users.id` de `auth_db`.

No se crea una Foreign Key porque pertenece a otra base de datos.

La asociación es lógica:

```text
auth_db.users.id
       │
       │ UUID
       ▼
inventory_db.movements.user_id
```

---

# 11. transfers

Representa una transferencia entre almacenes.

```text
transfers
├── id                       UUID PK
├── origin_warehouse_id      UUID FK → warehouses.id
├── destination_warehouse_id UUID FK → warehouses.id
├── user_id                  UUID
├── status                   VARCHAR
├── observation              TEXT
├── created_at               TIMESTAMP
└── updated_at               TIMESTAMP
```

Estados:

```text
PENDING
SENT
RECEIVED
CANCELLED
```

`origin_warehouse_id` y `destination_warehouse_id` deben ser diferentes.

---

# 12. transfer_details

Detalle de los productos incluidos en una transferencia.

```text
transfer_details
├── id                  UUID PK
├── transfer_id         UUID FK → transfers.id
├── product_id          UUID FK → products.id
└── quantity            NUMERIC
```

Relación:

```text
transfers
     │
     │ 1:N
     ▼
transfer_details
     │
     │ N:1
     ▼
products
```

Una transferencia puede contener múltiples productos.

---

# 13. Inventory DB - Relaciones

```text
                              ┌──────────────┐
                              │   categories │
                              └──────┬───────┘
                                     │
                                     │ 1:N
                                     ▼
┌──────────────┐              ┌──────────────┐
│  suppliers   │─────────────►│   products   │
└──────────────┘      1:N     └──────┬───────┘
                                     │
                              ┌──────┴──────┐
                              │             │
                             1:N           1:N
                              │             │
                              ▼             ▼
                       ┌────────────┐ ┌──────────────┐
                       │ inventory  │ │   movements  │
                       └──────┬─────┘ └──────────────┘
                              │
                              │ N:1
                              ▼
                       ┌──────────────┐
                       │  warehouses  │
                       └──────┬───────┘
                              │
                              │
                 ┌────────────┴────────────┐
                 │                         │
                 ▼                         ▼
          origin_warehouse          destination_warehouse
                 │                         │
                 └──────────┬──────────────┘
                            ▼
                       transfers
                            │
                            │ 1:N
                            ▼
                    transfer_details
                            │
                            │ N:1
                            ▼
                        products
```

---

# 14. Relación entre Auth DB e Inventory DB

Las bases permanecen independientes.

```text
                    AUTH DB
               ┌────────────────┐
               │     users      │
               │                │
               │ id             │
               └───────┬────────┘
                       │
                       │ UUID
                       │
                       │ referencia lógica
                       │
               ┌───────▼────────────────┐
               │     INVENTORY DB       │
               │                        │
               │ movements.user_id      │
               │ transfers.user_id      │
               │                        │
               └────────────────────────┘
```

No existen:

```text
Foreign Keys cross-database
Shared tables
Shared ORM entities
Direct database access entre servicios
```

Cada servicio utiliza exclusivamente su propia base de datos.

---

# 15. Responsabilidad de cada base

```text
┌─────────────────────────────┐
│           AUTH DB           │
├─────────────────────────────┤
│ users                       │
│ roles                       │
│ permissions                 │
│ user_roles                  │
│ role_permissions            │
│ refresh_tokens              │
└─────────────────────────────┘

             │
             │ JWT
             ▼

┌─────────────────────────────┐
│        INVENTORY DB         │
├─────────────────────────────┤
│ warehouses                  │
│ categories                  │
│ suppliers                   │
│ products                    │
│ inventory                   │
│ movements                   │
│ transfers                   │
│ transfer_details            │
└─────────────────────────────┘
```

---

# 16. Flujo de autorización

```text
inventory-front
  │
  │ JWT
  ▼
inventory-service
  │
  ▼
Spring Security
  │
  ├── valida JWT
  │
  ├── obtiene user_id
  │
  ├── obtiene roles/authorities
  │
  ├── valida permisos
  │
  └── ejecuta operación
          │
          ▼
     inventory_db
```

El `inventory-service` es responsable de decidir si el usuario puede realizar una operación.

El `auth-service` es responsable de autenticar al usuario y emitir el JWT.

---

# 17. Multi-almacén

Los almacenes pertenecen exclusivamente a `inventory-service`.

Por tanto:

```text
Auth DB
└── users
    └── id


Inventory DB
└── warehouses
    └── id
```

La asociación de un usuario con uno o varios almacenes **no forma parte de la identidad del usuario**.

Si posteriormente el negocio requiere restricciones del tipo:

```text
USER A → puede operar en WH-001
USER A → puede operar en WH-002

USER B → solo puede operar en WH-002
```

esa autorización puede modelarse dentro del dominio de inventario, por ejemplo:

```text
inventory_db

user_warehouses
├── user_id
├── warehouse_id
├── is_default
├── active
└── created_at
```

De esta forma la relación pertenece al dominio que conoce el concepto de `warehouse`.

---

# 18. Estructura final

```text
                         AUTH SERVICE
                              │
                              ▼
                         ┌─────────┐
                         │ Auth DB │
                         ├─────────┤
                         │ users   │
                         │ roles   │
                         │ perms   │
                         │ user_roles
                         │ role_perms
                         │ refresh │
                         └─────────┘


                         INVENTORY SERVICE
                              │
                              ▼
                      ┌────────────────┐
                      │ Inventory DB   │
                      ├────────────────┤
                      │ warehouses     │
                      │ categories     │
                      │ suppliers      │
                      │ products       │
                      │ inventory      │
                      │ movements      │
                      │ transfers      │
                      │ transfer_details│
                      └────────────────┘
```

## Regla principal

```text
Auth DB
    → ¿Quién es el usuario?
    → ¿Qué roles tiene?
    → ¿Qué permisos tiene?

Inventory DB
    → ¿Qué almacenes existen?
    → ¿Qué productos existen?
    → ¿Cuánto stock hay?
    → ¿Qué movimientos se realizaron?
    → ¿Qué transferencias existen?
```

Esta separación mantiene alineada la estructura de datos con la arquitectura de servicios.
