-- =============================================
-- auth.sql
-- Base de datos de autenticación (auth_db)
-- Servicio: auth-service
-- Motor: PostgreSQL
-- =============================================

-- Extensión necesaria para uuid_generate_v4()
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- Tablas base (sin dependencias)
-- =============================================

-- public.permissions definition
CREATE TABLE public.permissions (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	code varchar(100) NOT NULL,
	"name" varchar(150) NOT NULL,
	description varchar(255) NULL,
	active bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT permissions_code_key UNIQUE (code),
	CONSTRAINT permissions_pkey PRIMARY KEY (id)
);

-- public.roles definition
CREATE TABLE public.roles (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	code varchar(50) NOT NULL,
	"name" varchar(100) NOT NULL,
	description varchar(255) NULL,
	active bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT roles_code_key UNIQUE (code),
	CONSTRAINT roles_pkey PRIMARY KEY (id)
);

-- public.users definition
CREATE TABLE public.users (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	email varchar(255) NOT NULL,
	password_hash varchar(255) NOT NULL,
	"name" varchar(150) NULL,
	active bool DEFAULT true NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT users_email_key UNIQUE (email),
	CONSTRAINT users_email_unique UNIQUE (email),
	CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- =============================================
-- Tablas dependientes (con foreign keys)
-- =============================================

-- public.user_roles definition
CREATE TABLE public.user_roles (
	user_id uuid NOT NULL,
	role_id uuid NOT NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id)
);

ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_role_fk FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;
ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- public.role_permissions definition
CREATE TABLE public.role_permissions (
	role_id uuid NOT NULL,
	permission_id uuid NOT NULL,
	CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id)
);

ALTER TABLE public.role_permissions ADD CONSTRAINT role_permissions_permission_fk FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;
ALTER TABLE public.role_permissions ADD CONSTRAINT role_permissions_role_fk FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;

-- public.refresh_tokens definition
CREATE TABLE public.refresh_tokens (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	user_id uuid NOT NULL,
	token_hash varchar(255) NOT NULL,
	expires_at timestamp NOT NULL,
	revoked_at timestamp NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id)
);

ALTER TABLE public.refresh_tokens ADD CONSTRAINT refresh_tokens_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- =============================================
-- Drop tables (opcional, en orden inverso)
-- =============================================

-- DROP TABLE public.refresh_tokens;
-- DROP TABLE public.role_permissions;
-- DROP TABLE public.user_roles;
-- DROP TABLE public.users;
-- DROP TABLE public.roles;
-- DROP TABLE public.permissions;