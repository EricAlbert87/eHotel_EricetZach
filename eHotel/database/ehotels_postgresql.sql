DROP VIEW IF EXISTS vue_capacite_totale_hotel CASCADE;
DROP VIEW IF EXISTS vue_chambres_disponibles_par_zone CASCADE;
DROP TABLE IF EXISTS location CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS chambre CASCADE;
DROP TABLE IF EXISTS employe CASCADE;
DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS hotel CASCADE;
DROP TABLE IF EXISTS chaine_telephone CASCADE;
DROP TABLE IF EXISTS chaine_email CASCADE;
DROP TABLE IF EXISTS chaine_hotel CASCADE;

CREATE TABLE chaine_hotel (
    chaine_id SERIAL PRIMARY KEY,
    nom VARCHAR(120) NOT NULL UNIQUE,
    adresse_siege VARCHAR(255) NOT NULL,
    nb_hotels INT NOT NULL DEFAULT 0 CHECK (nb_hotels >= 0)
);

CREATE TABLE chaine_email (
    email_id SERIAL PRIMARY KEY,
    chaine_id INT NOT NULL REFERENCES chaine_hotel(chaine_id) ON DELETE RESTRICT,
    email VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE chaine_telephone (
    tel_id SERIAL PRIMARY KEY,
    chaine_id INT NOT NULL REFERENCES chaine_hotel(chaine_id) ON DELETE RESTRICT,
    telephone VARCHAR(30) NOT NULL
);

CREATE TABLE hotel (
    hotel_id SERIAL PRIMARY KEY,
    chaine_id INT NOT NULL REFERENCES chaine_hotel(chaine_id) ON DELETE RESTRICT,
    nom VARCHAR(150) NOT NULL,
    categorie INT NOT NULL CHECK (categorie BETWEEN 1 AND 5),
    adresse VARCHAR(255) NOT NULL,
    zone VARCHAR(120) NOT NULL,
    nb_chambres INT NOT NULL DEFAULT 0 CHECK (nb_chambres >= 0),
    email_contact VARCHAR(150) NOT NULL,
    telephone_contact VARCHAR(30) NOT NULL,
    gestionnaire_id INT UNIQUE
);

CREATE TABLE client (
    client_id SERIAL PRIMARY KEY,
    nom_complet VARCHAR(150) NOT NULL,
    adresse VARCHAR(255) NOT NULL,
    nas VARCHAR(20) NOT NULL UNIQUE,
    date_inscription DATE NOT NULL DEFAULT CURRENT_DATE,
    email VARCHAR(150),
    telephone VARCHAR(30)
);

CREATE TABLE employe (
    employe_id SERIAL PRIMARY KEY,
    hotel_id INT NOT NULL REFERENCES hotel(hotel_id) ON DELETE RESTRICT,
    nom_complet VARCHAR(150) NOT NULL,
    adresse VARCHAR(255) NOT NULL,
    nas VARCHAR(20) NOT NULL UNIQUE,
    role_hotel VARCHAR(80) NOT NULL,
    email VARCHAR(150),
    telephone VARCHAR(30)
);

ALTER TABLE hotel
ADD CONSTRAINT fk_hotel_gestionnaire
FOREIGN KEY (gestionnaire_id) REFERENCES employe(employe_id) ON DELETE SET NULL;

CREATE TABLE chambre (
    chambre_id SERIAL PRIMARY KEY,
    hotel_id INT NOT NULL REFERENCES hotel(hotel_id) ON DELETE RESTRICT,
    numero VARCHAR(20) NOT NULL,
    prix NUMERIC(10,2) NOT NULL CHECK (prix > 0),
    commodites TEXT,
    capacite INT NOT NULL CHECK (capacite > 0),
    vue VARCHAR(50),
    lit_suppl BOOLEAN NOT NULL DEFAULT FALSE,
    etat VARCHAR(100) DEFAULT 'bon état',
    superficie NUMERIC(10,2) NOT NULL CHECK (superficie > 0),
    statut VARCHAR(20) NOT NULL DEFAULT 'disponible' CHECK (statut IN ('disponible','occupée','maintenance')),
    UNIQUE (hotel_id, numero)
);

CREATE TABLE reservation (
    reservation_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES client(client_id) ON DELETE RESTRICT,
    chambre_id INT NOT NULL REFERENCES chambre(chambre_id) ON DELETE RESTRICT,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    date_reservation DATE NOT NULL DEFAULT CURRENT_DATE,
    statut VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (statut IN ('active','annulée','convertie','terminée','archivée')),
    CHECK (date_debut < date_fin)
);

CREATE TABLE location (
    location_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES client(client_id) ON DELETE RESTRICT,
    chambre_id INT NOT NULL REFERENCES chambre(chambre_id) ON DELETE RESTRICT,
    reservation_id INT UNIQUE REFERENCES reservation(reservation_id) ON DELETE SET NULL,
    employe_id INT REFERENCES employe(employe_id) ON DELETE SET NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    date_checkin DATE NOT NULL DEFAULT CURRENT_DATE,
    type_location VARCHAR(20) NOT NULL CHECK (type_location IN ('directe','conversion')),
    statut VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (statut IN ('active','terminée','annulée','archivée')),
    CHECK (date_debut < date_fin)
);

CREATE OR REPLACE FUNCTION verifier_chevauchement_reservation()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM reservation r
        WHERE r.chambre_id = NEW.chambre_id
          AND r.statut IN ('active','convertie')
          AND NEW.date_debut < r.date_fin
          AND NEW.date_fin > r.date_debut
    ) THEN
        RAISE EXCEPTION 'Chevauchement détecté pour cette chambre';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verifier_chevauchement_reservation
BEFORE INSERT ON reservation
FOR EACH ROW
EXECUTE FUNCTION verifier_chevauchement_reservation();

CREATE OR REPLACE FUNCTION mettre_a_jour_statut_chambre_location()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chambre
    SET statut = 'occupée'
    WHERE chambre_id = NEW.chambre_id;

    IF NEW.reservation_id IS NOT NULL THEN
        UPDATE reservation
        SET statut = 'convertie'
        WHERE reservation_id = NEW.reservation_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_location_statut_chambre
AFTER INSERT ON location
FOR EACH ROW
EXECUTE FUNCTION mettre_a_jour_statut_chambre_location();

CREATE INDEX idx_hotel_zone ON hotel(zone);
CREATE INDEX idx_chambre_recherche ON chambre(hotel_id, capacite, prix, superficie);
CREATE INDEX idx_reservation_dates ON reservation(chambre_id, date_debut, date_fin);

CREATE OR REPLACE VIEW vue_chambres_disponibles_par_zone AS
SELECT h.zone, COUNT(*) AS nb_chambres_disponibles
FROM chambre c
JOIN hotel h ON h.hotel_id = c.hotel_id
WHERE c.statut = 'disponible'
GROUP BY h.zone;

CREATE OR REPLACE VIEW vue_capacite_totale_hotel AS
SELECT h.hotel_id, h.nom, SUM(c.capacite) AS capacite_totale
FROM hotel h
JOIN chambre c ON c.hotel_id = h.hotel_id
GROUP BY h.hotel_id, h.nom;

INSERT INTO chaine_hotel (nom, adresse_siege, nb_hotels) VALUES
('Northern Lights Hotels', 'Ottawa, Ontario, Canada', 8),
('Maple Crown Resorts', 'Toronto, Ontario, Canada', 8),
('Atlantic Breeze Inns', 'Halifax, Nova Scotia, Canada', 8),
('Pacific Peak Suites', 'Vancouver, British Columbia, Canada', 8),
('Continental Stay Group', 'Montreal, Quebec, Canada', 8);

INSERT INTO chaine_email (chaine_id, email) VALUES
(1, 'contact@northernlights.ca'),
(2, 'contact@maplecrown.ca'),
(3, 'contact@atlanticbreeze.ca'),
(4, 'contact@pacificpeak.ca'),
(5, 'contact@continentalstay.ca');

INSERT INTO chaine_telephone (chaine_id, telephone) VALUES
(1, '613-555-1001'),
(2, '416-555-1002'),
(3, '902-555-1003'),
(4, '604-555-1004'),
(5, '514-555-1005');

INSERT INTO hotel (chaine_id, nom, categorie, adresse, zone, nb_chambres, email_contact, telephone_contact) VALUES
(1, 'NL Ottawa Downtown', 5, '100 Wellington St, Ottawa', 'Ottawa Centre', 5, 'ottawa@northernlights.ca', '613-555-2001'),
(1, 'NL Ottawa Airport', 4, '200 Airport Rd, Ottawa', 'Ottawa South', 5, 'airport@northernlights.ca', '613-555-2002'),
(1, 'NL Montreal Central', 4, '300 Rue Sainte-Catherine, Montreal', 'Montreal Centre', 5, 'montreal@northernlights.ca', '514-555-2003'),
(1, 'NL Toronto Union', 5, '10 Front St, Toronto', 'Toronto Centre', 5, 'toronto@northernlights.ca', '416-555-2004'),
(1, 'NL Quebec Vieux-Port', 3, '25 Rue du Port, Quebec City', 'Quebec Centre', 5, 'quebec@northernlights.ca', '418-555-2005'),
(1, 'NL Halifax Harbour', 4, '50 Harbour Rd, Halifax', 'Halifax Waterfront', 5, 'halifax@northernlights.ca', '902-555-2006'),
(1, 'NL Calgary West', 3, '75 Bow Tr, Calgary', 'Calgary West', 5, 'calgary@northernlights.ca', '403-555-2007'),
(1, 'NL Vancouver Bay', 5, '99 Bay Ave, Vancouver', 'Vancouver Bay', 5, 'vancouver@northernlights.ca', '604-555-2008'),

(2, 'MC Ottawa Central', 4, '110 Elgin St, Ottawa', 'Ottawa Centre', 5, 'ottawa@maplecrown.ca', '613-555-2101'),
(2, 'MC Ottawa East', 3, '250 Montreal Rd, Ottawa', 'Ottawa East', 5, 'east@maplecrown.ca', '613-555-2102'),
(2, 'MC Toronto Midtown', 4, '500 Yonge St, Toronto', 'Toronto Midtown', 5, 'midtown@maplecrown.ca', '416-555-2103'),
(2, 'MC Toronto Lakeshore', 5, '88 Lake Shore Blvd, Toronto', 'Toronto Waterfront', 5, 'lakeshore@maplecrown.ca', '416-555-2104'),
(2, 'MC Kingston Riverside', 3, '12 River Rd, Kingston', 'Kingston Riverside', 5, 'kingston@maplecrown.ca', '613-555-2105'),
(2, 'MC London North', 3, '15 North Ave, London', 'London North', 5, 'london@maplecrown.ca', '519-555-2106'),
(2, 'MC Windsor Hub', 4, '18 Hub St, Windsor', 'Windsor Centre', 5, 'windsor@maplecrown.ca', '519-555-2107'),
(2, 'MC Sudbury Grand', 4, '20 Grand Ave, Sudbury', 'Sudbury Centre', 5, 'sudbury@maplecrown.ca', '705-555-2108'),

(3, 'AB Halifax Central', 5, '11 Spring Garden Rd, Halifax', 'Halifax Centre', 5, 'halifax@atlanticbreeze.ca', '902-555-2201'),
(3, 'AB Halifax Harbour', 4, '13 Dockside Ln, Halifax', 'Halifax Waterfront', 5, 'harbour@atlanticbreeze.ca', '902-555-2202'),
(3, 'AB Moncton East', 3, '55 Main St, Moncton', 'Moncton East', 5, 'moncton@atlanticbreeze.ca', '506-555-2203'),
(3, 'AB Fredericton River', 3, '22 Riverfront Rd, Fredericton', 'Fredericton River', 5, 'fred@atlanticbreeze.ca', '506-555-2204'),
(3, 'AB St Johns Port', 4, '30 Port Ave, St Johns', 'St Johns Port', 5, 'stjohns@atlanticbreeze.ca', '709-555-2205'),
(3, 'AB Charlottetown Garden', 4, '40 Garden St, Charlottetown', 'Charlottetown Garden', 5, 'charlottetown@atlanticbreeze.ca', '902-555-2206'),
(3, 'AB Sydney Shore', 3, '44 Shore Rd, Sydney', 'Sydney Shore', 5, 'sydney@atlanticbreeze.ca', '902-555-2207'),
(3, 'AB Dartmouth Crossing', 4, '46 Crossing Blvd, Dartmouth', 'Dartmouth Crossing', 5, 'dartmouth@atlanticbreeze.ca', '902-555-2208'),

(4, 'PP Vancouver Central', 5, '60 Granville St, Vancouver', 'Vancouver Centre', 5, 'van@pacificpeak.ca', '604-555-2301'),
(4, 'PP Vancouver Airport', 4, '61 Sea Island Way, Richmond', 'Vancouver Airport', 5, 'airport@pacificpeak.ca', '604-555-2302'),
(4, 'PP Victoria Harbour', 4, '70 Wharf St, Victoria', 'Victoria Harbour', 5, 'victoria@pacificpeak.ca', '250-555-2303'),
(4, 'PP Kelowna Lake', 3, '72 Lakeview Rd, Kelowna', 'Kelowna Lake', 5, 'kelowna@pacificpeak.ca', '250-555-2304'),
(4, 'PP Surrey South', 3, '74 South Fraser Rd, Surrey', 'Surrey South', 5, 'surrey@pacificpeak.ca', '604-555-2305'),
(4, 'PP Burnaby Heights', 4, '76 Heights Ave, Burnaby', 'Burnaby Heights', 5, 'burnaby@pacificpeak.ca', '604-555-2306'),
(4, 'PP Whistler Alpine', 5, '78 Alpine Rd, Whistler', 'Whistler Alpine', 5, 'whistler@pacificpeak.ca', '604-555-2307'),
(4, 'PP Nanaimo Bay', 3, '79 Bay St, Nanaimo', 'Nanaimo Bay', 5, 'nanaimo@pacificpeak.ca', '250-555-2308'),

(5, 'CS Montreal Downtown', 5, '90 Rene-Levesque Blvd, Montreal', 'Montreal Centre', 5, 'montreal@continentalstay.ca', '514-555-2401'),
(5, 'CS Montreal North', 4, '92 Ahuntsic Ave, Montreal', 'Montreal North', 5, 'north@continentalstay.ca', '514-555-2402'),
(5, 'CS Laval Business', 3, '94 Business Park, Laval', 'Laval Business', 5, 'laval@continentalstay.ca', '450-555-2403'),
(5, 'CS Gatineau Centre', 4, '96 Boulevard Maisonneuve, Gatineau', 'Gatineau Centre', 5, 'gatineau@continentalstay.ca', '819-555-2404'),
(5, 'CS Sherbrooke Hills', 3, '98 Hill Rd, Sherbrooke', 'Sherbrooke Hills', 5, 'sherbrooke@continentalstay.ca', '819-555-2405'),
(5, 'CS Quebec Palace', 5, '100 Grande Allee, Quebec City', 'Quebec Centre', 5, 'quebec@continentalstay.ca', '418-555-2406'),
(5, 'CS Trois-Rivieres', 3, '102 River St, Trois-Rivieres', 'Trois-Rivieres', 5, 'troisrivieres@continentalstay.ca', '819-555-2407'),
(5, 'CS Longueuil Metro', 4, '104 Metro Blvd, Longueuil', 'Longueuil Metro', 5, 'longueuil@continentalstay.ca', '450-555-2408');

INSERT INTO employe (hotel_id, nom_complet, adresse, nas, role_hotel, email, telephone)
SELECT hotel_id,
       'Gestionnaire Hotel ' || hotel_id,
       'Adresse employe hotel ' || hotel_id,
       'EMP' || LPAD(hotel_id::text, 6, '0'),
       'Gestionnaire',
       'manager' || hotel_id || '@ehotels.ca',
       '555-700-' || LPAD(hotel_id::text, 4, '0')
FROM hotel;

UPDATE hotel h
SET gestionnaire_id = e.employe_id
FROM employe e
WHERE h.hotel_id = e.hotel_id
  AND e.role_hotel = 'Gestionnaire';

INSERT INTO client (nom_complet, adresse, nas, date_inscription, email, telephone) VALUES
('Alice Tremblay', 'Ottawa, ON', 'CLI000001', CURRENT_DATE - INTERVAL '120 days', 'alice@example.com', '613-555-3001'),
('Marc Gagnon', 'Montreal, QC', 'CLI000002', CURRENT_DATE - INTERVAL '90 days', 'marc@example.com', '514-555-3002'),
('Sophie Roy', 'Toronto, ON', 'CLI000003', CURRENT_DATE - INTERVAL '60 days', 'sophie@example.com', '416-555-3003'),
('David Nguyen', 'Vancouver, BC', 'CLI000004', CURRENT_DATE - INTERVAL '45 days', 'david@example.com', '604-555-3004'),
('Emma Bouchard', 'Halifax, NS', 'CLI000005', CURRENT_DATE - INTERVAL '30 days', 'emma@example.com', '902-555-3005');

INSERT INTO chambre (hotel_id, numero, prix, commodites, capacite, vue, lit_suppl, etat, superficie, statut)
SELECT h.hotel_id,
       '10' || g.n,
       CASE g.n WHEN 1 THEN 119.99 WHEN 2 THEN 149.99 WHEN 3 THEN 179.99 WHEN 4 THEN 219.99 ELSE 279.99 END,
       CASE g.n WHEN 1 THEN 'WiFi, TV'
                WHEN 2 THEN 'WiFi, TV, Climatisation'
                WHEN 3 THEN 'WiFi, TV, Mini-bar'
                WHEN 4 THEN 'WiFi, TV, Climatisation, Bureau'
                ELSE 'WiFi, TV, Climatisation, Mini-bar, Bureau'
       END,
       CASE g.n WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 2 WHEN 4 THEN 3 ELSE 4 END,
       CASE g.n WHEN 1 THEN 'ville' WHEN 2 THEN 'cour' WHEN 3 THEN 'ville' WHEN 4 THEN 'rivière' ELSE 'mer' END,
       CASE WHEN g.n IN (3,4,5) THEN TRUE ELSE FALSE END,
       'bon état',
       CASE g.n WHEN 1 THEN 18 WHEN 2 THEN 22 WHEN 3 THEN 28 WHEN 4 THEN 35 ELSE 42 END,
       'disponible'
FROM hotel h
CROSS JOIN generate_series(1,5) AS g(n);

UPDATE hotel h
SET nb_chambres = x.cnt
FROM (
  SELECT hotel_id, COUNT(*) AS cnt
  FROM chambre
  GROUP BY hotel_id
) x
WHERE x.hotel_id = h.hotel_id;

INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin, date_reservation, statut) VALUES
(1, 1, CURRENT_DATE + 5, CURRENT_DATE + 8, CURRENT_DATE, 'active'),
(2, 6, CURRENT_DATE + 10, CURRENT_DATE + 13, CURRENT_DATE, 'active'),
(3, 11, CURRENT_DATE + 3, CURRENT_DATE + 5, CURRENT_DATE, 'active'),
(4, 16, CURRENT_DATE + 14, CURRENT_DATE + 18, CURRENT_DATE, 'active');

INSERT INTO location (client_id, chambre_id, reservation_id, employe_id, date_debut, date_fin, date_checkin, type_location, statut) VALUES
(5, 2, NULL, 1, CURRENT_DATE, CURRENT_DATE + 2, CURRENT_DATE, 'directe', 'active');

SELECT h.zone, h.nom AS hotel, c.numero, c.prix, c.capacite, c.superficie
FROM chambre c
JOIN hotel h ON h.hotel_id = c.hotel_id
WHERE c.statut = 'disponible'
  AND c.capacite >= 2
  AND c.prix <= 250
ORDER BY h.zone, c.prix;

SELECT cl.nom_complet, r.reservation_id, r.date_debut, r.date_fin, r.statut
FROM reservation r
JOIN client cl ON cl.client_id = r.client_id
ORDER BY cl.nom_complet;

SELECT l.location_id, cl.nom_complet AS client, e.nom_complet AS employe, l.type_location, l.date_debut, l.date_fin
FROM location l
JOIN client cl ON cl.client_id = l.client_id
LEFT JOIN employe e ON e.employe_id = l.employe_id;

SELECT h.nom, COUNT(c.chambre_id) AS nombre_chambres
FROM hotel h
LEFT JOIN chambre c ON c.hotel_id = h.hotel_id
GROUP BY h.nom
ORDER BY h.nom;