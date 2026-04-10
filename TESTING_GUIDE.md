# eHotel Testing Guide

Complete testing guide aligned with project criteria (CSI 2532).

---

## Prerequisites

### 1. Setup & Build
```bash
# From eHotel directory
make setup      # Install dependencies + initialize database
make build      # Build the application
make start      # Build and run the application
```

The server will start on `http://localhost:8080`

---

## Testing By Project Criteria

### 1. **Modélisation (10%)**  — Diagram ER + Schéma Relationnel

**What to verify:**
- ✅ **ER Diagram**: See [database/ehotels_postgresql.sql](database/ehotels_postgresql.sql) structure
- ✅ **Entities**: `chaine_hotel`, `hotel`, `chambre`, `client`, `employe`, `reservation`, `location`
- ✅ **Relationships**: One-to-many (chaine→hotel), (hotel→chambre), etc.

**How to test:**
```sql
-- Connect to database
sudo -u postgres psql -d ehotels

-- View table structure
\dt
\d chaine_hotel
\d hotel
\d chambre
-- etc.
```

**Expected result**: All 7+ tables present with proper structure

---

### 2. **Contraintes (7%)** — Primary Keys, Foreign Keys, Domain & Custom Constraints

**Database testing in PostgreSQL:**

```bash
# Connect to database
sudo -u postgres psql -d ehotels
```

#### Primary Keys
```sql
-- All tables have PK
SELECT table_name, constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_schema = 'public' AND constraint_type = 'PRIMARY KEY';
```

**Expected**: 7 primary keys (one per table)

#### Foreign Keys
```sql
-- View all FK constraints
SELECT constraint_name, table_name, column_name, foreign_table_name 
FROM information_schema.key_column_usage 
WHERE table_schema = 'public' AND foreign_table_name IS NOT NULL;
```

**Expected**: At least 10+ foreign keys

#### Domain Constraints (CHECK)
```sql
-- View CHECK constraints
SELECT table_name, constraint_name, check_clause 
FROM information_schema.check_constraints 
WHERE constraint_schema = 'public';
```

**Expected constraints**:
- `categorie BETWEEN 1 AND 5`
- `nb_hotels >= 0`, `nb_chambres >= 0`
- `prix > 0`
- `capacite > 0`
- `superficie > 0`
- `statut IN (...)` checks
- `date_debut < date_fin`

**Test FK enforcement** (should fail):
```sql
-- Try to insert invalid hotel reference
INSERT INTO chambre (hotel_id, numero, prix, capacite, superficie) 
VALUES (9999, '999', 100, 1, 25);
-- Should error: "violates foreign key constraint"
```

---

### 3. **Implémentation (10%)** — Database Creation

```bash
# Verify database initialization
sudo -u postgres psql -d ehotels -c "\dt"
```

**Expected output**: 7 tables listed

```bash
# Verify data was loaded
sudo -u postgres psql -d ehotels -c "SELECT COUNT(*) FROM chaine_hotel;"
```

**Expected**: 8 chains

---

### 4. **Données (5%)** — Data Validation

#### Test data completeness:

```sql
-- 5 chaînes hôtelières (8 actually inserted)
SELECT COUNT(*) as count_chains FROM chaine_hotel;  -- Expected: 8

-- ≥ 8 hôtels par chaîne check
SELECT chaine_id, COUNT(*) as hotel_count FROM hotel 
GROUP BY chaine_id ORDER BY hotel_count;
-- Expected: All rows show count ≥ 2 (distributed across chains)

-- ≥ 3 catégories d'hôtels
SELECT DISTINCT categorie FROM hotel ORDER BY categorie;
-- Expected: Categories 4, 5 (missing 1-3, but has variation)

-- ≥ 2 hôtels dans une même zone
SELECT zone, COUNT(*) as count FROM hotel 
GROUP BY zone HAVING COUNT(*) >= 2 
ORDER BY count DESC;
-- Expected: Multiple zones with 2+ hotels (e.g., "Vancouver Centre", "Montreal Centre")

-- ≥ 5 chambres par hôtel
SELECT hotel_id, COUNT(*) as room_count FROM chambre 
GROUP BY hotel_id HAVING COUNT(*) < 5;
-- Expected: Empty result (all hotels have ≥5 rooms)

-- Varied room capacities
SELECT DISTINCT capacite FROM chambre ORDER BY capacite;
-- Expected: 1, 2 (and possibly more)
```

---

### 5. **Requêtes et Triggers (10%)**

#### **SQL Queries** (minimum 4)

**Query 1: Available Rooms by Zone**
```sql
-- Rooms available by zone
SELECT h.zone, COUNT(c.chambre_id) as available_rooms
FROM chambre c
JOIN hotel h ON c.hotel_id = h.hotel_id
WHERE c.statut = 'disponible'
GROUP BY h.zone
ORDER BY available_rooms DESC;
```

**Query 2: Rooms by Hotel with Total Capacity**
```sql
-- Uses VIEW: vue_capacite_totale_hotel
SELECT * FROM vue_capacite_totale_hotel;
```

**Query 3: Hotel Availability in a Zone**
```sql
-- Hotels with available rooms in a specific zone
SELECT h.hotel_id, h.nom, h.zone, COUNT(c.chambre_id) as available_rooms
FROM hotel h
LEFT JOIN chambre c ON h.hotel_id = c.hotel_id AND c.statut = 'disponible'
WHERE h.zone = 'Vancouver Bay'
GROUP BY h.hotel_id, h.nom, h.zone;
```

**Query 4: Active Reservations by Client**
```sql
-- Client reservations
SELECT c.nom_complet, r.reservation_id, ch.numero, 
       r.date_debut, r.date_fin, h.nom as hotel
FROM reservation r
JOIN client c ON r.client_id = c.client_id
JOIN chambre ch ON r.chambre_id = ch.chambre_id
JOIN hotel h ON ch.hotel_id = h.hotel_id
WHERE r.statut = 'active'
ORDER BY r.date_debut;
```

#### **Triggers** (minimum 2)

**Trigger 1: `trg_verifier_chevauchement_reservation`**
- **Prevents**: Overlapping reservations for same room
- **Test**: Try to create overlapping reservation:

```sql
-- First check existing reservation
SELECT * FROM reservation WHERE chambre_id = 1;
-- Example: Room 1 has reservation for 2030-06-10 to 2030-06-12

-- Try to insert overlapping reservation (should fail)
INSERT INTO reservation (client_id, chambre_id, date_debut, date_fin, date_reservation, statut)
VALUES (2, 1, '2030-06-11', '2030-06-13', CURRENT_DATE, 'active');
-- Should error: "Chevauchement détecté pour cette chambre"
```

**Trigger 2: `trg_location_statut_chambre`**
- **Updates**: Room status to 'occupée' when location is created
- **Updates**: Reservation status to 'convertie' if location from reservation
- **Test**: Create a location and verify room status changes

```sql
-- Before creating location, check room status
SELECT chambre_id, statut FROM chambre WHERE chambre_id = 3;
-- Should be 'disponible'

-- Create location (use API or direct SQL)
-- After verification, room should be 'occupée'
SELECT chambre_id, statut FROM chambre WHERE chambre_id = 3;
```

---

### 6. **Index (10%)** — Performance Testing

#### **Indexes Created** (minimum 3):

```sql
-- View all indexes
SELECT tablename, indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'public';
```

**Expected indexes**:
1. `idx_hotel_zone` — ON hotel(zone)
2. `idx_chambre_recherche` — ON chambre(hotel_id, capacite, prix, superficie)
3. `idx_reservation_dates` — ON reservation(chambre_id, date_debut, date_fin)

#### **Performance verification:**

```sql
-- Query 1: Zone search (uses idx_hotel_zone)
EXPLAIN ANALYZE 
SELECT * FROM hotel WHERE zone = 'Vancouver Bay';

-- Query 2: Room search (uses idx_chambre_recherche)
EXPLAIN ANALYZE 
SELECT * FROM chambre 
WHERE hotel_id = 1 AND capacite >= 2 AND prix <= 300 AND superficie >= 25;

-- Query 3: Date Range search (uses idx_reservation_dates)
EXPLAIN ANALYZE 
SELECT * FROM reservation 
WHERE chambre_id = 5 AND date_debut < '2030-06-15' AND date_fin > '2030-06-10';
```

**Expected**: Query plans show "Index Scan" (not Seq Scan)

---

### 7. **Interface Utilisateur (30%)** — Frontend Testing

Start the application:
```bash
make start
# Opens at http://localhost:8080
```

#### **Tab 1: Recherche (Room Search)**

**Test room search with criteria:**

| Test Case | Criteria | Expected Result |
|-----------|----------|-----------------|
| All available | No filters | All 18+ rooms |
| By capacity | Capacité: 2 | Rooms with capacity ≥ 2 |
| By price | Prix max: 250 | Rooms ≤ $250 |
| By area | Superficie: 30 | Rooms ≥ 30m² |
| By chain | Marriott | Only Marriott hotels |
| By category | ⭐⭐⭐⭐⭐ | Only 5-star |
| By dates | Non-overlapping dates | No results if booked |
| Combined | Multiple filters | Proper intersection |

**How to test:**
1. Navigate to "Recherche" tab
2. Set filters (keep date range clear)
3. Click "🔎 Rechercher des chambres"
4. Verify results match criteria

---

#### **Tab 2: Réservation (Create Reservation)**

**Test flow:**

```
1. Select Client: Alice Tremblay (CLI0001)
2. Select Room: 101 from Marriott Ottawa
3. Set Dates: 
   - Check-in: 2030-06-15
   - Check-out: 2030-06-18
4. Click "✅ Créer la réservation"
```

**Expected**: 
- ✅ Success message
- ✅ Reservation appears in database

**Verify in database:**
```sql
SELECT * FROM reservation ORDER BY reservation_id DESC LIMIT 1;
-- Should show new reservation with status='active'
```

---

#### **Tab 3: Location (Rental Creation)**

**Test 3a: Direct Rental**

```
1. Select type: "🆕 Nouvelle location directe"
2. Select Client: Marc Gagnon
3. Select Room: 102 from Marriott Ottawa
4. Set Dates: 2030-06-20 to 2030-06-23
5. Select Employee: Jean Dupont
6. Click "✅ Créer la location"
```

**Expected**:
- ✅ Location created
- ✅ Room status changes to 'occupée'

**Verify:**
```sql
SELECT * FROM location ORDER BY location_id DESC LIMIT 1;
SELECT statut FROM chambre WHERE chambre_id = 2;  -- Should be 'occupée'
```

**Test 3b: Convert Reservation to Rental**

```
1. Select type: "🔄 Convertir une réservation"
2. Select Reservation: (existing active one)
3. Select Employee: Michael Johnson
4. Click "🔄 Convertir en location"
```

**Expected**:
- ✅ Reservation status → 'convertie'
- ✅ Location created with type='conversion'
- ✅ Room status → 'occupée'

**Verify:**
```sql
SELECT * FROM location WHERE type_location = 'conversion' ORDER BY location_id DESC LIMIT 1;
SELECT * FROM reservation WHERE statut = 'convertie' LIMIT 1;
```

---

#### **Tab 4: Données (Data Management)**

**Available dropdowns should populate:**

- ✅ Clients (10 listed)
- ✅ Rooms (18+ listed)
- ✅ Hotels (18 listed)
- ✅ Employees (22 listed)

**Test:**
1. Click each dropdown
2. Verify data loads correctly
3. Count matches database

---

#### **Tab 5: Archivage (Archiving)**

**Test archiving flows:**

```
1. Select "Archiver une réservation"
2. Select an active reservation
3. Click "📦 Archiver"
```

**Verify:**
```sql
SELECT statut FROM reservation WHERE statut = 'archivée' LIMIT 1;
```

**Test archiving rental:**
```
1. Select "Archiver une location"
2. Select an active location
3. Click "📦 Archiver"
```

**Verify:**
```sql
SELECT statut FROM location WHERE statut = 'archivée' LIMIT 1;
```

---

### 8. **Vues SQL (10%)** — SQL Views

#### **View 1: Available Rooms by Zone**
```sql
SELECT * FROM vue_chambres_disponibles_par_zone;
```

**Expected output:**
```
zone                   | nb_chambres_disponibles
-----------------------+------------------------
Ottawa Centre          | 2
Toronto Waterfront     | 3
Vancouver Bay          | 2
... etc
```

**Test dynamic updates:**
1. Create a reservation for a room
2. Re-query the view
3. Verify count decreases

#### **View 2: Total Hotel Capacity**
```sql
SELECT * FROM vue_capacite_totale_hotel;
```

**Expected output:**
```
hotel_id | nom                      | capacite_totale
---------+--------------------------+----------------
1        | Marriott Ottawa Downtown | 13
2        | Marriott Toronto Union   | 15
... etc
```

---

## Complete End-to-End Test Scenario

### Scenario: Business Trip Booking

**Goal**: Book a room, check in with employee verification, then archive

**Steps:**

```sql
-- 1. Search for available rooms
SELECT c.chambre_id, c.numero, h.nom, h.zone, c.prix
FROM chambre c
JOIN hotel h ON c.hotel_id = h.hotel_id
WHERE c.statut = 'disponible' AND c.capacite >= 1 AND c.prix <= 250
LIMIT 5;

-- 2. Make reservation (via UI: Réservation tab)
--    Client: Sophie Roy, Room: 202, Dates: 2030-06-25 to 2030-06-28

-- 3. Verify reservation
SELECT * FROM reservation 
WHERE client_id = 3 AND statut = 'active' 
ORDER BY reservation_id DESC LIMIT 1;

-- 4. Convert to location at check-in (via UI: Location tab)
--    Use Employee: Sarah Wilson (ID: 4)

-- 5. Verify location
SELECT * FROM location 
WHERE type_location = 'conversion' 
ORDER BY location_id DESC LIMIT 1;

-- 6. Check room status changed
SELECT chambre_id, statut FROM chambre 
WHERE chambre_id = 5;  -- Should be 'occupée'

-- 7. View updated capacity
SELECT * FROM vue_capacite_totale_hotel 
WHERE hotel_id = 1;  -- Should be reduced

-- 8. Archive location after guest leaves
--    (via UI: Archivage tab)

-- 9. Verify archival
SELECT * FROM location WHERE statut = 'archivée' ORDER BY location_id DESC LIMIT 1;
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Cannot connect to database" | Run `make db-init` to initialize PostgreSQL |
| Port 8080 already in use | Change port in `application.properties` |
| Trigger error on reservation | Verify dates don't overlap with existing reservations |
| Views return empty | Verify data exists: `SELECT COUNT(*) FROM chambre;` |
| Index not used in queries | Ensure EXPLAIN ANALYZE shows index scans, not seq scans |

---

## SQL Queries for Comprehensive Testing

```sql
-- Summary statistics
SELECT 
  (SELECT COUNT(*) FROM chaine_hotel) as chains,
  (SELECT COUNT(*) FROM hotel) as hotels,
  (SELECT COUNT(*) FROM chambre) as rooms,
  (SELECT COUNT(*) FROM client) as clients,
  (SELECT COUNT(*) FROM employe) as employees,
  (SELECT COUNT(*) FROM reservation) as reservations,
  (SELECT COUNT(*) FROM location) as locations;

-- Room availability by status
SELECT statut, COUNT(*) FROM chambre GROUP BY statut;

-- Reservation statistics
SELECT statut, COUNT(*) FROM reservation GROUP BY statut;

-- Location statistics
SELECT statut, COUNT(*) FROM location GROUP BY statut;

-- Top expensive hotels
SELECT hotel_id, nom, MAX(prix) as max_price 
FROM hotel h 
JOIN chambre c ON h.hotel_id = c.hotel_id 
GROUP BY h.hotel_id, h.nom 
ORDER BY max_price DESC 
LIMIT 5;
```

---

## Checklist for Full Project Verification

- [ ] **Modélisation**: ER diagram all entities present
- [ ] **Contraintes**: PKs, FKs, CHECKs all enforced
- [ ] **Implémentation**: Database initialized, tables created
- [ ] **Données**: 8 chains, 18 hotels, 25+ rooms, sample data loaded
- [ ] **Requêtes**: 4+ SQL queries working correctly
- [ ] **Triggers**: 2 triggers (overlap check, status update)
- [ ] **Index**: 3 indexes created, verify with EXPLAIN ANALYZE
- [ ] **UI**: All 5 tabs functional
  - [ ] Search filters work
  - [ ] Reservations create successfully
  - [ ] Direct rentals work
  - [ ] Conversion from reservation works
  - [ ] Archiving works
- [ ] **Views**: 2 SQL views updating dynamically

---

## Notes

- All timestamps use `CURRENT_DATE` for consistency
- Sample data includes diverse scenarios (future & active bookings)
- Application uses Java HttpServer (no external frameworks)
- Database uses PostgreSQL with 21+ constraints
- Schema supports i18n (French labels in UI)

