-- =============================================
-- inventory.sql
-- Base de datos de negocio (inventory_db)
-- Servicio: inventory-service
-- Motor: PostgreSQL
-- =============================================

-- Extensión necesaria para uuid_generate_v4()
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- Tablas base (sin dependencias)
-- =============================================

-- public.categories definition

-- Drop table

-- DROP TABLE public.categories;

CREATE TABLE public.categories (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	"name" varchar(100) NOT NULL,
	description text NULL,
	active bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT categories_name_key UNIQUE (name),
	CONSTRAINT categories_pkey PRIMARY KEY (id)
);

-- public.suppliers definition

-- Drop table

-- DROP TABLE public.suppliers;

CREATE TABLE public.suppliers (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	"name" varchar(150) NOT NULL,
	identification varchar(50) NULL,
	phone varchar(30) NULL,
	email varchar(150) NULL,
	address text NULL,
	active bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT suppliers_pkey PRIMARY KEY (id)
);

-- public.warehouses definition

-- Drop table

-- DROP TABLE public.warehouses;

CREATE TABLE public.warehouses (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	code varchar(30) NOT NULL,
	"name" varchar(100) NOT NULL,
	description text NULL,
	address text NULL,
	active bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT warehouses_code_key UNIQUE (code),
	CONSTRAINT warehouses_pkey PRIMARY KEY (id)
);

-- =============================================
-- Tablas dependientes (con foreign keys)
-- =============================================

-- public.products definition

-- Drop table

-- DROP TABLE public.products;

CREATE TABLE public.products (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	sku varchar(50) NOT NULL,
	barcode varchar(100) NULL,
	"name" varchar(150) NOT NULL,
	description text NULL,
	category_id uuid NULL,
	supplier_id uuid NULL,
	purchase_price numeric(14, 2) DEFAULT 0 NOT NULL,
	sale_price numeric(14, 2) DEFAULT 0 NOT NULL,
	unit varchar(20) DEFAULT 'UNIT'::character varying NOT NULL,
	active bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT products_barcode_key UNIQUE (barcode),
	CONSTRAINT products_pkey PRIMARY KEY (id),
	CONSTRAINT products_purchase_price_check CHECK ((purchase_price >= (0)::numeric)),
	CONSTRAINT products_sale_price_check CHECK ((sale_price >= (0)::numeric)),
	CONSTRAINT products_sku_key UNIQUE (sku)
);
CREATE INDEX idx_products_category ON public.products USING btree (category_id);
CREATE INDEX idx_products_supplier ON public.products USING btree (supplier_id);


-- public.products foreign keys

ALTER TABLE public.products ADD CONSTRAINT products_category_fk FOREIGN KEY (category_id) REFERENCES public.categories(id);
ALTER TABLE public.products ADD CONSTRAINT products_supplier_fk FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);

-- public.transfers definition

-- Drop table

-- DROP TABLE public.transfers;

CREATE TABLE public.transfers (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	origin_warehouse_id uuid NOT NULL,
	destination_warehouse_id uuid NOT NULL,
	user_id uuid NULL,
	status varchar(20) DEFAULT 'PENDING'::character varying NOT NULL,
	observation text NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT transfers_different_warehouses CHECK ((origin_warehouse_id <> destination_warehouse_id)),
	CONSTRAINT transfers_pkey PRIMARY KEY (id),
	CONSTRAINT transfers_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SENT'::character varying, 'RECEIVED'::character varying, 'CANCELLED'::character varying])::text[])))
);
CREATE INDEX idx_transfers_destination ON public.transfers USING btree (destination_warehouse_id);
CREATE INDEX idx_transfers_origin ON public.transfers USING btree (origin_warehouse_id);
CREATE INDEX idx_transfers_status ON public.transfers USING btree (status);
CREATE INDEX idx_transfers_user ON public.transfers USING btree (user_id);


-- public.transfers foreign keys

ALTER TABLE public.transfers ADD CONSTRAINT transfers_destination_fk FOREIGN KEY (destination_warehouse_id) REFERENCES public.warehouses(id);
ALTER TABLE public.transfers ADD CONSTRAINT transfers_origin_fk FOREIGN KEY (origin_warehouse_id) REFERENCES public.warehouses(id);

-- public.transfer_details definition

-- Drop table

-- DROP TABLE public.transfer_details;

CREATE TABLE public.transfer_details (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	transfer_id uuid NOT NULL,
	product_id uuid NOT NULL,
	quantity numeric(14, 3) NOT NULL,
	CONSTRAINT transfer_details_pkey PRIMARY KEY (id),
	CONSTRAINT transfer_details_quantity_check CHECK ((quantity > (0)::numeric))
);
CREATE INDEX idx_transfer_details_product ON public.transfer_details USING btree (product_id);
CREATE INDEX idx_transfer_details_transfer ON public.transfer_details USING btree (transfer_id);


-- public.transfer_details foreign keys

ALTER TABLE public.transfer_details ADD CONSTRAINT transfer_details_product_fk FOREIGN KEY (product_id) REFERENCES public.products(id);
ALTER TABLE public.transfer_details ADD CONSTRAINT transfer_details_transfer_fk FOREIGN KEY (transfer_id) REFERENCES public.transfers(id) ON DELETE CASCADE;

-- public.inventory definition

-- Drop table

-- DROP TABLE public.inventory;

CREATE TABLE public.inventory (
	product_id uuid NOT NULL,
	warehouse_id uuid NOT NULL,
	quantity numeric(14, 3) DEFAULT 0 NOT NULL,
	minimum_stock numeric(14, 3) DEFAULT 0 NOT NULL,
	maximum_stock numeric(14, 3) NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT inventory_maximum_stock_check CHECK (((maximum_stock IS NULL) OR (maximum_stock >= minimum_stock))),
	CONSTRAINT inventory_minimum_stock_check CHECK ((minimum_stock >= (0)::numeric)),
	CONSTRAINT inventory_pkey PRIMARY KEY (product_id, warehouse_id),
	CONSTRAINT inventory_quantity_check CHECK ((quantity >= (0)::numeric))
);
CREATE INDEX idx_inventory_warehouse ON public.inventory USING btree (warehouse_id);


-- public.inventory foreign keys

ALTER TABLE public.inventory ADD CONSTRAINT inventory_product_fk FOREIGN KEY (product_id) REFERENCES public.products(id);
ALTER TABLE public.inventory ADD CONSTRAINT inventory_warehouse_fk FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);

-- public.movements definition

-- Drop table

-- DROP TABLE public.movements;

CREATE TABLE public.movements (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	product_id uuid NOT NULL,
	warehouse_id uuid NOT NULL,
	user_id uuid NULL,
	"type" varchar(30) NOT NULL,
	quantity numeric(14, 3) NOT NULL,
	previous_quantity numeric(14, 3) NOT NULL,
	new_quantity numeric(14, 3) NOT NULL,
	reference varchar(100) NULL,
	observation text NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT movements_new_quantity_check CHECK ((new_quantity >= (0)::numeric)),
	CONSTRAINT movements_pkey PRIMARY KEY (id),
	CONSTRAINT movements_previous_quantity_check CHECK ((previous_quantity >= (0)::numeric)),
	CONSTRAINT movements_quantity_check CHECK ((quantity > (0)::numeric)),
	CONSTRAINT movements_type_check CHECK (((type)::text = ANY ((ARRAY['ENTRY'::character varying, 'EXIT'::character varying, 'ADJUSTMENT'::character varying, 'TRANSFER'::character varying])::text[])))
);
CREATE INDEX idx_movements_created_at ON public.movements USING btree (created_at);
CREATE INDEX idx_movements_product ON public.movements USING btree (product_id);
CREATE INDEX idx_movements_user ON public.movements USING btree (user_id);
CREATE INDEX idx_movements_warehouse ON public.movements USING btree (warehouse_id);


-- public.movements foreign keys

ALTER TABLE public.movements ADD CONSTRAINT movements_product_fk FOREIGN KEY (product_id) REFERENCES public.products(id);
ALTER TABLE public.movements ADD CONSTRAINT movements_warehouse_fk FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);

-- =============================================
-- Drop tables (opcional, en orden inverso)
-- =============================================

-- DROP TABLE public.movements;
-- DROP TABLE public.inventory;
-- DROP TABLE public.transfer_details;
-- DROP TABLE public.transfers;
-- DROP TABLE public.products;
-- DROP TABLE public.warehouses;
-- DROP TABLE public.suppliers;
-- DROP TABLE public.categories;