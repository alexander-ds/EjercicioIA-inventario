# ADR-002: Servicio de inventario en Go como reemplazo de inventory-service

## Estado

Aceptado.

## Fecha

2026-11-25

## Contexto

El proyecto quiere contar con una implementación del servicio de inventario en Go,
como módulo `inventory-service-go/` dentro de este mismo repositorio. La base de
datos de negocio ya existe (`inventory_db`, scripts en `DDBB/`) y se desea
reutilizarla.

La documentación vigente (`docs/architecture.md` y `docs/databases.md`) establece
que `inventory-service` es el único propietario de `inventory_db` y que los
servicios no comparten tablas. Por tanto, no es aceptable que Spring Boot y Go
escriban simultáneamente las mismas tablas: se duplicarían las reglas de negocio
(stock, movimientos, transferencias) y se perdería la garantía de integridad.

El usuario ha decidido que se utilizará **uno u otro servicio, nunca ambos a la
vez**. `auth-service` permanece como único emisor de JWT.

## Decisión

1. `inventory-service-go` es una implementación alternativa de `inventory-service`.
2. En un momento dado, **solo un servicio de inventario está activo** y es el
   propietario de `inventory_db`:
   - `inventory-service` (Spring Boot), o
   - `inventory-service-go` (Go).
3. El contrato HTTP es el descrito en `docs/api-contract.md`. El servicio Go debe
   implementar el mismo contrato que el servicio Spring Boot.
4. El servicio Go valida el JWT emitido por `auth-service` con el mismo algoritmo
   y secreto (`HS256`, `JWT_SECRET`). No modifica el contrato del token.
5. El cambio entre implementaciones se realiza mediante configuración de
   `INVENTORY_SERVICE_URL` en `inventory-front`, sin cambiar el código del front.
6. Los roles/permisos siguen siendo una decisión futura: no se incluyen claims
   nuevos ni reglas de autorización basadas en roles hasta que se documenten.

## Consecuencias

### Positivas

* No existen dos propietarios concurrentes de `inventory_db`.
* El frente puede cambiar de backend con una variable de entorno.
* El contrato queda documentado en un único lugar.

### Negativas

* Hay dos bases de código con el mismo dominio que deben mantenerse alineadas.
* Durante la migración conviene ejecutar la misma batería de pruebas contra
  ambos servicios para detectar divergencias.
* El esquema de `inventory_db` debe ser compatible con ambos servicios antes de
  realizar el cambio.

## Alternativas consideradas

* **Ambos servicios activos compartiendo `inventory_db`**: rechazada. Rompe la
  separación de responsabilidades y duplica la lógica de negocio.
* **Base de datos propia para el servicio Go**: rechazada por ahora. El objetivo
  es reutilizar el esquema existente (`DDBB/inventory.sql`). Si se adopta en el
  futuro, este ADR debe actualizarse.
* **Migración incremental por tablas**: rechazada por ahora. Requiere definir un
  mecanismo de sincronización entre servicios, todavía no contratado.

## Procedimiento de cambio (switch)

1. Verificar que el esquema de `inventory_db` sea compatible con ambas
   implementaciones.
2. Ejecutar las pruebas de contrato contra el servicio de destino.
3. Detener el servicio de inventario que está activo.
4. Arranque el servicio de destino apuntando a la misma `inventory_db`.
5. Actualizar `INVENTORY_SERVICE_URL` en `inventory-front/.env`.
6. Verificar `/health`, login y una operación de lectura/escritura.

El rollback consiste en repetir el procedimiento en sentido inverso. Bajo ningún
concepto ambos servicios deben quedar activos contra la misma base de datos.
