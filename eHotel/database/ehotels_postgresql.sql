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

-- Adjusting the number of hotel chains to 5
DELETE FROM hotel WHERE chaine_id > 5; -- Remove hotels associated with chains beyond the first 5
DELETE FROM chaine_email WHERE chaine_id > 5; -- Remove emails for chains beyond the first 5
DELETE FROM chaine_telephone WHERE chaine_id > 5; -- Remove phone numbers for chains beyond the first 5
DELETE FROM chaine_hotel WHERE chaine_id > 5; -- Remove chains beyond the first 5

INSERT INTO chaine_hotel (nom, adresse_siege, nb_hotels) VALUES
('Marriott International', 'Bethesda, Maryland, USA', 8),
('Hilton Worldwide', 'McLean, Virginia, USA', 8),
('Hyatt Hotels Corporation', 'Chicago, Illinois, USA', 8),
('IHG Hotels & Resorts', 'Denham, Buckinghamshire, UK', 8),
('Accor', 'Issy-les-Moulineaux, France', 8);

INSERT INTO chaine_email (chaine_id, email) VALUES
(1, 'contact@marriott.com'),
(2, 'contact@hilton.com'),
(3, 'contact@hyatt.com'),
(4, 'contact@ihg.com'),
(5, 'contact@accor.com');

INSERT INTO chaine_telephone (chaine_id, telephone) VALUES
(1, '1-613-555-1001'),
(2, '1-416-555-1002'),
(3, '1-902-555-1003'),
(4, '1-604-555-1004'),
(5, '1-514-555-1005');

WITH hotel_data (chaine_id, nom, categorie, adresse, zone, email_contact, telephone_contact) AS (
    VALUES
    (1, 'Marriott Ottawa Downtown', 5, '100 Wellington St, Ottawa, ON', 'Ottawa Centre', 'ottawa@marriott.com', '613-555-2001'),
    (1, 'Marriott Toronto Union', 5, '10 Front St, Toronto, ON', 'Toronto Centre', 'toronto@marriott.com', '416-555-2002'),
    (1, 'Marriott Montreal Central', 4, '300 Rue Sainte-Catherine, Montreal, QC', 'Montreal Centre', 'montreal@marriott.com', '514-555-2003'),
    (1, 'Marriott Vancouver Bay', 5, '99 Bay Ave, Vancouver, BC', 'Vancouver Bay', 'vancouver@marriott.com', '604-555-2004'),
    (1, 'Marriott Calgary Centre', 4, '120 Stephen Ave, Calgary, AB', 'Calgary Centre', 'calgary@marriott.com', '403-555-2005'),
    (1, 'Marriott Edmonton Riverside', 4, '88 River Valley Rd, Edmonton, AB', 'Edmonton Riverside', 'edmonton@marriott.com', '780-555-2006'),
    (1, 'Marriott Quebec Heritage', 5, '15 Grande Allee, Quebec City, QC', 'Quebec Heritage', 'quebec@marriott.com', '418-555-2007'),
    (1, 'Marriott Halifax Harbour', 4, '55 Water St, Halifax, NS', 'Halifax Harbour', 'halifax@marriott.com', '902-555-2008'),
    (2, 'Hilton Toronto Lakeshore', 5, '88 Lake Shore Blvd, Toronto, ON', 'Toronto Waterfront', 'lakeshore@hilton.com', '416-555-2101'),
    (2, 'Hilton Ottawa Central', 4, '110 Elgin St, Ottawa, ON', 'Ottawa Centre', 'ottawa@hilton.com', '613-555-2102'),
    (2, 'Hilton Winnipeg Plaza', 4, '200 Portage Ave, Winnipeg, MB', 'Winnipeg Centre', 'winnipeg@hilton.com', '204-555-2103'),
    (2, 'Hilton Victoria Inner Harbour', 5, '20 Government St, Victoria, BC', 'Victoria Harbour', 'victoria@hilton.com', '250-555-2104'),
    (2, 'Hilton London Downtown', 4, '45 Dundas St, London, ON', 'London Centre', 'london@hilton.com', '519-555-2105'),
    (2, 'Hilton Saskatoon Riverfront', 4, '75 Spadina Cres, Saskatoon, SK', 'Saskatoon Riverfront', 'saskatoon@hilton.com', '306-555-2106'),
    (2, 'Hilton Niagara Falls View', 5, '1 Fallsview Blvd, Niagara Falls, ON', 'Niagara Falls', 'niagara@hilton.com', '289-555-2107'),
    (2, 'Hilton Regina Gateway', 4, '1000 Albert St, Regina, SK', 'Regina Gateway', 'regina@hilton.com', '306-555-2108'),
    (3, 'Hyatt Halifax Central', 5, '11 Spring Garden Rd, Halifax, NS', 'Halifax Centre', 'halifax@hyatt.com', '902-555-2201'),
    (3, 'Hyatt St Johns Port', 4, '30 Port Ave, St Johns, NL', 'St Johns Port', 'stjohns@hyatt.com', '709-555-2202'),
    (3, 'Hyatt Kelowna Lakeview', 5, '120 Lakeshore Rd, Kelowna, BC', 'Kelowna Lakeview', 'kelowna@hyatt.com', '250-555-2203'),
    (3, 'Hyatt Kamloops Summit', 4, '500 Summit Dr, Kamloops, BC', 'Kamloops Summit', 'kamloops@hyatt.com', '250-555-2204'),
    (3, 'Hyatt Fredericton Commons', 4, '10 Regent St, Fredericton, NB', 'Fredericton Commons', 'fredericton@hyatt.com', '506-555-2205'),
    (3, 'Hyatt Moncton Market', 4, '40 Main St, Moncton, NB', 'Moncton Market', 'moncton@hyatt.com', '506-555-2206'),
    (3, 'Hyatt Sherbrooke Square', 4, '75 King St W, Sherbrooke, QC', 'Sherbrooke Square', 'sherbrooke@hyatt.com', '819-555-2207'),
    (3, 'Hyatt Charlottetown Seaside', 5, '25 Water St, Charlottetown, PE', 'Charlottetown Seaside', 'charlottetown@hyatt.com', '902-555-2208'),
    (4, 'IHG Vancouver Central', 5, '60 Granville St, Vancouver, BC', 'Vancouver Centre', 'van@ihg.com', '604-555-2301'),
    (4, 'IHG Whistler Alpine', 5, '78 Alpine Rd, Whistler, BC', 'Whistler Alpine', 'whistler@ihg.com', '604-555-2302'),
    (4, 'IHG Richmond Airport', 4, '111 Airport Rd, Richmond, BC', 'Richmond Airport', 'richmond@ihg.com', '604-555-2303'),
    (4, 'IHG Burnaby Heights', 4, '250 Hastings St, Burnaby, BC', 'Burnaby Heights', 'burnaby@ihg.com', '604-555-2304'),
    (4, 'IHG Ottawa Parliament', 5, '70 Parliament Hill, Ottawa, ON', 'Ottawa Parliament', 'parliament@ihg.com', '613-555-2305'),
    (4, 'IHG Toronto Harbourfront', 5, '140 Queens Quay, Toronto, ON', 'Toronto Harbourfront', 'harbourfront@ihg.com', '416-555-2306'),
    (4, 'IHG Montreal Old Port', 5, '50 Old Port Way, Montreal, QC', 'Montreal Old Port', 'oldport@ihg.com', '514-555-2307'),
    (4, 'IHG Calgary Tech Park', 4, '300 Tech Park Blvd, Calgary, AB', 'Calgary Tech Park', 'tech@ihg.com', '403-555-2308'),
    (5, 'Accor Montreal Downtown', 5, '90 Rene-Levesque Blvd, Montreal, QC', 'Montreal Centre', 'montreal@accor.com', '514-555-2401'),
    (5, 'Accor Quebec Palace', 5, '100 Grande Allee, Quebec City, QC', 'Quebec Centre', 'quebec@accor.com', '418-555-2402'),
    (5, 'Accor Gatineau Parkside', 4, '200 Laurier St, Gatineau, QC', 'Gatineau Parkside', 'gatineau@accor.com', '819-555-2403'),
    (5, 'Accor Laval Metro', 4, '410 Des Laurentides Blvd, Laval, QC', 'Laval Metro', 'laval@accor.com', '450-555-2404'),
    (5, 'Accor Trois-Rivieres Heritage', 4, '75 Des Forges St, Trois-Rivieres, QC', 'Trois-Rivieres Heritage', 'troisrivieres@accor.com', '819-555-2405'),
    (5, 'Accor Saguenay Fjord', 4, '55 Du Fjord Rd, Saguenay, QC', 'Saguenay Fjord', 'saguenay@accor.com', '418-555-2406'),
    (5, 'Accor Rimouski Rivage', 4, '12 Saint-Germain E, Rimouski, QC', 'Rimouski Rivage', 'rimouski@accor.com', '418-555-2407'),
    (5, 'Accor Sherbrooke Plateau', 4, '88 Plateau St, Sherbrooke, QC', 'Sherbrooke Plateau', 'sherbrooke@accor.com', '819-555-2408')
)
INSERT INTO hotel (chaine_id, nom, categorie, adresse, zone, nb_chambres, email_contact, telephone_contact)
SELECT chaine_id, nom, categorie, adresse, zone, 5, email_contact, telephone_contact
FROM hotel_data
ORDER BY chaine_id, nom;

INSERT INTO employe (hotel_id, nom_complet, adresse, nas, role_hotel, email, telephone)
SELECT
    h.hotel_id,
    'Gestionnaire Hotel ' || h.hotel_id,
    h.adresse,
    'EMP' || LPAD(h.hotel_id::text, 6, '0'),
    'Gestionnaire',
    'manager' || h.hotel_id || '@hotels.example.com',
    '613-555-' || (6000 + h.hotel_id)::text
FROM hotel h
ORDER BY h.hotel_id;

UPDATE hotel SET gestionnaire_id = (SELECT employe_id FROM employe WHERE hotel_id = hotel.hotel_id AND role_hotel = 'Gestionnaire' LIMIT 1) WHERE gestionnaire_id IS NULL;

INSERT INTO client (nom_complet, adresse, nas, date_inscription, email, telephone) VALUES
('Alice Tremblay', '123 Elm St, Ottawa, ON', 'CLI0001', CURRENT_DATE - INTERVAL '120 days', 'alice@example.com', '613-555-7001'),
('Marc Gagnon', '456 Oak Ave, Montreal, QC', 'CLI0002', CURRENT_DATE - INTERVAL '90 days', 'marc@example.com', '514-555-7002'),
('Sophie Roy', '789 Maple Rd, Toronto, ON', 'CLI0003', CURRENT_DATE - INTERVAL '60 days', 'sophie@example.com', '416-555-7003'),
('David Nguyen', '100 Pine St, Vancouver, BC', 'CLI0004', CURRENT_DATE - INTERVAL '45 days', 'david@example.com', '604-555-7004'),
('Emma Bouchard', '234 Cedar Ln, Halifax, NS', 'CLI0005', CURRENT_DATE - INTERVAL '30 days', 'emma@example.com', '902-555-7005'),
('Michael Brown', '567 Birch Way, New York, NY', 'CLI0006', CURRENT_DATE - INTERVAL '20 days', 'michael@example.com', '212-555-7006'),
('Jennifer Davis', '890 Ash Court, Los Angeles, CA', 'CLI0007', CURRENT_DATE - INTERVAL '15 days', 'jennifer@example.com', '213-555-7007'),
('Robert Johnson', '111 Oak Hill, London, UK', 'CLI0008', CURRENT_DATE - INTERVAL '10 days', 'robert@example.com', '207-555-7008'),
('Catherine Martin', '222 Chestnut Ave, Paris, France', 'CLI0009', CURRENT_DATE - INTERVAL '5 days', 'catherine@example.com', '147-555-7009'),
('James Wong', '333 Willow St, Tokyo, Japan', 'CLI0010', CURRENT_DATE, 'james@example.com', '335-555-7010');

WITH room_template (numero, prix, commodites, capacite, vue, lit_suppl, etat, superficie, statut) AS (
    VALUES
    ('101', 159.99, 'WiFi, TV, Salle de bain luxe', 1, 'ville', FALSE, 'bon état', 20, 'disponible'),
    ('102', 199.99, 'WiFi, TV, Climatisation, Salle de bain luxe', 2, 'ville', FALSE, 'bon état', 28, 'disponible'),
    ('103', 249.99, 'WiFi, TV, Mini-bar, Balcon', 2, 'ville', TRUE, 'bon état', 32, 'disponible'),
    ('104', 199.99, 'WiFi, TV, Bureau', 1, 'cour', FALSE, 'bon état', 22, 'disponible'),
    ('105', 279.99, 'WiFi, TV, Bureau, Mini-bar, Jacuzzi', 2, 'rivière', TRUE, 'bon état', 38, 'disponible')
)
INSERT INTO chambre (hotel_id, numero, prix, commodites, capacite, vue, lit_suppl, etat, superficie, statut)
SELECT
    h.hotel_id,
    rt.numero,
    rt.prix,
    rt.commodites,
    rt.capacite,
    rt.vue,
    rt.lit_suppl,
    rt.etat,
    rt.superficie,
    rt.statut
FROM hotel h
CROSS JOIN room_template rt
ORDER BY h.hotel_id, rt.numero;

INSERT INTO chambre (hotel_id, numero, prix, commodites, capacite, vue, lit_suppl, etat, superficie, statut) VALUES
(1, '106', 249.99, 'WiFi, TV, Mini-bar, Balcon', 2, 'ville', TRUE, 'bon état', 32, 'disponible'),
(1, '107', 279.99, 'WiFi, TV, Bureau, Mini-bar, Jacuzzi', 2, 'rivière', TRUE, 'bon état', 38, 'disponible');

INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin, date_reservation, statut) VALUES
(1, 1, CURRENT_DATE + 5, CURRENT_DATE + 8, CURRENT_DATE - INTERVAL '2 days', 'active'),
(2, 7, CURRENT_DATE + 10, CURRENT_DATE + 15, CURRENT_DATE - INTERVAL '1 day', 'active'),
(3, 9, CURRENT_DATE + 3, CURRENT_DATE + 6, CURRENT_DATE, 'active'),
(4, 11, CURRENT_DATE + 14, CURRENT_DATE + 18, CURRENT_DATE, 'active'),
(5, 13, CURRENT_DATE + 20, CURRENT_DATE + 25, CURRENT_DATE, 'active'),
(6, 15, CURRENT_DATE + 7, CURRENT_DATE + 10, CURRENT_DATE, 'active'),
(7, 17, CURRENT_DATE + 12, CURRENT_DATE + 16, CURRENT_DATE, 'active'),
(8, 19, CURRENT_DATE + 8, CURRENT_DATE + 11, CURRENT_DATE, 'active');

INSERT INTO location (client_id, chambre_id, reservation_id, employe_id, date_debut, date_fin, date_checkin, type_location, statut) VALUES
(9, 3, NULL, 2, CURRENT_DATE, CURRENT_DATE + 3, CURRENT_DATE, 'directe', 'active'),
(10, 5, NULL, 4, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + 2, CURRENT_DATE - INTERVAL '1 day', 'directe', 'active');

UPDATE hotel h SET nb_chambres = (SELECT COUNT(*) FROM chambre c WHERE c.hotel_id = h.hotel_id);

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM chaine_hotel) <> 5 THEN
        RAISE EXCEPTION 'Expected 5 hotel chains in seed data';
    END IF;

    IF (SELECT COUNT(*) FROM hotel) <> 40 THEN
        RAISE EXCEPTION 'Expected 40 hotels in seed data';
    END IF;

    IF (SELECT COUNT(*) FROM chambre) <> 202 THEN
        RAISE EXCEPTION 'Expected 202 rooms in seed data';
    END IF;
END $$;

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