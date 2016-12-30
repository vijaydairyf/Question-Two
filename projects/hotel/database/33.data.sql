

INSERT INTO departments (department_id, department_name) VALUES (1, 'Main Store');
INSERT INTO departments (department_id, department_name) VALUES (2, 'Kitchen Store');
INSERT INTO departments (department_id, department_name) VALUES (3, 'Bar');
INSERT INTO departments (department_id, department_name) VALUES (4, 'Reservation');
INSERT INTO departments (department_id, department_name) VALUES (5, 'Hotel service');
SELECT pg_catalog.setval('departments_department_id_seq', 5, true);

INSERT INTO service_types (service_type_id, service_type_name) VALUES (1, 'VIP');
INSERT INTO service_types (service_type_id, service_type_name) VALUES (2, 'Bed and Breakfast');
INSERT INTO service_types (service_type_id, service_type_name) VALUES (3, 'Half Board');
INSERT INTO service_types (service_type_id, service_type_name) VALUES (4, 'Full Board');
SELECT pg_catalog.setval('service_types_service_type_id_seq', 5, false);

INSERT INTO room_types (room_type_id, room_type_name) VALUES (16, 'Sanctuary Suite');
INSERT INTO room_types (room_type_id, room_type_name) VALUES (22, 'Executive King Room ');
INSERT INTO room_types (room_type_id, room_type_name) VALUES (23, '2 Queen Bed Guest Room');
INSERT INTO room_types (room_type_id, room_type_name) VALUES (24, 'Quality Room');
SELECT pg_catalog.setval('room_types_room_type_id_seq', 24, true);

INSERT INTO reserve_modes (reserve_mode_id, reserve_mode_name) VALUES (1, 'Inquiry');
INSERT INTO reserve_modes (reserve_mode_id, reserve_mode_name) VALUES (2, 'Tentative');
INSERT INTO reserve_modes (reserve_mode_id, reserve_mode_name) VALUES (3, 'Wait listed');
INSERT INTO reserve_modes (reserve_mode_id, reserve_mode_name) VALUES (4, 'Guaranteed');
INSERT INTO reserve_modes (reserve_mode_id, reserve_mode_name) VALUES (5, 'Confirmed');
SELECT pg_catalog.setval('reserve_modes_reserve_mode_id_seq', 3, true);

INSERT INTO entity_types (org_id, entity_type_name, entity_role, use_key_id) VALUES (0, 'Waiters', 'users', 2);
