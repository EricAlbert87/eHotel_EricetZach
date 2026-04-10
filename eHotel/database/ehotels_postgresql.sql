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
('Marriott International', 'Bethesda, Maryland, USA', 0),
('Hilton Worldwide', 'McLean, Virginia, USA', 0),
('Hyatt Hotels Corporation', 'Chicago, Illinois, USA', 0),
('IHG Hotels & Resorts', 'Denham, Buckinghamshire, UK', 0),
('Accor', 'Issy-les-Moulineaux, France', 0),
('Wyndham Hotels & Resorts', 'Parsippany, New Jersey, USA', 0),
('Choice Hotels', 'Rockville, Maryland, USA', 0),
('Best Western', 'Phoenix, Arizona, USA', 0);

INSERT INTO chaine_email (chaine_id, email) VALUES
(1, 'contact@marriott.com'),
(2, 'contact@hilton.com'),
(3, 'contact@hyatt.com'),
(4, 'contact@ihg.com'),
(5, 'contact@accor.com'),
(6, 'reservations@wyndham.com'),
(7, 'info@choicehotels.com'),
(8, 'bookings@bestwestern.com');

INSERT INTO chaine_telephone (chaine_id, telephone) VALUES
(1, '1-613-555-1001'),
(2, '1-416-555-1002'),
(3, '1-902-555-1003'),
(4, '1-604-555-1004'),
(5, '1-514-555-1005'),
(6, '1-212-555-1006'),
(7, '+44-207-555-1007'),
(8, '+81-3-555-1008');

INSERT INTO hotel (chaine_id, nom, categorie, adresse, zone, nb_chambres, email_contact, telephone_contact) VALUES
(1, 'Marriott Ottawa Downtown', 5, '100 Wellington St, Ottawa, ON', 'Ottawa Centre', 25, 'ottawa@marriott.com', '613-555-2001'),
(1, 'Marriott Toronto Union', 5, '10 Front St, Toronto, ON', 'Toronto Centre', 30, 'toronto@marriott.com', '416-555-2004'),
(1, 'Marriott Montreal Central', 4, '300 Rue Sainte-Catherine, Montreal, QC', 'Montreal Centre', 20, 'montreal@marriott.com', '514-555-2003'),
(1, 'Marriott Vancouver Bay', 5, '99 Bay Ave, Vancouver, BC', 'Vancouver Bay', 28, 'vancouver@marriott.com', '604-555-2008'),
(2, 'Hilton Toronto Lakeshore', 5, '88 Lake Shore Blvd, Toronto, ON', 'Toronto Waterfront', 32, 'lakeshore@hilton.com', '416-555-2104'),
(2, 'Hilton Ottawa Central', 4, '110 Elgin St, Ottawa, ON', 'Ottawa Centre', 22, 'ottawa@hilton.com', '613-555-2101'),
(3, 'Hyatt Halifax Central', 5, '11 Spring Garden Rd, Halifax, NS', 'Halifax Centre', 24, 'halifax@hyatt.com', '902-555-2201'),
(3, 'Hyatt St Johns Port', 4, '30 Port Ave, St Johns, NL', 'St Johns Port', 18, 'stjohns@hyatt.com', '709-555-2205'),
(4, 'IHG Vancouver Central', 5, '60 Granville St, Vancouver, BC', 'Vancouver Centre', 26, 'van@ihg.com', '604-555-2301'),
(4, 'IHG Whistler Alpine', 5, '78 Alpine Rd, Whistler, BC', 'Whistler Alpine', 20, 'whistler@ihg.com', '604-555-2307'),
(5, 'Accor Montreal Downtown', 5, '90 Rene-Levesque Blvd, Montreal, QC', 'Montreal Centre', 28, 'montreal@accor.com', '514-555-2401'),
(5, 'Accor Quebec Palace', 5, '100 Grande Allee, Quebec City, QC', 'Quebec Centre', 25, 'quebec@accor.com', '418-555-2406'),
(6, 'Wyndham New York Times Square', 5, '1500 Broadway, New York, NY', 'Times Square', 35, 'newyork@wyndham.com', '212-555-3001'),
(6, 'Wyndham Los Angeles Sunset', 5, '5000 Sunset Blvd, Los Angeles, CA', 'Los Angeles', 30, 'losangeles@wyndham.com', '213-555-3002'),
(7, 'Choice London Piccadilly', 5, '100 Piccadilly, London, UK', 'London Centre', 40, 'london@choicehotels.com', '207-555-4001'),
(7, 'Choice Paris Champs', 5, '50 Avenue des Champs-Élysées, Paris, France', 'Paris Centre', 36, 'paris@choicehotels.com', '147-555-4002'),
(8, 'Best Western Tokyo Shibuya', 5, '1 Shibuya Crossing, Tokyo, Japan', 'Shibuya', 32, 'tokyo@bestwestern.com', '335-555-5001'),
(8, 'Best Western Bangkok Royal', 4, '150 Rajadamri Road, Bangkok, Thailand', 'Bangkok Centre', 28, 'bangkok@bestwestern.com', '226-555-5002');

INSERT INTO employe (hotel_id, nom_complet, adresse, nas, role_hotel, email, telephone) VALUES
(1, 'Jean Dupont', '100 Wellington St, Ottawa, ON', 'EMP000001', 'Gestionnaire', 'jean.dupont@northernlights.ca', '613-555-6001'),
(1, 'Marie Claire', '100 Wellington St, Ottawa, ON', 'EMP000002', 'Réceptionniste', 'marie@northernlights.ca', '613-555-6002'),
(2, 'Michael Johnson', '10 Front St, Toronto, ON', 'EMP000003', 'Gestionnaire', 'michael@northernlights.ca', '416-555-6003'),
(2, 'Sarah Wilson', '10 Front St, Toronto, ON', 'EMP000004', 'Réceptionniste', 'sarah@northernlights.ca', '416-555-6004'),
(3, 'Pierre Martin', '300 Rue Sainte-Catherine, Montreal, QC', 'EMP000005', 'Gestionnaire', 'pierre@northernlights.ca', '514-555-6005'),
(4, 'Lisa Wong', '99 Bay Ave, Vancouver, BC', 'EMP000006', 'Gestionnaire', 'lisa@northernlights.ca', '604-555-6006'),
(5, 'David Chen', '88 Lake Shore Blvd, Toronto, ON', 'EMP000007', 'Gestionnaire', 'david@maplecrown.ca', '416-555-6007'),
(5, 'Emma Taylor', '88 Lake Shore Blvd, Toronto, ON', 'EMP000008', 'Réceptionniste', 'emma@maplecrown.ca', '416-555-6008'),
(6, 'Robert Brown', '110 Elgin St, Ottawa, ON', 'EMP000009', 'Gestionnaire', 'robert@maplecrown.ca', '613-555-6009'),
(7, 'Catherine Roy', '11 Spring Garden Rd, Halifax, NS', 'EMP000010', 'Gestionnaire', 'catherine@atlanticbreeze.ca', '902-555-6010'),
(7, 'Thomas Moore', '11 Spring Garden Rd, Halifax, NS', 'EMP000011', 'Réceptionniste', 'thomas@atlanticbreeze.ca', '902-555-6011'),
(8, 'Sophie Adams', '30 Port Ave, St Johns, NL', 'EMP000012', 'Gestionnaire', 'sophie@atlanticbreeze.ca', '709-555-6012'),
(9, 'James White', '60 Granville St, Vancouver, BC', 'EMP000013', 'Gestionnaire', 'james@pacificpeak.ca', '604-555-6013'),
(10, 'Julia Garcia', '78 Alpine Rd, Whistler, BC', 'EMP000014', 'Gestionnaire', 'julia@pacificpeak.ca', '604-555-6014'),
(11, 'Marc Leblanc', '90 Rene-Levesque Blvd, Montreal, QC', 'EMP000015', 'Gestionnaire', 'marc@continentalstay.ca', '514-555-6015'),
(12, 'Nicole Gagnon', '100 Grande Allee, Quebec City, QC', 'EMP000016', 'Gestionnaire', 'nicole@continentalstay.ca', '418-555-6016'),
(13, 'William Smith', '1500 Broadway, New York, NY', 'EMP000017', 'Gestionnaire', 'william@globalluxury.com', '212-555-6017'),
(14, 'Patricia Davis', '5000 Sunset Blvd, Los Angeles, CA', 'EMP000018', 'Gestionnaire', 'patricia@globalluxury.com', '213-555-6018'),
(15, 'Nicholas Hunter', '100 Piccadilly, London, UK', 'EMP000019', 'Gestionnaire', 'nicholas@europeanhosp.co.uk', '207-555-6019'),
(16, 'Elizabeth Turner', '50 Avenue des Champs-Élysées, Paris, France', 'EMP000020', 'Gestionnaire', 'elizabeth@europeanhosp.co.uk', '147-555-6020'),
(17, 'Kevin Nakamura', '1 Shibuya Crossing, Tokyo, Japan', 'EMP000021', 'Gestionnaire', 'kevin@asianhotel.jp', '335-555-6021'),
(18, 'Angela Suwadi', '150 Rajadamri Road, Bangkok, Thailand', 'EMP000022', 'Gestionnaire', 'angela@asianhotel.jp', '226-555-6022');

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

INSERT INTO chambre (hotel_id, numero, prix, commodites, capacite, vue, lit_suppl, etat, superficie, statut) VALUES
(1, '101', 159.99, 'WiFi, TV, Salle de bain luxe', 1, 'ville', FALSE, 'bon état', 20, 'disponible'),
(1, '102', 199.99, 'WiFi, TV, Climatisation, Salle de bain luxe', 2, 'ville', FALSE, 'bon état', 28, 'disponible'),
(1, '103', 249.99, 'WiFi, TV, Mini-bar, Balcon', 2, 'ville', TRUE, 'bon état', 32, 'disponible'),
(1, '201', 199.99, 'WiFi, TV, Bureau', 1, 'cour', FALSE, 'bon état', 22, 'disponible'),
(1, '202', 279.99, 'WiFi, TV, Bureau, Mini-bar, Jacuzzi', 2, 'rivière', TRUE, 'bon état', 38, 'disponible'),
(2, '301', 179.99, 'WiFi, TV, Salle de bain moderne', 1, 'ville', FALSE, 'bon état', 21, 'disponible'),
(2, '302', 229.99, 'WiFi, TV, Climatisation, Balcon', 2, 'lac', FALSE, 'bon état', 29, 'disponible'),
(2, '303', 289.99, 'WiFi, TV, Studio complet, Kitchenette', 2, 'lac', TRUE, 'bon état', 42, 'disponible'),
(3, '401', 139.99, 'WiFi, TV', 1, 'terrasse', FALSE, 'bon état', 18, 'disponible'),
(3, '402', 189.99, 'WiFi, TV, Climatisation', 2, 'montagne', FALSE, 'bon état', 26, 'disponible'),
(4, '501', 329.99, 'WiFi, TV, Suite exécutive, Salon', 2, 'baie', TRUE, 'bon état', 55, 'disponible'),
(4, '502', 279.99, 'WiFi, TV, Balcon vue mer', 2, 'baie', FALSE, 'bon état', 38, 'disponible'),
(5, '601', 249.99, 'WiFi, TV, Bureau', 1, 'lac', FALSE, 'bon état', 25, 'disponible'),
(5, '602', 319.99, 'WiFi, TV, Suite, Salon', 2, 'lac', TRUE, 'bon état', 48, 'disponible'),
(6, '701', 149.99, 'WiFi, TV, Climatisation', 1, 'rue', FALSE, 'bon état', 20, 'disponible'),
(7, '801', 199.99, 'WiFi, TV, Balcon', 1, 'port', FALSE, 'bon état', 24, 'disponible'),
(8, '901', 169.99, 'WiFi, TV, Vue port', 2, 'port', FALSE, 'bon état', 28, 'disponible'),
(9, '1001', 209.99, 'WiFi, TV, Bureau', 1, 'ruelle', FALSE, 'bon état', 22, 'disponible'),
(10, '1101', 279.99, 'WiFi, TV, Cheminée, Balcon montagne', 2, 'montagne', TRUE, 'bon état', 40, 'disponible'),
(11, '1201', 199.99, 'WiFi, TV, Climatisation', 1, 'ville', FALSE, 'bon état', 23, 'disponible'),
(12, '1301', 229.99, 'WiFi, TV, Balcon panoramique', 2, 'fleuve', FALSE, 'bon état', 31, 'disponible'),
(13, '1401', 349.99, 'WiFi, TV, Suite Times Square, Spa', 2, 'times square', TRUE, 'bon état', 60, 'disponible'),
(14, '1501', 329.99, 'WiFi, TV, Suite Hollywood, Terrasse', 2, 'hollywood', TRUE, 'bon état', 58, 'disponible'),
(15, '1601', 389.99, 'WiFi, TV, Royal Suite, Service conciergerie', 2, 'piccadilly', TRUE, 'bon état', 70, 'disponible'),
(16, '1701', 399.99, 'WiFi, TV, Penthouse, Vue Eiffel', 2, 'champs elysees', TRUE, 'bon état', 75, 'disponible'),
(17, '1801', 319.99, 'WiFi, TV, Vue Shibuya Crossing', 2, 'shibuya', FALSE, 'bon état', 45, 'disponible'),
(18, '1901', 279.99, 'WiFi, TV, Vue Chao Phraya River', 2, 'riverside', FALSE, 'bon état', 42, 'disponible');

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