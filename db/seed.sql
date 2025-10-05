INSERT INTO passengers (full_name, email, password_hash)
VALUES ('Tk', 'hambira@gmail.com', '1234');

INSERT INTO admins (username, email, password_hash, role)
VALUES ('admin', 'admin@ticketing.com', 'hashed_admin_pass', 'super_admin');

INSERT INTO transport (route_name, origin, destination, departure_time, arrival_time, vehicle_type)
VALUES ('Route A', 'Windhoek Central', 'Katutura', '2025-10-05 08:30:00', '2025-10-05 09:10:00', 'bus');
