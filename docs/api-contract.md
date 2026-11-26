# API Contract

## 1. Objetivo

Este documento describe los contratos HTTP del sistema. Es la referencia común
para `auth-service`, `inventory-front` y el servicio de inventario activo
(`inventory-service` o `inventory-service-go`, ver ADR-002).

## 2. Autenticación — `auth-service`

Base URL por defecto: `http://localhost:3000`.

### POST /auth/register

```json
{
  "email": "nuevo@inventory.local",
  "name": "Nuevo",
  "password": "123456"
}
```

Respuesta `201`:

```json
{ "id": "uuid", "email": "nuevo@inventory.local" }
```

Errores: `400` payload inválido, `409` email duplicado.

### POST /auth/login

```json
{ "email": "admin@inventory.local", "password": "123456" }
```

Respuesta `201`:

```json
{ "access_token": "<JWT>" }
```

Errores: `400` payload inválido, `401` credenciales incorrectas.

### JWT

* Algoritmo: `HS256`, secreto configurado en `JWT_SECRET`.
* Claims actuales: `sub` (id de usuario), `email`, `name` (opcional), `iat`, `exp`.
* Expiración: 1 hora (3600 segundos).
* No hay claims de `roles` ni `permissions`: son decisión futura.
* El token viaja solo en `Authorization: Bearer <JWT>`.

## 3. Inventario — servicio activo

Base URL por defecto: `http://localhost:8080`.
Implementaciones: `inventory-service` (Spring Boot) o `inventory-service-go` (Go).
**Solo una activa a la vez.** Toda petición excepto `/health` requiere JWT válido.

La implementación Go publica además su especificación OpenAPI en
`GET /openapi.json` y Swagger UI en `GET /docs` (ambas públicas).

### 3.1 Respuestas de error

```json
{ "statusCode": 401, "message": "Unauthorized" }
```

| Código | Significado |
|---|---|
| `400` | Payload o parámetros inválidos |
| `401` | Sin token, token inválido o expirado |
| `403` | Autenticado sin permiso sobre el recurso |
| `404` | Recurso no encontrado |
| `409` | Conflicto (SKU duplicado, stock insuficiente, etc.) |

La autorización real siempre ocurre en el servicio de inventario. El frontend
puede ocultar acciones por UX, pero eso no sustituye la comprobación del servidor.

### 3.2 Health

```http
GET /health
```

Respuesta `200`:

```json
{ "status": "ok", "service": "inventory-service" }
```

El servicio Go devuelve `"service": "inventory-service-go"`.

### 3.3 Productos

```http
GET    /api/products
GET    /api/products/{id}
POST   /api/products
PUT    /api/products/{id}
DELETE /api/products/{id}
```

Payload de producto:

```json
{
  "sku": "LAP-001",
  "barcode": "7790000000012",
  "name": "Laptop",
  "description": "Laptop 14 pulgadas",
  "categoryId": "uuid",
  "supplierId": "uuid",
  "purchasePrice": 900.00,
  "salePrice": 1200.00,
  "unit": "UND",
  "active": true
}
```

`POST` responde `201` con el producto creado (incluye `id`). `PUT` responde `200`.
`DELETE` responde `204`.

### 3.4 Almacenes, categorías y proveedores

```http
GET  /api/warehouses
POST /api/warehouses
GET  /api/categories
POST /api/categories
GET  /api/suppliers
POST /api/suppliers
```

Los campos y tipos se derivan de `docs/databases.md` y `DDBB/inventory.sql`.

### 3.5 Inventario

```http
GET /api/inventory?warehouseId=<uuid>
PUT /api/inventory/{productId}/{warehouseId}
```

Payload:

```json
{
  "quantity": 50,
  "minimumStock": 10,
  "maximumStock": 100
}
```

La clave de inventario es `(product_id, warehouse_id)`.

### 3.6 Movimientos y transferencias

```http
GET  /api/movements
POST /api/movements
GET  /api/transfers
POST /api/transfers
```

Tipos de movimiento: `ENTRY`, `EXIT`, `ADJUSTMENT`, `TRANSFER`.
Estados de transferencia: `PENDING`, `SENT`, `RECEIVED`, `CANCELLED`.
`user_id` se obtiene del claim `sub` del JWT y se persiste como referencia
lógica a `auth_db.users.id` (sin foreign key entre bases).

Payload de movimiento:

```json
{
  "productId": "uuid",
  "warehouseId": "uuid",
  "type": "ENTRY",
  "quantity": 10,
  "reference": "OC-001",
  "observation": "Compra"
}
```

`POST /api/movements` modifica el stock en la misma transacción: `ENTRY` suma,
`EXIT` y `TRANSFER` descuentan, `ADJUSTMENT` fija la cantidad. Un descuento sin
stock suficiente responde `409`.

Payload de transferencia:

```json
{
  "originWarehouseId": "uuid",
  "destinationWarehouseId": "uuid",
  "observation": "Traslado entre almacenes",
  "details": [
    { "productId": "uuid", "quantity": 5 }
  ]
}
```

`POST /api/transfers` crea la transferencia en `PENDING`. Valida que los
almacenes sean distintos, que no se repita `productId` en `details` y que haya
stock suficiente en el origen. El contrato actual no incluye un endpoint para
cambiar el estado, por lo que la creación no modifica el stock.

### 3.7 Payloads de catálogos e inventario

```json
// POST /api/warehouses
{ "code": "WH-003", "name": "Sur", "description": "...", "address": "...", "active": true }

// POST /api/categories
{ "name": "Teclados", "description": "...", "active": true }

// POST /api/suppliers
{ "name": "Proveedor", "identification": "900...", "phone": "...", "email": "...", "address": "...", "active": true }
```

`active` es opcional y por defecto `true`. `GET /api/inventory` acepta el filtro
opcional `warehouseId=<uuid>`; `PUT /api/inventory/{productId}/{warehouseId}`
usa:

```json
{ "quantity": 50, "minimumStock": 10, "maximumStock": 100 }
```

## 4. Compatibilidad entre implementaciones

Ambas implementaciones deben:

* Validar firma, algoritmo y expiración del JWT.
* Responder `401` / `403` según `docs/authentication.md`.
* Usar el mismo esquema de `inventory_db` (`DDBB/inventory.sql`).
* No inventar claims ni endurecer/relajar el contrato del token.
