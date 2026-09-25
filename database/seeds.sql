-- Catálogo de Razas
INSERT INTO razas (nombre) VALUES 
('Sin raza definida / criollo'),
('Mestizo'),
('Labrador Retriever'),
('Chihuahua'),
('Pastor Alemán'),
('Husky Siberiano'),
('Poodle'),
('Pitbull'),
('Beagle'),
('Boxer');

-- Catálogo de Colores
INSERT INTO colores (nombre) VALUES 
('Negro'),
('Blanco'),
('Café'),
('Miel / Beige'),
('Gris'),
('Atigrado'),
('Manchado'),
('Canela'),
('Rojizo'),
('Crema');

-- 15 perritos de prueba
INSERT INTO perritos (idempotency_key, nombre, id_raza, id_color_principal, foto_ruta, latitud, longitud) VALUES
('seed-uuid-001', 'Solovino', 1, 4, 'perrito_001.webp', 25.42672000, -101.00530000),
('seed-uuid-002', 'Rocky', 5, 1, 'perrito_002.webp', 25.43120000, -100.99210000),
('seed-uuid-003', 'Manchas', 2, 7, 'perrito_003.webp', 25.41980000, -101.01540000),
('seed-uuid-004', 'Canela', 4, 8, 'perrito_004.webp', 25.44010000, -100.98560000),
('seed-uuid-005', 'Oso', 1, 3, 'perrito_005.webp', 25.41250000, -101.02010000),
('seed-uuid-006', 'Luna', 6, 2, 'perrito_006.webp', 25.44890000, -100.97890000),
('seed-uuid-007', 'Chuchín', 1, 1, 'perrito_007.webp', 25.43500000, -101.00100000),
('seed-uuid-008', 'Toby', 9, 3, 'perrito_008.webp', 25.42200000, -101.00800000),
('seed-uuid-009', 'Negro', 8, 1, 'perrito_009.webp', 25.41500000, -100.99800000),
('seed-uuid-010', 'Pelusa', 7, 2, 'perrito_010.webp', 25.45200000, -100.96500000),
('seed-uuid-011', 'Capitán', 3, 4, 'perrito_011.webp', 25.42800000, -101.01200000),
('seed-uuid-012', 'Güero', 1, 10, 'perrito_012.webp', 25.43800000, -100.98900000),
('seed-uuid-013', 'Tigre', 2, 6, 'perrito_013.webp', 25.40500000, -101.02500000),
('seed-uuid-014', 'Chispa', 4, 3, 'perrito_014.webp', 25.44150000, -100.99500000),
('seed-uuid-015', 'Firulais', 10, 8, 'perrito_015.webp', 25.42050000, -101.00300000);

-- Colores adicionales
INSERT INTO perrito_colores_adicionales (id_perrito, id_color) VALUES
(1, 2),
(2, 8), (2, 3),
(3, 1),
(5, 1),
(6, 5),
(8, 2), (8, 1),
(11, 2),
(13, 1);