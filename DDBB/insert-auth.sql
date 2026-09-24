-- =============================================
-- insert-auth.sql
-- Datos de ejemplo para la base de autenticación (auth_db)
-- Servicio: auth-service
-- Motor: PostgreSQL
-- =============================================

-- =============================================
-- roles
-- =============================================

INSERT INTO public.roles (id, code, "name", description, active) VALUES
	('11111111-1111-1111-1111-111111111111', 'ADMIN', 'Administrator', 'Full access to the system', true),
	('22222222-2222-2222-2222-222222222222', 'SELLER', 'Seller', 'Can manage sales and inventory operations', true),
	('33333333-3333-3333-3333-333333333333', 'CLIENT', 'Client', 'Can view catalog and manage own purchases', true);

-- =============================================
-- users
-- Clave en texto plano para entorno de desarrollo: 123456
-- =============================================

INSERT INTO public.users (id, email, password_hash, "name", active) VALUES
	('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin@inventory.local', '$2b$10$3IGqSJScw3.Pz7MiQLQgKOPwILNKg6AViyit/U.PuJNChgY9QS7F.', 'System Administrator', true),
	('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'seller@inventory.local', '$2b$10$3IGqSJScw3.Pz7MiQLQgKOPwILNKg6AViyit/U.PuJNChgY9QS7F.', 'Store Seller', true),
	('2e76924f-99fe-4f37-b915-19d23bd3ccf1', 'ALX@email.com', '$2b$10$3IGqSJScw3.Pz7MiQLQgKOPwILNKg6AViyit/U.PuJNChgY9QS7F.', 'Deiby', true),
	('6c9c151c-36f2-4ad1-b7df-a296cb07b7bc', 'test@email.com', '$2b$10$3IGqSJScw3.Pz7MiQLQgKOPwILNKg6AViyit/U.PuJNChgY9QS7F.', 'Pruebas', true);

-- =============================================
-- user_roles
-- =============================================

INSERT INTO public.user_roles (user_id, role_id) VALUES
	('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111'),
	('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222'),
	('2e76924f-99fe-4f37-b915-19d23bd3ccf1', '22222222-2222-2222-2222-222222222222'),
	('6c9c151c-36f2-4ad1-b7df-a296cb07b7bc', '33333333-3333-3333-3333-333333333333');